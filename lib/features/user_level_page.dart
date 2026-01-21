import 'dart:ui';
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
              final userData = snapshot.data;
              final int currentLevel = userData?.userLevel ?? 1;
              final double progress = (currentLevel % 10) / 10.0;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildLevelHeader(currentLevel, progress),
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

  Widget _buildLevelHeader(int level, double progress) {
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
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
            ),
          ),
          const SizedBox(height: 10),
          Text('تبقي 1,500 XP للوصول للعرش التالي', style: TextStyle(color: Colors.cyanAccent.withValues(alpha: 0.6), fontSize: 11)),
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
      {'icon': Icons.chat_bubble_outlined, 'title': 'ألوان رسائل ملكية', 'color': Colors.cyanAccent},
      {'icon': Icons.admin_panel_settings_outlined, 'title': 'تعيين مشرفين خاصين', 'color': Colors.greenAccent},
      {'icon': Icons.card_giftcard, 'title': 'هدايا نادرة وحصرية', 'color': Colors.amber},
      {'icon': Icons.rocket_launch_outlined, 'title': 'تأثير دخول متوهج', 'color': Colors.purpleAccent},
    ];

    return Column(
      children: privileges.map((priv) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        child: AppTheme.glassContainer(
          padding: const EdgeInsets.all(5),
          opacity: 0.02,
          child: ListTile(
            leading: Icon(priv['icon'], color: priv['color'], size: 22),
            title: Text(priv['title'], style: const TextStyle(color: Colors.white, fontSize: 14)),
            trailing: const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 20),
          ),
        ),
      )).toList(),
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
