import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../app_theme.dart';

class UserLevelPage extends StatefulWidget {
  const UserLevelPage({super.key});

  @override
  State<UserLevelPage> createState() => _UserLevelPageState();
}

class _UserLevelPageState extends State<UserLevelPage> {
  final FirestoreService _firestoreService = FirestoreService();

  // مصفوفة عتبات الخبرة (XP) لكل مستوى (مثال: 0, 1000, 3000, ...)
  final List<int> levelThresholds = [
    0, 1000, 3000, 7000, 15000, 40000, 100000, 250000, 500000, 1000000,
    2000000, 4000000, 8000000, 15000000, 30000000, 50000000, 80000000, 120000000, 200000000, 350000000
  ];

  int getLevelFromXP(int xp) {
    for (int i = levelThresholds.length - 1; i >= 0; i--) {
      if (xp >= levelThresholds[i]) return i + 1;
    }
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF020A1A),
        appBar: AppBar(
          title: const Text('المستوى الملكي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: AppTheme.background(
          child: StreamBuilder<UserModel>(
            stream: user != null ? _firestoreService.streamUserData(user.uid) : null,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.cyanAccent));
              }
              
              final userData = snapshot.data;
              if (userData == null) return const Center(child: Text('تعذر تحميل البيانات', style: TextStyle(color: Colors.white)));

              // استخدام XP الحقيقي من قاعدة البيانات
              final int currentXP = userData.royalXP;
              final int currentLevel = getLevelFromXP(currentXP);
              
              // حساب التقدم للمستوى القادم
              int nextLevelXP = currentLevel < levelThresholds.length 
                  ? levelThresholds[currentLevel] 
                  : levelThresholds.last;
              int currentLevelBaseXP = levelThresholds[currentLevel - 1];
              
              double progress = 0.0;
              if (currentLevel < levelThresholds.length) {
                progress = (currentXP - currentLevelBaseXP) / (nextLevelXP - currentLevelBaseXP);
              } else {
                progress = 1.0;
              }

              int remainingXP = nextLevelXP - currentXP;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildLevelHeader(currentLevel, progress, currentXP, nextLevelXP, remainingXP),
                    const SizedBox(height: 30),
                    _buildSectionTitle('امتيازاتك الملكية'),
                    _buildPrivilegesList(currentLevel),
                    const SizedBox(height: 30),
                    _buildLevelUpTips(),
                    const SizedBox(height: 50),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLevelHeader(int level, double progress, int currentXP, int nextLevelXP, int remainingXP) {
    return AppTheme.glassContainer(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      opacity: 0.05,
      borderGlow: true,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 130, height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF0D1B3E)]),
                  boxShadow: [BoxShadow(color: Colors.cyan.withValues(alpha: 0.3), blurRadius: 30, spreadRadius: 5)],
                ),
              ),
              Column(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
                  Text(level.toString(), style: const TextStyle(color: Colors.white, fontSize: 45, fontWeight: FontWeight.w900)),
                  const Text('LEVEL', style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('المستوى $level', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text('المستوى ${level + 1}', style: const TextStyle(color: Colors.white38)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$currentXP / $nextLevelXP XP', style: const TextStyle(color: Colors.white38, fontSize: 11)),
              if (remainingXP > 0)
                Text('تبقي $remainingXP XP للمستوى التالي', style: TextStyle(color: Colors.cyanAccent.withValues(alpha: 0.6), fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: Align(alignment: Alignment.centerRight, child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildPrivilegesList(int level) {
    final List<Map<String, dynamic>> privileges = [
      {'icon': Icons.chat_bubble_outlined, 'title': 'ألوان رسائل ملكية', 'color': Colors.cyanAccent, 'minLevel': 5},
      {'icon': Icons.admin_panel_settings_outlined, 'title': 'تعيين مشرفين خاصين', 'color': Colors.greenAccent, 'minLevel': 10},
      {'icon': Icons.card_giftcard, 'title': 'هدايا نادرة وحصرية', 'color': Colors.amber, 'minLevel': 15},
      {'icon': Icons.rocket_launch_outlined, 'title': 'تأثير دخول متوهج', 'color': Colors.purpleAccent, 'minLevel': 20},
    ];

    return Column(
      children: privileges.map((priv) {
        bool isUnlocked = level >= (priv['minLevel'] as int);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: AppTheme.glassContainer(
            padding: const EdgeInsets.all(5),
            opacity: 0.02,
            child: ListTile(
              leading: Icon(priv['icon'] as IconData, color: isUnlocked ? priv['color'] as Color : Colors.white24, size: 22),
              title: Text(priv['title'] as String, style: TextStyle(color: isUnlocked ? Colors.white : Colors.white24, fontSize: 14)),
              subtitle: !isUnlocked ? Text('يفتح في مستوى ${priv['minLevel']}', style: const TextStyle(color: Colors.white12, fontSize: 10)) : null,
              trailing: Icon(
                isUnlocked ? Icons.check_circle_rounded : Icons.lock_outline_rounded, 
                color: isUnlocked ? Colors.greenAccent : Colors.white10, 
                size: 20
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLevelUpTips() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0D1B3E), Color(0xFF00E5FF)]),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.cyan.withValues(alpha: 0.2), blurRadius: 15)],
      ),
      child: const Row(
        children: [
          Icon(Icons.tips_and_updates_rounded, color: Colors.white, size: 40),
          SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('نصيحة الصعود السريع', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 5),
                Text('التفاعل المستمر في الرومات وإهداء الأصدقاء يرفع من شأنك في المملكة بسرعة مذهلة!', style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
