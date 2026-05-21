import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:phone_number/phone_number.dart';
import '../constants/rewards_constants.dart';

/// كلاس استثناء OTP مخصص
class OTPException implements Exception {
  final String message;
  final String? code;

  OTPException(this.message, {this.code});

  @override
  String toString() => 'OTPException: $message';
}

/// نموذج بيانات OTP
class OTPData {
  final bool verified;
  final int remainingSeconds;
  final String? phoneNumber;
  final int verifyAttempts;
  final int maxVerifyAttempts;
  final bool exists;
  final bool locked;
  final int? lockedUntil;

  OTPData({
    required this.verified,
    required this.remainingSeconds,
    this.phoneNumber,
    required this.verifyAttempts,
    required this.maxVerifyAttempts,
    required this.exists,
    required this.locked,
    this.lockedUntil,
  });

  factory OTPData.fromMap(Map<String, dynamic> map) {
    return OTPData(
      verified: map['verified'] ?? false,
      remainingSeconds: map['remainingSeconds'] ?? 0,
      phoneNumber: map['phoneNumber'],
      verifyAttempts: map['verifyAttempts'] ?? 0,
      maxVerifyAttempts:
          map['maxVerifyAttempts'] ?? RewardsConstants.maxOtpAttempts,
      exists: map['exists'] ?? false,
      locked: map['locked'] ?? false,
      lockedUntil: map['lockedUntil'],
    );
  }
}

/// خدمة إدارة OTP المحسنة بالأمان
class OTPService {
  static final OTPService _instance = OTPService._internal();

  factory OTPService() {
    return _instance;
  }

  OTPService._internal() {
    _initializeFirebase();
  }

  late FirebaseFunctions _functions;
  late FirebaseFirestore _firestore;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final PhoneNumberUtil _phoneUtil = PhoneNumberUtil();

  // متغيرات حالة المؤقت
  Timer? _statusTimer;
  int _remainingSeconds = 0;

  // Streams للحالة
  late Stream<int> _remainingTimeStream;
  late StreamController<int> _remainingTimeController;

  void _initializeFirebase() {
    _functions = FirebaseFunctions.instance;
    _firestore = FirebaseFirestore.instance;
    _remainingTimeController = StreamController<int>.broadcast();
    _remainingTimeStream = _remainingTimeController.stream;
  }

  /// Stream لمراقبة الوقت المتبقي
  Stream<int> get remainingTimeStream => _remainingTimeStream;

  /// ==================== الدوال الأساسية ====================

  /// إرسال OTP إلى رقم الهاتف مع التحقق من الأمان
  Future<int> sendOTP(String phoneNumber, {bool isLogin = false}) async {
    try {
      // السماح بطلب OTP إذا كان الهدف هو تسجيل الدخول
      if (!isLogin && !_isUserLoggedIn()) {
        throw OTPException('يجب تسجيل الدخول أولاً', code: 'unauthenticated');
      }

      // التحقق من صحة رقم الهاتف
      if (!await _isValidPhoneNumber(phoneNumber)) {
        throw OTPException('صيغة رقم الهاتف غير صحيحة', code: 'invalid_phone');
      }

      // إرسال عبر Firebase Functions (نظام Twilio)
      final callable = _functions.httpsCallable('sendOTP');
      await callable.call({
        'phoneNumber': phoneNumber,
      });

      // Twilio Verify الافتراضي هو 10 دقائق (600 ثانية)
      const expiresIn = 600;

      // بدء مراقبة الوقت للواجهة
      _startTimerMonitoring(expiresIn);

      // تسجيل في Audit Log (اختياري)
      await _auditLog(RewardsConstants.auditActionOtpSent, {
        'phoneNumber': _maskPhoneNumber(phoneNumber),
        'userId': _auth.currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      return expiresIn;
    } on FirebaseFunctionsException catch (e) {
      throw OTPException(
        e.message ?? 'خطأ في إرسال الرمز',
        code: e.code,
      );
    } catch (e) {
      throw OTPException('فشل في إرسال OTP: ${e.toString()}');
    }
  }

  /// التحقق من رمز OTP عبر Twilio Verify
  Future<bool> verifyOTP(String otp, {required String phoneNumber}) async {
    try {
      // التحقق من صيغة OTP
      if (otp.isEmpty || otp.length < 4) {
        throw OTPException('الرمز غير صحيح', code: 'invalid_otp_format');
      }

      // التحقق عبر Cloud Function (Twilio Verify)
      final callable = _functions.httpsCallable('verifyOTP');
      final result = await callable.call({
        'phoneNumber': phoneNumber,
        'otp': otp,
      });

      final responseData = result.data as Map<String, dynamic>;

      if (responseData['success'] == true) {
        // إذا كان هناك customToken (حالة تسجيل دخول)
        if (responseData['customToken'] != null) {
          await _auth.signInWithCustomToken(responseData['customToken']);
        }

        // إيقاف المؤقت
        _stopTimerMonitoring();

        // تسجيل النجاح
        await _auditLog(RewardsConstants.auditActionOtpVerified, {
          'phoneNumber': phoneNumber,
          'timestamp': FieldValue.serverTimestamp(),
        });

        return true;
      }

      throw OTPException(responseData['message'] ?? 'الرمز غير صحيح');
    } on FirebaseFunctionsException catch (e) {
      throw OTPException(e.message ?? 'خطأ في التحقق', code: e.code);
    } catch (e) {
      if (e is! OTPException) {
        throw OTPException('فشل في التحقق: ${e.toString()}');
      }
      rethrow;
    }
  }

  /// الحصول على حالة الموقت الحالية
  OTPData checkOTPStatus() {
    return OTPData(
      verified: false,
      remainingSeconds: _remainingSeconds,
      verifyAttempts: 0,
      maxVerifyAttempts: 5,
      exists: _remainingSeconds > 0,
      locked: false,
    );
  }

  /// إعادة إرسال OTP مع التحقق من الأمان
  Future<int> resendOTP() async {
    try {
      if (!_isUserLoggedIn()) {
        throw OTPException('يجب تسجيل الدخول أولاً');
      }

      final userId = _auth.currentUser!.uid;

      // التحقق من Rate Limiting
      if (!await _checkRateLimit(userId, 'resend_otp')) {
        throw OTPException('تم تجاوز حد الطلبات. يرجى المحاولة لاحقاً',
            code: 'rate_limited');
      }

      // جلب البيانات المخزنة للحصول على رقم الهاتف
      final storedData = await _getStoredOTPData(userId);
      if (storedData == null || storedData['phoneNumber'] == null) {
        throw OTPException('لا يوجد OTP نشط لإعادة الإرسال');
      }

      final phoneNumber = storedData['phoneNumber'] as String;

      // إعادة إرسال OTP
      return await sendOTP(phoneNumber);
    } on FirebaseFunctionsException catch (e) {
      throw OTPException(e.message ?? 'خطأ في إعادة الإرسال');
    } catch (e) {
      throw OTPException('فشل في إعادة الإرسال: ${e.toString()}');
    }
  }

  /// ==================== دوال المراقبة ====================

  /// بدء مراقبة الوقت المتبقي
  void _startTimerMonitoring(int seconds) {
    _stopTimerMonitoring();

    _remainingSeconds = seconds;
    _remainingTimeController.add(_remainingSeconds);

    _statusTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _remainingSeconds--;
      _remainingTimeController.add(_remainingSeconds);

      if (_remainingSeconds <= 0) {
        _stopTimerMonitoring();
      }
    });
  }

  /// إيقاف مراقبة الوقت
  void _stopTimerMonitoring() {
    _statusTimer?.cancel();
    _statusTimer = null;
    _remainingSeconds = 0;
  }

  /// ==================== دوال الأمان المحسنة ====================

  /// إخفاء رقم الهاتف للتسجيل
  String _maskPhoneNumber(String phone) {
    if (phone.length < 8) return '***';
    return '${phone.substring(0, 3)}****${phone.substring(phone.length - 2)}';
  }

  /// جلب بيانات OTP المخزنة
  Future<Map<String, dynamic>?> _getStoredOTPData(String userId) async {
    final doc = await _firestore
        .collection(RewardsConstants.collectionOtpStorage)
        .doc(userId)
        .get();

    return doc.exists ? doc.data() : null;
  }

  /// التحقق من Rate Limiting
  Future<bool> _checkRateLimit(String identifier, String action) async {
    final now = DateTime.now();
    final windowStart = now.subtract(RewardsConstants.rateLimitWindow);

    // عد الطلبات في النافذة الزمنية
    final query = await _firestore
        .collection(RewardsConstants.collectionRateLimits)
        .where('identifier', isEqualTo: identifier)
        .where('action', isEqualTo: action)
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(windowStart))
        .get();

    final requestCount = query.docs.length;

    // إذا تجاوز الحد، ارفض الطلب
    if (requestCount >= RewardsConstants.rateLimitMaxRequests) {
      return false;
    }

    // سجل الطلب الجديد
    await _firestore.collection(RewardsConstants.collectionRateLimits).add({
      'identifier': identifier,
      'action': action,
      'timestamp': FieldValue.serverTimestamp(),
    });

    return true;
  }

  /// تسجيل في Audit Log
  Future<void> _auditLog(String action, Map<String, dynamic> details) async {
    try {
      await _firestore.collection(RewardsConstants.collectionAuditLogs).add({
        'action': action,
        'details': details,
        'userId': _auth.currentUser?.uid,
        'timestamp': FieldValue.serverTimestamp(),
        'ipAddress': null, // يمكن إضافته لاحقاً
        'userAgent': null, // يمكن إضافته لاحقاً
      });
    } catch (e) {
      debugPrint('فشل في تسجيل Audit Log: $e');
    }
  }

  /// ==================== دوال التحقق المساعدة ====================

  /// التحقق من تسجيل الدخول
  bool _isUserLoggedIn() {
    return _auth.currentUser != null;
  }

  /// التحقق من صحة رقم الهاتف باستخدام مكتبة phone_number
  Future<bool> _isValidPhoneNumber(String phoneNumber) async {
    try {
      // تنسيق رقم الهاتف أولاً
      final normalized = normalizePhoneNumber(phoneNumber);
      final parsed = await _phoneUtil.parse(normalized);
      // التحقق من أن رقم الهاتف ليس مفرغاً
      return parsed.toString().isNotEmpty;
    } catch (e) {
      debugPrint('خطأ في التحقق من رقم الهاتف: $e');
      return false;
    }
  }

  /// تنظيف الموارد
  void dispose() {
    _stopTimerMonitoring();
    _remainingTimeController.close();
  }

  /// ==================== دوال المساعدة ====================

  /// تحويل رقم الهاتف إلى صيغة دولية
  static String normalizePhoneNumber(String phoneNumber) {
    String cleaned = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (cleaned.startsWith('0')) {
      cleaned = '+966${cleaned.substring(1)}';
    }

    if (!cleaned.startsWith('+')) {
      cleaned = '+$cleaned';
    }

    return cleaned;
  }

  /// إخفاء معظم أرقام الهاتف مع إظهار آخر 2 رقم
  static String maskPhoneNumber(String phoneNumber) {
    if (phoneNumber.length < 3) return phoneNumber;
    return phoneNumber.replaceAll(RegExp(r'\d(?=\d{2})'), '*');
  }

  /// التحقق من هل OTP قريب من الانتهاء (أقل من دقيقة)
  bool isOtpExpiringSoon() {
    return _remainingSeconds > 0 && _remainingSeconds <= 60;
  }

  /// الحصول على الوقت المتبقي بصيغة MM:SS
  String getFormattedRemainingTime() {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    final minutesStr = minutes.toString().padLeft(2, '0');
    final secondsStr = seconds.toString().padLeft(2, '0');
    return '$minutesStr:$secondsStr';
  }
}
