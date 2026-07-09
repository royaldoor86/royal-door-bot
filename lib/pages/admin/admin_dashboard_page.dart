import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';
import '../../theme/reusable_widgets.dart';
import '../../services/admin_setup_service.dart';
import 'admin_users_page.dart';
import 'admin_rooms_page.dart';
import '../../features/admin/admin_rewards_page.dart';
import 'admin_announcement_page.dart';
import 'admin_gifts_page.dart';
import 'admin_reports_page.dart';
import 'admin_payments_page.dart';
import 'admin_gem_bundles_page.dart';
import 'admin_special_ids_page.dart';
import 'admin_room_themes_page.dart';
import 'admin_daily_posts_page.dart';
import 'admin_agencies_page.dart';
import 'admin_families_page.dart';
import 'admin_frames_page.dart';
import 'admin_effects_page.dart';
import 'admin_task_rewards_mgmt_page.dart';
import 'admin_levels_page.dart'; // استيراد صفحة المستويات

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedMenuIndex = 0;

  final List<String> _menuItems = const [
    'نظرة عامة 📊',
    'المستخدمون 👥',
    'الغرف الصوتية 🎙️',
    'إدارة المستويات 📈', // أضفتها هنا لتكون واضحة
    'العائلات الملكية 🏰',
    'الإطارات الملكية 🖼️',
    'تأثيرات الدخول ✨',
    'اقتصاد التطبيق 💰',
    'المتجر والهدايا 🎁',
    'إدارة اليوميات 📸',
    'إدارة الوكلاء 🛡️',
    'البلاغات والحظر 🚫',
    'الشريط الإعلاني 📢',
    'إدارة المكافآت 🏦',
    'مهام ومقالات 📄',
    'إعدادات اللوحة ⚙️',
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AppTheme.background(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: const HeadingText('لوحة تحكم رويال دور الملكية 👑',
                fontSize: DesignTokens.fontSizeLg),
          ),
          drawer: _buildDrawer(context),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: DesignTokens.backgroundDarkDeep,
      child: SafeArea(
        child: Column(
          children: [
            _buildDrawerHeader(),
            Expanded(
              child: ListView.builder(
                itemCount: _menuItems.length,
                padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingMd),
                itemBuilder: (context, index) {
                  final selected = index == _selectedMenuIndex;
                  return ListTile(
                    leading: Icon(_getIcon(index),
                        color: selected ? DesignTokens.primaryGold : DesignTokens.neutralWhite.withValues(alpha: 0.7)),
                    title: Text(_menuItems[index],
                        style: TextStyle(
                            color: selected ? DesignTokens.primaryGold : DesignTokens.neutralWhite,
                            fontWeight: selected
                                ? DesignTokens.fontWeightBold
                                : DesignTokens.fontWeightNormal,
                            fontFamily: DesignTokens.primaryFont)),
                    selected: selected,
                    selectedTileColor: DesignTokens.primaryGold.withValues(alpha: 0.1),
                    onTap: () {
                      setState(() => _selectedMenuIndex = index);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.spacingXl),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [DesignTokens.backgroundDarkDeep, DesignTokens.backgroundDarkMedium],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        border: Border(
          bottom: BorderSide(color: Colors.white10, width: 1),
        ),
      ),
      child: const Column(
        children: [
          CircleAvatar(
              radius: 35,
              backgroundColor: DesignTokens.primaryGold,
              child: Icon(Icons.admin_panel_settings,
                  size: 40, color: DesignTokens.neutralBlack)),
          SizedBox(height: DesignTokens.spacingMd),
          HeadingText("المدير العام", fontSize: DesignTokens.fontSizeBase),
          CaptionText("نظام رويال دور الموحد"),
        ],
      ),
    );
  }

  IconData _getIcon(int index) {
    switch (index) {
      case 0:
        return Icons.analytics;
      case 1:
        return Icons.people;
      case 2:
        return Icons.mic;
      case 3:
        return Icons.auto_graph; // أيقونة المستويات
      case 4:
        return Icons.castle;
      case 5:
        return Icons.branding_watermark; // الإطارات الملكية
      case 6:
        return Icons.auto_awesome;
      case 7:
        return Icons.stars_rounded;
      case 8:
        return Icons.card_giftcard;
      case 9:
        return Icons.camera_alt;
      case 10:
        return Icons.shield;
      case 11:
        return Icons.report;
      case 12:
        return Icons.campaign;
      case 13:
        return Icons.account_balance_wallet;
      default:
        return Icons.settings;
    }
  }

  Widget _buildContent() {
    switch (_selectedMenuIndex) {
      case 0:
        return const _OverviewSection();
      case 1:
        return const AdminUsersPage();
      case 2:
        return const AdminRoomsPage();
      case 3:
        return const AdminLevelsPage(); // ربط صفحة المستويات هنا
      case 4:
        return const AdminFamiliesPage();
      case 5:
        return const AdminFramesPage();
      case 6:
        return const AdminEffectsPage();
      case 7:
        return const AdminEconomyWrapper();
      case 8:
        return const AdminGiftsPage();
      case 9:
        return const AdminDailyPostsPage();
      case 10:
        return const AdminAgenciesPage();
      case 11:
        return const AdminReportsPage();
      case 12:
        return const AdminAnnouncementPage();
      case 13:
        return const AdminRewardsPage();
      case 14:
        return const AdminTaskRewardsMgmtPage();
      default:
        return const _AdminSettingsSection();
    }
  }
}

class AdminEconomyWrapper extends StatefulWidget {
  const AdminEconomyWrapper({super.key});

  @override
  State<AdminEconomyWrapper> createState() => _AdminEconomyWrapperState();
}

class _AdminEconomyWrapperState extends State<AdminEconomyWrapper> {
  int _innerIndex = 0;

  @override
  Widget build(BuildContext context) {
    if (_innerIndex == 0) return _buildEconomyMenu();
    if (_innerIndex == 1) return const AdminPaymentsPage();
    if (_innerIndex == 2) return const AdminGemBundlesPage();
    if (_innerIndex == 3) return const AdminSpecialIdsPage();
    if (_innerIndex == 4) return const AdminRoomThemesPage();
    return const SizedBox();
  }

  Widget _buildEconomyMenu() {
    return Column(
      children: [
        const HeadingText("إدارة اقتصاد التطبيق 💰", fontSize: DesignTokens.fontSizeXl2),
        const SizedBox(height: DesignTokens.spacingXl),
        _buildEconomyTile(
            "طلبات الشحن المعلقة 🧾",
            "تفعيل وشحن طلبات المستخدمين",
            Icons.receipt_long,
            () => setState(() => _innerIndex = 1)),
        _buildEconomyTile(
            "باقات الجواهر والنجوم 💎",
            "إدارة الأسعار والباقات المتوفرة",
            Icons.diamond,
            () => setState(() => _innerIndex = 2)),
        _buildEconomyTile("الـ ID المميز 🆔", "إنشاء وتفعيل الـ ID الخاص",
            Icons.verified, () => setState(() => _innerIndex = 3)),
        _buildEconomyTile(
            "ثيمات وموضوعات الغرف 🎨",
            "صنع وحذف ثيمات الغرف (GIF/صورة)",
            Icons.palette,
            () => setState(() => _innerIndex = 4)),
      ],
    );
  }

  Widget _buildEconomyTile(
      String title, String sub, IconData icon, VoidCallback onTap) {
    return RoyalCard(
      margin: const EdgeInsets.only(bottom: DesignTokens.spacingMd),
      onTap: onTap,
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
            backgroundColor: DesignTokens.primaryGold.withValues(alpha: 0.1),
            child: Icon(icon, color: DesignTokens.primaryGold)),
        title: BodyText(title, fontWeight: DesignTokens.fontWeightBold),
        subtitle: CaptionText(sub, textAlign: TextAlign.right),
        trailing: const Icon(Icons.arrow_forward_ios,
            color: Colors.white24, size: 14),
      ),
    );
  }
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const HeadingText("إحصائيات النظام العامة",
            fontSize: DesignTokens.fontSizeXl2),
        const SizedBox(height: DesignTokens.spacingXl),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          crossAxisSpacing: DesignTokens.spacingMd,
          mainAxisSpacing: DesignTokens.spacingMd,
          children: const [
            _StatCard(
                title: "المستخدمين",
                collection: "users",
                icon: Icons.group,
                color: DesignTokens.primarySapphire),
            _StatCard(
                title: "الغرف",
                collection: "rooms",
                icon: Icons.meeting_room,
                color: DesignTokens.primaryEmerald),
            _StatCard(
                title: "العائلات",
                collection: "families",
                icon: Icons.castle,
                color: DesignTokens.primaryAmethyst),
            _StatCard(
                title: "البلاغات",
                collection: "reports",
                icon: Icons.warning,
                color: DesignTokens.semanticError),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String collection;
  final IconData icon;
  final Color color;
  const _StatCard(
      {required this.title,
      required this.collection,
      required this.icon,
      required this.color});
  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(DesignTokens.spacingMd),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection(collection).snapshots(),
        builder: (context, snap) {
          int count = snap.hasData ? snap.data!.docs.length : 0;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: DesignTokens.iconSizeLg),
              const SizedBox(height: DesignTokens.spacingSm),
              CaptionText(title),
              HeadingText(count.toString(),
                  fontSize: DesignTokens.fontSizeXl2),
            ],
          );
        },
      ),
    );
  }
}

class _AdminSettingsSection extends StatefulWidget {
  const _AdminSettingsSection();

  @override
  State<_AdminSettingsSection> createState() => _AdminSettingsSectionState();
}

class _AdminSettingsSectionState extends State<_AdminSettingsSection> {
  final _maintenanceMessageController = TextEditingController();
  bool _maintenanceMode = false;
  bool _storeMaintenance = false;
  bool _giftsMaintenance = false;
  bool _harvestMaintenance = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final doc = await FirebaseFirestore.instance
        .collection('admin_settings')
        .doc('global')
        .get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _maintenanceMode = data['maintenanceMode'] ?? false;
        _storeMaintenance = data['storeMaintenance'] ?? false;
        _giftsMaintenance = data['giftsMaintenance'] ?? false;
        _harvestMaintenance = data['harvestMaintenance'] ??
            data['investmentMaintenance'] ??
            false;
        _maintenanceMessageController.text = data['maintenanceMessage'] ??
            "نحن نقوم ببعض التحسينات، سنعود قريباً!";
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    await FirebaseFirestore.instance
        .collection('admin_settings')
        .doc('global')
        .set({
      'maintenanceMode': _maintenanceMode,
      'storeMaintenance': _storeMaintenance,
      'giftsMaintenance': _giftsMaintenance,
      'harvestMaintenance': _harvestMaintenance,
      'investmentMaintenance':
          _harvestMaintenance, // Backwards compatibility for the maintenance flag
      'maintenanceMessage': _maintenanceMessageController.text,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("تم حفظ الإعدادات بنجاح ✅"),
          backgroundColor: Colors.green));
      setState(() => _isLoading = false);
    }
  }

  Future<void> _runInitialSetup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A0A10),
        title: const Text("تهيئة المحتوى الملكي 👑",
            style: TextStyle(color: Colors.amber)),
        content: const Text(
            "سيتم الآن رفع 20 هدية عالمية و5 إطارات فاخرة لقاعدة البيانات. هل تود الاستمرار؟",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("إلغاء")),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("بدء التهيئة ✅",
                  style: TextStyle(color: Colors.amber))),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await AdminSetupService.setupGlobalContent();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("تم رفع المحتوى بنجاح! اذهب للمتجر لرؤيته ✨")));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("خطأ: $e"), backgroundColor: Colors.redAccent));
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _setupFamilyTasks() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A0A10),
        title: const Text("تهيئة مهام العوائل 🏰",
            style: TextStyle(color: Colors.amber)),
        content: const Text(
            "سيتم الآن رفع مهام العوائل الأساسية (تسجيل دخول، هدايا، تفاعل صوتي) إلى Firestore. هل تود الاستمرار؟",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("تراجع")),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("رفع المهام ⚡",
                  style: TextStyle(color: Colors.amber))),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        final tasksCollection =
            FirebaseFirestore.instance.collection('family_tasks_config');
        List<Map<String, dynamic>> defaultTasks = [
          {
            'id': 'daily_login',
            'title': 'الولاء اليومي',
            'description': 'سجل دخولك للتطبيق يومياً لدعم عائلتك.',
            'xp': 100,
            'coins': 50,
            'gems': 0,
            'icon': 'event_available',
          },
          {
            'id': 'send_gift',
            'title': 'الكرم الملكي',
            'description': 'أرسل أي هدية داخل غرف الدردشة الصوتية.',
            'xp': 500,
            'coins': 200,
            'gems': 1,
            'icon': 'card_giftcard',
          },
          {
            'id': 'voice_stay',
            'title': 'صوت المملكة',
            'description':
                'ابقَ في الميكروفون لمدة 30 دقيقة داخل غرفة العائلة.',
            'xp': 300,
            'coins': 100,
            'gems': 0,
            'icon': 'mic',
          },
          {
            'id': 'invite_member',
            'title': 'توسيع الإمبراطورية',
            'description': 'قم بدعوة عضو جديد للانضمام إلى العائلة.',
            'xp': 1000,
            'coins': 500,
            'gems': 5,
            'icon': 'person_add',
          },
        ];

        for (var task in defaultTasks) {
          await tasksCollection.doc(task['id']).set(task);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  "تم رفع جميع المهام بنجاح! سيتمكن الأعضاء من رؤيتها الآن ✅"),
              backgroundColor: Colors.green));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("خطأ في الرفع: $e"),
              backgroundColor: Colors.redAccent));
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const RoyalLoadingIndicator();
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const HeadingText("إعدادات الصيانة والتحكم 🛠️",
              fontSize: DesignTokens.fontSizeXl2),
          const SizedBox(height: DesignTokens.spacingXl),
          RoyalButton(
            label: "تهيئة المحتوى الملكي (هدايا/إطارات) ⚡",
            onPressed: _runInitialSetup,
          ),
          const SizedBox(height: DesignTokens.spacingMd),
          RoyalButton(
            label: "تهيئة مهام العوائل 🏰",
            onPressed: _setupFamilyTasks,
          ),
          const SizedBox(height: DesignTokens.spacingXl2),
          const RoyalDivider(indent: 0, endIndent: 0),
          const SizedBox(height: DesignTokens.spacingMd),
          _buildOption("غلق التطبيق بالكامل للصيانة 🚫", _maintenanceMode,
              (v) => setState(() => _maintenanceMode = v)),
          _buildOption("غلق المتجر الملكي 🛒", _storeMaintenance,
              (v) => setState(() => _storeMaintenance = v)),
          _buildOption("غلق صندوق الهدايا 🎁", _giftsMaintenance,
              (v) => setState(() => _giftsMaintenance = v)),
          _buildOption("غلق نظام المكافآت 🏦", _harvestMaintenance,
              (v) => setState(() => _harvestMaintenance = v)),
          const SizedBox(height: DesignTokens.spacingLg),
          const BodyText("رسالة الصيانة للمستخدمين:",
              fontSize: DesignTokens.fontSizeSm),
          const SizedBox(height: DesignTokens.spacingSm),
          RoyalTextField(
            controller: _maintenanceMessageController,
            maxLines: 3,
            hintText: "اكتب رسالة تظهر للمستخدم عند الغلق...",
          ),
          const SizedBox(height: DesignTokens.spacingXl2),
          RoyalButton(
            label: "حفظ وتطبيق الإعدادات 💾",
            onPressed: _saveSettings,
          ),
          const SizedBox(height: DesignTokens.spacingXl4),
        ],
      ),
    );
  }

  Widget _buildOption(String title, bool val, Function(bool) onChanged) {
    return SwitchListTile(
      title: BodyText(title, fontSize: DesignTokens.fontSizeSm),
      value: val,
      onChanged: onChanged,
      activeThumbColor: DesignTokens.primaryGold,
      contentPadding: EdgeInsets.zero,
    );
  }
}
