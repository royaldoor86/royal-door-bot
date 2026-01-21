// Service: إدارة التحديات اليومية/الأسبوعية
// Collection: challenges, challenge_logs
// Cloud Function: manageChallenge, claimChallengeReward
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChallengesService {
  /// تحديث نقاط وخبرة المستخدم (Admin/ملكي)
  static Future<Map<String, dynamic>> updateUserPointsXP({
    required String uid,
    int? points,
    int? xp,
    int? level,
  }) async {
    final callable = _functions.httpsCallable('updateUserPointsXP');
    final result = await callable.call({
      'uid': uid,
      if (points != null) 'points': points,
      if (xp != null) 'xp': xp,
      if (level != null) 'level': level,
    });
    return Map<String, dynamic>.from(result.data);
  }

  static final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// إضافة/تعديل/حذف تحدي (Admin)
  static Future<Map<String, dynamic>> manageChallenge(
      Map<String, dynamic> data) async {
    final callable = _functions.httpsCallable('manageChallenge');
    final result = await callable.call(data);
    return Map<String, dynamic>.from(result.data);
  }

  /// استلام مكافأة تحدي (User)
  static Future<Map<String, dynamic>> claimChallengeReward(
      Map<String, dynamic> data) async {
    final callable = _functions.httpsCallable('claimChallengeReward');
    final result = await callable.call(data);
    return Map<String, dynamic>.from(result.data);
  }

  /// جلب التحديات من Firestore
  static Stream<QuerySnapshot<Map<String, dynamic>>> challengesStream() {
    return _firestore.collection('challenges').snapshots();
  }

  /// جلب سجل تحديات المستخدم
  static Stream<QuerySnapshot<Map<String, dynamic>>> userChallengeLogs(
      String uid) {
    return _firestore
        .collection('challenge_logs')
        .doc(uid)
        .collection('logs')
        .snapshots();
  }
}
