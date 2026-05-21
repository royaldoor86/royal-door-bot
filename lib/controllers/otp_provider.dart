import 'package:flutter/foundation.dart';
import '../services/otp_service.dart';

/// Provider Model لإدارة حالة OTP
/// يستخدم مع Provider package للحصول على تحديثات حالة فورية
class OTPProvider extends ChangeNotifier {
  final OTPService _otpService = OTPService();

  // متغیرات الحالة
  bool _isLoading = false;
  bool _showOTPInput = false;
  bool _otpSent = false;
  String? _errorMessage;
  String? _successMessage;
  int _remainingSeconds = 0;
  String? _phoneNumber;
  int _verifyAttempts = 0;

  // Getters
  bool get isLoading => _isLoading;
  bool get showOTPInput => _showOTPInput;
  bool get otpSent => _otpSent;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  int get remainingSeconds => _remainingSeconds;
  String? get phoneNumber => _phoneNumber;
  int get verifyAttempts => _verifyAttempts;
  bool get canResend => _remainingSeconds == 0;
  bool get isOTPExpiringSoon =>
      _remainingSeconds > 0 && _remainingSeconds <= 60;

  OTPProvider() {
    _initializeOTPListener();
  }

  /// الاستماع لتحديثات المُؤقت
  void _initializeOTPListener() {
    _otpService.remainingTimeStream.listen((remainingSeconds) {
      _remainingSeconds = remainingSeconds;
      notifyListeners();
    });
  }

  /// إرسال OTP
  Future<bool> sendOTP(String phoneNumber) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
      notifyListeners();

      await _otpService.sendOTP(phoneNumber);

      _phoneNumber = phoneNumber;
      _showOTPInput = true;
      _otpSent = true;
      _successMessage = 'تم إرسال الرمز إلى $phoneNumber';

      _isLoading = false;
      notifyListeners();

      // تنظيف رسالة النجاح
      Future.delayed(const Duration(seconds: 3), () {
        _successMessage = null;
        notifyListeners();
      });

      return true;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// التحقق من OTP
  Future<bool> verifyOTP(String otp) async {
    try {
      if (_phoneNumber == null) {
        _errorMessage = 'رقم الهاتف غير متوفر';
        notifyListeners();
        return false;
      }

      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final verified = await _otpService.verifyOTP(otp, phoneNumber: _phoneNumber!);

      if (verified) {
        _successMessage = 'تم التحقق بنجاح!';
        _isLoading = false;
        notifyListeners();

        // إعادة تعيين الحالة
        Future.delayed(const Duration(milliseconds: 800), resetOTPState);

        return true;
      }

      _errorMessage = 'فشل التحقق';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      _verifyAttempts++;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// إعادة إرسال OTP
  Future<bool> resendOTP() async {
    if (!canResend) return false;

    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await _otpService.resendOTP();

      _successMessage = 'تم إعادة إرسال الرمز';
      _isLoading = false;
      notifyListeners();

      Future.delayed(const Duration(seconds: 3), () {
        _successMessage = null;
        notifyListeners();
      });

      return true;
    } catch (e) {
      _errorMessage = _extractErrorMessage(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// فحص حالة OTP
  Future<void> checkOTPStatus() async {
    try {
      final otpData = _otpService.checkOTPStatus();
      _verifyAttempts = otpData.verifyAttempts;
      _remainingSeconds = otpData.remainingSeconds;
      notifyListeners();
    } catch (e) {
      // تجاهل الخطأ - قد لا يكون هناك OTP نشط
    }
  }

  /// الرجوع إلى إدخال الهاتف
  void goBackToPhoneInput() {
    _showOTPInput = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// إعادة تعيين الحالة
  void resetOTPState() {
    _showOTPInput = false;
    _otpSent = false;
    _phoneNumber = null;
    _verifyAttempts = 0;
    _remainingSeconds = 0;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  /// مسح رسائل الخطأ
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// مسح رسائل النجاح
  void clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }

  /// استخراج رسالة الخطأ من الاستثناء
  String _extractErrorMessage(dynamic error) {
    if (error is OTPException) {
      return error.message;
    }
    return error.toString();
  }

  /// الحصول على الوقت بصيغة MM:SS
  String getFormattedTime() {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _otpService.dispose();
    super.dispose();
  }
}
