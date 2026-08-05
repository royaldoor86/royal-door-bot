import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:async';
import 'dart:math';
import 'firestore_service.dart';
import '../models/user_model.dart';
import '../models/country_config.dart';
import '../core/constants/countries.dart';
import '../core/constants/otp_error_codes.dart';
import 'user_bootstrap_service.dart';
import 'fcm_service.dart';

/// استثناء OTP محسّن مع دعم الدول
class OTPException implements Exception {
  final String message;
  final String? code;
  final String? countryCode;
  final dynamic originalError;
  final StackTrace? stackTrace;

  OTPException(
    this.message, {
    this.code,
    this.countryCode,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'OTPException[$code]: $message';

  /// الحصول على رسالة الخطأ مترجمة
  String getLocalizedMessage({String language = 'ar'}) {
    if (code != null) {
      return OTPErrorMessages.getMessageWithContext(
        code!,
        language: language,
        countryName: countryCode != null &&
                CountriesDatabase.getCountry(countryCode!) != null
            ? CountriesDatabase.getCountry(countryCode!)!.countryName
            : null,
      );
    }
    return message;
  }
}

/// نموذج بيانات OTP محسّن
class OTPData {
  final bool verified;
  final int remainingSeconds;
  final String? phoneNumber;
  final String? countryCode;
  final int verifyAttempts;
  final int maxVerifyAttempts;
  final bool exists;
  final String? provider;
  final DateTime? sentAt;
  final DateTime? expiresAt;

  OTPData({
    required this.verified,
    required this.remainingSeconds,
    this.phoneNumber,
    this.countryCode,
    required this.verifyAttempts,
    required this.maxVerifyAttempts,
    required this.exists,
    this.provider,
    this.sentAt,
    this.expiresAt,
  });

  factory OTPData.fromMap(Map<String, dynamic> map) {
    return OTPData(
      verified: map['verified'] ?? false,
      remainingSeconds: map['remainingSeconds'] ?? 0,
      phoneNumber: map['phoneNumber'],
      countryCode: map['countryCode'],
      verifyAttempts: map['verifyAttempts'] ?? 0,
      maxVerifyAttempts: map['maxVerifyAttempts'] ?? 5,
      exists: map['exists'] ?? false,
      provider: map['provider'],
      sentAt: map['sentAt'] != null ? DateTime.parse(map['sentAt']) : null,
      expiresAt:
          map['expiresAt'] != null ? DateTime.parse(map['expiresAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'verified': verified,
      'remainingSeconds': remainingSeconds,
      'phoneNumber': phoneNumber,
      'countryCode': countryCode,
      'verifyAttempts': verifyAttempts,
      'maxVerifyAttempts': maxVerifyAttempts,
      'exists': exists,
      'provider': provider,
      'sentAt': sentAt?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  /// هل OTP قريب من الانتهاء؟
  bool isExpiringSoon() {
    return remainingSeconds > 0 && remainingSeconds <= 60;
  }

  /// هل OTP منتهي؟
  bool isExpired() {
    return remainingSeconds <= 0;
  }

  /// الحصول على الوقت المتبقي بصيغة MM:SS
  String getFormattedTime() {
    if (remainingSeconds <= 0) return '00:00';
    int minutes = remainingSeconds ~/ 60;
    int seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb 
        ? '836724893984-vrm9mb2pkqjkeri25n5218vrss5dlste.apps.googleusercontent.com' 
        : null,
  );
  late FirebaseFunctions _functions;

  // متغيرات OTP المحسنة
  Timer? _statusTimer;
  int _remainingSeconds = 0;
  String? _currentCountryCode;
  String? _currentPhoneNumber;
  int _verifyAttempts = 0;
  int _maxVerifyAttempts = 5;
  DateTime? _lastOTPSendTime;
  DateTime? _otpExpiresAt;

  // Streams لـ OTP
  late StreamController<int> _remainingTimeController;
  late StreamController<OTPData> _otpStatusController;

  AuthService() {
    _initializeFirebase();
  }

  void _initializeFirebase() {
    _functions = FirebaseFunctions.instance;
    _remainingTimeController = StreamController<int>.broadcast();
    _otpStatusController = StreamController<OTPData>.broadcast();

    // Handle OAuth Redirect Results for Web (Google, Facebook, etc.)
    if (kIsWeb) {
      _auth.getRedirectResult().then((result) async {
        if (result.user != null) {
          debugPrint("✅ OAuth Redirect Login Success: ${result.user?.email} (Provider: ${result.credential?.providerId})");
          await UserBootstrapService.bootstrapUser();
          await FcmService.registerTokenForCurrentUser();
        }
      }).catchError((e) {
        debugPrint("❌ OAuth Redirect Login Error: $e");
      });
    }
  }

  /// Stream لمراقبة الوقت المتبقي
  Stream<int> get remainingTimeStream => _remainingTimeController.stream;

  /// Stream لمراقبة حالة OTP
  Stream<OTPData> get otpStatusStream => _otpStatusController.stream;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signOut() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'isOnline': false,
          'lastSeen': FieldValue.serverTimestamp(),
        });
      }
      await FcmService.unregisterTokenForCurrentUser();
      await _googleSignIn.signOut();
      await FacebookAuth.instance.logOut();
      await _auth.signOut();
    } catch (e) {
      debugPrint("SignOut Error: $e");
    }
  }

  Future<User?> registerWithEmail(
      String email, String password, String name) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      final user = result.user;
      if (user != null) {
        final randomRoyalId =
            (10000000 + Random().nextInt(90000000)).toString();
        final newUser = UserModel(
            uid: user.uid, royalId: randomRoyalId, name: name, email: email);
        await _firestoreService.saveUser(newUser);
        await UserBootstrapService.bootstrapUser();
        await FcmService.registerTokenForCurrentUser();
      }
      return user;
    } catch (e) {
      debugPrint("Register Error: $e");
      return null;
    }
  }

  Future<String?> loginWithGoogle() async {
    try {
      debugPrint('🚀🚀🚀 loginWithGoogle START - Platform: ${kIsWeb ? "Web" : "Mobile"}');
      debugPrint('🔍 Firebase Auth state: ${FirebaseAuth.instance.currentUser}');
      
      if (kIsWeb) {
        debugPrint('🌐 Web platform detected');
        // Check if we're returning from a redirect
        debugPrint('🔄 Checking for redirect result...');
        final user = await _handleRedirectResult();
        if (user != null) {
          debugPrint("✅✅✅ Google Sign In successful from redirect: ${user.email}");
          debugPrint("✅ User UID: ${user.uid}");
          debugPrint("✅ User display name: ${user.displayName}");
          await UserBootstrapService.bootstrapUser();
          await FcmService.registerTokenForCurrentUser();
          return null;
        }
        debugPrint('ℹ️ No redirect result found, attempting popup...');
        
        // On web, use popup first (works better in most browsers)
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        
        debugPrint("🚀🚀🚀 Attempting Google Sign In with popup...");
        debugPrint("🔍 Current URL: ${Uri.base}");
        debugPrint("🔍 Firebase Auth current user: ${FirebaseAuth.instance.currentUser}");
        debugPrint("🔍 Provider scopes: email, profile");
        
        try {
          debugPrint('⏳ Calling signInWithPopup...');
          final userCredential = await _auth.signInWithPopup(googleProvider);
          debugPrint("✅✅✅ Google Sign In successful with popup: ${userCredential.user?.email}");
          debugPrint("✅ User UID: ${userCredential.user?.uid}");
          debugPrint("✅ User display name: ${userCredential.user?.displayName}");
          debugPrint("✅ User photo URL: ${userCredential.user?.photoURL}");
          debugPrint("✅ Credential provider: ${userCredential.credential?.providerId}");
          debugPrint("✅ Credential sign-in method: ${userCredential.credential?.signInMethod}");
          await UserBootstrapService.bootstrapUser();
          await FcmService.registerTokenForCurrentUser();
          debugPrint('✅✅✅ User bootstrap and FCM registration completed');
          return null;
        } catch (popupError) {
          debugPrint("❌❌❌ Popup failed: $popupError");
          debugPrint("❌ Popup error type: ${popupError.runtimeType}");
          debugPrint("❌ Popup error code: ${popupError is FirebaseAuthException ? (popupError).code : 'N/A'}");
          debugPrint("❌ Popup error message: ${popupError is FirebaseAuthException ? (popupError).message : popupError.toString()}");
          
          // Fallback to redirect if popup fails
          try {
            debugPrint("🔄🔄🔄 Trying redirect as fallback...");
            debugPrint("⏳ Calling signInWithRedirect...");
            await _auth.signInWithRedirect(googleProvider);
            debugPrint("✅ Google Sign In redirect initiated - page will reload");
            return null; // Page will redirect
          } catch (redirectError) {
            debugPrint("❌❌❌ Redirect also failed: $redirectError");
            debugPrint("❌ Redirect error type: ${redirectError.runtimeType}");
            debugPrint("❌ Redirect error code: ${redirectError is FirebaseAuthException ? (redirectError).code : 'N/A'}");
            debugPrint("❌ Redirect error message: ${redirectError is FirebaseAuthException ? (redirectError).message : redirectError.toString()}");
            return "فشل تسجيل الدخول بـ Google. تأكد من إضافة النطاق في Firebase Console.";
          }
        }
      } else {
        // On mobile, use the standard signIn method
        debugPrint("📱 Mobile platform detected");
        debugPrint("🚀🚀🚀 Mobile Google Sign In");
        debugPrint("🔄 Signing out from previous Google session...");
        await _googleSignIn.signOut();
        debugPrint("⏳ Calling GoogleSignIn.signIn()...");
        final googleUser = await _googleSignIn.signIn();
        debugPrint("📝 Google user: ${googleUser?.id}");
        debugPrint("📝 Google user email: ${googleUser?.email}");
        debugPrint("📝 Google user display name: ${googleUser?.displayName}");
        if (googleUser == null) {
          debugPrint("⚠️ Google user cancelled sign in");
          return "CANCELLED";
        }
        debugPrint("⏳ Getting Google authentication tokens...");
        final googleAuth = await googleUser.authentication;
        debugPrint("📝 Google auth - accessToken: ${googleAuth.accessToken != null}, idToken: ${googleAuth.idToken != null}");
        debugPrint("📝 Access token length: ${googleAuth.accessToken?.length}");
        debugPrint("📝 ID token length: ${googleAuth.idToken?.length}");
        debugPrint("⏳ Creating Firebase credential...");
        final credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
        debugPrint("⏳ Signing in with Firebase credential...");
        await _auth.signInWithCredential(credential);
        debugPrint("✅✅✅ Firebase sign in successful");
        debugPrint("✅ Current user: ${FirebaseAuth.instance.currentUser?.email}");
        debugPrint("✅ Current user UID: ${FirebaseAuth.instance.currentUser?.uid}");
        await UserBootstrapService.bootstrapUser();
        await FcmService.registerTokenForCurrentUser();
        debugPrint('✅✅✅ User bootstrap and FCM registration completed');
        return null;
      }
    } catch (e) {
      debugPrint("❌❌❌ Google Sign In Error: $e");
      debugPrint("❌ Error type: ${e.runtimeType}");
      debugPrint("❌ Error stack trace: ${StackTrace.current}");
      if (e is FirebaseAuthException) {
        debugPrint("❌ Firebase Auth error code: ${e.code}");
        debugPrint("❌ Firebase Auth error message: ${e.message}");
        debugPrint("❌ Firebase Auth error email: ${e.email}");
      }
      return e.toString();
    }
  }

  /// Handle redirect result from OAuth providers
  Future<User?> _handleRedirectResult() async {
    try {
      final result = await _auth.getRedirectResult();
      if (result.user != null) {
        debugPrint("✅ Redirect result found: ${result.user?.email}");
        return result.user;
      }
      return null;
    } catch (e) {
      debugPrint("❌ Error handling redirect result: $e");
      return null;
    }
  }

  /// Check if running in Telegram Mini App
  bool _isTelegramMiniApp() {
    if (!kIsWeb) return false;
    try {
      final uri = Uri.base;
      return uri.queryParameters.containsKey('tgWebAppData') || 
             uri.queryParameters.containsKey('user') ||
             uri.queryParameters.containsKey('query_id');
    } catch (e) {
      return false;
    }
  }

  Future<String?> loginWithFacebook() async {
    try {
      debugPrint('🚀 loginWithFacebook - Platform: ${kIsWeb ? "Web" : "Mobile"}');
      
      if (kIsWeb) {
        // Check if we're returning from a redirect
        final user = await _handleRedirectResult();
        if (user != null) {
          debugPrint("✅ Facebook Sign In successful from redirect: ${user.email}");
          await UserBootstrapService.bootstrapUser();
          await FcmService.registerTokenForCurrentUser();
          return null;
        }
        
        // On web, use popup first
        FacebookAuthProvider facebookProvider = FacebookAuthProvider();
        facebookProvider.addScope('public_profile');
        facebookProvider.addScope('email');
        
        debugPrint("🚀 Attempting Facebook Sign In with popup...");
        debugPrint("🔍 Current URL: ${Uri.base}");
        
        try {
          final userCredential = await _auth.signInWithPopup(facebookProvider);
          debugPrint("✅ Facebook Sign In successful with popup: ${userCredential.user?.email}");
          debugPrint("✅ User UID: ${userCredential.user?.uid}");
          await UserBootstrapService.bootstrapUser();
          await FcmService.registerTokenForCurrentUser();
          return null;
        } catch (popupError) {
          debugPrint("❌ Popup failed: $popupError");
          debugPrint("❌ Popup error type: ${popupError.runtimeType}");
          // Fallback to redirect if popup fails
          try {
            debugPrint("🔄 Trying redirect as fallback...");
            await _auth.signInWithRedirect(facebookProvider);
            debugPrint("✅ Facebook Sign In redirect initiated");
            return null; // Page will redirect
          } catch (redirectError) {
            debugPrint("❌ Redirect also failed: $redirectError");
            debugPrint("❌ Redirect error type: ${redirectError.runtimeType}");
            return "فشل تسجيل الدخول بـ Facebook. تأكد من إضافة النطاق في Firebase Console.";
          }
        }
      } else {
        // On mobile, use the standard Facebook Auth SDK
        debugPrint("🚀 Mobile Facebook Sign In");
        final LoginResult result = await FacebookAuth.instance.login(
          permissions: ['public_profile', 'email'],
        );
        
        debugPrint("📱 Facebook login status: ${result.status}");
        
        if (result.status == LoginStatus.cancelled) return "CANCELLED";
        
        if (result.status == LoginStatus.failed) {
          debugPrint("❌ Facebook failed: ${result.message}");
          return "فشل فيسبوك: ${result.message}\nملاحظة: يرجى التأكد من أن معرف التطبيق (1365126268889682) صالح في لوحة تحكم مطوري فيسبوك.";
        }
        
        if (result.accessToken == null) {
          return "فشل الحصول على رمز الوصول من فيسبوك";
        }

        final OAuthCredential credential =
            FacebookAuthProvider.credential(result.accessToken!.token);
        
        await _auth.signInWithCredential(credential);
        await UserBootstrapService.bootstrapUser();
        await FcmService.registerTokenForCurrentUser();
        
        debugPrint("✅ تم تسجيل الدخول بفيسبوك بنجاح");
        return null;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint("❌ خطأ Firebase في تسجيل دخول فيسبوك: ${e.code}");
      if (e.code == 'account-exists-with-different-credential') {
        return "هذا الحساب مسجل مسبقاً بطريقة دخول أخرى. يرجى تسجيل الدخول بنفس الطريقة السابقة لفتح نفس الحساب الموحد.";
      }
      return "فشل تسجيل الدخول: ${e.message}";
    } catch (e) {
      debugPrint("🔥 خطأ استثنائي في فيسبوك: $e");
      return "خطأ غير متوقع: $e";
    }
  }

  // الدوال المساعدة
  Future<bool> refreshEmailVerified() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      await user.reload();
      return _auth.currentUser?.emailVerified ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<String?> sendVerificationEmailAgain() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return "لا يوجد مستخدم مسجل";
      await user.sendEmailVerification();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(FirebaseAuthException e) onVerificationFailed,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: onVerificationCompleted,
      verificationFailed: onVerificationFailed,
      codeSent: (String verificationId, int? resendToken) =>
          onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<User?> signInWithPhone(String verificationId, String smsCode) async {
    try {
      final credential = PhoneAuthProvider.credential(
          verificationId: verificationId, smsCode: smsCode);
      final result = await _auth.signInWithCredential(credential);
      return result.user;
    } catch (e) {
      return null;
    }
  }

  Future<void> updateVerifiedPhoneNumber(String phoneNumber) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'phoneNumber': phoneNumber,
          'phoneVerified': true,
          'phoneVerifiedAt': FieldValue.serverTimestamp(),
          'twoFactorEnabled': true, // تفعيل 2FA تلقائياً عند ربط الهاتف
        });
      }
    } catch (e) {
      debugPrint("Error updating phone: $e");
    }
  }

  // اسم بديل للتوافق مع صفحات قديمة
  Future<void> updateUserPhoneNumber(String phoneNumber) =>
      updateVerifiedPhoneNumber(phoneNumber);

  /// ==================== دوال OTP المحسنة ====================

  /// إرسال OTP إلى رقم الهاتف مع دعم الدول
  Future<int> sendOTP(String phoneNumber,
      {String? countryCode, bool allowAnonymous = false}) async {
    try {
      if (!allowAnonymous) {
        _validateAuthentication();
      }

      // اكتشاف كود الدولة إذا لم يتم توفيره
      countryCode ??= _detectCountryCode(phoneNumber);

      if (countryCode == null) {
        throw OTPException(
          'لم يتم تحديد الدولة',
          code: OTPErrorCode.invalidCountryCode,
        );
      }

      // الحصول على بيانات الدولة (دعم الرمز المختصر ومفتاح الاتصال)
      CountryConfig? country = CountriesDatabase.getCountry(countryCode);
      if (country == null && countryCode.startsWith('+')) {
        country = CountriesDatabase.getCountryByDialCode(countryCode);
      }

      if (country == null) {
        throw OTPException(
          'الدولة المحددة ($countryCode) غير مدعومة حالياً ⚠️',
          code: OTPErrorCode.unsupportedCountry,
          countryCode: countryCode,
        );
      }

      // التحقق من صحة رقم الهاتف
      if (!country.isValidPhoneNumber(phoneNumber)) {
        throw OTPException(
          OTPErrorMessages.getMessage(OTPErrorCode.invalidPhoneFormat,
              countryName: country.countryName),
          code: OTPErrorCode.invalidPhoneFormat,
          countryCode: countryCode,
        );
      }

      // تنسيق رقم الهاتف
      final formattedPhone = country.formatPhoneNumber(phoneNumber);

      // فحص التحديث الزمني (مكافحة الرسائل المتكررة)
      _checkRateLimit();

      // استدعاء الدالة السحابية
      final callable = _functions.httpsCallable('sendOTP');
      final result = await callable.call({
        'phoneNumber': formattedPhone,
        'countryCode': countryCode,
        'provider': country.defaultProvider,
      });

      final responseData = result.data as Map<String, dynamic>;
      final expiresIn = responseData['expiresIn'] as int? ?? 300;

      // تحديث الحالة
      _currentCountryCode = countryCode;
      _currentPhoneNumber = formattedPhone;
      _verifyAttempts = 0;
      _maxVerifyAttempts = responseData['maxAttempts'] as int? ?? 5;
      _lastOTPSendTime = DateTime.now();
      _otpExpiresAt = DateTime.now().add(Duration(seconds: expiresIn));

      // بدء مراقبة الوقت
      _startTimerMonitoring(expiresIn);

      return expiresIn;
    } on FirebaseFunctionsException catch (e) {
      throw OTPException(
        e.message ?? OTPErrorMessages.getMessage(OTPErrorCode.providerError),
        code: _mapFirebaseErrorCode(e.code),
        countryCode: countryCode,
        originalError: e,
      );
    } catch (e, stackTrace) {
      if (e is OTPException) rethrow;
      throw OTPException(
        'فشل في إرسال OTP: ${e.toString()}',
        code: OTPErrorCode.unknownError,
        countryCode: countryCode,
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// التحقق من رمز OTP
  Future<bool> verifyOTP(String otp, {bool allowAnonymous = false}) async {
    try {
      if (!allowAnonymous) {
        _validateAuthentication();
      }

      if (otp.isEmpty || otp.length != 6 || !RegExp(r'^\d{6}$').hasMatch(otp)) {
        throw OTPException(
          OTPErrorMessages.getMessage(OTPErrorCode.invalidOTPFormat),
          code: OTPErrorCode.invalidOTPFormat,
          countryCode: _currentCountryCode,
        );
      }

      // فحص محاولات التحقق
      if (_verifyAttempts >= _maxVerifyAttempts) {
        throw OTPException(
          OTPErrorMessages.getMessageWithContext(
            OTPErrorCode.maxAttemptsExceeded,
            attemptsRemaining: 0,
          ),
          code: OTPErrorCode.maxAttemptsExceeded,
          countryCode: _currentCountryCode,
        );
      }

      // فحص انتهاء الصلاحية
      if (_otpExpiresAt != null && DateTime.now().isAfter(_otpExpiresAt!)) {
        throw OTPException(
          OTPErrorMessages.getMessage(OTPErrorCode.otpExpired),
          code: OTPErrorCode.otpExpired,
          countryCode: _currentCountryCode,
        );
      }

      // استدعاء الدالة السحابية
      final callable = _functions.httpsCallable('verifyOTP');
      final result = await callable.call({
        'otp': otp,
        'phoneNumber': _currentPhoneNumber,
        'countryCode': _currentCountryCode,
      });

      final responseData = result.data as Map<String, dynamic>;
      final verified = responseData['verified'] as bool? ?? false;
      final customToken = responseData['customToken'] as String? ?? responseData['token'] as String?;

      if (verified) {
        _stopTimerMonitoring();
        _verifyAttempts = 0;
        
        // إذا كان هناك رمز دخول مخصص، قم بتسجيل الدخول فوراً
        if (customToken != null && customToken.isNotEmpty) {
          debugPrint("🔑 Received custom token, signing in...");
          await _auth.signInWithCustomToken(customToken);
          await UserBootstrapService.bootstrapUser();
          await FcmService.registerTokenForCurrentUser();
        }
      } else {
        _verifyAttempts++;
      }

      return verified;
    } on FirebaseFunctionsException catch (e) {
      _verifyAttempts++;
      throw OTPException(
        e.message ?? OTPErrorMessages.getMessage(OTPErrorCode.invalidOTP),
        code: _mapFirebaseErrorCode(e.code),
        countryCode: _currentCountryCode,
        originalError: e,
      );
    } catch (e, stackTrace) {
      if (e is OTPException) rethrow;
      throw OTPException(
        'فشل في التحقق: ${e.toString()}',
        code: OTPErrorCode.unknownError,
        countryCode: _currentCountryCode,
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// الحصول على حالة OTP
  Future<OTPData> checkOTPStatus() async {
    try {
      _validateAuthentication();

      final callable = _functions.httpsCallable('checkOTPStatus');
      final result = await callable.call({
        'countryCode': _currentCountryCode,
      });

      final responseData = result.data as Map<String, dynamic>;
      final data = OTPData.fromMap(responseData);

      // تحديث الحالة المحلية
      if (data.remainingSeconds > 0) {
        _remainingSeconds = data.remainingSeconds;
        _remainingTimeController.add(_remainingSeconds);
      }

      _otpStatusController.add(data);

      return data;
    } on FirebaseFunctionsException catch (e) {
      throw OTPException(
        e.message ?? 'خطأ في الحصول على الحالة',
        code: e.code,
        countryCode: _currentCountryCode,
        originalError: e,
      );
    } catch (e, stackTrace) {
      if (e is OTPException) rethrow;
      throw OTPException(
        'فشل في فحص الحالة: ${e.toString()}',
        code: OTPErrorCode.unknownError,
        countryCode: _currentCountryCode,
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// إعادة إرسال OTP
  Future<int> resendOTP({bool allowAnonymous = false}) async {
    try {
      if (!allowAnonymous) {
        _validateAuthentication();
      }

      if (_currentPhoneNumber == null || _currentCountryCode == null) {
        throw OTPException(
          'لم يتم إرسال أي رمز سابقاً',
          code: OTPErrorCode.otpNotSent,
        );
      }

      // فحص التحديث الزمني
      _checkRateLimitForResend();

      final callable = _functions.httpsCallable('resendOTP');
      final result = await callable.call({
        'phoneNumber': _currentPhoneNumber,
        'countryCode': _currentCountryCode,
      });

      final responseData = result.data as Map<String, dynamic>;
      final expiresIn = responseData['expiresIn'] as int? ?? 300;

      _verifyAttempts = 0;
      _lastOTPSendTime = DateTime.now();
      _otpExpiresAt = DateTime.now().add(Duration(seconds: expiresIn));

      _startTimerMonitoring(expiresIn);

      return expiresIn;
    } on FirebaseFunctionsException catch (e) {
      throw OTPException(
        e.message ?? OTPErrorMessages.getMessage(OTPErrorCode.providerError),
        code: _mapFirebaseErrorCode(e.code),
        countryCode: _currentCountryCode,
        originalError: e,
      );
    } catch (e, stackTrace) {
      if (e is OTPException) rethrow;
      throw OTPException(
        'فشل في إعادة الإرسال: ${e.toString()}',
        code: OTPErrorCode.unknownError,
        countryCode: _currentCountryCode,
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// ==================== دوال مساعدة OTP ====================

  /// التحقق من المصادقة
  void _validateAuthentication() {
    if (!_isUserLoggedIn()) {
      throw OTPException(
        OTPErrorMessages.getMessage(OTPErrorCode.unauthenticated),
        code: OTPErrorCode.unauthenticated,
      );
    }
  }

  /// التحقق من تسجيل الدخول
  bool _isUserLoggedIn() {
    return _auth.currentUser != null;
  }

  /// اكتشاف كود الدولة من رقم الهاتف
  String? _detectCountryCode(String phoneNumber) {
    String cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    }

    // البحث عن رمز الدول المطابق
    for (final country in CountriesDatabase.getAllCountries()) {
      final dialCode = country.dialCode.replaceAll('+', '');
      if (cleaned.startsWith(dialCode)) {
        return country.countryCode;
      }
    }

    return null;
  }

  /// فحص التحديث الزمني منع الطلبات المتكررة
  void _checkRateLimit({int delaySeconds = 30}) {
    if (_lastOTPSendTime != null) {
      final elapsed = DateTime.now().difference(_lastOTPSendTime!).inSeconds;
      if (elapsed < delaySeconds) {
        throw OTPException(
          OTPErrorMessages.getMessageWithContext(
            OTPErrorCode.tooManyRequests,
            timeRemaining: delaySeconds - elapsed,
          ),
          code: OTPErrorCode.tooManyRequests,
          countryCode: _currentCountryCode,
        );
      }
    }
  }

  /// فحص التحديث الزمني لإعادة الإرسال
  void _checkRateLimitForResend({int delaySeconds = 60}) {
    _checkRateLimit(delaySeconds: delaySeconds);
  }

  /// تحويل أكواد أخطاء Firebase
  String _mapFirebaseErrorCode(String firebaseCode) {
    switch (firebaseCode) {
      case 'not-found':
        return OTPErrorCode.sessionNotFound;
      case 'permission-denied':
        return OTPErrorCode.invalidCredentials;
      case 'unauthenticated':
        return OTPErrorCode.unauthenticated;
      case 'deadline-exceeded':
        return OTPErrorCode.timeoutError;
      case 'resource-exhausted':
        return OTPErrorCode.rateLimitExceeded;
      default:
        return OTPErrorCode.providerError;
    }
  }

  /// بدء مراقبة الوقت المتبقي
  void _startTimerMonitoring(int seconds) {
    _stopTimerMonitoring();

    _remainingSeconds = seconds;
    _remainingTimeController.add(_remainingSeconds);

    _statusTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingSeconds--;
      _remainingTimeController.add(_remainingSeconds);

      if (_remainingSeconds <= 0) {
        _stopTimerMonitoring();
      }
    });
  }

  /// إيقاف مراقبة الوقت
  void _stopTimerMonitoring() {
    _statusTimer?.cancel();
    _statusTimer = null;
    _remainingSeconds = 0;
  }

  /// الحصول على البيانات الحالية
  OTPData getCurrentOTPData() {
    return OTPData(
      verified: false,
      remainingSeconds: _remainingSeconds,
      phoneNumber: _currentPhoneNumber,
      countryCode: _currentCountryCode,
      verifyAttempts: _verifyAttempts,
      maxVerifyAttempts: _maxVerifyAttempts,
      exists: _currentPhoneNumber != null,
      sentAt: _lastOTPSendTime,
      expiresAt: _otpExpiresAt,
    );
  }

  /// إعادة تعيين حالة OTP
  void resetOTP() {
    _stopTimerMonitoring();
    _currentCountryCode = null;
    _currentPhoneNumber = null;
    _verifyAttempts = 0;
    _maxVerifyAttempts = 5;
    _lastOTPSendTime = null;
    _otpExpiresAt = null;
  }

  /// تنظيف الموارد
  void dispose() {
    _stopTimerMonitoring();
    _remainingTimeController.close();
    _otpStatusController.close();
  }

  /// ==================== دوال ثابتة للدول ====================

  /// تنسيق رقم الهاتف حسب الدولة
  static String formatPhoneNumber(String phoneNumber, String countryCode) {
    final country = CountriesDatabase.getCountry(countryCode);
    if (country == null) return phoneNumber;
    return country.formatPhoneNumber(phoneNumber);
  }

  /// التحقق من صحة رقم الهاتف
  static bool isValidPhoneNumber(String phoneNumber, String countryCode) {
    final country = CountriesDatabase.getCountry(countryCode);
    if (country == null) return false;
    return country.isValidPhoneNumber(phoneNumber);
  }

  /// إخفاء رقم الهاتف
  static String maskPhoneNumber(String phoneNumber, String countryCode) {
    final country = CountriesDatabase.getCountry(countryCode);
    if (country == null) return phoneNumber;
    return country.maskPhoneNumber(phoneNumber);
  }

  /// الحصول على معلومات الدولة
  static CountryConfig? getCountryInfo(String countryCode) {
    return CountriesDatabase.getCountry(countryCode);
  }

  /// البحث عن الدول
  static List<CountryConfig> searchCountries(String query) {
    return CountriesDatabase.searchCountries(query);
  }

  /// ==================== دوال المستوى والخبرة ====================

  /// تحديث مستوى/خبرة المستخدم (Admin/System)
  static Future<Map<String, dynamic>> updateUserLevelXP(
      Map<String, dynamic> data) async {
    final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
    final callable = functions.httpsCallable('updateUserPointsXP');
    final result = await callable.call(data);
    return Map<String, dynamic>.from(result.data);
  }

  /// ==================== دوال الأدوار والصلاحيات ====================

  /// تعديل صلاحيات المستخدم (Admin/Owner)
  static Future<Map<String, dynamic>> updateUserRole(
      Map<String, dynamic> data) async {
    final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
    final callable = functions.httpsCallable('updateUserRole');
    final result = await callable.call(data);
    return Map<String, dynamic>.from(result.data);
  }
}
