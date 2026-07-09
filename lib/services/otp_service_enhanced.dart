import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../models/country_config.dart';
import '../core/constants/countries.dart';
import '../core/constants/otp_error_codes.dart';

/// كلاس استثناء OTP محسّن مع دعم الدول
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
  bool isExpiringsoon() {
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

/// خدمة OTP محسّنة مع دعم 96 دولة
class OTPService {
  static final OTPService _instance = OTPService._internal();

  factory OTPService() {
    return _instance;
  }

  OTPService._internal() {
    _initializeFirebase();
  }

  late FirebaseFunctions _functions;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // متغيرات الحالة
  Timer? _statusTimer;
  int _remainingSeconds = 0;
  String? _currentCountryCode;
  String? _currentPhoneNumber;
  int _verifyAttempts = 0;
  int _maxVerifyAttempts = 5;
  DateTime? _lastOTPSendTime;
  DateTime? _otpExpiresAt;

  // Streams
  late StreamController<int> _remainingTimeController;
  late StreamController<OTPData> _otpStatusController;

  void _initializeFirebase() {
    _functions = FirebaseFunctions.instance;
    _remainingTimeController = StreamController<int>.broadcast();
    _otpStatusController = StreamController<OTPData>.broadcast();
  }

  /// Stream لمراقبة الوقت المتبقي
  Stream<int> get remainingTimeStream => _remainingTimeController.stream;

  /// Stream لمراقبة حالة OTP
  Stream<OTPData> get otpStatusStream => _otpStatusController.stream;

  /// ==================== الدوال الأساسية ====================

  /// إرسال OTP إلى رقم الهاتف مع دعم الدول
  Future<int> sendOTP(String phoneNumber, {String? countryCode, bool allowAnonymous = false}) async {
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

      // الحصول على بيانات الدولة
      final country = CountriesDatabase.getCountry(countryCode);
      if (country == null) {
        throw OTPException(
          OTPErrorMessages.getMessage(OTPErrorCode.unsupportedCountry),
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
        'phoneNumber': _currentPhoneNumber, // إضافة رقم الهاتف لربط الجلسة
        'countryCode': _currentCountryCode,
      });

      final responseData = result.data as Map<String, dynamic>;
      final verified = responseData['verified'] as bool? ?? false;

      if (verified) {
        _stopTimerMonitoring();
        _verifyAttempts = 0;
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

  /// ==================== دوال المساعدة ====================

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

  /// ==================== دوال عامة ====================

  /// الحصول على البيانات الحالية
  OTPData getCurrentData() {
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

  /// إعادة تعيين الحالة
  void reset() {
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

  /// ==================== دوال ثابتة ====================

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
}
