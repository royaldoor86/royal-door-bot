import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

class AppearancePage extends StatefulWidget {
  const AppearancePage({super.key});

  @override
  State<AppearancePage> createState() => _AppearancePageState();
}

class _AppearancePageState extends State<AppearancePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();
  
  String? _previewFrame; // لمعاينة الإطار
  String? _previewBadge; // لمعاينة الشارة

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // اعتماد وتفعيل المظهر المختار في البروفايل العالمي
  Future<void> _applyAppearance() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    Map<String, dynamic> updates = {};
    if (_previewFrame != null) updates['currentFrame'] = _previewFrame;
    if (_previewBadge != null) updates['activeBadge'] = _previewBadge;

    if (updates.isNotEmpty) {
      await _db.collection('users').doc(user.uid).update(updates);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تفعيل المظهر الملكي الجديد بنجاح! 👑'), backgroundColor: Colors.green),
        );
        setState(() {
          _previewFrame = null;
          _previewBadge = null;
        });
      }
    }
  }

  // حذف مقتنى من القائمة بشكل نهائي
  Future<void> _deleteInventoryItem(String docId, String type) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('حذف مقتنى ملكي', style: TextStyle(color: Colors.white)),
        content: const Text('هل أنت متأكد من حذف هذا العنصر نهائياً من مقتنياتك؟ لا يمكن التراجع عن هذا الفعل.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف نهائياً', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _db.collection('users').doc(user.uid).collection('inventory').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إزالة العنصر من مقتنياتك ✅')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAuth = FirebaseAuth.instance.currentUser;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: StreamBuilder<UserModel>(
        stream: userAuth != null ? _firestoreService.streamUserData(userAuth.uid) : null,
        builder: (context, snapshot) {
          final userData = snapshot.data;
          if (snapshot.connectionState == ConnectionState.waiting || userData == null) {
            return const Scaffold(backgroundColor: Color(0xFF021412), body: Center(child: CircularProgressIndicator(color: Colors.amber)));
          }

          return Scaffold(
            body: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF042F2C), Color(0xFF021412)],
                    ),
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(),
                      _buildLivePreviewBox(userData),
                      _buildTabs(),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildInventorySection(userData, 'frame'),
                            _buildInventorySection(userData, 'badge'),
                            _buildInventorySection(userData, 'vehicle'),
                            _buildInventorySection(userData, 'cover'),
                            _buildInventorySection(userData, 'bubble'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
          const Text('مقتنياتي الملكية', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const Icon(Icons.inventory_2_rounded, color: Colors.amber),
        ],
      ),
    );
  }

  Widget _buildLivePreviewBox(UserModel userData) {
    String displayFrame = _previewFrame ?? userData.currentFrame ?? '';
    String displayBadge = _previewBadge ?? userData.activeBadge ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.amber.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: Colors.white10,
                backgroundImage: userData.profilePic.isNotEmpty ? NetworkImage(userData.profilePic) : null,
                child: userData.profilePic.isEmpty ? const Icon(Icons.person, color: Colors.white24, size: 40) : null,
              ),
              if (displayFrame.isNotEmpty)
                Image.network(displayFrame, width: 110, height: 110, fit: BoxFit.contain),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(userData.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              if (displayBadge.isNotEmpty) ...[
                const SizedBox(width: 5),
                Text(displayBadge, style: const TextStyle(fontSize: 18)),
              ]
            ],
          ),
          const SizedBox(height: 5),
          const Text('معاينة المظهر المختار', style: TextStyle(color: Colors.white38, fontSize: 11)),
          if (_previewFrame != null || _previewBadge != null) ...[
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: _applyAppearance,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              child: const Text('اعتماد وتفعيل الآن', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      indicatorColor: Colors.amber,
      labelColor: Colors.amber,
      unselectedLabelColor: Colors.white38,
      tabs: const [
        Tab(text: 'الإطارات'),
        Tab(text: 'الشارات'),
        Tab(text: 'المركبات'),
        Tab(text: 'الأغلفة'),
        Tab(text: 'الفقاعات'),
      ],
    );
  }

  Widget _buildInventorySection(UserModel userData, String type) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('users').doc(userData.uid).collection('inventory').where('type', isEqualTo: type).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));
        final items = snapshot.data!.docs;

        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_basket_outlined, size: 60, color: Colors.white10),
                const SizedBox(height: 10),
                const Text('لا تملك مقتنيات هنا حالياً', style: TextStyle(color: Colors.white24)),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('اذهب للمتجر للتسوق 🛍️', style: TextStyle(color: Colors.amber))),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.85),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final doc = items[index];
            final item = doc.data() as Map<String, dynamic>;
            
            bool isEquipped = false;
            if (type == 'frame') isEquipped = userData.currentFrame == item['imageUrl'];
            if (type == 'badge') isEquipped = userData.activeBadge == item['icon'];
            
            return _buildItemCard(doc.id, item, isEquipped, type);
          },
        );
      }
    );
  }

  Widget _buildItemCard(String docId, Map<String, dynamic> item, bool isEquipped, String type) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: isEquipped ? Colors.amber : Colors.white.withOpacity(0.05), width: isEquipped ? 2 : 1),
      ),
      child: Stack(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                if (type == 'frame') {
                  _previewFrame = item['imageUrl'];
                } else if (type == 'badge') {
                  _previewBadge = item['icon'];
                }
              });
            },
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (type == 'badge')
                    Text(item['icon'] ?? '🛡️', style: const TextStyle(fontSize: 40))
                  else
                    Image.network(item['imageUrl'] ?? '', width: 60, height: 60, fit: BoxFit.contain, errorBuilder: (c,e,s) => const Icon(Icons.image, color: Colors.white10)),
                  
                  const SizedBox(height: 10),
                  Text(item['name'] ?? 'مقتنى ملكي', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (isEquipped)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(8)),
                      child: const Text('مُفعل', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                    )
                  else
                    Text('تملكه ✅', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10)),
                ],
              ),
            ),
          ),
          Positioned(
            top: 5,
            right: 5,
            child: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
              onPressed: () => _deleteInventoryItem(docId, type),
            ),
          ),
        ],
      ),
    );
  }
}
