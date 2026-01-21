import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/admin_setup_service.dart';
import 'admin_users_page.dart';
import 'admin_rooms_page.dart';
import 'admin_investments_page.dart';
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
    'إدارة الاستثمارات 🏦',
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
            title: const Text('لوحة تحكم رويال دور الملكية 👑',
                style: TextStyle(fontWeight: FontWeight.bold)),
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
      backgroundColor: const Color(0xFF14022A),
      child: SafeArea(
        child: Column(
          children: [
            _buildDrawerHeader(),
            Expanded(
              child: ListView.builder(
                itemCount: _menuItems.length,
                itemBuilder: (context, index) {
                  final selected = index == _selectedMenuIndex;
                  return ListTile(
                    leading: Icon(_getIcon(index),
                        color: selected ? Colors.amber : Colors.white70),
                    title: Text(_menuItems[index],
                        style: TextStyle(
                            color: selected ? Colors.amber : Colors.white,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal)),
                    selected: selected,
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
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient:
            LinearGradient(colors: [Color(0xFF4B008F), Color(0xFF200040)]),
      ),
      child: const Column(
        children: [
          CircleAvatar(
              radius: 35,
              backgroundColor: Colors.amber,
              child: Icon(Icons.admin_panel_settings,
                  size: 40, color: Colors.black)),
          SizedBox(height: 10),
          Text("المدير العام",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          Text("نظام رويال دور الموحد",
              style: TextStyle(color: Colors.white54, fontSize: 10)),
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
        return Icons.monetization_on;
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
        return const AdminInvestmentsPage();
      default:
        return const _AdminSettingsSection();
    }
  }
}

// ... بقية الـ Widgets (_OverviewSection, AdminEconomyWrapper, _AdminSettingsSection) تبقى كما هي
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
        const Text("إدارة اقتصاد التطبيق 💰",
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        _buildEconomyTile(
            "طلبات الشحن المعلقة 🧾",
            "تفعيل وشحن طلبات المستخدمين",
            Icons.receipt_long,
            () => setState(() => _innerIndex = 1)),
        _buildEconomyTile(
            "باقات الجواهر والكوينز 💎",
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
            backgroundColor: Colors.amber.withOpacity(0.1),
            child: Icon(icon, color: Colors.amber)),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(sub,
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
        trailing: const Icon(Icons.arrow_forward_ios,
            color: Colors.white24, size: 14),
        onTap: onTap,
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
        const Text("إحصائيات النظام العامة",
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          children: const [
            _StatCard(
                title: "المستخدمين",
                collection: "users",
                icon: Icons.group,
                color: Colors.blue),
            _StatCard(
                title: "الغرف",
                collection: "rooms",
                icon: Icons.meeting_room,
                color: Colors.green),
            _StatCard(
                title: "العائلات",
                collection: "families",
                icon: Icons.castle,
                color: Colors.purple),
            _StatCard(
                title: "البلاغات",
                collection: "reports",
                icon: Icons.warning,
                color: Colors.red),
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
    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(15),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection(collection).snapshots(),
        builder: (context, snap) {
          int count = snap.hasData ? snap.data!.docs.length : 0;
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 10),
              Text(title,
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text(count.toString(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
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
  bool _investmentMaintenance = false;
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
        _investmentMaintenance = data['investmentMaintenance'] ?? false;
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
      'investmentMaintenance': _investmentMaintenance,
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
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("تم رفع المحتوى بنجاح! اذهب للمتجر لرؤيته ✨")));
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("خطأ: $e"), backgroundColor: Colors.redAccent));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading)
      return const Center(
          child: CircularProgressIndicator(color: Colors.amber));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("إعدادات الصيانة والتحكم 🛠️",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          AppTheme.gradientButton(
            text: "تهيئة المحتوى الملكي (هدايا/إطارات) ⚡",
            onPressed: _runInitialSetup,
            width: double.infinity,
          ),
          const SizedBox(height: 30),
          const Divider(color: Colors.white10),
          const SizedBox(height: 10),
          _buildOption("غلق التطبيق بالكامل للصيانة 🚫", _maintenanceMode,
              (v) => setState(() => _maintenanceMode = v)),
          _buildOption("غلق المتجر الملكي 🛒", _storeMaintenance,
              (v) => setState(() => _storeMaintenance = v)),
          _buildOption("غلق صندوق الهدايا 🎁", _giftsMaintenance,
              (v) => setState(() => _giftsMaintenance = v)),
          _buildOption("غلق نظام الاستثمار 🏦", _investmentMaintenance,
              (v) => setState(() => _investmentMaintenance = v)),
          const SizedBox(height: 20),
          const Text("رسالة الصيانة للمستخدمين:",
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 10),
          TextField(
            controller: _maintenanceMessageController,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none),
              hintText: "اكتب رسالة تظهر للمستخدم عند الغلق...",
              hintStyle: const TextStyle(color: Colors.white24),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text("حفظ وتطبيق الإعدادات 💾",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildOption(String title, bool val, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(title,
          style: const TextStyle(color: Colors.white, fontSize: 14)),
      value: val,
      onChanged: onChanged,
      activeColor: Colors.amber,
      contentPadding: EdgeInsets.zero,
    );
  }
}
