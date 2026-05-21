import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../app_theme.dart';
import '../../services/localization_service.dart';
import '../../theme/design_tokens.dart';
import '../../theme/reusable_widgets.dart';
import '../../widgets/royal_frame_widget.dart';
import '../gems_coins_page.dart';
import '../rewards_page.dart';
import '../user_level_page.dart';
import '../family_page.dart';
import '../badges_page.dart';
import '../appearance_page.dart';
import '../vip_center_page.dart';
import '../vip_subscription_page.dart';
import '../agent_dashboard_page.dart';
import '../agent_control_panel.dart';
import '../points_page.dart';
import '../invites_page.dart';
import '../store_page.dart';
import '../account_settings_page.dart';
import '../support_center_page.dart';
import '../notifications_page.dart';
import 'daily_rewards_page.dart';
import 'daily_tasks_page.dart';
import '../rewards/royal_task_center_page.dart';
import 'royal_level_page.dart';
import 'user_details_view_page.dart';
import '../user_challenges_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirestoreService _firestoreService = FirestoreService();

  // مصفوفة عتبات الخبرة (XP) لكل مستوى (يجب أن تتطابق مع المستخدمة في UserLevelPage)
  final List<int> levelThresholds = [
    0,
    1000,
    3000,
    7000,
    15000,
    40000,
    100000,
    250000,
    500000,
    1000000,
    2000000,
    4000000,
    8000000,
    15000000,
    30000000,
    50000000,
    80000000,
    120000000,
    200000000,
    350000000
  ];

  int _calculateRealLevel(int xp) {
    for (int i = levelThresholds.length - 1; i >= 0; i--) {
      if (xp >= levelThresholds[i]) return i + 1;
    }
    return 1;
  }

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content:
              Text('$message ✅', style: const TextStyle(color: Colors.black)),
          backgroundColor: DesignTokens.primaryGold),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final trans = Translations.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: AppTheme.background(
          child: SafeArea(
            child: StreamBuilder<UserModel>(
              stream: user != null
                  ? _firestoreService.streamUserData(user.uid)
                  : null,
              builder: (context, snapshot) {
                final userData = snapshot.data;
                if (snapshot.connectionState == ConnectionState.waiting ||
                    userData == null) {
                  return const RoyalLoadingIndicator();
                }

                // حساب المستوى الحقيقي هنا لضمان التزامن
                final int realLevel = _calculateRealLevel(userData.royalXP);

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildHeader(userData, trans),
                      _buildVipBanner(userData, trans),
                      const SizedBox(height: 20),
                      _buildBalanceSection(userData, trans),
                      const SizedBox(height: 20),
                      _buildQuickActionsGrid(userData, trans, realLevel),
                      const SizedBox(height: 20),
                      _buildMainOptionsList(userData, trans),
                      const SizedBox(height: 120),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(UserModel userData, Translations trans) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      color: Colors.white70),
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const NotificationsPage()))),
              IconButton(
                  icon: const Icon(Icons.settings_outlined,
                      color: Colors.white70),
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AccountSettingsPage()))),
            ],
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => UserDetailsViewPage(user: userData))),
            child: RoyalFrameWidget(
              frameUrl: userData.currentFrame,
              size: 160,
              child: CircleAvatar(
                radius: 55,
                backgroundColor: Colors.white10,
                backgroundImage: userData.profilePic.isNotEmpty
                    ? NetworkImage(userData.profilePic)
                    : null,
                child: userData.profilePic.isEmpty
                    ? const Icon(Icons.person, size: 55, color: Colors.white24)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 15),
          Text(userData.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () =>
                _copyToClipboard(userData.royalId, 'تم نسخ الآيدي الملكي'),
            child: AppTheme.glassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
              borderRadius: BorderRadius.circular(20),
              opacity: 0.05,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.copy_all_rounded,
                      size: 14, color: DesignTokens.primaryGold),
                  const SizedBox(width: 8),
                  Text('ID: ${userData.royalId}',
                      style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVipBanner(UserModel userData, Translations trans) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const RoyalLevelPage())),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        height: 65,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(
              colors: [Color(0xFF1E1E30), Color(0xFF0D1B3E)],
              begin: Alignment.centerRight,
              end: Alignment.centerLeft),
          border: Border.all(
              color: DesignTokens.primaryGold.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: DesignTokens.primaryGold.withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 2)
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 15),
            const Icon(Icons.stars_rounded,
                color: DesignTokens.primaryGold, size: 35),
            const SizedBox(width: 15),
            Text(trans.get('royal_membership'),
                style: const TextStyle(
                    color: DesignTokens.primaryGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 0.5)),
            const Spacer(),
            const SizedBox(width: 15),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceSection(UserModel userData, Translations trans) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
              child: _buildBalanceCard(
                  userData.gems.toString(),
                  trans.get('gems_title'),
                  Icons.diamond,
                  Colors.blue,
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const GemsCoinsPage())))),
          const SizedBox(width: 15),
          Expanded(
              child: _buildBalanceCard(
                  userData.stars.toString(),
                  trans.get('كوينزاتك'),
                  Icons.stars,
                  DesignTokens.primaryGold,
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const GemsCoinsPage())))),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(String val, String label, IconData icon, Color color,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AppTheme.glassContainer(
        padding: const EdgeInsets.all(15),
        opacity: 0.05,
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(label,
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 10)),
                  Text(val,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis)
                ]))
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(
      UserModel userData, Translations trans, int realLevel) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(25)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _quickAction(
              trans.get('level'),
              Icons.flag_circle_outlined,
              Colors.pinkAccent,
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const UserLevelPage())),
              badge: '$realLevel'), // تم التعديل لعرض المستوى الحقيقي المحسوب
          _quickAction(
              trans.get('family'),
              Icons.shield_outlined,
              Colors.purpleAccent,
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const FamilyPage()))),
          _quickAction(
              trans.get('badges'),
              Icons.workspace_premium_outlined,
              Colors.orangeAccent,
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const BadgesPage()))),
          _quickAction(
              trans.get('my_appearance'),
              Icons.auto_fix_high_outlined,
              Colors.cyanAccent,
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AppearancePage()))),
        ],
      ),
    );
  }

  Widget _quickAction(
      String label, IconData icon, Color color, VoidCallback onTap,
      {String? badge}) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 75,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(15),
                        border:
                            Border.all(color: color.withValues(alpha: 0.2))),
                    child: Icon(icon, color: color, size: 24)),
                if (badge != null)
                  Positioned(
                    top: -5,
                    right: -5,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: DesignTokens.primaryGold,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 1.5)),
                      child: Text(badge,
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildMainOptionsList(UserModel userData, Translations trans) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _listOption(
              2,
              trans.get('daily_tasks'),
              Icons.task_alt,
              Colors.greenAccent,
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const DailyTasksPage())),
              info: 'احصل على مكافآت 🏆'),
          _listOption(
              3,
              trans.get('daily_rewards'),
              Icons.event_available,
              Colors.orange,
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const DailyRewardsPage())),
              info: 'استلم جائزتك 🎁'),
          _listOption(
              1,
              'المكافآت الملكية',
              Icons.stars_rounded,
              const Color(0xFF00F2FE),
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const RewardsPage()))),
          _listOption(
              4,
              trans.get('vip_center'),
              Icons.military_tech_outlined,
              Colors.amber,
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const VipCenterPage()))),
          _listOption(
              5,
              trans.get('vip_subscription'),
              Icons.stars_rounded,
              DesignTokens.primaryGold,
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const VipSubscriptionPage())),
              info: 'كن ملكياً 🔥'),
          if (userData.isAgent)
            _listOption(
                7,
                trans.get('agent_panel'),
                Icons.admin_panel_settings_outlined,
                Colors.cyan,
                () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AgentControlPanel())),
                info: 'إدارة شؤون الدعم والفعاليات ⚡'),
          _listOption(
              8,
              trans.get('agency_create'),
              Icons.castle_outlined,
              Colors.blueAccent,
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const AgentDashboardPage()))),
          _listOption(
              9,
              trans.get('friendly_points'),
              Icons.favorite_outline,
              Colors.orange,
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PointsPage()))),
          _listOption(
              10,
              trans.get('challenges'),
              Icons.rocket_launch_outlined,
              Colors.redAccent,
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const UserChallengesPage())),
              info: 'شارك واجمع مكافآت!'),
          _listOption(
              11,
              trans.get('invite_center'),
              Icons.mail_outline,
              Colors.purpleAccent,
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const InvitesPage())),
              info: 'ادعُ واحصل على مكافأة 🚀'),
          _listOption(
              12,
              trans.get('store'),
              Icons.store_mall_directory_outlined,
              Colors.pink,
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const StorePage()))),
          _listOption(
              13,
              'مركز المهام الملكي',
              Icons.stars_rounded,
              DesignTokens.primaryGold,
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const RoyalTaskCenterPage())),
              info: 'اربح عملات ذهبية 💰'),
          _listOption(
              14,
              trans.get('support'),
              Icons.help_outline,
              Colors.deepPurpleAccent,
              () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SupportCenterPage()))),
        ],
      ),
    );
  }

  Widget _listOption(
      int index, String title, IconData icon, Color color, VoidCallback onTap,
      {String? info}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: AppTheme.glassContainer(
        padding: const EdgeInsets.all(5),
        opacity: 0.02,
        child: ListTile(
          onTap: onTap,
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 20,
                child: Text('$index',
                    style: const TextStyle(
                        color: Colors.white24,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 20)),
            ],
          ),
          title: Row(
            children: [
              Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600))),
              if (info != null)
                Text(info,
                    style: const TextStyle(
                        color: DesignTokens.primaryGold,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
            ],
          ),
          trailing: const Icon(Icons.arrow_forward_ios,
              color: Colors.white10, size: 14),
        ),
      ),
    );
  }
}
