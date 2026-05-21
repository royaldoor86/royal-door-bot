import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../constants/rewards_constants.dart';
import 'audit_log_service.dart';

/// أنواع Rate Limiting
enum RateLimitType {
  user, // لكل مستخدم
  ip, // لكل عنوان IP
  global, // عام للنظام
  endpoint, // لكل نقطة نهاية
}

/// مستويات Rate Limiting
enum RateLimitLevel {
  strict, // صارم
  normal, // عادي
  lenient, // متساهل
}

/// حالة Rate Limit
class RateLimitStatus {
  final bool allowed;
  final int currentRequests;
  final int maxRequests;
  final Duration remainingTime;
  final DateTime resetTime;
  final String? blockReason;

  RateLimitStatus({
    required this.allowed,
    required this.currentRequests,
    required this.maxRequests,
    required this.remainingTime,
    required this.resetTime,
    this.blockReason,
  });

  bool get isBlocked => !allowed;
  double get usagePercentage => (currentRequests / maxRequests) * 100;
}

/// خدمة Rate Limiting المتقدمة
class RateLimiterService {
  static final RateLimiterService _instance = RateLimiterService._internal();

  factory RateLimiterService() {
    return _instance;
  }

  RateLimiterService._internal() {
    _initializeService();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditLogService _auditService = AuditLogService();

  // Cache للحدود الزمنية
  final Map<String, DateTime> _resetTimes = {};
  final Map<String, int> _requestCounts = {};

  // Timer للتنظيف التلقائي
  Timer? _cleanupTimer;

  void _initializeService() {
    // تنظيف Cache كل دقيقة
    _cleanupTimer =
        Timer.periodic(const Duration(minutes: 1), (_) => _cleanupExpiredEntries());
  }

  /// ==================== الدوال الأساسية ====================

  /// التحقق من Rate Limit
  Future<RateLimitStatus> checkRateLimit({
    required String identifier,
    required String action,
    RateLimitType type = RateLimitType.user,
    RateLimitLevel level = RateLimitLevel.normal,
    String? ipAddress,
  }) async {
    try {
      final key = _generateKey(identifier, action, type);
      final config = _getRateLimitConfig(action, level);

      // جلب عدد الطلبات في النافذة الزمنية
      final requestCount = await _getRequestCount(key, config.window);

      // التحقق من تجاوز الحد
      if (requestCount >= config.maxRequests) {
        final resetTime = await _getResetTime(key);
        final remainingTime = resetTime.difference(DateTime.now());

        // تسجيل محاولة تجاوز الحد
        await _auditService.logSecurityAlert(
          alertType: 'rate_limit_exceeded',
          description: 'تم تجاوز حد الطلبات المسموح',
          alertDetails: {
            'identifier': _maskIdentifier(identifier, type),
            'action': action,
            'requestCount': requestCount,
            'maxRequests': config.maxRequests,
            'window': config.window.inMinutes,
          },
          userId: type == RateLimitType.user ? identifier : null,
          ipAddress: ipAddress,
        );

        return RateLimitStatus(
          allowed: false,
          currentRequests: requestCount,
          maxRequests: config.maxRequests,
          remainingTime: remainingTime,
          resetTime: resetTime,
          blockReason:
              'تم تجاوز حد الطلبات ($requestCount/${config.maxRequests})',
        );
      }

      // تسجيل الطلب
      await _recordRequest(key, config.window);

      return RateLimitStatus(
        allowed: true,
        currentRequests: requestCount + 1,
        maxRequests: config.maxRequests,
        remainingTime: config.window,
        resetTime: DateTime.now().add(config.window),
      );
    } catch (e) {
      debugPrint('فشل في التحقق من Rate Limit: $e');
      // في حالة الخطأ، اسمح بالطلب لتجنب حجب المستخدمين
      return RateLimitStatus(
        allowed: true,
        currentRequests: 0,
        maxRequests: 100,
        remainingTime: const Duration(minutes: 1),
        resetTime: DateTime.now().add(const Duration(minutes: 1)),
      );
    }
  }

  /// التحقق السريع من Rate Limit (للاستخدامات عالية التكرار)
  Future<bool> isAllowed({
    required String identifier,
    required String action,
    RateLimitType type = RateLimitType.user,
    RateLimitLevel level = RateLimitLevel.normal,
  }) async {
    final status = await checkRateLimit(
      identifier: identifier,
      action: action,
      type: type,
      level: level,
    );
    return status.allowed;
  }

  /// الحصول على حالة Rate Limit الحالية
  Future<RateLimitStatus> getCurrentStatus({
    required String identifier,
    required String action,
    RateLimitType type = RateLimitType.user,
    RateLimitLevel level = RateLimitLevel.normal,
  }) async {
    final key = _generateKey(identifier, action, type);
    final config = _getRateLimitConfig(action, level);

    final requestCount = await _getRequestCount(key, config.window);
    final resetTime = await _getResetTime(key);
    final remainingTime = resetTime.difference(DateTime.now());

    return RateLimitStatus(
      allowed: requestCount < config.maxRequests,
      currentRequests: requestCount,
      maxRequests: config.maxRequests,
      remainingTime:
          remainingTime > Duration.zero ? remainingTime : Duration.zero,
      resetTime: resetTime,
    );
  }

  /// ==================== دوال مخصصة للأحداث الشائعة ====================

  /// Rate Limiting لإرسال OTP
  Future<RateLimitStatus> checkOtpSendLimit(String phoneNumber,
      {String? ipAddress}) async {
    return await checkRateLimit(
      identifier: phoneNumber,
      action: 'send_otp',
      type: RateLimitType.user,
      level: RateLimitLevel.normal,
      ipAddress: ipAddress,
    );
  }

  /// Rate Limiting للتحقق من OTP
  Future<RateLimitStatus> checkOtpVerifyLimit(String userId,
      {String? ipAddress}) async {
    return await checkRateLimit(
      identifier: userId,
      action: 'verify_otp',
      type: RateLimitType.user,
      level: RateLimitLevel.strict,
      ipAddress: ipAddress,
    );
  }

  /// Rate Limiting لتسجيل الدخول
  Future<RateLimitStatus> checkLoginLimit(String identifier,
      {String? ipAddress}) async {
    return await checkRateLimit(
      identifier: identifier,
      action: 'user_login',
      type: RateLimitType.user,
      level: RateLimitLevel.normal,
      ipAddress: ipAddress,
    );
  }

  /// Rate Limiting للطلبات العامة
  Future<RateLimitStatus> checkApiLimit(String endpoint,
      {String? ipAddress}) async {
    return await checkRateLimit(
      identifier: endpoint,
      action: 'api_request',
      type: RateLimitType.endpoint,
      level: RateLimitLevel.lenient,
      ipAddress: ipAddress,
    );
  }

  /// ==================== دوال الإدارة ====================

  /// إعادة تعيين عداد Rate Limit
  Future<void> resetLimit({
    required String identifier,
    required String action,
    RateLimitType type = RateLimitType.user,
  }) async {
    final key = _generateKey(identifier, action, type);

    // حذف من Cache
    _requestCounts.remove(key);
    _resetTimes.remove(key);

    // حذف من Firestore
    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection(RewardsConstants.collectionRateLimits)
        .where('key', isEqualTo: key)
        .get();

    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  /// الحصول على إحصائيات Rate Limiting
  Future<Map<String, dynamic>> getRateLimitStats({
    String? identifier,
    String? action,
    Duration? timeRange,
  }) async {
    try {
      DateTime startDate = DateTime.now();
      if (timeRange != null) {
        startDate = startDate.subtract(timeRange);
      }

      Query query = _firestore
          .collection(RewardsConstants.collectionRateLimits)
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));

      if (identifier != null) {
        query = query.where('identifier', isEqualTo: identifier);
      }

      if (action != null) {
        query = query.where('action', isEqualTo: action);
      }

      final snapshot = await query.get();

      final stats = <String, dynamic>{
        'totalRequests': snapshot.docs.length,
        'timeRange': timeRange?.inHours ?? 24,
        'requestsByAction': <String, int>{},
        'requestsByHour': <String, int>{},
      };

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          final action = data['action'] as String? ?? 'unknown';
          final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

          // عد بالإجراء
          stats['requestsByAction'][action] =
              (stats['requestsByAction'][action] as int? ?? 0) + 1;

          // عد بالساعة
          if (timestamp != null) {
            final hourKey =
                '${timestamp.year}-${timestamp.month}-${timestamp.day}-${timestamp.hour}';
            stats['requestsByHour'][hourKey] =
                (stats['requestsByHour'][hourKey] as int? ?? 0) + 1;
          }
        }
      }

      return stats;
    } catch (e) {
      debugPrint('فشل في جلب إحصائيات Rate Limit: $e');
      return {};
    }
  }

  /// ==================== دوال مساعدة ====================

  /// توليد مفتاح فريد للتحقق
  String _generateKey(String identifier, String action, RateLimitType type) {
    return '${type.name}_${action}_${identifier.hashCode}';
  }

  /// إخفاء المعرف للتسجيل
  String _maskIdentifier(String identifier, RateLimitType type) {
    switch (type) {
      case RateLimitType.user:
        return identifier.length > 8
            ? '${identifier.substring(0, 4)}****'
            : '****';
      case RateLimitType.ip:
        return identifier.replaceAll(RegExp(r'\d'), '*');
      default:
        return identifier;
    }
  }

  /// الحصول على إعدادات Rate Limit
  _RateLimitConfig _getRateLimitConfig(String action, RateLimitLevel level) {
    // إعدادات افتراضية حسب الإجراء والمستوى
    switch (action) {
      case 'send_otp':
        return _RateLimitConfig(
          maxRequests: level == RateLimitLevel.strict
              ? 2
              : level == RateLimitLevel.normal
                  ? 5
                  : 10,
          window: const Duration(minutes: 15),
        );
      case 'verify_otp':
        return _RateLimitConfig(
          maxRequests: level == RateLimitLevel.strict
              ? 3
              : level == RateLimitLevel.normal
                  ? 5
                  : 10,
          window: const Duration(minutes: 10),
        );
      case 'user_login':
        return _RateLimitConfig(
          maxRequests: level == RateLimitLevel.strict
              ? 3
              : level == RateLimitLevel.normal
                  ? 5
                  : 10,
          window: const Duration(minutes: 30),
        );
      case 'api_request':
        return _RateLimitConfig(
          maxRequests: level == RateLimitLevel.strict
              ? 50
              : level == RateLimitLevel.normal
                  ? 100
                  : 200,
          window: const Duration(minutes: 1),
        );
      default:
        return _RateLimitConfig(
          maxRequests: level == RateLimitLevel.strict
              ? 10
              : level == RateLimitLevel.normal
                  ? 50
                  : 100,
          window: const Duration(minutes: 1),
        );
    }
  }

  /// جلب عدد الطلبات في النافذة الزمنية
  Future<int> _getRequestCount(String key, Duration window) async {
    final now = DateTime.now();
    final windowStart = now.subtract(window);

    final snapshot = await _firestore
        .collection(RewardsConstants.collectionRateLimits)
        .where('key', isEqualTo: key)
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(windowStart))
        .get();

    return snapshot.docs.length;
  }

  /// جلب وقت إعادة التعيين
  Future<DateTime> _getResetTime(String key) async {
    if (_resetTimes.containsKey(key)) {
      return _resetTimes[key]!;
    }

    // افتراضياً، إعادة تعيين كل دقيقة
    return DateTime.now().add(const Duration(minutes: 1));
  }

  /// تسجيل طلب جديد
  Future<void> _recordRequest(String key, Duration window) async {
    final resetTime = DateTime.now().add(window);
    _resetTimes[key] = resetTime;
    _requestCounts[key] = (_requestCounts[key] ?? 0) + 1;

    await _firestore.collection(RewardsConstants.collectionRateLimits).add({
      'key': key,
      'identifier': key.split('_').skip(2).join('_'), // استخراج المعرف الأصلي
      'action': key.split('_')[1],
      'type': key.split('_')[0],
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// تنظيف الإدخالات المنتهية الصلاحية
  void _cleanupExpiredEntries() {
    final now = DateTime.now();
    _resetTimes.removeWhere((key, resetTime) => resetTime.isBefore(now));
    _requestCounts.clear(); // إعادة بناء من Firestore عند الحاجة
  }

  /// تنظيف الموارد
  void dispose() {
    _cleanupTimer?.cancel();
  }
}

/// إعدادات Rate Limit
class _RateLimitConfig {
  final int maxRequests;
  final Duration window;

  _RateLimitConfig({
    required this.maxRequests,
    required this.window,
  });
}
