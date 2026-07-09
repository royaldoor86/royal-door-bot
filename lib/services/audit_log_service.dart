import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../constants/rewards_constants.dart';
import 'encryption_service.dart';

/// أنواع الأحداث في Audit Log
enum AuditEventType {
  userLogin('user_login'),
  userLogout('user_logout'),
  otpSent('otp_sent'),
  otpVerified('otp_verified'),
  otpFailed('otp_failed'),
  harvestCreated('harvest_created'),
  harvestUpdated('harvest_updated'),
  harvestDeleted('harvest_deleted'),
  paymentProcessed('payment_processed'),
  paymentFailed('payment_failed'),
  redemptionRequested('redemption_requested'),
  redemptionProcessed('redemption_processed'),
  adminAction('admin_action'),
  securityAlert('security_alert'),
  rewardClaimed('reward_claimed'),
  dataAccess('data_access'),
  systemError('system_error');

  const AuditEventType(this.value);
  final String value;
}

/// مستويات خطورة الحدث
enum AuditSeverity {
  low('low'),
  medium('medium'),
  high('high'),
  critical('critical');

  const AuditSeverity(this.value);
  final String value;
}

/// نموذج بيانات Audit Log
class AuditLogEntry {
  final String id;
  final String action;
  final AuditEventType eventType;
  final AuditSeverity severity;
  final Map<String, dynamic> details;
  final String? userId;
  final String? sessionId;
  final String? ipAddress;
  final String? userAgent;
  final DateTime timestamp;
  final bool isEncrypted;

  AuditLogEntry({
    required this.id,
    required this.action,
    required this.eventType,
    required this.severity,
    required this.details,
    this.userId,
    this.sessionId,
    this.ipAddress,
    this.userAgent,
    required this.timestamp,
    this.isEncrypted = false,
  });

  factory AuditLogEntry.fromMap(Map<String, dynamic> map) {
    return AuditLogEntry(
      id: map['id'] ?? '',
      action: map['action'] ?? '',
      eventType: AuditEventType.values.firstWhere(
        (e) => e.value == map['eventType'],
        orElse: () => AuditEventType.systemError,
      ),
      severity: AuditSeverity.values.firstWhere(
        (s) => s.value == map['severity'],
        orElse: () => AuditSeverity.medium,
      ),
      details: Map<String, dynamic>.from(map['details'] ?? {}),
      userId: map['userId'],
      sessionId: map['sessionId'],
      ipAddress: map['ipAddress'],
      userAgent: map['userAgent'],
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isEncrypted: map['isEncrypted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action': action,
      'eventType': eventType.value,
      'severity': severity.value,
      'details': details,
      'userId': userId,
      'sessionId': sessionId,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'timestamp': Timestamp.fromDate(timestamp),
      'isEncrypted': isEncrypted,
    };
  }
}

/// خدمة Audit Log الشاملة
class AuditLogService {
  static final AuditLogService _instance = AuditLogService._internal();

  factory AuditLogService() {
    return _instance;
  }

  AuditLogService._internal() {
    _initializeService();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream للأحداث الأمنية
  late StreamController<AuditLogEntry> _securityEventsController;
  late Stream<AuditLogEntry> securityEventsStream;

  void _initializeService() {
    _securityEventsController = StreamController<AuditLogEntry>.broadcast();
    securityEventsStream = _securityEventsController.stream;
  }

  /// ==================== الدوال الأساسية ====================

  /// تسجيل حدث في Audit Log
  Future<String> logEvent({
    required String action,
    required AuditEventType eventType,
    required AuditSeverity severity,
    required Map<String, dynamic> details,
    String? userId,
    String? sessionId,
    String? ipAddress,
    String? userAgent,
    bool encryptSensitive = false,
  }) async {
    try {
      final entryId = _generateEventId();
      final currentUserId = userId ?? _auth.currentUser?.uid;
      final timestamp = DateTime.now();

      // تشفير البيانات الحساسة إذا طُلب
      Map<String, dynamic> processedDetails = details;
      bool isEncrypted = false;

      if (encryptSensitive && _hasSensitiveData(details)) {
        processedDetails = await _encryptSensitiveDetails(details);
        isEncrypted = true;
      }

      final entry = AuditLogEntry(
        id: entryId,
        action: action,
        eventType: eventType,
        severity: severity,
        details: processedDetails,
        userId: currentUserId,
        sessionId: sessionId,
        ipAddress: ipAddress,
        userAgent: userAgent,
        timestamp: timestamp,
        isEncrypted: isEncrypted,
      );

      // حفظ في Firestore
      await _firestore
          .collection(RewardsConstants.collectionAuditLogs)
          .doc(entryId)
          .set(entry.toMap());

      // إرسال إلى Stream إذا كان حدث أمني
      if (severity == AuditSeverity.high ||
          severity == AuditSeverity.critical) {
        _securityEventsController.add(entry);
      }

      // تنظيف السجلات القديمة تلقائياً
      if (await _shouldCleanup()) {
        await _cleanupOldLogs();
      }

      return entryId;
    } catch (e) {
      debugPrint('فشل في تسجيل Audit Log: $e');
      rethrow;
    }
  }

  /// تسجيل حدث تسجيل دخول
  Future<String> logUserLogin({
    required String userId,
    String? ipAddress,
    String? userAgent,
    String? deviceInfo,
  }) async {
    return await logEvent(
      action: RewardsConstants.auditActionUserLogin,
      eventType: AuditEventType.userLogin,
      severity: AuditSeverity.medium,
      details: {
        'loginMethod': 'phone_auth',
        'deviceInfo': deviceInfo,
        'timestamp': FieldValue.serverTimestamp(),
      },
      userId: userId,
      ipAddress: ipAddress,
      userAgent: userAgent,
    );
  }

  /// تسجيل حدث تسجيل خروج
  Future<String> logUserLogout({
    required String userId,
    String? sessionDuration,
  }) async {
    return await logEvent(
      action: RewardsConstants.auditActionUserLogout,
      eventType: AuditEventType.userLogout,
      severity: AuditSeverity.low,
      details: {
        'sessionDuration': sessionDuration,
        'timestamp': FieldValue.serverTimestamp(),
      },
      userId: userId,
    );
  }

  /// تسجيل حدث أمني حرج
  Future<String> logSecurityAlert({
    required String alertType,
    required String description,
    required Map<String, dynamic> alertDetails,
    String? userId,
    String? ipAddress,
  }) async {
    return await logEvent(
      action: 'security_alert_$alertType',
      eventType: AuditEventType.securityAlert,
      severity: AuditSeverity.critical,
      details: {
        'alertType': alertType,
        'description': description,
        'alertDetails': alertDetails,
        'timestamp': FieldValue.serverTimestamp(),
      },
      userId: userId,
      ipAddress: ipAddress,
      encryptSensitive: true,
    );
  }

  /// تسجيل حدث خطأ في النظام
  Future<String> logSystemError({
    required String errorType,
    required String errorMessage,
    String? stackTrace,
    String? userId,
  }) async {
    return await logEvent(
      action: 'system_error_$errorType',
      eventType: AuditEventType.systemError,
      severity: AuditSeverity.high,
      details: {
        'errorType': errorType,
        'errorMessage': errorMessage,
        'stackTrace': stackTrace,
        'timestamp': FieldValue.serverTimestamp(),
      },
      userId: userId,
    );
  }

  /// ==================== دوال الاستعلام ====================

  /// جلب سجلات Audit Log لمستخدم معين
  Future<List<AuditLogEntry>> getUserAuditLogs({
    required String userId,
    int limit = 50,
    DateTime? startDate,
    DateTime? endDate,
    List<AuditEventType>? eventTypes,
  }) async {
    try {
      Query query = _firestore
          .collection(RewardsConstants.collectionAuditLogs)
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (startDate != null) {
        query = query.where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();
      final entries = <AuditLogEntry>[];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          final entry = AuditLogEntry.fromMap(data);
          entries.add(entry);
        }
      }

      return entries;
    } catch (e) {
      debugPrint('فشل في جلب سجلات Audit Log: $e');
      return [];
    }
  }

  /// جلب الأحداث الأمنية الحرجة
  Future<List<AuditLogEntry>> getSecurityAlerts({
    int limit = 100,
    Duration? withinDuration,
  }) async {
    try {
      DateTime startDate = DateTime.now();
      if (withinDuration != null) {
        startDate = startDate.subtract(withinDuration);
      }

      final snapshot = await _firestore
          .collection(RewardsConstants.collectionAuditLogs)
          .where('severity', whereIn: ['high', 'critical'])
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      final alerts = <AuditLogEntry>[];
      for (final doc in snapshot.docs) {
        final entry = AuditLogEntry.fromMap(doc.data());
        alerts.add(entry);
      }

      return alerts;
    } catch (e) {
      debugPrint('فشل في جلب التنبيهات الأمنية: $e');
      return [];
    }
  }

  /// البحث في Audit Log
  Future<List<AuditLogEntry>> searchAuditLogs({
    String? userId,
    String? action,
    AuditEventType? eventType,
    AuditSeverity? severity,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    try {
      Query query = _firestore
          .collection(RewardsConstants.collectionAuditLogs)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (userId != null) {
        query = query.where('userId', isEqualTo: userId);
      }

      if (action != null) {
        query = query.where('action', isEqualTo: action);
      }

      if (eventType != null) {
        query = query.where('eventType', isEqualTo: eventType.value);
      }

      if (severity != null) {
        query = query.where('severity', isEqualTo: severity.value);
      }

      if (startDate != null) {
        query = query.where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }

      if (endDate != null) {
        query = query.where('timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();
      final results = <AuditLogEntry>[];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null) {
          final entry = AuditLogEntry.fromMap(data);
          results.add(entry);
        }
      }

      return results;
    } catch (e) {
      debugPrint('فشل في البحث في Audit Log: $e');
      return [];
    }
  }

  /// ==================== دوال الصيانة ====================

  /// تنظيف السجلات القديمة
  Future<void> cleanupOldLogs({Duration? retentionPeriod}) async {
    try {
      final cutoffDate = DateTime.now().subtract(
        retentionPeriod ?? const Duration(days: RewardsConstants.auditLogRetention),
      );

      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection(RewardsConstants.collectionAuditLogs)
          .where('timestamp', isLessThan: Timestamp.fromDate(cutoffDate))
          .get();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('تم تنظيف ${snapshot.docs.length} سجل قديم من Audit Log');
    } catch (e) {
      debugPrint('فشل في تنظيف السجلات القديمة: $e');
    }
  }

  /// ==================== دوال مساعدة ====================

  /// توليد معرف فريد للحدث
  String _generateEventId() {
    return 'audit_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}';
  }

  /// توليد سلسلة عشوائية
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    String result = '';
    for (int i = 0; i < length; i++) {
      result += chars[(random + i) % chars.length];
    }
    return result;
  }

  /// التحقق من وجود بيانات حساسة
  bool _hasSensitiveData(Map<String, dynamic> details) {
    final sensitiveKeys = [
      'password',
      'otp',
      'token',
      'key',
      'secret',
      'phone',
      'email'
    ];
    return details.keys.any((key) => sensitiveKeys
        .any((sensitive) => key.toLowerCase().contains(sensitive)));
  }

  /// تشفير البيانات الحساسة
  Future<Map<String, dynamic>> _encryptSensitiveDetails(
      Map<String, dynamic> details) async {
    final encrypted = <String, dynamic>{};

    for (final entry in details.entries) {
      if (_isSensitiveKey(entry.key)) {
        encrypted[entry.key] =
            EncryptionService.encryptSensitive(entry.value.toString());
      } else if (entry.value is Map<String, dynamic>) {
        encrypted[entry.key] = await _encryptSensitiveDetails(entry.value);
      } else {
        encrypted[entry.key] = entry.value;
      }
    }

    return encrypted;
  }

  /// التحقق من أن المفتاح حساس
  bool _isSensitiveKey(String key) {
    final sensitiveKeys = [
      'password',
      'otp',
      'token',
      'key',
      'secret',
      'phone',
      'email'
    ];
    return sensitiveKeys
        .any((sensitive) => key.toLowerCase().contains(sensitive));
  }

  /// التحقق من الحاجة للتنظيف
  Future<bool> _shouldCleanup() async {
    try {
      final count = await _firestore
          .collection(RewardsConstants.collectionAuditLogs)
          .count()
          .get();

      return count.count != null && count.count! >= RewardsConstants.auditLogMaxEntries;
    } catch (e) {
      return false;
    }
  }

  /// تنظيف السجلات القديمة
  Future<void> _cleanupOldLogs() async {
    await cleanupOldLogs();
  }

  /// تنظيف الموارد
  void dispose() {
    _securityEventsController.close();
  }
}
