import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';
import '../models/user_model.dart';
import 'user_bootstrap_service.dart';
import 'dart:math';
import 'fcm_service.dart';
import 'otp_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signOut() async {
    try {
      await FcmService.unregisterTokenForCurrentUser();
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {/* ignore */}
  }

  Future<User?> registerWithEmail(
      String email, String password, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;

      if (user != null) {
        final randomRoyalId =
            (10000000 + Random().nextInt(90000000)).toString();

        UserModel newUser = UserModel(
          uid: user.uid,
          royalId: randomRoyalId,
          name: name,
          email: email,
        );
        await _firestoreService.saveUser(newUser);
        await UserBootstrapService.bootstrapUser();
        await FcmService.registerTokenForCurrentUser();
      }
      return user;
    } catch (e) {
      return null;
    }
  }

  Future<String?> loginWithGoogle() async {
    try {
      // إجبار النظام على إظهار قائمة اختيار الحسابات عبر تسجيل الخروج أولاً
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return "CANCELLED";

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;

      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (!userDoc.exists) {
          final randomRoyalId =
              (10000000 + Random().nextInt(90000000)).toString();
          UserModel newUser = UserModel(
            uid: user.uid,
            royalId: randomRoyalId,
            name: user.displayName ?? "مستخدم جوجل",
            email: user.email ?? "",
            profilePic: user.photoURL ?? "",
          );
          await _firestoreService.saveUser(newUser);
        }
        await UserBootstrapService.bootstrapUser();
        await FcmService.registerTokenForCurrentUser();
        return null;
      }
      return "فشل الدخول";
    } catch (e) {
      return e.toString();
    }
  }

  // --- دوال التحقق من البريد المفقودة ---

  Future<bool> refreshEmailVerified() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      await user.reload(); // تحديث حالة المستخدم من السيرفر
      return _auth.currentUser?.emailVerified ?? false;
    } catch (e) {
      print("Error refreshing email: $e");
      return false;
    }
  }

  Future<String?> sendVerificationEmailAgain() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return "لا يوجد مستخدم مسجل";
      await user.sendEmailVerification();
      return null; // نجاح
    } catch (e) {
      return e.toString();
    }
  }

  // --- دوال تسجيل الدخول بالهاتف ---

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
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<User?> signInWithPhone(String verificationId, String smsCode) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;

      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (!userDoc.exists) {
          final randomRoyalId =
              (10000000 + Random().nextInt(90000000)).toString();
          UserModel newUser = UserModel(
            uid: user.uid,
            royalId: randomRoyalId,
            name: "مستخدم ملكي",
            email: "",
          );
          await _firestoreService.saveUser(newUser);
        }
        await UserBootstrapService.bootstrapUser();
        await FcmService.registerTokenForCurrentUser();
      }
      return user;
    } catch (e) {
      print("Phone Login Error: $e");
      return null;
    }
  }

  Future<void> linkPhoneCredential(PhoneAuthCredential credential) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.linkWithCredential(credential);
    }
  }

  // ==================== دوال OTP ====================

  final OTPService _otpService = OTPService();

  /// إرسال OTP إلى رقم الهاتف
  Future<int> sendPhoneOTP(String phoneNumber, {bool isLogin = false}) async {
    try {
      return await _otpService.sendOTP(phoneNumber, isLogin: isLogin);
    } catch (e) {
      print("Error sending OTP: $e");
      rethrow;
    }
  }

  /// التحقق من رمز OTP
  Future<bool> verifyPhoneOTP(String otp, {required String phoneNumber}) async {
    try {
      return await _otpService.verifyOTP(otp, phoneNumber: phoneNumber);
    } catch (e) {
      print("Error verifying OTP: $e");
      rethrow;
    }
  }

  /// فحص حالة OTP الحالية
  Future<OTPData> checkPhoneOTPStatus() async {
    try {
      return _otpService.checkOTPStatus();
    } catch (e) {
      print("Error checking OTP status: $e");
      rethrow;
    }
  }

  /// إعادة إرسال OTP
  Future<int> resendPhoneOTP() async {
    try {
      return await _otpService.resendOTP();
    } catch (e) {
      print("Error resending OTP: $e");
      rethrow;
    }
  }

  /// تحديث رقم الهاتف المُتحقق منه في Firestore
  Future<void> updateVerifiedPhoneNumber(String phoneNumber) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestoreService.updateSingleField(
          user.uid,
          'phoneNumber',
          phoneNumber,
        );
        await _firestoreService.updateSingleField(
          user.uid,
          'phoneVerified',
          true,
        );
        await _firestoreService.updateSingleField(
          user.uid,
          'phoneVerifiedAt',
          DateTime.now(),
        );
      }
    } catch (e) {
      print("Error updating phone number: $e");
    }
  }
}
