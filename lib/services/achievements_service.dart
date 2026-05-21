// Service: إدارة الإنجازات والإحصائيات
// Collection: achievements, achievements_logs, user_achievements
// Cloud Function: manageAchievement, logUserAchievement
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/achievement_model.dart';

class AchievementsService {
  static final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// جلب إحصائيات الإنجازات وسجلها للإدارة
  Future<Map<String, dynamic>> fetchAdminAchievementsStats() async {
    // جلب جميع الإنجازات
    final achievementsSnap = await _firestore.collection('achievements').get();
    final achievements = achievementsSnap.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        'title': data['title'] ?? '',
        'description': data['description'] ?? '',
        'usersCount': data['usersCount'] ?? 0,
      };
    }).toList();

    // إحصائيات عامة (عدد الإنجازات، مجموع المستخدمين الذين حققوا أي إنجاز)
    int totalAchievements = achievements.length;
    int totalUsers =
        achievements.fold(0, (acc, a) => acc + ((a['usersCount'] ?? 0) as int));

    final stats = {
      'عدد الإنجازات': totalAchievements,
      'إجمالي المستخدمين المحققين': totalUsers,
    };

    return {
      'achievements': achievements,
      'stats': stats,
    };
  }

  /// إضافة/تعديل/حذف إنجاز (Admin)
  static Future<Map<String, dynamic>> manageAchievement(
      Map<String, dynamic> data) async {
    final callable = _functions.httpsCallable('manageAchievement');
    final result = await callable.call(data);
    return Map<String, dynamic>.from(result.data);
  }

  /// تسجيل إنجاز للمستخدم (User)
  static Future<Map<String, dynamic>> logUserAchievement(
      Map<String, dynamic> data) async {
    final callable = _functions.httpsCallable('logUserAchievement');
    final result = await callable.call(data);
    return Map<String, dynamic>.from(result.data);
  }

  /// جلب الإنجازات من Firestore
  static Stream<QuerySnapshot<Map<String, dynamic>>> achievementsStream() {
    return _firestore.collection('achievements').snapshots();
  }

  /// جلب سجل إنجازات المستخدم
  static Stream<QuerySnapshot<Map<String, dynamic>>> userAchievementsLogs(
      String uid) {
    return _firestore
        .collection('achievements_logs')
        .doc(uid)
        .collection('logs')
        .snapshots();
  }

  /// جلب إنجازات المستخدم
  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserAchievements(
      String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('user_achievements')
        .snapshots();
  }

  /// التحقق من الإنجازات تلقائياً
  static Future<void> checkAndUnlockAchievements(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return;

    final userData = userDoc.data();
    final totalGems = (userData?['harvestWallet'] ?? 0).toDouble();
    final totalStars = (userData?['starsHarvestWallet'] ?? 0).toDouble();

    // جلب الباقات النشطة
    final activeRewards = await _firestore
        .collection('users')
        .doc(userId)
        .collection('active_rewards')
        .get();
    final packagesCount = activeRewards.docs.length;

    // جلب سجل الحصاد
    final harvestLogs = await _firestore
        .collection('users')
        .doc(userId)
        .collection('harvest_daily_logs')
        .orderBy('timestamp', descending: true)
        .limit(7)
        .get();

    // التحقق من الإنجازات المحددة
    final achievements = AchievementsList.defaultAchievements;

    for (final achievement in achievements) {
      final userAchievementDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('user_achievements')
          .doc(achievement.id)
          .get();

      if (userAchievementDoc.exists) continue; // الإنجاز مفتوح بالفعل

      bool shouldUnlock = false;

      switch (achievement.type) {
        case AchievementType.totalGems:
          shouldUnlock = totalGems >= achievement.targetValue;
          break;
        case AchievementType.totalStars:
          shouldUnlock = totalStars >= achievement.targetValue;
          break;
        case AchievementType.packagesOwned:
          shouldUnlock = packagesCount >= achievement.targetValue;
          break;
        case AchievementType.firstHarvest:
          shouldUnlock = harvestLogs.docs.isNotEmpty;
          break;
        case AchievementType.harvestStreak:
          // حساب أيام الحصاد المتتالية
          if (harvestLogs.docs.isNotEmpty) {
            int streak = 1;
            for (int i = 0; i < harvestLogs.docs.length - 1; i++) {
              final current =
                  harvestLogs.docs[i].data()['timestamp'] as Timestamp;
              final next =
                  harvestLogs.docs[i + 1].data()['timestamp'] as Timestamp;
              final diff = current.toDate().difference(next.toDate()).inDays;
              if (diff <= 1) {
                streak++;
              } else {
                break;
              }
            }
            shouldUnlock = streak >= achievement.targetValue;
          }
          break;
        default:
          break;
      }

      if (shouldUnlock) {
        await _unlockAchievement(userId, achievement);
      }
    }
  }

  /// فتح إنجاز
  static Future<void> _unlockAchievement(
      String userId, Achievement achievement) async {
    final userAchievementRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('user_achievements')
        .doc(achievement.id);

    await userAchievementRef.set({
      ...achievement.toMap(),
      'status': AchievementStatus.unlocked.name,
      'unlockedAt': FieldValue.serverTimestamp(),
    });

    // إضافة مكافآت الإنجاز
    if (achievement.rewardGems > 0 || achievement.rewardStars > 0) {
      await _firestore.collection('users').doc(userId).update({
        if (achievement.rewardGems > 0)
          'harvestWallet':
              FieldValue.increment(achievement.rewardGems.toDouble()),
        if (achievement.rewardStars > 0)
          'starsHarvestWallet':
              FieldValue.increment(achievement.rewardStars.toDouble()),
      });
    }

    // تسجيل في سجل الإنجازات
    await _firestore
        .collection('achievements_logs')
        .doc(userId)
        .collection('logs')
        .add({
      'achievementId': achievement.id,
      'achievementTitle': achievement.title,
      'timestamp': FieldValue.serverTimestamp(),
      'rewardGems': achievement.rewardGems,
      'rewardStars': achievement.rewardStars,
    });
  }

  /// مطالبة بمكافآت الإنجاز
  static Future<void> claimAchievementReward(
      String userId, String achievementId) async {
    final userAchievementRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('user_achievements')
        .doc(achievementId);

    final doc = await userAchievementRef.get();
    if (!doc.exists) return;

    final data = doc.data();
    final status = data?['status'];

    if (status == AchievementStatus.unlocked.name) {
      await userAchievementRef.update({
        'status': AchievementStatus.claimed.name,
        'claimedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// حساب تقدم الإنجاز
  static Future<double> getAchievementProgress(
      String userId, Achievement achievement) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    if (!userDoc.exists) return 0.0;

    final userData = userDoc.data();
    double currentValue = 0.0;

    switch (achievement.type) {
      case AchievementType.totalGems:
        currentValue = (userData?['harvestWallet'] ?? 0).toDouble();
        break;
      case AchievementType.totalStars:
        currentValue = (userData?['starsHarvestWallet'] ?? 0).toDouble();
        break;
      case AchievementType.packagesOwned:
        final activeRewards = await _firestore
            .collection('users')
            .doc(userId)
            .collection('active_rewards')
            .get();
        currentValue = activeRewards.docs.length.toDouble();
        break;
      case AchievementType.firstHarvest:
        final harvestLogs = await _firestore
            .collection('users')
            .doc(userId)
            .collection('harvest_daily_logs')
            .get();
        currentValue = harvestLogs.docs.isEmpty ? 0.0 : 1.0;
        break;
      case AchievementType.harvestStreak:
        final harvestLogs = await _firestore
            .collection('users')
            .doc(userId)
            .collection('harvest_daily_logs')
            .orderBy('timestamp', descending: true)
            .limit(7)
            .get();
        if (harvestLogs.docs.isNotEmpty) {
          int streak = 1;
          for (int i = 0; i < harvestLogs.docs.length - 1; i++) {
            final current =
                harvestLogs.docs[i].data()['timestamp'] as Timestamp;
            final next =
                harvestLogs.docs[i + 1].data()['timestamp'] as Timestamp;
            final diff = current.toDate().difference(next.toDate()).inDays;
            if (diff <= 1) {
              streak++;
            } else {
              break;
            }
          }
          currentValue = streak.toDouble();
        }
        break;
      default:
        currentValue = 0.0;
    }

    return (currentValue / achievement.targetValue).clamp(0.0, 1.0);
  }
}
