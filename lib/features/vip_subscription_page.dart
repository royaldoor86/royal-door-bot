import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../services/ad_manager.dart';
import 'voice_room_page.dart';

class VipSubscriptionPage extends StatefulWidget {
  const VipSubscriptionPage({super.key});

  @override
  State<VipSubscriptionPage> createState() => _VipSubscriptionPageState();
}

class _VipSubscriptionPageState extends State<VipSubscriptionPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  final List<Map<String, dynamic>> _vipPackages = [
    {
      'name': 'الفيروز',
      'image': 'assets/vip/turquoise.png',
      'priceGems': 300000,
      'priceStars': 300000,
      'level': 5,
      'royalId': '555555',
      'mics': 30,
      'friends': 200,
      'boost': 1.05,
      'color': const Color(0xFF00ACC1),
      'desc': 'بداية الدخول لعالم النخبة بامتيازات أساسية.',
      'powers': [
        'شارة VIP',
        'إعلان دخول عالمي 📢',
        'توثيق الحساب ✅',
        'تأثير دخول',
        'غرفه ملكيه 30 مايك',
        'سعة الأصدقاء 200',
        'زيادة المتابعة',
        'موضوعات مميزة',
        'هدايا حصرية',
        'إطارات ملكية',
        'تصدّر كافة الغرف',
        'قفل الغرفة برقم سري'
      ]
    },
    {
      'name': 'الزمرد',
      'image': 'assets/vip/coral.png',
      'priceGems': 400000,
      'priceStars': 400000,
      'level': 8,
      'royalId': '444444',
      'mics': 40,
      'friends': 400,
      'boost': 1.08,
      'color': const Color(0xFF2E7D32),
      'desc': 'باقة الزمرد للباحثين عن التميز والهدوء.',
      'powers': [
        'شارة VIP',
        'إعلان دخول عالمي 📢',
        'توثيق الحساب ✅',
        'درع الطرد 🛡️',
        'غرفه ملكيه 40 مايك',
        'سعة الأصدقاء 400',
        'زيادة المتابعة',
        'موضوعات مميزة',
        'هدايا حصرية',
        'إطارات ملكية',
        'تصدّر كافة الغرف',
        'قفل الغرفة برقم سري'
      ]
    },
    {
      'name': 'اللؤلؤ',
      'image': 'assets/vip/1.png',
      'priceGems': 500000,
      'priceStars': 500000,
      'level': 10,
      'royalId': '333333',
      'mics': 50,
      'friends': 700,
      'boost': 1.10,
      'color': const Color(0xFFE0E0E0),
      'desc': 'تألق ببريق اللؤلؤ وافتح آفاقاً جديدة.',
      'powers': [
        'شارة VIP',
        'إعلان دخول عالمي 📢',
        'توثيق الحساب ✅',
        'تأثير دخول فاخر',
        'غرفه ملكيه 50 مايك',
        'سعة الأصدقاء 700',
        'زيادة المتابعة',
        'موضوعات مميزة',
        'هدايا حصرية',
        'إطارات ملكية',
        'تصدّر كافة الغرف',
        'قفل الغرفة برقم سري'
      ]
    },
    {
      'name': 'الياقوت',
      'image': 'assets/vip/ruby.png',
      'priceGems': 750000,
      'priceStars': 750000,
      'level': 15,
      'royalId': '222222',
      'mics': 75,
      'friends': 800,
      'boost': 1.15,
      'color': const Color(0xFFD81B60),
      'desc': 'القوة والهيبة في باقة الياقوت الفاخرة.',
      'powers': [
        'شارة VIP',
        'إعلان دخول عالمي 📢',
        'توثيق الحساب ✅',
        'درع الحصانة 🛡️',
        'أولوية المايك 🎤',
        'توثيق ذهبي',
        'غرفه ملكيه 75 مايك',
        'سعة الأصدقاء 800',
        'زيادة المتابعة',
        'موضوعات مميزة',
        'هدايا حصرية',
        'إطارات ملكية',
        'تصدّر كافة الغرف',
        'قفل الغرفة برقم سري'
      ]
    },
    {
      'name': 'Royal Door',
      'image': 'assets/vip/royal.png',
      'priceGems': 1000000,
      'priceStars': 1000000,
      'level': 20,
      'royalId': '111111',
      'mics': 100,
      'friends': 1000,
      'boost': 1.25,
      'color': const Color(0xFFFFD700),
      'desc': 'السيادة الملكية المطلقة - التحكم في قوانين التطبيق.',
      'powers': [
        'شارة VIP خاصة',
        'إعلان دخول عالمي 📢',
        'توثيق الحساب (العلامة الزرقاء) ✅',
        'المستوى الملكي: 20 🏆',
        'آيدي (ID) ملكي مميز: 111111 🔥',
        'غرفة ملكية خاصة مكونة من 100 مايك',
        'سعة الأصدقاء 1000',
        'شارة ذهبية ملكية',
        'أولوية الدعم الفني',
        'تصدّر كافة الغرف',
        'زيادة المتابعة 1000',
        'تأثيرات دخول فاخرة',
        'موضوعات (Themes) مميزة',
        'هدايا حصرية',
        'إطارات ملكية',
        'قفل الغرفة برقم سري',
        'صورة غلاف متحركة',
        'تجاوز قفل الغرف 🔐',
        'المايك الملكي #1',
        'السيادة الكاملة 👑'
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: _vipPackages.length, vsync: this, initialIndex: 0);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _purchaseVip(
      Map<String, dynamic> package, UserModel userData) async {
    // نستخدم num للتعامل مع أي نوع رقمي قادم من Firestore ثم نحوله لـ int
    int pGems = (package['priceGems'] as num).toInt();
    int pStars = (package['priceStars'] as num).toInt();
    int userGems = (userData.gems as num).toInt();
    int userStars = (userData.stars as num).toInt();

    // طباعة للتحقق في الـ Debug Console
    print("Purchase Attempt: Need Gems:$pGems, Stars:$pStars | User has Gems:$userGems, Stars:$userStars");

    if (userGems < pGems || userStars < pStars) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'رصيد غير كافٍ. تحتاج $pGems جوهرة و $pStars نجمة ⭐. رصيدك الحالي: $userGems جوهرة و $userStars نجمة ⭐.'),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 4),
      ));
      return;
    }

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: package['color'].withValues(alpha: 0.5))),
        title: Text('مرسوم السيادة: باقة ${package['name']}',
            style: TextStyle(
                color: package['color'], fontWeight: FontWeight.bold)),
        content: Text(
            'هل تريد تفعيل باقة (${package['name']}) بخصم $pGems جوهرة و $pStars نجمة ⭐؟ سيتم إنشاء غرفتك الملكية فوراً.',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  const Text('إلغاء', style: TextStyle(color: Colors.white24))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: package['color']),
            child: const Text('تأكيد التفعيل',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _db.runTransaction((tx) async {
          final userRef = _db.collection('users').doc(userData.uid);
          // التحقق مرة أخرى داخل المعاملة لضمان الأمان
          final userSnap = await tx.get(userRef);
          int currentGems = (userSnap.data()?['gems'] as num).toInt();
          int currentStars = (userSnap.data()?['stars'] ?? userSnap.data()?['coins'] ?? 0) as int;

          if (currentGems < pGems || currentStars < pStars) {
             throw Exception("الرصيد غير كافٍ فعلياً في قاعدة البيانات");
          }

          tx.update(userRef, {
            'gems': currentGems - pGems,
            'stars': currentStars - pStars,
            'coins': currentStars - pStars, // Keep coins in sync during transition
            'vipRank': package['name'],
            'royalId': package['royalId'],
            'accountLevel': package['level'],
            'isVerified': true,
            'maxFriends': package['friends'],
            'maxMics': package['mics'],
            'harvestBoost': package['boost'],
            'hasAntiKick': package['name'] == 'Royal Door' ||
                package['name'] == 'الياقوت' ||
                package['name'] == 'الزمرد',
            'canBypassLocks': package['name'] == 'Royal Door',
            'hasGlobalArrival': true,
            'canSeeInvisible':
                package['name'] == 'Royal Door' || package['name'] == 'الزمرد',
            'hasGlowingName':
                package['name'] == 'Royal Door' || package['name'] == 'الزمرد',
          });
        });

        final String roomName = "غرفة الملك ${userData.name}";
        final String roomId = await _firestoreService.createRoom(
          ownerId: userData.uid,
          roomName: roomName,
          maxSeats: package['mics'],
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'تم تفعيل باقة ${package['name']} وإنشاء غرفتك الملكية بنجاح! 👑'),
              backgroundColor: Colors.green));

          // إظهار إعلان ملء الشاشة بعد تفعيل باقة VIP
          AdManager().showInterstitialAd();

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VoiceRoomPage(
                roomId: roomId,
                roomName: roomName,
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('فشل التفعيل: ${e.toString()}')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAuth = FirebaseAuth.instance.currentUser;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: StreamBuilder<UserModel>(
          stream: userAuth != null
              ? _firestoreService.streamUserData(userAuth.uid)
              : null,
          builder: (context, snapshot) {
            final userData = snapshot.data;
            if (userData == null) {
              return const Scaffold(
                  backgroundColor: Color(0xFF0A0A12),
                  body: Center(
                      child: CircularProgressIndicator(color: Colors.amber)));
            }

            return AnimatedBuilder(
                animation: _tabController,
                builder: (context, child) {
                  final currentColor =
                      _vipPackages[_tabController.index]['color'] as Color;
                  return Scaffold(
                    backgroundColor:
                        Color.lerp(const Color(0xFF0A0A12), currentColor, 0.15),
                    appBar: AppBar(
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      title: const Text('اشتراكات السيادة الملكية VIP',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      centerTitle: true,
                      bottom: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        indicatorColor: currentColor,
                        labelColor: currentColor,
                        unselectedLabelColor: Colors.white24,
                        tabs: _vipPackages
                            .map((p) => Tab(text: p['name']))
                            .toList(),
                      ),
                    ),
                    body: TabBarView(
                      controller: _tabController,
                      children: _vipPackages
                          .map((p) => _buildPackageView(p))
                          .toList(),
                    ),
                    bottomNavigationBar:
                        _buildActionBtn(userData, currentColor),
                  );
                });
          }),
    );
  }

  Widget _buildPackageView(Map<String, dynamic> p) {
    final Color pColor = p['color'] as Color;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [pColor, pColor.withValues(alpha: 0.3)]),
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                BoxShadow(
                    color: pColor.withValues(alpha: 0.2),
                    blurRadius: 30,
                    spreadRadius: 2)
              ],
            ),
            child: Column(
              children: [
                Image.asset(p['image'] as String,
                    width: 140,
                    height: 140,
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => Icon(Icons.workspace_premium,
                        size: 100, color: pColor)),
                const SizedBox(height: 20),
                Text(p['name'] as String,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5)),
                const SizedBox(height: 5),
                Text(p['desc'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8), fontSize: 14)),
              ],
            ),
          ),
          const SizedBox(height: 35),
          Align(
              alignment: Alignment.centerRight,
              child: Text('قوى السيادة الممنوحة لـ ${p['name']}:',
                  style: TextStyle(
                      color: pColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold))),
          const SizedBox(height: 20),
          _feature('المستوى الملكي: ${p['level']} 🏆', pColor),
          _feature('آيدي ملكي ذهبي: ${p['royalId']} 🔥', pColor),
          _feature(
              'مكافأة إضافية في الحصاد: +${(((p['boost'] as double) - 1) * 100).toInt()}% 🌟',
              pColor),
          ...(p['powers'] as List<String>)
              .map((power) => _feature(power, pColor))
              ,
          const SizedBox(height: 150),
        ],
      ),
    );
  }

  Widget _feature(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.1))),
      child: Row(children: [
        Expanded(
            child: Text(text,
                style: const TextStyle(color: Colors.white, fontSize: 14))),
        Icon(Icons.verified_rounded, color: color, size: 22)
      ]),
    );
  }

  Widget _buildActionBtn(UserModel user, Color currentColor) {
    final p = _vipPackages[_tabController.index];
    int pGems = (p['priceGems'] as num).toInt();
    int pStars = (p['priceStars'] as num).toInt();

    return Container(
      decoration: BoxDecoration(
          color: const Color(0xFF0A0A12),
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(35), topRight: Radius.circular(35)),
          border:
              Border(top: BorderSide(color: currentColor.withValues(alpha: 0.2)))),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(25, 20, 25, 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _balItem(user.gems.toString(), 'جواهر', Icons.diamond,
                      Colors.blue),
                  _balItem(user.stars.toString(), 'نجمة ⭐', Icons.stars_rounded,
                      Colors.amber),
                ],
              ),
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: () => _purchaseVip(p, user),
                style: ElevatedButton.styleFrom(
                    backgroundColor: currentColor,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                    elevation: 10,
                    shadowColor: currentColor.withValues(alpha: 0.5)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('تفعيل باقة ${p['name']}',
                        style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    Text('بخصم $pGems جوهرة و $pStars نجمة ⭐',
                        style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(val,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          const SizedBox(width: 5),
          Text(label,
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }
}
