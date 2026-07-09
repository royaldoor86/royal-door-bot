import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../theme/design_tokens.dart';
import '../theme/reusable_widgets.dart';
import '../theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RefundManagementPage extends StatefulWidget {
  const RefundManagementPage({super.key});

  @override
  State<RefundManagementPage> createState() => _RefundManagementPageState();
}

class _RefundManagementPageState extends State<RefundManagementPage> {
  final TextEditingController _transactionIdController =
      TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  String? _selectedReason;
  bool _hasSystemError = false;
  String? _systemErrorDescription;
  bool _isSubmitting = false;

  final List<String> _refundReasons = [
    'خلل تقني في النظام',
    'تحويل خاطئ للمبلغ',
    'عدم استلام الخدمة',
    'خدمة معيبة',
    'أخرى',
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: DesignTokens.backgroundDarkDeep,
        appBar: AppBar(
          title: const HeadingText('طلب دعم الباقة'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: Stack(
          children: [
            // الخلفية الملكية
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.createBackgroundGradient(isRoyalMode: true),
              ),
            ),
            SingleChildScrollView(
              padding: AppTheme.getPaddingForScreen(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoCard(),
                  const SizedBox(height: DesignTokens.spacingLg),
                  _buildRefundForm(),
                  const SizedBox(height: DesignTokens.spacingXl),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: DesignTokens.primaryGold),
              SizedBox(width: 8),
              HeadingText(
                'سياسة دعم وتصحيح طلب الباقة',
                fontSize: 16,
                color: DesignTokens.primaryGold,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            'يتم قبول طلبات الدعم فقط في حالة:',
            [
              'وجود خلل تقني في نظام الباقات',
              'خطأ في تسجيل المعاملة من النظام',
              'عدم تفعيل الميزة المشتراة بشكل صحيح',
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            'لا يتم قبول طلبات الدعم في حالة:',
            [
              'تغيير رأي المستخدم بعد الشراء بدون خلل تقني',
              'عدم فهم آلية الاحتساب أو المكافآت الافتراضية',
              'اختيار خاطئ من المستخدم بدون خلل فني',
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DesignTokens.primaryGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
              border: Border.all(color: DesignTokens.primaryGold.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.timer_outlined, size: 16, color: DesignTokens.primaryGold),
                SizedBox(width: 8),
                BodyText(
                  'وقت معالجة الطلب المتوقع: 5 أيام عمل',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BodyText(
          title,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: Colors.white70,
        ),
        const SizedBox(height: 8),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 12, color: DesignTokens.primaryEmerald),
                const SizedBox(width: 8),
                Expanded(child: CaptionText(item, fontSize: 13)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRefundForm() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HeadingText('تفاصيل الطلب', fontSize: 16),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _transactionIdController,
            label: 'رقم المعاملة أو الطلب',
            hint: 'أدخل رقم المعاملة الخاص بك',
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _amountController,
            label: 'قيمة الباقة',
            hint: 'أدخل قيمة الباقة (نجوم/جواهر)',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          _buildDropdown(),
          if (_selectedReason == 'أخرى') ...[
            const SizedBox(height: 16),
            _buildTextField(
              controller: _reasonController,
              label: 'السبب الآخر',
              hint: 'اشرح السبب بالتفصيل',
              maxLines: 3,
            ),
          ],
          const SizedBox(height: 20),
          _buildSystemErrorToggle(),
          if (_hasSystemError) ...[
            const SizedBox(height: 16),
            _buildTextField(
              controller: TextEditingController(text: _systemErrorDescription),
              label: 'وصف الخلل التقني',
              hint: 'صف الخلل الذي حدث بوضوح',
              onChanged: (value) {
                _systemErrorDescription = value;
              },
              maxLines: 3,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BodyText(label, fontWeight: FontWeight.bold, fontSize: 13),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
              borderSide: const BorderSide(color: DesignTokens.primaryGold),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BodyText('سبب الاسترجاع', fontWeight: FontWeight.bold, fontSize: 13),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedReason,
          dropdownColor: DesignTokens.backgroundDarkDeep,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          items: _refundReasons
              .map((reason) => DropdownMenuItem(
                    value: reason,
                    child: Text(reason),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() => _selectedReason = value);
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          isExpanded: true,
        ),
      ],
    );
  }

  Widget _buildSystemErrorToggle() {
    return Container(
      decoration: BoxDecoration(
        color: _hasSystemError 
            ? DesignTokens.semanticError.withValues(alpha: 0.1)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
        border: Border.all(
          color: _hasSystemError 
              ? DesignTokens.semanticError.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: CheckboxListTile(
        value: _hasSystemError,
        onChanged: (value) {
          setState(() => _hasSystemError = value ?? false);
        },
        activeColor: DesignTokens.semanticError,
        title: const BodyText(
          'يوجد خلل تقني من النظام',
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }

  Widget _buildSubmitButton() {
    return AppTheme.gradientButton(
      text: 'إرسال طلب الدعم',
      onPressed: _isFormValid() && !_isSubmitting ? _submitRefundRequest : null,
    );
  }

  bool _isFormValid() {
    return _transactionIdController.text.isNotEmpty &&
        _amountController.text.isNotEmpty &&
        _selectedReason != null;
  }

  Future<void> _submitRefundRequest() async {
    setState(() => _isSubmitting = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('يجب تسجيل الدخول أولاً');

      final amount = double.tryParse(_amountController.text) ?? 0.0;

      await FirebaseFirestore.instance.collection('refund_requests').add({
        'userId': user.uid,
        'transactionId': _transactionIdController.text,
        'amount': amount,
        'reason': _selectedReason ?? '',
        'systemError': _hasSystemError,
        'systemErrorDescription': _systemErrorDescription,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        AppTheme.showSuccessSnackbar(context, 'تم إرسال طلب الدعم بنجاح');
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    } catch (e) {
      if (mounted) {
        AppTheme.showErrorSnackbar(context, 'خطأ: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
