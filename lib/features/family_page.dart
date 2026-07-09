import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
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
import 'family_events_management_page.dart';
import 'family_badges_page.dart';
import 'family_alliances_page.dart';
import 'family_history_page.dart';
import 'family_challenges_page.dart';
import 'family_branding_page.dart';
import 'family_voting_page.dart';
import 'family_daily_rewards_page.dart';
import 'family_invitation_page.dart';
import 'family_analytics_page.dart';
import 'family_wars_management_page.dart';
import 'family_chat_page.dart';
import 'family_mini_games_page.dart';
import 'family_member_details_page.dart';
import 'family_level_progress_page.dart';
import 'family_nominations_page.dart';
import 'family_archive_page.dart';
import 'family_roles_management_page.dart';
import 'family_activity_log_page.dart';
import 'family_financial_reports_page.dart';
import 'family_advanced_settings_page.dart';
import 'profile/user_profile_page.dart';
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
  final AudioPlayer _audioPlayer = AudioPlayer();
  String _searchQuery = "";
  bool _isDeleting = false;
  int _minLevelFilter = 1;
  bool _isPrivateFilter = false;
  bool _isPlayingMusic = false;
  String? _currentMusicUrl;

  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _initBannerAd();
    _tabController = TabController(length: 9, vsync: this, initialIndex: 1);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });

    // فحص الجوائز المعلقة عند الدخول
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _checkForLevelRewards());
  }

  Future<void> _toggleMusic(String musicUrl) async {
    if (_isPlayingMusic) {
      await _audioPlayer.stop();
      setState(() {
        _isPlayingMusic = false;
      });
    } else {
      await _audioPlayer.play(UrlSource(musicUrl));
      setState(() {
        _isPlayingMusic = true;
        _currentMusicUrl = musicUrl;
      });
    }
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
    _audioPlayer.dispose();
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

    final options = <Map<String, dynamic>>[];

    if (isLeader) {
      options.add({
        'icon': Icons.manage_accounts,
        'title': 'إدارة الأدوار',
        'color': Colors.cyan,
        'action': () {
          Navigator.pop(context);
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ManageFamilyRolesPage(familyId: family.id)));
        }
      });
    }

    if (canManage) {
      options.addAll([
        {
          'icon': Icons.group_add,
          'title': 'طلبات الانضمام',
          'color': Colors.teal,
          'action': () {
            Navigator.pop(context);
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => FamilyRequestsPage(familyId: family.id)));
          }
        },
        {
          'icon': Icons.person_add,
          'title': 'دعوة عضو جديد',
          'color': Colors.blue,
          'action': () {
            Navigator.pop(context);
            _showInviteDialog(family.id);
          }
        },
        {
          'icon': Icons.people_outline,
          'title': 'إضافة من الأصدقاء',
          'color': Colors.purpleAccent,
          'action': () {
            Navigator.pop(context);
            _showInviteFromFriends(family.id);
          }
        },
        {
          'icon': Icons.campaign,
          'title': 'تحديث الإعلان',
          'color': Colors.orange,
          'action': () {
            Navigator.pop(context);
            _showAnnouncementDialog(family);
          }
        },
        {
          'icon': Icons.settings,
          'title': 'إعدادات المملكة',
          'color': Colors.grey,
          'action': () {
            Navigator.pop(context);
            _showFamilySettings(family, isLeader);
          }
        },
        {
          'icon': Icons.military_tech,
          'title': 'الشارات والأوسمة',
          'color': Colors.amber,
          'action': () {
            Navigator.pop(context);
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => FamilyBadgesPage(familyId: family.id)));
          }
        },
        {
          'icon': Icons.handshake,
          'title': 'التحالفات',
          'color': Colors.blue,
          'action': () {
            Navigator.pop(context);
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => FamilyAlliancesPage(familyId: family.id)));
          }
        },
        {
          'icon': Icons.history,
          'title': 'سجل العائلة',
          'color': Colors.green,
          'action': () {
            Navigator.pop(context);
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => FamilyHistoryPage(familyId: family.id)));
          }
        },
        {
          'icon': Icons.event_available,
          'title': 'إدارة الأحداث',
          'color': Colors.purple,
          'action': () {
            Navigator.pop(context);
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => FamilyEventsManagementPage(
                        familyId: family.id, familyName: family.name)));
          }
        },
        {
          'icon': Icons.emoji_events,
          'title': 'التحديات الداخلية',
          'color': Colors.orange,
          'action': () {
            Navigator.pop(context);
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => FamilyChallengesPage(familyId: family.id)));
          }
        },
        {
          'icon': Icons.palette,
          'title': 'العلامات التجارية',
          'color': Colors.purple,
          'action': () {
            Navigator.pop(context);
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => FamilyBrandingPage(familyId: family.id)));
          }
        },
        {
          'icon': Icons.how_to_vote,
          'title': 'التصويت الديمقراطي',
          'color': Colors.cyan,
          'action': () {
            Navigator.pop(context);
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => FamilyVotingPage(familyId: family.id)));
          }
        },
        {
          'icon': Icons.card_giftcard,
          'title': 'المكافآت اليومية',
          'color': Colors.pink,
          'action': () {
            Navigator.pop(context);
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        FamilyDailyRewardsPage(familyId: family.id)));
          }
        },
        {
          'icon': Icons.mail,
          'title': 'الدعوات المخصصة',
          'color': Colors.teal,
          'action': () {
            Navigator.pop(context);
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => FamilyInvitationPage(familyId: family.id)));
          }
        },
        {
          'icon': Icons.analytics,
          'title': 'إحصائيات العائلة',
          'color': Colors.purple,
          'action': () {
            Navigator.pop(context);
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => FamilyAnalyticsPage(familyId: family.id)));
          }
        },
        {
          'icon': Icons.sports_esports,
          'title': 'الألعاب المصغرة',
          'color': Colors.orange,
          'action': () {
            Navigator.pop(context);
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => FamilyMiniGamesPage(
                        familyId: family.id, familyName: family.name)));
          }
        },
        {
          'icon': Icons.person,
          'title': 'تفاصيل العضو',
          'color': Colors.blue,
          'action': () {
            Navigator.pop(context);
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => FamilyMemberDetailsPage(
                        familyId: family.id,
                        memberId:
                            FirebaseAuth.instance.currentUser?.uid ?? '')));
          }
        },
        {
          'icon': Icons.trending_up,
          'title': 'ترقية العائلة',
          'color': Colors.green,
          'action': () {
            Navigator.pop(context);
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        FamilyLevelProgressPage(familyId: family.id)));
          }
        },
        {
          'icon': Icons.how_to_vote,
          'title': 'الترشيحات والمقترحات',
          'color': Colors.pink,
          'action': () {
            Navigator.pop(context);
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        FamilyNominationsPage(familyId: family.id)));
          }
        },
        {
          'icon': Icons.archive,
          'title': 'أرشيف العائلة',
          'color': Colors.brown,
          'action': () {
            Navigator.pop(context);
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => FamilyArchivePage(familyId: family.id)));
          }
        },
        {
          'icon': Icons.admin_panel_settings,
          'title': 'إدارة الأدوار',
          'color': Colors.deepPurple,
          'action': () {
            Navigator.pop(context);
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        FamilyRolesManagementPage(familyId: family.id)));
          }
        },
        {
          'icon': Icons.history,
          'title': 'سجل الأنشطة',
          'color': Colors.indigo,
          'action': () {
            Navigator.pop(context);
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        FamilyActivityLogPage(familyId: family.id)));
          }
        },
        {
          'icon': Icons.account_balance_wallet,
          'title': 'التقارير المالية',
          'color': Colors.green,
          'action': () {
            Navigator.pop(context);
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        FamilyFinancialReportsPage(familyId: family.id)));
          }
        },
        {
          'icon': Icons.settings,
          'title': 'الإعدادات المتقدمة',
          'color': Colors.grey,
          'action': () {
            Navigator.pop(context);
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        FamilyAdvancedSettingsPage(familyId: family.id)));
          }
        },
        if (isLeader)
          {
            'icon': Icons.room,
            'title': 'تعيين غرفة العائلة',
            'color': Colors.teal,
            'action': () {
              Navigator.pop(context);
              _showSetFamilyRoomDialog(family.id);
            }
          },
      ]);
    }

    options.add({
      'icon': Icons.exit_to_app,
      'title': 'الخروج من العائلة',
      'color': Colors.red,
      'action': () {
        Navigator.pop(context);
        _leaveFamilyConfirm(family.id);
      }
    });

    if (isLeader) {
      options.add({
        'icon': Icons.delete_forever,
        'title': 'تفكيك العائلة',
        'color': Colors.redAccent,
        'action': () {
          Navigator.pop(context);
          _deleteFamilyConfirm(family.id, family.name);
        }
      });
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
              color: Color(0xFF1A050E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('خيارات العائلة',
                  style: TextStyle(
                      color: Colors.amber,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final option = options[index];
                    return GestureDetector(
                      onTap: option['action'],
                      child: Container(
                        decoration: BoxDecoration(
                          color: option['color'].withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: option['color'].withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              option['icon'],
                              color: option['color'],
                              size: 32,
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                option['title'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionTile(
          IconData icon, String title, Color color, VoidCallback onTap) =>
      Material(
        color: Colors.transparent,
        child: ListTile(
            leading: Icon(icon, color: color),
            title: Text(title,
                style: const TextStyle(color: Colors.white, fontSize: 14)),
            onTap: onTap),
      );

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
                    return Material(
                      color: Colors.transparent,
                      child: ListTile(
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
                      'coins',
                      'كوينز 🪙',
                      selectedCurrency == 'coins',
                      () => setDialogState(() => selectedCurrency = 'coins')),
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
                      selectedCurrency == 'coins' ? 'coins' : 'gems');
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
                                    Tab(text: 'الأحداث'),
                                    Tab(text: 'محفظة العائلة')
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
                              _buildEventsView(userData),
                              _buildFamilyInventoryView(userData)
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
                    child: Material(
                      color: Colors.transparent,
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
                    style:
                        TextStyle(color: Colors.white.withValues(alpha: 0.5))));
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
          if (familyData == null) {
            return const Center(child: Text('بيانات العائلة تالفة'));
          }

          final family = FamilyModel.fromFirestore(
              snap.data! as DocumentSnapshot<Map<String, dynamic>>);
          final backgroundUrl = familyData['backgroundUrl'];
          final hasCustomBackground =
              familyData['hasCustomBackground'] ?? false;
          final musicUrl = familyData['musicUrl'];
          final hasCustomMusic = familyData['hasCustomMusic'] ?? false;

          return Container(
            decoration: hasCustomBackground &&
                    backgroundUrl != null &&
                    backgroundUrl.isNotEmpty
                ? BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(backgroundUrl),
                      fit: BoxFit.cover,
                      onError: (error, stackTrace) {},
                    ),
                  )
                : null,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: hasCustomBackground &&
                          backgroundUrl != null &&
                          backgroundUrl.isNotEmpty
                      ? [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.black.withValues(alpha: 0.7),
                          Colors.black.withValues(alpha: 0.8),
                        ]
                      : [
                          Colors.transparent,
                          Colors.transparent,
                          Colors.transparent,
                        ],
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  _buildFamilyHeaderCard(family, user),
                  const SizedBox(height: 25),
                  if (hasCustomMusic && musicUrl != null && musicUrl.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _isPlayingMusic
                                ? Icons.pause_circle
                                : Icons.play_circle,
                            color: Colors.amber,
                            size: 32,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _isPlayingMusic
                                ? 'إيقاف الموسيقى'
                                : 'تشغيل الموسيقى',
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            onPressed: () => _toggleMusic(musicUrl),
                            icon: Icon(
                              _isPlayingMusic ? Icons.pause : Icons.play_arrow,
                              color: Colors.amber,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  Colors.amber.withValues(alpha: 0.2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 25),
                  _buildFamilyWealthRow(family),
                  const SizedBox(height: 20),
                  _buildFamilyStatsRow(family),
                  const SizedBox(height: 30),
                  _buildQuickServices(family, hasCustomMusic, musicUrl),
                  const SizedBox(height: 30),
                  _buildTopContributors(family.id),
                  const SizedBox(height: 30),
                  _buildSectionTitle('أعضاء العائلة'),
                  _buildMembersList(family, user),
                ]),
              ),
            ),
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
                    style:
                        TextStyle(color: Colors.white.withValues(alpha: 0.5))));
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
          if (familyData == null) {
            return const Center(child: Text('بيانات العائلة تالفة'));
          }

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
                      Material(
                        color: Colors.transparent,
                        child: ListTile(
                          leading: const Icon(Icons.calendar_today,
                              color: Colors.purpleAccent),
                          title: const Text('تاريخ التأسيس',
                              style: TextStyle(color: Colors.white)),
                          subtitle: Text(
                              '${family.createdAt.toDate().year}/${family.createdAt.toDate().month}/${family.createdAt.toDate().day}',
                              style: const TextStyle(color: Colors.white70)),
                        ),
                      ),
                      Material(
                        color: Colors.transparent,
                        child: ListTile(
                          leading: const Icon(Icons.person,
                              color: Colors.blueAccent),
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

  Widget _buildQuickServices(
      FamilyModel family, bool hasCustomMusic, String? musicUrl) {
    return Column(
      children: [
        Row(
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
                                roomId: family.roomId!,
                                roomName: family.name)));
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
        ),
        const SizedBox(height: 15),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _ServiceBox(
                label: 'دردشة العائلة',
                icon: Icons.chat,
                color: Colors.amber,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => FamilyChatPage(familyId: family.id)))),
            _ServiceBox(
                label: 'إدارة الحروب',
                icon: Icons.military_tech,
                color: Colors.red,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => FamilyWarsManagementPage(
                            familyId: family.id, familyName: family.name)))),
            if (hasCustomMusic && musicUrl != null && musicUrl.isNotEmpty)
              _MusicPlayerBox(
                isPlaying: _isPlayingMusic,
                musicUrl: musicUrl,
                onToggle: () => _toggleMusic(musicUrl),
              ),
          ],
        ),
      ],
    );
  }

  Widget _MusicPlayerBox({
    required bool isPlaying,
    required String musicUrl,
    required VoidCallback onToggle,
  }) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        width: 100,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPlaying ? Icons.pause_circle : Icons.play_circle,
              color: Colors.amber,
              size: 32,
            ),
            const SizedBox(height: 5),
            const Text(
              'الموسيقى',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
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
                onTap: () {
                  final String? targetUid = m['uid'] ?? snap.data!.docs[i].id;
                  if (targetUid != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UserProfilePage(userId: targetUid),
                      ),
                    );
                  }
                },
                onLongPress: () {
                  if (currentUser.familyRole == 'leader' &&
                      m['uid'] != currentUser.uid) {
                    _showMemberManagementSheet(m, family.id);
                  } else if (currentUser.familyRole != 'leader') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('هذه الميزة للزعماء فقط')),
                    );
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
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.5,
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 25,
            right: 25,
            top: 25,
          ),
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
              Material(
                color: Colors.transparent,
                child: ListTile(
                  leading: const Icon(Icons.person_remove, color: Colors.red),
                  title: const Text('إزالة من العائلة',
                      style: TextStyle(color: Colors.white)),
                  onTap: () async {
                    Navigator.pop(context);
                    _confirmRemoveMember(
                        member['uid'], member['name'], familyId);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmRemoveMember(String uid, String name, String familyId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.4,
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          decoration: const BoxDecoration(
              color: Color(0xFF1A050E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.amber, size: 50),
                const SizedBox(height: 15),
                const Text('تأكيد الإزالة',
                    style: TextStyle(
                        color: Colors.amber,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text('هل أنت متأكد من إزالة ($name) من العائلة؟',
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center),
                const SizedBox(height: 25),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white10,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15))),
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('إلغاء',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15))),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _familyService.removeMember(familyId, uid);
                          _showSuccessSnack('تمت إزالة العضو');
                        },
                        child: const Text('إزالة',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
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

  Widget _buildFamilyInventoryView(UserModel userData) {
    if (userData.familyId == null || userData.familyId!.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2, size: 64, color: Colors.white38),
            SizedBox(height: 16),
            Text(
              'يجب أن تكون عضواً في عائلة لعرض محفظة العائلة',
              style: TextStyle(color: Colors.white38, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: 5,
      child: Column(
        children: [
          const TabBar(
            isScrollable: true,
            indicatorColor: Colors.amber,
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white38,
            tabs: [
              Tab(text: 'الشارات'),
              Tab(text: 'المزايا'),
              Tab(text: 'التأثيرات'),
              Tab(text: 'الترفيه'),
              Tab(text: 'الإيديات'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildFamilyInventoryItems(userData.familyId!, 'badge'),
                _buildFamilyInventoryItems(userData.familyId!, 'perk'),
                _buildFamilyInventoryItems(userData.familyId!, 'hand_effect'),
                _buildFamilyInventoryItems(userData.familyId!, 'entertainment'),
                _buildFamilyInventoryItems(userData.familyId!, 'hand_id'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyInventoryItems(String familyId, String type) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('families')
          .doc(familyId)
          .collection('purchased_items')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final purchasedItems = snapshot.data!.docs;
        if (purchasedItems.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2, size: 64, color: Colors.white38),
                SizedBox(height: 16),
                Text(
                  'لا توجد عناصر في المحفظة',
                  style: TextStyle(color: Colors.white38, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance
              .collection('family_store_items')
              .where(FieldPath.documentId,
                  whereIn: purchasedItems
                      .map((doc) => doc['itemId'] as String)
                      .toList())
              .where('type', isEqualTo: type)
              .get(),
          builder: (context, itemSnapshot) {
            if (!itemSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final items = itemSnapshot.data!.docs;
            if (items.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2, size: 64, color: Colors.white38),
                    SizedBox(height: 16),
                    Text(
                      'لا توجد عناصر من هذا النوع',
                      style: TextStyle(color: Colors.white38, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildFamilyInventoryItemCard(item);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildFamilyInventoryItemCard(DocumentSnapshot itemDoc) {
    final data = itemDoc.data() as Map<String, dynamic>;
    final name = data['name'] ?? '';
    final description = data['description'] ?? '';
    final imageUrl = data['imageUrl'] ?? '';
    final type = data['type'] ?? '';
    final handNumber = data['handNumber'];
    final handLetters = data['handLetters'];

    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (type == 'hand_id')
            _buildHandIdDisplay(handNumber, handLetters)
          else if (type == 'hand_effect')
            _buildHandEffectDisplay(handNumber, handLetters)
          else
            _buildItemImageDisplay(imageUrl),
          const SizedBox(height: 6),
          Text(name,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Text(description,
              style: const TextStyle(color: Colors.white38, fontSize: 9),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          _getTypeBadge(type),
        ],
      ),
    );
  }

  Widget _buildHandIdDisplay(dynamic handNumber, dynamic handLetters) {
    return Container(
      width: 50,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.green, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (handNumber != null && handNumber.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(handNumber,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          if (handLetters != null && handLetters.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(handLetters,
                  style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildHandEffectDisplay(dynamic handNumber, dynamic handLetters) {
    return Container(
      width: 50,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.purple, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (handNumber != null && handNumber.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(handNumber,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold)),
            ),
          if (handLetters != null && handLetters.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(handLetters,
                  style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildItemImageDisplay(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.1),
        ),
        child: const Icon(Icons.shopping_bag, color: Colors.amber, size: 18),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        imageUrl,
        width: 36,
        height: 36,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.white.withValues(alpha: 0.1),
            ),
            child:
                const Icon(Icons.broken_image, color: Colors.white38, size: 18),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.white.withValues(alpha: 0.1),
            ),
            child: const Center(
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _getTypeBadge(String type) {
    String label;
    Color color;

    switch (type) {
      case 'badge':
        label = 'شارة';
        color = Colors.blue;
        break;
      case 'perk':
        label = 'ميزة';
        color = Colors.orange;
        break;
      case 'hand_id':
        label = 'إيد';
        color = Colors.green;
        break;
      case 'hand_effect':
        label = 'تأثير';
        color = Colors.purple;
        break;
      case 'entertainment':
        label = 'ترفيه';
        color = Colors.pink;
        break;
      default:
        label = type;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
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
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '#$rank',
                      style: TextStyle(
                        color: rank == 1
                            ? Colors.amber
                            : (rank == 2
                                ? Colors.grey[400]
                                : Colors.brown[300]),
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
                      color: Colors.lightBlueAccent,
                      fontWeight: FontWeight.bold),
                ),
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
  final VoidCallback? onTap;

  const _MemberGridItem({
    required this.memberData,
    required this.familyId,
    required this.currentUser,
    required this.onLongPress,
    this.onTap,
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
            Transform.translate(
              offset: const Offset(0, -5),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  GestureDetector(
                    onTap: onTap,
                    child: Container(
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
                  ),
                  if (isOnline)
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.greenAccent,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFF1A050E), width: 2),
                      ),
                    )
                ],
              ),
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
        child: Material(
          color: Colors.transparent,
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
              Expanded(
                child: Text(family.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              if (family.isVerified)
                const Icon(Icons.verified, size: 14, color: Colors.blue),
              if (family.activeBadgeId != null &&
                  family.activeBadgeId!.isNotEmpty)
                const Icon(Icons.emoji_events, size: 14, color: Colors.amber),
              if (family.isPrivate)
                const Icon(Icons.lock, size: 12, color: Colors.white38)
            ]),
            subtitle: Text('المستوى ${family.level}'),
            onTap: onTap,
          ),
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
