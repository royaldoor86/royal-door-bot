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
      final currentGems = (userData?['harvestWallet'] ?? 0).toDouble();

      if (currentGems < package.price) {
        throw Exception('رصيد الجواهر غير كافٍ');
      }

      // خصم المبلغ
      transaction.update(userRef, {
        'harvestWallet': FieldValue.increment(-package.price),
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

  /// تحديث نقاط النشاط
  static Future<void> addActivityPoints(String userId, int points) async {
    final userRef = _firestore.collection('users').doc(userId);
    final userDoc = await userRef.get();

    if (!userDoc.exists) return;

    final userData = userDoc.data();
    final vipData = userData?['vip_status'] as Map<String, dynamic>?;
    final currentActivityPoints = vipData?['activityPoints'] ?? 0;
    final newActivityPoints = currentActivityPoints + points;

    // التحقق من الترقية التلقائية
    VIPLevel newLevel = VIPLevel.none;
    if (vipData != null) {
      newLevel = _parseLevel(vipData['level']);
    }

    if (newActivityPoints >= 50000 && newLevel != VIPLevel.platinum) {
      newLevel = VIPLevel.platinum;
    } else if (newActivityPoints >= 15000 && newLevel != VIPLevel.gold) {
      newLevel = VIPLevel.gold;
    } else if (newActivityPoints >= 5000 && newLevel != VIPLevel.silver) {
      newLevel = VIPLevel.silver;
    } else if (newActivityPoints >= 1000 && newLevel != VIPLevel.bronze) {
      newLevel = VIPLevel.bronze;
    }

    await userRef.update({
      'vip_status.activityPoints': newActivityPoints,
      if (newLevel != VIPLevel.none) 'vip_status.level': newLevel.name,
      if (newLevel != VIPLevel.none && vipData == null)
        'vip_status.activatedAt': FieldValue.serverTimestamp(),
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

  /// حساب مكافأة الحصاد بناءً على مستوى VIP
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
