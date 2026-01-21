import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';
import '../models/user_model.dart';
import 'user_bootstrap_service.dart';
import 'dart:math';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // جلب المستخدم الحالي
  User? get currentUser => _auth.currentUser;

  // مراقبة حالة تسجيل الدخول
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// تسجيل الخروج الحقيقي من كافة المنصات
  Future<void> signOut() async {
    try {
      if (await GoogleSignIn().isSignedIn()) {
        await GoogleSignIn().signOut();
      }
      await FacebookAuth.instance.logOut();
      await _auth.signOut();
    } catch (e) {
      print("Error signing out: $e");
    }
  }

  /// تسجيل الدخول أو إنشاء حساب
  Future<User?> registerWithEmail(String email, String password, String name) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      
      if (user != null) {
        // توليد ايدي ملكي عشوائي للمستخدم الجديد فوراً
        final randomRoyalId = (10000000 + Random().nextInt(90000000)).toString();
        
        UserModel newUser = UserModel(
          uid: user.uid,
          royalId: randomRoyalId,
          name: name,
          email: email,
        );
        await _firestoreService.saveUser(newUser);
        
        // تشغيل خدمة التأسيس لضمان إنشاء باقي السجلات (المحفظة، الإعدادات...)
        await UserBootstrapService.bootstrapUser();
      }
      return user;
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  /// تسجيل الدخول عبر جوجل مع حفظ البيانات
  Future<String?> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return "تم إلغاء العملية من المستخدم.";

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;

      if (user != null) {
        // التأكد من وجود المستخدم في قاعدة البيانات أولاً قبل محاولة الحفظ
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        
        if (!userDoc.exists) {
          // مستخدم جديد تماماً
          final randomRoyalId = (10000000 + Random().nextInt(90000000)).toString();
          UserModel newUser = UserModel(
            uid: user.uid,
            royalId: randomRoyalId,
            name: user.displayName ?? "مستخدم جوجل",
            email: user.email ?? "",
            profilePic: user.photoURL ?? "",
          );
          await _firestoreService.saveUser(newUser);
        } else {
          // المستخدم موجود مسبقاً: لا نلمس الـ royalId أبداً
          // فقط نحدث الاسم والصورة إذا رغبنا (اختياري)
          await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
            'lastActive': FieldValue.serverTimestamp(),
          });
        }
        
        // تشغيل خدمة التأسيس لضمان اكتمال كافة البيانات
        await UserBootstrapService.bootstrapUser();
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? "فشل تسجيل الدخول عبر Google.";
    } catch (e) {
      return e.toString();
    }
  }

  Future<bool> refreshEmailVerified() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      await user.reload();
      final fresh = _auth.currentUser;
      return fresh?.emailVerified ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<String?> sendVerificationEmailAgain() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return 'لا يوجد مستخدم مسجّل';
      await user.sendEmailVerification();
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
