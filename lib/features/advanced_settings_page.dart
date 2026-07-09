import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_theme.dart';
import 'notification_settings_page.dart';
import 'privacy_settings_page.dart';
import 'appearance_settings_page.dart';
import 'voice_room_settings_page.dart';
import 'usage_statistics_page.dart';
import 'two_factor_auth_page.dart';
import 'session_management_page.dart';
import 'social_accounts_page.dart';

class AdvancedSettingsPage extends StatefulWidget {
  const AdvancedSettingsPage({super.key});

  @override
  State<AdvancedSettingsPage> createState() => _AdvancedSettingsPageState();
}

class _AdvancedSettingsPageState extends State<AdvancedSettingsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  Map<String, dynamic> _notificationSettings = {};
  Map<String, dynamic> _privacySettings = {};
  Map<String, dynamic> _appearanceSettings = {};
  Map<String, dynamic> _voiceRoomSettings = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
    _loadAllSettings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllSettings() async {
    try {
      final doc = await _db.collection('users').doc(_currentUserId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _notificationSettings = {
            'internalNotificationsEnabled':
                data['internalNotificationsEnabled'] ?? true,
            'pushNotificationsEnabled':
                data['pushNotificationsEnabled'] ?? true,
            'followNotificationsEnabled':
                data['followNotificationsEnabled'] ?? true,
            'likeNotificationsEnabled':
                data['likeNotificationsEnabled'] ?? true,
            'commentNotificationsEnabled':
                data['commentNotificationsEnabled'] ?? true,
            'giftNotificationsEnabled':
                data['giftNotificationsEnabled'] ?? true,
            'badgeNotificationsEnabled':
                data['badgeNotificationsEnabled'] ?? true,
            'friendRequestNotificationsEnabled':
                data['friendRequestNotificationsEnabled'] ?? true,
            'chatNotificationsEnabled':
                data['chatNotificationsEnabled'] ?? true,
            'systemNotificationsEnabled':
                data['systemNotificationsEnabled'] ?? true,
          };

          _privacySettings = {
            'profileVisibilityPublic': data['profileVisibilityPublic'] ?? true,
            'allowMessagesFromEveryone':
                data['allowMessagesFromEveryone'] ?? true,
            'allowMessagesFromFriendsOnly':
                data['allowMessagesFromFriendsOnly'] ?? false,
            'allowMessagesFromNoOne': data['allowMessagesFromNoOne'] ?? false,
            'showOnlineStatus': data['showOnlineStatus'] ?? true,
            'allowFriendRequests': data['allowFriendRequests'] ?? true,
            'notificationsFromNonFriends':
                data['notificationsFromNonFriends'] ?? true,
          };

          _appearanceSettings = {
            'darkMode': data['darkMode'] ?? true,
            'fontSize': data['fontSize'] ?? 16.0,
            'theme': data['theme'] ?? 'royal',
          };

          _voiceRoomSettings = {
            'autoJoinEnabled': data['autoJoinEnabled'] ?? false,
            'micAutoEnabled': data['micAutoEnabled'] ?? true,
            'speakerAutoEnabled': data['speakerAutoEnabled'] ?? true,
            'micVolume': data['micVolume'] ?? 0.8,
            'speakerVolume': data['speakerVolume'] ?? 1.0,
            'noiseCancellation': data['noiseCancellation'] ?? true,
            'echoCancellation': data['echoCancellation'] ?? true,
          };
        });
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> _saveAllSettings() async {
    try {
      await _db.collection('users').doc(_currentUserId).update({
        ..._notificationSettings,
        ..._privacySettings,
        ..._appearanceSettings,
        ..._voiceRoomSettings,
      });

      if (mounted) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ جميع الإعدادات بنجاح'),
            backgroundColor: AppTheme.royalGold,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل حفظ الإعدادات: $e')),
        );
      }
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
            'الإعدادات المتقدمة',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.save, color: AppTheme.royalGold),
              onPressed: _saveAllSettings,
              tooltip: 'حفظ جميع الإعدادات',
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: AppTheme.royalGold,
            labelColor: AppTheme.royalGold,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(icon: Icon(Icons.notifications), text: 'الإشعارات'),
              Tab(icon: Icon(Icons.privacy_tip), text: 'الخصوصية'),
              Tab(icon: Icon(Icons.palette), text: 'المظهر'),
              Tab(icon: Icon(Icons.mic), text: 'الصوتيات'),
              Tab(icon: Icon(Icons.bar_chart), text: 'الإحصائيات'),
              Tab(icon: Icon(Icons.phonelink_lock), text: '2FA'),
              Tab(icon: Icon(Icons.devices), text: 'الجلسات'),
              Tab(icon: Icon(Icons.link), text: 'الاجتماعي'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildNotificationSettingsTab(),
            _buildPrivacySettingsTab(),
            _buildAppearanceSettingsTab(),
            _buildVoiceRoomSettingsTab(),
            _buildStatisticsTab(),
            _buildTwoFactorAuthTab(),
            _buildSessionsTab(),
            _buildSocialAccountsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20)
          .copyWith(bottom: MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('إعدادات الإشعارات'),
          _buildSwitchCard(
            icon: Icons.notifications,
            title: 'الإشعارات الداخلية',
            value:
                _notificationSettings['internalNotificationsEnabled'] ?? true,
            onChanged: (val) {
              setState(() =>
                  _notificationSettings['internalNotificationsEnabled'] = val);
            },
          ),
          _buildSwitchCard(
            icon: Icons.notifications_active,
            title: 'الإشعارات الفورية (Push)',
            value: _notificationSettings['pushNotificationsEnabled'] ?? true,
            onChanged: (val) {
              setState(() =>
                  _notificationSettings['pushNotificationsEnabled'] = val);
            },
          ),
          _buildSwitchCard(
            icon: Icons.person_add,
            title: 'إشعارات المتابعة',
            value: _notificationSettings['followNotificationsEnabled'] ?? true,
            onChanged: (val) {
              setState(() =>
                  _notificationSettings['followNotificationsEnabled'] = val);
            },
          ),
          _buildSwitchCard(
            icon: Icons.favorite,
            title: 'إشعارات الإعجابات',
            value: _notificationSettings['likeNotificationsEnabled'] ?? true,
            onChanged: (val) {
              setState(() =>
                  _notificationSettings['likeNotificationsEnabled'] = val);
            },
          ),
          _buildSwitchCard(
            icon: Icons.comment,
            title: 'إشعارات التعليقات',
            value: _notificationSettings['commentNotificationsEnabled'] ?? true,
            onChanged: (val) {
              setState(() =>
                  _notificationSettings['commentNotificationsEnabled'] = val);
            },
          ),
          _buildSwitchCard(
            icon: Icons.card_giftcard,
            title: 'إشعارات الهدايا',
            value: _notificationSettings['giftNotificationsEnabled'] ?? true,
            onChanged: (val) {
              setState(() =>
                  _notificationSettings['giftNotificationsEnabled'] = val);
            },
          ),
          _buildSwitchCard(
            icon: Icons.workspace_premium,
            title: 'إشعارات الأوسمة',
            value: _notificationSettings['badgeNotificationsEnabled'] ?? true,
            onChanged: (val) {
              setState(() =>
                  _notificationSettings['badgeNotificationsEnabled'] = val);
            },
          ),
          _buildSwitchCard(
            icon: Icons.group_add,
            title: 'إشعارات طلبات الصداقة',
            value: _notificationSettings['friendRequestNotificationsEnabled'] ??
                true,
            onChanged: (val) {
              setState(() =>
                  _notificationSettings['friendRequestNotificationsEnabled'] =
                      val);
            },
          ),
          _buildSwitchCard(
            icon: Icons.chat,
            title: 'إشعارات المحادثات',
            value: _notificationSettings['chatNotificationsEnabled'] ?? true,
            onChanged: (val) {
              setState(() =>
                  _notificationSettings['chatNotificationsEnabled'] = val);
            },
          ),
          _buildSwitchCard(
            icon: Icons.system_update,
            title: 'إشعارات النظام',
            value: _notificationSettings['systemNotificationsEnabled'] ?? true,
            onChanged: (val) {
              setState(() =>
                  _notificationSettings['systemNotificationsEnabled'] = val);
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const NotificationSettingsPage()),
            ),
            icon: const Icon(Icons.open_in_new),
            label: const Text('فتح صفحة الإشعارات المخصصة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.royalGold,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20)
          .copyWith(bottom: MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('إعدادات الخصوصية'),
          _buildSwitchCard(
            icon: Icons.public,
            title: 'البروفايل العام',
            value: _privacySettings['profileVisibilityPublic'] ?? true,
            onChanged: (val) {
              setState(() => _privacySettings['profileVisibilityPublic'] = val);
            },
          ),
          _buildSwitchCard(
            icon: Icons.message,
            title: 'السماح بالرسائل من الجميع',
            value: _privacySettings['allowMessagesFromEveryone'] ?? true,
            onChanged: (val) {
              setState(
                  () => _privacySettings['allowMessagesFromEveryone'] = val);
            },
          ),
          _buildSwitchCard(
            icon: Icons.group,
            title: 'السماح بالرسائل من الأصدقاء فقط',
            value: _privacySettings['allowMessagesFromFriendsOnly'] ?? false,
            onChanged: (val) {
              setState(
                  () => _privacySettings['allowMessagesFromFriendsOnly'] = val);
            },
          ),
          _buildSwitchCard(
            icon: Icons.block,
            title: 'منع الرسائل من الجميع',
            value: _privacySettings['allowMessagesFromNoOne'] ?? false,
            onChanged: (val) {
              setState(() => _privacySettings['allowMessagesFromNoOne'] = val);
            },
          ),
          _buildSwitchCard(
            icon: Icons.visibility,
            title: 'إظهار الحالة النشطة',
            value: _privacySettings['showOnlineStatus'] ?? true,
            onChanged: (val) {
              setState(() => _privacySettings['showOnlineStatus'] = val);
            },
          ),
          _buildSwitchCard(
            icon: Icons.person_add,
            title: 'قبول طلبات الصداقة',
            value: _privacySettings['allowFriendRequests'] ?? true,
            onChanged: (val) {
              setState(() => _privacySettings['allowFriendRequests'] = val);
            },
          ),
          _buildSwitchCard(
            icon: Icons.notifications,
            title: 'إشعارات من غير الأصدقاء',
            value: _privacySettings['notificationsFromNonFriends'] ?? true,
            onChanged: (val) {
              setState(
                  () => _privacySettings['notificationsFromNonFriends'] = val);
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacySettingsPage()),
            ),
            icon: const Icon(Icons.open_in_new),
            label: const Text('فتح صفحة الخصوصية المتقدمة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.royalGold,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20)
          .copyWith(bottom: MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('إعدادات المظهر'),
          _buildSwitchCard(
            icon: Icons.dark_mode,
            title: 'الوضع الليلي',
            value: _appearanceSettings['darkMode'] ?? true,
            onChanged: (val) {
              setState(() => _appearanceSettings['darkMode'] = val);
            },
          ),
          _buildSliderCard(
            icon: Icons.format_size,
            title: 'حجم الخط',
            subtitle: '${(_appearanceSettings['fontSize'] ?? 16.0).toInt()}',
            value: _appearanceSettings['fontSize'] ?? 16.0,
            min: 12.0,
            max: 24.0,
            divisions: 12,
            onChanged: (val) {
              setState(() => _appearanceSettings['fontSize'] = val);
            },
          ),
          _buildThemeSelector(
            icon: Icons.palette,
            title: 'الثيم',
            currentTheme: _appearanceSettings['theme'] ?? 'royal',
            onChanged: (val) {
              setState(() => _appearanceSettings['theme'] = val);
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AppearanceSettingsPage()),
            ),
            icon: const Icon(Icons.open_in_new),
            label: const Text('فتح صفحة المظهر'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.royalGold,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceRoomSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20)
          .copyWith(bottom: MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('إعدادات الغرف الصوتية'),
          _buildSwitchCard(
            icon: Icons.login,
            title: 'الدخول التلقائي',
            value: _voiceRoomSettings['autoJoinEnabled'] ?? false,
            onChanged: (val) {
              setState(() => _voiceRoomSettings['autoJoinEnabled'] = val);
            },
          ),
          _buildSwitchCard(
            icon: Icons.mic,
            title: 'تفعيل الميكروفون تلقائياً',
            value: _voiceRoomSettings['micAutoEnabled'] ?? true,
            onChanged: (val) {
              setState(() => _voiceRoomSettings['micAutoEnabled'] = val);
            },
          ),
          _buildSliderCard(
            icon: Icons.volume_up,
            title: 'مستوى صوت الميكروفون',
            subtitle:
                '${((_voiceRoomSettings['micVolume'] ?? 0.8) * 100).toInt()}%',
            value: _voiceRoomSettings['micVolume'] ?? 0.8,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            onChanged: (val) {
              setState(() => _voiceRoomSettings['micVolume'] = val);
            },
          ),
          _buildSwitchCard(
            icon: Icons.graphic_eq,
            title: 'إلغاء الضوضاء',
            value: _voiceRoomSettings['noiseCancellation'] ?? true,
            onChanged: (val) {
              setState(() => _voiceRoomSettings['noiseCancellation'] = val);
            },
          ),
          _buildSwitchCard(
            icon: Icons.waves,
            title: 'إلغاء الصدى',
            value: _voiceRoomSettings['echoCancellation'] ?? true,
            onChanged: (val) {
              setState(() => _voiceRoomSettings['echoCancellation'] = val);
            },
          ),
          _buildSwitchCard(
            icon: Icons.headset,
            title: 'تفعيل السماعات تلقائياً',
            value: _voiceRoomSettings['speakerAutoEnabled'] ?? true,
            onChanged: (val) {
              setState(() => _voiceRoomSettings['speakerAutoEnabled'] = val);
            },
          ),
          _buildSliderCard(
            icon: Icons.volume_down,
            title: 'مستوى صوت السماعات',
            subtitle:
                '${((_voiceRoomSettings['speakerVolume'] ?? 1.0) * 100).toInt()}%',
            value: _voiceRoomSettings['speakerVolume'] ?? 1.0,
            min: 0.0,
            max: 1.0,
            divisions: 10,
            onChanged: (val) {
              setState(() => _voiceRoomSettings['speakerVolume'] = val);
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VoiceRoomSettingsPage()),
            ),
            icon: const Icon(Icons.open_in_new),
            label: const Text('فتح صفحة الغرف الصوتية'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.royalGold,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsTab() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: UsageStatisticsPage(),
      ),
    );
  }

  Widget _buildTwoFactorAuthTab() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: TwoFactorAuthPage(),
      ),
    );
  }

  Widget _buildSessionsTab() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: SessionManagementPage(),
      ),
    );
  }

  Widget _buildSocialAccountsTab() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: SocialAccountsPage(),
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
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
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

  Widget _buildSliderCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Function(double) onChanged,
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
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: AppTheme.royalGold,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelector({
    required IconData icon,
    required String title,
    required String currentTheme,
    required Function(String) onChanged,
  }) {
    final themes = [
      {'name': 'Royal', 'value': 'royal', 'color': AppTheme.royalGold},
      {'name': 'Ocean', 'value': 'ocean', 'color': Colors.blue},
      {'name': 'Forest', 'value': 'forest', 'color': Colors.green},
      {'name': 'Sunset', 'value': 'sunset', 'color': Colors.orange},
      {'name': 'Purple', 'value': 'purple', 'color': Colors.purple},
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
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
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: themes.map((theme) {
              final isSelected = currentTheme == theme['value'];
              return InkWell(
                onTap: () => onChanged(theme['value'] as String),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (theme['color'] as Color).withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? theme['color'] as Color
                          : Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: theme['color'] as Color,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        theme['name'] as String,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
