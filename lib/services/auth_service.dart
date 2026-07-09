import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:twitter_login/twitter_login.dart';
import 'package:flutter/foundation.dart';
import 'firestore_service.dart';
import '../models/user_model.dart';
import 'user_bootstrap_service.dart';
import 'dart:math';
import 'fcm_service.dart';

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
      await _googleSignIn.signOut();
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return "CANCELLED";
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
      await _auth.signInWithCredential(credential);
      await UserBootstrapService.bootstrapUser();
      await FcmService.registerTokenForCurrentUser();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> loginWithFacebook() async {
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.cancelled) return "CANCELLED";
      if (result.status == LoginStatus.failed) {
        return "فشل فيسبوك: ${result.message}";
      }
      final OAuthCredential credential =
          FacebookAuthProvider.credential(result.accessToken!.token);
      await _auth.signInWithCredential(credential);
      await UserBootstrapService.bootstrapUser();
      await FcmService.registerTokenForCurrentUser();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// تسجيل الدخول بـ Twitter
  Future<String?> loginWithTwitter() async {
    try {
      debugPrint("🚀 محاولة تسجيل الدخول بتويتر...");

      // إنشاء كائن TwitterLogin
      final twitterLogin = TwitterLogin(
        apiKey: "LtQWuusMVrralZV6608FPWFHx",
        apiSecretKey: "yUOO8tjVMf3Y5jyNkGI6FrQPww5bDyyZ8IU8Or84RFBHomhujl",
        redirectURI: "royaldoor://",
      );

      // محاولة تسجيل الدخول
      final authResult = await twitterLogin.login();

      // التحقق من حالة النتيجة
      if (authResult.status != TwitterLoginStatus.loggedIn) {
        if (authResult.status == TwitterLoginStatus.cancelledByUser) {
          return "CANCELLED";
        }
        debugPrint("❌ خطأ تويتر: ${authResult.errorMessage}");
        return "خطأ: ${authResult.errorMessage}";
      }

      // الحصول على بيانات المستخدم
      final twitterUser = authResult.user;
      if (twitterUser == null) {
        return "فشل الحصول على بيانات المستخدم";
      }

      debugPrint("✅ تم تسجيل الدخول بتويتر: ${twitterUser.name}");

      // التأكد من وجود جلسة Firebase
      User? firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        try {
          await _auth.signInAnonymously();
          firebaseUser = _auth.currentUser;
        } catch (e) {
          debugPrint("خطأ في Anonymous Auth: $e");
          return "فشل إنشاء جلسة";
        }
      }

      if (firebaseUser == null) {
        return "فشل إنشاء جلسة Firebase";
      }

      final uid = firebaseUser.uid;

      // التحقق من وجود المستخدم
      final userDocSnapshot =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (!userDocSnapshot.exists) {
        // إنشاء حساب جديد
        final newRoyalId = (10000000 + Random().nextInt(90000000)).toString();
        final newUser = UserModel(
          uid: uid,
          royalId: newRoyalId,
          name: twitterUser.name ?? "مستخدم تويتر",
          email: twitterUser.email ?? "twitter_${twitterUser.id}@royaldoor.app",
          profilePic: twitterUser.thumbnailImage ?? "",
        );
        await _firestoreService.saveUser(newUser);
        debugPrint("✅ تم إنشاء حساب جديد");
      }

      // تحديث معلومات Twitter
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'lastTwitterLogin': FieldValue.serverTimestamp(),
        'twitterHandle': twitterUser.screenName ?? "",
        'twitterId': twitterUser.id.toString(),
      });

      // تحضير البيانات الإضافية
      await UserBootstrapService.bootstrapUser();
      await FcmService.registerTokenForCurrentUser();

      return null;
    } catch (e) {
      debugPrint("🔥 خطأ في Twitter Login: $e");
      return "خطأ: ${e.toString()}";
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
        await _firestoreService.updateSingleField(
            user.uid, 'phoneNumber', phoneNumber);
        await _firestoreService.updateSingleField(
            user.uid, 'phoneVerified', true);
        await _firestoreService.updateSingleField(
            user.uid, 'phoneVerifiedAt', DateTime.now());
      }
    } catch (e) {
      debugPrint("Error updating phone: $e");
    }
  }
}
