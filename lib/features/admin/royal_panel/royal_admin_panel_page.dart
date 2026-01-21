import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../admin_users_page.dart';
import '../admin_rooms_page.dart';
import '../admin_gifts_page.dart';
import '../../../pages/admin/admin_payments_page.dart';
import '../manage_agents_page.dart';
import '../admin_challenges_page.dart';
import '../points_xp_system_page.dart';
import '../admin_daily_tasks_page.dart';
import '../admin_investments_page.dart';
import '../admin_announcement_page.dart';
import '../admin_roles_permissions_page.dart';
import '../admin_congrats_effects_page.dart';
import '../texts_languages_system_page.dart';
import '../admin_achievements_stats_page.dart';

import 'sub_pages/admin_families_page.dart';
import 'sub_pages/admin_frames_page.dart';
import 'sub_pages/admin_entry_effects_page.dart';
import 'sub_pages/admin_economy_grid.dart';
import 'sub_pages/admin_diaries_page.dart';
import 'sub_pages/admin_reports_page.dart';
import 'sub_pages/admin_marquee_page.dart';
import 'sub_pages/admin_system_settings_page.dart';
import 'sub_pages/admin_levels_mgmt_page.dart';
import 'sub_pages/admin_family_requests_page.dart';
import 'sub_pages/admin_verification_mgmt_page.dart';
import 'sub_pages/admin_badges_mgmt_page.dart';
import 'sub_pages/admin_bot_points_page.dart'; 
import '../../../../pages/admin/admin_room_themes_page.dart';

class RoyalAdminPanelPage extends StatefulWidget {
  const RoyalAdminPanelPage({Key? key}) : super(key: key);

  @override
  State<RoyalAdminPanelPage> createState() => _RoyalAdminPanelPageState();
}

class _RoyalAdminPanelPageState extends State<RoyalAdminPanelPage> {
  final Color primaryEmerald = const Color(0xFF042F2C);
  final Color secondaryDark = const Color(0xFF021412);
  final Color royalGold = const Color(0xFFC5A059);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: secondaryDark,
        body: Stack(
          children: [
            _buildLuxuryBackdrop(),
            CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildGlobalHeader(),
                _buildSystemOverview(),
                
                _buildCategory('الرعية والوكالات', Icons.people_outline),
                _buildGridSection([
                  _adminTile('إدارة المستخدمين', Icons.group_add_rounded, Colors.blueAccent, const AdminUsersPage()),
                  _adminTile('شؤون الوكلاء', Icons.verified_user_rounded, Colors.tealAccent, const ManageAgentsPage()),
                  _adminTile('العائلات الملكية', Icons.castle_rounded, Colors.amberAccent, const AdminFamiliesPage()),
                  _adminTile('طلبات العائلات', Icons.notification_add_rounded, Colors.pinkAccent, const AdminFamilyRequestsPage()),
                  _adminTile('الرتب والصلاحيات', Icons.gavel_rounded, Colors.orangeAccent, const AdminRolesPermissionsPage()),
                ]),

                _buildCategory('الخزينة والاقتصاد', Icons.account_balance_outlined),
                _buildGridSection([
                  _adminTile('اقتصاد التطبيق', Icons.grid_view_rounded, Colors.greenAccent, const AdminEconomyGrid()),
                  _adminTile('شحن نقاط البوت', Icons.smart_toy_rounded, Colors.amber, const AdminBotPointsPage()), 
                  _adminTile('إدارة المستويات', Icons.upgrade_rounded, Colors.purpleAccent, const AdminLevelsMgmtPage()),
                  _adminTile('الاستثمار الملكي', Icons.trending_up_rounded, Colors.cyanAccent, const AdminInvestmentsPage()),
                  _adminTile('نظام النقاط XP', Icons.auto_awesome_rounded, Colors.yellowAccent, const PointsXPSystemPage()),
                ]),

                _buildCategory('المتجر والجماليات', Icons.shopping_bag_outlined),
                _buildGridSection([
                  _adminTile('الإطارات الملكية', Icons.person_pin_circle_rounded, Colors.amber, const AdminFramesPage()),
                  _adminTile('تأثيرات الدخول', Icons.auto_fix_high_rounded, Colors.pinkAccent, const AdminEntryEffectsPage()),
                  _adminTile('توثيق الحسابات', Icons.verified_rounded, Colors.blueAccent, const AdminVerificationMgmtPage()),
                  _adminTile('إدارة الشارات', Icons.shield_rounded, Colors.orangeAccent, const AdminBadgesMgmtPage()),
                  _adminTile('ثيمات الرومات', Icons.palette_rounded, Colors.indigoAccent, const AdminRoomThemesPage()),
                  _adminTile('المتجر والهدايا', Icons.card_giftcard_rounded, Colors.redAccent, const AdminGiftsPage()),
                ]),

                _buildCategory('الأنشطة والرقابة', Icons.security_rounded),
                _buildGridSection([
                  _adminTile('الغرف الصوتية', Icons.mic_external_on_rounded, Colors.lightBlueAccent, const AdminRoomsPage()),
                  _adminTile('إدارة اليوميات', Icons.auto_stories_rounded, Colors.green, const AdminDiariesPage()),
                  _adminTile('البلاغات والحظر', Icons.report_problem_rounded, Colors.red, const AdminReportsPage()),
                  _adminTile('التحديات والمهام', Icons.emoji_events_rounded, Colors.deepOrangeAccent, const AdminDailyTasksPage()),
                ]),

                _buildCategory('إعدادات السيادة', Icons.settings_suggest_outlined),
                _buildGridSection([
                  _adminTile('إعدادات اللوحة', Icons.settings_applications_rounded, Colors.grey, const AdminSystemSettingsPage()),
                  _adminTile('الشريط الإعلاني', Icons.view_carousel_rounded, Colors.white70, const AdminMarqueePage()),
                  _adminTile('اللغات والنصوص', Icons.translate_rounded, Colors.blueGrey, const TextsLanguagesSystemPage()),
                  _adminTile('الإحصائيات', Icons.analytics_rounded, Colors.cyan, const AdminAchievementsStatsPage()),
                ]),

                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLuxuryBackdrop() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryEmerald, secondaryDark],
        ),
      ),
      // تم حذف الصورة المعطلة لضمان استقرار الواجهة
    );
  }

  Widget _buildGlobalHeader() {
    return SliverAppBar(
      expandedHeight: 240.0,
      pinned: true,
      backgroundColor: primaryEmerald,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text('الديوان الملكي العالمي', style: TextStyle(color: royalGold, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1.5)),
        background: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.auto_awesome, size: 180, color: Colors.white10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: royalGold, width: 2),
                    boxShadow: [BoxShadow(color: royalGold.withOpacity(0.3), blurRadius: 30)],
                  ),
                  child: Icon(Icons.admin_panel_settings_rounded, size: 60, color: royalGold),
                ),
                const SizedBox(height: 10),
                Text('GLOBAL MASTER CONSOLE', style: TextStyle(color: royalGold.withOpacity(0.5), fontSize: 10, letterSpacing: 3)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemOverview() {
    return SliverToBoxAdapter(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, userSnap) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('rooms').snapshots(),
            builder: (context, roomSnap) {
              int totalUsers = userSnap.data?.docs.length ?? 0;
              int activeUsers = userSnap.data?.docs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                return data['isActive'] == true;
              }).length ?? 0;
              int activeRooms = roomSnap.data?.docs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                return data['isClosed'] == false;
              }).length ?? 0;

              return Container(
                height: 120,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _overviewCard('المستخدمين', '$totalUsers', Icons.people, Colors.blue),
                    _overviewCard('نشط الآن', '$activeUsers', Icons.bolt, Colors.green),
                    _overviewCard('الغرف النشطة', '$activeRooms', Icons.meeting_room, Colors.amber),
                    _overviewCard('البلاغات', '5', Icons.warning, Colors.red),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _overviewCard(String label, String val, IconData icon, Color color) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          Text(val, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildCategory(String title, IconData icon) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 30, 20, 15),
        child: Row(
          children: [
            Icon(icon, color: royalGold, size: 20),
            const SizedBox(width: 10),
            Text(title, style: TextStyle(color: royalGold, fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            Container(width: 60, height: 1, color: royalGold.withOpacity(0.2)),
          ],
        ),
      ),
    );
  }

  Widget _buildGridSection(List<Widget> children) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
        ),
        delegate: SliverChildListDelegate(children),
      ),
    );
  }

  Widget _adminTile(String title, IconData icon, Color color, Widget page) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withOpacity(0.1), Colors.transparent],
              ),
            ),
            child: Stack(
              children: [
                Positioned(right: -10, bottom: -10, child: Icon(icon, size: 60, color: color.withOpacity(0.05))),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(icon, color: color, size: 24),
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
