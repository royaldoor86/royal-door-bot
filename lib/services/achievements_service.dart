// Service: إدارة الإنجازات والإحصائيات
// Collection: achievements, achievements_logs
// Cloud Function: manageAchievement, logUserAchievement
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AchievementsService {
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

  static final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
}
