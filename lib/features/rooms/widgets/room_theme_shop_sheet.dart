import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RoomThemeShopSheet extends StatefulWidget {
  final String roomId;
  const RoomThemeShopSheet({super.key, required this.roomId});

  @override
  State<RoomThemeShopSheet> createState() => _RoomThemeShopSheetState();

  static Future<void> show(BuildContext context, String roomId) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomThemeShopSheet(roomId: roomId),
        fullscreenDialog: true,
      ),
    );
  }
}

class _RoomThemeShopSheetState extends State<RoomThemeShopSheet>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1B25),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F1B25),
        elevation: 0,
        title: const Text('موضوعات الغرفة',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _buildHeaderBalance(),
          const SizedBox(width: 10),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.amber,
          labelColor: Colors.amber,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'موضوعاتي'),
            Tab(text: 'المتجر'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyThemesView(),
          _buildStoreThemesView(),
        ],
      ),
    );
  }

  Widget _buildMyThemesView() {
    final user = _auth.currentUser;
    if (user == null) {
      return const Center(
          child: Text('يرجى تسجيل الدخول',
              style: TextStyle(color: Colors.white38)));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('users')
          .doc(user.uid)
          .collection('owned_themes')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
              child: Text('حدث خطأ في تحميل مقتنياتك',
                  style: TextStyle(color: Colors.redAccent)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.amber));
        }

        var docs = snapshot.data!.docs;
        
        // Sort manually to handle missing boughtAt fields
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = aData['boughtAt'] as Timestamp?;
          final bTime = bData['boughtAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.palette_outlined,
                    size: 64, color: Colors.white10),
                const SizedBox(height: 16),
                const Text('لم تقتنِ أي موضوعات بعد 💔',
                    style: TextStyle(color: Colors.white38)),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _tabController.animateTo(1),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                  child: const Text('اذهب للمتجر',
                      style: TextStyle(color: Colors.black)),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(15),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 150,
            childAspectRatio: 0.7,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildThemeCard(docs[index].id, data, isStore: false);
          },
        );
      },
    );
  }

  Widget _buildStoreThemesView() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('room_themes')
          .where('isActive', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
              child: Text('حدث خطأ في تحميل المتجر',
                  style: TextStyle(color: Colors.redAccent)));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.amber));
        }

        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(
              child: Text('المتجر فارغ حالياً 📦',
                  style: TextStyle(color: Colors.white38)));
        }

        return GridView.builder(
          padding: const EdgeInsets.all(15),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 150,
            childAspectRatio: 0.7,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final String imageUrl = data['imageUrl'] ?? data['url'] ?? '';

            return StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('users')
                  .doc(_auth.currentUser?.uid)
                  .collection('owned_themes')
                  .where('imageUrl', isEqualTo: imageUrl)
                  .snapshots(),
              builder: (context, ownedSnap) {
                bool isOwned =
                    ownedSnap.hasData && ownedSnap.data!.docs.isNotEmpty;
                return _buildThemeCard(docs[index].id, data,
                    isStore: !isOwned);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildThemeCard(String id, Map<String, dynamic> data,
      {required bool isStore}) {
    final String imageUrl = data['imageUrl'] ?? data['url'] ?? '';
    final String name = data['name'] ?? 'موضوع ملكي';
    final double price = _parseDouble(data['price'] ?? 0);
    final String currencyType = data['currencyType'] ?? 'coins';

    return GestureDetector(
      onTap: () => _showThemePreview(imageUrl, isStore, id, data),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A242F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isStore
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.green.withValues(alpha: 0.3),
              width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                      color: Colors.black12,
                      child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2))),
                  errorWidget: (c, url, error) => Container(
                    color: const Color(0xFF1A242F),
                    child: const Icon(Icons.image,
                        color: Colors.white10, size: 40),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  if (isStore)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            price.toStringAsFixed(0),
                            style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 3),
                          Icon(
                            currencyType == 'gems'
                                ? Icons.diamond
                                : Icons.monetization_on,
                            size: 11,
                            color: Colors.amber,
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'مملوك ✅',
                        style: TextStyle(
                            color: Colors.green,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemePreview(
      String imageUrl, bool isStore, String themeId, Map<String, dynamic> data) {
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
            left: 50,
            right: 50,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isStore)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _purchaseTheme(themeId, data);
                    },
                    child: const Text('اقتناء هذا الموضوع',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                  )
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _applyTheme(imageUrl);
                    },
                    child: const Text('تطبيق على الغرفة',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBalance() {
    final user = _auth.currentUser;
    if (user == null) return const SizedBox.shrink();
    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() as Map<String, dynamic>?;
        if (data == null) return const SizedBox.shrink();

        final double coins = _parseDouble(data['coins'] ?? 0);
        final double gems = _parseDouble(data['gems'] ?? 0);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBalanceItem(
                gems.toStringAsFixed(0), Icons.diamond, Colors.cyan),
            const SizedBox(width: 8),
            _buildBalanceItem(
                coins.toStringAsFixed(0), Icons.monetization_on, Colors.amber),
          ],
        );
      },
    );
  }

  Widget _buildBalanceItem(String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 10)),
          const SizedBox(width: 3),
          Icon(icon, color: color, size: 12),
        ],
      ),
    );
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Future<void> _purchaseTheme(
      String themeId, Map<String, dynamic> themeData) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userDoc = await _db.collection('users').doc(user.uid).get();
      final String currencyType = themeData['currencyType'] ?? 'coins';
      double balance = _parseDouble(userDoc.data()?[currencyType] ?? 0);
      double price = _parseDouble(themeData['price'] ?? 0);

      if (balance < price) {
        String currencyName = currencyType == 'gems' ? 'الجواهر' : 'الكوينز';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('رصيد $currencyName غير كافٍ ❌'),
            backgroundColor: Colors.redAccent));
        return;
      }

      await _db.runTransaction((transaction) async {
        transaction.update(_db.collection('users').doc(user.uid),
            {currencyType: balance - price});

        transaction.set(
            _db
                .collection('users')
                .doc(user.uid)
                .collection('owned_themes')
                .doc(themeId),
            {
              ...themeData,
              'imageUrl': themeData['imageUrl'] ?? themeData['url'],
              'url': themeData['url'] ?? themeData['imageUrl'],
              'boughtAt': FieldValue.serverTimestamp(),
            });
      });

      _applyTheme(themeData['imageUrl'] ?? themeData['url']);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم شراء وتطبيق الموضوع بنجاح 🎁✨'),
          backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('فشل عملية الشراء ❌'),
          backgroundColor: Colors.redAccent));
    }
  }

  Future<void> _applyTheme(String url) async {
    try {
      await _db
          .collection('rooms')
          .doc(widget.roomId)
          .update({'backgroundImage': url});
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('تم تغيير خلفية الغرفة بنجاح ✅'),
            backgroundColor: Colors.blueAccent));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('فشل تطبيق التغيير ❌'),
            backgroundColor: Colors.redAccent));
      }
    }
  }
}
