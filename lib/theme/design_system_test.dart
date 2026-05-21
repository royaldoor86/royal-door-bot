/// اختبار نظام التصميم الموحد
/// Design System Test & Showcase
library design_system_test;

import 'package:flutter/material.dart';
import 'design_tokens.dart';
import 'responsive_breakpoints.dart';
import 'reusable_widgets.dart';
import 'app_theme.dart';

/// صفحة اختبار نظام التصميم
class DesignSystemTestPage extends StatefulWidget {
  const DesignSystemTestPage({super.key});

  @override
  State<DesignSystemTestPage> createState() => _DesignSystemTestPageState();
}

class _DesignSystemTestPageState extends State<DesignSystemTestPage> {
  bool _isDarkMode = true;
  bool _isRoyalMode = false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: DesignTokens.backgroundDarkDeep,
        appBar: AppBar(
          title: const HeadingText('اختبار نظام التصميم'),
          backgroundColor: DesignTokens.backgroundDarkMedium,
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.createBackgroundGradient(
              isRoyalMode: _isRoyalMode,
            ),
          ),
          child: SingleChildScrollView(
            padding: AppTheme.getPaddingForScreen(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildModeSelector(),
                const SizedBox(height: DesignTokens.spacingXl3),
                _buildColorsSection(context),
                const SizedBox(height: DesignTokens.spacingXl3),
                _buildTypographySection(context),
                const SizedBox(height: DesignTokens.spacingXl3),
                _buildComponentsSection(context),
                const SizedBox(height: DesignTokens.spacingXl3),
                _buildSpacingSection(context),
                const SizedBox(height: DesignTokens.spacingXl3),
                _buildResponsiveSection(context),
                const SizedBox(height: DesignTokens.spacingXl3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HeadingText('وضع العرض'),
          const SizedBox(height: DesignTokens.spacingLg),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'الوضع الداكن',
                  onPressed: () => setState(() => _isDarkMode = true),
                  color: _isDarkMode
                      ? DesignTokens.primaryGold
                      : DesignTokens.neutralGray400,
                ),
              ),
              const SizedBox(width: DesignTokens.spacingLg),
              Expanded(
                child: SecondaryButton(
                  label: 'الوضع الفاتح',
                  onPressed: () => setState(() => _isDarkMode = false),
                  color: !_isDarkMode
                      ? DesignTokens.primaryGold
                      : DesignTokens.neutralGray400,
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingLg),
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'عادي',
                  onPressed: () => setState(() => _isRoyalMode = false),
                  color: !_isRoyalMode
                      ? DesignTokens.primaryGold
                      : DesignTokens.neutralGray400,
                ),
              ),
              const SizedBox(width: DesignTokens.spacingLg),
              Expanded(
                child: SecondaryButton(
                  label: 'ملكي',
                  onPressed: () => setState(() => _isRoyalMode = true),
                  color: _isRoyalMode
                      ? DesignTokens.primaryGold
                      : DesignTokens.neutralGray400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColorsSection(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HeadingText('الألوان'),
          const SizedBox(height: DesignTokens.spacingLg),
          _buildColorGrid(const [
            ('ذهب', DesignTokens.primaryGold),
            ('زمردي', DesignTokens.primaryEmerald),
            ('ياقوت أزرق', DesignTokens.primarySapphire),
            ('روبي', DesignTokens.primaryRuby),
            ('نجاح', DesignTokens.semanticSuccess),
            ('خطأ', DesignTokens.semanticError),
            ('تحذير', DesignTokens.semanticWarning),
            ('معلومة', DesignTokens.semanticInfo),
          ]),
        ],
      ),
    );
  }

  Widget _buildColorGrid(List<(String, Color)> colors) {
    return ResponsiveBuilder(
      phone: (context) => GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: DesignTokens.spacingMd,
        crossAxisSpacing: DesignTokens.spacingMd,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: colors.map((item) => _buildColorBox(item)).toList(),
      ),
      tablet: (context) => GridView.count(
        crossAxisCount: 4,
        mainAxisSpacing: DesignTokens.spacingMd,
        crossAxisSpacing: DesignTokens.spacingMd,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: colors.map((item) => _buildColorBox(item)).toList(),
      ),
      desktop: (context) => GridView.count(
        crossAxisCount: 8,
        mainAxisSpacing: DesignTokens.spacingMd,
        crossAxisSpacing: DesignTokens.spacingMd,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: colors.map((item) => _buildColorBox(item)).toList(),
      ),
    );
  }

  Widget _buildColorBox((String, Color) item) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            color: item.$2,
            borderRadius: BorderRadius.circular(DesignTokens.borderRadiusLg),
          ),
        ),
        const SizedBox(height: DesignTokens.spacingSm),
        CaptionText(item.$1),
      ],
    );
  }

  Widget _buildTypographySection(BuildContext context) {
    return const GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeadingText('أنماط النصوص'),
          SizedBox(height: DesignTokens.spacingLg),
          DisplayText('عنوان كبير جداً (Display)'),
          SizedBox(height: DesignTokens.spacingLg),
          HeadingText('عنوان متوسط (Heading)'),
          SizedBox(height: DesignTokens.spacingLg),
          BodyText('نص عادي (Body) - يستخدم في الفقرات والمحتوى الرئيسي'),
          SizedBox(height: DesignTokens.spacingLg),
          CaptionText('نص صغير جداً (Caption) - للملاحظات والتفاصيل'),
        ],
      ),
    );
  }

  Widget _buildComponentsSection(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HeadingText('المكونات'),
          const SizedBox(height: DesignTokens.spacingLg),
          RoyalButton(
            label: 'زر أساسي',
            onPressed: () {
              AppTheme.showSuccessSnackbar(
                context,
                'تم الضغط على الزر بنجاح!',
              );
            },
          ),
          const SizedBox(height: DesignTokens.spacingLg),
          SecondaryButton(
            label: 'زر ثانوي',
            onPressed: () {
              AppTheme.showInfoSnackbar(
                context,
                'هذا زر ثانوي',
              );
            },
          ),
          const SizedBox(height: DesignTokens.spacingLg),
          const RoyalTextField(
            hintText: 'اكتب شيئاً هنا',
            labelText: 'حقل إدخال',
            prefixIcon: Icons.text_fields,
          ),
          const SizedBox(height: DesignTokens.spacingLg),
          const RoyalDivider(),
          const SizedBox(height: DesignTokens.spacingLg),
          const RoyalProgressBar(
            value: 0.65,
            label: 'التقدم: 65%',
          ),
          const SizedBox(height: DesignTokens.spacingLg),
          const RoyalLoadingIndicator(
            message: 'جاري التحميل...',
            size: 40,
          ),
        ],
      ),
    );
  }

  Widget _buildSpacingSection(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HeadingText('نظام المسافات'),
          const SizedBox(height: DesignTokens.spacingLg),
          Wrap(
            spacing: DesignTokens.spacingLg,
            runSpacing: DesignTokens.spacingLg,
            children: [
              _buildSpacingBox('xs (4)', DesignTokens.spacingXs),
              _buildSpacingBox('sm (8)', DesignTokens.spacingSm),
              _buildSpacingBox('md (12)', DesignTokens.spacingMd),
              _buildSpacingBox('lg (16)', DesignTokens.spacingLg),
              _buildSpacingBox('xl (20)', DesignTokens.spacingXl),
              _buildSpacingBox('xl2 (24)', DesignTokens.spacingXl2),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpacingBox(String label, double size) {
    return Column(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: DesignTokens.primaryGold.withValues(alpha: 0.5),
            border: Border.all(
              color: DesignTokens.primaryGold,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(DesignTokens.borderRadiusSm),
          ),
        ),
        const SizedBox(height: DesignTokens.spacingSm),
        CaptionText(label),
      ],
    );
  }

  Widget _buildResponsiveSection(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HeadingText('معلومات الشاشة'),
          const SizedBox(height: DesignTokens.spacingLg),
          BodyText(
            'حجم الشاشة: ${ResponsiveBreakpoints.getScreenWidth(context).toStringAsFixed(0)}x${ResponsiveBreakpoints.getScreenHeight(context).toStringAsFixed(0)}',
          ),
          const SizedBox(height: DesignTokens.spacingMd),
          BodyText(
            'نوع الجهاز: ${ResponsiveBreakpoints.isPhone(context) ? 'هاتف' : ResponsiveBreakpoints.isTablet(context) ? 'جهاز لوحي' : 'سطح مكتب'}',
          ),
          const SizedBox(height: DesignTokens.spacingMd),
          BodyText(
            'عدد الأعمدة في الشبكة: ${ResponsiveBreakpoints.getGridColumns(context)}',
          ),
          const SizedBox(height: DesignTokens.spacingMd),
          BodyText(
            'الاتجاه: ${ResponsiveBreakpoints.isPortrait(context) ? 'عمودي' : 'أفقي'}',
          ),
        ],
      ),
    );
  }
}
