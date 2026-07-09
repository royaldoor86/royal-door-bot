import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_theme.dart';

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({super.key});

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  bool _isPrivate = false;
  bool _profileVisibilityPublic = true;
  bool _allowMessagesFromEveryone = true;
  bool _allowMessagesFromFriendsOnly = false;
  bool _allowMessagesFromNoOne = false;
  bool _showOnlineStatus = true;
  bool _allowFriendRequests = true;
  bool _notificationsFromNonFriends = true;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    try {
      final doc = await _db.collection('users').doc(_currentUserId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _isPrivate = data['isPrivate'] ?? false;
          _profileVisibilityPublic = data['profileVisibilityPublic'] ?? true;
          _allowMessagesFromEveryone = data['allowMessagesFromEveryone'] ?? true;
          _allowMessagesFromFriendsOnly = data['allowMessagesFromFriendsOnly'] ?? false;
          _allowMessagesFromNoOne = data['allowMessagesFromNoOne'] ?? false;
          _showOnlineStatus = data['showOnlineStatus'] ?? true;
          _allowFriendRequests = data['allowFriendRequests'] ?? true;
          _notificationsFromNonFriends = data['notificationsFromNonFriends'] ?? true;
        });
      }
    } catch (e) {
      debugPrint('Error loading privacy settings: $e');
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    try {
      await _db.collection('users').doc(_currentUserId).update({key: value});
      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('Error updating privacy setting: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A12),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'إعدادات الخصوصية المتقدمة',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // إعدادات البروفايل
              _buildSectionHeader('إعدادات البروفايل'),
              _buildSwitchCard(
                icon: Icons.lock,
                title: 'حساب خاص',
                subtitle: 'جعل حسابك خاصاً لا يراه إلا الأصدقاء',
                value: _isPrivate,
                onChanged: (val) {
                  setState(() => _isPrivate = val);
                  _updateSetting('isPrivate', val);
                },
              ),
              _buildSwitchCard(
                icon: Icons.public,
                title: 'البروفايل عام',
                subtitle: 'السماح للجميع برؤية بروفايلك',
                value: _profileVisibilityPublic,
                onChanged: (val) {
                  setState(() => _profileVisibilityPublic = val);
                  _updateSetting('profileVisibilityPublic', val);
                },
              ),
              const SizedBox(height: 30),

              // إعدادات الرسائل
              _buildSectionHeader('إعدادات الرسائل'),
              _buildRadioCard(
                icon: Icons.message,
                title: 'من يمكنه إرسال رسائل؟',
                options: [
                  RadioOption('الجميع', _allowMessagesFromEveryone, () {
                    setState(() {
                      _allowMessagesFromEveryone = true;
                      _allowMessagesFromFriendsOnly = false;
                      _allowMessagesFromNoOne = false;
                    });
                    _updateSetting('allowMessagesFromEveryone', true);
                    _updateSetting('allowMessagesFromFriendsOnly', false);
                    _updateSetting('allowMessagesFromNoOne', false);
                  }),
                  RadioOption('الأصدقاء فقط', _allowMessagesFromFriendsOnly, () {
                    setState(() {
                      _allowMessagesFromEveryone = false;
                      _allowMessagesFromFriendsOnly = true;
                      _allowMessagesFromNoOne = false;
                    });
                    _updateSetting('allowMessagesFromEveryone', false);
                    _updateSetting('allowMessagesFromFriendsOnly', true);
                    _updateSetting('allowMessagesFromNoOne', false);
                  }),
                  RadioOption('لا أحد', _allowMessagesFromNoOne, () {
                    setState(() {
                      _allowMessagesFromEveryone = false;
                      _allowMessagesFromFriendsOnly = false;
                      _allowMessagesFromNoOne = true;
                    });
                    _updateSetting('allowMessagesFromEveryone', false);
                    _updateSetting('allowMessagesFromFriendsOnly', false);
                    _updateSetting('allowMessagesFromNoOne', true);
                  }),
                ],
              ),
              const SizedBox(height: 30),

              // إعدادات الحالة
              _buildSectionHeader('إعدادات الحالة'),
              _buildSwitchCard(
                icon: Icons.visibility,
                title: 'إظهار الحالة النشطة',
                subtitle: 'السماح للآخرين برؤية متى كنت متصلاً',
                value: _showOnlineStatus,
                onChanged: (val) {
                  setState(() => _showOnlineStatus = val);
                  _updateSetting('showOnlineStatus', val);
                },
              ),
              const SizedBox(height: 30),

              // إعدادات الصداقة
              _buildSectionHeader('إعدادات الصداقة'),
              _buildSwitchCard(
                icon: Icons.person_add,
                title: 'قبول طلبات الصداقة',
                subtitle: 'السماح للآخرين بإرسال طلبات صداقة',
                value: _allowFriendRequests,
                onChanged: (val) {
                  setState(() => _allowFriendRequests = val);
                  _updateSetting('allowFriendRequests', val);
                },
              ),
              _buildSwitchCard(
                icon: Icons.notifications_none,
                title: 'إشعارات من غير الأصدقاء',
                subtitle: 'استلام إشعارات من أشخاص ليسوا أصدقاء',
                value: _notificationsFromNonFriends,
                onChanged: (val) {
                  setState(() => _notificationsFromNonFriends = val);
                  _updateSetting('notificationsFromNonFriends', val);
                },
              ),
              const SizedBox(height: 30),

              // زر إعادة التعيين
              Center(
                child: TextButton.icon(
                  onPressed: _resetToDefaults,
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  label: const Text(
                    'إعادة التعيين إلى الافتراضي',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.royalGold,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSwitchCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.royalGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.royalGold, size: 22),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.royalGold,
            activeTrackColor: AppTheme.royalGold.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioCard({
    required IconData icon,
    required String title,
    required List<RadioOption> options,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.royalGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.royalGold, size: 22),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ...options.map((option) => RadioListTile<String>(
            title: Text(
              option.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            value: option.label,
            groupValue: options.firstWhere((o) => o.value).label,
            onChanged: (_) => option.onTap(),
            activeColor: AppTheme.royalGold,
          )),
        ],
      ),
    );
  }

  Future<void> _resetToDefaults() async {
    setState(() {
      _isPrivate = false;
      _profileVisibilityPublic = true;
      _allowMessagesFromEveryone = true;
      _allowMessagesFromFriendsOnly = false;
      _allowMessagesFromNoOne = false;
      _showOnlineStatus = true;
      _allowFriendRequests = true;
      _notificationsFromNonFriends = true;
    });

    await _db.collection('users').doc(_currentUserId).update({
      'isPrivate': false,
      'profileVisibilityPublic': true,
      'allowMessagesFromEveryone': true,
      'allowMessagesFromFriendsOnly': false,
      'allowMessagesFromNoOne': false,
      'showOnlineStatus': true,
      'allowFriendRequests': true,
      'notificationsFromNonFriends': true,
    });

    if (mounted) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إعادة التعيين إلى الافتراضي'),
          backgroundColor: AppTheme.royalGold,
        ),
      );
    }
  }
}

class RadioOption {
  final String label;
  final bool value;
  final VoidCallback onTap;

  RadioOption(this.label, this.value, this.onTap);
}
