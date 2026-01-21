import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../models/frame_model.dart';
import 'gems_coins_page.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // قائمة الأعلام الثابتة التي طلبت نسخها للمتجر
  final List<Map<String, dynamic>> countryBadges = [
    {'name': 'فخر السعودية', 'icon': '🇸🇦', 'category': 'achievement', 'price': 5000},
    {'name': 'نجمة العراق', 'icon': '🇮🇶', 'category': 'achievement', 'price': 5000},
    {'name': 'فخر مصر', 'icon': '🇪🇬', 'category': 'achievement', 'price': 5000},
    {'name': 'فخر الكويت', 'icon': '🇰🇼', 'category': 'achievement', 'price': 5000},
    {'name': 'فخر الإمارات', 'icon': '🇦🇪', 'category': 'achievement', 'price': 5000},
    {'name': 'فخر قطر', 'icon': '🇶🇦', 'category': 'achievement', 'price': 5000},
    {'name': 'فخر عمان', 'icon': '🇴🇲', 'category': 'achievement', 'price': 5000},
    {'name': 'نجم الأردن', 'icon': '🇯🇴', 'category': 'achievement', 'price': 5000},
    {'name': 'نجم فلسطيني', 'icon': '🇵🇸', 'category': 'achievement', 'price': 5000},
    {'name': 'نجم سوريا', 'icon': '🇸🇾', 'category': 'achievement', 'price': 5000},
    {'name': 'نجم لبنان', 'icon': '🇱🇧', 'category': 'achievement', 'price': 5000},
    {'name': 'فخر الجزائر', 'icon': '🇩🇿', 'category': 'achievement', 'price': 5000},
    {'name': 'فخر المغرب', 'icon': '🇲🇦', 'category': 'achievement', 'price': 5000},
    {'name': 'فخر تونس', 'icon': '🇹🇳', 'category': 'achievement', 'price': 5000},
    {'name': 'نجم ليبيا', 'icon': '🇱🇾', 'category': 'achievement', 'price': 5000},
    {'name': 'نجم يمني', 'icon': '🇾🇪', 'category': 'achievement', 'price': 5000},
    {'name': 'فخر السودان', 'icon': '🇸🇩', 'category': 'achievement', 'price': 5000},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A12),
        body: StreamBuilder<UserModel>(
          stream: user != null ? _firestoreService.streamUserData(user.uid) : null,
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
                        Tab(text: 'المؤثرات'),
                        Tab(text: 'الشارات'),
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
                      _buildDynamicEntryEffectsGrid(userData),
                      _buildBadgesSection(userData), // القسم المدمج (أعلام + إدارة)
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
  }

  Widget _buildBadgesSection(UserModel? userData) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('badges_templates').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        final dynamicBadges = snapshot.data?.docs.map((d) => d.data() as Map<String, dynamic>).toList() ?? [];
        
        // دمج الأعلام الثابتة مع الشارات المضافة من الإدارة
        final allBadges = [...countryBadges, ...dynamicBadges];

        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, 
            childAspectRatio: 0.65, 
            crossAxisSpacing: 8, 
            mainAxisSpacing: 8
          ),
          itemCount: allBadges.length,
          itemBuilder: (context, index) {
            return _buildBadgeStoreCard(allBadges[index], userData);
          },
        );
      }
    );
  }

  Widget _buildBadgeStoreCard(Map<String, dynamic> data, UserModel? userData) {
    int price = data['price'] ?? 0;
    return StreamBuilder<QuerySnapshot>(
      stream: userData != null 
        ? _db.collection('users').doc(userData.uid).collection('inventory').where('icon', isEqualTo: data['icon']).snapshots()
        : null,
      builder: (context, snapshot) {
        bool isOwned = snapshot.hasData && snapshot.data!.docs.isNotEmpty;
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03), 
            borderRadius: BorderRadius.circular(20), 
            border: Border.all(color: isOwned ? Colors.green.withOpacity(0.2) : Colors.amber.withOpacity(0.1))
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(data['icon'] ?? '🛡️', style: const TextStyle(fontSize: 30)),
              const SizedBox(height: 5),
              Text(data['name'] ?? 'وسام', textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              Text('$price 🪙', style: const TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: isOwned ? null : () => _purchaseBadge(data, userData),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOwned ? Colors.grey.withOpacity(0.1) : Colors.amber.withOpacity(0.1), 
                  minimumSize: const Size(double.infinity, 28), 
                  padding: EdgeInsets.zero
                ),
                child: Text(isOwned ? 'تملكه ✅' : 'اقتناء', style: TextStyle(fontSize: 9, color: isOwned ? Colors.white38 : Colors.amber)),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رصيد الكوينز غير كافٍ 🪙')));
      return;
    }

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('اقتناء وسام', style: TextStyle(color: Colors.white)),
        content: Text('هل تريد شراء شارة (${data['name']}) مقابل $price كوينز؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('شراء', style: TextStyle(color: Colors.amber))),
        ],
      ),
    );

    if (confirm == true) {
      await _db.runTransaction((tx) async {
        final userRef = _db.collection('users').doc(user.uid);
        tx.update(userRef, { 'coins': user.coins - price });
        tx.set(userRef.collection('inventory').doc(), {
          'type': data['category'] ?? 'badge',
          'name': data['name'],
          'icon': data['icon'],
          'boughtAt': FieldValue.serverTimestamp(),
        });
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('مبروك! حصلت على وسام ${data['name']} 🏆'), backgroundColor: Colors.amber));
    }
  }

  // --- بقية الأقسام (إطارات، هدايا، إلخ) تبقى كما هي ---
  Widget _buildDynamicFramesGrid(UserModel? userData) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('frames').where('isActive', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));
        final docs = snapshot.data!.docs;
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 12, mainAxisSpacing: 12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final frame = FrameModel.fromFirestore(docs[index] as DocumentSnapshot<Map<String, dynamic>>);
            return _buildFrameStoreCard(frame, userData);
          },
        );
      }
    );
  }

  Widget _buildFrameStoreCard(FrameModel frame, UserModel? userData) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.amber.withOpacity(0.1))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: Stack(alignment: Alignment.center, children: [const CircleAvatar(radius: 35, backgroundImage: AssetImage('assets/images/avatar_placeholder.png')), Image.network(frame.imageUrl, width: 90, height: 90, fit: BoxFit.contain, errorBuilder: (c,e,s) => const Icon(Icons.person_pin_circle, color: Colors.amber))])),
          const SizedBox(height: 8),
          Text(frame.name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          Text('${frame.price} كوينز 🪙', style: const TextStyle(color: Colors.amber, fontSize: 11)),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: () => _purchaseFrame(frame, userData), child: const Text('شراء', style: TextStyle(fontSize: 11))),
        ],
      ),
    );
  }

  void _purchaseFrame(FrameModel frame, UserModel? user) async {
    if (user == null) return;
    if (user.coins < frame.price) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رصيد الكوينز غير كافٍ 🪙'))); return; }
    await _db.runTransaction((tx) async { tx.update(_db.collection('users').doc(user.uid), {'coins': user.coins - frame.price, 'currentFrame': frame.imageUrl}); tx.set(_db.collection('users').doc(user.uid).collection('inventory').doc(frame.id), {'type': 'frame', 'name': frame.name, 'imageUrl': frame.imageUrl, 'boughtAt': FieldValue.serverTimestamp()}); });
  }

  Widget _buildDynamicEntryEffectsGrid(UserModel? userData) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('entry_effects').where('isActive', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));
        final docs = snapshot.data!.docs;
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 12, mainAxisSpacing: 12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildEntryEffectStoreCard(docs[index].id, data, userData);
          },
        );
      }
    );
  }

  Widget _buildEntryEffectStoreCard(String docId, Map<String, dynamic> data, UserModel? userData) {
    int price = data['price'] ?? 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.purpleAccent.withOpacity(0.1))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.rocket_launch_rounded, color: Colors.purpleAccent, size: 45),
          const SizedBox(height: 12),
          Text(data['name'] ?? 'تأثير دخول', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          Text('$price كوينز 🪙', style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          ElevatedButton(onPressed: () => _purchaseEntryEffect(docId, data, userData), style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.05), minimumSize: const Size(double.infinity, 35)), child: const Text('اقتناء الآن', style: TextStyle(fontSize: 11))),
        ],
      ),
    );
  }

  void _purchaseEntryEffect(String docId, Map<String, dynamic> data, UserModel? user) async {
    if (user == null) return;
    int price = data['price'] ?? 0;
    if (user.coins < price) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرصيد غير كافٍ 🪙'))); return; }
    await _db.runTransaction((tx) async { final userRef = _db.collection('users').doc(user.uid); tx.update(userRef, { 'coins': user.coins - price, 'entryEffect': data['lottieUrl'] }); tx.set(userRef.collection('inventory').doc(docId), { 'type': 'vehicle', 'name': data['name'], 'imageUrl': data['lottieUrl'], 'boughtAt': FieldValue.serverTimestamp() }); });
  }

  Widget _buildDynamicGiftsGrid(UserModel? userData) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('gifts').where('showInStore', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));
        final docs = snapshot.data!.docs;
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 12, mainAxisSpacing: 12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildGiftStoreCard(docs[index].id, data, userData);
          },
        );
      }
    );
  }

  Widget _buildGiftStoreCard(String docId, Map<String, dynamic> data, UserModel? userData) {
    int price = data['price'] ?? 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.pinkAccent.withOpacity(0.1))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(child: data['imageUrl'].toString().isNotEmpty ? Image.network(data['imageUrl'], fit: BoxFit.contain) : const Icon(Icons.card_giftcard, color: Colors.pinkAccent, size: 40)),
          const SizedBox(height: 8),
          Text(data['name'] ?? 'هدية ملكية', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('$price ', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)), const Icon(Icons.diamond, size: 12, color: Colors.cyanAccent)]),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: () => _purchaseGift(docId, data, userData), style: ElevatedButton.styleFrom(backgroundColor: Colors.white.withOpacity(0.05), minimumSize: const Size(double.infinity, 32)), child: const Text('شراء', style: TextStyle(fontSize: 11))),
        ],
      ),
    );
  }

  void _purchaseGift(String docId, Map<String, dynamic> data, UserModel? user) async {
    if (user == null) return;
    int price = data['price'] ?? 0;
    if (user.gems < price) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رصيد الألماس غير كافٍ 💎'))); return; }
    await _db.runTransaction((tx) async { tx.update(_db.collection('users').doc(user.uid), { 'gems': user.gems - price }); tx.set(_db.collection('users').doc(user.uid).collection('inventory').doc(docId), { 'type': 'gift', 'name': data['name'], 'imageUrl': data['imageUrl'], 'boughtAt': FieldValue.serverTimestamp() }); });
  }

  Widget _buildDynamicVerificationGrid(UserModel? userData) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('verifications').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));
        final docs = snapshot.data!.docs;
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 12, mainAxisSpacing: 12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildVerificationStoreCard(docs[index].id, data, userData);
          },
        );
      }
    );
  }

  Widget _buildVerificationStoreCard(String docId, Map<String, dynamic> data, UserModel? userData) {
    String? hex = data['color'];
    Color badgeColor = Colors.amber;
    if (hex != null && hex.isNotEmpty) {
      try {
        String cleanHex = hex.replaceAll('#', '');
        if (cleanHex.length == 6) cleanHex = 'FF' + cleanHex;
        badgeColor = Color(int.parse('0x' + cleanHex));
      } catch (_) {}
    }
    bool isOwned = userData?.verificationColor == data['color'];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(25), border: Border.all(color: badgeColor.withOpacity(0.3))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified, color: badgeColor, size: 50),
          const SizedBox(height: 12),
          Text(data['name'] ?? 'توثيق', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          Text('${data['price']} كوينز 🪙', style: TextStyle(color: badgeColor, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          ElevatedButton(onPressed: isOwned ? null : () => _purchaseVerification(docId, data, userData), style: ElevatedButton.styleFrom(backgroundColor: isOwned ? Colors.grey : badgeColor.withOpacity(0.2), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 35), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: Text(isOwned ? 'مفعل ✅' : 'شراء وتوثيق', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _purchaseVerification(String docId, Map<String, dynamic> data, UserModel? user) async {
    if (user == null) return;
    int price = data['price'] ?? 0;
    if (user.coins < price) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رصيد الكوينز غير كافٍ 🪙'))); return; }
    await _db.runTransaction((tx) async { tx.update(_db.collection('users').doc(user.uid), { 'coins': user.coins - price, 'verificationColor': data['color'] }); });
  }

  Widget _buildDynamicSpecialIdGrid(UserModel? userData) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('special_ids').where('showInStore', isEqualTo: true).where('isSold', isEqualTo: false).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 12, mainAxisSpacing: 12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildIdStoreCard(docs[index].id, data, userData);
          },
        );
      }
    );
  }

  Widget _buildIdStoreCard(String docId, Map<String, dynamic> data, UserModel? userData) {
    final currency = data['currencyType'] ?? 'coins';
    final price = data['price'] ?? 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.amber.withOpacity(0.1))),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.badge, color: Colors.amber, size: 35),
        const SizedBox(height: 8),
        Text(data['royalId'] ?? '---', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text('$price ', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)), Icon(currency == 'gems' ? Icons.diamond : Icons.monetization_on, size: 14, color: currency == 'gems' ? Colors.cyanAccent : Colors.amber)]),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: () => _handlePurchaseId(docId, data['royalId'], price, currency, userData), child: const Text('استبدال', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
      ]),
    );
  }

  void _handlePurchaseId(String docId, String newId, int price, String currency, UserModel? user) async {
    if (user == null) return;
    final bal = currency == 'gems' ? user.gems : user.coins;
    if (bal < price) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرصيد غير كافٍ 🪙'))); return; }
    await _db.runTransaction((tx) async { tx.update(_db.collection('users').doc(user.uid), {currency: bal - price, 'royalId': newId}); tx.update(_db.collection('special_ids').doc(docId), {'isSold': true, 'ownerUid': user.uid, 'soldAt': FieldValue.serverTimestamp()}); });
  }

  Widget _buildRoyalSliverAppBar(UserModel? user) {
    return SliverAppBar(
      expandedHeight: 180.0, pinned: true, backgroundColor: const Color(0xFF1A1A2E),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1A1A2E), Color(0xFF0A0A12)])),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(height: 40), const Icon(Icons.shopping_bag, color: Colors.amber, size: 35),
            const Text('سوق رويال دور العالمي', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GemsCoinsPage())), child: _buildGlassBalance(user?.gems.toString() ?? '0', Icons.diamond, Colors.cyanAccent)),
              const SizedBox(width: 10),
              GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GemsCoinsPage())), child: _buildGlassBalance(user?.coins.toString() ?? '0', Icons.monetization_on, Colors.amber)),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _buildGlassBalance(String amount, IconData icon, Color color) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.3))), child: Row(children: [Icon(icon, color: color, size: 16), const SizedBox(width: 6), Text(amount, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))]));
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override double get minExtent => _tabBar.preferredSize.height;
  @override double get maxExtent => _tabBar.preferredSize.height;
  @override Widget build(context, shrink, overlaps) => Container(color: const Color(0xFF0A0A12), child: _tabBar);
  @override bool shouldRebuild(_SliverAppBarDelegate old) => false;
}
