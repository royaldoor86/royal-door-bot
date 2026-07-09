/// مثال عملي: تحديث صفحة المكافآت لاستخدام نظام التصميم الموحد
/// Example: Updating Rewards Page to use the new Design System
library rewards_page_example;

import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'design_tokens.dart';
import 'responsive_breakpoints.dart';
import 'reusable_widgets.dart';
import 'app_theme.dart';

/// مثال محسّن من صفحة المكافآت
class RewardsPageExample extends StatefulWidget {
  const RewardsPageExample({super.key});

  @override
  State<RewardsPageExample> createState() => _RewardsPageExampleState();
}

class _RewardsPageExampleState extends State<RewardsPageExample>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _rotationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 15))
          ..repeat();
    _pulseController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatNumber(num number) {
    return NumberFormat.decimalPattern('ar').format(number);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: DesignTokens.backgroundDarkDeep,
        body: Stack(
          children: [
            // خلفية بتدرج لوني
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.createBackgroundGradient(),
              ),
            ),

            // النجوم المتحركة (خلفية)
            _buildStarField(),

            // المحتوى الرئيسي
            SafeArea(
              child: SingleChildScrollView(
                padding: AppTheme.getPaddingForScreen(context),
                child: Column(
                  children: [
                    // الرأس
                    _buildHeader(context),
                    const SizedBox(height: DesignTokens.spacingXl3),

                    // البطاقات الرئيسية
                    ResponsiveBuilder(
                      phone: (context) => _buildPhoneLayout(context),
                      tablet: (context) => _buildTabletLayout(context),
                      desktop: (context) => _buildDesktopLayout(context),
                    ),

                    const SizedBox(height: DesignTokens.spacingXl3),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        const DisplayText('سوق المكافآت الملكي'),
        const SizedBox(height: DesignTokens.spacingLg),
        BodyText(
          'احصل على نجوم يومية من خلال الاشتراك في الباقات الملكية',
          color: DesignTokens.neutralWhite.withValues(alpha: 0.7),
        ),
      ],
    );
  }

  Widget _buildPhoneLayout(BuildContext context) {
    return Column(
      children: [
        _buildStatsCard(context),
        const SizedBox(height: DesignTokens.spacingXl),
        _buildActiveRewardsCard(context),
        const SizedBox(height: DesignTokens.spacingXl),
        _buildPackagesGrid(context, columns: 1),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatsCard(context)),
            const SizedBox(width: DesignTokens.spacingLg),
            Expanded(child: _buildActiveRewardsCard(context)),
          ],
        ),
        const SizedBox(height: DesignTokens.spacingXl),
        _buildPackagesGrid(context, columns: 2),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatsCard(context)),
            const SizedBox(width: DesignTokens.spacingLg),
            Expanded(child: _buildActiveRewardsCard(context)),
            const SizedBox(width: DesignTokens.spacingLg),
            Expanded(child: _buildCompletedRewardsCard(context)),
          ],
        ),
        const SizedBox(height: DesignTokens.spacingXl),
        _buildPackagesGrid(context, columns: 4),
      ],
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          HeadingText(
            'إجمالي النجوم',
            fontSize: ResponsiveBreakpoints.responsiveFontSize(context, 20),
          ),
          const SizedBox(height: DesignTokens.spacingLg),
          Text(
            _formatNumber(15750),
            style: TextStyle(
              fontSize: ResponsiveBreakpoints.responsiveFontSize(context, 36),
              fontWeight: DesignTokens.fontWeightBold,
              color: DesignTokens.primaryGold,
              fontFamily: DesignTokens.secondaryFont,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingMd),
          BodyText(
            'من 5 باقات نشطة',
            fontSize: DesignTokens.fontSizeSm,
            color: DesignTokens.neutralWhite.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRewardsCard(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          HeadingText(
            'باقات نشطة',
            fontSize: ResponsiveBreakpoints.responsiveFontSize(context, 20),
          ),
          const SizedBox(height: DesignTokens.spacingLg),
          Text(
            '5',
            style: TextStyle(
              fontSize: ResponsiveBreakpoints.responsiveFontSize(context, 36),
              fontWeight: DesignTokens.fontWeightBold,
              color: DesignTokens.primaryEmerald,
              fontFamily: DesignTokens.secondaryFont,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingMd),
          BodyText(
            'تحقق منها الآن',
            fontSize: DesignTokens.fontSizeSm,
            color: DesignTokens.neutralWhite.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedRewardsCard(BuildContext context) {
    return GlassCard(
      child: Column(
        children: [
          HeadingText(
            'مكتملة',
            fontSize: ResponsiveBreakpoints.responsiveFontSize(context, 20),
          ),
          const SizedBox(height: DesignTokens.spacingLg),
          Text(
            '12',
            style: TextStyle(
              fontSize: ResponsiveBreakpoints.responsiveFontSize(context, 36),
              fontWeight: DesignTokens.fontWeightBold,
              color: DesignTokens.semanticSuccess,
              fontFamily: DesignTokens.secondaryFont,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingMd),
          BodyText(
            'باقات مكتملة',
            fontSize: DesignTokens.fontSizeSm,
            color: DesignTokens.neutralWhite.withValues(alpha: 0.6),
          ),
        ],
      ),
    );
  }

  Widget _buildPackagesGrid(BuildContext context, {required int columns}) {
    final packages = [
      {
        'name': 'الباقة الذهبية',
        'price': '5000',
        'daily': '100',
        'total': '3000',
        'color': DesignTokens.primaryGold,
      },
      {
        'name': 'الباقة الزمردية',
        'price': '7500',
        'daily': '150',
        'total': '4500',
        'color': DesignTokens.primaryEmerald,
      },
      {
        'name': 'الباقة الزرقاء',
        'price': '10000',
        'daily': '200',
        'total': '6000',
        'color': DesignTokens.primarySapphire,
      },
      {
        'name': 'الباقة الملكية',
        'price': '15000',
        'daily': '300',
        'total': '9000',
        'color': DesignTokens.primaryRuby,
      },
    ];

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: DesignTokens.spacingLg,
        crossAxisSpacing: DesignTokens.spacingLg,
        childAspectRatio: 0.85,
      ),
      itemCount: packages.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final package = packages[index];
        return GlassCard(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // الرأس
              HeadingText(
                package['name'] as String,
                fontSize: ResponsiveBreakpoints.responsiveFontSize(context, 16),
              ),

              // الإحصائيات
              Column(
                children: [
                  BodyText(
                    'السعر: ${package['price']} جواهر',
                    fontSize: DesignTokens.fontSizeSm,
                    color: DesignTokens.neutralWhite.withValues(
                      alpha: 0.7,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacingMd),
                  BodyText(
                    'يومياً: ${package['daily']} نجمة',
                    fontSize: DesignTokens.fontSizeSm,
                    color: package['color'] as Color,
                  ),
                  const SizedBox(height: DesignTokens.spacingSm),
                  BodyText(
                    'الإجمالي: ${package['total']} نجمة',
                    fontSize: DesignTokens.fontSizeSm,
                    color: (package['color'] as Color).withValues(alpha: 0.8),
                  ),
                ],
              ),

              // الزر
              RoyalButton(
                label: 'شراء الآن',
                onPressed: () {
                  AppTheme.showSuccessSnackbar(
                    context,
                    'تم الشراء بنجاح!',
                  );
                },
                height: 40,
                gradient: [
                  package['color'] as Color,
                  (package['color'] as Color).withValues(alpha: 0.7),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStarField() {
    return CustomPaint(
      painter: StarFieldPainter(
        animation: _rotationController,
      ),
      size: Size.infinite,
    );
  }
}

/// رسام حقل النجوم
class StarFieldPainter extends CustomPainter {
  final Animation<double> animation;

  StarFieldPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.1);

    for (int i = 0; i < 50; i++) {
      final x = (i * 17.3) % size.width;
      final y = (i * 23.7) % size.height;
      final radius = 1.0 + (i % 3);

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
