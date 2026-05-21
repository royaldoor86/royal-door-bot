import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/design_tokens.dart';
import '../theme/reusable_widgets.dart';
import '../app_theme.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_manager.dart';

class GemsCoinsPage extends StatefulWidget {
  const GemsCoinsPage({super.key});

  @override
  State<GemsCoinsPage> createState() => _GemsCoinsPageState();
}

class _GemsCoinsPageState extends State<GemsCoinsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initBannerAd();
  }

  void _initBannerAd() {
    _bannerAd = AdManager().getBannerAd(
      size: AdSize.banner,
      onAdLoaded: () {
        if (mounted) {
          setState(() {
            _isAdLoaded = true;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: DesignTokens.backgroundDarkDeep,
        bottomNavigationBar: _isAdLoaded && _bannerAd != null
            ? Container(
                color: DesignTokens.backgroundDarkDeep,
                height: _bannerAd!.size.height.toDouble(),
                width: _bannerAd!.size.width.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              )
            : null,
        appBar: AppBar(
          backgroundColor: DesignTokens.backgroundDarkMedium,
          elevation: 0,
          title: const HeadingText('مركز الشحن الملكي',
              fontSize: DesignTokens.fontSizeXl),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: DesignTokens.primaryGold,
            labelColor: DesignTokens.primaryGold,
            unselectedLabelColor:
                DesignTokens.neutralWhite.withValues(alpha: 0.54),
            tabs: const [
              Tab(text: 'شحن كوينز 🪙'),
              Tab(text: 'شحن جواهر 💎'),
            ],
          ),
        ),
        body: AppTheme.background(
          child: StreamBuilder<UserModel>(
            stream: user != null
                ? _firestoreService.streamUserData(user.uid)
                : null,
            builder: (context, snapshot) {
              final userData = snapshot.data;
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: RoyalLoadingIndicator());
              }

              return Column(
                children: [
                  _buildWalletHeader(userData),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildPackagesList('coins'),
                        _buildPackagesList('gems'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWalletHeader(UserModel? user) {
    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingXl),
      decoration: const BoxDecoration(
        color: DesignTokens.backgroundDarkMedium,
        borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(DesignTokens.borderRadiusXl3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          GestureDetector(
            onTap: () => _tabController.animateTo(0),
            child: _buildBalanceItem('كوينز', user?.stars.toString() ?? '0',
                const RoyalCoinIcon(size: DesignTokens.iconSizeLg), DesignTokens.primaryGold),
          ),
          Container(
              width: 1,
              height: 40,
              color: DesignTokens.neutralWhite.withValues(alpha: 0.1)),
          GestureDetector(
            onTap: () => _tabController.animateTo(1),
            child: _buildBalanceItem('جواهر', user?.gems.toString() ?? '0',
                const Icon(Icons.diamond, color: DesignTokens.primarySapphireLight, size: DesignTokens.iconSizeLg), DesignTokens.primarySapphireLight),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(
      String label, String amount, Widget icon, Color color) {
    return Column(
      children: [
        icon,
        const SizedBox(height: DesignTokens.spacingSm),
        HeadingText(amount, fontSize: DesignTokens.fontSizeLg),
        CaptionText(label),
      ],
    );
  }

  Widget _buildPackagesList(String type) {
    // دعم كلا الصيغتين (المفرد والجمع) لضمان عدم اختفاء الباقات
    final types = type == 'coins' ? ['coins', 'coin'] : ['gems', 'gem'];
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('recharge_packages')
          .where('type', whereIn: types)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: RoyalLoadingIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('حدث خطأ أثناء تحميل الباقات', style: TextStyle(color: Colors.white.withOpacity(0.5))));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.inventory_2_outlined,
            title: 'لا توجد باقات متاحة حالياً',
          );
        }

        // ترتيب الباقات حسب السعر مع معالجة القيم الفارغة
        final sortedDocs = docs.toList()
          ..sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;
            final priceA = (dataA['price'] ?? 0) as num;
            final priceB = (dataB['price'] ?? 0) as num;
            return priceA.compareTo(priceB);
          });

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: sortedDocs.length,
          itemBuilder: (context, index) {
            final data = sortedDocs[index].data() as Map<String, dynamic>;
            return _buildPackageCard(data, type);
          },
        );
      },
    );
  }

  Widget _buildPackageCard(Map<String, dynamic> data, String type) {
    final color = type == 'coins'
        ? DesignTokens.primaryGold
        : DesignTokens.primarySapphireLight;
    return GlassCard(
      padding: const EdgeInsets.all(DesignTokens.spacingMd),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          type == 'coins'
              ? const RoyalCoinIcon(size: DesignTokens.iconSizeXl)
              : Icon(Icons.diamond,
                  color: color, size: DesignTokens.iconSizeXl),
          const SizedBox(height: DesignTokens.spacingMd),
          BodyText('${data['amount']} ${type == 'coins' ? 'كوينز' : 'جوهرة'}',
              fontWeight: DesignTokens.fontWeightBold),
          HeadingText('${data['price']} نجمة ⭐',
              color: DesignTokens.primaryEmerald,
              fontSize: DesignTokens.fontSizeSm),
          const SizedBox(height: DesignTokens.spacingMd),
          RoyalButton(
            label: 'تفعيل',
            onPressed: () => _launchPaymentWebsite(),
            height: 36,
            gradient: [color, color.withValues(alpha: 0.7)],
          ),
        ],
      ),
    );
  }

  Future<void> _launchPaymentWebsite() async {
    final Uri url = Uri.parse('https://www.royaldoor.live');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح البوابه الملكية حالياً، يرجى المحاولة لاحقاً')),
        );
      }
    }
  }
}
