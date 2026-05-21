import 'package:flutter/material.dart';
import '../../models/country_config.dart';
import '../../core/constants/countries.dart';
import '../../services/otp_service_enhanced.dart';
import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';
import '../../theme/reusable_widgets.dart';

/// صفحة التحقق من الهاتف المحسّنة مع دعم 96 دولة
class EnhancedPhoneVerificationPage extends StatefulWidget {
  final Function(String, String)?
      onVerificationComplete; // phoneNumber, countryCode
  final String? initialCountryCode;
  final bool isRegistration;

  const EnhancedPhoneVerificationPage({
    super.key,
    this.onVerificationComplete,
    this.initialCountryCode,
    this.isRegistration = false,
  });

  @override
  State<EnhancedPhoneVerificationPage> createState() =>
      _EnhancedPhoneVerificationPageState();
}

class _EnhancedPhoneVerificationPageState
    extends State<EnhancedPhoneVerificationPage> {
  late OTPService _otpService;
  late TextEditingController _phoneController;
  late TextEditingController _otpController;
  late TextEditingController _countrySearchController;

  String? _selectedCountryCode;
  CountryConfig? _selectedCountry;
  bool _showOTPInput = false;
  bool _isLoading = false;
  String? _errorMessage;
  int _remainingSeconds = 0;
  int _verifyAttempts = 0;
  int _maxVerifyAttempts = 5;
  bool _showCountryList = false;
  List<CountryConfig> _filteredCountries = [];

  @override
  void initState() {
    super.initState();
    _otpService = OTPService();
    _phoneController = TextEditingController();
    _otpController = TextEditingController();
    _countrySearchController = TextEditingController();

    // تعيين الدولة الافتراضية
    _selectedCountryCode = widget.initialCountryCode ?? 'SA';
    _selectedCountry = CountriesDatabase.getCountry(_selectedCountryCode!);
    _filteredCountries = CountriesDatabase.getAllCountries();

    // الاستماع إلى تدفق الوقت المتبقي
    _otpService.remainingTimeStream.listen((seconds) {
      if (mounted) {
        setState(() => _remainingSeconds = seconds);
      }
    });

    // الاستماع إلى تدفق حالة OTP
    _otpService.otpStatusStream.listen((data) {
      if (mounted) {
        setState(() {
          _verifyAttempts = data.verifyAttempts;
          _maxVerifyAttempts = data.maxVerifyAttempts;
        });
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _countrySearchController.dispose();
    _otpService.dispose();
    super.dispose();
  }

  /// إرسال OTP إلى رقم الهاتف
  Future<void> _sendOTP() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      _showError('الرجاء إدخال رقم الهاتف');
      return;
    }

    if (_selectedCountryCode == null) {
      _showError('الرجاء تحديد الدولة');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _otpService.sendOTP(
        phone,
        countryCode: _selectedCountryCode,
        allowAnonymous: widget.isRegistration,
      );

      if (mounted) {
        setState(() {
          _showOTPInput = true;
          _isLoading = false;
        });

        _showSuccess('تم إرسال رمز التحقق إلى رقم الهاتف');
      }
    } catch (e) {
      if (mounted) {
        final errorMessage =
            e is OTPException ? e.getLocalizedMessage() : e.toString();
        _showError(errorMessage);
        setState(() => _isLoading = false);
      }
    }
  }

  /// التحقق من رمز OTP
  Future<void> _verifyOTP() async {
    final otp = _otpController.text.trim();

    if (otp.isEmpty || otp.length != 6) {
      _showError('الرمز يجب أن يكون 6 أرقام');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final verified = await _otpService.verifyOTP(otp, allowAnonymous: widget.isRegistration);

      if (verified) {
        setState(() {
          _isLoading = false;
        });

        _showSuccess('تم التحقق من رقم الهاتف بنجاح');

        await Future.delayed(const Duration(milliseconds: 800));

        if (mounted) {
          final formattedPhone = _selectedCountry?.formatPhoneNumber(
                _phoneController.text.trim(),
              ) ??
              _phoneController.text.trim();

          Navigator.of(context).pop(true);
          widget.onVerificationComplete?.call(
            formattedPhone,
            _selectedCountryCode!,
          );
        }
      } else {
        setState(() => _isLoading = false);
        _showError('الرمز غير صحيح. يرجى المحاولة مرة أخرى');
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e is OTPException
            ? e.getLocalizedMessage()
            : 'فشل التحقق. حاول مرة أخرى';
        _showError(errorMessage);
        setState(() => _isLoading = false);
      }
    }
  }

  /// إعادة إرسال OTP
  Future<void> _resendOTP() async {
    if (_remainingSeconds > 0) {
      _showError(
        'انتظر $_remainingSeconds ثانية قبل إعادة الإرسال',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _otpService.resendOTP(allowAnonymous: widget.isRegistration);
      if (mounted) {
        _showSuccess('تم إعادة إرسال الرمز');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e is OTPException
            ? e.getLocalizedMessage()
            : 'فشل في إعادة الإرسال';
        _showError(errorMessage);
        setState(() => _isLoading = false);
      }
    }
  }

  /// البحث عن الدول
  void _searchCountries(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCountries = CountriesDatabase.getAllCountries();
      } else {
        _filteredCountries = CountriesDatabase.searchCountries(query);
      }
    });
  }

  /// تحديد دولة
  void _selectCountry(CountryConfig country) {
    setState(() {
      _selectedCountryCode = country.countryCode;
      _selectedCountry = country;
      _showCountryList = false;
      _countrySearchController.clear();
      _filteredCountries = CountriesDatabase.getAllCountries();
    });
  }

  /// عرض رسالة الخطأ
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

  /// عرض رسالة النجاح
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

  /// الحصول على الوقت المتبقي بصيغة مقروءة
  String _getFormattedTime() {
    if (_remainingSeconds <= 0) return '00:00';
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_showOTPInput) {
          setState(() {
            _showOTPInput = false;
            _otpController.clear();
            _errorMessage = null;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        body: AppTheme.background(
          child: SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(DesignTokens.spacingXl),
                      child: _showOTPInput ? _buildOTPInputUI() : _buildPhoneInputUI(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingMd,
        vertical: DesignTokens.spacingSm,
      ),
      child: Row(
        children: [
          if (_showOTPInput)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: DesignTokens.primaryGold),
              onPressed: () {
                setState(() {
                  _showOTPInput = false;
                  _otpController.clear();
                  _errorMessage = null;
                });
                // إعادة تعيين الخدمة
                _otpService.reset();
              },
            )
          else
            const BackButton(color: DesignTokens.primaryGold),
          const Spacer(),
          HeadingText(
            _showOTPInput ? 'التحقق من الرمز' : 'التحقق من الهاتف',
            fontSize: DesignTokens.fontSizeXl,
            color: DesignTokens.primaryGold,
          ),
          const Spacer(),
          const SizedBox(width: 48), // Balancing for the back button
        ],
      ),
    );
  }

  /// واجهة إدخال رقم الهاتف
  Widget _buildPhoneInputUI() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // عنوان
        const HeadingText(
          'أدخل رقم الهاتف',
          fontSize: DesignTokens.fontSizeXl3,
        ),
        const SizedBox(height: DesignTokens.spacingSm),
        BodyText(
          'سنرسل لك رمز تحقق عبر الرسائل النصية',
          color: DesignTokens.neutralWhite.withValues(alpha: 0.7),
        ),
        const SizedBox(height: DesignTokens.spacingXl2),

        // اختيار الدولة
        const BodyText(
          'اختر الدولة',
          fontSize: DesignTokens.fontSizeSm,
          fontWeight: DesignTokens.fontWeightSemiBold,
          color: DesignTokens.primaryGold,
        ),
        const SizedBox(height: DesignTokens.spacingSm),
        _buildCountrySelector(),
        const SizedBox(height: DesignTokens.spacingLg),

        // إدخال رقم الهاتف
        const BodyText(
          'رقم الهاتف',
          fontSize: DesignTokens.fontSizeSm,
          fontWeight: DesignTokens.fontWeightSemiBold,
          color: DesignTokens.primaryGold,
        ),
        const SizedBox(height: DesignTokens.spacingSm),
        _buildPhoneNumberInput(),
        const SizedBox(height: DesignTokens.spacingXl),

        // رسالة الخطأ
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.spacingLg),
            child: GlassCard(
              padding: const EdgeInsets.all(DesignTokens.spacingMd),
              borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
              hasBorder: true,
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: DesignTokens.semanticError, size: 20),
                  const SizedBox(width: DesignTokens.spacingSm),
                  Expanded(
                    child: BodyText(
                      _errorMessage!,
                      color: DesignTokens.semanticError,
                      fontSize: DesignTokens.fontSizeSm,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // زر الإرسال
        RoyalButton(
          label: 'إرسال الرمز',
          onPressed: _sendOTP,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  /// واجهة إدخال رمز OTP
  Widget _buildOTPInputUI() {
    final maskedPhone = _selectedCountry?.maskPhoneNumber(
          _phoneController.text.trim(),
        ) ??
        _phoneController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // عنوان
        const HeadingText(
          'أدخل رمز التحقق',
          fontSize: DesignTokens.fontSizeXl3,
        ),
        const SizedBox(height: DesignTokens.spacingSm),
        BodyText(
          'أرسلنا رمز التحقق إلى $maskedPhone',
          color: DesignTokens.neutralWhite.withValues(alpha: 0.7),
        ),
        const SizedBox(height: DesignTokens.spacingXl2),

        // مؤشر الوقت المتبقي
        if (_remainingSeconds > 0)
          GlassCard(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingLg,
              vertical: DesignTokens.spacingMd,
            ),
            borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
            child: Row(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  color: DesignTokens.primaryGold,
                  size: 20,
                ),
                const SizedBox(width: DesignTokens.spacingMd),
                BodyText(
                  'ينتهي الرمز في: ${_getFormattedTime()}',
                  color: DesignTokens.primaryGold,
                  fontWeight: DesignTokens.fontWeightSemiBold,
                ),
              ],
            ),
          ),
        const SizedBox(height: DesignTokens.spacingXl),

        // حقل إدخال OTP
        Container(
          decoration: BoxDecoration(
            color: DesignTokens.backgroundDarkMedium,
            borderRadius: BorderRadius.circular(DesignTokens.borderRadiusLg),
            border: Border.all(
              color: _errorMessage != null
                  ? DesignTokens.semanticError
                  : DesignTokens.primaryGold.withValues(alpha: 0.3),
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
              color: DesignTokens.neutralWhite,
              fontSize: 32,
              letterSpacing: 8,
              fontWeight: DesignTokens.fontWeightBold,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: '000000',
              hintStyle: TextStyle(
                color: DesignTokens.neutralWhite.withValues(alpha: 0.2),
                fontSize: 32,
              ),
              counterText: '',
              contentPadding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingLg),
            ),
          ),
        ),
        const SizedBox(height: DesignTokens.spacingMd),

        // عرض المحاولات المتبقية
        if (_verifyAttempts > 0)
          CaptionText(
            'المحاولات المتبقية: ${_maxVerifyAttempts - _verifyAttempts}',
            color: _verifyAttempts >= _maxVerifyAttempts - 2
                ? DesignTokens.semanticError
                : DesignTokens.neutralGray400,
          ),
        const SizedBox(height: DesignTokens.spacingLg),

        // رسالة الخطأ
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(bottom: DesignTokens.spacingLg),
            child: GlassCard(
              padding: const EdgeInsets.all(DesignTokens.spacingMd),
              borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: DesignTokens.semanticError, size: 20),
                  const SizedBox(width: DesignTokens.spacingSm),
                  Expanded(
                    child: BodyText(
                      _errorMessage!,
                      color: DesignTokens.semanticError,
                      fontSize: DesignTokens.fontSizeSm,
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: DesignTokens.spacingLg),

        // زر التحقق
        RoyalButton(
          label: 'تحقق الآن',
          onPressed: _verifyOTP,
          isLoading: _isLoading,
        ),
        const SizedBox(height: DesignTokens.spacingLg),

        // زر إعادة الإرسال
        SecondaryButton(
          label: _remainingSeconds > 0
              ? 'أعد الإرسال خلال ${_getFormattedTime()}'
              : 'لم تستقبل الرمز؟ أعد الإرسال',
          onPressed: (_remainingSeconds > 0 || _isLoading) ? () {} : _resendOTP,
          color: (_remainingSeconds > 0 || _isLoading)
              ? DesignTokens.neutralGray500
              : DesignTokens.primaryGold,
        ),
      ],
    );
  }

  /// منتقي الدولة
  Widget _buildCountrySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // زر اختيار الدولة
        GestureDetector(
          onTap: () {
            setState(() => _showCountryList = !_showCountryList);
            _countrySearchController.clear();
            _filteredCountries = CountriesDatabase.getAllCountries();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingLg,
              vertical: DesignTokens.spacingMd,
            ),
            decoration: BoxDecoration(
              color: DesignTokens.backgroundDarkMedium,
              borderRadius: BorderRadius.circular(DesignTokens.borderRadiusLg),
              border: Border.all(
                color: DesignTokens.primaryGold.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_selectedCountry != null)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BodyText(
                          _selectedCountry!.countryName,
                          fontWeight: DesignTokens.fontWeightSemiBold,
                          color: DesignTokens.neutralWhite,
                        ),
                        CaptionText(
                          _selectedCountry!.dialCode,
                          color: DesignTokens.neutralGray400,
                        ),
                      ],
                    ),
                  ),
                Icon(
                  _showCountryList ? Icons.expand_less : Icons.expand_more,
                  color: DesignTokens.primaryGold,
                ),
              ],
            ),
          ),
        ),

        // قائمة الدول
        if (_showCountryList)
          Container(
            margin: const EdgeInsets.only(top: DesignTokens.spacingSm),
            decoration: BoxDecoration(
              color: DesignTokens.backgroundDarkMedium,
              borderRadius: BorderRadius.circular(DesignTokens.borderRadiusLg),
              border: Border.all(
                color: DesignTokens.primaryGold.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // حقل البحث
                Padding(
                  padding: const EdgeInsets.all(DesignTokens.spacingSm),
                  child: RoyalTextField(
                    controller: _countrySearchController,
                    hintText: 'ابحث عن دولة...',
                    prefixIcon: Icons.search,
                    onChanged: _searchCountries,
                  ),
                ),
                // قائمة الدول المفلترة
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxHeight: 300,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _filteredCountries.length,
                    itemBuilder: (context, index) {
                      final country = _filteredCountries[index];
                      final isSelected =
                          country.countryCode == _selectedCountryCode;

                      return ListTile(
                        title: BodyText(
                          country.countryName,
                          color: isSelected
                              ? DesignTokens.primaryGold
                              : DesignTokens.neutralWhite,
                          fontWeight: isSelected
                              ? DesignTokens.fontWeightBold
                              : DesignTokens.fontWeightNormal,
                        ),
                        subtitle: CaptionText(
                          country.dialCode,
                          color: isSelected
                              ? DesignTokens.primaryGold.withValues(alpha: 0.7)
                              : DesignTokens.neutralGray500,
                          textAlign: TextAlign.right,
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check_circle,
                                color: DesignTokens.primaryGold,
                              )
                            : null,
                        onTap: () => _selectCountry(country),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// حقل إدخال رقم الهاتف
  Widget _buildPhoneNumberInput() {
    return Container(
      decoration: BoxDecoration(
        color: DesignTokens.backgroundDarkMedium,
        borderRadius: BorderRadius.circular(DesignTokens.borderRadiusLg),
        border: Border.all(
          color: _errorMessage != null
              ? DesignTokens.semanticError
              : DesignTokens.primaryGold.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: TextField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        enabled: !_isLoading,
        style: const TextStyle(
          color: DesignTokens.neutralWhite,
          fontSize: DesignTokens.fontSizeBase,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: 'أدخل رقم الهاتف',
          hintStyle: TextStyle(
            color: DesignTokens.neutralWhite.withValues(alpha: 0.2),
            fontSize: DesignTokens.fontSizeSm,
          ),
          prefixText: _selectedCountry?.dialCode != null
              ? '${_selectedCountry!.dialCode} '
              : null,
          prefixStyle: const TextStyle(
            color: DesignTokens.primaryGold,
            fontSize: DesignTokens.fontSizeBase,
            fontWeight: DesignTokens.fontWeightBold,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingLg,
            vertical: DesignTokens.spacingMd,
          ),
        ),
      ),
    );
  }
}
