import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../theme/design_tokens.dart';
import '../theme/reusable_widgets.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../models/frame_model.dart';
import '../widgets/royal_frame_widget.dart';
import '../widgets/animated_vehicle_preview.dart';
import 'gems_coins_page.dart';
import '../widgets/feature_lock_wrapper.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_manager.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);
    // تم إزالة مستمع التنقل بين التبويبات بناءً على طلبك لتقليل الإزعاج
    _initBannerAd();

    // إظهار إعلان ملء الشاشة عند دخول المتجر (مرة واحدة)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdManager().showInterstitialAd();
    });
  }

  // تم إزالة دالة _onTabChanged لمنع ظهور الإعلانات عند كل تنقل

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
    return FeatureLockWrapper(
      lockField: 'isStoreLocked',
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: PopScope(
          canPop: true,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) {
              // إظهار إعلان الخروج باحتمالية 50% للامتثال لسياسات جوجل ومنع إزعاج المستخدم
              if (math.Random().nextBool()) {
                AdManager().showInterstitialAd();
              }
            }
          },
          child: Scaffold(
            backgroundColor: DesignTokens.backgroundDarkDeep,
            bottomNavigationBar: _isAdLoaded && _bannerAd != null
                ? Container(
                    color: DesignTokens.backgroundDarkDeep,
                    height: _bannerAd!.size.height.toDouble(),
                    width: double.infinity,
                    child: AdWidget(ad: _bannerAd!),
                  )
                : null,
            body: StreamBuilder<UserModel>(
              stream: user != null
                  ? _firestoreService.streamUserData(user.uid)
                  : null,
              builder: (context, snapshot) {
                final userData = snapshot.data;
                return CustomScrollView(
                  slivers: [
                    _buildRoyalSliverAppBar(userData),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SliverAppBarDelegate(
                        TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          indicatorColor: DesignTokens.primaryGold,
                          labelColor: DesignTokens.primaryGold,
                          unselectedLabelColor: DesignTokens.neutralGray500,
                          labelStyle: const TextStyle(
                            fontFamily: DesignTokens.primaryFont,
                            fontWeight: DesignTokens.fontWeightBold,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontFamily: DesignTokens.primaryFont,
                            fontWeight: DesignTokens.fontWeightNormal,
                          ),
                          tabs: const [
                            Tab(text: 'الإطارات'),
                            Tab(text: 'المركبات'),
                            Tab(text: 'الدومينو'),
                            Tab(text: 'المؤثرات'),
                            Tab(text: 'الشارات'),
                            Tab(text: 'الأغلفة'),
                            Tab(text: 'الفقاعات'),
                            Tab(text: 'الأرقام المميزة'),
                            Tab(text: 'التوثيق'),
                          ],
                        ),
                      ),
                    ),
                    SliverFillRemaining(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildDynamicFramesGrid(userData),
                          _buildDynamicVehiclesGrid(userData),
                          _buildDominoStoreGrid(userData),
                          _buildDynamicEntryEffectsGrid(userData),
                          _buildBadgesSection(userData),
                          _buildDynamicCoversGrid(userData),
                          _buildDynamicBubblesGrid(userData),
                          _buildDynamicSpecialIdGrid(userData),
                          _buildDynamicVerificationGrid(userData),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDominoStoreGrid(UserModel? userData) {
    return StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('domino_skins')
            .where('isActive', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const RoyalLoadingIndicator();
          }
          if (snapshot.hasError) {
            return _buildErrorState();
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return _buildEmptyState('لا توجد قطع دومينو حالياً');
          }
          return GridView.builder(
            padding: const EdgeInsets.all(DesignTokens.spacingMd),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: DesignTokens.spacingMd,
                mainAxisSpacing: DesignTokens.spacingMd),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return _buildStoreItemCard(
                  docs[index].id, data, 'domino_skin', userData);
            },
          );
        });
  }

  Widget _buildDynamicCoversGrid(UserModel? userData) {
    return StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('covers')
            .where('isActive', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const RoyalLoadingIndicator();
          }
          if (snapshot.hasError) {
            return _buildErrorState();
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return _buildEmptyState('لا توجد أغلفة بروفايل حالياً');
          }
          return GridView.builder(
            padding: const EdgeInsets.all(DesignTokens.spacingMd),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: DesignTokens.spacingMd,
                mainAxisSpacing: DesignTokens.spacingMd),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return _buildStoreItemCard(
                  docs[index].id, data, 'cover', userData);
            },
          );
        });
  }

  Widget _buildDynamicBubblesGrid(UserModel? userData) {
    return StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('bubbles')
            .where('isActive', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const RoyalLoadingIndicator();
          }
          if (snapshot.hasError) {
            return _buildErrorState();
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return _buildEmptyState('لا توجد فقاعات دردشة حالياً');
          }
          return GridView.builder(
            padding: const EdgeInsets.all(DesignTokens.spacingMd),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: DesignTokens.spacingMd,
                mainAxisSpacing: DesignTokens.spacingMd),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return _buildStoreItemCard(
                  docs[index].id, data, 'bubble', userData);
            },
          );
        });
  }

  Widget _buildStoreItemCard(
      String id, Map<String, dynamic> data, String type, UserModel? userData) {
    int price = (data['price'] ?? 0).toInt();
    String url = data['url'] ?? data['imageUrl'] ?? '';

    return StreamBuilder<QuerySnapshot>(
        stream: userData != null
            ? _db
                .collection('users')
                .doc(userData.uid)
                .collection('inventory')
                .where('imageUrl', isEqualTo: url)
                .snapshots()
            : null,
        builder: (context, snapshot) {
          bool isOwned = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

          return Container(
            padding: const EdgeInsets.all(DesignTokens.spacingMd),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(DesignTokens.borderRadiusXl2),
              border: Border.all(
                color: isOwned
                    ? DesignTokens.primaryGold.withValues(alpha: 0.3)
                    : DesignTokens.neutralWhite.withValues(alpha: 0.05),
              ),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius:
                          BorderRadius.circular(DesignTokens.borderRadiusLg),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: type == 'frame'
                        ? RoyalFrameWidget(
                            frameUrl: url,
                            size: 80,
                            child: const CircleAvatar(
                              radius: 35,
                              backgroundColor: Colors.white10,
                              child: Icon(Icons.person,
                                  color: Colors.white12, size: 40),
                            ),
                          )
                        : url.isNotEmpty &&
                                Uri.tryParse(url)?.host.isNotEmpty == true
                            ? CachedNetworkImage(
                                imageUrl: url,
                                fit: BoxFit.contain,
                                placeholder: (c, u) => const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: DesignTokens.primaryGold)),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.broken_image,
                                        color: DesignTokens.neutralGray700),
                              )
                            : const Center(
                                child: Icon(Icons.image_not_supported,
                                    color: DesignTokens.neutralGray700)),
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingSm),
                BodyText(data['name'] ?? 'عنصر ملكي',
                    fontSize: DesignTokens.fontSizeSm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    fontWeight: DesignTokens.fontWeightBold),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.stars_rounded,
                        color: DesignTokens.primaryGold, size: 14),
                    const SizedBox(width: 4),
                    CaptionText('$price',
                        color: DesignTokens.primaryGold,
                        fontWeight: FontWeight.bold),
                  ],
                ),
                const SizedBox(height: DesignTokens.spacingMd),
                SizedBox(
                  width: double.infinity,
                  child: RoyalButton(
                    height: 34,
                    onPressed: isOwned
                        ? null
                        : () => _purchaseStoreItem(id, data, type, userData),
                    label: isOwned ? 'مملوك' : 'اقتناء',
                    gradient: isOwned
                        ? [
                            DesignTokens.neutralGray700,
                            DesignTokens.neutralGray800
                          ]
                        : [
                            DesignTokens.primaryGold,
                            DesignTokens.primarySapphireLight
                          ],
                  ),
                ),
              ],
            ),
          );
        });
  }

  void _purchaseStoreItem(String id, Map<String, dynamic> data, String type,
      UserModel? user) async {
    if (user == null) return;
    int price = (data['price'] ?? 0).toInt();
    if (user.stars < price) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('رصيد النجوم غير كافٍ ⭐')));
      return;
    }

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => RoyalConfirmDialog(
        title: 'اقتناء ${type == 'cover' ? 'غلاف' : 'فقاعة'}',
        message: 'هل تريد الشراء مقابل $price نجمة؟',
        confirmLabel: 'شراء',
        icon: type == 'cover' ? Icons.style : Icons.chat_bubble_outline,
        onConfirm: () => Navigator.pop(ctx, true),
      ),
    );

    if (confirm == true) {
      await _db.runTransaction((tx) async {
        final userRef = _db.collection('users').doc(user.uid);
        tx.update(userRef, {'stars': user.stars - price});
        tx.set(userRef.collection('inventory').doc(), {
          'type': type,
          'name': data['name'],
          'imageUrl': data['url'],
          'boughtAt': FieldValue.serverTimestamp(),
        });
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('تمت الإضافة لمقتنياتك بنجاح ✨'),
            backgroundColor: DesignTokens.primaryGold));
      }
    }
  }

  Widget _buildDynamicVehiclesGrid(UserModel? userData) {
    return StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('vehicles')
            .where('isActive', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const RoyalLoadingIndicator();
          }
          if (snapshot.hasError) {
            return _buildErrorState();
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return _buildEmptyState('لا توجد مركبات متاحة حالياً');
          }
          return GridView.builder(
            padding: const EdgeInsets.all(DesignTokens.spacingMd),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: DesignTokens.spacingMd,
                mainAxisSpacing: DesignTokens.spacingMd),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return _buildVehicleStoreCard(docs[index].id, data, userData);
            },
          );
        });
  }

  Widget _buildVehicleStoreCard(
      String id, Map<String, dynamic> data, UserModel? userData) {
    String url = data['url'] ?? '';
    String type = data['type'] ?? 'gif';
    int price = (data['price'] ?? 0).toInt();

    return StreamBuilder<QuerySnapshot>(
        stream: userData != null
            ? _db
                .collection('users')
                .doc(userData.uid)
                .collection('inventory')
                .where('imageUrl', isEqualTo: url)
                .snapshots()
            : null,
        builder: (context, snapshot) {
          bool isOwned = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

          return Container(
            padding: const EdgeInsets.all(DesignTokens.spacingMd),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(DesignTokens.borderRadiusXl2),
              border: Border.all(
                color: isOwned
                    ? DesignTokens.primarySapphireLight.withValues(alpha: 0.3)
                    : DesignTokens.neutralWhite.withValues(alpha: 0.05),
              ),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black38, blurRadius: 15, offset: Offset(0, 5))
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(colors: [
                        DesignTokens.primarySapphire.withValues(alpha: 0.1),
                        Colors.transparent
                      ]),
                      borderRadius:
                          BorderRadius.circular(DesignTokens.borderRadiusLg),
                    ),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(DesignTokens.borderRadiusLg),
                      child: AnimatedVehiclePreview(
                        type: type,
                        url: url,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingSm),
                BodyText(data['name'] ?? 'مركبة ملكية',
                    fontSize: DesignTokens.fontSizeSm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    fontWeight: DesignTokens.fontWeightBold),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.stars_rounded,
                        color: DesignTokens.primaryGold, size: 14),
                    const SizedBox(width: 4),
                    CaptionText('$price',
                        color: DesignTokens.primaryGold,
                        fontWeight: FontWeight.bold),
                  ],
                ),
                const SizedBox(height: DesignTokens.spacingMd),
                SizedBox(
                  width: double.infinity,
                  child: RoyalButton(
                    height: 36,
                    onPressed: isOwned
                        ? null
                        : () => _purchaseVehicle(id, data, userData),
                    label: isOwned ? 'مملوكة' : 'اقتناء',
                    gradient: isOwned
                        ? [
                            DesignTokens.neutralGray700,
                            DesignTokens.neutralGray800
                          ]
                        : [
                            DesignTokens.primarySapphireLight,
                            DesignTokens.primarySapphire
                          ],
                  ),
                ),
              ],
            ),
          );
        });
  }

  void _purchaseVehicle(
      String id, Map<String, dynamic> data, UserModel? user) async {
    if (user == null) return;
    int price = (data['price'] ?? 0).toInt();
    if (user.stars < price) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('رصيد النجوم غير كافٍ ⭐')));
      return;
    }

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => RoyalConfirmDialog(
        title: 'اقتناء مركبة',
        message: 'هل تريد شراء مركبة (${data['name']}) مقابل $price نجمة؟',
        confirmLabel: 'شراء',
        icon: Icons.directions_car,
        onConfirm: () => Navigator.pop(ctx, true),
      ),
    );

    if (confirm == true) {
      await _db.runTransaction((tx) async {
        final userRef = _db.collection('users').doc(user.uid);
        tx.update(userRef, {'stars': user.stars - price});
        tx.set(userRef.collection('inventory').doc(), {
          'type': 'vehicle',
          'name': data['name'],
          'imageUrl': data['url'],
          'vehicleType': data['type'],
          'boughtAt': FieldValue.serverTimestamp(),
        });
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('مبروك! تم إضافة العنصر إلى مرآبك الخاص 🏎️'),
            backgroundColor: DesignTokens.primarySapphireLight));
      }
    }
  }

  Widget _buildDynamicFramesGrid(UserModel? userData) {
    return StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('frames')
            .where('isActive', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const RoyalLoadingIndicator();
          }
          if (snapshot.hasError) {
            return _buildErrorState();
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return _buildEmptyState('لا توجد إطارات متاحة حالياً');
          }
          return GridView.builder(
            padding: const EdgeInsets.all(DesignTokens.spacingMd),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: DesignTokens.spacingMd,
                mainAxisSpacing: DesignTokens.spacingMd),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final frame = FrameModel.fromFirestore(
                  docs[index] as DocumentSnapshot<Map<String, dynamic>>);
              return _buildFrameStoreCard(frame, userData);
            },
          );
        });
  }

  Widget _buildFrameStoreCard(FrameModel frame, UserModel? userData) {
    return StreamBuilder<QuerySnapshot>(
        stream: userData != null
            ? _db
                .collection('users')
                .doc(userData.uid)
                .collection('inventory')
                .where('imageUrl', isEqualTo: frame.imageUrl)
                .snapshots()
            : null,
        builder: (context, snapshot) {
          bool isOwned = (snapshot.hasData && snapshot.data!.docs.isNotEmpty) ||
              userData?.currentFrame == frame.imageUrl;
          return RoyalCard(
            padding: const EdgeInsets.all(DesignTokens.spacingMd),
            margin: EdgeInsets.zero,
            backgroundColor:
                DesignTokens.backgroundDarkMedium.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(DesignTokens.borderRadiusXl2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                    child: RoyalFrameWidget(
                        frameUrl: frame.imageUrl,
                        size: 110,
                        child: CircleAvatar(
                            radius: 35,
                            backgroundColor: DesignTokens.neutralWhite
                                .withValues(alpha: 0.05),
                            child: const Icon(Icons.person,
                                color: DesignTokens.neutralGray700)))),
                const SizedBox(height: DesignTokens.spacingSm),
                BodyText(frame.name,
                    textAlign: TextAlign.center,
                    fontSize: DesignTokens.fontSizeSm,
                    fontWeight: DesignTokens.fontWeightBold),
                CaptionText('${frame.price} ⭐',
                    color: DesignTokens.primaryGold),
                const SizedBox(height: DesignTokens.spacingMd),
                RoyalButton(
                  height: 32,
                  onPressed: isOwned
                      ? () {}
                      : () => _purchaseFrameDirect(frame, userData),
                  label: isOwned ? 'تملكه ✅' : 'اقتناء',
                  gradient: isOwned
                      ? [
                          DesignTokens.semanticDisabled,
                          DesignTokens.semanticDisabled.withValues(alpha: 0.6)
                        ]
                      : null,
                ),
              ],
            ),
          );
        });
  }

  void _purchaseFrameDirect(FrameModel frame, UserModel? user) async {
    if (user == null) return;
    if (user.stars < frame.price) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('رصيد النجوم غير كافٍ ⭐')));
      return;
    }
    bool? confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => RoyalConfirmDialog(
              title: 'اقتناء إطار ملكي',
              message:
                  'هل تريد شراء إطار (${frame.name}) مقابل ${frame.price} نجمة؟',
              confirmLabel: 'شراء',
              icon: Icons.portrait,
              onConfirm: () => Navigator.pop(ctx, true),
            ));
    if (confirm == true) {
      await _db.runTransaction((tx) async {
        final userRef = _db.collection('users').doc(user.uid);
        tx.update(userRef, {'stars': user.stars - frame.price});
        tx.set(userRef.collection('inventory').doc(), {
          'type': 'frame',
          'name': frame.name,
          'imageUrl': frame.imageUrl,
          'boughtAt': FieldValue.serverTimestamp()
        });
      });
    }
  }

  Widget _buildBadgesSection(UserModel? userData) {
    return StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('badges_templates')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.amber));
          }
          if (snapshot.hasError) {
            return _buildErrorState();
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return _buildEmptyState('لا توجد أوسمة متاحة حالياً');
          }
          final dynamicBadges =
              docs.map((d) => d.data() as Map<String, dynamic>).toList();
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.65,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8),
            itemCount: dynamicBadges.length,
            itemBuilder: (context, index) =>
                _buildBadgeStoreCard(dynamicBadges[index], userData),
          );
        });
  }

  Widget _buildBadgeStoreCard(Map<String, dynamic> data, UserModel? userData) {
    int price = data['price'] ?? 0;
    final bool isImage = data['isImage'] ?? false;
    final String iconData = data['icon'] ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: userData != null
          ? _db
              .collection('users')
              .doc(userData.uid)
              .collection('inventory')
              .where('icon', isEqualTo: iconData)
              .snapshots()
          : null,
      builder: (context, snapshot) {
        bool isOwned = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: isOwned
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.amber.withValues(alpha: 0.1))),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: isImage
                      ? (iconData.isNotEmpty &&
                              Uri.tryParse(iconData)?.host.isNotEmpty == true
                          ? CachedNetworkImage(
                              imageUrl: iconData,
                              width: 40,
                              height: 40,
                              placeholder: (context, url) =>
                                  const CircularProgressIndicator(
                                      strokeWidth: 2),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error, color: Colors.red),
                            )
                          : const Icon(Icons.broken_image,
                              color: Colors.white24))
                      : Text(iconData,
                          style: const TextStyle(fontSize: 30),
                          overflow: TextOverflow.ellipsis),
                ),
              ),
              const SizedBox(height: 5),
              Text(data['name'] ?? 'وسام',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
              Text('$price ⭐',
                  style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 9,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed:
                    isOwned ? null : () => _purchaseBadge(data, userData),
                style: ElevatedButton.styleFrom(
                    backgroundColor: isOwned
                        ? Colors.grey.withValues(alpha: 0.1)
                        : Colors.amber.withValues(alpha: 0.1),
                    minimumSize: const Size(double.infinity, 28),
                    padding: EdgeInsets.zero),
                child: Text(isOwned ? 'تملكه ✅' : 'اقتناء',
                    style: TextStyle(
                        fontSize: 9,
                        color: isOwned ? Colors.white38 : Colors.amber)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _purchaseBadge(Map<String, dynamic> data, UserModel? user) async {
    if (user == null) return;
    int price = data['price'] ?? 0;
    if (user.stars < price) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('رصيد النجوم غير كافٍ ⭐')));
      return;
    }
    bool? confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1A1A2E),
              title: const Text('اقتناء وسام',
                  style: TextStyle(color: Colors.white)),
              content: Text(
                  'هل تريد شراء شارة (${data['name']}) مقابل $price نجمة؟'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('إلغاء')),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('شراء',
                        style: TextStyle(color: Colors.amber))),
              ],
            ));
    if (confirm == true) {
      await _db.runTransaction((tx) async {
        final userRef = _db.collection('users').doc(user.uid);
        tx.update(userRef, {'stars': user.stars - price});
        tx.set(userRef.collection('inventory').doc(), {
          'type': 'badge',
          'name': data['name'],
          'icon': data['icon'],
          'isImage': data['isImage'] ?? false,
          'boughtAt': FieldValue.serverTimestamp()
        });
      });
    }
  }

  Widget _buildDynamicEntryEffectsGrid(UserModel? userData) {
    return StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('entry_effects')
            .where('isActive', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.amber));
          }
          if (snapshot.hasError) {
            return _buildErrorState();
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return _buildEmptyState('لا توجد تأثيرات دخول حالياً');
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return _buildEntryEffectStoreCard(docs[index].id, data, userData);
            },
          );
        });
  }

  Widget _buildEntryEffectStoreCard(
      String docId, Map<String, dynamic> data, UserModel? userData) {
    int price = data['price'] ?? 0;
    final String url = data['lottieUrl'] ?? '';
    final bool isLottie = url.contains('.json');

    return Container(
      padding: const EdgeInsets.all(DesignTokens.spacingMd),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(DesignTokens.borderRadiusXl2),
        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.2)),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius:
                    BorderRadius.circular(DesignTokens.borderRadiusLg),
              ),
              padding: const EdgeInsets.all(8),
              child: url.isNotEmpty
                  ? (isLottie
                      ? Lottie.network(url, fit: BoxFit.contain)
                      : (Uri.tryParse(url)?.host.isNotEmpty == true
                          ? CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.contain,
                              placeholder: (c, u) => const Center(
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.amber)),
                              errorWidget: (context, url, error) => const Icon(
                                  Icons.broken_image,
                                  color: Colors.white24),
                            )
                          : const Icon(Icons.broken_image,
                              color: Colors.white24)))
                  : const Icon(Icons.rocket_launch_rounded,
                      color: Colors.purpleAccent, size: 45),
            ),
          ),
          const SizedBox(height: 12),
          BodyText(data['name'] ?? 'تأثير دخول',
              fontSize: DesignTokens.fontSizeSm,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              fontWeight: DesignTokens.fontWeightBold),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.stars_rounded, color: Colors.amber, size: 14),
              const SizedBox(width: 4),
              CaptionText('$price',
                  color: Colors.amber, fontWeight: FontWeight.bold),
            ],
          ),
          const SizedBox(height: DesignTokens.spacingMd),
          SizedBox(
            width: double.infinity,
            child: RoyalButton(
              height: 34,
              onPressed: () => _purchaseEntryEffect(docId, data, userData),
              label: 'اقتناء الآن',
              gradient: const [Colors.purple, Colors.deepPurpleAccent],
            ),
          ),
        ],
      ),
    );
  }

  void _purchaseEntryEffect(
      String docId, Map<String, dynamic> data, UserModel? user) async {
    if (user == null) return;
    int price = data['price'] ?? 0;
    if (user.stars < price) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('الرصيد غير كافٍ ⭐')));
      return;
    }
    await _db.runTransaction((tx) async {
      final userRef = _db.collection('users').doc(user.uid);
      tx.update(userRef, {'stars': user.stars - price});
      tx.set(userRef.collection('inventory').doc(docId), {
        'type': 'entry_effect',
        'name': data['name'],
        'imageUrl': data['lottieUrl'],
        'boughtAt': FieldValue.serverTimestamp()
      });
    });
  }

  Widget _buildDynamicVerificationGrid(UserModel? userData) {
    return StreamBuilder<QuerySnapshot>(
        stream: _db.collection('verifications').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.amber));
          }
          if (snapshot.hasError) {
            return _buildErrorState();
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return _buildEmptyState('لا توجد عروض توثيق حالياً');
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return _buildVerificationStoreCard(
                  docs[index].id, data, userData);
            },
          );
        });
  }

  Widget _buildVerificationStoreCard(
      String docId, Map<String, dynamic> data, UserModel? userData) {
    String? hex = data['color'];
    Color badgeColor = Colors.amber;
    if (hex != null && hex.isNotEmpty) {
      try {
        String cleanHex = hex.replaceAll('#', '');
        if (cleanHex.length == 6) cleanHex = 'FF$cleanHex';
        badgeColor = Color(int.parse('0x$cleanHex'));
      } catch (_) {}
    }
    bool isOwned = userData?.verificationColor == data['color'];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: badgeColor.withValues(alpha: 0.3))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified, color: badgeColor, size: 50),
          const SizedBox(height: 12),
          Text(data['name'] ?? 'توثيق',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
          Text('${data['price']} نجمة ⭐',
              style: TextStyle(
                  color: badgeColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          ElevatedButton(
              onPressed: isOwned
                  ? null
                  : () => _purchaseVerification(docId, data, userData),
              style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isOwned ? Colors.grey : badgeColor.withValues(alpha: 0.2),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 35),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: Text(isOwned ? 'مفعل ✅' : 'شراء وتوثيق',
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _purchaseVerification(
      String docId, Map<String, dynamic> data, UserModel? user) async {
    if (user == null) return;
    int price = (data['price'] ?? 0).toInt();
    if (user.stars < price) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('رصيد النجوم غير كافٍ ⭐')));
      return;
    }
    await _db.runTransaction((tx) async {
      tx.update(_db.collection('users').doc(user.uid),
          {'stars': user.stars - price, 'verificationColor': data['color']});
    });
  }

  Widget _buildDynamicSpecialIdGrid(UserModel? userData) {
    return StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('special_ids')
            .where('showInStore', isEqualTo: true)
            .where('isSold', isEqualTo: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _buildErrorState();
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return _buildEmptyState('لا توجد أرقام مميزة متاحة');
          }
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return _buildIdStoreCard(docs[index].id, data, userData);
            },
          );
        });
  }

  Widget _buildIdStoreCard(
      String docId, Map<String, dynamic> data, UserModel? userData) {
    final currency = data['currencyType'] ?? 'stars';
    final price = data['price'] ?? 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.1))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.badge, color: Colors.amber, size: 35),
          const SizedBox(height: 8),
          Text(data['royalId'] ?? '---',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5)),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('$price ',
                style: const TextStyle(
                    color: Colors.amber, fontWeight: FontWeight.bold)),
            Icon(currency == 'gems' ? Icons.diamond : Icons.stars_rounded,
                size: 14,
                color: currency == 'gems' ? Colors.cyanAccent : Colors.amber)
          ]),
          const SizedBox(height: 12),
          ElevatedButton(
              onPressed: () =>
                  _handlePurchaseId(docId, price, currency, userData),
              child: const Text('استبدال',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Future<void> _handlePurchaseId(
      String docId, int price, String currency, UserModel? user) async {
    if (user == null) return;
    final bal = currency == 'gems' ? user.gems : user.stars;
    if (bal < price) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('الرصيد غير كافٍ ⭐')));
      }
      return;
    }

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('purchaseRoyalId');
      final result = await callable.call({
        'specialIdDocId': docId,
      });

      if (result.data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('تم شراء المعرف بنجاح ✅'),
              backgroundColor: Colors.green));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(result.data['message']?.toString() ??
                  'حدث خطأ أثناء شراء المعرف')));
        }
      }
    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? 'خطأ في الخادم')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ غير متوقع: $e')));
      }
    }
  }

  Widget _buildRoyalSliverAppBar(UserModel? user) {
    return SliverAppBar(
      expandedHeight: 180.0,
      pinned: true,
      backgroundColor: DesignTokens.backgroundDarkMedium,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                DesignTokens.backgroundDarkMedium,
                DesignTokens.backgroundDarkDeep
              ])),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(height: 40),
            const Icon(Icons.shopping_bag,
                color: DesignTokens.primaryRuby, size: 35),
            const HeadingText('المتجر الملكي المطور',
                fontSize: DesignTokens.fontSizeXl2),
            const SizedBox(height: DesignTokens.spacingMd),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const GemsCoinsPage())),
                  child: _buildGlassBalance(user?.gems.toString() ?? '0',
                      Icons.diamond, DesignTokens.primarySapphireLight)),
              const SizedBox(width: DesignTokens.spacingSm),
              GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const GemsCoinsPage())),
                  child: _buildGlassBalance(user?.stars.toString() ?? '0',
                      Icons.stars, DesignTokens.primaryGold)),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _buildGlassBalance(String amount, IconData icon, Color color) {
    return Container(
        padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingMd,
            vertical: DesignTokens.spacingXs),
        decoration: BoxDecoration(
            color: DesignTokens.neutralWhite.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(DesignTokens.borderRadiusFull),
            border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Row(children: [
          Icon(icon, color: color, size: DesignTokens.iconSizeXs),
          const SizedBox(width: DesignTokens.spacingSm),
          BodyText(amount,
              fontWeight: DesignTokens.fontWeightBold,
              fontSize: DesignTokens.fontSizeSm,
              color: DesignTokens.neutralWhite),
        ]));
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline,
              color: DesignTokens.primaryRuby, size: 40),
          const SizedBox(height: 10),
          const BodyText('حدث خطأ في تحميل البيانات',
              color: DesignTokens.neutralGray500),
          TextButton(
              onPressed: () => setState(() {}),
              child: const Text('إعادة المحاولة')),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inventory_2_outlined,
              color: DesignTokens.neutralGray700, size: 40),
          const SizedBox(height: 10),
          BodyText(message, color: DesignTokens.neutralGray500),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(context, shrink, overlaps) =>
      Container(color: DesignTokens.backgroundDarkDeep, child: _tabBar);
  @override
  bool shouldRebuild(_SliverAppBarDelegate old) => false;
}
