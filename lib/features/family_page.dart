import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ad_manager.dart';
import '../services/firestore_service.dart';
import '../services/family_service.dart';
import '../services/storage_service.dart';
import '../models/user_model.dart';
import '../models/family_model.dart';
import '../app_theme.dart';
import 'create_family_page.dart';
import 'manage_family_roles_page.dart';
import 'voice_room_page.dart';
import 'family_store_page.dart';
import 'family_requests_page.dart';
import 'family_tasks_page.dart';
import 'family_notifications_page.dart';
import 'family_leaderboard_page.dart';
import 'family_events_page.dart';
import 'family_badges_page.dart';
import 'family_alliances_page.dart';
import 'family_history_page.dart';
import 'family_challenges_page.dart';
import 'family_branding_page.dart';
import 'family_voting_page.dart';
import 'family_daily_rewards_page.dart';
import 'family_invitation_page.dart';
import '../widgets/feature_lock_wrapper.dart';

class FamilyPage extends StatefulWidget {
  const FamilyPage({super.key});

  @override
  State<FamilyPage> createState() => _FamilyPageState();
}

class _FamilyPageState extends State<FamilyPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final FamilyService _familyService = FamilyService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isDeleting = false;
  int _minLevelFilter = 1;
  bool _isPrivateFilter = false;

  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _initBannerAd();
    _tabController = TabController(length: 8, vsync: this, initialIndex: 1);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });

    // فحص الجوائز المعلقة عند الدخول
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _checkForLevelRewards());
  }

  void _initBannerAd() {
    _bannerAd = AdManager().getBannerAd(
      size: AdSize.banner,
      onAdLoaded: () {
        if (mounted) {
          setState(() {
            _isAdLoaded = true;
          });
        }
      },
    );
  }

  void _checkForLevelRewards() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await _db.collection('users').doc(user.uid).get();
    final familyId = userDoc.data()?['familyId'];

    if (familyId != null && familyId.isNotEmpty) {
      final reward = await _familyService.claimPendingLevelRewards(familyId);
      if (reward != null && mounted) {
        _showRewardDialog(reward);
      }
    }
  }

  void _showRewardDialog(LevelReward reward) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A050E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
          side: const BorderSide(color: Colors.amber, width: 1.5),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.workspace_premium, color: Colors.amber, size: 70),
            const SizedBox(height: 20),
            const Text('مباراك لرفع رتبة العائلة! 👑',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
                'لقد وصلت عائلتك للمستوى (${reward.level}) وحصلت على حصتك من الغنائم:',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _rewardItem('${reward.stars}', 'نجمة ⭐', Colors.amber),
                if (reward.gems > 0)
                  _rewardItem('${reward.gems}', 'جواهر 💎', Colors.cyanAccent),
              ],
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  minimumSize: const Size(120, 45),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15))),
              child: const Text('استلام',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }

  Widget _rewardItem(String val, String label, Color color) {
    return Column(
      children: [
        Text(val,
            style: TextStyle(
                color: color, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating),
    );
  }

  void _showSuccessSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating));
  }

  Future<void> _repairStaleStatus(String uid) async {
    try {
      await _db.collection('users').doc(uid).update(
          {'familyId': FieldValue.delete(), 'familyRole': FieldValue.delete()});
      _showSuccessSnack('تم تحديث حالتك الملكية بنجاح ✅');
    } catch (e) {
      _showErrorSnack('فشل التحديث');
    }
  }

  void _showMoreOptions(FamilyModel family, UserModel user) {
    final isLeader = user.familyRole == 'leader';
    final canManage = isLeader ||
        user.familyRole == 'organizer' ||
        user.familyRole == 'co-leader' ||
        user.familyRole == 'recruiter';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
              color: Color(0xFF1A050E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLeader)
                _optionTile(Icons.manage_accounts, 'إدارة الأدوار', Colors.cyan,
                    () {
                  Navigator.pop(ctx);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              ManageFamilyRolesPage(familyId: family.id)));
                }),
              if (canManage) ...[
                _optionTile(Icons.group_add, 'طلبات الانضمام', Colors.teal, () {
                  Navigator.pop(ctx);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              FamilyRequestsPage(familyId: family.id)));
                }),
                _optionTile(Icons.person_add, 'دعوة عضو جديد', Colors.blue, () {
                  Navigator.pop(ctx);
                  _showInviteDialog(family.id);
                }),
                _optionTile(Icons.people_outline, 'إضافة عضو من الأصدقاء',
                    Colors.purpleAccent, () {
                  Navigator.pop(ctx);
                  _showInviteFromFriends(family.id);
                }),
                _optionTile(Icons.campaign, 'تحديث الإعلان', Colors.orange, () {
                  Navigator.pop(ctx);
                  _showAnnouncementDialog(family);
                }),
                _optionTile(Icons.settings, 'إعدادات المملكة', Colors.grey, () {
                  Navigator.pop(ctx);
                  _showFamilySettings(family, isLeader);
                }),
                _optionTile(
                    Icons.military_tech, 'الشارات والأوسمة', Colors.amber, () {
                  Navigator.pop(ctx);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              FamilyBadgesPage(familyId: family.id)));
                }),
                _optionTile(Icons.handshake, 'التحالفات', Colors.blue, () {
                  Navigator.pop(ctx);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              FamilyAlliancesPage(familyId: family.id)));
                }),
                _optionTile(Icons.history, 'سجل العائلة', Colors.green, () {
                  Navigator.pop(ctx);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              FamilyHistoryPage(familyId: family.id)));
                }),
                _optionTile(
                    Icons.emoji_events, 'التحديات الداخلية', Colors.orange, () {
                  Navigator.pop(ctx);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              FamilyChallengesPage(familyId: family.id)));
                }),
                _optionTile(Icons.palette, 'العلامات التجارية', Colors.purple,
                    () {
                  Navigator.pop(ctx);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              FamilyBrandingPage(familyId: family.id)));
                }),
                _optionTile(
                    Icons.how_to_vote, 'التصويت الديمقراطي', Colors.cyan, () {
                  Navigator.pop(ctx);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              FamilyVotingPage(familyId: family.id)));
                }),
                _optionTile(
                    Icons.card_giftcard, 'المكافآت اليومية', Colors.pink, () {
                  Navigator.pop(ctx);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              FamilyDailyRewardsPage(familyId: family.id)));
                }),
                _optionTile(Icons.mail, 'الدعوات المخصصة', Colors.teal, () {
                  Navigator.pop(ctx);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              FamilyInvitationPage(familyId: family.id)));
                }),
                if (isLeader)
                  _optionTile(Icons.room, 'تعيين غرفة العائلة', Colors.teal,
                      () {
                    Navigator.pop(ctx);
                    _showSetFamilyRoomDialog(family.id);
                  }),
              ],
              _optionTile(Icons.exit_to_app, 'الخروج من العائلة', Colors.red,
                  () {
                Navigator.pop(ctx);
                _leaveFamilyConfirm(family.id);
              }),
              if (isLeader)
                _optionTile(
                    Icons.delete_forever, 'تفكيك العائلة', Colors.redAccent,
                    () {
                  Navigator.pop(ctx);
                  _deleteFamilyConfirm(family.id, family.name);
                }),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionTile(
          IconData icon, String title, Color color, VoidCallback onTap) =>
      ListTile(
          leading: Icon(icon, color: color),
          title: Text(title,
              style: const TextStyle(color: Colors.white, fontSize: 14)),
          onTap: onTap);

  void _showInviteDialog(String familyId) {
    final idController = TextEditingController();
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF1A050E),
                title: const Text('دعوة صديق',
                    style: TextStyle(color: Colors.amber)),
                content: TextField(
                    controller: idController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                        hintText: 'أدخل الآيدي الملكي...')),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('إلغاء')),
                  ElevatedButton(
                      onPressed: () async {
                        try {
                          await _familyService.addMemberByShortId(
                              familyId, idController.text.trim());
                          if (mounted) Navigator.pop(ctx);
                          _showSuccessSnack('تمت الإضافة بنجاح');
                        } catch (e) {
                          _showErrorSnack(e.toString());
                        }
                      },
                      child: const Text('إضافة'))
                ]));
  }

  void _showInviteFromFriends(String familyId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A050E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('إضافة من الأصدقاء',
                style: TextStyle(
                    color: Colors.amber,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _firestoreService
                  .streamFriends(FirebaseAuth.instance.currentUser!.uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final friends = snapshot.data!;
                if (friends.isEmpty) {
                  return const Center(
                      child: Text('لا يوجد أصدقاء حالياً',
                          style: TextStyle(color: Colors.white24)));
                }

                return ListView.builder(
                  itemCount: friends.length,
                  itemBuilder: (context, i) {
                    final friend = friends[i];
                    return ListTile(
                      leading: CircleAvatar(
                          backgroundImage: (Uri.tryParse(friend.profilePic)
                                      ?.host
                                      .isNotEmpty ==
                                  true)
                              ? NetworkImage(friend.profilePic)
                              : null),
                      title: Text(friend.name,
                          style: const TextStyle(color: Colors.white)),
                      subtitle: Text('ID: ${friend.royalId}',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 11)),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black),
                        onPressed: () async {
                          try {
                            await _familyService.acceptJoinRequest(
                                familyId, friend.uid);
                            if (mounted) Navigator.pop(context);
                            _showSuccessSnack(
                                'تمت إضافة ${friend.name} للعائلة');
                          } catch (e) {
                            _showErrorSnack(e.toString());
                          }
                        },
                        child: const Text('إضافة'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAnnouncementDialog(FamilyModel family) {
    final sloganController = TextEditingController(text: family.slogan);
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF1A050E),
                title: const Text('إعلان العائلة',
                    style: TextStyle(color: Colors.amber)),
                content: TextField(
                    controller: sloganController,
                    maxLines: 2,
                    style: const TextStyle(color: Colors.white)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('إلغاء')),
                  ElevatedButton(
                      onPressed: () async {
                        await _familyService.updateFamily(
                            familyId: family.id,
                            slogan: sloganController.text.trim());
                        if (mounted) Navigator.pop(ctx);
                        _showSuccessSnack('تم التحديث');
                      },
                      child: const Text('تحديث'))
                ]));
  }

  void _showFamilySettings(FamilyModel family, bool isLeader) {
    final nameController = TextEditingController(text: family.name);
    final descController = TextEditingController(text: family.description);
    final sloganController = TextEditingController(text: family.slogan);
    bool isPrivate = family.isPrivate;
    File? newLogo;
    bool updating = false;
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => StatefulBuilder(
            builder: (ctx, setModalState) => Container(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                    left: 20,
                    right: 20,
                    top: 20),
                decoration: const BoxDecoration(
                    color: Color(0xFF1A050E),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(30))),
                child: SingleChildScrollView(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('إعدادات المملكة',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    GestureDetector(
                        onTap: () async {
                          final picker = ImagePicker();
                          final image = await picker.pickImage(
                              source: ImageSource.gallery);
                          if (image != null) {
                            setModalState(() => newLogo = File(image.path));
                          }
                        },
                        child: CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.white10,
                            backgroundImage: newLogo != null
                                ? FileImage(newLogo!)
                                : (Uri.tryParse(family.logoUrl)
                                            ?.host
                                            .isNotEmpty ==
                                        true
                                    ? NetworkImage(family.logoUrl)
                                    : null) as ImageProvider?)),
                    const SizedBox(height: 20),
                    AppTheme.royalInputField(
                        controller: nameController,
                        hint: 'اسم العائلة',
                        icon: Icons.shield),
                    const SizedBox(height: 10),
                    AppTheme.royalInputField(
                        controller: sloganController,
                        hint: 'شعار العائلة (Slogan)',
                        icon: Icons.campaign),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'قصة عائلتنا (الوصف)',
                        hintStyle: const TextStyle(color: Colors.white24),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SwitchListTile(
                        title: const Text('عائلة خاصة (تطلب انضمام)',
                            style: TextStyle(color: Colors.white70)),
                        value: isPrivate,
                        onChanged: (v) => setModalState(() => isPrivate = v),
                        activeThumbColor: Colors.amber),
                    const SizedBox(height: 20),
                    updating
                        ? const CircularProgressIndicator()
                        : AppTheme.gradientButton(
                            text: 'حفظ التغييرات',
                            onPressed: () async {
                              setModalState(() => updating = true);
                              String? logoUrl;
                              if (newLogo != null) {
                                logoUrl = await StorageService.uploadFamilyLogo(
                                    family.id, newLogo!);
                              }
                              await _familyService.updateFamily(
                                  familyId: family.id,
                                  name: nameController.text.trim(),
                                  description: descController.text.trim(),
                                  slogan: sloganController.text.trim(),
                                  logoUrl: logoUrl,
                                  isPrivate: isPrivate);
                              if (mounted) Navigator.pop(context);
                              _showSuccessSnack('تم التحديث بنجاح ✅');
                            }),
                    const SizedBox(height: 40)
                  ]),
                ))));
  }

  void _leaveFamilyConfirm(String familyId) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF2A0000),
                title: const Text('الخروج'),
                content:
                    const Text('هل أنت متأكد من رغبتك في الخروج من العائلة؟'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('إلغاء')),
                  ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        try {
                          await _familyService.leaveFamily(familyId);
                          _showSuccessSnack('لقد خرجت من العائلة');
                        } catch (e) {
                          _showErrorSnack(e.toString());
                        }
                      },
                      child: const Text('خروج'))
                ]));
  }

  void _deleteFamilyConfirm(String familyId, String familyName) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                backgroundColor: const Color(0xFF2A0000),
                title: const Text('حذف نهائي'),
                content: Text('هل أنت متأكد من تفكيك عائلة ($familyName)؟'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('إلغاء')),
                  ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        setState(() => _isDeleting = true);
                        await _familyService.deleteFamily(familyId);
                        setState(() => _isDeleting = false);
                        _showSuccessSnack('تم التفكيك');
                      },
                      child: const Text('حذف'))
                ]));
  }

  void _showDonateDialog(FamilyModel family) {
    final amountController = TextEditingController();
    String selectedCurrency = 'gems';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A050E),
          title: const Text('تبرع لخزينة العائلة 💰',
              style: TextStyle(color: Colors.amber)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('ساهم في زيادة ثروة العائلة لفتح مميزات حصرية.',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 20),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    hintText: 'أدخل المبلغ...',
                    hintStyle: TextStyle(color: Colors.white24)),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _currencyOption(
                      'gems',
                      'جواهر 💎',
                      selectedCurrency == 'gems',
                      () => setDialogState(() => selectedCurrency = 'gems')),
                  const SizedBox(width: 10),
                  _currencyOption(
                      'stars',
                      'نجمة ⭐',
                      selectedCurrency == 'stars',
                      () => setDialogState(() => selectedCurrency = 'stars')),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                int amount = int.tryParse(amountController.text) ?? 0;
                if (amount <= 0) return;
                try {
                  await _familyService.donateToFamily(family.id, amount,
                      selectedCurrency == 'stars' ? 'stars' : 'gems');
                  if (mounted) Navigator.pop(ctx);
                  _showSuccessSnack('شكراً لمساهمتك الملكية! ✅');
                } catch (e) {
                  _showErrorSnack(e.toString());
                }
              },
              child: const Text('تبرع الآن'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _currencyOption(
      String id, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.redAccent.withValues(alpha: 0.2)
              : Colors.white10,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: isSelected ? Colors.redAccent : Colors.transparent),
        ),
        child: Text(label,
            style: TextStyle(
                color: isSelected ? Colors.white : Colors.white38,
                fontSize: 12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAuth = FirebaseAuth.instance.currentUser;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: FeatureLockWrapper(
        lockField: 'isFamilyLocked',
        child: Stack(
          children: [
            StreamBuilder<UserModel>(
                stream: userAuth != null
                    ? _firestoreService.streamUserData(userAuth.uid)
                    : null,
                builder: (context, userSnapshot) {
                  if (userSnapshot.hasError) {
                    return Scaffold(
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 50),
                            const SizedBox(height: 15),
                            const Text('حدث خطأ أثناء تحميل بياناتك الملكية',
                                style: TextStyle(color: Colors.white)),
                            TextButton(
                                onPressed: () => setState(() {}),
                                child: const Text('إعادة المحاولة')),
                          ],
                        ),
                      ),
                    );
                  }

                  final userData = userSnapshot.data;
                  if (userSnapshot.connectionState == ConnectionState.waiting ||
                      userData == null) {
                    return const Scaffold(
                        body: Center(
                            child: CircularProgressIndicator(
                                color: Colors.amber)));
                  }

                  bool hasFamily = userData.familyId != null &&
                      userData.familyId!.isNotEmpty;
                  return Scaffold(
                    backgroundColor: const Color(0xFF1A050E),
                    body: Container(
                      decoration: const BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                            Color(0xFF3D0B16),
                            Color(0xFF1A050E),
                            Color(0xFF000000)
                          ])),
                      child: NestedScrollView(
                        physics: const BouncingScrollPhysics(),
                        headerSliverBuilder: (context, innerBoxIsScrolled) => [
                          _buildSliverAppBar(userData),
                          SliverToBoxAdapter(child: _buildSearchBox()),
                          SliverPersistentHeader(
                              pinned: true,
                              delegate: _SliverAppBarDelegate(TabBar(
                                  controller: _tabController,
                                  indicatorColor: Colors.amber,
                                  labelColor: Colors.amber,
                                  unselectedLabelColor: Colors.white38,
                                  physics: const BouncingScrollPhysics(),
                                  isScrollable: true,
                                  tabs: const [
                                    Tab(text: 'أقوى العوائل'),
                                    Tab(text: 'عائلتي'),
                                    Tab(text: 'حروب العوائل'),
                                    Tab(text: 'عن العائلة'),
                                    Tab(text: 'البحث'),
                                    Tab(text: 'الإشعارات'),
                                    Tab(text: 'الترتيب الداخلي'),
                                    Tab(text: 'الأحداث')
                                  ]))),
                        ],
                        body: TabBarView(
                            controller: _tabController,
                            physics: const BouncingScrollPhysics(),
                            children: [
                              _buildTopFamiliesList(hasFamily),
                              _buildMyFamilyView(userData),
                              _buildFamilyWarsView(userData),
                              _buildAboutFamilyView(userData),
                              _buildSearchList(hasFamily),
                              _buildNotificationsView(userData),
                              _buildLeaderboardView(userData),
                              _buildEventsView(userData)
                            ]),
                      ),
                    ),
                    floatingActionButton: !hasFamily
                        ? FloatingActionButton.extended(
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const CreateFamilyPage())),
                            backgroundColor: Colors.redAccent,
                            label: const Text('تأسيس عائلة ملكية',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            icon: const Icon(Icons.shield_rounded,
                                color: Colors.white))
                        : null,
                    bottomNavigationBar: _isAdLoaded && _bannerAd != null
                        ? Container(
                            color: const Color(0xFF1A050E),
                            height: _bannerAd!.size.height.toDouble(),
                            width: _bannerAd!.size.width.toDouble(),
                            child: AdWidget(ad: _bannerAd!),
                          )
                        : null,
                  );
                }),
            if (_isDeleting)
              Container(
                  color: Colors.black87,
                  child: const Center(
                      child: CircularProgressIndicator(color: Colors.amber))),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyWarsView(UserModel user) {
    return Column(
      children: [
        const SizedBox(height: 20),
        _buildSectionTitle('🏆 ترتيب أبطال الحروب'),
        Expanded(
          child: StreamBuilder<List<FamilyModel>>(
            stream: _db
                .collection('families')
                .orderBy('warExp', descending: true)
                .limit(20)
                .snapshots()
                .map((s) =>
                    s.docs.map((d) => FamilyModel.fromFirestore(d)).toList()),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final families = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: families.length,
                itemBuilder: (context, i) {
                  final f = families[i];
                  return AppTheme.glassContainer(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    opacity: 0.05,
                    child: ListTile(
                      leading: Text('#${i + 1}',
                          style: const TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold)),
                      title: Text(f.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      subtitle: Text(
                          'الانتصارات: ${f.warWins} | الهزائم: ${f.warLosses}',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${f.warExp}',
                              style: const TextStyle(
                                  color: Colors.cyanAccent,
                                  fontWeight: FontWeight.bold)),
                          const Text('خبرة حرب',
                              style: TextStyle(
                                  color: Colors.white24, fontSize: 9)),
                        ],
                      ),
                      onTap: () {
                        if (user.familyId != null &&
                            user.familyId != f.id &&
                            user.familyRole == 'leader') {
                          _showChallengeDialog(user.familyId!, f);
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showChallengeDialog(String myFamilyId, FamilyModel targetFamily) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A050E),
        title: const Text('إعلان حرب ملكية! ⚔️',
            style: TextStyle(color: Colors.amber)),
        content: Text(
            'هل أنت متأكد من رغبتك في تحدي عائلة (${targetFamily.name}) في حرب الهدايا؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('تراجع')),
          ElevatedButton(
              onPressed: () async {
                try {
                  await _familyService.startFamilyWar(
                      challengerId: myFamilyId,
                      targetId: targetFamily.id,
                      durationMinutes: 30);
                  if (mounted) Navigator.pop(ctx);
                  _showSuccessSnack('تم إرسال التحدي! بدأت الحرب الآن 🔥');
                } catch (e) {
                  _showErrorSnack(e.toString());
                }
              },
              child: const Text('بدء التحدي')),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(UserModel user) {
    return SliverAppBar(
      expandedHeight: 80.0,
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const Text('نظام العوائل الملكي',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      centerTitle: true,
      leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context)),
      actions: [
        if (user.familyId != null)
          StreamBuilder<DocumentSnapshot>(
              stream: _db.collection('families').doc(user.familyId).snapshots(),
              builder: (context, snap) {
                if (!snap.hasData || !snap.data!.exists) {
                  return const SizedBox();
                }
                final family = FamilyModel.fromFirestore(
                    snap.data! as DocumentSnapshot<Map<String, dynamic>>);
                return IconButton(
                    icon: const Icon(Icons.more_horiz,
                        color: Colors.white, size: 30),
                    onPressed: () => _showMoreOptions(family, user));
              }),
      ],
    );
  }

  Widget _buildSearchBox() => Padding(
      padding: const EdgeInsets.all(20),
      child: AppTheme.glassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
          opacity: 0.03,
          child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              onChanged: (v) => setState(() {}),
              decoration: InputDecoration(
                  hintText: 'ابحث عن عائلة...',
                  prefixIcon: const Icon(Icons.search, color: Colors.redAccent),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.filter_list, color: Colors.amber),
                    onPressed: _showFilterDialog,
                  ),
                  border: InputBorder.none))));

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1A050E),
          title:
              const Text('فلاتر البحث', style: TextStyle(color: Colors.amber)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    labelText: 'الحد الأدنى للمستوى',
                    labelStyle: TextStyle(color: Colors.white70)),
                onChanged: (v) => _minLevelFilter = int.tryParse(v) ?? 1,
              ),
              SwitchListTile(
                title: const Text('عائلات خاصة فقط',
                    style: TextStyle(color: Colors.white70)),
                value: _isPrivateFilter,
                onChanged: (v) => setState(() => _isPrivateFilter = v),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () {
                setState(() {});
                Navigator.pop(ctx);
              },
              child: const Text('تطبيق'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopFamiliesList(bool hasFam) => StreamBuilder<List<FamilyModel>>(
      stream: _familyService.getLeaderboard('total'),
      builder: (context, snapshot) => snapshot.hasData
          ? ListView.builder(
              padding: const EdgeInsets.all(20),
              physics: const BouncingScrollPhysics(),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, i) => _FamilyListItem(
                  family: snapshot.data![i],
                  rank: i + 1,
                  hasFamily: hasFam,
                  onTap: () => _showFamilyJoinSheet(snapshot.data![i], hasFam)))
          : const Center(child: CircularProgressIndicator()));

  Widget _buildMyFamilyView(UserModel user) {
    if (user.familyId == null || user.familyId!.isEmpty) {
      return const Center(
          child: Text('لا تنتمي لعائلة حالياً',
              style: TextStyle(color: Colors.white24)));
    }

    return StreamBuilder<DocumentSnapshot>(
        stream: _db.collection('families').doc(user.familyId).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.amber));
          }
          if (snap.hasError) {
            return Center(
                child: Text('خطأ في تحميل بيانات العائلة',
                    style: TextStyle(color: Colors.white.withOpacity(0.5))));
          }
          if (!snap.hasData || !snap.data!.exists) {
            return Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('يبدو أن هذه العائلة لم تعد موجودة',
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 10),
                ElevatedButton(
                    onPressed: () => _repairStaleStatus(user.uid),
                    child: const Text('تحديث حالة العضوية')),
              ],
            ));
          }

          final familyData = snap.data!.data() as Map<String, dynamic>?;
          if (familyData == null)
            return const Center(child: Text('بيانات العائلة تالفة'));

          final family = FamilyModel.fromFirestore(
              snap.data! as DocumentSnapshot<Map<String, dynamic>>);
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              _buildFamilyHeaderCard(family, user),
              const SizedBox(height: 25),
              _buildFamilyWealthRow(family),
              const SizedBox(height: 20),
              _buildFamilyStatsRow(family),
              const SizedBox(height: 30),
              _buildQuickServices(family),
              const SizedBox(height: 30),
              _buildTopContributors(family.id),
              const SizedBox(height: 30),
              _buildSectionTitle('أعضاء العائلة'),
              _buildMembersList(family, user),
            ]),
          );
        });
  }

  Widget _buildFamilyWealthRow(FamilyModel family) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
            onTap: () => _showDonateDialog(family),
            child: _WealthItem(
                value: family.familyGems,
                icon: Icons.diamond,
                color: Colors.cyanAccent)),
        const SizedBox(width: 30),
        GestureDetector(
            onTap: () => _showDonateDialog(family),
            child: _WealthItem(
                value: family.familyStars,
                icon: Icons.stars_rounded,
                color: Colors.amber)),
      ],
    );
  }

  Widget _buildAboutFamilyView(UserModel user) {
    if (user.familyId == null || user.familyId!.isEmpty) {
      return const Center(
          child: Text('لا تنتمي لعائلة حالياً',
              style: TextStyle(color: Colors.white24)));
    }

    return StreamBuilder<DocumentSnapshot>(
        stream: _db.collection('families').doc(user.familyId).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.amber));
          }
          if (snap.hasError) {
            return Center(
                child: Text('خطأ في تحميل بيانات العائلة',
                    style: TextStyle(color: Colors.white.withOpacity(0.5))));
          }
          if (!snap.hasData || !snap.data!.exists) {
            return Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('يبدو أن هذه العائلة لم تعد موجودة',
                    style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 10),
                ElevatedButton(
                    onPressed: () => _repairStaleStatus(user.uid),
                    child: const Text('تحديث حالة العضوية')),
              ],
            ));
          }

          final familyData = snap.data!.data() as Map<String, dynamic>?;
          if (familyData == null)
            return const Center(child: Text('بيانات العائلة تالفة'));

          final family = FamilyModel.fromFirestore(
              snap.data! as DocumentSnapshot<Map<String, dynamic>>);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('قصة عائلتنا'),
                AppTheme.glassContainer(
                  opacity: 0.03,
                  padding: const EdgeInsets.all(15),
                  child: Text(
                    family.description.isEmpty
                        ? 'لم تتم كتابة قصة العائلة بعد.'
                        : family.description,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 14, height: 1.6),
                  ),
                ),
                const SizedBox(height: 30),
                _buildSectionTitle('مزايا العائلة الحالية'),
                _buildPerksList(family),
                const SizedBox(height: 30),
                _buildSectionTitle('معلومات أساسية'),
                AppTheme.glassContainer(
                  opacity: 0.03,
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.calendar_today,
                            color: Colors.purpleAccent),
                        title: const Text('تاريخ التأسيس',
                            style: TextStyle(color: Colors.white)),
                        subtitle: Text(
                            '${family.createdAt.toDate().year}/${family.createdAt.toDate().month}/${family.createdAt.toDate().day}',
                            style: const TextStyle(color: Colors.white70)),
                      ),
                      ListTile(
                        leading:
                            const Icon(Icons.person, color: Colors.blueAccent),
                        title: const Text('المؤسس',
                            style: TextStyle(color: Colors.white)),
                        subtitle: family.creatorId.isEmpty
                            ? const Text('مستخدم غير معروف',
                                style: TextStyle(color: Colors.white70))
                            : StreamBuilder<DocumentSnapshot>(
                                stream: _db
                                    .collection('users')
                                    .doc(family.creatorId)
                                    .snapshots(),
                                builder: (context, userSnap) {
                                  if (userSnap.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Text('جاري التحميل...',
                                        style:
                                            TextStyle(color: Colors.white24));
                                  }
                                  if (userSnap.hasError ||
                                      !userSnap.hasData ||
                                      !userSnap.data!.exists) {
                                    return const Text('مستخدم غير معروف',
                                        style:
                                            TextStyle(color: Colors.white70));
                                  }
                                  final data = userSnap.data!.data()
                                      as Map<String, dynamic>?;
                                  final String name =
                                      data?['name'] ?? 'بدون اسم';
                                  return Text(name,
                                      style: const TextStyle(
                                          color: Colors.white70));
                                }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
  }

  Widget _buildPerksList(FamilyModel family) {
    if (family.perks.isEmpty) {
      return const Text('لا توجد مزايا مفعلة حالياً.',
          style: TextStyle(color: Colors.white38));
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: family.perks.keys
          .map((p) => Chip(
                label: Text(p,
                    style: const TextStyle(color: Colors.white, fontSize: 12)),
                backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
                side: const BorderSide(color: Colors.redAccent),
              ))
          .toList(),
    );
  }

  Widget _buildTopContributors(String familyId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('🏆 كبار المساهمين'),
        StreamBuilder<QuerySnapshot>(
          stream: _db
              .collection('families')
              .doc(familyId)
              .collection('members')
              .orderBy('totalContribution', descending: true)
              .limit(3)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const SizedBox.shrink();
            }
            final docs = snapshot.data!.docs;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final memberData = docs[index].data() as Map<String, dynamic>;
                return _ContributorTile(
                  uid: memberData['uid'],
                  contribution: memberData['totalContribution'] ?? 0,
                  rank: index + 1,
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickServices(FamilyModel family) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ServiceBox(
            label: 'مهام العائلة',
            icon: Icons.task_alt,
            color: Colors.greenAccent,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => FamilyTasksPage(familyId: family.id)))),
        _ServiceBox(
            label: 'غرفة العائلة',
            icon: Icons.mic_none_rounded,
            color: Colors.purple,
            onTap: () {
              if (family.roomId != null && family.roomId!.isNotEmpty) {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => VoiceRoomPage(
                            roomId: family.roomId!, roomName: family.name)));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('غرفة العائلة غير متاحة حالياً')));
              }
            }),
        _ServiceBox(
            label: 'متجر العائلة',
            icon: Icons.shopping_bag_outlined,
            color: Colors.orange,
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => FamilyStorePage(family: family)))),
      ],
    );
  }

  Widget _buildMembersList(FamilyModel family, UserModel currentUser) =>
      StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('users')
            .where('familyId', isEqualTo: family.id)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.75,
            ),
            itemCount: snap.data!.docs.length,
            itemBuilder: (context, i) {
              final m = snap.data!.docs[i].data() as Map<String, dynamic>;
              return _MemberGridItem(
                memberData: m,
                familyId: family.id,
                currentUser: currentUser,
                onLongPress: () {
                  if (currentUser.familyRole == 'leader' &&
                      m['uid'] != currentUser.uid) {
                    _showMemberManagementSheet(m, family.id);
                  }
                },
              );
            },
          );
        },
      );

  void _showMemberManagementSheet(
      Map<String, dynamic> member, String familyId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        decoration: const BoxDecoration(
          color: Color(0xFF1A050E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('إدارة العضو: ${member['name']}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.person_remove, color: Colors.red),
              title: const Text('إزالة من العائلة',
                  style: TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(context);
                _confirmRemoveMember(member['uid'], member['name'], familyId);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRemoveMember(String uid, String name, String familyId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A050E),
        title:
            const Text('تأكيد الإزالة', style: TextStyle(color: Colors.amber)),
        content: Text('هل أنت متأكد من إزالة ($name) من العائلة؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _familyService.removeMember(familyId, uid);
              Navigator.pop(ctx);
              _showSuccessSnack('تمت إزالة العضو');
            },
            child: const Text('إزالة'),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyHeaderCard(FamilyModel f, UserModel u) =>
      Column(children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.amber, width: 3),
              boxShadow: [
                BoxShadow(
                    color: Colors.amber.withValues(alpha: 0.2), blurRadius: 20)
              ]),
          child: ClipOval(
              child: (Uri.tryParse(f.logoUrl)?.host.isNotEmpty == true)
                  ? Image.network(f.logoUrl, fit: BoxFit.cover)
                  : const Icon(Icons.shield, color: Colors.white24, size: 50)),
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (f.isVerified)
              const Icon(Icons.verified, color: Colors.blue, size: 18),
            const SizedBox(width: 5),
            Text(f.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        Text('شعارنا: ${f.slogan}',
            style: const TextStyle(color: Colors.amber, fontSize: 12)),
        Text('ID: ${f.id.substring(0, 8)}',
            style: const TextStyle(color: Colors.white24, fontSize: 11)),
      ]);

  Widget _buildFamilyStatsRow(FamilyModel f) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _StatBox(value: 'LV.${f.level}', label: 'المستوى'),
        _StatBox(value: '${f.memberCount}/${f.maxMembers}', label: 'الأعضاء'),
        _StatBox(value: '#${f.totalExp}', label: 'الترتيب')
      ]);

  Widget _buildSectionTitle(String t) => Align(
      alignment: Alignment.centerRight,
      child: Padding(
          padding: const EdgeInsets.only(bottom: 15, top: 10),
          child: Text(t,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold))));

  void _showFamilyJoinSheet(FamilyModel f, bool hasFam) => showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SafeArea(
          child: Container(
              padding: const EdgeInsets.all(25),
              decoration: const BoxDecoration(
                  color: Color(0xFF1A050E),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(30))),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                CircleAvatar(
                    radius: 40,
                    backgroundImage:
                        (Uri.tryParse(f.logoUrl)?.host.isNotEmpty == true)
                            ? NetworkImage(f.logoUrl)
                            : null),
                const SizedBox(height: 15),
                Text(f.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                Text(f.description,
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 25),
                if (!hasFam)
                  AppTheme.gradientButton(
                      text: f.isPrivate ? 'إرسال طلب انضمام' : 'انضمام الآن',
                      onPressed: () async {
                        try {
                          if (f.isPrivate) {
                            await _familyService.sendJoinRequest(f.id);
                            if (mounted) Navigator.pop(context);
                            _showSuccessSnack('تم إرسال طلب الانضمام');
                          } else {
                            await _familyService.joinFamily(f.id);
                            if (mounted) Navigator.pop(context);
                            _showSuccessSnack('تم الانضمام بنجاح');
                          }
                        } catch (e) {
                          _showErrorSnack(e.toString());
                        }
                      }),
                const SizedBox(height: 20)
              ]))));

  Widget _buildSearchList(bool hasFam) => StreamBuilder<List<FamilyModel>>(
      stream: _familyService.searchFamilies(_searchQuery),
      builder: (c, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final filtered = snapshot.data!
            .where((f) =>
                f.level >= _minLevelFilter &&
                (!_isPrivateFilter || f.isPrivate))
            .toList();
        return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: filtered.length,
            itemBuilder: (c, i) => _FamilyListItem(
                  family: filtered[i],
                  rank: i + 1,
                  hasFamily: hasFam,
                  onTap: () => _showFamilyJoinSheet(filtered[i], hasFam),
                ));
      });

  Widget _buildNotificationsView(UserModel user) {
    if (user.familyId == null) {
      return const Center(
          child:
              Text('لا تنتمي لعائلة', style: TextStyle(color: Colors.white38)));
    }
    return FamilyNotificationsPage(familyId: user.familyId!);
  }

  Widget _buildLeaderboardView(UserModel user) {
    if (user.familyId == null) {
      return const Center(
          child:
              Text('لا تنتمي لعائلة', style: TextStyle(color: Colors.white38)));
    }
    return FamilyLeaderboardPage(familyId: user.familyId!);
  }

  Widget _buildEventsView(UserModel user) {
    if (user.familyId == null) {
      return const Center(
          child:
              Text('لا تنتمي لعائلة', style: TextStyle(color: Colors.white38)));
    }
    return FamilyEventsPage(familyId: user.familyId!);
  }

  void _showSetFamilyRoomDialog(String familyId) {
    final roomIdController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A050E),
        title: const Text('تعيين غرفة العائلة',
            style: TextStyle(color: Colors.amber)),
        content: TextField(
          controller: roomIdController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
              hintText: 'أدخل معرف الغرفة...',
              hintStyle: TextStyle(color: Colors.white24)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              try {
                await _familyService.setFamilyRoom(
                    familyId, roomIdController.text.trim());
                if (mounted) Navigator.pop(ctx);
                _showSuccessSnack('تم تعيين غرفة العائلة');
              } catch (e) {
                _showErrorSnack(e.toString());
              }
            },
            child: const Text('تعيين'),
          ),
        ],
      ),
    );
  }
}

class _WealthItem extends StatelessWidget {
  final int value;
  final IconData icon;
  final Color color;

  const _WealthItem({
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(value.toString(),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;

  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: const TextStyle(
              color: Colors.deepPurpleAccent,
              fontSize: 18,
              fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11))
    ]);
  }
}

class _ServiceBox extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ServiceBox({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AppTheme.glassContainer(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.symmetric(vertical: 15),
          opacity: 0.03,
          child: Column(children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 10))
          ]),
        ),
      ),
    );
  }
}

class _ContributorTile extends StatelessWidget {
  final String uid;
  final int contribution;
  final int rank;

  const _ContributorTile({
    required this.uid,
    required this.contribution,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) return const SizedBox.shrink();
        final userData = userSnap.data!.data() as Map<String, dynamic>?;
        if (userData == null) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: AppTheme.glassContainer(
            opacity: 0.03,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '#$rank',
                    style: TextStyle(
                      color: rank == 1
                          ? Colors.amber
                          : (rank == 2 ? Colors.grey[400] : Colors.brown[300]),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 15),
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white10,
                    backgroundImage: (userData['profilePic'] != null &&
                            Uri.tryParse(userData['profilePic'])
                                    ?.host
                                    .isNotEmpty ==
                                true)
                        ? NetworkImage(userData['profilePic'])
                        : null,
                  ),
                ],
              ),
              title: Text(userData['name'] ?? '',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              trailing: Text(
                '$contribution 💎',
                style: const TextStyle(
                    color: Colors.lightBlueAccent, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MemberGridItem extends StatelessWidget {
  final Map<String, dynamic> memberData;
  final String familyId;
  final UserModel currentUser;
  final VoidCallback onLongPress;

  const _MemberGridItem({
    required this.memberData,
    required this.familyId,
    required this.currentUser,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    bool isOnline = memberData['isActive'] ?? false;
    String roleName;
    Color roleColor;

    switch (memberData['familyRole']) {
      case 'leader':
        roleName = 'رئيس العائلة';
        roleColor = Colors.redAccent;
        break;
      case 'co-leader':
        roleName = 'قائد مشارك';
        roleColor = Colors.blueAccent;
        break;
      case 'organizer':
        roleName = 'نائب';
        roleColor = Colors.orangeAccent;
        break;
      case 'recruiter':
        roleName = 'مسؤول توظيف';
        roleColor = Colors.greenAccent;
        break;
      default:
        roleName = 'عضو ملكي';
        roleColor = Colors.purpleAccent;
    }

    return GestureDetector(
      onLongPress: onLongPress,
      child: AppTheme.glassContainer(
        opacity: 0.05,
        padding: const EdgeInsets.all(5),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: roleColor.withValues(alpha: 0.5), width: 2),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white10,
                    backgroundImage: (memberData['profilePic'] != null &&
                            Uri.tryParse(memberData['profilePic'])
                                    ?.host
                                    .isNotEmpty ==
                                true)
                        ? NetworkImage(memberData['profilePic'])
                        : null,
                    child: (memberData['profilePic'] == null ||
                            Uri.tryParse(memberData['profilePic'] ?? '')
                                    ?.host
                                    .isEmpty !=
                                false)
                        ? const Icon(Icons.person,
                            color: Colors.white24, size: 30)
                        : null,
                  ),
                ),
                if (isOnline)
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: const Color(0xFF1A050E), width: 2),
                    ),
                  )
              ],
            ),
            const SizedBox(height: 8),
            Text(
              memberData['name'] ?? '',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              roleName,
              style: TextStyle(
                  color: roleColor, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _FamilyListItem extends StatelessWidget {
  final FamilyModel family;
  final int rank;
  final bool hasFamily;
  final VoidCallback onTap;

  const _FamilyListItem({
    required this.family,
    required this.rank,
    required this.hasFamily,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: AppTheme.glassContainer(
        padding: const EdgeInsets.all(5),
        opacity: 0.02,
        child: ListTile(
          leading: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('#$rank',
                style: TextStyle(
                    color: rank <= 3 ? Colors.amber : Colors.white24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(width: 10),
            CircleAvatar(
                backgroundImage:
                    (Uri.tryParse(family.logoUrl)?.host.isNotEmpty == true)
                        ? NetworkImage(family.logoUrl)
                        : null)
          ]),
          title: Row(children: [
            Text(family.name,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            if (family.isPrivate)
              const Icon(Icons.lock, size: 12, color: Colors.white38)
          ]),
          subtitle: Text('المستوى ${family.level}'),
          onTap: onTap,
        ),
      ),
    );
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
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      Container(color: const Color(0xFF1A050E), child: _tabBar);
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
