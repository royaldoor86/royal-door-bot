import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vip_model.dart';

class VIPService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static VIPLevel _parseLevel(String? level) {
    if (level == null) return VIPLevel.none;
    return VIPLevel.values.firstWhere(
      (e) => e.name == level,
      orElse: () => VIPLevel.none,
    );
  }

  /// جلب حالة VIP للمستخدم
  static Future<VIPStatus> getUserVIPStatus(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) {
      return VIPStatus(level: VIPLevel.none);
    }

    final data = doc.data();
    final vipData = data?['vip_status'] as Map<String, dynamic>?;

    if (vipData == null) {
      return VIPStatus(level: VIPLevel.none);
    }

    return VIPStatus.fromMap(vipData);
  }

  /// شراء باقة VIP
  static Future<void> purchaseVIPPackage(
    String userId,
    VIPPackage package,
  ) async {
    await _firestore.runTransaction((transaction) async {
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await transaction.get(userRef);

      if (!userDoc.exists) throw Exception('المستخدم غير موجود');

      final userData = userDoc.data();
      final currentGems =
          (userData?['rewardGems'] ?? userData?['harvestWallet'] ?? 0)
              .toDouble();

      if (currentGems < package.price) {
        throw Exception('رصيد الجواهر غير كافٍ');
      }

      // خصم المبلغ
      transaction.update(userRef, {
        'rewardGems': FieldValue.increment(-package.price),
        'harvestWallet': FieldValue.increment(-package.price), // للتوافقية
      });

      // تحديث حالة VIP
      final expiresAt =
          DateTime.now().add(Duration(days: package.durationDays));
      transaction.update(userRef, {
        'vip_status': {
          'level': package.level.name,
          'activatedAt': FieldValue.serverTimestamp(),
          'expiresAt': Timestamp.fromDate(expiresAt),
          'totalSpent': FieldValue.increment(package.price.toInt()),
        },
      });

      // تسجيل في سجل عمليات VIP
      final vipLogRef = userRef.collection('vip_logs').doc();
      transaction.set(vipLogRef, {
        'packageId': package.id,
        'packageName': package.name,
        'level': package.level.name,
        'price': package.price,
        'currency': package.currency,
        'durationDays': package.durationDays,
        'activatedAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiresAt),
      });
    });
  }

  /// تحديث نقاط النشاط (ملاحظة: الترقية التلقائية معطلة - VIP فقط بالشراء)
  static Future<void> addActivityPoints(String userId, int points) async {
    final userRef = _firestore.collection('users').doc(userId);
    final userDoc = await userRef.get();

    if (!userDoc.exists) return;

    final userData = userDoc.data();
    final vipData = userData?['vip_status'] as Map<String, dynamic>?;
    final currentActivityPoints = vipData?['activityPoints'] ?? 0;
    final newActivityPoints = currentActivityPoints + points;

    // تحديث نقاط النشاط فقط بدون ترقية تلقائية
    await userRef.update({
      'vip_status.activityPoints': newActivityPoints,
    });
  }

  /// التحقق من انتهاء VIP
  static Future<void> checkVIPExpiry(String userId) async {
    final userRef = _firestore.collection('users').doc(userId);
    final userDoc = await userRef.get();

    if (!userDoc.exists) return;

    final userData = userDoc.data();
    final vipData = userData?['vip_status'] as Map<String, dynamic>?;

    if (vipData == null) return;

    final expiresAt = (vipData['expiresAt'] as Timestamp?)?.toDate();
    if (expiresAt != null && DateTime.now().isAfter(expiresAt)) {
      // VIP منتهي - إعادة إلى none
      await userRef.update({
        'vip_status.level': VIPLevel.none.name,
      });
    }
  }

  /// حساب مكافأة المكافآت بناءً على مستوى VIP
  static double calculateHarvestBonus(VIPStatus vipStatus) {
    return vipStatus.harvestBonus;
  }

  /// حساب مكافأة التحويل بناءً على مستوى VIP
  static double calculateConversionBonus(VIPStatus vipStatus) {
    return vipStatus.conversionBonus;
  }

  /// التحقق من الحد الأقصى للباقات النشطة
  static Future<bool> canAddPackage(String userId, int currentCount) async {
    final vipStatus = await getUserVIPStatus(userId);
    return currentCount < vipStatus.maxActivePackages;
  }

  /// جلب سجل عمليات VIP
  static Stream<QuerySnapshot<Map<String, dynamic>>> getVIPLogs(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('vip_logs')
        .orderBy('activatedAt', descending: true)
        .snapshots();
  }
}
