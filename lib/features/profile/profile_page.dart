import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../app_theme.dart';
import '../account_level_page.dart';
import '../gems_coins_page.dart';
import '../investment_page.dart';
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
import 'visitors_page.dart';
import 'friends_lists_page.dart';
import 'daily_rewards_page.dart';
import 'daily_tasks_page.dart';
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

  void _copyToClipboard(String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$message ✅', style: const TextStyle(color: Colors.black)), backgroundColor: AppTheme.royalGold),
    );
  }

  void _showBotLinkingDialog(String uid) async {
    final code = await _firestoreService.generateVerificationCode(uid);
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('كود التحقق للبوت 🤖', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.royalGold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('استخدم هذا الكود لربط حسابك في بوت التلغرام:', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.royalGold.withOpacity(0.3))),
              child: SelectableText(code, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 5)),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                _copyToClipboard(code, 'تم نسخ كود التحقق');
                Navigator.pop(context);
              },
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('نسخ الكود'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.royalGold, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundBlack,
        body: AppTheme.background(
          child: StreamBuilder<UserModel>(
            stream: user != null ? _firestoreService.streamUserData(user.uid) : null,
            builder: (context, snapshot) {
              final userData = snapshot.data;
              if (snapshot.connectionState == ConnectionState.waiting || userData == null) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.royalGold));
              }
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildHeader(userData),
                    _buildVipBanner(userData),
                    const SizedBox(height: 20),
                    _buildBalanceSection(userData),
                    const SizedBox(height: 20),
                    _buildQuickActionsGrid(),
                    const SizedBox(height: 20),
                    _buildMainOptionsList(userData),
                    const SizedBox(height: 120),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(UserModel userData) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.notifications_outlined, color: Colors.white70), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsPage()))),
              IconButton(icon: const Icon(Icons.settings_outlined, color: Colors.white70), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountSettingsPage()))),
            ],
          ),
          const SizedBox(height: 10),
          
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UserDetailsViewPage(user: userData))),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.royalGold.withValues(alpha: 0.5), width: 2),
                boxShadow: [BoxShadow(color: AppTheme.royalGold.withValues(alpha: 0.1), blurRadius: 20)],
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white10,
                backgroundImage: userData.profilePic.isNotEmpty ? NetworkImage(userData.profilePic) : null,
                child: userData.profilePic.isEmpty ? const Icon(Icons.person, size: 50, color: Colors.white24) : null,
              ),
            ),
          ),
          
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(userData.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'Serif')),
              if (userData.activeBadge != null) Padding(padding: const EdgeInsets.only(right: 8), child: Text(userData.activeBadge!, style: const TextStyle(fontSize: 20))),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.blueGrey.shade700, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white24)),
                child: Text(userData.nobleLevel, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _copyToClipboard(userData.royalId, 'تم نسخ الآيدي الملكي'),
            child: AppTheme.glassContainer(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
              borderRadius: BorderRadius.circular(20),
              opacity: 0.05,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.copy_all_rounded, size: 14, color: AppTheme.royalGold),
                  const SizedBox(width: 8),
                  Text('ID: ${userData.royalId}', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVipBanner(UserModel userData) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoyalLevelPage())),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        height: 65,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF0D1B3E)],
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
          ),
          border: Border.all(color: AppTheme.royalGold.withValues(alpha: 0.3)),
          boxShadow: [BoxShadow(color: AppTheme.royalGold.withValues(alpha: 0.1), blurRadius: 10)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.stars_rounded, color: AppTheme.royalGold, size: 24),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ROYAL EXCLUSIVE MEMBERSHIP',
                  style: TextStyle(color: AppTheme.royalGold, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2, fontStyle: FontStyle.italic),
                ),
                Text(
                  '     (${userData.nobleLevel})',
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
            const SizedBox(width: 15),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceSection(UserModel userData) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: _buildBalanceCard(userData.gems.toString(), 'جواهر ملكية', Icons.diamond, Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GemsCoinsPage())))),
          const SizedBox(width: 15),
          Expanded(child: _buildBalanceCard(userData.coins.toString(), 'كوينز الشحن', Icons.stars, AppTheme.royalGold, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GemsCoinsPage())))),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(String val, String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AppTheme.glassContainer(
        padding: const EdgeInsets.all(15),
        opacity: 0.05,
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)), Text(val, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)]))
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(25)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _quickAction('المستوى', Icons.flag_circle_outlined, Colors.pinkAccent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserLevelPage()))),
          _quickAction('العائلة', Icons.shield_outlined, Colors.purpleAccent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyPage()))),
          _quickAction('الشارات', Icons.workspace_premium_outlined, Colors.orangeAccent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BadgesPage()))),
          _quickAction('مظهري', Icons.auto_fix_high_outlined, Colors.cyanAccent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppearancePage()))),
        ],
      ),
    );
  }

  Widget _quickAction(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: color, size: 26)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildMainOptionsList(UserModel userData) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _listOption('المهام اليومية', Icons.task_alt, Colors.greenAccent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyTasksPage())), info: 'اربح مكافآت 🏆'),
          _listOption('مكافأة تسجيل الدخول اليومي', Icons.event_available, Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyRewardsPage())), info: 'استلم جائزتك 🎁'),
          _listOption('الاستثمار الملكي', Icons.account_balance_wallet_outlined, Colors.tealAccent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvestmentPage())), info: 'اربح كوينز 📈'),
          _listOption('مركز VIP المطور', Icons.military_tech_outlined, Colors.amber, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VipCenterPage()))),
          _listOption('امتيازات رويال', Icons.workspace_premium, Colors.amber, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoyalLevelPage())), info: 'توشاتي الملكية 🔥'),
          _listOption('اشتراك VIP', Icons.stars_rounded, AppTheme.royalGold, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VipSubscriptionPage())), info: 'كن ملكياً 🔥'),
          if (userData.isAgent) _listOption('لوحة تحكم الوكيل', Icons.admin_panel_settings_outlined, Colors.cyan, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AgentControlPanel())), info: 'إدارة المبيعات والمسابقات ⚡'),
          _listOption('إنشاء وكالة', Icons.person_add_alt_outlined, Colors.blueAccent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AgentDashboardPage()))),
          _listOption('النقاط الودية', Icons.favorite_outline, Colors.orange, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PointsPage()))),
          _listOption('تحديات يومية', Icons.rocket_launch_outlined, Colors.redAccent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserChallengesPage())), info: 'شارك واربح!'),
          _listOption('مركز الدعوات', Icons.mail_outline, Colors.purpleAccent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InvitesPage())), info: 'ادعُ واربح 🚀'),
          _listOption('المتجر الملكي', Icons.store_mall_directory_outlined, Colors.pink, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StorePage()))),
          if (userData.telegramId == null) _listOption('ربط حساب التلغرام', Icons.smart_toy_outlined, Colors.blueAccent, () => _showBotLinkingDialog(userData.uid), info: 'اربح مكافآت 🤖'),
          _listOption('الدعم والمساعدة', Icons.help_outline, Colors.deepPurpleAccent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportCenterPage()))),
        ],
      ),
    );
  }

  Widget _listOption(String title, IconData icon, Color color, VoidCallback onTap, {String? info}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: AppTheme.glassContainer(
        padding: const EdgeInsets.all(5),
        opacity: 0.02,
        child: ListTile(
          onTap: onTap,
          leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
          title: Row(
            children: [
              Expanded(child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14))),
              if (info != null) Text(info, style: const TextStyle(color: Colors.white24, fontSize: 10)),
            ],
          ),
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white10, size: 14),
        ),
      ),
    );
  }
}
