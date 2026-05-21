import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/rewards_models.dart';
import '../constants/rewards_constants.dart';
import 'notifications_service.dart';
import 'audit_log_service.dart';

/// خدمة إدارة نظام المكافآت المحسن بالأمان
class RewardsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final AuditLogService _auditService = AuditLogService();

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll('%', '')) ?? 0.0;
    }
    return 0.0;
  }

  String? get currentUserUid => _auth.currentUser?.uid;

  String _formatNumber(num number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toStringAsFixed(0);
  }

  /// جلب إعدادات المكافآت من Firestore
  Future<Map<String, dynamic>> getRewardsSettings() async {
    try {
      final doc = await _firestore
          .collection(RewardsConstants.collectionSettings)
          .doc(RewardsConstants.collectionConfig)
          .get();
      if (doc.exists) {
        return doc.data()!;
      }
    } catch (e) {
      debugPrint('Error fetching rewards settings: $e');
    }
    // إعدادات افتراضية في حال فشل الجلب أو عدم وجود الوثيقة
    return {
      RewardsConstants.configExchangeRate: 2500,
      RewardsConstants.configMinRedemption: 150000.0,
      RewardsConstants.configIsMaintenance: false,
      RewardsConstants.configTransferFee: 0.05,
    };
  }

  /// جلب الحزم المتاحة
  Future<List<RewardPackage>> getAvailablePackages() async {
    try {
      final snapshot = await _firestore
          .collection(RewardsConstants.collectionPackages)
          .where('isActive', isEqualTo: true)
          .orderBy('sortOrder')
          .get();

      return snapshot.docs
          .map((doc) => RewardPackage.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error fetching reward packages: $e');
      return [];
    }
  }

  /// جلب حزمة معينة بواسطة معرفها
  Future<RewardPackage?> getPackageById(String packageId) async {
    try {
      final doc = await _firestore
          .collection(RewardsConstants.collectionPackages)
          .doc(packageId)
          .get();
      if (doc.exists) {
        return RewardPackage.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      debugPrint('Error fetching package $packageId: $e');
    }
    return null;
  }

  /// الحصول على المكافآت النشطة للمستخدم
  Stream<List<ActiveReward>> getActiveRewards(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection(RewardsConstants.collectionActiveRewards)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ActiveReward.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// الحصول على المكافآت المكتملة للمستخدم
  Stream<List<CompletedReward>> getCompletedRewards(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection(RewardsConstants.collectionCompletedRewards)
        .snapshots()
        .map((snapshot) {
      final rewards = snapshot.docs
          .map((doc) => CompletedReward.fromMap(doc.data(), doc.id))
          .toList();

      // Sort in-memory
      rewards.sort((a, b) => b.completedAt.compareTo(a.completedAt));
      return rewards;
    });
  }

  /// جلب طلبات السحب الخاصة بمستخدم معين
  Stream<List<RedemptionRequest>> getRedemptionRequests(String userId) {
    return _firestore
        .collection(RewardsConstants.collectionRedemptions)
        .where(RewardsConstants.fieldUserId, isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final requests = snapshot.docs
          .map((doc) => RedemptionRequest.fromMap(doc.data(), doc.id))
          .toList();
      // فرز يدوي لتجنب الحاجة لفهرس مركب (Index)
      requests.sort((a, b) => b.requestDate.compareTo(a.requestDate));
      return requests;
    });
  }

  /// جلب كافة طلبات السحب بناءً على الحالة (للإدارة)
  Stream<List<RedemptionRequest>> getAllRedemptionsByStatus(String status) {
    return _firestore
        .collection(RewardsConstants.collectionRedemptions)
        .where(RewardsConstants.fieldStatus, isEqualTo: status)
        .snapshots()
        .map((snapshot) {
      final requests = snapshot.docs
          .map((doc) => RedemptionRequest.fromMap(doc.data(), doc.id))
          .toList();
      // فرز يدوي لتجنب الحاجة لفهرس مركب (Index)
      requests.sort((a, b) => b.requestDate.compareTo(a.requestDate));
      return requests;
    });
  }

  /// جلب كافة طلبات السحب بناءً على Royal ID (للإدارة)
  Stream<List<RedemptionRequest>> getAllRedemptionsByRoyalId(String royalId) {
    return _firestore
        .collection(RewardsConstants.collectionRedemptions)
        .where('userRoyalId', isEqualTo: royalId)
        .snapshots()
        .map((snapshot) {
      final requests = snapshot.docs
          .map((doc) => RedemptionRequest.fromMap(doc.data(), doc.id))
          .toList();
      // فرز يدوي لتجنب الحاجة لفهرس مركب (Index)
      requests.sort((a, b) => b.requestDate.compareTo(a.requestDate));
      return requests;
    });
  }

  /// جلب سجل العمولات المحصلة من السوق لفترة محددة (للإدارة)
  Stream<List<Map<String, dynamic>>> getMarketplaceCommissionsByDateRange(
      DateTime start, DateTime end) {
    return _firestore
        .collection('admin_logs')
        .where('action', isEqualTo: 'MARKETPLACE_SALE_FEE')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .snapshots()
        .map((snapshot) {
      final logs = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      // فرز يدوي
      logs.sort((a, b) =>
          (b['timestamp'] as Timestamp).compareTo(a['timestamp'] as Timestamp));
      return logs;
    });
  }

  /// التحقق من قيود معدل الطلبات (Rate Limiting)
  Future<void> _checkRateLimit(String userId, String action) async {
    final now = DateTime.now();
    final windowStart = now.subtract(RewardsConstants.rateLimitWindow);
    final dayStart = DateTime(now.year, now.month, now.day);

    final limitDoc = await _firestore
        .collection(RewardsConstants.collectionRateLimits)
        .doc('${userId}_$action')
        .get();

    if (limitDoc.exists) {
      final data = limitDoc.data()!;
      final List<dynamic> timestamps = data['timestamps'] ?? [];
      final List<DateTime> dates =
          timestamps.map((t) => (t as Timestamp).toDate()).toList();

      // 1. فحص الحد اليومي (Max 10 per day)
      final dailyRequests = dates.where((t) => t.isAfter(dayStart)).length;
      if (dailyRequests >= RewardsConstants.maxDailyRequests) {
        throw RewardsException(
            'لقد تجاوزت الحد الأقصى للطلبات اليومية (10 طلبات).');
      }

      // 2. فحص نافذة الساعة (Max 5 per hour)
      final recentRequests =
          dates.where((t) => t.isAfter(windowStart)).toList();
      if (recentRequests.length >= RewardsConstants.rateLimitMaxRequests) {
        throw RewardsException(RewardsConstants.errorRateLimitExceeded);
      }

      // تحديث القائمة
      dates.add(now);
      await limitDoc.reference.set({
        'timestamps': dates.map((t) => Timestamp.fromDate(t)).toList(),
        'lastUpdate': FieldValue.serverTimestamp(),
      });
    } else {
      await _firestore
          .collection(RewardsConstants.collectionRateLimits)
          .doc('${userId}_$action')
          .set({
        'timestamps': [Timestamp.fromDate(now)],
        'lastUpdate': FieldValue.serverTimestamp(),
      });
    }
  }

  /// التحقق من حالة الصيانة (Maintenance Mode)
  Future<void> _checkMaintenance() async {
    final settings = await getRewardsSettings();
    final bool isMaintenance =
        settings[RewardsConstants.configIsMaintenance] ?? false;

    if (isMaintenance) {
      throw RewardsException(
          'النظام في وضع الصيانة حالياً. يرجى المحاولة لاحقاً.');
    }
  }

  /// طلب تحويل مكافأة (معطل للامتثال لسياسات المتجر)
  Future<void> requestRedemption({
    required double amount,
    required String currency,
    required String method,
    required String wallet,
    required String phone,
    required String otpCode,
  }) async {
    throw RewardsException('هذه الميزة غير متوفرة حالياً في هذا الإصدار.');
  }

  /// قبول طلب تحويل (معطل)
  Future<void> approveRedemption(String requestId) async {
    throw RewardsException('العملية غير مسموح بها حالياً.');
  }

  /// رفض طلب تحويل (معطل)
  Future<void> rejectRedemption(String requestId, String reason) async {
    throw RewardsException('العملية غير مسموح بها حالياً.');
  }

  /// جلب العروض النشطة من السوق
  Stream<List<Map<String, dynamic>>> getActiveListings() {
    return _firestore
        .collection('reward_marketplace')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      final listings = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      // فرز يدوي
      listings.sort((a, b) =>
          (b['createdAt'] as Timestamp).compareTo(a['createdAt'] as Timestamp));
      return listings;
    });
  }

  /// شراء مكافأة من السوق (عبر Cloud Function للأمان)
  Future<void> purchaseFromMarketplace(String listingId) async {
    final buyerId = _auth.currentUser?.uid;
    if (buyerId == null) throw RewardsException('يجب تسجيل الدخول أولاً');

    await _checkMaintenance();

    try {
      // استدعاء الـ Cloud Function لضمان أمان العملية ومنع التلاعب
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');
      final result = await functions
          .httpsCallable('purchaseRewardFromMarketplace')
          .call({'listingId': listingId});

      if (result.data['success'] != true) {
        throw RewardsException(result.data['message'] ?? 'فشلت عملية الشراء');
      }
    } catch (e) {
      debugPrint('Error purchasing from marketplace: $e');
      if (e is FirebaseFunctionsException) {
        throw RewardsException(e.message ?? 'حدث خطأ في السيرفر الملكي');
      }
      rethrow;
    }
  }

  /// جلب العروض الخاصة بالمستخدم الحالي فقط
  Stream<List<Map<String, dynamic>>> getUserListings() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('reward_marketplace')
        .where('sellerId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final listings = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
      // فرز يدوي
      listings.sort((a, b) =>
          (b['createdAt'] as Timestamp).compareTo(a['createdAt'] as Timestamp));
      return listings;
    });
  }

  /// إلغاء عرض تداول (حذفه أو تغيير حالته)
  Future<void> cancelListing(String listingId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw RewardsException('يجب تسجيل الدخول أولاً');

    await _firestore.runTransaction((transaction) async {
      final listingRef =
          _firestore.collection('reward_marketplace').doc(listingId);
      final listingDoc = await transaction.get(listingRef);

      if (!listingDoc.exists) throw RewardsException('العرض غير موجود');

      final data = listingDoc.data()!;
      if (data['sellerId'] != userId) {
        throw RewardsException('لا تملك صلاحية إلغاء هذا العرض');
      }

      if (data['status'] != 'active') {
        throw RewardsException('لا يمكن إلغاء عرض غير نشط');
      }

      final rewardId = data['rewardId'];

      // 1. إعادة حالة المكافأة للأصل عند المستخدم
      final rewardRef = _firestore
          .collection('users')
          .doc(userId)
          .collection(RewardsConstants.collectionActiveRewards)
          .doc(rewardId);

      transaction.update(rewardRef, {
        'status': 'active',
        'listingId': FieldValue.delete(),
      });

      // 2. حذف العرض من السوق (أو تغيير حالته لـ cancelled)
      transaction.update(listingRef, {
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });

      // تسجيل في Audit Log
      await _auditService.logEvent(
        action: 'marketplace_cancel',
        eventType: AuditEventType.paymentProcessed,
        severity: AuditSeverity.low,
        details: {
          'listingId': listingId,
          'rewardId': rewardId,
          'userId': userId,
        },
      );
    });
  }

  /// تحديث بيانات العرض (السعر أو العملة)
  Future<void> updateTradeListing({
    required String listingId,
    required double newPrice,
    required String newCurrency,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw RewardsException('يجب تسجيل الدخول أولاً');

    await _checkMaintenance();

    await _firestore.runTransaction((transaction) async {
      final listingRef =
          _firestore.collection('reward_marketplace').doc(listingId);
      final listingDoc = await transaction.get(listingRef);

      if (!listingDoc.exists) throw RewardsException('العرض غير موجود');

      final data = listingDoc.data()!;
      if (data['sellerId'] != userId) {
        throw RewardsException('لا تملك صلاحية تعديل هذا العرض');
      }

      if (data['status'] != 'active') {
        throw RewardsException('لا يمكن تعديل عرض غير نشط');
      }

      transaction.update(listingRef, {
        'askingPrice': newPrice,
        'currency': newCurrency,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    });
  }

  /// فحص وتسجيل الأيام الفائتة (Missed Days)
  Future<void> _checkAndLogMissedDays(String userId, DateTime now) async {
    final startOfDay = DateTime(now.year, now.month, now.day);

    final activeRewardsSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection(RewardsConstants.collectionActiveRewards)
        .get();

    for (var doc in activeRewardsSnapshot.docs) {
      final reward = ActiveReward.fromMap(doc.data(), doc.id);
      final lastUpdate = reward.lastRewardDate;

      if (lastUpdate != null) {
        final lastUpdateDay =
            DateTime(lastUpdate.year, lastUpdate.month, lastUpdate.day);
        final difference = startOfDay.difference(lastUpdateDay).inDays;

        if (difference > 1) {
          // تسجيل الأيام الفائتة في وثيقة المكافأة
          await doc.reference.update({
            'missedDays': FieldValue.increment(difference - 1),
          });
        }
      }
    }
  }

  /// شراء مكافأة جديدة مع خصم الرصيد
  Future<ActiveReward> purchaseReward({
    required String packageName,
    required double rewardAmount, // هذه هي تكلفة الشراء
    required double totalReward,
    required double dailyReward,
    required int durationDays,
    required String paymentMethod,
    Map<String, dynamic>? metadata,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw RewardsException('يجب تسجيل الدخول أولاً');

    await _checkMaintenance();

    final now = DateTime.now();

    return await _firestore.runTransaction((transaction) async {
      // 1. التحقق من الرصيد والخصم
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await transaction.get(userRef);

      await _validateFunds(userId, rewardAmount, paymentMethod,
          userDoc: userDoc);
      await _deductFunds(transaction, userId, rewardAmount, paymentMethod,
          userDoc: userDoc);

      // 2. حساب هدية الباقة بحسب قيمة الخطة
      final bonusGift = _calculatePackageGift(rewardAmount, paymentMethod);
      final activeReward = ActiveReward(
        id: '',
        userId: userId,
        packageName: packageName,
        rewardAmount: rewardAmount,
        totalReward: totalReward,
        dailyReward: dailyReward,
        startTime: now,
        endTime: now.add(Duration(days: durationDays)),
        status: RewardsStatus.active,
        paymentMethod: paymentMethod,
        metadata: {
          ...?metadata,
          'purchase_at': FieldValue.serverTimestamp(),
          'bonusGift': bonusGift,
        },
      );

      // 3. حفظ المكافأة في مجموعة المستخدم
      final rewardCollRef =
          userRef.collection(RewardsConstants.collectionActiveRewards);
      final newDocRef = rewardCollRef.doc();

      transaction.set(newDocRef, activeReward.toMap());

      // 4. تسجيل في سجل العمليات (Audit Log)
      await _auditService.logEvent(
        action: 'package_purchase',
        eventType: AuditEventType.paymentProcessed,
        severity: AuditSeverity.medium,
        details: {
          'packageName': packageName,
          'cost': rewardAmount,
          'currency': paymentMethod,
          'rewardId': newDocRef.id,
        },
      );

      // 5. التحقق من الإنجازات بعد الشراء
      checkAndUnlockAchievements(userId);

      return activeReward.copyWith(id: newDocRef.id);
    });
  }

  int _calculatePackageGift(double rewardAmount, String paymentMethod) {
    if (paymentMethod != 'points') return 0;
    if (rewardAmount >= 1000000) return 15;
    if (rewardAmount >= 500000) return 10;
    if (rewardAmount >= 100000) return 5;
    return 0;
  }

  /// تنظيف المكافآت منتهية الصلاحية
  Future<void> cleanupExpiredRewards() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final activeRewardsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection(RewardsConstants.collectionActiveRewards)
          .get();

      for (var doc in activeRewardsSnapshot.docs) {
        final reward = ActiveReward.fromMap(doc.data(), doc.id);
        if (reward.isExpired) {
          await completeReward(reward.id);
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up expired rewards: $e');
    }
  }

  /// إنشاء عرض تداول في السوق
  Future<void> createTradeListing({
    required String rewardId,
    required double askingPrice,
    required String currency,
    String? description,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw RewardsException('يجب تسجيل الدخول أولاً');

    await _checkMaintenance();

    await _firestore.runTransaction((transaction) async {
      final rewardRef = _firestore
          .collection('users')
          .doc(userId)
          .collection(RewardsConstants.collectionActiveRewards)
          .doc(rewardId);

      final rewardDoc = await transaction.get(rewardRef);
      if (!rewardDoc.exists) throw RewardsException('المكافأة غير موجودة');

      final reward = ActiveReward.fromMap(rewardDoc.data()!, rewardDoc.id);

      // إنشاء معرف فريد للعرض
      final listingRef = _firestore.collection('reward_marketplace').doc();

      final listing = RewardListing(
        id: listingRef.id,
        sellerId: userId,
        rewardId: rewardId,
        packageName: reward.packageName,
        askingPrice: askingPrice,
        currency: currency,
        rewardData: reward.toMap(),
        description: description,
        status: 'active',
        createdAt: DateTime.now(),
      );

      transaction.set(listingRef, listing.toMap());

      // تحديث حالة المكافأة لتكون "في السوق" أو مشابه
      transaction.update(rewardRef, {
        'status': 'listed',
        'listingId': listingRef.id,
      });
    });
  }

  /// تفعيل المكافأة اليومية (يشترط مشاهدة إعلان ومرور 24 ساعة)
  Future<void> activateDailyReward(String rewardId,
      {required bool adWatched}) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw RewardsException('يجب تسجيل الدخول أولاً');

    await _checkMaintenance();

    // تفعيل نظام الرقابة لمنع استغلال تكرار النداء البرمجي
    await _checkRateLimit(userId, 'activate_daily_reward');

    if (!adWatched) {
      throw RewardsException('يجب مشاهدة الإعلان أولاً لتفعيل المكافأة');
    }

    await _firestore.runTransaction((transaction) async {
      final rewardRef = _firestore
          .collection('users')
          .doc(userId)
          .collection(RewardsConstants.collectionActiveRewards)
          .doc(rewardId);

      final rewardDoc = await transaction.get(rewardRef);
      if (!rewardDoc.exists) throw RewardsException('الباقة غير موجودة');

      final reward = ActiveReward.fromMap(rewardDoc.data()!, rewardDoc.id);

      if (reward.remainingDays <= 0 || reward.isExpired) {
        throw RewardsException('انتهت مدة صلاحية هذه الباقة');
      }

      final now = DateTime.now();
      final lastRewardDate = reward.lastRewardDate;

      if (lastRewardDate != null) {
        final nextAvailable = lastRewardDate.add(const Duration(hours: 24));
        if (now.isBefore(nextAvailable)) {
          final remaining = nextAvailable.difference(now);
          throw RewardsException(
              'يرجى الانتظار ${remaining.inHours} ساعة و ${remaining.inMinutes % 60} دقيقة');
        }
      }

      // تحديث الباقة: تسجيل وقت الحصاد الأخير
      transaction.update(rewardRef, {
        'lastRewardDate': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      // إضافة الربح اليومي إلى محفظة المكافآت (جواهر)
      await _addRewardToWallet(transaction, userId, reward.dailyReward,
          RewardsConstants.currencyGems);

      // تسجيل العملية في السجل اليومي
      final logRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('harvest_daily_logs')
          .doc();

      transaction.set(logRef, {
        'id': logRef.id,
        'rewardId': rewardId,
        'packageName': reward.packageName,
        'amount': reward.dailyReward,
        'currency': RewardsConstants.currencyGems,
        'timestamp': FieldValue.serverTimestamp(),
        'type': 'daily_claim'
      });

      // التحقق من الإنجازات بعد الحصاد
      checkAndUnlockAchievements(userId);
    });
  }

  /// معالجة جميع المكافآت المستحقة للمستخدم (بما في ذلك تحويل الـ 31 يوماً)
  Future<double> processDueDailyRewardsForUser(String userId,
      {bool isManualActivation = false, bool adWatched = false}) async {
    final now = DateTime.now();
    double totalProcessed = 0;

    await _checkAndLogMissedDays(userId, now);

    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection(RewardsConstants.collectionActiveRewards)
        .get();

    for (var doc in snapshot.docs) {
      final reward = ActiveReward.fromMap(doc.data(), doc.id);

      // 1. فحص انتهاء دورة الـ 31 يوماً للتحويل التلقائي للنجوم
      final expiryThreshold = reward.startTime.add(const Duration(days: 31));
      if (now.isAfter(expiryThreshold)) {
        await finalizeAndConvertPackage(doc.id);
        continue; // انتقل للباقة التالية بعد تصفية الحالية
      }

      // 2. معالجة الربح اليومي
      if (reward.remainingDays > 0 && reward.status == RewardsStatus.active) {
        bool shouldProcess = false;
        if (reward.lastRewardDate == null) {
          if (isManualActivation) shouldProcess = true;
        } else {
          final nextAvailable =
              reward.lastRewardDate!.add(const Duration(hours: 24));
          if (now.isAfter(nextAvailable)) {
            shouldProcess = true;
          }
        }

        if (shouldProcess && isManualActivation) {
          try {
            await activateDailyReward(doc.id, adWatched: adWatched);
            totalProcessed += reward.dailyReward;
          } catch (e) {
            debugPrint('Skipping reward ${doc.id}: $e');
          }
        }
      }
    }

    return totalProcessed;
  }

  /// معالجة انتهاء الباقة (بعد 31 يوم) وتحويل الجواهر لنجوم
  Future<void> finalizeAndConvertPackage(String rewardId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore.runTransaction((transaction) async {
      final rewardRef = _firestore
          .collection('users')
          .doc(userId)
          .collection(RewardsConstants.collectionActiveRewards)
          .doc(rewardId);

      final rewardDoc = await transaction.get(rewardRef);
      if (!rewardDoc.exists) return;

      final rewardData = rewardDoc.data()!;
      final reward = ActiveReward.fromMap(rewardData, rewardDoc.id);

      // جلب بيانات الباقة الأصلية لمعرفة نسبة التحويل الدقيقة
      double starsAmount = 0;
      final packageSnapshot = await _firestore
          .collection(RewardsConstants.collectionPackages)
          .where('name', isEqualTo: reward.packageName)
          .limit(1)
          .get();

      if (packageSnapshot.docs.isNotEmpty) {
        final pkg = packageSnapshot.docs.first.data();
        starsAmount = _parseDouble(pkg['conversion_stars']);
      } else {
        // نسبة افتراضية (رأس المال + 5% ربح) إذا لم يتم العثور على الباقة
        double conversionRate = 105000 / 40400;
        starsAmount = reward.totalReward * conversionRate;
      }

      // 1. تحديث المحفظة (إضافة النجوم المكتملة)
      final userRef = _firestore.collection('users').doc(userId);
      final userDoc = await transaction.get(userRef);
      final userData = userDoc.data()!;

      double currentStars = _parseDouble(
          userData[RewardsConstants.walletStarsField] ??
              userData['harvest_stars_wallet'] ??
              0);

      transaction.update(userRef, {
        RewardsConstants.walletStarsField: currentStars + starsAmount,
        'harvest_stars_wallet': currentStars + starsAmount,
      });

      // 2. أرشفة الباقة وحذفها من النشط
      final completedRef = _firestore
          .collection('users')
          .doc(userId)
          .collection(RewardsConstants.collectionCompletedRewards)
          .doc(rewardId);

      transaction.set(completedRef, {
        ...reward.toMap(),
        'status': 'finalized_and_converted',
        'finalStarsAwarded': starsAmount,
        'finalizedAt': FieldValue.serverTimestamp(),
      });

      transaction.delete(rewardRef);

      // إشعار المستخدم
      await NotificationsService.sendNotification(
        userId: userId,
        title: 'اكتمال دورة الباقة 👑',
        message:
            'تم تحويل باقة ${reward.packageName} بنجاح وإضافة ${_formatNumber(starsAmount)} نجمة لمحفظتك.',
        type: 'package_finalized',
      );
    });
  }

  // --- دوال مساعدة خاصة (Private Helpers) ---

  Future<void> _validateFunds(String userId, double amount, String currency,
      {DocumentSnapshot? userDoc}) async {
    final doc =
        userDoc ?? await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) throw RewardsException('المستخدم غير موجود');

    final data = doc.data() as Map<String, dynamic>;
    double balance = 0;

    if (currency == RewardsConstants.currencyGems) {
      balance = _parseDouble(data[RewardsConstants.walletGemsField] ??
          data['harvest_wallet'] ??
          data['harvestWallet'] ??
          0);
    } else if (currency == RewardsConstants.currencyStars) {
      balance = _parseDouble(data[RewardsConstants.walletStarsField] ??
          data['harvest_stars_wallet'] ??
          data['starsHarvestWallet'] ??
          0);
    } else if (currency == 'points') {
      balance = _parseDouble(data['points_wallet'] ?? 0);
    }

    if (balance < amount) throw RewardsException('رصيد $currency غير كافٍ');
  }

  Future<void> _deductFunds(
      Transaction transaction, String userId, double amount, String currency,
      {DocumentSnapshot? userDoc}) async {
    final userRef = _firestore.collection('users').doc(userId);
    String field = '';

    if (currency == RewardsConstants.currencyGems) {
      field = RewardsConstants.walletGemsField;
    } else if (currency == RewardsConstants.currencyStars) {
      field = RewardsConstants.walletStarsField;
    } else if (currency == 'points') {
      field = 'points_wallet';
    }

    if (field.isNotEmpty) {
      transaction.update(userRef, {
        field: FieldValue.increment(-amount),
        // للتوافق مع المسميات القديمة إذا وجدت
        if (field == RewardsConstants.walletGemsField)
          'harvest_wallet': FieldValue.increment(-amount),
        if (field == RewardsConstants.walletGemsField)
          'harvestWallet': FieldValue.increment(-amount),
        if (field == RewardsConstants.walletStarsField)
          'harvest_stars_wallet': FieldValue.increment(-amount),
        if (field == RewardsConstants.walletStarsField)
          'starsHarvestWallet': FieldValue.increment(-amount),
      });
    }
  }

  Future<void> addRewardToWallet(
      String userId, double amount, String currency) async {
    await _firestore.runTransaction((transaction) async {
      await _addRewardToWallet(transaction, userId, amount, currency);
    });
  }

  Future<void> _addRewardToWallet(Transaction transaction, String userId,
      double amount, String currency) async {
    final userRef = _firestore.collection('users').doc(userId);
    String field = '';

    if (currency == RewardsConstants.currencyGems) {
      field = RewardsConstants.walletGemsField;
    } else if (currency == RewardsConstants.currencyStars) {
      field = RewardsConstants.walletStarsField;
    }

    if (field.isNotEmpty) {
      transaction.update(userRef, {
        field: FieldValue.increment(amount),
        if (field == RewardsConstants.walletGemsField)
          'harvest_wallet': FieldValue.increment(amount),
        if (field == RewardsConstants.walletGemsField)
          'harvestWallet': FieldValue.increment(amount),
        if (field == RewardsConstants.walletStarsField)
          'harvest_stars_wallet': FieldValue.increment(amount),
        if (field == RewardsConstants.walletStarsField)
          'starsHarvestWallet': FieldValue.increment(amount),
      });
    }
  }

  /// تحويل هدايا الملكية (تحويل رصيد المكافآت بين المستخدمين مع رسوم لصندوق الدعم)
  Future<void> transferRoyalGifts({
    required String senderId,
    required String recipientRoyalId,
    required double amount,
    required String currency,
  }) async {
    await _checkMaintenance();

    await _firestore.runTransaction((transaction) async {
      // 1. جلب بيانات المرسل والمستلم
      final senderRef = _firestore.collection('users').doc(senderId);
      final senderDoc = await transaction.get(senderRef);

      final recipientQuery = await _firestore
          .collection('users')
          .where('royalId', isEqualTo: recipientRoyalId)
          .limit(1)
          .get();

      if (recipientQuery.docs.isEmpty) {
        throw RewardsException('المستلم غير موجود');
      }
      final recipientId = recipientQuery.docs.first.id;

      if (senderId == recipientId) {
        throw RewardsException('لا يمكنك التحويل لنفسك');
      }

      // 2. التحقق من الرصيد والرسوم
      final settings = await getRewardsSettings();
      final double feePercent =
          _parseDouble(settings[RewardsConstants.configTransferFee]);
      final double feeAmount = amount * feePercent;
      final double recipientAmount = amount - feeAmount;

      await _validateFunds(senderId, amount, currency, userDoc: senderDoc);

      // 3. تنفيذ العمليات المالية
      await _deductFunds(transaction, senderId, amount, currency,
          userDoc: senderDoc);
      await _addRewardToWallet(
          transaction, recipientId, recipientAmount, currency);

      // 4. إضافة الرسوم لصندوق الدعم العالمي
      final fundRef =
          _firestore.collection('global_support_fund').doc('status');
      transaction.set(
          fundRef,
          {
            'current_gems_pool': FieldValue.increment(feeAmount),
            'lastUpdate': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));

      // 5. تسجيل التحويل
      final transferRef =
          _firestore.collection(RewardsConstants.collectionTransfers).doc();
      transaction.set(transferRef, {
        'senderId': senderId,
        'recipientId': recipientId,
        'recipientRoyalId': recipientRoyalId,
        'amount': amount,
        'fee': feeAmount,
        'netAmount': recipientAmount,
        'currency': currency,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // إشعارات
      await NotificationsService.sendNotification(
        userId: recipientId,
        title: 'وصلتك هدية ملكية! 🎁',
        message:
            'استلمت ${_formatNumber(recipientAmount)} $currency من $senderId',
        type: 'gift_received',
      );
    });
  }

  Future<void> completeReward(String rewardId) async {
    // دالة بسيطة لنقل المكافأة للأرشيف عند انتهاء صلاحيتها العادية (إن لم تحول لنجوم)
    await finalizeAndConvertPackage(rewardId);
  }

  // --- لوحة المتصدرين (Leaderboard) ---

  /// جلب قائمة المتصدرين (أعلى 10 مستخدمين حسب النجوم)
  Stream<List<Map<String, dynamic>>> getLeaderboard() {
    return _firestore
        .collection('users')
        .orderBy('harvest_stars_wallet', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'uid': doc.id,
                'name':
                    data['displayName'] ?? data['username'] ?? 'مستخدم ملكي',
                'stars': data['harvest_stars_wallet'] ?? 0,
                'photoUrl': data['photoUrl'],
                'royalId': data['royalId'] ?? data['royal_id'] ?? 'N/A',
              };
            }).toList());
  }

  // --- نظام الإنجازات (Achievements) ---

  /// جلب إنجازات المستخدم
  Stream<List<RewardAchievement>> getUserAchievements(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection(RewardsConstants.collectionAchievements)
        .orderBy('unlockedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => RewardAchievement.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// التحقق وتفعيل الإنجازات المحققة
  Future<void> checkAndUnlockAchievements(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return;
      final userData = userDoc.data()!;

      final achievementsRef = _firestore
          .collection('users')
          .doc(userId)
          .collection(RewardsConstants.collectionAchievements);

      // 1. إنجاز جامع النجوم (أكثر من 100,000 نجمة)
      double totalStars = _parseDouble(
          userData[RewardsConstants.walletStarsField] ??
              userData['harvest_stars_wallet'] ??
              0);
      if (totalStars >= 100000) {
        await _unlockIfNew(achievementsRef, 'star_collector', {
          'title': 'جامع النجوم',
          'description': 'حصدت أكثر من 100,000 نجمة ملكية',
          'icon': 'stars',
          'rewardGems': 10,
        });
      }

      // 2. إنجاز المستثمر الذهبي (3 باقات نشطة)
      final activeSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection(RewardsConstants.collectionActiveRewards)
          .where('status', isEqualTo: 'active')
          .get();
      if (activeSnapshot.docs.length >= 3) {
        await _unlockIfNew(achievementsRef, 'golden_investor', {
          'title': 'المستثمر الذهبي',
          'description': 'تمتلك 3 باقات نشطة في وقت واحد',
          'icon': 'workspace_premium',
          'rewardGems': 100,
        });
      }

      // 3. إنجاز المواظب الملكي (سجل حصاد 7 أيام)
      final logsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('harvest_daily_logs')
          .limit(7)
          .get();
      if (logsSnapshot.docs.length >= 7) {
        await _unlockIfNew(achievementsRef, 'royal_constant', {
          'title': 'المواظب الملكي',
          'description': 'التزمت بالحصاد اليومي لمدة 7 أيام',
          'icon': 'event_available',
          'rewardGems': 20,
        });
      }
    } catch (e) {
      debugPrint('Error checking achievements: $e');
    }
  }

  Future<void> _unlockIfNew(
      CollectionReference ref, String id, Map<String, dynamic> data) async {
    final doc = await ref.doc(id).get();
    if (!doc.exists) {
      await ref.doc(id).set({
        ...data,
        'userId': ref.parent!.id,
        'unlockedAt': FieldValue.serverTimestamp(),
        'isClaimed': false,
      });

      // إرسال إشعار بفتح إنجاز جديد
      await NotificationsService.sendNotification(
        userId: ref.parent!.id,
        title: 'إنجاز جديد! 🏆',
        message: 'لقد فتحت إنجاز "${data['title']}". اذهب للمطالبة بمكافأتك.',
        type: 'achievement_unlocked',
      );
    }
  }

  /// المطالبة بمكافأة الإنجاز
  Future<void> claimAchievementReward(String achievementId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore.runTransaction((transaction) async {
      final achRef = _firestore
          .collection('users')
          .doc(userId)
          .collection(RewardsConstants.collectionAchievements)
          .doc(achievementId);

      final doc = await transaction.get(achRef);
      if (!doc.exists) throw RewardsException('الإنجاز غير موجود');

      final data = doc.data()!;
      if (data['isClaimed'] == true) {
        throw RewardsException('تم استلام المكافأة مسبقاً');
      }

      double reward = _parseDouble(data['rewardGems']);

      // 1. إضافة المكافأة للمحفظة (جواهر)
      await _addRewardToWallet(
          transaction, userId, reward, RewardsConstants.currencyGems);

      // 2. تحديث حالة الإنجاز
      transaction.update(achRef, {
        'isClaimed': true,
        'claimedAt': FieldValue.serverTimestamp(),
      });

      // 3. تسجيل في Audit Log
      await _auditService.logEvent(
        action: 'achievement_claim',
        eventType: AuditEventType.rewardClaimed,
        severity: AuditSeverity.low,
        details: {
          'achievementId': achievementId,
          'amount': reward,
        },
      );
    });
  }
}
