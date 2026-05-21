import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:royaldoor/features/admin/admin_users_page.dart';
import 'package:royaldoor/features/admin/admin_rooms_page.dart';
import 'package:royaldoor/features/admin/admin_gifts_page.dart';
import 'package:royaldoor/features/admin/manage_agents_page.dart';
import 'package:royaldoor/features/admin/points_xp_system_page.dart';
import 'package:royaldoor/features/admin/admin_daily_tasks_page.dart';
import 'package:royaldoor/features/admin/admin_roles_permissions_page.dart';
import 'package:royaldoor/features/admin/texts_languages_system_page.dart';
import 'package:royaldoor/features/admin/admin_achievements_stats_page.dart';
import 'package:royaldoor/features/admin/admin_logs_page.dart';
import 'package:royaldoor/features/admin/admin_redemption_mgmt_page.dart';
import 'package:royaldoor/pages/admin/admin_room_themes_page.dart';

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
import 'sub_pages/admin_vehicles_mgmt_page.dart';
import 'sub_pages/admin_covers_bubbles_page.dart';
import 'sub_pages/admin_rewards_settings_page.dart';

class RoyalAdminPanelPage extends StatefulWidget {
  const RoyalAdminPanelPage({super.key});

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
      textDirection: ui.TextDirection.rtl,
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
                _buildCategory('الرعية والمجتمعات', Icons.people_outline),
                _buildGridSection([
                  _adminTile('إدارة المستخدمين', Icons.group_add_rounded,
                      Colors.blueAccent, const AdminUsersPage()),
                  _adminTile('بيوت الدعم', Icons.castle_rounded,
                      Colors.tealAccent, const ManageAgentsPage()),
                  _adminTile('العائلات الملكية', Icons.shield_rounded,
                      Colors.amberAccent, const AdminFamiliesPage()),
                  _adminTile('طلبات العائلات', Icons.notification_add_rounded,
                      Colors.pinkAccent, const AdminFamilyRequestsPage()),
                  _adminTile('الرتب والصلاحيات', Icons.gavel_rounded,
                      Colors.orangeAccent, const AdminRolesPermissionsPage()),
                ]),
                _buildCategory(
                    'الخزينة والاقتصاد', Icons.account_balance_outlined),
                _buildGridSection([
                  _adminTile('اقتصاد التطبيق', Icons.grid_view_rounded,
                      Colors.greenAccent, const AdminEconomyGrid()),
                  _adminTile('إدارة المستويات', Icons.upgrade_rounded,
                      Colors.purpleAccent, const AdminLevelsMgmtPage()),
                  _adminTile('نظام الخبرة XP', Icons.auto_awesome_rounded,
                      Colors.yellowAccent, const PointsXPSystemPage()),
                  _adminTile(
                      'طلبات تحويل المزايا',
                      Icons.stars_rounded,
                      Colors.amber,
                      const AdminRedemptionMgmtPage()),
                  _adminTile(
                      'إعدادات الحصاد الملكي',
                      Icons.settings_suggest_rounded,
                      Colors.orange,
                      const AdminHarvestSettingsPage()),
                ]),
                _buildCategory(
                    'المتجر والجماليات', Icons.shopping_bag_outlined),
                _buildGridSection([
                  _adminTile(
                      'الإطارات الملكية',
                      Icons.person_pin_circle_rounded,
                      Colors.amber,
                      const AdminFramesPage()),
                  _adminTile(
                      'المركبات الفاخرة',
                      Icons.directions_car_filled_rounded,
                      Colors.cyanAccent,
                      const AdminVehiclesMgmtPage()),
                  _adminTile('تأثيرات الدخول', Icons.auto_fix_high_rounded,
                      Colors.pinkAccent, const AdminEntryEffectsPage()),
                  _adminTile(
                      'إدارة الأغلفة',
                      Icons.wallpaper_rounded,
                      Colors.purpleAccent,
                      const AdminCoversBubblesPage(type: 'covers')),
                  _adminTile(
                      'إدارة الفقاعات',
                      Icons.chat_bubble_outline_rounded,
                      Colors.tealAccent,
                      const AdminCoversBubblesPage(type: 'bubbles')),
                  _adminTile('توثيق الحسابات', Icons.verified_rounded,
                      Colors.blueAccent, const AdminVerificationMgmtPage()),
                  _adminTile('إدارة الشارات', Icons.shield_rounded,
                      Colors.orangeAccent, const AdminBadgesMgmtPage()),
                  _adminTile('ثيمات الغرف', Icons.palette_rounded,
                      Colors.indigoAccent, const AdminRoomThemesPage()),
                  _adminTile('المتجر والهدايا', Icons.card_giftcard_rounded,
                      Colors.redAccent, const AdminGiftsPage()),
                ]),
                _buildCategory('الأنشطة والرقابة', Icons.security_rounded),
                _buildGridSection([
                  _adminTile('الغرف الصوتية', Icons.mic_external_on_rounded,
                      Colors.lightBlueAccent, const AdminRoomsPage()),
                  _adminTile('إدارة اليوميات', Icons.auto_stories_rounded,
                      Colors.green, const AdminDiariesPage()),
                  _adminTile('البلاغات والحظر', Icons.report_problem_rounded,
                      Colors.red, const AdminReportsPage()),
                  _adminTile('التحديات والمهام', Icons.emoji_events_rounded,
                      Colors.deepOrangeAccent, const AdminDailyTasksPage()),
                ]),
                _buildCategory(
                    'إعدادات السيادة', Icons.settings_suggest_outlined),
                _buildGridSection([
                  _adminTile(
                      'إعدادات اللوحة',
                      Icons.settings_applications_rounded,
                      Colors.grey,
                      const AdminSystemSettingsPage()),
                  _adminTile('سجل الإدارة', Icons.history_edu_rounded,
                      Colors.cyanAccent, const AdminLogsPage()),
                  _adminTile('الشريط الإعلاني', Icons.view_carousel_rounded,
                      Colors.white70, const AdminMarqueePage()),
                  _adminTile('اللغات والنصوص', Icons.translate_rounded,
                      Colors.blueGrey, const TextsLanguagesSystemPage()),
                  _adminTile('إحصائيات', Icons.analytics_rounded, Colors.cyan,
                      const AdminAchievementsStatsPage()),
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
    );
  }

  Widget _buildGlobalHeader() {
    return SliverAppBar(
      expandedHeight: 240.0,
      pinned: true,
      backgroundColor: primaryEmerald,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text('الديوان الملكي العالمي',
            style: TextStyle(
                color: royalGold,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 1.5)),
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
                    boxShadow: [
                      BoxShadow(
                          color: royalGold.withValues(alpha: 0.3), blurRadius: 30)
                    ],
                  ),
                  child: Icon(Icons.admin_panel_settings_rounded,
                      size: 60, color: royalGold),
                ),
                const SizedBox(height: 10),
                Text('GLOBAL MASTER CONSOLE',
                    style: TextStyle(
                        color: royalGold.withValues(alpha: 0.5),
                        fontSize: 10,
                        letterSpacing: 3)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemOverview() {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final startOfToday = DateTime(now.year, now.month, now.day);

    return SliverToBoxAdapter(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, userSnap) {
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('rooms')
                .where('isClosed', isEqualTo: false)
                .snapshots(),
            builder: (context, roomSnap) {
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('payments')
                    .where('status', isEqualTo: 'completed')
                    .where('timestamp',
                        isGreaterThanOrEqualTo:
                            Timestamp.fromDate(startOfToday))
                    .snapshots(),
                builder: (context, paySnap) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('gift_logs')
                        .where('timestamp',
                            isGreaterThanOrEqualTo:
                                Timestamp.fromDate(startOfToday))
                        .snapshots(),
                    builder: (context, giftSnap) {
                      int totalUsers = userSnap.data?.docs.length ?? 0;
                      int onlineUsers = 0;
                      if (userSnap.hasData) {
                        onlineUsers = userSnap.data!.docs.where((d) {
                          final data = d.data() as Map;
                          return data['isOnline'] == true;
                        }).length;
                      }

                      int dailyActive = 0;
                      if (userSnap.hasData) {
                        dailyActive = userSnap.data!.docs.where((d) {
                          final data = d.data() as Map;
                          return (data['lastLoginDate'] ?? "")
                              .toString()
                              .startsWith(todayStr);
                        }).length;
                      }

                      int newUsersToday = 0;
                      if (userSnap.hasData) {
                        newUsersToday = userSnap.data!.docs.where((d) {
                          final data = d.data() as Map;
                          var created = data['createdAt'];
                          if (created is Timestamp) {
                            return created.toDate().isAfter(startOfToday);
                          }
                          return false;
                        }).length;
                      }

                      int activeRooms = roomSnap.data?.docs.length ?? 0;
                      int usersInVoice = 0;
                      if (roomSnap.hasData) {
                        for (var doc in roomSnap.data!.docs) {
                          final data = doc.data() as Map;
                          final mics = data['activeMics'];
                          if (mics is List) {
                            usersInVoice += mics.length;
                          } else if (mics is Map) {
                            usersInVoice += mics.length;
                          }
                        }
                      }

                      double dailyRevenue = 0;
                      if (paySnap.hasData) {
                        for (var doc in paySnap.data!.docs) {
                          final data = doc.data() as Map;
                          dailyRevenue += _parseDouble(data['amount'] ?? 0);
                        }
                      }

                      int giftsToday = giftSnap.data?.docs.length ?? 0;

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collectionGroup('active_investments')
                            .where('type', isEqualTo: 'harvest')
                            .snapshots(),
                        builder: (context, harvestSnap) {
                          final harvestSubscribers =
                              harvestSnap.data?.docs.length ?? 0;

                          return Container(
                            height: 130,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              children: [
                                _overviewCard('المتصلون الآن', '$onlineUsers',
                                    Icons.bolt, Colors.greenAccent,
                                    onTap: _showOnlineUsersDialog),
                                _overviewCard('نشط اليوم (DAU)', '$dailyActive',
                                    Icons.trending_up, Colors.blueAccent,
                                    onTap: _showActiveTodayDialog),
                                _overviewCard('مستخدمون جدد', '$newUsersToday',
                                    Icons.person_add, Colors.cyanAccent,
                                    onTap: _showNewUsersDialog),
                                _overviewCard('الغرف النشطة', '$activeRooms',
                                    Icons.mic, Colors.amberAccent,
                                    onTap: _showActiveRoomsDialog),
                                _overviewCard(
                                    'على المايك',
                                    '$usersInVoice',
                                    Icons.record_voice_over,
                                    Colors.orangeAccent,
                                    onTap: _showOnMicDialog),
                                _overviewCard('هدايا اليوم', '$giftsToday',
                                    Icons.card_giftcard, Colors.pinkAccent,
                                    onTap: _showGiftsTodayDialog),
                                _overviewCard(
                                    'عوائد اليوم',
                                    '${dailyRevenue.toStringAsFixed(0)} نجمة',
                                    Icons.stars,
                                    Colors.lightGreenAccent,
                                    onTap: _showDailyRevenueDialog),
                                _overviewCard(
                                    'المشتركون في باقات المكافآت',
                                    '$harvestSubscribers',
                                    Icons.redeem,
                                    Colors.purpleAccent,
                                    onTap: _showHarvestSubscribersDialog),
                                _overviewCard('إجمالي المستخدمين',
                                    '$totalUsers', Icons.group, Colors.white70,
                                    onTap: _showTotalUsersDialog),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _overviewCard(String label, String val, IconData icon, Color color,
      {VoidCallback? onTap}) {
    final card = Container(
      width: 150,
      margin: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            top: -10,
            child: Icon(icon, color: color.withValues(alpha: 0.05), size: 60),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(icon, color: color, size: 16),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 10,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  child: Text(val,
                      style: TextStyle(
                          color: color,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1)),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: card,
        ),
      );
    }

    return card;
  }

  void _showOnlineUsersDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF051211),
          title: Text('المتصلون الآن', style: TextStyle(color: royalGold)),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('isOnline', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final onlineUsers = snapshot.data!.docs;
                if (onlineUsers.isEmpty) {
                  return const SizedBox(
                    height: 120,
                    child: Center(
                      child: Text('لا يوجد متصلون حالياً',
                          style: TextStyle(color: Colors.white70)),
                    ),
                  );
                }

                return SizedBox(
                  height: 300,
                  child: ListView.builder(
                    itemCount: onlineUsers.length,
                    itemBuilder: (context, index) {
                      final data =
                          onlineUsers[index].data() as Map<String, dynamic>;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 0),
                        leading: CircleAvatar(
                          backgroundColor: Colors.white12,
                          backgroundImage: data['profilePic'] != null &&
                                  data['profilePic'].toString().isNotEmpty &&
                                  Uri.tryParse(data['profilePic'].toString())
                                          ?.hasAbsolutePath ==
                                      true
                              ? NetworkImage(data['profilePic'])
                                  as ImageProvider
                              : null,
                          child: data['profilePic'] == null ||
                                  data['profilePic'].toString().isEmpty ||
                                  Uri.tryParse(data['profilePic'].toString())
                                          ?.hasAbsolutePath !=
                                      true
                              ? const Icon(Icons.person, color: Colors.white54)
                              : null,
                        ),
                        title: Text(
                          data['name'] ?? 'مستخدم',
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          data['royalId'] != null
                              ? 'الآيدي: ${data['royalId']}'
                              : 'آيدي غير متوفر',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text('إغلاق', style: TextStyle(color: Colors.white70)),
            ),
          ],
        );
      },
    );
  }

  void _showStreamDialog({
    required String title,
    required Stream<QuerySnapshot> stream,
    required Widget Function(BuildContext, AsyncSnapshot<QuerySnapshot>)
        builder,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF051211),
          title: Text(title, style: TextStyle(color: royalGold)),
          content: SizedBox(
            width: double.maxFinite,
            child: StreamBuilder<QuerySnapshot>(
              stream: stream,
              builder: builder,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text('إغلاق', style: TextStyle(color: Colors.white70)),
            ),
          ],
        );
      },
    );
  }

  void _showActiveTodayDialog() {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);

    _showStreamDialog(
      title: 'نشط اليوم',
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final activeUsers = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return (data['lastLoginDate'] ?? '').toString().startsWith(todayStr);
        }).toList();

        if (activeUsers.isEmpty) {
          return const SizedBox(
            height: 120,
            child: Center(
              child: Text('لا يوجد مستخدمين نشطين اليوم',
                  style: TextStyle(color: Colors.white70)),
            ),
          );
        }

        return SizedBox(
          height: 300,
          child: ListView.builder(
            itemCount: activeUsers.length,
            itemBuilder: (context, index) {
              final data = activeUsers[index].data() as Map<String, dynamic>;
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                leading: CircleAvatar(
                  backgroundColor: Colors.white12,
                  backgroundImage: data['profilePic'] != null &&
                          data['profilePic'].toString().isNotEmpty
                      ? NetworkImage(data['profilePic']) as ImageProvider
                      : null,
                  child: data['profilePic'] == null ||
                          data['profilePic'].toString().isEmpty
                      ? const Icon(Icons.person, color: Colors.white54)
                      : null,
                ),
                title: Text(
                  data['name'] ?? 'مستخدم',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  data['royalId'] != null
                      ? 'الآيدي: ${data['royalId']}'
                      : 'آيدي غير متوفر',
                  style: const TextStyle(color: Colors.white70),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showNewUsersDialog() {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    _showStreamDialog(
      title: 'مستخدمون جدد',
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final newUsers = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final created = data['createdAt'];
          return created is Timestamp && created.toDate().isAfter(startOfToday);
        }).toList();

        if (newUsers.isEmpty) {
          return const SizedBox(
            height: 120,
            child: Center(
              child: Text('لا يوجد مستخدمين جدد اليوم',
                  style: TextStyle(color: Colors.white70)),
            ),
          );
        }

        return SizedBox(
          height: 300,
          child: ListView.builder(
            itemCount: newUsers.length,
            itemBuilder: (context, index) {
              final data = newUsers[index].data() as Map<String, dynamic>;
              final createdAt = data['createdAt'];
              final createdText = createdAt is Timestamp
                  ? DateFormat('yyyy-MM-dd HH:mm').format(createdAt.toDate())
                  : 'غير متوفر';

              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                leading: CircleAvatar(
                  backgroundColor: Colors.white12,
                  backgroundImage: data['profilePic'] != null &&
                          data['profilePic'].toString().isNotEmpty
                      ? NetworkImage(data['profilePic']) as ImageProvider
                      : null,
                  child: data['profilePic'] == null ||
                          data['profilePic'].toString().isEmpty
                      ? const Icon(Icons.person_add, color: Colors.white54)
                      : null,
                ),
                title: Text(
                  data['name'] ?? 'مستخدم جديد',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'الآيدي: ${data['royalId'] ?? 'غير متوفر'} • انضم: $createdText',
                  style: const TextStyle(color: Colors.white70),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showActiveRoomsDialog() {
    _showStreamDialog(
      title: 'الغرف النشطة',
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .where('isClosed', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final rooms = snapshot.data!.docs;
        if (rooms.isEmpty) {
          return const SizedBox(
            height: 120,
            child: Center(
              child: Text('لا توجد غرف نشطة حالياً',
                  style: TextStyle(color: Colors.white70)),
            ),
          );
        }

        return SizedBox(
          height: 300,
          child: ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final data = rooms[index].data() as Map<String, dynamic>;
              final title = data['title'] ?? 'غرفة صوتية';
              final roomId = rooms[index].id;
              final participants = data['participants'] is List
                  ? (data['participants'] as List).length
                  : data['participants'] is Map
                      ? (data['participants'] as Map).length
                      : 0;

              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                leading: const CircleAvatar(
                  backgroundColor: Colors.white12,
                  child: Icon(Icons.mic, color: Colors.white54),
                ),
                title: Text(
                  title,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'آيدي الغرفة: $roomId • المشاركون: $participants',
                  style: const TextStyle(color: Colors.white70),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showOnMicDialog() {
    _showStreamDialog(
      title: 'المستخدمون على المايك',
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .where('isClosed', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final activeRooms = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final mics = data['activeMics'];
          if (mics is List) {
            return mics.isNotEmpty;
          }
          if (mics is Map) {
            return mics.isNotEmpty;
          }
          return false;
        }).toList();

        if (activeRooms.isEmpty) {
          return const SizedBox(
            height: 120,
            child: Center(
              child: Text('لا يوجد مستخدمون على المايك حالياً',
                  style: TextStyle(color: Colors.white70)),
            ),
          );
        }

        return SizedBox(
          height: 300,
          child: ListView.builder(
            itemCount: activeRooms.length,
            itemBuilder: (context, index) {
              final data = activeRooms[index].data() as Map<String, dynamic>;
              final roomTitle = data['title'] ?? 'غرفة صوتية';
              final mics = data['activeMics'];
              final micCount = mics is List
                  ? mics.length
                  : mics is Map
                      ? mics.length
                      : 0;

              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                leading: const CircleAvatar(
                  backgroundColor: Colors.white12,
                  child: Icon(Icons.mic_none, color: Colors.white54),
                ),
                title: Text(
                  roomTitle,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'على المايك: $micCount',
                  style: const TextStyle(color: Colors.white70),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showGiftsTodayDialog() {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    _showStreamDialog(
      title: 'هدايا اليوم',
      stream: FirebaseFirestore.instance
          .collection('gift_logs')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final gifts = snapshot.data!.docs;
        if (gifts.isEmpty) {
          return const SizedBox(
            height: 120,
            child: Center(
              child: Text('لا توجد هدايا اليوم',
                  style: TextStyle(color: Colors.white70)),
            ),
          );
        }

        return SizedBox(
          height: 300,
          child: ListView.builder(
            itemCount: gifts.length,
            itemBuilder: (context, index) {
              final data = gifts[index].data() as Map<String, dynamic>;
              final giftName = data['giftName'] ?? data['gift'] ?? 'هدية';
              final sender =
                  data['senderName'] ?? data['senderId'] ?? 'مرسل غير معروف';
              final receiver = data['receiverName'] ??
                  data['receiverId'] ??
                  'مستقبل غير معروف';

              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                leading: const CircleAvatar(
                  backgroundColor: Colors.white12,
                  child: Icon(Icons.card_giftcard, color: Colors.white54),
                ),
                title: Text(
                  giftName.toString(),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '$sender → $receiver',
                  style: const TextStyle(color: Colors.white70),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showDailyRevenueDialog() {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    _showStreamDialog(
      title: 'عوائد اليوم',
      stream: FirebaseFirestore.instance
          .collection('payments')
          .where('status', isEqualTo: 'completed')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final payments = snapshot.data!.docs;
        if (payments.isEmpty) {
          return const SizedBox(
            height: 120,
            child: Center(
              child: Text('لا توجد عوائد اليوم',
                  style: TextStyle(color: Colors.white70)),
            ),
          );
        }

        return SizedBox(
          height: 300,
          child: ListView.builder(
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final data = payments[index].data() as Map<String, dynamic>;
              final amount = data['amount']?.toString() ?? '0';
              final user = data['userName'] ?? data['userId'] ?? 'مستخدم';
              final createdAt = data['timestamp'];
              final timeText = createdAt is Timestamp
                  ? DateFormat('HH:mm').format(createdAt.toDate())
                  : 'غير معروف';

              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                leading: const CircleAvatar(
                  backgroundColor: Colors.white12,
                  child: Icon(Icons.stars, color: Colors.white54),
                ),
                title: Text(
                  '$amount نجمة',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '$user • $timeText',
                  style: const TextStyle(color: Colors.white70),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showHarvestSubscribersDialog() {
    _showStreamDialog(
      title: 'المشتركون في باقات المكافآت',
      stream: FirebaseFirestore.instance
          .collectionGroup('active_investments')
          .where('type', isEqualTo: 'harvest')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final subscribers = snapshot.data!.docs;
        if (subscribers.isEmpty) {
          return const SizedBox(
            height: 120,
            child: Center(
              child: Text('لا يوجد مشتركين في باقات المكافآت حالياً',
                  style: TextStyle(color: Colors.white70)),
            ),
          );
        }

        return SizedBox(
          height: 300,
          child: ListView.builder(
            itemCount: subscribers.length,
            itemBuilder: (context, index) {
              final data = subscribers[index].data() as Map<String, dynamic>;
              final userId = data['userId'] ?? data['uid'] ?? 'غير معروف';
              final packageName =
                  data['packageName'] ?? data['plan'] ?? 'باقة مكافآت';
              final startAt = data['startAt'];
              final startText = startAt is Timestamp
                  ? DateFormat('yyyy-MM-dd').format(startAt.toDate())
                  : 'غير معروف';

              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                leading: const CircleAvatar(
                  backgroundColor: Colors.white12,
                  child: Icon(Icons.redeem, color: Colors.white54),
                ),
                title: Text(
                  packageName.toString(),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'المستخدم: $userId • بدأ: $startText',
                  style: const TextStyle(color: Colors.white70),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showTotalUsersDialog() {
    _showStreamDialog(
      title: 'إجمالي المستخدمين',
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final users = snapshot.data!.docs;
        if (users.isEmpty) {
          return const SizedBox(
            height: 120,
            child: Center(
              child: Text('لا يوجد مستخدمين',
                  style: TextStyle(color: Colors.white70)),
            ),
          );
        }

        return SizedBox(
          height: 300,
          child: ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final data = users[index].data() as Map<String, dynamic>;
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                leading: CircleAvatar(
                  backgroundColor: Colors.white12,
                  backgroundImage: data['profilePic'] != null &&
                          data['profilePic'].toString().isNotEmpty
                      ? NetworkImage(data['profilePic']) as ImageProvider
                      : null,
                  child: data['profilePic'] == null ||
                          data['profilePic'].toString().isEmpty
                      ? const Icon(Icons.person, color: Colors.white54)
                      : null,
                ),
                title: Text(
                  data['name'] ?? 'مستخدم',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  data['royalId'] != null
                      ? 'الآيدي: ${data['royalId']}'
                      : 'آيدي غير متوفر',
                  style: const TextStyle(color: Colors.white70),
                ),
              );
            },
          ),
        );
      },
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
            Text(title,
                style: TextStyle(
                    color: royalGold,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1)),
            const Spacer(),
            Container(
                width: 80,
                height: 1,
                decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                  royalGold.withValues(alpha: 0.3),
                  Colors.transparent
                ]))),
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
          mainAxisSpacing: 15,
          crossAxisSpacing: 15,
          childAspectRatio: 1.5,
        ),
        delegate: SliverChildListDelegate(children),
      ),
    );
  }

  Widget _adminTile(String title, IconData icon, Color color, Widget page) {
    return GestureDetector(
      onTap: () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              border: Border.all(color: Colors.white10),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [color.withValues(alpha: 0.15), Colors.transparent],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                    right: -15,
                    bottom: -15,
                    child:
                        Icon(icon, size: 80, color: color.withValues(alpha: 0.05))),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            shape: BoxShape.circle),
                        child: Icon(icon, color: color, size: 20),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.1,
                                fontWeight: FontWeight.bold)),
                      ),
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

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll('%', '')) ?? 0.0;
    }
    return 0.0;
  }
}
