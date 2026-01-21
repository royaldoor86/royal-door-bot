import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

class VipSubscriptionPage extends StatefulWidget {
  const VipSubscriptionPage({super.key});

  @override
  State<VipSubscriptionPage> createState() => _VipSubscriptionPageState();
}

class _VipSubscriptionPageState extends State<VipSubscriptionPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  final List<Map<String, dynamic>> _vipPackages = [
    {
      'name': 'الفيروز',
      'image': 'assets/vip/turquoise.png',
      'price': 250000,
      'level': 5,
      'royalId': '555555',
      'mics': 30,
      'friends': 200,
      'boost': 1.05,
      'color': const Color(0xFF00ACC1),
      'desc': 'بداية الدخول لعالم النخبة بامتيازات أساسية.',
      'powers': ['شارة VIP', 'توثيق حساب', 'تأثير دخول']
    },
    {
      'name': 'اللؤلؤ',
      'image': 'assets/vip/1.png',
      'price': 400000,
      'level': 10,
      'royalId': '444444',
      'mics': 40,
      'friends': 700,
      'boost': 1.10,
      'color': const Color(0xFFE0E0E0),
      'desc': 'تألق ببريق اللؤلؤ وافتح آفاقاً جديدة.',
      'powers': ['شارة VIP', 'توثيق حساب', 'تأثير دخول فاخر']
    },
    {
      'name': 'الياقوت',
      'image': 'assets/vip/ruby.png',
      'price': 500000,
      'level': 12,
      'royalId': '333333',
      'mics': 60,
      'friends': 800,
      'boost': 1.15,
      'color': const Color(0xFFD81B60),
      'desc': 'القوة والهيبة في باقة الياقوت الفاخرة.',
      'powers': ['درع الحصانة 🛡️', 'أولوية المايك 🎤', 'توثيق ذهبي']
    },
    {
      'name': 'الزمرد',
      'image': 'assets/vip/coral.png',
      'price': 750000,
      'level': 15,
      'royalId': '222222',
      'mics': 80,
      'friends': 900,
      'boost': 1.20,
      'color': const Color(0xFF2E7D32),
      'desc': 'باقة الزمرد للباحثين عن التميز المطلق والخصوصية.',
      'powers': ['درع الطرد 🛡️', 'وضع التخفي 👤', 'رادار الأشباح 📡', 'أرباح مضاعفة']
    },
    {
      'name': 'Royal Door',
      'image': 'assets/vip/royal.png',
      'price': 1000000,
      'level': 20,
      'royalId': '111111',
      'mics': 100,
      'friends': 1000,
      'boost': 1.25,
      'color': const Color(0xFFFFD700),
      'desc': 'السيادة الملكية المطلقة - التحكم في قوانين التطبيق.',
      'powers': ['إعلان دخول عالمي 📢', 'تجاوز قفل الغرف 🔐', 'المايك الملكي #1', 'السيادة الكاملة 👑']
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _vipPackages.length, vsync: this, initialIndex: 4);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _purchaseVip(Map<String, dynamic> package, UserModel userData) async {
    int price = package['price'];
    if (userData.gems < price || userData.coins < price) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('رصيد الجواهر أو الكوينز غير كافٍ لتفعيل هذه الباقة الملكية ❌'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF380621),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('مرسوم السيادة: باقة ${package['name']}', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
        content: Text('هل تريد خصم $price جوهرة و $price كوينز لتفعيل باقة (${package['name']})؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء', style: TextStyle(color: Colors.white24))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text('تأكيد التفعيل', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _db.runTransaction((tx) async {
          final userRef = _db.collection('users').doc(userData.uid);
          tx.update(userRef, {
            'gems': userData.gems - price,
            'coins': userData.coins - price,
            'vipRank': package['name'],
            'royalId': package['royalId'],
            'accountLevel': package['level'],
            'isVerified': true,
            'maxFriends': package['friends'],
            'maxMics': package['mics'],
            'investmentBoost': package['boost'],
            'hasAntiKick': package['name'] == 'Royal Door' || package['name'] == 'الزمرد' || package['name'] == 'الياقوت',
            'canBypassLocks': package['name'] == 'Royal Door',
            'hasGlobalArrival': package['name'] == 'Royal Door',
            'canSeeInvisible': package['name'] == 'Royal Door' || package['name'] == 'الزمرد',
            'hasGlowingName': package['name'] == 'Royal Door' || package['name'] == 'الزمرد',
          });
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم تفعيل باقة ${package['name']} بنجاح! انطلق كملك 👑'), backgroundColor: Colors.green));
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء معالجة المرسوم')));
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
          if (userData == null) return const Scaffold(backgroundColor: Color(0xFF2D0518), body: Center(child: CircularProgressIndicator(color: Colors.amber)));

          return Scaffold(
            backgroundColor: const Color(0xFF2D0518),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text('اشتراكات السيادة الملكية VIP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              centerTitle: true,
              bottom: TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Colors.amber,
                labelColor: Colors.amber,
                unselectedLabelColor: Colors.white38,
                tabs: _vipPackages.map((p) => Tab(text: p['name'])).toList(),
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: _vipPackages.map((p) => _buildPackageView(p)).toList(),
            ),
            bottomNavigationBar: _buildActionBtn(userData),
          );
        }
      ),
    );
  }

  Widget _buildPackageView(Map<String, dynamic> p) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [p['color'], p['color'].withValues(alpha: 0.4)]),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [BoxShadow(color: p['color'].withValues(alpha: 0.2), blurRadius: 20)],
            ),
            child: Column(
              children: [
                // استبدال النجمة بصورة الـ VIP
                Image.asset(p['image'], width: 120, height: 120, fit: BoxFit.contain, errorBuilder: (c,e,s) => const Icon(Icons.workspace_premium, size: 80, color: Colors.white)),
                const SizedBox(height: 15),
                Text(p['name'], style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)),
                Text(p['desc'], textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Align(alignment: Alignment.centerRight, child: Text('قوى السيادة الممنوحة:', style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold))),
          const SizedBox(height: 15),
          _feature('المستوى الملكي: ${p['level']} 🏆'),
          _feature('آيدي ملكي ذهبي: ${p['royalId']} 🔥'),
          _feature('ربح إضافي في الاستثمار: +${((p['boost'] - 1) * 100).toInt()}% 💰'),
          ...(p['powers'] as List<String>).map((power) => _feature(power)).toList(),
          const SizedBox(height: 150),
        ],
      ),
    );
  }

  Widget _feature(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20)),
      child: Row(children: [Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14))), const Icon(Icons.check_circle, color: Colors.amber, size: 20)]),
    );
  }

  Widget _buildActionBtn(UserModel user) {
    final p = _vipPackages[_tabController.index];
    int price = p['price'];
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF1F0411), borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30))),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _balItem(user.gems.toString(), 'جواهر', Icons.diamond, Colors.blue),
                  _balItem(user.coins.toString(), 'كوينز', Icons.stars, Colors.amber),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _purchaseVip(p, user),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                child: Column(
                  children: [
                    Text('تفعيل باقة ${p['name']}', style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('بخصم $price جوهرة و $price كوينز', style: const TextStyle(color: Colors.black54, fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _balItem(String val, String label, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 5),
        Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }
}
