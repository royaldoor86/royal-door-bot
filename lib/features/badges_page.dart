import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/firestore_service.dart';
import '../services/badge_service.dart';
import '../models/user_model.dart';

class BadgesPage extends StatefulWidget {
  const BadgesPage({super.key});

  @override
  State<BadgesPage> createState() => _BadgesPageState();
}

class _BadgesPageState extends State<BadgesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // القائمة الأساسية للأعلام والشارات الثابتة
  final List<Map<String, dynamic>> staticBadges = [
    {'name': 'فخر السعودية', 'icon': '🇸🇦', 'category': 'achievement', 'isImage': false},
    {'name': 'نجم العراق', 'icon': '🇮🇶', 'category': 'achievement', 'isImage': false},
    {'name': 'فخر مصر', 'icon': '🇪🇬', 'category': 'achievement', 'isImage': false},
    {'name': 'فخر الكويت', 'icon': '🇰🇼', 'category': 'achievement', 'isImage': false},
    {'name': 'فخر الإمارات', 'icon': '🇦🇪', 'category': 'achievement', 'isImage': false},
    {'name': 'فخر قطر', 'icon': '🇶🇦', 'category': 'achievement', 'isImage': false},
    {'name': 'فخر عمان', 'icon': '🇴🇲', 'category': 'achievement', 'isImage': false},
    {'name': 'نجم الأردن', 'icon': '🇯🇴', 'category': 'achievement', 'isImage': false},
    {'name': 'نجم فلسطيني', 'icon': '🇵🇸', 'category': 'achievement', 'isImage': false},
    {'name': 'نجم سوريا', 'icon': '🇸🇾', 'category': 'achievement', 'isImage': false},
    {'name': 'نجم لبنان', 'icon': '🇱🇧', 'category': 'achievement', 'isImage': false},
    {'name': 'فخر الجزائر', 'icon': '🇩🇿', 'category': 'achievement', 'isImage': false},
    {'name': 'فخر المغرب', 'icon': '🇲🇦', 'category': 'achievement', 'isImage': false},
    {'name': 'فخر تونس', 'icon': '🇹🇳', 'category': 'achievement', 'isImage': false},
    {'name': 'نجم ليبيا', 'icon': '🇱🇾', 'category': 'achievement', 'isImage': false},
    {'name': 'نجم يمني', 'icon': '🇾🇪', 'category': 'achievement', 'isImage': false},
    {'name': 'فخر السودان', 'icon': '🇸🇩', 'category': 'achievement', 'isImage': false},
    {'name': 'الملك الذهبي', 'icon': '👑', 'category': 'badge', 'isImage': false},
    {'name': 'درع رويال', 'icon': '🛡️', 'category': 'badge', 'isImage': false},
    {'name': 'المتفاعل الأول', 'icon': '🔥', 'category': 'activity', 'isImage': false},
  ];

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

  Future<void> _equipBadge(String badgeName, String badgeIcon, String category, bool isImage) async {
    try {
      await BadgeService.equipBadge(
        badgeName: badgeName,
        badgeIcon: badgeIcon,
        category: category,
        isImage: isImage,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم تفعيل الشارة الملكية بنجاح! 🏆'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل التفعيل: $e')));
      }
    }
  }

  void _showBadgeDetails(String name, String icon, bool isOwned, bool isImage, String category) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
            side: BorderSide(color: Colors.amber.withValues(alpha: 0.3)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                  boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 5)],
                ),
                child: isImage
                    ? CachedNetworkImage(imageUrl: icon, width: 80, height: 80, fit: BoxFit.contain)
                    : Text(icon, style: const TextStyle(fontSize: 60)),
              ),
              const SizedBox(height: 20),
              Text(name, style: const TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(
                isOwned ? 'أنت تمتلك هذه الشارة الملكية ✅' : 'هذه الشارة مقفلة حالياً 🔒',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 25),
              if (isOwned)
                ElevatedButton(
                  onPressed: () {
                    _equipBadge(name, icon, category, isImage);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text('ارتداء الشارة الآن', style: TextStyle(fontWeight: FontWeight.bold)),
                )
              else
                Column(
                  children: [
                    const Text(
                      'احصل عليها من خلال المتجر، أو ترقية عضويتك لـ رويال VIP، أو الفوز في المسابقات الملكية.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('فهمت', style: TextStyle(color: Colors.amber)),
                    )
                  ],
                ),
            ],
          ),
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
          if (userData == null) {
            return const Scaffold(backgroundColor: Color(0xFF0A0A12), body: Center(child: CircularProgressIndicator(color: Colors.amber)));
          }

          return Scaffold(
            backgroundColor: const Color(0xFF0A0A12),
            body: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF1A1A2E), Color(0xFF0A0A12)],
                    ),
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      _buildHeader(userData),
                      _buildTabs(),
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _db.collection('badges_templates').orderBy('createdAt', descending: true).snapshots(),
                          builder: (context, templatesSnapshot) {
                            return StreamBuilder<QuerySnapshot>(
                              stream: _db.collection('users').doc(userData.uid).collection('inventory').snapshots(),
                              builder: (context, invSnapshot) {
                                final ownedIcons = invSnapshot.data?.docs.map((doc) {
                                  final data = doc.data() as Map<String, dynamic>;
                                  return data['icon'] ?? data['imageUrl'] ?? '';
                                }).where((icon) => icon.toString().isNotEmpty).toList() ?? [];

                                final List<Map<String, dynamic>> dynamicBadges = templatesSnapshot.data?.docs.map((doc) => doc.data() as Map<String, dynamic>).toList() ?? [];

                                // دمج القائمة الثابتة مع الديناميكية
                                final allBadges = [...staticBadges, ...dynamicBadges];

                                return TabBarView(
                                  controller: _tabController,
                                  children: [
                                    _buildCategoryGrid(userData, 'achievement', allBadges, ownedIcons),
                                    _buildCategoryGrid(userData, 'badge', allBadges, ownedIcons),
                                    _buildCategoryGrid(userData, 'activity', allBadges, ownedIcons),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(UserModel userData) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
            const Text('معرض الشارات الملكي', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const Icon(Icons.workspace_premium, color: Colors.amber, size: 30),
          ]),
          const SizedBox(height: 25),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 45,
                backgroundColor: Colors.amber.withValues(alpha: 0.1),
                backgroundImage: userData.profilePic.isNotEmpty ? NetworkImage(userData.profilePic) : null,
                child: userData.profilePic.isEmpty ? const Icon(Icons.person, color: Colors.white24, size: 45) : null,
              ),
              if (userData.isVerified)
                const CircleAvatar(radius: 12, backgroundColor: Colors.blue, child: Icon(Icons.check, color: Colors.white, size: 15)),
            ],
          ),
          const SizedBox(height: 15),
          Text(userData.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          if (userData.activeBadge != null)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3))),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('الشارة الحالية: ', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  _buildActiveBadgeDisplay(userData.activeBadge!),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveBadgeDisplay(String activeBadge) {
    bool isUrl = activeBadge.startsWith('http');
    if (isUrl) {
      return CachedNetworkImage(imageUrl: activeBadge, width: 20, height: 20, fit: BoxFit.contain);
    }
    return Text(activeBadge, style: const TextStyle(fontSize: 16));
  }

  Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(15)),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(borderRadius: BorderRadius.circular(15), color: Colors.amber.withValues(alpha: 0.2)),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.amber,
        unselectedLabelColor: Colors.white38,
        tabs: const [Tab(text: 'أعلام الإنجاز'), Tab(text: 'شارات ملكية'), Tab(text: 'أوسمة النشاط')],
      ),
    );
  }

  Widget _buildCategoryGrid(UserModel userData, String category, List<Map<String, dynamic>> allBadges, List<dynamic> ownedIcons) {
    final categoryBadges = allBadges.where((b) => b['category'] == category).toList();

    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 0.85, crossAxisSpacing: 15, mainAxisSpacing: 15),
      itemCount: categoryBadges.length,
      itemBuilder: (context, index) {
        final badge = categoryBadges[index];
        final String iconData = badge['icon'] ?? '';
        final bool isImage = badge['isImage'] ?? false;

        // الأعلام في قسم الإنجازات تعتبر مفتوحة دائماً للاختيار (مجانية)
        // شارات الـ VIP يتم تفعيلها برمجياً عند الشراء وتظهر في الـ inventory
        final bool isOwned = category == 'achievement' || ownedIcons.contains(iconData);
        final bool isActive = userData.activeBadge == iconData;

        return GestureDetector(
          onTap: () => _showBadgeDetails(badge['name'] ?? '', iconData, isOwned, isImage, category),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: isOwned ? Colors.white.withValues(alpha: 0.08) : Colors.black38,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isActive ? Colors.amber : (isOwned ? Colors.amber.withValues(alpha: 0.3) : Colors.white10), width: isActive ? 2 : 1),
              boxShadow: isActive ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.2), blurRadius: 10)] : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: Opacity(
                      opacity: isOwned ? 1.0 : 0.4,
                      child: isImage ? CachedNetworkImage(imageUrl: iconData, width: 45, height: 45, fit: BoxFit.contain) : Text(iconData, style: const TextStyle(fontSize: 35)),
                    ),
                  ),
                ),
                Text(badge['name'] ?? '', textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isOwned ? Colors.white : Colors.white38, fontSize: 10)),
                if (isActive) const Text('نشط الآن', style: TextStyle(color: Colors.amber, fontSize: 8, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }
}
