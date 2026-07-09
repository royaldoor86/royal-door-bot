import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_theme.dart';

class FamilyAdvancedSettingsPage extends StatefulWidget {
  final String familyId;
  const FamilyAdvancedSettingsPage({super.key, required this.familyId});

  @override
  State<FamilyAdvancedSettingsPage> createState() => _FamilyAdvancedSettingsPageState();
}

class _FamilyAdvancedSettingsPageState extends State<FamilyAdvancedSettingsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _isPrivate = false;
  bool _requireApproval = false;
  bool _enableNotifications = true;
  int _minLevel = 1;
  String _description = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final familySnap = await _db.collection('families').doc(widget.familyId).get();
    if (familySnap.exists) {
      final data = familySnap.data() as Map<String, dynamic>;
      setState(() {
        _isPrivate = data['isPrivate'] ?? false;
        _requireApproval = data['requireApproval'] ?? false;
        _enableNotifications = data['enableNotifications'] ?? true;
        _minLevel = data['minLevel'] ?? 1;
        _description = data['description'] ?? '';
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
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3D0B16), Color(0xFF1A050E), Color(0x00000000)],
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
                _buildSaveButton(),
              ],
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
            title: const Text('عائلة خاصة',
                style: TextStyle(color: Colors.white)),
            subtitle: const Text('لا يمكن البحث عن العائلة',
                style: TextStyle(color: Colors.white38)),
            value: _isPrivate,
            onChanged: (value) {
              setState(() => _isPrivate = value);
            },
            activeColor: Colors.amber,
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
            activeColor: Colors.amber,
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
            activeColor: Colors.amber,
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
