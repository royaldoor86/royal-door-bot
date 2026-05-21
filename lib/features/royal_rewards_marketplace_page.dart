import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_manager.dart';
import 'dart:math' as math;
import '../models/rewards_models.dart';
import '../services/rewards_service.dart';
import '../app_theme.dart';
import 'dart:ui' as ui;

class RoyalRewardsMarketplacePage extends StatefulWidget {
  const RoyalRewardsMarketplacePage({super.key});

  @override
  State<RoyalRewardsMarketplacePage> createState() =>
      _RoyalRewardsMarketplacePageState();
}

class _RoyalRewardsMarketplacePageState
    extends State<RoyalRewardsMarketplacePage>
    with SingleTickerProviderStateMixin {
  final RewardsService _rewardsService = RewardsService();
  final NumberFormat _formatter = NumberFormat.decimalPattern('ar');
  late TabController _tabController;
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBannerAd();

    // إظهار إعلان دخول احترافي للسوق الملكي
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdManager().showInterstitialAd();
    });
  }

  void _loadBannerAd() {
    _bannerAd = AdManager().getBannerAd(
      size: AdSize.banner,
      onAdLoaded: () => setState(() => _isBannerLoaded = true),
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _tabController.dispose();
    super.dispose();
  }

  String _formatNumber(num number) {
    return _formatter.format(number);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) {
            // إظهار إعلان خروج باحتمالية 50% لضمان تجربة مستخدم جيدة (Compliance)
            if (math.Random().nextBool()) {
              AdManager().showInterstitialAd();
            }
          }
        },
        child: AppTheme.background(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text('سوق المكافآت الملكي',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              bottom: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'السوق العام'),
                  Tab(text: 'باقاتي الجارية'),
                ],
                labelColor: Colors.tealAccent,
                unselectedLabelColor: Colors.white54,
                indicatorColor: Colors.tealAccent,
              ),
            ),
            bottomNavigationBar: _isBannerLoaded && _bannerAd != null
                ? Container(
                    height: _bannerAd!.size.height.toDouble(),
                    width: double.infinity,
                    color: Colors.black.withOpacity(0.5),
                    child: AdWidget(ad: _bannerAd!),
                  )
                : null,
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildMarketplaceTab(),
                _buildMyRewardsTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMarketplaceTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _rewardsService.getActiveListings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.storefront,
                    size: 80, color: Colors.white.withValues(alpha: 0.2)),
                const SizedBox(height: 16),
                const Text('لا توجد عروض متاحة حالياً في السوق',
                    style: TextStyle(color: Colors.white70, fontSize: 16)),
              ],
            ),
          );
        }

        final listings = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: listings.length,
          itemBuilder: (context, index) {
            final listing = RewardListing.fromMap(listings[index]);
            return _buildListingCard(listing);
          },
        );
      },
    );
  }

  Widget _buildMyRewardsTab() {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<List<ActiveReward>>(
      stream: _rewardsService.getActiveRewards(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.tealAccent));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 80, color: Colors.white.withValues(alpha: 0.2)),
                const SizedBox(height: 16),
                const Text('ليس لديك باقات جارية حالياً',
                    style: TextStyle(color: Colors.white70, fontSize: 16)),
              ],
            ),
          );
        }

        final rewards = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: rewards.length,
          itemBuilder: (context, index) {
            return _buildActiveRewardCard(rewards[index]);
          },
        );
      },
    );
  }

  Widget _buildActiveRewardCard(ActiveReward harvest) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: AppTheme.glassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(harvest.packageName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.teal.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'نشطة',
                    style: TextStyle(color: Colors.tealAccent, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: harvest.progress,
                backgroundColor: Colors.white10,
                color: Colors.tealAccent,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoColumn(
                    'الأيام المتبقية', '${harvest.remainingDays} يوم'),
                _buildInfoColumn('المكافأة اليومية',
                    '${_formatNumber(harvest.dailyReward)} جوهرة'),
                _buildInfoColumn(
                    'الإجمالي', '${_formatNumber(harvest.totalReward)} جوهرة'),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppTheme.gradientButton(
                    text: 'عرض للبيع في السوق',
                    onPressed: () => _showListForSaleDialog(harvest),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showCancelPackageDialog(harvest),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text('إلغاء الباقة',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showListForSaleDialog(ActiveReward reward) {
    final TextEditingController priceController = TextEditingController();
    String selectedCurrency = 'stars';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF021B2B),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('عرض الباقة للبيع',
              style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('أدخل سعر البيع المطلوب لباقة "${reward.packageName}"',
                  style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'السعر',
                  labelStyle: const TextStyle(color: Colors.tealAccent),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white24),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.tealAccent),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('اختر عملة البيع:',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _currencyOption(
                      label: 'النجوم ⭐',
                      value: 'stars',
                      groupValue: selectedCurrency,
                      onChanged: (val) =>
                          setModalState(() => selectedCurrency = val!),
                    ),
                  ),
                  Expanded(
                    child: _currencyOption(
                      label: 'الجواهر 💎',
                      value: 'gems',
                      groupValue: selectedCurrency,
                      onChanged: (val) =>
                          setModalState(() => selectedCurrency = val!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('إلغاء', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () async {
                final price = double.tryParse(priceController.text);
                if (price == null || price <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يرجى إدخال سعر صحيح')),
                  );
                  return;
                }
                Navigator.pop(context);
                _processListForSale(reward.id, price, selectedCurrency);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text('تأكيد العرض'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _currencyOption(
      {required String label,
      required String value,
      required String groupValue,
      required ValueChanged<String?> onChanged}) {
    bool isSelected = value == groupValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.teal.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isSelected ? Colors.tealAccent : Colors.transparent),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.tealAccent : Colors.white54,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _processListForSale(
      String rewardId, double price, String currency) async {
    try {
      await _rewardsService.createTradeListing(
        rewardId: rewardId,
        askingPrice: price,
        currency: currency,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم عرض الباقة في السوق بنجاح!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('فشل العرض: $e'),
              backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Widget _buildListingCard(RewardListing listing) {
    final harvest = ActiveReward.fromMap(listing.rewardData, listing.rewardId);
    final bool isMyListing =
        listing.sellerId == FirebaseAuth.instance.currentUser?.uid;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: AppTheme.glassContainer(
        padding: const EdgeInsets.all(16),
        borderGlow: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(listing.packageName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Text('البائع: ${listing.sellerId.substring(0, 8)}...',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.green.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    '${_formatNumber(listing.askingPrice)} ${listing.currency == 'stars' ? 'نجمة ⭐' : 'جوهرة 💎'}',
                    style: const TextStyle(
                        color: Colors.greenAccent, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(color: Colors.white10, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoColumn('المكافآت المتبقية',
                    '${_formatNumber(harvest.remainingReward)} جوهرة'),
                _buildInfoColumn(
                    'الأيام المتبقية', '${harvest.remainingDays} يوم'),
                _buildInfoColumn('المكافأة اليومية',
                    '${_formatNumber(harvest.dailyReward)} جوهرة'),
              ],
            ),
            if (listing.description != null &&
                listing.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(listing.description!,
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
            const SizedBox(height: 16),
            if (isMyListing)
              Row(
                children: [
                  Expanded(
                    child: AppTheme.gradientButton(
                      text: 'تعديل العرض',
                      onPressed: () => _showEditListingDialog(listing),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showCancelListingDialog(listing),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('إلغاء البيع',
                          style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: AppTheme.gradientButton(
                  text: 'شراء الحصاد الآن',
                  onPressed: () => _showPurchaseDialog(listing),
                  isRoyal: true,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showEditListingDialog(RewardListing listing) {
    final TextEditingController priceController =
        TextEditingController(text: listing.askingPrice.toString());
    String selectedCurrency = listing.currency;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF021B2B),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('تعديل بيانات العرض',
              style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('تعديل سعر البيع لباقة "${listing.packageName}"',
                  style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'السعر الجديد',
                  labelStyle: const TextStyle(color: Colors.tealAccent),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white24),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.tealAccent),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('تغيير عملة البيع:',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _currencyOption(
                      label: 'النجوم ⭐',
                      value: 'stars',
                      groupValue: selectedCurrency,
                      onChanged: (val) =>
                          setModalState(() => selectedCurrency = val!),
                    ),
                  ),
                  Expanded(
                    child: _currencyOption(
                      label: 'الجواهر 💎',
                      value: 'gems',
                      groupValue: selectedCurrency,
                      onChanged: (val) =>
                          setModalState(() => selectedCurrency = val!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('إلغاء', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () async {
                final price = double.tryParse(priceController.text);
                if (price == null || price <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يرجى إدخال سعر صحيح')),
                  );
                  return;
                }
                Navigator.pop(context);
                _processUpdateListing(listing.id, price, selectedCurrency);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text('حفظ التعديلات'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processUpdateListing(
      String listingId, double price, String currency) async {
    try {
      await _rewardsService.updateTradeListing(
        listingId: listingId,
        newPrice: price,
        newCurrency: currency,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم تحديث العرض بنجاح!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('فشل التعديل: $e'),
              backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _showCancelListingDialog(RewardListing listing) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF021B2B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('إلغاء العرض', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('هل أنت متأكد من إلغاء عرض باقة "${listing.packageName}"؟',
                style: const TextStyle(color: Colors.white70)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('تراجع', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _processCancelListing(listing.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('تأكيد الإلغاء',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCancelPackageDialog(ActiveReward reward) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF021B2B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('إلغاء الباقة',
            style: TextStyle(
                color: Colors.redAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('هل أنت متأكد من إلغاء باقة "${reward.packageName}"؟',
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 10),
            const Text(
                'سيتم إيقاف المكافآت اليومية وسيتم استرداد جزء من المبلغ المتبقي.',
                style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('تراجع', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _cancelPackage(reward);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('تأكيد الإلغاء',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelPackage(ActiveReward reward) async {
    try {
      await _rewardsService.cancelListing(reward.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم إلغاء الباقة بنجاح'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('خطأ في إلغاء الباقة: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  Future<void> _processCancelListing(String listingId) async {
    try {
      await _rewardsService.cancelListing(listingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم إلغاء العرض بنجاح'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('خطأ في إلغاء العرض: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13)),
      ],
    );
  }

  void _showPurchaseDialog(RewardListing listing) {
    final currencyText = listing.currency == 'stars' ? 'نجمة ⭐' : 'جوهرة 💎';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF021B2B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:
            const Text('تأكيد الشراء', style: TextStyle(color: Colors.white)),
        content: Text(
            'هل أنت متأكد من شراء حصاد "${listing.packageName}" مقابل ${_formatNumber(listing.askingPrice)} $currencyText؟\n\nستنتقل ملكية الحصاد ومكافآته المتبقية إليك فوراً.\n\nتنبيه: هذه العناصر افتراضية للترفيه فقط ولا تمثل أموالاً حقيقية.',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              _processPurchase(listing.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('تأكيد الشراء'),
          ),
        ],
      ),
    );
  }

  Future<void> _processPurchase(String listingId) async {
    try {
      await _rewardsService.purchaseFromMarketplace(listingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تمت عملية الشراء بنجاح! 🎉'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('فشل الشراء: $e'),
              backgroundColor: Colors.redAccent),
        );
      }
    }
  }
}
