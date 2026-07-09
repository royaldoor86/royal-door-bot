import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BadgeService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// تفعيل شارة للمستخدم وإضافتها لمقتنياته بشكل حقيقي
  static Future<void> equipBadge({
    required String badgeName,
    required String badgeIcon,
    required String category,
    required bool isImage,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول أولاً';

    final userRef = _db.collection('users').doc(user.uid);
    final inventoryRef = userRef.collection('inventory');

    await _db.runTransaction((transaction) async {
      // 1. تحديث الشارة النشطة في ملف المستخدم
      transaction.update(userRef, {'activeBadge': badgeIcon});

      // 2. التحقق من وجود الشارة في المقتنيات
      final invQuery =
          await inventoryRef.where('icon', isEqualTo: badgeIcon).get();

      if (invQuery.docs.isEmpty) {
        // إذا لم تكن موجودة، نضيفها (مثل أعلام الدول المجانية)
        final newBadgeDoc = inventoryRef.doc();
        transaction.set(newBadgeDoc, {
          'type': 'badge',
          'name': badgeName,
          'icon': badgeIcon,
          'category': category,
          'isImage': isImage,
          'acquiredAt': FieldValue.serverTimestamp(),
          'isPermanent': true,
        });
      }
    });
  }

  /// التحقق من استحقاق شارات الإنجاز التلقائية (مثل ليفل معين أو عدد هدايا)
  static Future<void> checkAndGrantAchievementBadges(
      Map<String, dynamic> userData) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final int userLevel = (userData['userLevel'] ?? 1).toInt();
    final String vipRank = userData['vipRank'] ?? '';

    // مثال: شارة "الملك الذهبي" لمن يصل لليفل 20 أو لديه اشتراك رويال
    if (userLevel >= 20 || vipRank == 'Royal Door') {
      await _grantBadgeIfMissing(uid, 'الملك الذهبي', '👑', 'badge');
    }

    // مثال: شارة "درع رويال" للمشتركين في VIP
    if (vipRank.isNotEmpty) {
      await _grantBadgeIfMissing(uid, 'درع رويال', '🛡️', 'badge');
    }
  }

  static Future<void> _grantBadgeIfMissing(
      String uid, String name, String icon, String category) async {
    final invRef = _db.collection('users').doc(uid).collection('inventory');
    final query = await invRef.where('icon', isEqualTo: icon).get();

    if (query.docs.isEmpty) {
      await invRef.add({
        'type': 'badge',
        'name': name,
        'icon': icon,
        'category': category,
        'isImage': false,
        'acquiredAt': FieldValue.serverTimestamp(),
        'isPermanent': true,
      });
    }
  }
}
