import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../theme/design_tokens.dart';
import '../theme/reusable_widgets.dart';
import '../theme/app_theme.dart';

/// صفحة الشروط والأحكام - تم تحديثها لتتوافق مع نظام التصميم الملكي
class TermsAndConditionsPage extends StatefulWidget {
  const TermsAndConditionsPage({super.key});

  @override
  State<TermsAndConditionsPage> createState() => _TermsAndConditionsPageState();
}

class _TermsAndConditionsPageState extends State<TermsAndConditionsPage> {
  final bool _isLoading = false;
  bool _agreedToTerms = false;
  bool _agreedToPrivacy = false;

  final String _termsContent = '''
1. شروط الاستخدام العامة
يلتزم المستخدم باستخدام التطبيق وفقاً للقوانين والأنظمة المعمول بها.

2. سياسة المحتوى
يُحظر نشر أي محتوى ينتهك حقوق الملكية الفكرية أو يحتوي على إساءة.

3. المسؤولية
التطبيق غير مسؤول عن أي خسائر ناتجة عن سوء استخدام الحساب.
''';

  final String _privacyPolicy = '''
نحن نحترم خصوصيتك ونلتزم بحماية بياناتك الشخصية. يتم جمع البيانات فقط لتحسين تجربة المستخدم.
''';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: DesignTokens.backgroundDarkDeep,
        appBar: AppBar(
          title: const HeadingText('شروط وأحكام الاستخدام'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: Stack(
          children: [
            // الخلفية الملكية المتدرجة
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.createBackgroundGradient(isRoyalMode: true),
              ),
            ),
            
            _isLoading
                ? const Center(
                    child: RoyalLoadingIndicator(message: 'جاري التحميل...'),
                  )
                : SafeArea(
                    child: Column(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            padding: AppTheme.getPaddingForScreen(context),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSection('الشروط والأحكام', _termsContent),
                                const SizedBox(height: DesignTokens.spacingLg),
                                _buildSection('سياسة الخصوصية', _privacyPolicy),
                                const SizedBox(height: DesignTokens.spacingLg),
                                _buildAgreementCheckboxes(),
                              ],
                            ),
                          ),
                        ),
                        
                        // زر القبول والتابعة
                        Padding(
                          padding: AppTheme.getPaddingForScreen(context),
                          child: AppTheme.gradientButton(
                            text: 'أقبل الشروط والأحكام',
                            onPressed: (_agreedToTerms && _agreedToPrivacy)
                                ? () => _acceptTerms()
                                : null,
                          ),
                        ),
                        const SizedBox(height: DesignTokens.spacingMd),
                      ],
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HeadingText(
          title,
          fontSize: 18,
          color: DesignTokens.primaryGold,
        ),
        const SizedBox(height: DesignTokens.spacingMd),
        GlassCard(
          padding: const EdgeInsets.all(DesignTokens.spacingMd),
          child: SizedBox(
            width: double.infinity,
            child: BodyText(
              content,
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAgreementCheckboxes() {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Theme(
            data: ThemeData(unselectedWidgetColor: Colors.white54),
            child: CheckboxListTile(
              title: const BodyText('أوافق على الشروط والأحكام', fontSize: 14),
              value: _agreedToTerms,
              activeColor: DesignTokens.primaryGold,
              checkColor: DesignTokens.neutralBlack,
              contentPadding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingMd),
              onChanged: (value) {
                setState(() => _agreedToTerms = value ?? false);
              },
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          Theme(
            data: ThemeData(unselectedWidgetColor: Colors.white54),
            child: CheckboxListTile(
              title: const BodyText('أوافق على سياسة الخصوصية', fontSize: 14),
              value: _agreedToPrivacy,
              activeColor: DesignTokens.primaryGold,
              checkColor: DesignTokens.neutralBlack,
              contentPadding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingMd),
              onChanged: (value) {
                setState(() => _agreedToPrivacy = value ?? false);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _acceptTerms() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const BodyText('تم قبول الشروط والأحكام بنجاح', color: Colors.white),
        backgroundColor: DesignTokens.primaryEmerald.withValues(alpha: 0.8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd)),
      ),
    );
    Navigator.pop(context, true);
  }
}
