import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_manager.dart';
import '../services/firestore_service.dart';
import '../services/vip_privilege_service.dart';
import '../models/user_model.dart';

class VipCenterPage extends StatefulWidget {
  const VipCenterPage({super.key});

  @override
  State<VipCenterPage> createState() => _VipCenterPageState();
}

class _VipCenterPageState extends State<VipCenterPage> {
  final FirestoreService _firestoreService = FirestoreService();
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = AdManager().getBannerAd(
      size: AdSize.banner,
      onAdLoaded: () {
        setState(() {
          _isAdLoaded = true;
        });
      },
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _toggleIncognito(bool currentStatus, String uid) async {
    final success = await VIPPrivilegeService.toggleVIPIncognito(uid);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(success
                ? (!currentStatus
                    ? 'تم تفعيل وضع التخفي الملكي 👤'
                    : 'تم إيقاف وضع التخفي')
                : 'لا يمكن استخدام وضع التخفي - يجب أن تكون VIP فضي أو أعلى'),
            backgroundColor: success ? Colors.amber : Colors.red),
      );
    }
  }

  Future<void> _activateVerification(String uid) async {
    final success = await VIPPrivilegeService.activateVIPVerification(uid);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(success
                ? 'تم تفعيل توثيق الحساب الملكي ✅'
                : 'لا يمكن تفعيل التوثيق - يجب أن تكون VIP برونزي أو أعلى'),
            backgroundColor: success ? Colors.green : Colors.red),
      );
    }
  }

  Future<void> _checkAnimatedFrame(String uid) async {
    final hasFrame = await VIPPrivilegeService.hasAnimatedFrame(uid);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(hasFrame
                ? 'لديك إطار متحرك ملكي ✨'
                : 'لا يوجد إطار متحرك - يجب أن تكون VIP فضي أو أعلى'),
            backgroundColor: hasFrame ? Colors.purple : Colors.grey),
      );
    }
  }

  Future<void> _checkKickProtection(String uid) async {
    final hasProtection = await VIPPrivilegeService.hasVIPKickProtection(uid);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(hasProtection
                ? 'لديك حماية الطرد الملكية 🛡️'
                : 'لا يوجد حماية الطرد - يجب أن تكون VIP برونزي أو أعلى'),
            backgroundColor: hasProtection ? Colors.blue : Colors.grey),
      );
    }
  }

  Future<void> _checkXPBoost(String uid) async {
    final multiplier = await VIPPrivilegeService.getXPMultiplier(uid);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'مضاعف الخبرة الحالي: ${multiplier}x ${multiplier > 1 ? '✨' : ''}'),
            backgroundColor: multiplier > 1 ? Colors.orange : Colors.grey),
      );
    }
  }

  Future<void> _checkPrioritySupport(String uid) async {
    final hasSupport = await VIPPrivilegeService.hasPrioritySupport(uid);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(hasSupport
                ? 'لديك دعم أولوية VIP 🎯'
                : 'لا يوجد دعم أولوية - يجب أن تكون VIP بلاتيني'),
            backgroundColor: hasSupport ? Colors.green : Colors.grey),
      );
    }
  }

  Future<void> _checkStoreDiscount(String uid) async {
    final discount = await VIPPrivilegeService.getStoreDiscount(uid);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'خصم المتجر الحالي: ${(discount * 100).toInt()}% ${discount > 0 ? '🏷️' : ''}'),
            backgroundColor: discount > 0 ? Colors.redAccent : Colors.grey),
      );
    }
  }

  Future<void> _claimDailyGifts(String uid) async {
    final success = await VIPPrivilegeService.sendVIPDailyGifts(uid);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(success
                ? 'تم إرسال هدايا VIP اليومية 🎁'
                : 'لا يمكن إرسال الهدايا - يجب أن تكون VIP ذهبي أو أعلى'),
            backgroundColor: success ? Colors.pink : Colors.grey),
      );
    }
  }

  Future<void> _checkEntryEffect(String uid) async {
    final hasEffect = await VIPPrivilegeService.hasRoyalEntryEffect(uid);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(hasEffect
                ? 'لديك تأثير الدخول الملكي ✨'
                : 'لا يوجد تأثير الدخول - يجب أن تكون VIP بلاتيني'),
            backgroundColor: hasEffect ? Colors.cyanAccent : Colors.grey),
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
                  backgroundColor: Color(0xFF121212),
                  body: Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFFE0C080))));
            }

            bool isVip =
                userData.isVipActive; // استخدام الحقل الصحيح لتفعيل VIP
            String vipStatus = isVip ? 'عضوية نشطة ✨' : 'غير نشط حالياً';

            return Scaffold(
              backgroundColor: const Color(0xFF121212),
              bottomNavigationBar: _isAdLoaded && _bannerAd != null
                  ? Container(
                      color: const Color(0xFF121212),
                      height: _bannerAd!.size.height.toDouble(),
                      width: _bannerAd!.size.width.toDouble(),
                      child: AdWidget(ad: _bannerAd!),
                    )
                  : null,
              appBar: AppBar(
                title: const Text('مركز VIP الملكي',
                    style: TextStyle(
                        color: Color(0xFFE0C080), fontWeight: FontWeight.bold)),
                centerTitle: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: const IconThemeData(color: Color(0xFFE0C080)),
              ),
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildVipCard(userData, vipStatus, isVip),
                    const SizedBox(height: 30),
                    _buildSectionTitle('امتيازات النخبة الحالية'),
                    _buildPerksGrid(userData, isVip),
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFFE0C080)
                                  .withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.info_outline,
                                color: Color(0xFFE0C080), size: 30),
                            const SizedBox(height: 10),
                            Text(
                              isVip
                                  ? 'أهلاً بك يا ${userData.name}! جميع امتيازاتك الملكية مفعلة وتعمل الآن. استمتع بمكانتك في رويال دور.'
                                  : 'اشترك الآن لتصبح جزءاً من النخبة الملكية وتحصل على حماية كاملة ومميزات حصرية.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            );
          }),
    );
  }

  Widget _buildVipCard(UserModel user, String status, bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isActive
              ? [
                  const Color(0xFFD4AF37),
                  const Color(0xFFB8860B),
                  const Color(0xFF8A6E2F)
                ]
              : [const Color(0xFF3A3A3A), const Color(0xFF000000)],
        ),
        border: Border.all(
            color: const Color(0xFFE0C080).withValues(alpha: 0.5), width: 2),
        boxShadow: [
          BoxShadow(
              color: (isActive ? Colors.amber : Colors.black)
                  .withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 5)
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(Icons.workspace_premium,
                size: 150, color: Colors.white.withValues(alpha: 0.1)),
          ),
          Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('عضوية ROYAL VIP',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2)),
                    Icon(isActive ? Icons.stars : Icons.stars_outlined,
                        color: Colors.white, size: 40),
                  ],
                ),
                const SizedBox(height: 20),
                Text(user.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900)),
                Text('الحالة: $status',
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 14)),
                if (isActive && user.vipExpiryDate != null) ...[
                  const SizedBox(height: 8),
                  Text('ينتهي: ${_formatDate(user.vipExpiryDate!)}',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
                const SizedBox(height: 20),
                if (isActive) ...[
                  Text('الباقة: ${user.vipRank ?? "VIP"}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: 0.4,
                      backgroundColor: Colors.black26,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withValues(alpha: 0.8)),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                      'سيتم الترقية لـ VIP 2 تلقائياً عند تجديد الاشتراك',
                      style: TextStyle(color: Colors.white54, fontSize: 10)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: Align(
          alignment: Alignment.centerRight,
          child: Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildPerksGrid(UserModel user, bool isVip) {
    final bool isIncognito = user.agentData?['isIncognito'] ?? false;

    final List<Map<String, dynamic>> perks = [
      {
        'icon': Icons.verified,
        'title': 'توثيق الحساب',
        'color': Colors.amber,
        'desc': 'شارة ملكية 👑',
        'onTap': () => _activateVerification(user.uid)
      },
      {
        'icon': Icons.animation,
        'title': 'إطار متحرك',
        'color': Colors.purpleAccent,
        'desc': 'حصري للنخبة',
        'onTap': () => _checkAnimatedFrame(user.uid)
      },
      {
        'icon': Icons.security,
        'title': 'حماية الطرد',
        'color': Colors.blue,
        'desc': 'درع ملكي 🛡️',
        'onTap': () => _checkKickProtection(user.uid)
      },
      {
        'icon': Icons.visibility_off,
        'title': 'وضع التخفي',
        'color': Colors.grey,
        'desc': isIncognito ? 'نشط ✅' : 'تفعيل التخفي',
        'onTap': () => _toggleIncognito(isIncognito, user.uid)
      },
      {
        'icon': Icons.rocket_launch,
        'title': 'تسريع المستوى',
        'color': Colors.orange,
        'desc': 'X2 خبرة ✨',
        'onTap': () => _checkXPBoost(user.uid)
      },
      {
        'icon': Icons.support_agent,
        'title': 'دعم أولوية',
        'color': Colors.green,
        'desc': 'استجابة فورية',
        'onTap': () => _checkPrioritySupport(user.uid)
      },
      {
        'icon': Icons.local_offer,
        'title': 'خصومات',
        'color': Colors.redAccent,
        'desc': '20% للمتجر',
        'onTap': () => _checkStoreDiscount(user.uid)
      },
      {
        'icon': Icons.card_giftcard,
        'title': 'هدايا حصرية',
        'color': Colors.pink,
        'desc': 'يومياً 🎁',
        'onTap': () => _claimDailyGifts(user.uid)
      },
      {
        'icon': Icons.auto_awesome,
        'title': 'تأثير دخول',
        'color': Colors.cyanAccent,
        'desc': 'بروتوكول ملكي',
        'onTap': () => _checkEntryEffect(user.uid)
      },
    ];

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.8,
          mainAxisSpacing: 15,
          crossAxisSpacing: 15),
      itemCount: perks.length,
      itemBuilder: (context, index) {
        bool hasTap = perks[index].containsKey('onTap');
        return GestureDetector(
          onTap: (isVip && hasTap) ? perks[index]['onTap'] : null,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                  color: isVip
                      ? perks[index]['color'].withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(perks[index]['icon'],
                    color: isVip ? perks[index]['color'] : Colors.grey,
                    size: 30),
                const SizedBox(height: 8),
                Text(perks[index]['title'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: isVip ? Colors.white : Colors.grey,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(perks[index]['desc'],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: isVip
                            ? Colors.amber.withValues(alpha: 0.7)
                            : Colors.white24,
                        fontSize: 9)),
              ],
            ),
          ),
        );
      },
    );
  }
}
