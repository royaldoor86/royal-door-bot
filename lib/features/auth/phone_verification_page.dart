import 'package:flutter/material.dart';
import '../../services/otp_service.dart';
import '../../theme/app_theme.dart';

/// صفحة إدخال رقم الهاتف والتحقق عبر OTP
class PhoneVerificationPage extends StatefulWidget {
  final VoidCallback? onVerificationComplete;

  const PhoneVerificationPage({
    super.key,
    this.onVerificationComplete,
  });

  @override
  State<PhoneVerificationPage> createState() => _PhoneVerificationPageState();
}

class _PhoneVerificationPageState extends State<PhoneVerificationPage>
    with WidgetsBindingObserver {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final OTPService _otpService = OTPService();

  bool _isLoading = false;
  bool _showOTPInput = false;
  String? _errorMessage;
  String? _successMessage;
  int _remainingSeconds = 0;

  // متغیرات الدولة
  String _selectedCountryCode = '+966'; // افتراضي للسعودية
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenToOTPTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _phoneController.dispose();
    _otpController.dispose();
    _otpService.dispose();
    super.dispose();
  }

  /// الاستماع للوقت المتبقي
  void _listenToOTPTimer() {
    _otpService.remainingTimeStream.listen((remainingSeconds) {
      if (mounted) {
        setState(() {
          _remainingSeconds = remainingSeconds;
          _canResend = remainingSeconds == 0;
        });
      }
    });
  }

  /// إرسال OTP
  Future<void> _sendOTP() async {
    final phone = _selectedCountryCode + _phoneController.text.trim();

    if (_phoneController.text.isEmpty) {
      _showError('يرجى إدخال رقم الهاتف');
      return;
    }

    if (_phoneController.text.length < 8 || _phoneController.text.length > 13) {
      _showError('رقم الهاتف غير صحيح');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _otpService.sendOTP(phone);

      setState(() {
        _showOTPInput = true;
        _isLoading = false;
        _successMessage = 'تم إرسال الرمز إلى $phone';
      });

      _showSuccess(_successMessage!);

      // تنظيف رسالة النجاح بعد 3 ثوان
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _successMessage = null);
        }
      });
    } catch (e) {
      _showError(_extractErrorMessage(e));
      setState(() => _isLoading = false);
    }
  }

  /// التحقق من OTP
  Future<void> _verifyOTP() async {
    final otp = _otpController.text.trim();

    if (otp.isEmpty || otp.length != 6) {
      _showError('الرمز يجب أن يكون 6 أرقام');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final phone = _phoneController.text.trim();
      final fullPhoneNumber = "$_selectedCountryCode$phone";
      final verified = await _otpService.verifyOTP(otp, phoneNumber: fullPhoneNumber);

      if (verified) {
        setState(() {
          _isLoading = false;
          _successMessage = 'تم التحقق بنجاح!';
        });

        _showSuccess('تم التحقق من رقم الهاتف بنجاح');

        // تأخير قليل قبل إغلاق الصفحة
        await Future.delayed(const Duration(milliseconds: 800));

        if (mounted) {
          Navigator.of(context).pop(true);
          widget.onVerificationComplete?.call();
        }
      }
    } catch (e) {
      _showError(_extractErrorMessage(e));
      setState(() => _isLoading = false);
    }
  }

  /// إعادة إرسال OTP
  Future<void> _resendOTP() async {
    if (!_canResend) return;

    setState(() => _isLoading = true);

    try {
      await _otpService.resendOTP();
      _showSuccess('تم إعادة إرسال الرمز');
    } catch (e) {
      _showError(_extractErrorMessage(e));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// ==================== دوال المساعدة ====================

  void _showError(String message) {
    if (!mounted) return;

    setState(() => _errorMessage = message);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _extractErrorMessage(dynamic error) {
    if (error is OTPException) {
      return error.message;
    }
    return error.toString();
  }

  String _getFormattedTime() {
    if (_remainingSeconds <= 0) return '00:00';

    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// ==================== واجهة المستخدم ====================

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_showOTPInput,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _showOTPInput) {
          setState(() {
            _showOTPInput = false;
            _otpController.clear();
            _errorMessage = null;
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundDark,
        appBar: AppBar(
          backgroundColor: AppTheme.backgroundDark,
          elevation: 0,
          leading: _showOTPInput
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppTheme.accentWarm),
                  onPressed: () {
                    setState(() {
                      _showOTPInput = false;
                      _otpController.clear();
                      _errorMessage = null;
                    });
                  },
                )
              : null,
          title: Text(
            _showOTPInput ? 'التحقق من الرمز' : 'التحقق من الهاتف',
            style: const TextStyle(
              color: AppTheme.accentWarm,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _showOTPInput
                ? _buildOTPVerificationUI()
                : _buildPhoneInputUI(),
          ),
        ),
      ),
    );
  }

  /// واجهة إدخال رقم الهاتف
  Widget _buildPhoneInputUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),

        // أيقونة الهاتف
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppTheme.accentWarm,
                AppTheme.accentWarm.withValues(alpha: 0.6),
              ],
            ),
          ),
          child: const Icon(
            Icons.check_circle_outline,
            size: 50,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 30),

        // العنوان
        const Text(
          'التحقق من رقم الهاتف',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 12),

        // الوصف
        Text(
          'سنرسل رمز تحقق إلى رقم الهاتف الخاص بك',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[400],
          ),
        ),

        const SizedBox(height: 40),

        // حقل إدخال رقم الهاتف
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _errorMessage != null
                  ? Colors.red
                  : AppTheme.accentWarm.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              // اختيار رمز الدولة
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButton<String>(
                  value: _selectedCountryCode,
                  dropdownColor: Colors.grey.shade900,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (value) {
                    setState(() => _selectedCountryCode = value!);
                  },
                  items: const [
                    // Middle East & North Africa
                    DropdownMenuItem(
                        value: '+966', child: Text('🇸🇦 Saudi Arabia +966')),
                    DropdownMenuItem(
                        value: '+971', child: Text('🇦🇪 UAE +971')),
                    DropdownMenuItem(
                        value: '+970', child: Text('🇵🇸 Palestine +970')),
                    DropdownMenuItem(
                        value: '+968', child: Text('🇴🇲 Oman +968')),
                    DropdownMenuItem(
                        value: '+965', child: Text('🇰🇼 Kuwait +965')),
                    DropdownMenuItem(
                        value: '+974', child: Text('🇶🇦 Qatar +974')),
                    DropdownMenuItem(
                        value: '+973', child: Text('🇧🇭 Bahrain +973')),
                    DropdownMenuItem(
                        value: '+20', child: Text('🇪🇬 Egypt +20')),
                    DropdownMenuItem(
                        value: '+212', child: Text('🇲🇦 Morocco +212')),
                    DropdownMenuItem(
                        value: '+216', child: Text('🇹🇳 Tunisia +216')),
                    DropdownMenuItem(
                        value: '+213', child: Text('🇩🇿 Algeria +213')),
                    DropdownMenuItem(
                        value: '+218', child: Text('🇱🇾 Libya +218')),
                    DropdownMenuItem(
                        value: '+220', child: Text('🇲🇷 Mauritania +220')),
                    DropdownMenuItem(
                        value: '+221', child: Text('🇸🇳 Senegal +221')),
                    DropdownMenuItem(
                        value: '+222', child: Text('🇲🇷 Mauritania Alt +222')),
                    DropdownMenuItem(
                        value: '+223', child: Text('🇲🇱 Mali +223')),
                    DropdownMenuItem(
                        value: '+224', child: Text('🇬🇳 Guinea +224')),
                    DropdownMenuItem(
                        value: '+225', child: Text('🇨🇮 Ivory Coast +225')),
                    DropdownMenuItem(
                        value: '+226', child: Text('🇧🇫 Burkina Faso +226')),
                    DropdownMenuItem(
                        value: '+227', child: Text('🇳🇪 Niger +227')),
                    DropdownMenuItem(
                        value: '+228', child: Text('🇹🇬 Togo +228')),
                    DropdownMenuItem(
                        value: '+229', child: Text('🇧🇯 Benin +229')),
                    DropdownMenuItem(
                        value: '+230', child: Text('🇲🇺 Mauritius +230')),
                    DropdownMenuItem(
                        value: '+231', child: Text('🇱🇷 Liberia +231')),
                    DropdownMenuItem(
                        value: '+232', child: Text('🇸🇱 Sierra Leone +232')),
                    DropdownMenuItem(
                        value: '+233', child: Text('🇬🇭 Ghana +233')),
                    DropdownMenuItem(
                        value: '+234', child: Text('🇳🇬 Nigeria +234')),
                    DropdownMenuItem(
                        value: '+235', child: Text('🇹🇩 Chad +235')),
                    DropdownMenuItem(
                        value: '+236',
                        child: Text('🇨🇫 Central African Republic +236')),
                    DropdownMenuItem(
                        value: '+237', child: Text('🇨🇲 Cameroon +237')),
                    DropdownMenuItem(
                        value: '+238', child: Text('🇨🇻 Cape Verde +238')),
                    DropdownMenuItem(
                        value: '+239', child: Text('🇸🇹 São Tomé +239')),
                    DropdownMenuItem(
                        value: '+240',
                        child: Text('🇬🇶 Equatorial Guinea +240')),
                    DropdownMenuItem(
                        value: '+241', child: Text('🇬🇦 Gabon +241')),
                    DropdownMenuItem(
                        value: '+242', child: Text('🇨🇬 Congo +242')),
                    DropdownMenuItem(
                        value: '+243', child: Text('🇨🇩 DR Congo +243')),
                    DropdownMenuItem(
                        value: '+244', child: Text('🇦🇴 Angola +244')),
                    DropdownMenuItem(
                        value: '+245', child: Text('🇬🇼 Guinea-Bissau +245')),
                    DropdownMenuItem(
                        value: '+246', child: Text('🇩🇬 Djibouti +246')),
                    DropdownMenuItem(
                        value: '+248', child: Text('🇸🇨 Seychelles +248')),
                    DropdownMenuItem(
                        value: '+249', child: Text('🇸🇩 Sudan +249')),
                    DropdownMenuItem(
                        value: '+250', child: Text('🇷🇼 Rwanda +250')),
                    DropdownMenuItem(
                        value: '+251', child: Text('🇪🇹 Ethiopia +251')),
                    DropdownMenuItem(
                        value: '+252', child: Text('🇸🇴 Somalia +252')),
                    DropdownMenuItem(
                        value: '+253', child: Text('🇩🇯 Djibouti Alt +253')),
                    DropdownMenuItem(
                        value: '+254', child: Text('🇰🇪 Kenya +254')),
                    DropdownMenuItem(
                        value: '+255', child: Text('🇹🇿 Tanzania +255')),
                    DropdownMenuItem(
                        value: '+256', child: Text('🇺🇬 Uganda +256')),
                    DropdownMenuItem(
                        value: '+257', child: Text('🇧🇮 Burundi +257')),
                    DropdownMenuItem(
                        value: '+258', child: Text('🇲🇿 Mozambique +258')),
                    DropdownMenuItem(
                        value: '+260', child: Text('🇿🇲 Zambia +260')),
                    DropdownMenuItem(
                        value: '+261', child: Text('🇲🇬 Madagascar +261')),
                    DropdownMenuItem(
                        value: '+262', child: Text('🇷🇪 Reunion +262')),
                    DropdownMenuItem(
                        value: '+263', child: Text('🇿🇼 Zimbabwe +263')),
                    DropdownMenuItem(
                        value: '+264', child: Text('🇳🇦 Namibia +264')),
                    DropdownMenuItem(
                        value: '+265', child: Text('🇲🇼 Malawi +265')),
                    DropdownMenuItem(
                        value: '+266', child: Text('🇱🇸 Lesotho +266')),
                    DropdownMenuItem(
                        value: '+267', child: Text('🇧🇼 Botswana +267')),
                    DropdownMenuItem(
                        value: '+268', child: Text('🇪🇿 Eswatini +268')),
                    DropdownMenuItem(
                        value: '+269', child: Text('🇰🇲 Comoros +269')),
                    DropdownMenuItem(
                        value: '+290', child: Text('🇹🇦 Saint Helena +290')),
                    DropdownMenuItem(
                        value: '+291', child: Text('🇪🇷 Eritrea +291')),
                    DropdownMenuItem(
                        value: '+297', child: Text('🇦🇼 Aruba +297')),
                    DropdownMenuItem(
                        value: '+298', child: Text('🇫🇴 Faroe Islands +298')),
                    DropdownMenuItem(
                        value: '+299', child: Text('🇬🇱 Greenland +299')),
                    DropdownMenuItem(
                        value: '+350', child: Text('🇬🇮 Gibraltar +350')),
                    DropdownMenuItem(
                        value: '+351', child: Text('🇵🇹 Portugal +351')),
                    DropdownMenuItem(
                        value: '+352', child: Text('🇱🇺 Luxembourg +352')),
                    DropdownMenuItem(
                        value: '+353', child: Text('🇮🇪 Ireland +353')),
                    DropdownMenuItem(
                        value: '+354', child: Text('🇮🇸 Iceland +354')),
                    DropdownMenuItem(
                        value: '+355', child: Text('🇦🇱 Albania +355')),
                    DropdownMenuItem(
                        value: '+356', child: Text('🇲🇹 Malta +356')),
                    DropdownMenuItem(
                        value: '+357', child: Text('🇨🇾 Cyprus +357')),
                    DropdownMenuItem(
                        value: '+358', child: Text('🇫🇮 Finland +358')),
                    DropdownMenuItem(
                        value: '+359', child: Text('🇧🇬 Bulgaria +359')),
                    DropdownMenuItem(
                        value: '+370', child: Text('🇱🇹 Lithuania +370')),
                    DropdownMenuItem(
                        value: '+371', child: Text('🇱🇻 Latvia +371')),
                    DropdownMenuItem(
                        value: '+372', child: Text('🇪🇪 Estonia +372')),
                    DropdownMenuItem(
                        value: '+373', child: Text('🇲🇩 Moldova +373')),
                    DropdownMenuItem(
                        value: '+374', child: Text('🇦🇲 Armenia +374')),
                    DropdownMenuItem(
                        value: '+375', child: Text('🇧🇾 Belarus +375')),
                    DropdownMenuItem(
                        value: '+376', child: Text('🇦🇩 Andorra +376')),
                    DropdownMenuItem(
                        value: '+377', child: Text('🇲🇨 Monaco +377')),
                    DropdownMenuItem(
                        value: '+378', child: Text('🇸🇲 San Marino +378')),
                    DropdownMenuItem(
                        value: '+380', child: Text('🇺🇦 Ukraine +380')),
                    DropdownMenuItem(
                        value: '+381', child: Text('🇷🇸 Serbia +381')),
                    DropdownMenuItem(
                        value: '+382', child: Text('🇲🇪 Montenegro +382')),
                    DropdownMenuItem(
                        value: '+383', child: Text('🇽🇰 Kosovo +383')),
                  ],
                  underline: const SizedBox(),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 30,
                width: 1,
                color: Colors.grey.shade700,
              ),
              const SizedBox(width: 12),
              // حقل رقم الهاتف
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  enabled: !_isLoading,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'أدخل رقم الهاتف',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),

        // رسالة الخطأ
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),

        const SizedBox(height: 40),

        // زر الإرسال
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _sendOTP,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentWarm,
              disabledBackgroundColor: Colors.grey.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'إرسال الرمز',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 20),

        // نصيحة أمان
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade900.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.blue.shade400.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.info, color: Colors.blue[300], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'سيتم إرسال رمز مكون من 6 أرقام إلى رقم الهاتف',
                  style: TextStyle(
                    color: Colors.blue[300],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// واجهة إدخال رمز OTP
  Widget _buildOTPVerificationUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),

        // أيقونة النجاح
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppTheme.accentWarm,
                AppTheme.accentWarm.withValues(alpha: 0.6),
              ],
            ),
          ),
          child: const Icon(
            Icons.mail_outline,
            size: 50,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 30),

        // العنوان
        const Text(
          'أدخل الرمز',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 8),

        // الوصف
        Text(
          'تم إرسال رمز تحقق من 6 أرقام',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[400],
          ),
        ),

        const SizedBox(height: 40),

        // حقل إدخال الرمز
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _errorMessage != null
                  ? Colors.red
                  : AppTheme.primaryColor.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: TextField(
            controller: _otpController,
            keyboardType: TextInputType.number,
            enabled: !_isLoading,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              letterSpacing: 8,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: '000000',
              hintStyle: TextStyle(
                color: Colors.grey[700],
                fontSize: 32,
              ),
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),

        // رسالة الخطأ
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),

        const SizedBox(height: 40),

        // زر التحقق
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _verifyOTP,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              disabledBackgroundColor: Colors.grey.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'تحقق الآن',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),

        const SizedBox(height: 20),

        // شريط الوقت المتبقي
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _otpService.isOtpExpiringSoon()
                ? Colors.orange.shade900.withValues(alpha: 0.3)
                : Colors.blue.shade900.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _otpService.isOtpExpiringSoon()
                  ? Colors.orange.shade400.withValues(alpha: 0.5)
                  : Colors.blue.shade400.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: _otpService.isOtpExpiringSoon()
                        ? Colors.orange[300]
                        : Colors.blue[300],
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'الوقت المتبقي:',
                    style: TextStyle(
                      color: _otpService.isOtpExpiringSoon()
                          ? Colors.orange[300]
                          : Colors.blue[300],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Text(
                _getFormattedTime(),
                style: TextStyle(
                  color: _otpService.isOtpExpiringSoon()
                      ? Colors.orange[300]
                      : Colors.blue[300],
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // زر إعادة الإرسال
        if (_canResend)
          TextButton(
            onPressed: _resendOTP,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.refresh, color: AppTheme.accentWarm, size: 18),
                const SizedBox(width: 8),
                Text(
                  'إعادة إرسال الرمز',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'إعادة الإرسال في ${_getFormattedTime()}',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 12,
              ),
            ),
          ),

        const SizedBox(height: 20),

        // نصيحة أمان
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.yellow.shade900.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.yellow.shade400.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.yellow[300], size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'لا تشارك هذا الرمز مع أحد',
                  style: TextStyle(
                    color: Colors.yellow[300],
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
