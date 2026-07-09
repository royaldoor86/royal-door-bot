import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';
import '../../theme/reusable_widgets.dart';
import '../../services/rewards_service.dart';
import '../../models/rewards_models.dart';

/// صفحة سجل السحوبات لعرض حالة طلبات تحويل النجوم/الجواهر
class WithdrawalHistoryPage extends StatefulWidget {
  const WithdrawalHistoryPage({super.key});

  @override
  State<WithdrawalHistoryPage> createState() => _WithdrawalHistoryPageState();
}

class _WithdrawalHistoryPageState extends State<WithdrawalHistoryPage> {
  final RewardsService _rewardsService = RewardsService();
  final DateFormat _dateFormat = DateFormat('yyyy/MM/dd HH:mm', 'ar');
  final NumberFormat _numberFormat = NumberFormat.decimalPattern('ar');

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: DesignTokens.backgroundDarkDeep,
        appBar: AppBar(
          title: const HeadingText('سجل المكافآت الملكية'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: AppTheme.background(
              child: Container()), // Root wrapper theme consistency
        ),
        body: AppTheme.background(
          child: SafeArea(
            child: StreamBuilder<List<RedemptionRequest>>(
              stream: _rewardsService.getRedemptionRequests(
                  _rewardsService.currentUserUid ??
                      ''), // جلب طلبات المستخدم الحالي
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const RoyalLoadingIndicator(
                      message: 'جاري تحميل السجل...');
                }

                if (snapshot.hasError) {
                  return EmptyStateWidget(
                    icon: Icons.error_outline,
                    title: 'حدث خطأ',
                    subtitle: 'فشل تحميل سجل السحوبات',
                    actionButton: RoyalButton(
                      label: 'إعادة المحاولة',
                      onPressed: () => setState(() {}),
                      width: 150,
                    ),
                  );
                }

                final logs = snapshot.data ?? [];

                if (logs.isEmpty) {
                  return const EmptyStateWidget(
                    icon: Icons.history_toggle_off,
                    title: 'لا يوجد سجل',
                    subtitle: 'لم تقم بإجراء أي عمليات تحويل حتى الآن.',
                  );
                }

                return ListView.builder(
                  padding: AppTheme.getPaddingForScreen(context),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    return _buildHistoryItem(logs[index]);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryItem(RedemptionRequest request) {
    final double amount = request.amount;
    final String method = request.methodText;
    final String currency = request.currency;
    final DateTime date = request.requestDate;
    final String? note = request.adminNote; // ملاحظة الإدارة في حال الرفض

    return GlassCard(
      margin: const EdgeInsets.only(bottom: DesignTokens.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      HeadingText(
                        _numberFormat.format(amount),
                        fontSize: DesignTokens.fontSizeXl,
                        color: DesignTokens.primaryGold,
                      ),
                      const SizedBox(width: DesignTokens.spacingXs),
                      CaptionText(currency == 'stars' ? 'نجمة' : 'جوهرة'),
                    ],
                  ),
                  CaptionText(_dateFormat.format(date)),
                ],
              ),
              _buildStatusBadge(request),
            ],
          ),
          const RoyalDivider(thickness: 1, indent: 0, endIndent: 0),
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_outlined,
                  size: DesignTokens.iconSizeXs, color: Colors.white54),
              const SizedBox(width: DesignTokens.spacingSm),
              BodyText('وسيلة السحب: $method',
                  fontSize: DesignTokens.fontSizeSm),
            ],
          ),
          if (request.isRejected && note != null) ...[
            const SizedBox(height: DesignTokens.spacingSm),
            Container(
              padding: const EdgeInsets.all(DesignTokens.spacingSm),
              decoration: BoxDecoration(
                color: DesignTokens.semanticError.withValues(alpha: 0.1),
                borderRadius:
                    BorderRadius.circular(DesignTokens.borderRadiusSm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: DesignTokens.iconSizeXs,
                      color: DesignTokens.semanticError),
                  const SizedBox(width: DesignTokens.spacingSm),
                  Expanded(
                    child: BodyText(
                      'سبب الرفض: $note',
                      fontSize: DesignTokens.fontSizeXs,
                      color: DesignTokens.semanticError.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(RedemptionRequest request) {
    Color color;
    String text = request.statusText;

    if (request.isApproved) {
      color = DesignTokens.primaryEmerald;
    } else if (request.isRejected) {
      color = DesignTokens.semanticError;
    } else if (request.isCompleted) {
      color = DesignTokens.primarySapphire;
    } else {
      color = DesignTokens.semanticWarning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(DesignTokens.borderRadiusFull),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: BodyText(text,
          color: color, fontSize: 12, fontWeight: FontWeight.bold),
    );
  }
}
