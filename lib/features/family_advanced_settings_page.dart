import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_theme.dart';
import '../services/family_service.dart';

class FamilyAdvancedSettingsPage extends StatefulWidget {
  final String familyId;
  const FamilyAdvancedSettingsPage({super.key, required this.familyId});

  @override
  State<FamilyAdvancedSettingsPage> createState() =>
      _FamilyAdvancedSettingsPageState();
}

class _FamilyAdvancedSettingsPageState
    extends State<FamilyAdvancedSettingsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FamilyService _familyService = FamilyService();

  bool _isPrivate = false;
  bool _requireApproval = false;
  bool _enableNotifications = true;
  int _minLevel = 1;
  String _description = '';
  Map<String, dynamic> _currentPerks = {};
  final TextEditingController _customPerkNameController =
      TextEditingController();
  final TextEditingController _customPerkDescController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final familySnap =
        await _db.collection('families').doc(widget.familyId).get();
    if (familySnap.exists) {
      final data = familySnap.data() as Map<String, dynamic>;
      setState(() {
        _isPrivate = data['isPrivate'] ?? false;
        _requireApproval = data['requireApproval'] ?? false;
        _enableNotifications = data['enableNotifications'] ?? true;
        _minLevel = data['minLevel'] ?? 1;
        _description = data['description'] ?? '';
        _currentPerks = data['perks'] ?? {};
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A050E),
        appBar: AppBar(
          title: const Text('الإعدادات المتقدمة',
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF3D0B16),
                  Color(0xFF1A050E),
                  Color(0x00000000)
                ],
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildPrivacySettings(),
                  const SizedBox(height: 20),
                  _buildNotificationSettings(),
                  const SizedBox(height: 20),
                  _buildMembershipSettings(),
                  const SizedBox(height: 20),
                  _buildDescriptionSettings(),
                  const SizedBox(height: 20),
                  _buildPerksManagement(),
                  const SizedBox(height: 20),
                  _buildSaveButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacySettings() {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('إعدادات الخصوصية',
              style: TextStyle(
                  color: Colors.amber,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          SwitchListTile(
            title:
                const Text('عائلة خاصة', style: TextStyle(color: Colors.white)),
            subtitle: const Text('لا يمكن البحث عن العائلة',
                style: TextStyle(color: Colors.white38)),
            value: _isPrivate,
            onChanged: (value) {
              setState(() => _isPrivate = value);
            },
            activeThumbColor: Colors.amber,
          ),
          SwitchListTile(
            title: const Text('تتطلب موافقة للانضمام',
                style: TextStyle(color: Colors.white)),
            subtitle: const Text('يجب على القائد الموافقة على طلبات الانضمام',
                style: TextStyle(color: Colors.white38)),
            value: _requireApproval,
            onChanged: (value) {
              setState(() => _requireApproval = value);
            },
            activeThumbColor: Colors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('إعدادات الإشعارات',
              style: TextStyle(
                  color: Colors.amber,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          SwitchListTile(
            title: const Text('تفعيل الإشعارات',
                style: TextStyle(color: Colors.white)),
            subtitle: const Text('إرسال إشعارات للأنشطة العائلية',
                style: TextStyle(color: Colors.white38)),
            value: _enableNotifications,
            onChanged: (value) {
              setState(() => _enableNotifications = value);
            },
            activeThumbColor: Colors.amber,
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipSettings() {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('إعدادات العضوية',
              style: TextStyle(
                  color: Colors.amber,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Text(
            'المستوى الأدنى للانضمام: $_minLevel',
            style: const TextStyle(color: Colors.white),
          ),
          Slider(
            value: _minLevel.toDouble(),
            min: 1,
            max: 50,
            divisions: 49,
            label: 'المستوى $_minLevel',
            activeColor: Colors.amber,
            onChanged: (value) {
              setState(() => _minLevel = value.toInt());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSettings() {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('وصف العائلة',
              style: TextStyle(
                  color: Colors.amber,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          TextField(
            maxLines: 4,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'وصف العائلة',
              labelStyle: const TextStyle(color: Colors.white38),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.white38),
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
            ),
            controller: TextEditingController(text: _description),
            onChanged: (value) {
              setState(() => _description = value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPerksManagement() {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('إدارة مزايا العائلة',
              style: TextStyle(
                  color: Colors.amber,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          if (_currentPerks.isEmpty)
            const Text('لا توجد مزايا مفعلة حالياً.',
                style: TextStyle(color: Colors.white38))
          else
            Column(
              children: _currentPerks.entries.map((entry) {
                final perkName = entry.key;
                final perkData = entry.value is Map<String, dynamic>
                    ? entry.value as Map<String, dynamic>
                    : {'name': perkName, 'description': ''};
                return ListTile(
                  title: Text(perkData['name'] ?? perkName,
                      style: const TextStyle(color: Colors.white)),
                  subtitle: Text(perkData['description'] ?? '',
                      style: const TextStyle(color: Colors.white38)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removePerk(perkName),
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: _showAddPerkDialog,
            icon: const Icon(Icons.add),
            label: const Text('إضافة ميزة جديدة'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddPerkDialog() async {
    _customPerkNameController.clear();
    _customPerkDescController.clear();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('إضافة ميزة جديدة',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _customPerkNameController,
              decoration: const InputDecoration(
                labelText: 'اسم الميزة',
                labelStyle: TextStyle(color: Colors.white38),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _customPerkDescController,
              decoration: const InputDecoration(
                labelText: 'وصف الميزة',
                labelStyle: TextStyle(color: Colors.white38),
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white24)),
          ),
          ElevatedButton(
            onPressed: () async {
              final perkName = _customPerkNameController.text.trim();
              final perkDesc = _customPerkDescController.text.trim();

              if (perkName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('يرجى إدخال اسم الميزة')),
                );
                return;
              }

              try {
                await _familyService.addFamilyPerk(
                  widget.familyId,
                  perkName,
                  perkDesc,
                );
                if (mounted) {
                  Navigator.pop(ctx);
                  _loadSettings();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم إضافة الميزة بنجاح ✅')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('فشل الإضافة: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text('إضافة', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Future<void> _removePerk(String perkName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('حذف الميزة', style: TextStyle(color: Colors.white)),
        content: Text('هل أنت متأكد من حذف ميزة "$perkName"؟',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white24)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _familyService.removeFamilyPerk(widget.familyId, perkName);
        if (mounted) {
          _loadSettings();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف الميزة بنجاح ✅')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل الحذف: $e')),
          );
        }
      }
    }
  }

  Widget _buildSaveButton() {
    return AppTheme.gradientButton(
      text: 'حفظ الإعدادات',
      onPressed: _saveSettings,
    );
  }

  Future<void> _saveSettings() async {
    try {
      await _db.collection('families').doc(widget.familyId).update({
        'isPrivate': _isPrivate,
        'requireApproval': _requireApproval,
        'enableNotifications': _enableNotifications,
        'minLevel': _minLevel,
        'description': _description,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حفظ الإعدادات بنجاح ✅')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    }
  }
}
