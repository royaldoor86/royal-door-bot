import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DailyLoginService {
  static final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// استدعاء مكافأة تسجيل الدخول اليومي (مع Fallback لـ Firestore في حال فشل Cloud Function)
  static Future<Map<String, dynamic>> claimDailyLogin() async {
    try {
      final callable = _functions.httpsCallable('claimDailyLogin');
      final result = await callable.call();
      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      // Fallback: معالجة يدوية في Firestore في حال لم يتم رفع الـ Cloud Functions
      print(
          "DailyLogin: Cloud Function failed, using Firestore fallback. Error: $e");
      return await _claimDailyLoginFirestoreFallback();
    }
  }

  /// معالجة استلام المكافأة محلياً في Firestore لضمان استمرارية الخدمة
  static Future<Map<String, dynamic>>
      _claimDailyLoginFirestoreFallback() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول أولاً';

    final userRef = _firestore.collection('users').doc(user.uid);
    final dailyLoginRef = _firestore.collection('daily_logins').doc(user.uid);

    return await _firestore.runTransaction((transaction) async {
      final userSnap = await transaction.get(userRef);

      if (!userSnap.exists) throw 'حساب المستخدم غير موجود';

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      int streak = 1;
      DateTime? lastClaimed;

      // جلب آخر موعد استلام (ندعم كلا الحقلين للتوافق)
      final userData = userSnap.data()!;
      final ts = userData['lastClaimedAt'] ?? userData['lastDailyLogin'];
      if (ts != null) {
        lastClaimed = (ts as Timestamp).toDate();
      }

      if (lastClaimed != null) {
        final lastClaimedDay =
            DateTime(lastClaimed.year, lastClaimed.month, lastClaimed.day);
        final diffDays = today.difference(lastClaimedDay).inDays;

        if (diffDays == 0) {
          throw 'already-exists'; // تم الاستلام اليوم بالفعل
        } else if (diffDays == 1) {
          streak =
              (userData['rewardStreak'] ?? userData['dailyStreak'] ?? 0) + 1;
        } else {
          streak = 1; // انقطعت السلسلة
        }
      }

      // حساب الجائزة بناءً على اليوم
      final dayIndex = (streak - 1) % 7;
      int starReward = 0;
      int gemReward = 0;

      switch (dayIndex) {
        case 0:
          starReward = 500;
          break;
        case 1:
          starReward = 800;
          break;
        case 2:
          gemReward = 5;
          break;
        case 3:
          starReward = 1000;
          break;
        case 4:
          starReward = 1500;
          break;
        case 5:
          starReward = 2000;
          break;
        case 6:
          starReward = 2000;
          gemReward = 10;
          break;
      }

      // تحديث بيانات المستخدم (تحديث جميع الحقول المحتملة للتوحيد)
      transaction.update(userRef, {
        'stars': FieldValue.increment(starReward),
        'coins': FieldValue.increment(starReward),
        'gems': FieldValue.increment(gemReward),
        'rewardStreak': streak,
        'dailyStreak': streak,
        'lastClaimedAt': FieldValue.serverTimestamp(),
        'lastDailyLogin': FieldValue.serverTimestamp(),
      });

      // تحديث سجل الدخول اليومي
      transaction.set(
          dailyLoginRef,
          {
            'lastLogin': FieldValue.serverTimestamp(),
            'streak': streak,
          },
          SetOptions(merge: true));

      return {
        'message': 'تم استلام الكنز الملكي بنجاح! 👑',
        'streak': streak,
        'stars': starReward,
        'gems': gemReward,
      };
    });
  }

  /// التحقق مما إذا كانت المكافأة جاهزة للاستلام
  static Future<bool> isRewardReady() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return false;

      final data = doc.data();
      if (data == null) return false;

      // دعم كلا الحقلين للتوافق بين Cloud Functions و Firestore Local logic
      final lastClaimed = data['lastClaimedAt'] as Timestamp? ??
          data['lastDailyLogin'] as Timestamp?;
      if (lastClaimed == null) return true;

      final now = DateTime.now();
      final lastDate = lastClaimed.toDate();

      // السماح بالاستلام إذا بدأ يوم جديد (توقيت محلي)
      final today = DateTime(now.year, now.month, now.day);
      final lastClaimedDay =
          DateTime(lastDate.year, lastDate.month, lastDate.day);

      return today.isAfter(lastClaimedDay);
    } catch (e) {
      return false;
    }
  }

  /// مراقبة بيانات streak والنجوم ⭐ والرصيد والمستوى (ريل تايم)
  static Stream<DocumentSnapshot<Map<String, dynamic>>> userStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }
}
