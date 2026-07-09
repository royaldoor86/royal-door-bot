import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';
import '../../theme/reusable_widgets.dart';
import '../../services/rewards_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// لوحة تحكم إحصائيات عمولات السوق للإدارة
class AdminMarketplaceStatsPage extends StatefulWidget {
  const AdminMarketplaceStatsPage({super.key});

  @override
  State<AdminMarketplaceStatsPage> createState() =>
      _AdminMarketplaceStatsPageState();
}

class _AdminMarketplaceStatsPageState extends State<AdminMarketplaceStatsPage> {
  final RewardsService _rewardsService = RewardsService();
  final NumberFormat _numberFormat = NumberFormat.decimalPattern('ar');
  final DateFormat _dateFormat = DateFormat('yyyy/MM/dd HH:mm', 'ar');

  // الشهر المختار حالياً (الافتراضي هو الشهر الحالي)
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    // حساب نطاق البحث
    final DateTime startOfMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final DateTime endOfMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0, 23, 59, 59);

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: DesignTokens.backgroundDarkDeep,
        appBar: AppBar(
          title: const HeadingText('إحصائيات عمولات السوق'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: AppTheme.background(child: Container()),
        ),
        body: AppTheme.background(
          child: SafeArea(
            child: Column(
              children: [
                _buildMonthSelector(),
                Expanded(
                  child: StreamBuilder<List<Map<String, dynamic>>>(
                    stream:
                        _rewardsService.getMarketplaceCommissionsByDateRange(
                            startOfMonth, endOfMonth),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const RoyalLoadingIndicator(
                            message: 'جاري جلب البيانات...');
                      }

                      final logs = snapshot.data ?? [];

                      // حساب الإحصائيات التجميعية
                      double totalCommissions = 0;
                      double totalVolume = 0;
                      for (var log in logs) {
                        totalCommissions += (log['amount'] ?? 0).toDouble();
                        totalVolume +=
                            (log['metadata']?['originalPrice'] ?? 0)
                                .toDouble();
                      }

                      return ListView(
                        padding:
                            AppTheme.getPaddingForScreen(context),
                        children: [
                          _buildSummarySection(
                              totalCommissions, totalVolume, logs.length),
                          const SizedBox(height: DesignTokens.spacingXl),
                          const HeadingText('تفاصيل العمولات المحصلة',
                              fontSize: DesignTokens.fontSizeLg),
                          const SizedBox(height: DesignTokens.spacingMd),
                          if (logs.isEmpty)
                            const EmptyStateWidget(
                              icon: Icons.analytics_outlined,
                              title: 'لا توجد بيانات',
                              subtitle:
                                  'لم يتم تسجيل أي عمليات بيع في هذا الشهر.',
                            )
                          else
                            ...logs.map((log) => _buildLogCard(log)),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return GlassCard(
      margin: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingLg,
        vertical: DesignTokens.spacingSm,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingLg,
        vertical: DesignTokens.spacingSm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_right,
                color: DesignTokens.primaryGold),
            onPressed: () => setState(() {
              _selectedMonth =
                  DateTime(_selectedMonth.year, _selectedMonth.month - 1);
            }),
          ),
          Row(
            children: [
              const Icon(Icons.calendar_month,
                  size: DesignTokens.iconSizeSm, color: DesignTokens.primaryGold),
              const SizedBox(width: DesignTokens.spacingSm),
              HeadingText(
                DateFormat.yMMMM('ar').format(_selectedMonth),
                fontSize: DesignTokens.fontSizeBase,
              ),
            ],
          ),
          IconButton(
            icon:
                const Icon(Icons.chevron_left, color: DesignTokens.primaryGold),
            onPressed: () => setState(() {
              _selectedMonth =
                  DateTime(_selectedMonth.year, _selectedMonth.month + 1);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection(double commission, double volume, int count) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'إجمالي العمولات',
                _numberFormat.format(commission),
                Icons.account_balance_wallet,
                DesignTokens.primaryGold,
              ),
            ),
            const SizedBox(width: DesignTokens.spacingMd),
            Expanded(
              child: _buildStatCard(
                'حجم المبيعات',
                _numberFormat.format(volume),
                Icons.shopping_bag_outlined,
                DesignTokens.primaryEmerald,
              ),
            ),
          ],
        ),
        const SizedBox(height: DesignTokens.spacingMd),
        _buildStatCard(
          'إجمالي عدد الصفقات',
          count.toString(),
          Icons.handshake_outlined,
          DesignTokens.primarySapphire,
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(DesignTokens.spacingLg),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(DesignTokens.spacingSm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
            ),
            child: Icon(icon, color: color, size: DesignTokens.iconSizeMd),
          ),
          const SizedBox(width: DesignTokens.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CaptionText(label),
                HeadingText(value, fontSize: DesignTokens.fontSizeXl, color: color),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    final DateTime date =
        (log['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
    final double amount = (log['amount'] ?? 0).toDouble();
    final double original = (log['metadata']?['originalPrice'] ?? 0).toDouble();
    final String details = log['details'] ?? '';
    final String currency = log['currency'] == 'stars' ? 'نجمة' : 'جوهرة';

    return GlassCard(
      margin: const EdgeInsets.only(bottom: DesignTokens.spacingMd),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BodyText(details, fontSize: DesignTokens.fontSizeSm, fontWeight: DesignTokens.fontWeightBold),
              CaptionText(_dateFormat.format(date)),
            ],
          ),
          const RoyalDivider(thickness: 1, indent: 0, endIndent: 0),
          Row(
            children: [
              const RoyalCoinIcon(size: DesignTokens.iconSizeXs),
              const SizedBox(width: DesignTokens.spacingXs),
              CaptionText(
                  'قيمة الصفقة: ${_numberFormat.format(original)} $currency'),
              const Spacer(),
              HeadingText('+ ${_numberFormat.format(amount)}',
                  fontSize: DesignTokens.fontSizeBase, color: DesignTokens.primaryGold),
              const SizedBox(width: DesignTokens.spacingXs),
              CaptionText(currency),
            ],
          ),
        ],
      ),
    );
  }
}
