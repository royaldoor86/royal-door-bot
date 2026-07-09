import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSystemSettingsPage extends StatefulWidget {
  const AdminSystemSettingsPage({super.key});

  @override
  State<AdminSystemSettingsPage> createState() =>
      _AdminSystemSettingsPageState();
}

class _AdminSystemSettingsPageState extends State<AdminSystemSettingsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Color primaryDark = const Color(0xFF0A1F1C);
  final Color accentGold = const Color(0xFFC5A059);

  // التحكم بالصيانة والمتاجر
  bool _isMaintenanceMode = false;
  bool _isStoreLocked = false;
  bool _isGiftBoxLocked = false;
  bool _isHarvestLocked = false;

  // التحكم بالغرف
  bool _isRoomsLocked = false;
  bool _isCreateRoomLocked = false;

  // مقترحات إضافية للتحكم الكامل
  bool _isMomentsLocked = false; // قفل اليوميات
  bool _isChatLocked = false; // قفل المحادثات الخاصة
  bool _isAgencyLocked = false; // قفل الوكالات
  bool _isLeaderboardLocked = false; // قفل قائمة المتصدرين
  bool _isFamilyLocked = false; // قفل العوائل
  bool _isGamesLocked = false; // قفل الألعاب

  final TextEditingController _maintenanceMsgCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final doc = await _db.collection('system_settings').doc('global').get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _isMaintenanceMode = data['isMaintenanceMode'] ?? false;
        _isStoreLocked = data['isStoreLocked'] ?? false;
        _isGiftBoxLocked = data['isGiftBoxLocked'] ?? false;
        _isHarvestLocked =
            data['isHarvestLocked'] ?? data['isInvestmentLocked'] ?? false;
        _isRoomsLocked = data['isRoomsLocked'] ?? false;
        _isCreateRoomLocked = data['isCreateRoomLocked'] ?? false;

        _isMomentsLocked = data['isMomentsLocked'] ?? false;
        _isChatLocked = data['isChatLocked'] ?? false;
        _isAgencyLocked = data['isAgencyLocked'] ?? false;
        _isLeaderboardLocked = data['isLeaderboardLocked'] ?? false;
        _isFamilyLocked = data['isFamilyLocked'] ?? false;
        _isGamesLocked = data['isGamesLocked'] ?? false;

        _maintenanceMsgCtrl.text =
            data['maintenanceMessage'] ?? "نحن في صيانة دورية، نعود قريباً 👑";
      });
    }
  }

  Future<void> _updateSetting(String field, dynamic value) async {
    await _db.collection('system_settings').doc('global').set({
      field: value,
    }, SetOptions(merge: true));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم تحديث الإعداد بنجاح ✅'),
          duration: Duration(seconds: 1)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: primaryDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('إعدادات السيادة والصيانة',
              style: TextStyle(color: accentGold, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSectionTitle('نظام الصيانة والوصول'),
            _buildSettingCard(
              'وضع الصيانة الشامل',
              'إغلاق التطبيق بالكامل عن الجميع باستثناء الإدارة.',
              Icons.handyman_rounded,
              _isMaintenanceMode,
              (v) {
                setState(() => _isMaintenanceMode = v);
                _updateSetting('isMaintenanceMode', v);
              },
            ),
            if (_isMaintenanceMode)
              Padding(
                padding: const EdgeInsets.only(bottom: 20, left: 10, right: 10),
                child: TextField(
                  controller: _maintenanceMsgCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'رسالة الصيانة للمستخدمين',
                    labelStyle: TextStyle(color: accentGold),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.save, color: accentGold),
                      onPressed: () => _updateSetting(
                          'maintenanceMessage', _maintenanceMsgCtrl.text),
                    ),
                    enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                            color: accentGold.withValues(alpha: 0.3))),
                  ),
                ),
              ),
            _buildSectionTitle('إدارة الميزات الأساسية'),
            _buildSettingCard(
              'قفل المتجر الملكي',
              'إيقاف عمليات الشراء في المتجر مؤقتاً.',
              Icons.store_rounded,
              _isStoreLocked,
              (v) {
                setState(() => _isStoreLocked = v);
                _updateSetting('isStoreLocked', v);
              },
            ),
            _buildSettingCard(
              'قفل صندوق الهدايا',
              'منع إرسال الهدايا في الغرف والمحادثات.',
              Icons.card_giftcard_rounded,
              _isGiftBoxLocked,
              (v) {
                setState(() => _isGiftBoxLocked = v);
                _updateSetting('isGiftBoxLocked', v);
              },
            ),
            _buildSettingCard(
              'قفل نظام المكافآت',
              'إيقاف المكافآت والعمليات في قسم المكافآت.',
              Icons.trending_up_rounded,
              _isHarvestLocked,
              (v) {
                setState(() => _isHarvestLocked = v);
                _updateSetting('isHarvestLocked', v);
              },
            ),
            _buildSectionTitle('إدارة الغرف الصوتية'),
            _buildSettingCard(
              'قفل الغرف الصوتية',
              'منع الدخول أو استخدام الغرف الصوتية بالكامل.',
              Icons.meeting_room_rounded,
              _isRoomsLocked,
              (v) {
                setState(() => _isRoomsLocked = v);
                _updateSetting('isRoomsLocked', v);
              },
            ),
            _buildSettingCard(
              'قفل إنشاء الغرف',
              'منع المستخدمين من إنشاء غرف جديدة.',
              Icons.add_home_work_rounded,
              _isCreateRoomLocked,
              (v) {
                setState(() => _isCreateRoomLocked = v);
                _updateSetting('isCreateRoomLocked', v);
              },
            ),
            _buildSectionTitle('تحكم إضافي (مقترحات السيادة)'),
            _buildSettingCard(
              'قفل اليوميات (اللحظات)',
              'منع نشر أو التفاعل مع المنشورات.',
              Icons.photo_library_rounded,
              _isMomentsLocked,
              (v) {
                setState(() => _isMomentsLocked = v);
                _updateSetting('isMomentsLocked', v);
              },
            ),
            _buildSettingCard(
              'قفل المحادثات الخاصة',
              'إيقاف نظام الدردشة الفردية.',
              Icons.chat_bubble_rounded,
              _isChatLocked,
              (v) {
                setState(() => _isChatLocked = v);
                _updateSetting('isChatLocked', v);
              },
            ),
            _buildSettingCard(
              'قفل نظام الوكالات',
              'منع الوصول لخدمات الوكلاء والمشحنين.',
              Icons.support_agent_rounded,
              _isAgencyLocked,
              (v) {
                setState(() => _isAgencyLocked = v);
                _updateSetting('isAgencyLocked', v);
              },
            ),
            _buildSettingCard(
              'قفل المتصدرين',
              'إخفاء قوائم الترتيب والمنافسات.',
              Icons.leaderboard_rounded,
              _isLeaderboardLocked,
              (v) {
                setState(() => _isLeaderboardLocked = v);
                _updateSetting('isLeaderboardLocked', v);
              },
            ),
            _buildSettingCard(
              'قفل العوائل',
              'إيقاف نظام العوائل الملكية مؤقتاً.',
              Icons.shield_rounded,
              _isFamilyLocked,
              (v) {
                setState(() => _isFamilyLocked = v);
                _updateSetting('isFamilyLocked', v);
              },
            ),
            _buildSettingCard(
              'قفل الألعاب',
              'إيقاف نظام الألعاب والمنافسات مؤقتاً.',
              Icons.videogame_asset_rounded,
              _isGamesLocked,
              (v) {
                setState(() => _isGamesLocked = v);
                _updateSetting('isGamesLocked', v);
              },
            ),
            const SizedBox(height: 40),
            const Text(
              'تحذير: هذه الإعدادات سيادية وتؤثر على كافة المستخدمين فوراً.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 11,
                  fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
      child: Text(
        title,
        style: TextStyle(
            color: accentGold,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildSettingCard(String title, String subtitle, IconData icon,
      bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentGold.withValues(alpha: 0.1)),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: accentGold),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
        subtitle: Text(subtitle,
            style: const TextStyle(color: Colors.white38, fontSize: 11)),
        value: value,
        onChanged: onChanged,
        activeThumbColor: accentGold,
      ),
    );
  }
}
