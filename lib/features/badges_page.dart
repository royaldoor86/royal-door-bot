import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

class BadgesPage extends StatefulWidget {
  const BadgesPage({super.key});

  @override
  State<BadgesPage> createState() => _BadgesPageState();
}

class _BadgesPageState extends State<BadgesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  final List<Map<String, String>> allAvailableBadges = [
    {'name': 'فخر السعودية', 'icon': '🇸🇦', 'category': 'achievement'},
    {'name': 'نجمة العراق', 'icon': '🇮🇶', 'category': 'achievement'},
    {'name': 'فخر مصر', 'icon': '🇪🇬', 'category': 'achievement'},
    {'name': 'فخر الكويت', 'icon': '🇰🇼', 'category': 'achievement'},
    {'name': 'فخر الإمارات', 'icon': '🇦🇪', 'category': 'achievement'},
    {'name': 'فخر قطر', 'icon': '🇶🇦', 'category': 'achievement'},
    {'name': 'فخر عمان', 'icon': '🇴🇲', 'category': 'achievement'},
    {'name': 'نجم الأردن', 'icon': '🇯🇴', 'category': 'achievement'},
    {'name': 'نجم فلسطيني', 'icon': '🇵🇸', 'category': 'achievement'},
    {'name': 'نجم سوريا', 'icon': '🇸🇾', 'category': 'achievement'},
    {'name': 'نجم لبنان', 'icon': '🇱🇧', 'category': 'achievement'},
    {'name': 'فخر الجزائر', 'icon': '🇩🇿', 'category': 'achievement'},
    {'name': 'فخر المغرب', 'icon': '🇲🇦', 'category': 'achievement'},
    {'name': 'فخر تونس', 'icon': '🇹🇳', 'category': 'achievement'},
    {'name': 'نجم ليبيا', 'icon': '🇱🇾', 'category': 'achievement'},
    {'name': 'نجم يمني', 'icon': '🇾🇪', 'category': 'achievement'},
    {'name': 'فخر السودان', 'icon': '🇸🇩', 'category': 'achievement'},
    {'name': 'الملك الذهبي', 'icon': '👑', 'category': 'badge'},
    {'name': 'درع رويال', 'icon': '🛡️', 'category': 'badge'},
    {'name': 'المتفاعل الأول', 'icon': '🔥', 'category': 'activity'},
  ];

  Future<void> _equipBadge(String badgeIcon) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _db.collection('users').doc(user.uid).update({'activeBadge': badgeIcon});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تفعيل الشارة بنجاح! 🏆'), backgroundColor: Colors.amber));
    }
  }

  void _showBadgeDetails(String name, String icon, bool isOwned, String? currentActiveBadge) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D140F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 70)),
            const SizedBox(height: 15),
            Text(name, style: const TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(isOwned ? 'أنت تمتلك هذه الشارة ✅' : 'هذه الشارة مقفلة حالياً 🔒', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            if (isOwned)
              ElevatedButton(
                onPressed: () { _equipBadge(icon); Navigator.pop(context); },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                child: const Text('ارتداء الشارة', style: TextStyle(color: Colors.black)),
              )
            else
              const Text('يمكنك الحصول عليها من خلال زيادة نشاطك أو الفوز في المسابقات', textAlign: TextAlign.center, style: TextStyle(color: Colors.white38, fontSize: 12)),
          ],
        ),
      ),
    );
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
          if (userData == null) return const Scaffold(backgroundColor: Color(0xFF2D140F), body: Center(child: CircularProgressIndicator(color: Colors.amber)));

          return Scaffold(
            body: Stack(
              children: [
                Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF4E2A1E), Color(0xFF2D140F)]))),
                SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(userData),
                      _buildTabs(),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _db.collection('users').doc(userData.uid).collection('inventory').snapshots(),
                          builder: (context, invSnapshot) {
                            // تم إصلاح الخطأ هنا: التحقق من وجود الحقل "icon" بأمان
                            final ownedIcons = invSnapshot.data?.docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return data.containsKey('icon') ? data['icon'] as String : '';
                            }).where((icon) => icon.isNotEmpty).toList() ?? [];
                            
                            return TabBarView(
                              controller: _tabController,
                              children: [
                                _buildCategoryGrid(userData, 'achievement', ownedIcons),
                                _buildCategoryGrid(userData, 'badge', ownedIcons),
                                _buildCategoryGrid(userData, 'activity', ownedIcons),
                              ],
                            );
                          }
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

  Widget _buildHeader(UserModel userData) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
            const Text('معرض الشارات', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const Icon(Icons.workspace_premium, color: Colors.amber),
          ]),
          const SizedBox(height: 15),
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white10,
            backgroundImage: userData.profilePic.isNotEmpty ? NetworkImage(userData.profilePic) : null,
            child: userData.profilePic.isEmpty ? const Icon(Icons.person, color: Colors.white24, size: 40) : null,
          ),
          const SizedBox(height: 10),
          Text(userData.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          if (userData.activeBadge != null) 
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('الشارة الحالية: ', style: TextStyle(color: Colors.white54, fontSize: 12)),
                Text(userData.activeBadge!, style: const TextStyle(fontSize: 16)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return TabBar(
      controller: _tabController,
      indicatorColor: Colors.amber,
      labelColor: Colors.amber,
      unselectedLabelColor: Colors.white38,
      tabs: const [Tab(text: 'إنجازات'), Tab(text: 'فخري'), Tab(text: 'نشاط')],
    );
  }

  Widget _buildCategoryGrid(UserModel userData, String category, List<String> ownedIcons) {
    final categoryBadges = allAvailableBadges.where((b) => b['category'] == category).toList();

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.8, crossAxisSpacing: 15, mainAxisSpacing: 15),
      itemCount: categoryBadges.length,
      itemBuilder: (context, index) {
        final badge = categoryBadges[index];
        final bool isOwned = ownedIcons.contains(badge['icon']);
        final bool isActive = userData.activeBadge == badge['icon'];

        return GestureDetector(
          onTap: () => _showBadgeDetails(badge['name']!, badge['icon']!, isOwned, userData.activeBadge),
          child: Container(
            decoration: BoxDecoration(
              color: isOwned ? Colors.white.withOpacity(0.1) : Colors.black26,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: isActive ? Colors.amber : (isOwned ? Colors.white24 : Colors.transparent), width: isActive ? 2 : 1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Opacity(
                  opacity: isOwned ? 1.0 : 0.3,
                  child: Text(badge['icon']!, style: const TextStyle(fontSize: 35)),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(badge['name']!, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isOwned ? Colors.white : Colors.white38, fontSize: 10)),
                ),
                if (isActive) 
                  const Text('مُفعل', style: TextStyle(color: Colors.amber, fontSize: 8, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }
}
