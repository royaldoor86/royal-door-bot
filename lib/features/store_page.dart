import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../models/frame_model.dart';
import '../widgets/royal_frame_widget.dart';
import '../widgets/animated_vehicle_preview.dart';
import 'gems_coins_page.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 9, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('system_settings').doc('global').snapshots(),
      builder: (context, systemSnap) {
        bool isStoreLocked = false;
        if (systemSnap.hasData && systemSnap.data!.exists) {
          isStoreLocked = (systemSnap.data!.data()
                  as Map<String, dynamic>)['isStoreLocked'] ??
              false;
        }

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: const Color(0xFF0A0A12),
            bottomNavigationBar: SizedBox(
              height: 50,
              child: AdWidget(ad: AdManager().getBannerAd()),
            ),
            body: isStoreLocked
                ? _buildLockedStoreUI()
                : StreamBuilder<UserModel>(
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
                                indicatorColor: Colors.amber,
                                labelColor: Colors.amber,
                                unselectedLabelColor: Colors.white38,
                                tabs: const [
                                  Tab(text: 'الإطارات'),
                                  Tab(text: 'المركبات'),
                                  Tab(text: 'المؤثرات'),
                                  Tab(text: 'الشارات'),
                                  Tab(text: 'الأغلفة'),
                                  Tab(text: 'الفقاعات'),
                                  Tab(text: 'الأرقام المميزة'),
                                  Tab(text: 'التوثيق'),
                                  Tab(text: 'الهدايا'),
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
                                _buildDynamicEntryEffectsGrid(userData),
                                _buildBadgesSection(userData),
                                _buildDynamicCoversGrid(userData),
                                _buildDynamicBubblesGrid(userData),
                                _buildDynamicSpecialIdGrid(userData),
                                _buildDynamicVerificationGrid(userData),
                                _buildDynamicGiftsGrid(userData),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        );
      },
    );
  }

  Widget _buildLockedStoreUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.store_mall_directory_outlined,
                size: 80, color: Colors.pinkAccent),
            const SizedBox(height: 20),
            const Text(
              'المتجر الملكي مغلق حالياً',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'نحن نقوم بتحديث المنتجات، نعود قريباً ✨',
              style: TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              child: const Text('العودة للخلف',
                  style: TextStyle(color: Colors.black)),
            )
          ],
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
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.amber));
          }
          final docs = snapshot.data!.docs;
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12),
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
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.amber));
          }
          final docs = snapshot.data!.docs;
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12),
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
    String url = data['url'] ?? '';

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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                    color: isOwned
                        ? Colors.green.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.05))),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (c, u) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(data['name'] ?? 'عنصر ملكي',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                Text('$price ⭐',
                    style: const TextStyle(color: Colors.amber, fontSize: 11)),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: isOwned
                      ? null
                      : () => _purchaseStoreItem(id, data, type, userData),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOwned
                        ? Colors.grey.withValues(alpha: 0.2)
                        : Colors.amber.withValues(alpha: 0.1),
                    minimumSize: const Size(double.infinity, 32),
                  ),
                  child: Text(isOwned ? 'تملكه ✅' : 'اقتناء',
                      style: TextStyle(
                          fontSize: 11,
                          color: isOwned ? Colors.white38 : Colors.amber)),
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
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text('اقتناء ${type == 'cover' ? 'غلاف' : 'فقاعة'}',
            style: const TextStyle(color: Colors.white)),
        content: Text('هل تريد الشراء مقابل $price نجمة؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('شراء', style: TextStyle(color: Colors.amber))),
        ],
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
            backgroundColor: Colors.amber));
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
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.cyanAccent));
          }
          final docs = snapshot.data!.docs;
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12),
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                    color: isOwned
                        ? Colors.cyanAccent.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.05))),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: AnimatedVehiclePreview(
                      type: type,
                      url: url,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(data['name'] ?? 'مركبة ملكية',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
                Text('$price ⭐',
                    style: const TextStyle(color: Colors.amber, fontSize: 11)),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: isOwned
                      ? null
                      : () => _purchaseVehicle(id, data, userData),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOwned
                        ? Colors.grey.withValues(alpha: 0.2)
                        : Colors.cyanAccent.withValues(alpha: 0.1),
                    minimumSize: const Size(double.infinity, 32),
                  ),
                  child: Text(isOwned ? 'تملكها ✅' : 'اقتناء',
                      style: TextStyle(
                          fontSize: 11,
                          color: isOwned ? Colors.white38 : Colors.cyanAccent)),
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
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title:
            const Text('اقتناء مركبة', style: TextStyle(color: Colors.white)),
        content:
            Text('هل تريد شراء مركبة (${data['name']}) مقابل $price نجمة؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('شراء',
                  style: TextStyle(color: Colors.cyanAccent))),
        ],
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content:
                Text('مبروك! تم إضافة ${data['name']} إلى مرآبك الخاص 🏎️'),
            backgroundColor: Colors.cyanAccent));
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
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.amber));
          }
          final docs = snapshot.data!.docs;
          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12),
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
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                    color: isOwned
                        ? Colors.green.withValues(alpha: 0.3)
                        : Colors.amber.withValues(alpha: 0.1))),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                    child: RoyalFrameWidget(
                        frameUrl: frame.imageUrl,
                        size: 110,
                        child: const CircleAvatar(
                            radius: 35,
                            backgroundColor: Colors.white10,
                            child: Icon(Icons.person, color: Colors.white24)))),
                const SizedBox(height: 8),
                Text(frame.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
                Text('${frame.price} ⭐',
                    style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: isOwned
                      ? null
                      : () => _purchaseFrameDirect(frame, userData),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: isOwned
                          ? Colors.grey.withValues(alpha: 0.2)
                          : Colors.amber.withValues(alpha: 0.1),
                      minimumSize: const Size(double.infinity, 32)),
                  child: Text(isOwned ? 'تملكه ✅' : 'اقتناء',
                      style: TextStyle(
                          fontSize: 11,
                          color: isOwned ? Colors.white38 : Colors.amber)),
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
        builder: (ctx) => AlertDialog(
              backgroundColor: const Color(0xFF1A1A2E),
              title: const Text('اقتناء إطار ملكي',
                  style: TextStyle(color: Colors.white)),
              content: Text(
                  'هل تريد شراء إطار (${frame.name}) مقابل ${frame.price} نجمة؟'),
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
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.amber));
          }
          final dynamicBadges = snapshot.data!.docs
              .map((d) => d.data() as Map<String, dynamic>)
              .toList();
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
                      ? CachedNetworkImage(
                          imageUrl: iconData,
                          width: 40,
                          height: 40,
                          placeholder: (context, url) =>
                              const CircularProgressIndicator(strokeWidth: 2),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.error, color: Colors.red),
                        )
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
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.amber));
          }
          final docs = snapshot.data!.docs;
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.1))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: url.isNotEmpty
                  ? (isLottie
                      ? Lottie.network(url, fit: BoxFit.contain)
                      : CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.contain,
                          placeholder: (c, u) => const Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.amber))))
                  : const Icon(Icons.rocket_launch_rounded,
                      color: Colors.purpleAccent, size: 45),
            ),
          ),
          const SizedBox(height: 12),
          Text(data['name'] ?? 'تأثير دخول',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
          Text('$price نجمة ⭐',
              style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          ElevatedButton(
              onPressed: () => _purchaseEntryEffect(docId, data, userData),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  minimumSize: const Size(double.infinity, 35)),
              child: const Text('اقتناء الآن', style: TextStyle(fontSize: 11))),
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

  Widget _buildDynamicGiftsGrid(UserModel? userData) {
    return StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('gifts')
            .where('showInStore', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.amber));
          }
          final docs = snapshot.data!.docs;
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
              return _buildGiftStoreCard(docs[index].id, data, userData);
            },
          );
        });
  }

  Widget _buildGiftStoreCard(
      String docId, Map<String, dynamic> data, UserModel? userData) {
    int price = data['price'] ?? 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.1))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
              child: data['imageUrl'].toString().isNotEmpty
                  ? Image.network(data['imageUrl'], fit: BoxFit.contain)
                  : const Icon(Icons.card_giftcard,
                      color: Colors.pinkAccent, size: 40)),
          const SizedBox(height: 8),
          Text(data['name'] ?? 'هدية ملكية',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('$price ',
                style: const TextStyle(
                    color: Colors.amber, fontWeight: FontWeight.bold)),
            const Icon(Icons.diamond, size: 12, color: Colors.cyanAccent)
          ]),
          const SizedBox(height: 10),
          ElevatedButton(
              onPressed: () => _purchaseGift(docId, data, userData),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  minimumSize: const Size(double.infinity, 32)),
              child: const Text('شراء', style: TextStyle(fontSize: 11))),
        ],
      ),
    );
  }

  void _purchaseGift(
      String docId, Map<String, dynamic> data, UserModel? user) async {
    if (user == null) return;
    int price = (data['price'] ?? 0).toInt();
    if (user.gems < price) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('رصيد الألماس غير كافٍ 💎')));
      return;
    }
    await _db.runTransaction((tx) async {
      final userRef = _db.collection('users').doc(user.uid);
      tx.update(userRef, {'gems': user.gems - price});
      tx.set(userRef.collection('inventory').doc(docId), {
        'type': 'gift',
        'name': data['name'],
        'imageUrl': data['imageUrl'],
        'boughtAt': FieldValue.serverTimestamp()
      });
    });
  }

  Widget _buildDynamicVerificationGrid(UserModel? userData) {
    return StreamBuilder<QuerySnapshot>(
        stream: _db.collection('verifications').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.amber));
          }
          final docs = snapshot.data!.docs;
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
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('الرصيد غير كافٍ ⭐')));
      return;
    }

    try {
      final callable = FirebaseFunctions.instanceFor(region: 'us-central1')
          .httpsCallable('purchaseRoyalId');
      final result = await callable.call({
        'specialIdDocId': docId,
      });

      if (result.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('تم شراء المعرف بنجاح ✅'),
            backgroundColor: Colors.green));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(result.data['message']?.toString() ??
                'حدث خطأ أثناء شراء المعرف')));
      }
    } on FirebaseFunctionsException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message ?? 'خطأ في الخادم')));
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('خطأ غير متوقع: $e')));
    }
  }

  Widget _buildRoyalSliverAppBar(UserModel? user) {
    return SliverAppBar(
      expandedHeight: 180.0,
      pinned: true,
      backgroundColor: const Color(0xFF1A1A2E),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1A1A2E), Color(0xFF0A0A12)])),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(height: 40),
            const Icon(Icons.shopping_bag, color: Colors.pinkAccent, size: 35),
            const Text('المتجر الملكي المطور',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const GemsCoinsPage())),
                  child: _buildGlassBalance(user?.gems.toString() ?? '0',
                      Icons.diamond, Colors.cyanAccent)),
              const SizedBox(width: 10),
              GestureDetector(
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const GemsCoinsPage())),
                  child: _buildGlassBalance(user?.stars.toString() ?? '0',
                      Icons.stars, Colors.amber)),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _buildGlassBalance(String amount, IconData icon, Color color) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Row(children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(amount,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13))
        ]));
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
      Container(color: const Color(0xFF0A0A12), child: _tabBar);
  @override
  bool shouldRebuild(_SliverAppBarDelegate old) => false;
}
