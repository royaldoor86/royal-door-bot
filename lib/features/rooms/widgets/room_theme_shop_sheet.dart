import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoomThemeShopSheet extends StatefulWidget {
  final String roomId;
  const RoomThemeShopSheet({super.key, required this.roomId});

  @override
  State<RoomThemeShopSheet> createState() => _RoomThemeShopSheetState();
}

class _RoomThemeShopSheetState extends State<RoomThemeShopSheet> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _selectedTab = 0; // 0: المتجر, 1: موضوعاتي

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F1B25),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            border: Border(top: BorderSide(color: Colors.amber, width: 0.5)),
          ),
          child: Column(
            children: [
              // مقبض السحب العلوي
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              
              // الرصيد (Coins & Gems)
              _buildHeaderBalance(),

              // التبويبات (Tabs)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTabItem('المتجر', 0),
                const SizedBox(width: 30),
                _buildTabItem('موضوعاتي', 1),
              ],
            ),
          ),
              
              const Divider(color: Colors.white10, height: 1),

              // المحتوى (Store or My Themes)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomPadding + 10),
                  child: _selectedTab == 0 
                      ? _buildStoreView(scrollController) 
                      : _buildMyThemesView(scrollController),
                ),
              ),
            ],
          ),
        );
      },
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
        
        final double stars = _parseDouble(data['stars'] ?? data['coins'] ?? 0);
        final double gems = _parseDouble(data['gems'] ?? 0);
        
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildBalanceItem(gems.toStringAsFixed(0), Icons.diamond, Colors.cyan),
              const SizedBox(width: 12),
              _buildBalanceItem(stars.toStringAsFixed(0), Icons.stars_rounded, Colors.amber),
            ],
          ),
        );
      },
    );
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Widget _buildBalanceItem(String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
          const SizedBox(width: 4),
          Icon(icon, color: color, size: 14),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, int index) {
    bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Column(
        children: [
          Text(title, style: TextStyle(color: isSelected ? Colors.amber : Colors.white54, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, fontSize: 15)),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isSelected ? 20 : 0, height: 2,
            decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(2)),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreView(ScrollController controller) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('room_themes').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('خطأ في التحميل: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('لا توجد ثيمات متاحة حالياً', style: TextStyle(color: Colors.white38)));

        return GridView.builder(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(15, 10, 15, 15),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 12, mainAxisSpacing: 12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildThemeCard(docs[index].id, data, isStore: true);
          },
        );
      },
    );
  }

  Widget _buildMyThemesView(ScrollController controller) {
    final user = _auth.currentUser;
    if (user == null) return const Center(child: Text('يرجى تسجيل الدخول', style: TextStyle(color: Colors.white38)));

    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('users').doc(user.uid).collection('owned_themes').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('خطأ: ${snapshot.error}', style: const TextStyle(color: Colors.redAccent)));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('لم يتم شراء أي ثيمات بعد 💔', style: TextStyle(color: Colors.white38)));

        return GridView.builder(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(15, 10, 15, 15),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 12, mainAxisSpacing: 12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildThemeCard(docs[index].id, data, isStore: false);
          },
        );
      },
    );
  }

  Widget _buildThemeCard(String id, Map<String, dynamic> data, {required bool isStore}) {
    final String imageUrl = data['imageUrl'] ?? '';
    final String name = data['name'] ?? 'ثيم ملكي';
    final double price = _parseDouble(data['price'] ?? 0);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A242F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.image, color: Colors.white10)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 10),
                isStore 
                  ? ElevatedButton(
                      onPressed: () => _purchaseTheme(id, data),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber, 
                        foregroundColor: Colors.black, 
                        minimumSize: const Size(double.infinity, 36), 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
                        elevation: 0
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(price.toStringAsFixed(0), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          const Icon(Icons.stars_rounded, size: 14, color: Colors.black87),
                        ],
                      ),
                    )
                  : ElevatedButton(
                      onPressed: () => _applyTheme(imageUrl),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 36), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                      child: const Text('تطبيق الآن', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _purchaseTheme(String themeId, Map<String, dynamic> themeData) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userDoc = await _db.collection('users').doc(user.uid).get();
      double balance = _parseDouble(userDoc.data()?['stars'] ?? userDoc.data()?['coins'] ?? 0);
      double price = _parseDouble(themeData['price'] ?? 0);

      if (balance < price) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رصيدك من النجوم غير كافٍ ❌'), backgroundColor: Colors.redAccent));
        return;
      }

      await _db.runTransaction((transaction) async {
        double newBalance = balance - price;
        transaction.update(_db.collection('users').doc(user.uid), {
          'stars': newBalance,
          'coins': newBalance,
        });
        transaction.set(_db.collection('users').doc(user.uid).collection('owned_themes').doc(themeId), {
          ...themeData,
          'price': price, // Ensure price is double if needed
          'boughtAt': FieldValue.serverTimestamp(),
        });

        final roomRef = _db.collection('rooms').doc(widget.roomId);
        final roomSnap = await transaction.get(roomRef);
        if (roomSnap.exists) {
          int currentExp = roomSnap.data()?['exp'] ?? 0;
          int currentLevel = roomSnap.data()?['level'] ?? 1;
          int pointsToAdd = 25; 
          int newExp = currentExp + pointsToAdd;
          int nextLevelThreshold = currentLevel * 10000;
          
          if (newExp >= nextLevelThreshold) {
            transaction.update(roomRef, {
              'exp': newExp - nextLevelThreshold,
              'level': currentLevel + 1,
            });
          } else {
            transaction.update(roomRef, {'exp': newExp});
          }
        }
      });

      await _applyTheme(themeData['imageUrl']);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('مبروك! تم شراء وتطبيق الموضوع بنجاح 🎁✨'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل عملية الشراء، حاول لاحقاً ❌'), backgroundColor: Colors.redAccent));
    }
  }

  Future<void> _applyTheme(String url) async {
    try {
      await _db.collection('rooms').doc(widget.roomId).update({'backgroundImage': url});
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تغيير خلفية الغرفة بنجاح ✅'), backgroundColor: Colors.blueAccent));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل في تطبيق التغيير ❌'), backgroundColor: Colors.redAccent));
    }
  }
}
