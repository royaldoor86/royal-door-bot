import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;
import '../theme/design_tokens.dart';
import '../theme/reusable_widgets.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../models/frame_model.dart';
import '../widgets/royal_frame_widget.dart';
import '../widgets/animated_vehicle_preview.dart';
import 'gems_coins_page.dart';
import '../widgets/feature_lock_wrapper.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  late TabController _idCategoryTabController;
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final List<String> _idCategories = [
    'مقترح',
    'الأفضل',
    'ملحمي',
    'نادر',
    'شائع',
    'ملكي'
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 10, vsync: this);
    _idCategoryTabController =
        TabController(length: _idCategories.length, vsync: this);
    _idCategoryTabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _idCategoryTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return FeatureLockWrapper(
      lockField: 'isStoreLocked',
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: DesignTokens.backgroundDarkDeep,
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
                            Tab(text: 'المؤثرات'),
                            Tab(text: 'الشارات'),
                            Tab(text: 'الأغلفة'),
                            Tab(text: 'الفقاعات'),
                            Tab(text: 'الأرقام المميزة'),
                            Tab(text: 'التوثيق'),
                            Tab(text: 'موضوعات الغرف'),
                            Tab(text: 'تثبيت الغرف'),
                          ],
                        ),
                      ),
                    ),
                    SliverFillRemaining(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 80),
                            child: _buildDynamicFramesGrid(userData),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 80),
                            child: _buildDynamicVehiclesGrid(userData),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 80),
                            child: _buildDynamicEntryEffectsGrid(userData),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 80),
                            child: _buildBadgesSection(userData),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 80),
                            child: _buildDynamicCoversGrid(userData),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 80),
                            child: _buildDynamicBubblesGrid(userData),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 80),
                            child: _buildDynamicSpecialIdGrid(userData),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 80),
                            child: _buildDynamicVerificationGrid(userData),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 80),
                            child: _buildDynamicRoomThemesGrid(userData),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 80),
                            child: _buildRoomPinningSection(userData),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }),
        ),
      ),
    );
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
          final screenWidth = MediaQuery.of(context).size.width;
          final crossAxisCount = screenWidth > 600 ? 4 : 2;
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.8,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8),
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
          final screenWidth = MediaQuery.of(context).size.width;
          final crossAxisCount = screenWidth > 600 ? 4 : 2;
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.8,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8),
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
    int gemsPrice = (data['gemsPrice'] ?? 0).toInt();
    int coinsPrice = (data['coinsPrice'] ?? price).toInt();
    String url = data['url'] ?? data['imageUrl'] ?? '';
    // جعل جميع العناصر قيد التطوير مؤقتاً
    final bool inDevelopment = true;

    return StreamBuilder<QuerySnapshot>(
        stream: userData != null
            ? _db
                .collection('users')
                .doc(userData.uid)
                .collection('inventory')
                .where('type', isEqualTo: type)
                .snapshots()
            : null,
        builder: (context, snapshot) {
          bool isOwned = false;
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            for (var doc in snapshot.data!.docs) {
              final itemData = doc.data() as Map<String, dynamic>;
              if (itemData['imageUrl'] == url || itemData['url'] == url) {
                isOwned = true;
                break;
              }
            }
          }

          return Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isOwned
                    ? DesignTokens.primaryGold.withValues(alpha: 0.3)
                    : DesignTokens.neutralWhite.withValues(alpha: 0.05),
              ),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: type == 'frame'
                        ? RoyalFrameWidget(
                            frameUrl: url,
                            size: 50,
                            child: const CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.white10,
                              child: Icon(Icons.person,
                                  color: Colors.white12, size: 20),
                            ),
                          )
                        : url.isNotEmpty &&
                                Uri.tryParse(url)?.host.isNotEmpty == true
                            ? CachedNetworkImage(
                                imageUrl: url,
                                fit: BoxFit.contain,
                                placeholder: (c, u) => const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        color: DesignTokens.primaryGold)),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.broken_image,
                                        color: DesignTokens.neutralGray700,
                                        size: 24),
                              )
                            : const Center(
                                child: Icon(Icons.image_not_supported,
                                    color: DesignTokens.neutralGray700,
                                    size: 24)),
                  ),
                ),
                const SizedBox(height: 4),
                BodyText(data['name'] ?? 'عنصر ملكي',
                    fontSize: 10,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    fontWeight: DesignTokens.fontWeightBold),
                const SizedBox(height: 2),
                if (gemsPrice > 0 && coinsPrice > 0)
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.diamond_outlined,
                              color: Colors.cyan, size: 10),
                          const SizedBox(width: 2),
                          CaptionText('$gemsPrice جواهر',
                              fontSize: 8,
                              color: Colors.cyan,
                              fontWeight: FontWeight.bold),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.stars_rounded,
                              color: DesignTokens.primaryGold, size: 10),
                          const SizedBox(width: 2),
                          CaptionText('$coinsPrice كوينز',
                              fontSize: 8,
                              color: DesignTokens.primaryGold,
                              fontWeight: FontWeight.bold),
                        ],
                      ),
                    ],
                  )
                else if (gemsPrice > 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.diamond_outlined,
                          color: Colors.cyan, size: 10),
                      const SizedBox(width: 2),
                      CaptionText('$gemsPrice جواهر',
                          fontSize: 8,
                          color: Colors.cyan,
                          fontWeight: FontWeight.bold),
                    ],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.stars_rounded,
                          color: DesignTokens.primaryGold, size: 10),
                      const SizedBox(width: 2),
                      CaptionText('$coinsPrice كوينز',
                          fontSize: 8,
                          color: DesignTokens.primaryGold,
                          fontWeight: FontWeight.bold),
                    ],
                  ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: RoyalButton(
                    height: 24,
                    onPressed: isOwned
                        ? null
                        : (inDevelopment
                            ? () => _showUnderDevelopmentDialog(type)
                            : () =>
                                _purchaseStoreItem(id, data, type, userData)),
                    label: isOwned
                        ? 'مملوك'
                        : (inDevelopment ? 'قيد التطوير' : 'اقتناء'),
                    fontSize: 9,
                    gradient: isOwned
                        ? [
                            DesignTokens.neutralGray700,
                            DesignTokens.neutralGray800
                          ]
                        : (inDevelopment
                            ? [
                                DesignTokens.neutralGray700,
                                DesignTokens.neutralGray800
                              ]
                            : [
                                DesignTokens.primaryGold,
                                DesignTokens.primarySapphireLight
                              ]),
                  ),
                ),
              ],
            ),
          );
        });
  }

  void _showUnderDevelopmentDialog(String type) {
    String label;
    if (type == 'frame') {
      label = 'الإطارات';
    } else if (type == 'bubble') {
      label = 'الفقاعات';
    } else if (type == 'cover') {
      label = 'الأغلفة';
    } else {
      label = 'العنصر';
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('قيد التطوير', style: TextStyle(color: Colors.white)),
        content: Text(
            'قريباً سيتم فتحها. نعمل حالياً على تطويرها وتحسينها',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('حسناً', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _purchaseStoreItem(String id, Map<String, dynamic> data, String type,
      UserModel? user) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final scaffold = ScaffoldMessenger.of(context);
    if (currentUser == null || user == null || user.uid.isEmpty) {
      if (mounted) {
        scaffold.showSnackBar(const SnackBar(
            content: Text('يجب تسجيل الدخول أولاً'),
            backgroundColor: Colors.red));
      }
      return;
    }

    int gemsPrice = (data['gemsPrice'] ?? 0).toInt();
    int coinsPrice = (data['coinsPrice'] ?? data['price'] ?? 0).toInt();

    String? selectedCurrency;
    int finalPrice = 0;

    if (gemsPrice > 0 && coinsPrice > 0) {
      final currencySelectionFuture = showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title:
              const Text('اختر العملة', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('$gemsPrice جواهر',
                    style: const TextStyle(color: Colors.cyan)),
                trailing:
                    const Icon(Icons.diamond_outlined, color: Colors.cyan),
                onTap: () => Navigator.pop(ctx, 'gems'),
              ),
              ListTile(
                title: Text('$coinsPrice كوينز',
                    style: const TextStyle(color: Colors.amber)),
                trailing: const Icon(Icons.stars_rounded, color: Colors.amber),
                onTap: () => Navigator.pop(ctx, 'coins'),
              ),
            ],
          ),
        ),
      );
      selectedCurrency = await currencySelectionFuture;

      if (selectedCurrency == 'gems') {
        finalPrice = gemsPrice;
      } else if (selectedCurrency == 'coins') {
        finalPrice = coinsPrice;
      } else {
        return;
      }
    } else if (gemsPrice > 0) {
      selectedCurrency = 'gems';
      finalPrice = gemsPrice;
    } else {
      selectedCurrency = 'coins';
      finalPrice = coinsPrice;
    }

    if (selectedCurrency == 'gems' && user.gems < finalPrice) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('رصيد الجواهر غير كافٍ')));
      }
      return;
    } else if (selectedCurrency == 'coins' && user.coins < finalPrice) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('رصيد الكوينز غير كافٍ')));
      }
      return;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text('اقتناء ${type == 'cover' ? 'غلاف' : 'فقاعة'}',
            style: const TextStyle(color: Colors.white)),
        content: Text(
            'هل تريد الشراء مقابل $finalPrice ${selectedCurrency == 'gems' ? 'جواهر' : 'كوينز'}؟',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final currentUser = FirebaseAuth.instance.currentUser;
                if (currentUser == null) {
                  throw Exception('المستخدم غير مسجل الدخول');
                }

                final userRef = _db.collection('users').doc(currentUser.uid);
                final userDoc = await userRef.get();
                if (!userDoc.exists) {
                  throw Exception('المستخدم غير موجود');
                }
                final userData = userDoc.data() as Map<String, dynamic>;
                final currentGems = (userData['gems'] ?? 0).toInt();
                final currentStars = (userData['stars'] ?? 0).toInt();

                if (selectedCurrency == 'gems') {
                  if (currentGems < finalPrice) {
                    throw Exception('رصيد الجواهر غير كافٍ');
                  }
                  await userRef.update({'gems': currentGems - finalPrice});
                } else {
                  if (currentStars < finalPrice) {
                    throw Exception('رصيد الكوينز غير كافٍ');
                  }
                  final newCoins = currentStars - finalPrice;
                  await userRef.update({'stars': newCoins});
                  await userRef.update({'coins': newCoins});
                }
                await userRef.collection('inventory').add({
                  'type': type,
                  'name': data['name'],
                  'imageUrl': data['url'],
                  'url': data['url'],
                  'boughtAt': FieldValue.serverTimestamp(),
                });
                if (mounted) {
                  scaffold.showSnackBar(const SnackBar(
                      content: Text('تمت الإضافة لمقتنياتك بنجاح ✨'),
                      backgroundColor: DesignTokens.primaryGold));
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('حدث خطأ: $e'),
                      backgroundColor: Colors.red));
                }
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37)),
            child: const Text('شراء', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
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
          final screenWidth = MediaQuery.of(context).size.width;
          final crossAxisCount = screenWidth > 600 ? 4 : 2;
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8),
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
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isOwned
                    ? DesignTokens.primarySapphireLight.withValues(alpha: 0.3)
                    : DesignTokens.neutralWhite.withValues(alpha: 0.05),
              ),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black38, blurRadius: 6, offset: Offset(0, 2))
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
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedVehiclePreview(
                        type: type,
                        url: url,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                BodyText(data['name'] ?? 'مركبة ملكية',
                    fontSize: 10,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    fontWeight: DesignTokens.fontWeightBold),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.stars_rounded,
                        color: DesignTokens.primaryGold, size: 10),
                    const SizedBox(width: 2),
                    CaptionText('$price',
                        fontSize: 8,
                        color: DesignTokens.primaryGold,
                        fontWeight: FontWeight.bold),
                  ],
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: double.infinity,
                  child: RoyalButton(
                    height: 24,
                    onPressed: isOwned
                        ? null
                        : () => _purchaseVehicle(id, data, userData),
                    label: isOwned ? 'مملوكة' : 'اقتناء',
                    fontSize: 9,
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
    if (user.coins < price) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('رصيد الكوينز غير كافٍ')));
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => RoyalConfirmDialog(
        title: 'اقتناء مركبة',
        message: 'هل تريد شراء مركبة (${data['name']}) مقابل $price كوينز؟',
        confirmLabel: 'شراء',
        icon: Icons.directions_car,
        onConfirm: () async {
          Navigator.pop(ctx);
          try {
            await _db.runTransaction((tx) async {
              final userRef = _db.collection('users').doc(user.uid);
              tx.update(userRef, {'coins': user.coins - price});
              final inventoryRef = userRef.collection('inventory').doc();
              tx.set(inventoryRef, {
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
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('حدث خطأ: $e'), backgroundColor: Colors.red));
            }
          }
        },
      ),
    );
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
          final screenWidth = MediaQuery.of(context).size.width;
          final crossAxisCount = screenWidth > 600 ? 4 : 2;
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final docSnap =
                  docs[index] as DocumentSnapshot<Map<String, dynamic>>;
              final dataMap = docSnap.data() ?? <String, dynamic>{};
              final frame = FrameModel.fromFirestore(docSnap);
              // جعل جميع الإطارات قيد التطوير مؤقتاً
              final bool inDevelopment = true;
              return _buildFrameStoreCard(frame, userData, inDevelopment);
            },
          );
        });
  }

  Widget _buildFrameStoreCard(
      FrameModel frame, UserModel? userData, bool inDevelopment) {
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
            padding: const EdgeInsets.all(6),
            margin: EdgeInsets.zero,
            backgroundColor:
                DesignTokens.backgroundDarkMedium.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                    child: RoyalFrameWidget(
                        frameUrl: frame.imageUrl,
                        size: 60,
                        child: CircleAvatar(
                            radius: 20,
                            backgroundColor: DesignTokens.neutralWhite
                                .withValues(alpha: 0.05),
                            child: const Icon(Icons.person,
                                color: DesignTokens.neutralGray700,
                                size: 20)))),
                const SizedBox(height: 4),
                BodyText(frame.name,
                    textAlign: TextAlign.center,
                    fontSize: 10,
                    fontWeight: DesignTokens.fontWeightBold),
                CaptionText('${frame.price} كوينز',
                    fontSize: 8, color: DesignTokens.primaryGold),
                const SizedBox(height: 6),
                RoyalButton(
                  height: 24,
                  onPressed: isOwned
                      ? null
                      : (inDevelopment
                          ? () => _showUnderDevelopmentDialog('frame')
                          : () => _purchaseFrameDirect(frame, userData)),
                  label: isOwned
                      ? 'تملكه ✅'
                      : (inDevelopment ? 'قيد التطوير' : 'اقتناء'),
                  fontSize: 9,
                  gradient: isOwned
                      ? [
                          DesignTokens.semanticDisabled,
                          DesignTokens.semanticDisabled.withValues(alpha: 0.6)
                        ]
                      : (inDevelopment
                          ? [
                              DesignTokens.neutralGray700,
                              DesignTokens.neutralGray800
                            ]
                          : null),
                ),
              ],
            ),
          );
        });
  }

  void _purchaseFrameDirect(FrameModel frame, UserModel? user) async {
    if (user == null) return;
    if (user.coins < frame.price) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('رصيد الكوينز غير كافٍ')));
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => RoyalConfirmDialog(
        title: 'اقتناء إطار ملكي',
        message:
            'هل تريد شراء إطار (${frame.name}) مقابل ${frame.price} كوينز؟',
        confirmLabel: 'شراء',
        icon: Icons.portrait,
        onConfirm: () async {
          Navigator.pop(ctx);
          try {
            await _db.runTransaction((tx) async {
              final userRef = _db.collection('users').doc(user.uid);
              tx.update(userRef, {'coins': user.coins - frame.price});
              final inventoryRef = userRef.collection('inventory').doc();
              tx.set(inventoryRef, {
                'type': 'frame',
                'name': frame.name,
                'imageUrl': frame.imageUrl,
                'boughtAt': FieldValue.serverTimestamp()
              });
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('تم شراء الإطار بنجاح ✨'),
                  backgroundColor: Colors.green));
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('حدث خطأ: $e'), backgroundColor: Colors.red));
            }
          }
        },
      ),
    );
  }

  Widget _buildDynamicRoomThemesGrid(UserModel? userData) {
    return StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('room_themes')
            .where('isActive', isEqualTo: true)
            .orderBy('createdAt', descending: true)
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
            return _buildEmptyState('لا توجد موضوعات غرف متاحة حالياً');
          }
          final screenWidth = MediaQuery.of(context).size.width;
          final crossAxisCount = screenWidth > 600 ? 4 : 2;
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.8,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return _buildRoomThemeCard(docs[index].id, data, userData);
            },
          );
        });
  }

  Widget _buildRoomThemeCard(
      String id, Map<String, dynamic> data, UserModel? userData) {
    final String imageUrl = data['imageUrl'] ?? data['url'] ?? '';
    final String name = data['name'] ?? 'ثيم ملكي';
    final double price = (data['price'] ?? 0).toDouble();
    final String currencyType = data['currencyType'] ?? 'coins';

    return StreamBuilder<DocumentSnapshot>(
        stream: userData != null
            ? _db
                .collection('users')
                .doc(userData.uid)
                .collection('owned_themes')
                .doc(id)
                .snapshots()
            : null,
        builder: (context, snapshot) {
          bool isOwned = snapshot.hasData && snapshot.data!.exists;

          return StreamBuilder<QuerySnapshot>(
              stream: (!isOwned && userData != null && imageUrl.isNotEmpty)
                  ? _db
                      .collection('users')
                      .doc(userData.uid)
                      .collection('owned_themes')
                      .where('imageUrl', isEqualTo: imageUrl)
                      .snapshots()
                  : null,
              builder: (context, urlSnap) {
                if (urlSnap.hasData && urlSnap.data!.docs.isNotEmpty) {
                  isOwned = true;
                }

                return GestureDetector(
                  onTap: () => _showThemePreview(imageUrl, name, price.toInt(),
                      currencyType, isOwned, id, data, userData),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isOwned
                            ? Colors.green.withValues(alpha: 0.3)
                            : DesignTokens.neutralWhite.withValues(alpha: 0.05),
                      ),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black26,
                            blurRadius: 6,
                            offset: Offset(0, 2))
                      ],
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 1.5)),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.broken_image,
                                        color: DesignTokens.neutralGray700),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        BodyText(name,
                            fontSize: 10,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            fontWeight: DesignTokens.fontWeightBold),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              currencyType == 'gems'
                                  ? Icons.diamond
                                  : Icons.monetization_on,
                              color: currencyType == 'gems'
                                  ? Colors.cyan
                                  : DesignTokens.primaryGold,
                              size: 10,
                            ),
                            const SizedBox(width: 2),
                            CaptionText(
                                '$price ${currencyType == 'gems' ? 'جواهر' : 'كوينز'}',
                                fontSize: 8,
                                color: currencyType == 'gems'
                                    ? Colors.cyan
                                    : DesignTokens.primaryGold,
                                fontWeight: FontWeight.bold),
                          ],
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          child: RoyalButton(
                            height: 24,
                            onPressed: isOwned
                                ? null
                                : () => _purchaseRoomTheme(id, data, userData),
                            label: isOwned ? 'مملوك ✅' : 'اقتناء',
                            fontSize: 9,
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
                  ),
                );
              });
        });
  }

  void _showThemePreview(
      String imageUrl,
      String name,
      int price,
      String currency,
      bool isOwned,
      String id,
      Map<String, dynamic> data,
      UserModel? userData) {
    showDialog(
      context: context,
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Container(
                color: Colors.black.withValues(alpha: 0.95),
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: imageUrl,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(ctx).padding.top + 20,
            left: 20,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 40,
            right: 40,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none)),
                const SizedBox(height: 20),
                if (!isOwned)
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      icon: Icon(
                          currency == 'gems' ? Icons.diamond : Icons.stars,
                          color: Colors.black),
                      label: Text(
                          'اقتناء مقابل $price ${currency == 'gems' ? 'جوهرة' : 'كوينز'}',
                          style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignTokens.primaryGold,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _purchaseRoomTheme(id, data, userData);
                      },
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                    decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(30)),
                    child: const Text('أنت تملك هذا الموضوع بالفعل ✅',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _purchaseRoomTheme(
      String id, Map<String, dynamic> data, UserModel? user) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final scaffold = ScaffoldMessenger.of(context);
    if (currentUser == null || user == null || user.uid.isEmpty) {
      if (mounted) {
        scaffold.showSnackBar(const SnackBar(
            content: Text('يجب تسجيل الدخول أولاً'),
            backgroundColor: Colors.red));
      }
      return;
    }

    final String currencyType = data['currencyType'] ?? 'coins';
    double price = (data['price'] ?? 0).toDouble();

    if (currencyType == 'gems' && user.gems < price) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('رصيد الجواهر غير كافٍ')));
      }
      return;
    } else if (currencyType == 'coins' && user.coins < price) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('رصيد الكوينز غير كافٍ')));
      }
      return;
    }

    if (!mounted) return;

    final confirmFuture = showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('اقتناء موضوع غرفة',
            style: TextStyle(color: Colors.white)),
        content: Text(
            'هل تريد الشراء مقابل $price ${currencyType == 'gems' ? 'جواهر' : 'كوينز'}؟',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD4AF37)),
            child: const Text('شراء', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
    final confirm = await confirmFuture;

    if (!mounted) return;

    if (confirm == true) {
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          throw Exception('المستخدم غير مسجل الدخول');
        }

        final userRef = _db.collection('users').doc(currentUser.uid);
        final userDoc = await userRef.get();
        if (!userDoc.exists) {
          throw Exception('المستخدم غير موجود');
        }
        final userData = userDoc.data() as Map<String, dynamic>;
        final currentGems = (userData['gems'] ?? 0).toDouble();
        final currentCoins = (userData['coins'] ?? 0).toDouble();

        if (currencyType == 'gems') {
          if (currentGems < price) {
            throw Exception('رصيد الجواهر غير كافٍ');
          }
          await userRef.update({'gems': currentGems - price});
        } else {
          if (currentCoins < price) {
            throw Exception('رصيد الكوينز غير كافٍ');
          }
          await userRef.update({'coins': currentCoins - price});
        }

        await userRef.collection('owned_themes').doc(id).set({
          ...data,
          'imageUrl': data['imageUrl'] ?? data['url'],
          'boughtAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          scaffold.showSnackBar(const SnackBar(
              content: Text('تمت الإضافة لمقتنياتك بنجاح ✨'),
              backgroundColor: DesignTokens.primaryGold));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('حدث خطأ: $e'), backgroundColor: Colors.red));
        }
      }
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
          final screenWidth = MediaQuery.of(context).size.width;
          final crossAxisCount = screenWidth > 600 ? 6 : 3;
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.65,
                crossAxisSpacing: 6,
                mainAxisSpacing: 6),
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
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(10),
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
                              width: 28,
                              height: 28,
                              placeholder: (context, url) =>
                                  const CircularProgressIndicator(
                                      strokeWidth: 1.5),
                              errorWidget: (context, url, error) => const Icon(
                                  Icons.error,
                                  color: Colors.red,
                                  size: 20),
                            )
                          : const Icon(Icons.broken_image,
                              color: Colors.white24, size: 20))
                      : Text(iconData,
                          style: const TextStyle(fontSize: 20),
                          overflow: TextOverflow.ellipsis),
                ),
              ),
              const SizedBox(height: 3),
              Text(data['name'] ?? 'وسام',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold)),
              Text('$price كوينز',
                  style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 7,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ElevatedButton(
                onPressed:
                    isOwned ? null : () => _purchaseBadge(data, userData),
                style: ElevatedButton.styleFrom(
                    backgroundColor: isOwned
                        ? Colors.grey.withValues(alpha: 0.1)
                        : Colors.amber.withValues(alpha: 0.1),
                    minimumSize: const Size(double.infinity, 20),
                    padding: EdgeInsets.zero),
                child: Text(isOwned ? 'تملكه ✅' : 'اقتناء',
                    style: TextStyle(
                        fontSize: 7,
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
    if (user.coins < price) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('رصيد الكوينز غير كافٍ')));
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('اقتناء وسام', style: TextStyle(color: Colors.white)),
        content:
            Text('هل تريد شراء شارة (${data['name']}) مقابل $price كوينز؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await _db.runTransaction((tx) async {
                    final userRef = _db.collection('users').doc(user.uid);
                    tx.update(userRef, {'coins': user.coins - price});
                    final inventoryRef = userRef.collection('inventory').doc();
                    tx.set(inventoryRef, {
                      'type': 'badge',
                      'name': data['name'],
                      'icon': data['icon'],
                      'isImage': data['isImage'] ?? false,
                      'boughtAt': FieldValue.serverTimestamp()
                    });
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('تم شراء الشارة بنجاح ✨'),
                        backgroundColor: Colors.green));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('حدث خطأ: $e'),
                        backgroundColor: Colors.red));
                  }
                }
              },
              child: const Text('شراء', style: TextStyle(color: Colors.amber))),
        ],
      ),
    );
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
          final screenWidth = MediaQuery.of(context).size.width;
          final crossAxisCount = screenWidth > 600 ? 4 : 2;
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.75,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8),
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
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.2)),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
      ),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(4),
              child: url.isNotEmpty
                  ? (isLottie
                      ? Lottie.network(url, fit: BoxFit.contain, animate: false)
                      : (Uri.tryParse(url)?.host.isNotEmpty == true
                          ? CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.contain,
                              placeholder: (c, u) => const Center(
                                  child: CircularProgressIndicator(
                                      strokeWidth: 1.5, color: Colors.amber)),
                              errorWidget: (context, url, error) => const Icon(
                                  Icons.broken_image,
                                  color: Colors.white24,
                                  size: 24),
                            )
                          : const Icon(Icons.broken_image,
                              color: Colors.white24, size: 24)))
                  : const Icon(Icons.rocket_launch_rounded,
                      color: Colors.purpleAccent, size: 30),
            ),
          ),
          const SizedBox(height: 4),
          BodyText(data['name'] ?? 'تأثير دخول',
              fontSize: 10,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              fontWeight: DesignTokens.fontWeightBold),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.stars_rounded, color: Colors.amber, size: 10),
              const SizedBox(width: 2),
              CaptionText('$price',
                  fontSize: 8,
                  color: Colors.amber,
                  fontWeight: FontWeight.bold),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: RoyalButton(
              height: 24,
              onPressed: () => _purchaseEntryEffect(docId, data, userData),
              label: 'اقتناء',
              fontSize: 9,
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
    if (user.coins < price) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('الرصيد غير كافٍ')));
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('اقتناء مؤثر دخول',
            style: TextStyle(color: Colors.white)),
        content:
            Text('هل تريد شراء مؤثر (${data['name']}) مقابل $price كوينز؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await _db.runTransaction((tx) async {
                    final userRef = _db.collection('users').doc(user.uid);
                    tx.update(userRef, {'coins': user.coins - price});
                    final inventoryRef = userRef.collection('inventory').doc();
                    tx.set(inventoryRef, {
                      'type': 'entry_effect',
                      'name': data['name'],
                      'imageUrl': data['lottieUrl'],
                      'boughtAt': FieldValue.serverTimestamp()
                    });
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('تم شراء المؤثر بنجاح ✨'),
                        backgroundColor: Colors.green));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('حدث خطأ: $e'),
                        backgroundColor: Colors.red));
                  }
                }
              },
              child: const Text('شراء', style: TextStyle(color: Colors.amber))),
        ],
      ),
    );
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
          final screenWidth = MediaQuery.of(context).size.width;
          final crossAxisCount = screenWidth > 600 ? 4 : 2;
          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.75,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8),
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
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: badgeColor.withValues(alpha: 0.3))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified, color: badgeColor, size: 30),
          const SizedBox(height: 4),
          Text(data['name'] ?? 'توثيق',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
          Text('${data['price']} كوينز',
              style: TextStyle(
                  color: badgeColor, fontSize: 8, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          ElevatedButton(
              onPressed: isOwned
                  ? null
                  : () => _purchaseVerification(docId, data, userData),
              style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isOwned ? Colors.grey : badgeColor.withValues(alpha: 0.2),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 24),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
              child: Text(isOwned ? 'مفعل ✅' : 'شراء',
                  style: const TextStyle(
                      fontSize: 9, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _purchaseVerification(
      String docId, Map<String, dynamic> data, UserModel? user) async {
    if (user == null) return;
    int price = (data['price'] ?? 0).toInt();
    if (user.coins < price) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('رصيد الكوينز غير كافٍ')));
      return;
    }
    await _db.runTransaction((tx) async {
      tx.update(_db.collection('users').doc(user.uid),
          {'coins': user.coins - price, 'verificationColor': data['color']});
    });
  }

  Widget _buildDynamicSpecialIdGrid(UserModel? userData) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0E5E4E),
      ),
      child: SingleChildScrollView(
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: ShelvesPainter(),
              ),
            ),
            Column(
              children: [
                _buildUserAccountCard(userData),
                _buildPremiumTabs(),
                StreamBuilder<QuerySnapshot>(
                    stream: _db
                        .collection('special_ids')
                        .where('showInStore', isEqualTo: true)
                        .where('isSold', isEqualTo: false)
                        .where('category',
                            isEqualTo:
                                _idCategories[_idCategoryTabController.index])
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: Padding(
                          padding: EdgeInsets.all(40.0),
                          child: CircularProgressIndicator(
                              color: Color(0xFF00E5FF)),
                        ));
                      }
                      if (snapshot.hasError) {
                        return _buildErrorState();
                      }
                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return _buildEmptyState(
                            'لا توجد أرقام مميزة في هذه الفئة حالياً');
                      }
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 20),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 1.6,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 35),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data =
                              docs[index].data() as Map<String, dynamic>;
                          return _buildPremiumIdCard(
                              docs[index].id, data, userData, index);
                        },
                      );
                    }),
                const SizedBox(height: 100),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAccountCard(UserModel? userData) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignTokens.primaryEmerald.withValues(alpha: 0.3),
            DesignTokens.primaryEmeraldDark.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: DesignTokens.primaryEmerald.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.primaryEmerald.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: DesignTokens.primaryGold, width: 3),
              boxShadow: [
                BoxShadow(
                  color: DesignTokens.primaryGold.withValues(alpha: 0.4),
                  blurRadius: 15,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ClipOval(
              child: userData?.profilePic != null &&
                      userData!.profilePic.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: userData.profilePic,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: DesignTokens.primaryGold,
                        ),
                      ),
                      errorWidget: (context, url, error) => const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 30),
                    )
                  : const Icon(Icons.person, color: Colors.white, size: 30),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('معرفك الحالي',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontFamily: DesignTokens.primaryFont)),
                const SizedBox(height: 4),
                Text(
                  userData?.royalId ?? '---',
                  style: const TextStyle(
                    color: DesignTokens.primaryGold,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: DesignTokens.primaryFont,
                    shadows: [
                      Shadow(color: DesignTokens.primaryGold, blurRadius: 10)
                    ],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              if (userData?.royalId != null) {
                Clipboard.setData(ClipboardData(text: userData!.royalId));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم نسخ المعرف بنجاح ✨'),
                    backgroundColor: DesignTokens.primaryEmerald,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [
                  DesignTokens.primaryGold,
                  DesignTokens.primaryGoldLight
                ]),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: DesignTokens.primaryGold.withValues(alpha: 0.4),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.copy, color: Colors.black, size: 18),
                  SizedBox(width: 6),
                  Text('نسخ',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: DesignTokens.primaryFont,
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TabBar(
        controller: _idCategoryTabController,
        isScrollable: true,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF00E5FF), Color(0xFF00B8D4)]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
              blurRadius: 15,
              spreadRadius: 0,
            ),
          ],
        ),
        labelColor: Colors.black,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
        labelStyle: const TextStyle(
          fontFamily: DesignTokens.primaryFont,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: DesignTokens.primaryFont,
          fontWeight: FontWeight.normal,
          fontSize: 14,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        labelPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        tabs: _idCategories.map((cat) => Tab(text: cat)).toList(),
      ),
    );
  }

  Widget _buildPremiumIdCard(
      String docId, Map<String, dynamic> data, UserModel? userData, int index) {
    final royalId = data['royalId'] ?? data['value'] ?? '---';
    final category = data['category'] ?? 'شائع';
    final price = data['price'] ?? 0;
    final currency = data['currencyType'] ?? 'stars';

    final rarityColors = _getRarityColors(category);

    return GestureDetector(
      onTap: () => _showPremiumPurchaseDialog(docId, data, userData),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: rarityColors['border'] as Color,
            width: (category == 'ملكي' || category == 'ملحمي') ? 2 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: rarityColors['gradient'] as List<Color>,
                ),
              ),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0.2,
                child: CustomPaint(
                  painter: RadialBurstPainter(),
                ),
              ),
            ),
            Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            royalId,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              fontFamily: DesignTokens.primaryFont,
                              shadows: [
                                Shadow(
                                  color: Colors.black38,
                                  offset: Offset(0, 2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildIDCircleIcon(rarityColors['iconColor'] as Color),
                      ],
                    ),
                  ),
                ),
                Container(
                  height: 24,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$price',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        currency == 'gems'
                            ? Icons.diamond
                            : Icons.stars_rounded,
                        color: currency == 'gems'
                            ? const Color(0xFF00E5FF)
                            : DesignTokens.primaryGold,
                        size: 12,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIDCircleIcon(Color color) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.3),
            color.withValues(alpha: 0.7),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'ID',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 11,
            shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getRarityColors(String category) {
    switch (category) {
      case 'مقترح':
        return {
          'gradient': [const Color(0xFF00E5FF), const Color(0xFF00B8D4)],
          'border': Colors.white.withValues(alpha: 0.4),
          'iconColor': const Color(0xFF00B8D4),
          'glow': const Color(0xFF00E5FF),
        };
      case 'الأفضل':
        return {
          'gradient': [const Color(0xFFFFA726), const Color(0xFFF57C00)],
          'border': Colors.white.withValues(alpha: 0.4),
          'iconColor': const Color(0xFFF57C00),
          'glow': const Color(0xFFFB8C00),
        };
      case 'شائع':
        return {
          'gradient': [const Color(0xFF6EC6FF), const Color(0xFF2196F3)],
          'border': Colors.white.withValues(alpha: 0.3),
          'iconColor': const Color(0xFF2196F3),
          'glow': const Color(0xFF2196F3),
        };
      case 'نادر':
        return {
          'gradient': [const Color(0xFFB67DFF), const Color(0xFF8B44FF)],
          'border': Colors.white.withValues(alpha: 0.3),
          'iconColor': const Color(0xFF8B44FF),
          'glow': const Color(0xFF9C27B0),
        };
      case 'ملحمي':
        return {
          'gradient': [const Color(0xFFFF8EC7), const Color(0xFFFF4081)],
          'border': const Color(0xFFFFD700).withValues(alpha: 0.8),
          'iconColor': const Color(0xFFFF4081),
          'glow': const Color(0xFFE91E63),
        };
      case 'أسطوري':
        return {
          'gradient': [const Color(0xFFFFD700), const Color(0xFFFFA000)],
          'border': Colors.white.withValues(alpha: 0.5),
          'iconColor': const Color(0xFFFFA000),
          'glow': const Color(0xFFFFD700),
        };
      case 'ملكي':
        return {
          'gradient': [const Color(0xFFF44336), const Color(0xFFD32F2F)],
          'border': const Color(0xFFFFD700),
          'iconColor': const Color(0xFFD32F2F),
          'glow': const Color(0xFFFFD700),
        };
      default:
        return {
          'gradient': [const Color(0xFF6EC6FF), const Color(0xFF2196F3)],
          'border': Colors.white.withValues(alpha: 0.3),
          'iconColor': const Color(0xFF2196F3),
          'glow': Colors.blue,
        };
    }
  }

  void _showPremiumPurchaseDialog(
      String docId, Map<String, dynamic> data, UserModel? userData) {
    final royalId = data['royalId'] ?? data['value'] ?? '---';
    final price = data['price'] ?? 0;
    final currency = data['currencyType'] ?? 'stars';
    final category = data['category'] ?? 'شائع';

    final currencyIcon =
        currency == 'gems' ? Icons.diamond : Icons.stars_rounded;
    final currencyName = currency == 'gems' ? 'جوهرة' : 'كوينز';
    final userBalance =
        currency == 'gems' ? (userData?.gems ?? 0) : (userData?.coins ?? 0);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A2F2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
              color: DesignTokens.primaryGold.withValues(alpha: 0.3), width: 2),
        ),
        title: const Row(
          children: [
            Icon(Icons.shopping_bag, color: DesignTokens.primaryGold, size: 28),
            SizedBox(width: 12),
            Text('تأكيد الشراء',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: DesignTokens.primaryFont)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors:
                        _getRarityColors(category)['gradient'] as List<Color>),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(royalId,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        fontFamily: DesignTokens.primaryFont,
                        shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                      )),
                  const SizedBox(height: 8),
                  Text(category,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontFamily: DesignTokens.primaryFont)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(currencyIcon, color: DesignTokens.primaryGold, size: 24),
                const SizedBox(width: 8),
                Text('$price $currencyName',
                    style: const TextStyle(
                      color: DesignTokens.primaryGold,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: DesignTokens.primaryFont,
                    )),
              ],
            ),
            const SizedBox(height: 12),
            Text('رصيدك الحالي: $userBalance $currencyName',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontFamily: DesignTokens.primaryFont)),
            if (userBalance < price)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('⚠️ رصيدك غير كافٍ',
                    style: TextStyle(
                      color: Colors.red.withValues(alpha: 0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFamily: DesignTokens.primaryFont,
                    )),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء',
                style: TextStyle(
                    color: Colors.white70,
                    fontFamily: DesignTokens.primaryFont)),
          ),
          ElevatedButton(
            onPressed: userBalance >= price
                ? () {
                    Navigator.pop(ctx);
                    _handlePurchaseId(docId, price, currency, userData);
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: DesignTokens.primaryGold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('شراء الآن',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: DesignTokens.primaryFont)),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A2F2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
              color: DesignTokens.primaryGold.withValues(alpha: 0.3), width: 2),
        ),
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: DesignTokens.primaryGold, size: 28),
            SizedBox(width: 12),
            Text('مساعدة',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: DesignTokens.primaryFont)),
          ],
        ),
        content: const Text(
          'اختر المعرف المميز الذي يناسبك من المتجر. يمكنك البحث عن معرف معين أو تصفح حسب الفئة. بعد الشراء، سيتم تحديث معرفك تلقائياً.',
          style: TextStyle(
              color: Colors.white70, fontFamily: DesignTokens.primaryFont),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('حسناً',
                style: TextStyle(
                    color: DesignTokens.primaryGold,
                    fontFamily: DesignTokens.primaryFont)),
          ),
        ],
      ),
    );
  }

  void _showRankingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0A2F2A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
              color: DesignTokens.primaryGold.withValues(alpha: 0.3), width: 2),
        ),
        title: const Row(
          children: [
            Icon(Icons.emoji_events, color: DesignTokens.primaryGold, size: 28),
            SizedBox(width: 12),
            Text('الترتيب',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontFamily: DesignTokens.primaryFont)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('special_ids')
                .where('isSold', isEqualTo: true)
                .orderBy('soldAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                      color: DesignTokens.primaryGold),
                );
              }
              if (snapshot.hasError) {
                return const Center(
                  child: Text('حدث خطأ في تحميل البيانات',
                      style: TextStyle(color: Colors.white70)),
                );
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(
                  child: Text('لا يوجد مستخدمين حصلوا على أرقام مميزة بعد',
                      style: TextStyle(color: Colors.white70)),
                );
              }
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final royalId = data['royalId'] ?? data['value'] ?? '---';
                  final soldTo = data['soldTo'] ?? data['userId'] ?? '';
                  final soldAt = data['soldAt'];
                  final category = data['category'] ?? 'عام';

                  return FutureBuilder<DocumentSnapshot>(
                    future: _db.collection('users').doc(soldTo).get(),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData) {
                        return const SizedBox();
                      }
                      final userData = userSnapshot.data;
                      if (userData == null || !userData.exists) {
                        return const SizedBox();
                      }
                      final userName = userData['name'] ?? 'مستخدم';
                      final userProfilePic = userData['profilePic'] ?? '';

                      return Card(
                        color: Colors.white.withValues(alpha: 0.05),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: userProfilePic.isNotEmpty
                                ? NetworkImage(userProfilePic)
                                : null,
                            child: userProfilePic.isEmpty
                                ? const Icon(Icons.person,
                                    color: Colors.white38)
                                : null,
                          ),
                          title: Text(
                            userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'الرقم: $royalId',
                                style: const TextStyle(
                                  color: DesignTokens.primaryGold,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                'الفئة: $category',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          trailing: Text(
                            '#${index + 1}',
                            style: TextStyle(
                              color: index < 3
                                  ? DesignTokens.primaryGold
                                  : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق',
                style: TextStyle(
                    color: DesignTokens.primaryGold,
                    fontFamily: DesignTokens.primaryFont)),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePurchaseId(
      String docId, int price, String currency, UserModel? user) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final scaffold = ScaffoldMessenger.of(context);
    final db = FirebaseFirestore.instance;

    if (user == null || currentUser == null) {
      if (mounted) {
        scaffold.showSnackBar(const SnackBar(
            content: Text('يجب تسجيل الدخول أولاً لإتمام عملية الشراء')));
      }
      return;
    }

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: DesignTokens.primaryGold),
        ),
      );
    }

    try {
      final specialDocRef = db.collection('special_ids').doc(docId);
      final userRef = db.collection('users').doc(currentUser.uid);

      await db.runTransaction((transaction) async {
        final specialDoc = await transaction.get(specialDocRef);
        if (!specialDoc.exists) {
          throw Exception('المعرف المميز غير موجود');
        }

        final specialData = specialDoc.data() as Map<String, dynamic>;
        final isSold = specialData['isSold'] == true;
        final royalIdValue =
            (specialData['royalId'] ?? specialData['value'] ?? '').toString();

        if (isSold) {
          throw Exception('هذا المعرف المميز تم بيعه سابقاً');
        }

        if (royalIdValue.trim().isEmpty) {
          throw Exception('قيمة المعرف المميز غير صالحة');
        }

        final idQuery = await db
            .collection('users')
            .where('royalId', isEqualTo: royalIdValue)
            .limit(1)
            .get();

        if (idQuery.docs.isNotEmpty) {
          throw Exception('هذا المعرف مستخدم بالفعل');
        }

        final userDoc = await transaction.get(userRef);
        if (!userDoc.exists) {
          throw Exception('المستخدم غير موجود');
        }

        final userData = userDoc.data() as Map<String, dynamic>;
        final currentBalance = (userData[currency] ?? 0) as int;

        if (currentBalance < price) {
          throw Exception('الرصيد غير كافٍ');
        }

        // إعادة الرقم القديم إلى المتجر إذا كان موجوداً
        final oldRoyalId = userData['royalId'] as String?;
        final oldRoyalIdSource = userData['royalIdAssignmentSource'] as String?;
        
        if (oldRoyalId != null && oldRoyalIdSource != null && oldRoyalIdSource.startsWith('special_ids/')) {
          final oldDocId = oldRoyalIdSource.split('/')[1];
          final oldSpecialDocRef = db.collection('special_ids').doc(oldDocId);
          final oldSpecialDoc = await transaction.get(oldSpecialDocRef);
          
          if (oldSpecialDoc.exists) {
            transaction.update(oldSpecialDocRef, {
              'isSold': false,
              'ownerUid': null,
              'soldTo': null,
              'returnedAt': FieldValue.serverTimestamp(),
            });
          }
        }

        transaction.update(userRef, {
          'royalId': royalIdValue,
          'shortId': royalIdValue,
          'hasCustomId': true,
          'royalIdAssignedAt': FieldValue.serverTimestamp(),
          'royalIdAssignmentType': 'purchase',
          'royalIdAssignmentSource': 'special_ids/$docId',
          currency: currentBalance - price,
        });

        transaction.update(specialDocRef, {
          'isSold': true,
          'ownerUid': currentUser.uid,
          'soldTo': currentUser.uid,
          'soldAt': FieldValue.serverTimestamp(),
        });

        final historyRef = userRef.collection('royalIdHistory').doc();
        transaction.set(historyRef, {
          'oldRoyalId': oldRoyalId,
          'newRoyalId': royalIdValue,
          'changedBy': currentUser.uid,
          'changeType': 'purchase',
          'reason': 'شراء معرف من المتجر',
          'timestamp': FieldValue.serverTimestamp(),
        });
      });

      if (mounted) Navigator.of(context, rootNavigator: true).pop();

      if (mounted) {
        scaffold.showSnackBar(const SnackBar(
            content: Text('تم شراء المعرف بنجاح ✅'),
            backgroundColor: Colors.green));
      }
      return;
    } catch (e) {
      if (mounted) {
        if (Navigator.canPop(context)) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        scaffold.showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
  }

  Widget _buildRoyalSliverAppBar(UserModel? user) {
    return SliverAppBar(
      expandedHeight: 180.0,
      pinned: true,
      backgroundColor: DesignTokens.backgroundDarkMedium,
      actions: [
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 12),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => _showHelpDialog(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: const Icon(Icons.help_outline,
                      color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _showRankingsDialog(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: DesignTokens.primaryGold.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: const Icon(Icons.emoji_events,
                      color: DesignTokens.primaryGold, size: 20),
                ),
              ),
            ],
          ),
        ),
      ],
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
                  child: _buildGlassBalance(user?.coins.toString() ?? '0',
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

  String _formatNumber(dynamic n) {
    if (n == null) return "0";
    final num number = n is num ? n : (num.tryParse(n.toString()) ?? 0);
    if (number >= 1000000) return "${(number / 1000000).toStringAsFixed(1)}M";
    if (number >= 1000) return "${(number / 1000).toStringAsFixed(1)}K";
    return number.toString();
  }

  Widget _buildRoomPinningSection(UserModel? userData) {
    if (userData == null) return const SizedBox.shrink();

    final List<Map<String, dynamic>> pinPackages = [
      {
        'id': 'pin_1d',
        'title': 'تثبيت يوم واحد',
        'duration': 1,
        'price': 10000,
        'gradient': [const Color(0xFF642B73), const Color(0xFFC6426E)]
      },
      {
        'id': 'pin_3d',
        'title': 'تثبيت 3 أيام',
        'duration': 3,
        'price': 15000,
        'gradient': [const Color(0xFF000428), const Color(0xFF004e92)]
      },
      {
        'id': 'pin_7d',
        'title': 'تثبيت أسبوع',
        'duration': 7,
        'price': 250000,
        'gradient': [const Color(0xFF134E5E), const Color(0xFF71B280)]
      },
      {
        'id': 'pin_1m',
        'title': 'تثبيت شهر',
        'duration': 30,
        'price': 500000,
        'gradient': [const Color(0xFFFF512F), const Color(0xFFDD2476)]
      },
      {
        'id': 'pin_3m',
        'title': 'تثبيت 3 أشهر',
        'duration': 90,
        'price': 1000000,
        'gradient': [const Color(0xFF4776E6), const Color(0xFF8E54E9)]
      },
      {
        'id': 'pin_6m',
        'title': 'تثبيت 6 أشهر',
        'duration': 180,
        'price': 2000000,
        'gradient': [const Color(0xFFF09819), const Color(0xFFEDDE5D)]
      },
      {
        'id': 'pin_9m',
        'title': 'تثبيت 9 أشهر',
        'duration': 270,
        'price': 2500000,
        'gradient': [const Color(0xFF1D976C), const Color(0xFF93F9B9)]
      },
      {
        'id': 'pin_1y',
        'title': 'تثبيت سنة كاملة',
        'duration': 365,
        'price': 3000000,
        'gradient': [
          const Color(0xFF833ab4),
          const Color(0xFFfd1d1d),
          const Color(0xFFfcb045)
        ]
      },
    ];

    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('rooms')
          .where('ownerId', isEqualTo: userData.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final rooms = snapshot.data?.docs ?? [];
        return ListView(
          padding: const EdgeInsets.all(DesignTokens.spacingMd),
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 15),
              child: Column(
                children: [
                  Icon(Icons.push_pin_rounded,
                      color: DesignTokens.primaryGold, size: 40),
                  SizedBox(height: 10),
                  Text('خدمة التثبيت الملكي 👑',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  Text(
                      'ثبّت غرفتك في مقدمة "الغرف الشائعة" لتصل لآلاف المستخدمين',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            if (rooms.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                    child: Text(
                        'يجب أن تملك غرفة واحدة على الأقل لاستخدام هذه الخدمة',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.3)))),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: StreamBuilder<QuerySnapshot>(
                  stream: _db
                      .collection('pin_offers')
                      .where('isActive', isEqualTo: true)
                      .snapshots(),
                  builder: (context, offersSnap) {
                    final offers = offersSnap.data?.docs ?? [];
                    if (offers.isEmpty) {
                      // fallback to built-in packages
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.85,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: pinPackages.length,
                        itemBuilder: (context, index) {
                          final pkg = pinPackages[index];
                          return _buildPinPackageCard(pkg, rooms, userData);
                        },
                      );
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: offers.length,
                      itemBuilder: (context, index) {
                        final o = offers[index].data() as Map<String, dynamic>;
                        final pkg = {
                          'id': offers[index].id,
                          'title': o['title'] ?? 'عرض تثبيت',
                          'duration': o['durationDays'] ?? o['duration'] ?? 1,
                          'price': o['priceGems'] ??
                              o['price'] ??
                              o['priceGems'] ??
                              0,
                          'priceCoins': o['priceCoins'] ?? 0,
                          'imageUrl': o['imageUrl'] ?? '',
                          'gradient': pinPackages[index % pinPackages.length]
                              ['gradient'],
                        };
                        return _buildPinOfferCard(pkg, rooms, userData);
                      },
                    );
                  },
                ),
              )
            ],
            const SizedBox(height: 50),
          ],
        );
      },
    );
  }

  Widget _buildPinPackageCard(Map<String, dynamic> pkg,
      List<QueryDocumentSnapshot> rooms, UserModel userData) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: pkg['gradient'],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color:
                  (pkg['gradient'] as List<Color>).first.withValues(alpha: 0.3),
              blurRadius: 4,
              spreadRadius: 1)
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showPinRoomSelection(pkg, rooms, userData),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.flash_on_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(height: 4),
                Text(pkg['title'],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10)),
                const SizedBox(height: 3),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.diamond,
                          color: Colors.cyanAccent, size: 10),
                      const SizedBox(width: 2),
                      Text(_formatNumber(pkg['price']),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 8)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinOfferCard(Map<String, dynamic> pkg,
      List<QueryDocumentSnapshot> rooms, UserModel userData) {
    final String title = pkg['title'] ?? 'عرض تثبيت';
    final int duration = (pkg['duration'] ?? pkg['durationDays'] ?? 1).toInt();
    final int gemsPrice = (pkg['price'] ?? pkg['priceGems'] ?? 0).toInt();
    final int coinsPrice = (pkg['priceCoins'] ?? 0).toInt();
    final String imageUrl = pkg['imageUrl'] ?? '';

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors:
              (pkg['gradient'] as List<Color>?) ?? [Colors.blue, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showPinRoomSelectionCustom(pkg, rooms, userData),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (imageUrl.isNotEmpty)
                  SizedBox(
                    height: 60,
                    child: Image.network(imageUrl, fit: BoxFit.cover),
                  )
                else
                  const Icon(Icons.push_pin, color: Colors.white, size: 36),
                const SizedBox(height: 8),
                Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('$duration يوم',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 6),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  if (gemsPrice > 0) ...[
                    const Icon(Icons.diamond, size: 12, color: Colors.cyan),
                    const SizedBox(width: 4),
                    Text(_formatNumber(gemsPrice),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                  if (coinsPrice > 0) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.monetization_on,
                        size: 12, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text(_formatNumber(coinsPrice),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ]
                ])
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPinRoomSelectionCustom(Map<String, dynamic> pkg,
      List<QueryDocumentSnapshot> rooms, UserModel userData) {
    // reuse existing selection sheet but adapt to support coins/gems
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1B25),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('اختر الغرفة للتثبيت (${pkg['title']})',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms[index].data() as Map<String, dynamic>;
                    final roomId = rooms[index].id;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(
                            room['roomImage'] ?? room['image'] ?? ''),
                      ),
                      title: Text(room['name'] ?? 'غرفة ملكية',
                          style: const TextStyle(color: Colors.white)),
                      subtitle: Text('مدة: ${pkg['duration']} يوم',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11)),
                      trailing: const Icon(Icons.chevron_left,
                          color: DesignTokens.primaryGold),
                      onTap: () {
                        Navigator.pop(context);
                        _confirmPinPurchaseCustom(
                            pkg, roomId, room['name'], userData);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmPinPurchaseCustom(Map<String, dynamic> pkg,
      String roomId, String roomName, UserModel userData) async {
    final int gemsPrice = (pkg['price'] ?? pkg['priceGems'] ?? 0).toInt();
    final int coinsPrice = (pkg['priceCoins'] ?? 0).toInt();

    // prefer coins if available and user has enough coins, otherwise gems
    final bool useCoins = userData.coins >= coinsPrice && coinsPrice > 0;
    final int cost = useCoins ? coinsPrice : gemsPrice;
    final String currency = useCoins ? 'coins' : 'gems';

    if (currency == 'gems' && userData.gems < cost) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('رصيد الجواهر غير كافٍ 💎'),
          backgroundColor: Colors.red));
      return;
    }
    if (currency == 'coins' && userData.coins < cost) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('رصيد الكوينز غير كافٍ 🪙'),
          backgroundColor: Colors.red));
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A242F),
        title: const Text('تأكيد عملية التثبيت',
            style: TextStyle(color: Colors.white)),
        content: Text(
            'هل أنت متأكد من تثبيت غرفة "$roomName" لمدة ${pkg['duration']} يوم مقابل ${_formatNumber(cost)} ${currency == 'gems' ? 'جواهر' : 'كوينز'}؟',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: DesignTokens.primaryGold),
              child: const Text('تأكيد الشراء',
                  style: TextStyle(color: Colors.black))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _db.runTransaction((transaction) async {
          final userRef = _db.collection('users').doc(userData.uid);
          final roomRef = _db.collection('rooms').doc(roomId);

          final userSnap = await transaction.get(userRef);
          final currentGems = (userSnap.data()?['gems'] ?? 0).toInt();
          final currentCoins = (userSnap.data()?['coins'] ?? 0).toInt();

          if (currency == 'gems') {
            if (currentGems < cost) throw Exception('Insufficient gems');
            transaction.update(userRef, {'gems': currentGems - cost});
          } else {
            if (currentCoins < cost) throw Exception('Insufficient coins');
            transaction.update(userRef, {'coins': currentCoins - cost});
          }

          // قراءة حالة التثبيت الحالية للغرفة وفحص التكرار
          final roomSnap = await transaction.get(roomRef);
          final roomData = roomSnap.data() ?? {};
          final bool alreadyPinned = (roomData['isPinned'] ?? false) == true;
          final String? existingOfferId = roomData['pinOfferId']?.toString();
          final expiryTs = roomData['pinExpiry'] as Timestamp?;
          final expiryDateExisting = expiryTs?.toDate();
          final now = DateTime.now();

          // منع شراء نفس العرض لغرفة مثبتة حالياً بنفس العرض (طالما الصلاحية لم تنتهي)
          if (alreadyPinned &&
              existingOfferId == pkg['id'] &&
              expiryDateExisting != null &&
              expiryDateExisting.isAfter(now)) {
            throw Exception('هذه الغرفة مثبتة بنفس العرض حالياً');
          }

          final expiryDate = now.add(Duration(
              days: (pkg['duration'] ?? pkg['durationDays'] ?? 1).toInt()));

          transaction.update(roomRef, {
            'isPinned': true,
            'pinExpiry': Timestamp.fromDate(expiryDate),
            'pinLevel': pkg['duration'],
            'lastPinnedAt': FieldValue.serverTimestamp(),
            'pinOfferId': pkg['id'],
          });

          final logRef = _db.collection('purchase_logs').doc();
          transaction.set(logRef, {
            'userId': userData.uid,
            'type': 'room_pin',
            'roomId': roomId,
            'packageName': pkg['title'],
            'cost': cost,
            'currency': currency,
            'offerId': pkg['id'],
            'timestamp': FieldValue.serverTimestamp(),
          });
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('مبروك! تم تثبيت غرفتك بنجاح 👑'),
              backgroundColor: Colors.green));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(e.toString()), backgroundColor: Colors.red));
        }
      }
    }
  }

  void _showPinRoomSelection(Map<String, dynamic> pkg,
      List<QueryDocumentSnapshot> rooms, UserModel userData) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1B25),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('اختر الغرفة للتثبيت (${pkg['title']})',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms[index].data() as Map<String, dynamic>;
                    final roomId = rooms[index].id;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(
                            room['roomImage'] ?? room['image'] ?? ''),
                      ),
                      title: Text(room['name'] ?? 'غرفة ملكية',
                          style: const TextStyle(color: Colors.white)),
                      subtitle: const Text('سيتم التثبيت فور التأكيد',
                          style:
                              TextStyle(color: Colors.white38, fontSize: 11)),
                      trailing: const Icon(Icons.chevron_left,
                          color: DesignTokens.primaryGold),
                      onTap: () {
                        Navigator.pop(context);
                        _confirmPinPurchase(
                            pkg, roomId, room['name'], userData);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmPinPurchase(Map<String, dynamic> pkg, String roomId,
      String roomName, UserModel userData) async {
    final int cost = pkg['price'];
    if (userData.gems < cost) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('رصيد الجواهر غير كافٍ 💎'),
          backgroundColor: Colors.red));
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A242F),
        title: const Text('تأكيد عملية التثبيت',
            style: TextStyle(color: Colors.white)),
        content: Text(
            'هل أنت متأكد من تثبيت غرفة "$roomName" لمدة ${pkg['duration']} يوم مقابل ${_formatNumber(cost)} جوهرة؟',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.primaryGold),
            child: const Text('تأكيد الشراء',
                style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _db.runTransaction((transaction) async {
          final userRef = _db.collection('users').doc(userData.uid);
          final roomRef = _db.collection('rooms').doc(roomId);

          final userSnap = await transaction.get(userRef);
          final currentGems = (userSnap.data()?['gems'] ?? 0).toInt();

          if (currentGems < cost) throw Exception('Insufficient gems');

          final now = DateTime.now();
          final expiryDate = now.add(Duration(days: pkg['duration']));

          transaction.update(userRef, {'gems': currentGems - cost});

          transaction.update(roomRef, {
            'isPinned': true,
            'pinExpiry': Timestamp.fromDate(expiryDate),
            'pinLevel': pkg['duration'],
            'lastPinnedAt': FieldValue.serverTimestamp(),
          });

          final logRef = _db.collection('purchase_logs').doc();
          transaction.set(logRef, {
            'userId': userData.uid,
            'type': 'room_pin',
            'roomId': roomId,
            'packageName': pkg['title'],
            'cost': cost,
            'currency': 'gems',
            'timestamp': FieldValue.serverTimestamp(),
          });
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('مبروك! تم تثبيت غرفتك بنجاح 👑'),
              backgroundColor: Colors.green));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(e.toString()), backgroundColor: Colors.red));
        }
      }
    }
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

class CardPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < 360; i += 15) {
      double radians = i * 3.14159 / 180;
      canvas.drawLine(
          center,
          Offset(center.dx + size.width * 2 * math.cos(radians),
              center.dy + size.height * 2 * math.sin(radians)),
          paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ShelvesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final shelfPaint = Paint()
      ..color = const Color(0xFF2DB38E)
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    double padding = 16.0;
    double spacing = 16.0;
    double itemWidth = (size.width - (padding * 2) - spacing) / 2;
    double itemHeight = itemWidth / 1.6;
    double mainSpacing = 35.0;
    double rowFullHeight = itemHeight + mainSpacing;
    double startY = 320;

    for (double y = startY + itemHeight; y < size.height; y += rowFullHeight) {
      canvas.drawRect(Rect.fromLTWH(0, y + 2, size.width, 6), shadowPaint);
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 6), shelfPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RadialBurstPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    const double rayCount = 12;
    const double sweepAngle = 3.14159 * 2 / (rayCount * 2);

    for (int i = 0; i < rayCount; i++) {
      final double startAngle = i * sweepAngle * 2;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: size.width),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
