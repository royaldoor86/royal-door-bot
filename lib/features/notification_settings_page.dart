import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_theme.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  bool _internalNotificationsEnabled = true;
  bool _pushNotificationsEnabled = true;
  bool _followNotificationsEnabled = true;
  bool _likeNotificationsEnabled = true;
  bool _commentNotificationsEnabled = true;
  bool _giftNotificationsEnabled = true;
  bool _badgeNotificationsEnabled = true;
  bool _friendRequestNotificationsEnabled = true;
  bool _chatNotificationsEnabled = true;
  bool _systemNotificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    try {
      final doc = await _db.collection('users').doc(_currentUserId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _internalNotificationsEnabled =
              data['internalNotificationsEnabled'] ?? true;
          _pushNotificationsEnabled = data['pushNotificationsEnabled'] ?? true;
          _followNotificationsEnabled =
              data['followNotificationsEnabled'] ?? true;
          _likeNotificationsEnabled = data['likeNotificationsEnabled'] ?? true;
          _commentNotificationsEnabled =
              data['commentNotificationsEnabled'] ?? true;
          _giftNotificationsEnabled = data['giftNotificationsEnabled'] ?? true;
          _badgeNotificationsEnabled =
              data['badgeNotificationsEnabled'] ?? true;
          _friendRequestNotificationsEnabled =
              data['friendRequestNotificationsEnabled'] ?? true;
          _chatNotificationsEnabled = data['chatNotificationsEnabled'] ?? true;
          _systemNotificationsEnabled =
              data['systemNotificationsEnabled'] ?? true;
        });
      }
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    try {
      await _db.collection('users').doc(_currentUserId).update({key: value});
      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('Error updating notification setting: $e');
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
            'إعدادات الإشعارات',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20)
              .copyWith(bottom: MediaQuery.of(context).padding.bottom + 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الإشعارات العامة
              _buildSectionHeader('الإشعارات العامة'),
              _buildSwitchCard(
                icon: Icons.notifications,
                title: 'الإشعارات الداخلية',
                subtitle: 'استلام الإشعارات داخل التطبيق',
                value: _internalNotificationsEnabled,
                onChanged: (val) {
                  setState(() => _internalNotificationsEnabled = val);
                  _updateSetting('internalNotificationsEnabled', val);
                },
              ),
              _buildSwitchCard(
                icon: Icons.push_pin,
                title: 'الإشعارات الفورية',
                subtitle: 'استلام الإشعارات على الجهاز',
                value: _pushNotificationsEnabled,
                onChanged: (val) {
                  setState(() => _pushNotificationsEnabled = val);
                  _updateSetting('pushNotificationsEnabled', val);
                },
              ),
              const SizedBox(height: 30),

              // إشعارات التفاعل
              _buildSectionHeader('إشعارات التفاعل'),
              _buildSwitchCard(
                icon: Icons.person_add,
                title: 'المتابعات',
                subtitle: 'عندما يتابعك شخص جديد',
                value: _followNotificationsEnabled,
                onChanged: (val) {
                  setState(() => _followNotificationsEnabled = val);
                  _updateSetting('followNotificationsEnabled', val);
                },
              ),
              _buildSwitchCard(
                icon: Icons.favorite,
                title: 'الإعجابات',
                subtitle: 'عندما يعجب أحد بمنشوراتك',
                value: _likeNotificationsEnabled,
                onChanged: (val) {
                  setState(() => _likeNotificationsEnabled = val);
                  _updateSetting('likeNotificationsEnabled', val);
                },
              ),
              _buildSwitchCard(
                icon: Icons.comment,
                title: 'التعليقات',
                subtitle: 'عندما يعلق أحد على منشوراتك',
                value: _commentNotificationsEnabled,
                onChanged: (val) {
                  setState(() => _commentNotificationsEnabled = val);
                  _updateSetting('commentNotificationsEnabled', val);
                },
              ),
              const SizedBox(height: 30),

              // إشعارات المكافآت
              _buildSectionHeader('إشعارات المكافآت'),
              _buildSwitchCard(
                icon: Icons.card_giftcard,
                title: 'الهدايا',
                subtitle: 'عندما ترسل لك هدايا',
                value: _giftNotificationsEnabled,
                onChanged: (val) {
                  setState(() => _giftNotificationsEnabled = val);
                  _updateSetting('giftNotificationsEnabled', val);
                },
              ),
              _buildSwitchCard(
                icon: Icons.workspace_premium,
                title: 'الأوسمة',
                subtitle: 'عندما تحصل على وسام جديد',
                value: _badgeNotificationsEnabled,
                onChanged: (val) {
                  setState(() => _badgeNotificationsEnabled = val);
                  _updateSetting('badgeNotificationsEnabled', val);
                },
              ),
              const SizedBox(height: 30),

              // إشعارات التواصل
              _buildSectionHeader('إشعارات التواصل'),
              _buildSwitchCard(
                icon: Icons.person_add_alt_1,
                title: 'طلبات الصداقة',
                subtitle: 'عندما يرسل لك شخص طلب صداقة',
                value: _friendRequestNotificationsEnabled,
                onChanged: (val) {
                  setState(() => _friendRequestNotificationsEnabled = val);
                  _updateSetting('friendRequestNotificationsEnabled', val);
                },
              ),
              _buildSwitchCard(
                icon: Icons.chat,
                title: 'المحادثات',
                subtitle: 'عندما تصلك رسالة جديدة',
                value: _chatNotificationsEnabled,
                onChanged: (val) {
                  setState(() => _chatNotificationsEnabled = val);
                  _updateSetting('chatNotificationsEnabled', val);
                },
              ),
              const SizedBox(height: 30),

              // إشعارات النظام
              _buildSectionHeader('إشعارات النظام'),
              _buildSwitchCard(
                icon: Icons.settings,
                title: 'إشعارات النظام',
                subtitle: 'تحديثات وأخبار التطبيق',
                value: _systemNotificationsEnabled,
                onChanged: (val) {
                  setState(() => _systemNotificationsEnabled = val);
                  _updateSetting('systemNotificationsEnabled', val);
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

  Future<void> _resetToDefaults() async {
    setState(() {
      _internalNotificationsEnabled = true;
      _pushNotificationsEnabled = true;
      _followNotificationsEnabled = true;
      _likeNotificationsEnabled = true;
      _commentNotificationsEnabled = true;
      _giftNotificationsEnabled = true;
      _badgeNotificationsEnabled = true;
      _friendRequestNotificationsEnabled = true;
      _chatNotificationsEnabled = true;
      _systemNotificationsEnabled = true;
    });

    await _db.collection('users').doc(_currentUserId).update({
      'internalNotificationsEnabled': true,
      'pushNotificationsEnabled': true,
      'followNotificationsEnabled': true,
      'likeNotificationsEnabled': true,
      'commentNotificationsEnabled': true,
      'giftNotificationsEnabled': true,
      'badgeNotificationsEnabled': true,
      'friendRequestNotificationsEnabled': true,
      'chatNotificationsEnabled': true,
      'systemNotificationsEnabled': true,
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
