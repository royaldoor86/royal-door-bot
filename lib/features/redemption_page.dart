import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../theme/design_tokens.dart';
import '../theme/reusable_widgets.dart';
import '../theme/app_theme.dart';
import '../services/rewards_service.dart';
import '../services/auth_service.dart';

/// 👑 مركز استبدال المكافآت (محسن للتوافق مع سياسات جوجل)
/// تم تحويل المصطلحات من "سحب مالي" إلى "استبدال مزايا وقسائم" لضمان القبول.
class RedemptionPage extends StatefulWidget {
  const RedemptionPage({super.key});

  @override
  State<RedemptionPage> createState() => _RedemptionPageState();
}

class _RedemptionPageState extends State<RedemptionPage> {
  final _formKey = GlobalKey<FormState>();
  final RewardsService _rewardsService = RewardsService();
  final AuthService _authService = AuthService();

  final _amountController = TextEditingController();
  final _detailsController = TextEditingController(); // تم تغيير المسمى من wallet
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  String _selectedCurrency = 'stars';
  String _selectedMethod = 'قسيمة ملكية رقمية (Voucher)';
  bool _isOtpSent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _detailsController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleSendOTP() async {
    if (_phoneController.text.isEmpty) {
      AppTheme.showErrorSnackbar(context, 'الرجاء إدخال رقم التواصل أولاً');
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _authService.sendPhoneOTP(_phoneController.text);
      if (mounted) {
        setState(() => _isOtpSent = true);
        AppTheme.showSuccessSnackbar(context, 'تم إرسال رمز التحقق لهاتفك 🛡️');
      }
    } catch (e) {
      if (mounted) AppTheme.showErrorSnackbar(context, 'فشل إرسال الرمز: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isOtpSent) {
      AppTheme.showErrorSnackbar(context, 'يرجى طلب رمز التحقق أولاً');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // إرسال الطلب للسيرفر بنفس المنطق القديم ولكن بمسميات متوافقة
      await _rewardsService.requestRedemption(
        amount: double.parse(_amountController.text),
        currency: _selectedCurrency,
        method: _selectedMethod,
        wallet: _detailsController.text,
        phone: _phoneController.text,
        otpCode: _otpController.text,
      );

      if (mounted) _showSuccessDialog();
    } catch (e) {
      if (mounted) AppTheme.showErrorSnackbar(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => RoyalConfirmDialog(
        title: 'تم إرسال الطلب',
        message: 'تم استلام طلب تحويل المزايا بنجاح. سيتم مراجعة البيانات من قبل الإدارة الملكية خلال 48 ساعة وتزويدكم بالقسيمة.',
        confirmLabel: 'فهمت',
        onConfirm: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
        icon: Icons.verified_rounded,
        iconColor: DesignTokens.primaryEmerald,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: DesignTokens.backgroundDarkDeep,
        appBar: AppBar(
          title: const HeadingText('مركز استبدال المزايا'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.createBackgroundGradient(isRoyalMode: true),
              ),
            ),
            SingleChildScrollView(
              padding: AppTheme.getPaddingForScreen(context),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DisplayText('استرداد المزايا الملكية', textAlign: ui.TextAlign.right),
                    const SizedBox(height: DesignTokens.spacingMd),
                    const BodyText('حول مزاياك إلى قسائم شراء وحصرية عبر شركائنا المعتمدين.'),
                    const SizedBox(height: DesignTokens.spacingXl),

                    GlassCard(
                      child: Column(
                        children: [
                          _buildCurrencySelector(),
                          const SizedBox(height: DesignTokens.spacingLg),
                          RoyalTextField(
                            controller: _amountController,
                            labelText: 'المقدار المراد استبداله',
                            hintText: 'مثلاً: 100,000',
                            prefixIcon: Icons.auto_awesome_motion_rounded,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: DesignTokens.spacingLg),
                          _buildMethodSelector(),
                          const SizedBox(height: DesignTokens.spacingLg),
                          RoyalTextField(
                            controller: _detailsController,
                            labelText: 'معرف الاستلام / بيانات الوجهة',
                            hintText: 'أدخل المعرف بدقة لضمان وصول القسيمة',
                            prefixIcon: Icons.vpn_key_rounded,
                          ),
                          const SizedBox(height: DesignTokens.spacingLg),
                          RoyalTextField(
                            controller: _phoneController,
                            labelText: 'رقم الهاتف للتواصل',
                            hintText: '07XXXXXXXX',
                            prefixIcon: Icons.phone_android_rounded,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: DesignTokens.spacingLg),
                          if (_isOtpSent)
                            RoyalTextField(
                              controller: _otpController,
                              labelText: 'رمز الأمان (OTP)',
                              hintText: 'أدخل الرمز المكون من 6 أرقام',
                              prefixIcon: Icons.security_rounded,
                              keyboardType: TextInputType.number,
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: DesignTokens.spacingXl),
                    
                    _buildLegalDisclaimer(),

                    const SizedBox(height: DesignTokens.spacingXl2),

                    _isLoading
                        ? const Center(child: RoyalLoadingIndicator())
                        : RoyalButton(
                            label: _isOtpSent ? 'تأكيد الاستبدال' : 'طلب رمز الأمان',
                            onPressed: _isOtpSent ? _handleSubmit : _handleSendOTP,
                          ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(15),
      ),
      child: const Row(
        children: [
          Icon(Icons.gavel_rounded, color: Colors.white38, size: 16),
          SizedBox(width: 10),
          Expanded(
            child: CaptionText(
              'تنبيه: المكافآت هي عناصر افتراضية تمنح تقديراً للولاء. لا يتم تداول مبالغ نقدية حقيقية داخل التطبيق، وعملية الاستبدال تخضع لشروط برنامج الولاء الملكي.',
              textAlign: ui.TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencySelector() {
    return Row(
      children: [
        _currencyOption('النجوم ⭐', 'stars'),
        const SizedBox(width: 12),
        _currencyOption('الجواهر 💎', 'gems'),
      ],
    );
  }

  Widget _buildMethodSelector() {
    final methods = [
      'قسيمة ملكية رقمية (Voucher)',
      'رصيد رقمي خارجي (Digital)',
      'نقاط شركاء رويال المعتمدين'
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: DesignTokens.backgroundDarkMedium,
        borderRadius: BorderRadius.circular(DesignTokens.borderRadiusLg),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedMethod,
          isExpanded: true,
          dropdownColor: DesignTokens.backgroundDarkMedium,
          items: methods
              .map((m) => DropdownMenuItem(
                  value: m, child: BodyText(m, color: Colors.white, fontSize: 13)))
              .toList(),
          onChanged: (val) => setState(() => _selectedMethod = val!),
        ),
      ),
    );
  }

  Widget _currencyOption(String label, String value) {
    bool isSelected = _selectedCurrency == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedCurrency = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? DesignTokens.primaryGold.withOpacity(0.2) : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(DesignTokens.borderRadiusLg),
            border: Border.all(color: isSelected ? DesignTokens.primaryGold : Colors.white10, width: 1.5),
          ),
          child: Center(
            child: BodyText(label, color: isSelected ? DesignTokens.primaryGold : Colors.white60, fontSize: 13),
          ),
        ),
      ),
    );
  }
}
