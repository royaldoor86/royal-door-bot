import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../services/privilege_service.dart';
import '../models/user_model.dart';
import '../app_theme.dart';

class AccountLevelPage extends StatefulWidget {
  const AccountLevelPage({super.key});

  @override
  State<AccountLevelPage> createState() => _AccountLevelPageState();
}

class _AccountLevelPageState extends State<AccountLevelPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  // عتبات الخبرة لكل مستوى
  final List<int> _levelThresholds = [
    0,
    1000,
    3000,
    7000,
    15000,
    40000,
    100000,
    300000,
    500000,
    1000000,
    2000000,
    4000000,
    8000000,
    15000000,
    30000000,
    50000000,
    80000000,
    100000000,
    110000000,
    120000000
  ];

  int _calculateLevel(int xp) {
    for (int i = _levelThresholds.length - 1; i >= 0; i--) {
      if (xp >= _levelThresholds[i]) return i + 1;
    }
    return 1;
  }

  Color _getLevelColor(int level) {
    if (level >= 17) return const Color(0xFFFFD700);
    if (level >= 13) return Colors.purpleAccent;
    if (level >= 9) return Colors.blueAccent;
    if (level >= 5) return Colors.cyanAccent;
    return Colors.orangeAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundBlack,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('مستوى الحساب',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: AppTheme.background(
          child: StreamBuilder<UserModel>(
            stream: _firestoreService.streamUserData(_currentUserId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.royalGold));
              }

              final userData = snapshot.data!;
              int currentLevel = _calculateLevel(userData.royalXP);
              Color themeColor = _getLevelColor(currentLevel);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLevelHeader(userData, currentLevel, themeColor),
                    const SizedBox(height: 30),
                    _buildPrivilegesSection(currentLevel, themeColor),
                    const SizedBox(height: 30),
                    _buildLevelProgress(userData, currentLevel, themeColor),
                    const SizedBox(height: 30),
                    _buildSpecialPrivileges(userData),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLevelHeader(UserModel userData, int level, Color themeColor) {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(25),
      opacity: 0.07,
      borderGlow: true,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('مستوى الحساب',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 5),
                  Text('ROYAL $level',
                      style: TextStyle(
                          color: themeColor,
                          fontSize: 36,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: themeColor.withValues(alpha: 0.1),
                  border: Border.all(
                      color: themeColor.withValues(alpha: 0.3), width: 2),
                ),
                child: Icon(Icons.shield_moon_rounded,
                    size: 50, color: themeColor),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('خبرة رويال: ${userData.royalXP}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
              Text('المستوى القادم: ${level < 20 ? level + 1 : 'الأقصى'}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelProgress(UserModel userData, int level, Color themeColor) {
    int currentThreshold = _levelThresholds[level - 1];
    int nextThreshold =
        level < 20 ? _levelThresholds[level] : _levelThresholds.last;
    int xpInLevel = userData.royalXP - currentThreshold;
    int xpNeeded = nextThreshold - currentThreshold;
    double progress =
        xpNeeded > 0 ? (xpInLevel / xpNeeded).clamp(0.0, 1.0) : 1.0;

    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(20),
      opacity: 0.05,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('تقدم المستوى',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.white10,
              valueColor: AlwaysStoppedAnimation<Color>(themeColor),
            ),
          ),
          const SizedBox(height: 10),
          Text('$xpInLevel / $xpNeeded XP',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildPrivilegesSection(int level, Color themeColor) {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(20),
      opacity: 0.05,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.workspace_premium, color: themeColor, size: 24),
              const SizedBox(width: 10),
              const Text('امتيازاتك الحالية',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          FutureBuilder<List<String>>(
            future: PrivilegeService.getActivePrivileges(_currentUserId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.royalGold));
              }

              final privileges = snapshot.data!;
              if (privileges.isEmpty) {
                return const Text('لا توجد امتيازات مفعلة حالياً',
                    style: TextStyle(color: Colors.white70));
              }

              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: privileges.take(12).map((privilege) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: themeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: themeColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: themeColor, size: 16),
                        const SizedBox(width: 6),
                        Text(_getPrivilegeName(privilege),
                            style: TextStyle(color: themeColor, fontSize: 12)),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialPrivileges(UserModel userData) {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(20),
      opacity: 0.05,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('الامتيازات الخاصة',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildSpecialPrivilegeTile('مضاد الطرد', Icons.admin_panel_settings,
              userData.privilegeSettings['anti_kick'] ?? false),
          _buildSpecialPrivilegeTile('هدايا الإدارة', Icons.card_giftcard,
              userData.privilegeSettings['admin_gifts'] ?? false),
          _buildSpecialPrivilegeTile('مركبة مخصصة', Icons.directions_car,
              userData.privilegeSettings['custom_car'] ?? false),
          _buildSpecialPrivilegeTile('حساب موثق', Icons.verified,
              userData.privilegeSettings['account_verify'] ?? false),
        ],
      ),
    );
  }

  Widget _buildSpecialPrivilegeTile(
      String title, IconData icon, bool isActive) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.royalGold.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                color: isActive ? AppTheme.royalGold : Colors.white38,
                size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(title,
                style: const TextStyle(color: Colors.white, fontSize: 15)),
          ),
          Icon(
            isActive ? Icons.check_circle : Icons.cancel,
            color: isActive ? Colors.greenAccent : Colors.white24,
            size: 20,
          ),
        ],
      ),
    );
  }

  String _getPrivilegeName(String privilegeId) {
    final names = {
      'mic_frame': 'إطار ميكروفون',
      'exclusive_badge': 'شارة حصرية',
      'status_badge': 'شارة الحالة',
      'chat_bubble': 'فقاعة حصرية',
      'follow_limit': 'زيادة المتابعة',
      'friends_limit': 'زيادة الأصدقاء',
      'entry_statement': 'بيان الدخول',
      'hide_country': 'إخفاء الدولة',
      'hide_last_seen': 'إخفاء الظهور',
      'game_exp': 'خبرة الألعاب x2',
      'exclusive_car': 'مركبة حصرية',
      'stream_banner': 'بانر البث',
      'anti_mute': 'منع الحظر',
      'extra_exp': 'مكافأة إضافية',
      'mystery_man': 'الرجل الغامض',
      'exclusive_seat': 'مقعد رويال',
      'entry_effect': 'تأثير الدخول',
      'monthly_gift': 'هدية شهرية',
      'glowing_name': 'اسم متوهج',
      'store_coupons': 'قسائم المتجر',
      'freeze_charm': 'تجميد الجاذبية',
      'animated_profile': 'بروفايل متحرك',
      'anti_remove': 'مضاد الإزالة',
      'hide_rank': 'إخفاء الترتيب',
      'elite_frame': 'إطار فاخر',
      'profile_deco': 'تزيين البروفايل',
      'global_promo_notif': 'إشعار عالمي',
      'special_id': 'آيدي مميز',
      'anti_kick': 'مضاد الطرد',
      'military_frame': 'إطار عسكري',
      'vip_welcome': 'ترحيب VIP',
      'custom_car': 'مركبة مخصصة',
      'crowned_title': 'لقب ملكي',
      'admin_gifts': 'هدايا الإدارة',
      'account_verify': 'توثيق الحساب',
    };
    return names[privilegeId] ?? privilegeId;
  }
}
