import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import '../../theme/design_tokens.dart';
import '../../theme/responsive_breakpoints.dart';
import '../../theme/reusable_widgets.dart';
import '../../theme/app_theme.dart';
import '../../services/rewards_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// صفحة سوق التداول للمكافآت الملكية
class RewardMarketplacePage extends StatefulWidget {
  const RewardMarketplacePage({super.key});

  @override
  State<RewardMarketplacePage> createState() => _RewardMarketplacePageState();
}

class _RewardMarketplacePageState extends State<RewardMarketplacePage> {
  final RewardsService _rewardsService = RewardsService();
  final NumberFormat _formatter = NumberFormat.decimalPattern('ar');

  bool _isShowingMyListings = false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: DesignTokens.backgroundDarkDeep,
        body: Stack(
          children: [
            // الخلفية المتدرجة الرسمية
            Container(
              decoration: BoxDecoration(
                gradient: AppTheme.createBackgroundGradient(
                    isRoyalMode: true),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: _buildMarketplaceContent(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: AppTheme.getPaddingForScreen(context),
      child: Column(
        children: [
          DisplayText(
              _isShowingMyListings ? 'عروضي النشطة' : 'سوق التبادل الملكي'),
          const SizedBox(height: DesignTokens.spacingSm),
          BodyText(
            _isShowingMyListings
                ? 'إدارة الباقات التي قمت بعرضها للبيع'
                : 'تداول باقاتك النشطة مع مستخدمين آخرين بكل أمان',
            color: DesignTokens.neutralWhite.withValues(alpha: 0.7),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DesignTokens.spacingLg),

          // مفتاح التبديل بين السوق وعروضي
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(DesignTokens.borderRadiusLg),
            ),
            child: Row(
              children: [
                Expanded(
                  child:
                      _buildTabButton('السوق العام', !_isShowingMyListings, () {
                    setState(() => _isShowingMyListings = false);
                  }),
                ),
                Expanded(
                  child: _buildTabButton('عروضي', _isShowingMyListings, () {
                    setState(() => _isShowingMyListings = true);
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: DesignTokens.durationFast,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? DesignTokens.primaryGold.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
          border: isSelected
              ? Border.all(color: DesignTokens.primaryGold.withOpacity(0.5))
              : null,
        ),
        child: Center(
          child: BodyText(
            label,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? DesignTokens.primaryGold : Colors.white60,
          ),
        ),
      ),
    );
  }

  Widget _buildMarketplaceContent() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _isShowingMyListings
          ? _rewardsService
              .getUserListings() // دالة لجلب عروض المستخدم الحالي فقط
          : _rewardsService.getActiveListings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const RoyalLoadingIndicator(message: 'جاري تحديث العروض...');
        }

        if (snapshot.hasError) {
          return EmptyStateWidget(
            icon: Icons.error_outline,
            title: 'حدث خطأ ما',
            subtitle: 'فشل تحميل العروض من السوق',
            actionButton: RoyalButton(
              label: 'إعادة المحاولة',
              onPressed: () => setState(() {}),
              width: 150,
            ),
          );
        }

        final listings = snapshot.data ?? [];

        if (listings.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.storefront_outlined,
            title: 'السوق فارغ حالياً',
            subtitle: 'لا توجد عروض تداول نشطة في الوقت الحالي.',
          );
        }

        return ResponsiveBuilder(
          phone: (context) => _buildGrid(listings, 1),
          tablet: (context) => _buildGrid(listings, 2),
          desktop: (context) => _buildGrid(listings, 4),
        );
      },
    );
  }

  Widget _buildGrid(List<Map<String, dynamic>> listings, int crossAxisCount) {
    return GridView.builder(
      padding: AppTheme.getPaddingForScreen(context),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: DesignTokens.spacingLg,
        crossAxisSpacing: DesignTokens.spacingLg,
        childAspectRatio: 0.8,
      ),
      itemCount: listings.length,
      itemBuilder: (context, index) {
        return _buildListingCard(listings[index]);
      },
    );
  }

  Widget _buildListingCard(Map<String, dynamic> listing) {
    final String id = listing['id'] ?? '';
    final String packageName = listing['packageName'] ?? 'باقة غير معروفة';
    final double price = (listing['askingPrice'] ?? 0).toDouble();
    final String currency = listing['currency'] ?? 'stars';
    final Map<String, dynamic> rewardData = listing['rewardData'] ?? {};

    // تفاصيل المكافأة داخل العرض
    final double daily = (rewardData['dailyReward'] ?? 0).toDouble();
    final double total = (rewardData['totalReward'] ?? 0).toDouble();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رأس البطاقة
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: DesignTokens.primaryGold.withValues(alpha: 0.2),
                  borderRadius:
                      BorderRadius.circular(DesignTokens.borderRadiusSm),
                ),
                child:
                    const CaptionText('عرض تداول', color: DesignTokens.primaryGold),
              ),
              const Icon(Icons.verified_user,
                  color: DesignTokens.primaryEmerald, size: 16),
            ],
          ),

          const SizedBox(height: DesignTokens.spacingMd),
          HeadingText(packageName, fontSize: 18),
          const SizedBox(height: DesignTokens.spacingSm),

          // السعر
          Row(
            children: [
              Text(
                _formatter.format(price),
                style: const TextStyle(
                  color: DesignTokens.primaryGold,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: DesignTokens.secondaryFont,
                ),
              ),
              const SizedBox(width: 4),
              CaptionText(currency == 'stars' ? 'نجمة' : 'جوهرة'),
            ],
          ),

          const Divider(color: Colors.white10, height: 20),

          // تفاصيل الربح
          _buildDetailRow(Icons.calendar_today, 'الربح اليومي:',
              '${_formatter.format(daily)} نجمة'),
          _buildDetailRow(Icons.account_balance_wallet, 'إجمالي الربح:',
              '${_formatter.format(total)} نجمة'),

          const Spacer(),

          // زر الإجراء: شراء أو إلغاء
          if (_isShowingMyListings)
            RoyalButton(
              label: 'إلغاء العرض',
              onPressed: () => _showConfirmCancelDialog(id, packageName),
              height: 42,
              gradient: [
                DesignTokens.semanticError,
                DesignTokens.semanticError.withOpacity(0.7),
              ],
            )
          else
            RoyalButton(
              label: 'شراء الآن',
              onPressed: () =>
                  _showConfirmPurchaseDialog(id, packageName, price, currency),
              height: 42,
              gradient: const [
                DesignTokens.primaryEmerald,
                DesignTokens.primaryEmeraldDark
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(dynamic icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          icon is IconData
              ? Icon(icon,
                  size: 14,
                  color: DesignTokens.neutralWhite.withValues(alpha: 0.5))
              : icon as Widget,
          const SizedBox(width: 8),
          CaptionText(label),
          const Spacer(),
          BodyText(value, fontSize: 13, fontWeight: FontWeight.bold),
        ],
      ),
    );
  }

  Future<void> _showConfirmCancelDialog(String id, String name) async {
    showDialog(
      context: context,
      builder: (context) => RoyalConfirmDialog(
        title: 'تأكيد إلغاء العرض',
        message: 'هل أنت متأكد من سحب "$name" من السوق؟',
        icon: Icons.warning_amber_rounded,
        iconColor: DesignTokens.semanticError,
        confirmLabel: 'تأكيد الإلغاء',
        onConfirm: () => _handleCancelListing(id, name),
      ),
    );
  }

  Future<void> _showConfirmPurchaseDialog(
      String id, String name, double price, String currency) async {
    // حساب العمولة بنسبة 2% كما هو مطبق في الخدمة
    final double commission = price * 0.02;
    final double totalAmount = price; // المشتري يدفع السعر المعلن، والعمولة تُخصم من البائع

    final String currencyText = currency == 'stars' ? 'نجمة' : 'جوهرة';
    final formattedPrice = _formatter.format(price);
    final formattedCommission = _formatter.format(commission);
    final formattedTotal = _formatter.format(totalAmount);

    // التحقق من الرصيد قبل عرض الحوار
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data();

      // تحديد حقل الرصيد بناءً على نوع العملة (Stars أو Gems/Coins)
      final String balanceField = currency == 'stars' ? 'stars' : 'coins';
      final double currentBalance = (userData?[balanceField] ?? 0).toDouble();

      // إذا كان الرصيد غير كافٍ، نعرض تنبيهاً ونخرج فوراً
      if (currentBalance < price) {
        if (mounted) {
          AppTheme.showErrorSnackbar(
            context,
            'رصيدك الحالي (${_formatter.format(currentBalance)}) غير كافٍ لشراء هذه الباقة.',
          );
        }
        return;
      }
    } catch (e) {
      if (mounted) {
        AppTheme.showErrorSnackbar(
            context, 'حدث خطأ أثناء التحقق من الرصيد: $e');
      }
      return;
    }

    showDialog(
      context: context,
      builder: (context) => RoyalConfirmDialog(
        title: 'تأكيد عملية الشراء',
        message: 'يرجى مراجعة تفاصيل الشراء للباقة الملكية:',
        icon: Icons.shopping_basket_outlined,
        iconColor: DesignTokens.primaryEmerald,
        confirmLabel: 'تأكيد وشراء',
        details: [
          _buildDetailRow(Icons.label_outline, 'اسم الباقة:', name),
          _buildDetailRow(const RoyalCoinIcon(size: 16), 'السعر:',
              '$formattedPrice $currencyText'),
          _buildDetailRow(Icons.account_balance_wallet_outlined, 'رسوم الخدمة (على البائع):',
              '$formattedCommission $currencyText'),
          const Divider(color: Colors.white10),
          _buildDetailRow(Icons.payments_outlined, 'الإجمالي المطلوب:',
              '$formattedTotal $currencyText'),
        ],
        onConfirm: () => _confirmPurchase(id, name, price),
      ),
    );
  }

  Future<void> _confirmPurchase(String id, String name, double price) async {
    try {
      // هنا يمكن إضافة حوار تأكيد قبل الشراء
      await _rewardsService.purchaseFromMarketplace(id);
      if (mounted) {
        AppTheme.showSuccessSnackbar(
            context, 'مبروك! تمت ملكية $name بنجاح.');
      }
    } catch (e) {
      if (mounted) {
        AppTheme.showErrorSnackbar(context, e.toString());
      }
    }
  }

  Future<void> _handleCancelListing(String id, String name) async {
    try {
      // استدعاء دالة الحذف من Firestore عبر الخدمة
      await _rewardsService.cancelListing(id);
      if (mounted) {
        AppTheme.showSuccessSnackbar(
            context, 'تم سحب عرض $name من السوق بنجاح.');
      }
    } catch (e) {
      if (mounted) {
        AppTheme.showErrorSnackbar(context, 'فشل إلغاء العرض: $e');
      }
    }
  }
}
