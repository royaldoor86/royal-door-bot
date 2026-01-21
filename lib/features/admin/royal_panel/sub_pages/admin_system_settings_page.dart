import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSystemSettingsPage extends StatefulWidget {
  const AdminSystemSettingsPage({Key? key}) : super(key: key);

  @override
  State<AdminSystemSettingsPage> createState() => _AdminSystemSettingsPageState();
}

class _AdminSystemSettingsPageState extends State<AdminSystemSettingsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Color primaryDark = const Color(0xFF0A1F1C);
  final Color accentGold = const Color(0xFFC5A059);

  bool _isMaintenanceMode = false;
  bool _isStoreLocked = false;
  bool _isGiftBoxLocked = false;
  bool _isInvestmentLocked = false;
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
        _isInvestmentLocked = data['isInvestmentLocked'] ?? false;
        _maintenanceMsgCtrl.text = data['maintenanceMessage'] ?? "نحن في صيانة دورية، نعود قريباً 👑";
      });
    }
  }

  Future<void> _updateSetting(String field, dynamic value) async {
    await _db.collection('system_settings').doc('global').set({
      field: value,
    }, SetOptions(merge: true));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث الإعداد بنجاح ✅')));
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
          title: Text('إعدادات السيادة والصيانة', style: TextStyle(color: accentGold, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSettingCard(
              'وضع الصيانة الشامل',
              'إغلاق التطبيق بالكامل عن الجميع باستثناء المالك.',
              Icons.handyman_rounded,
              _isMaintenanceMode,
              (v) {
                setState(() => _isMaintenanceMode = v);
                _updateSetting('isMaintenanceMode', v);
              },
            ),
            if (_isMaintenanceMode)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: TextField(
                  controller: _maintenanceMsgCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'رسالة الصيانة للمستخدمين',
                    labelStyle: TextStyle(color: accentGold),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.save, color: accentGold),
                      onPressed: () => _updateSetting('maintenanceMessage', _maintenanceMsgCtrl.text),
                    ),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: accentGold.withOpacity(0.3))),
                  ),
                ),
              ),
            const SizedBox(height: 20),
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
              'قفل نظام الاستثمار',
              'إيقاف الأرباح والعمليات في قسم الاستثمار.',
              Icons.trending_up_rounded,
              _isInvestmentLocked,
              (v) {
                setState(() => _isInvestmentLocked = v);
                _updateSetting('isInvestmentLocked', v);
              },
            ),
            const SizedBox(height: 40),
            const Text(
              'تحذير: هذه الإعدادات سيادية وتؤثر على كافة المستخدمين فوراً.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.redAccent, fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingCard(String title, String subtitle, IconData icon, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentGold.withOpacity(0.1)),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: accentGold),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        value: value,
        onChanged: onChanged,
        activeColor: accentGold,
      ),
    );
  }
}
