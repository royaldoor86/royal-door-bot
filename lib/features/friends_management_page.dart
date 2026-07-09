import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/social_progress_bar.dart';

class FriendsManagementPage extends StatelessWidget {
  const FriendsManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('يرجى تسجيل الدخول')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الأصدقاء')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SocialProgressBar(userId: currentUser.uid),
            const SizedBox(height: 16),
            _buildFriendsSection(),
            const SizedBox(height: 16),
            _buildSocialActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'أصدقائي',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          // TODO: Add friends list from Firestore
          Text('قائمة الأصدقاء ستظهر هنا'),
        ],
      ),
    );
  }

  Widget _buildSocialActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'الإجراءات الاجتماعية',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            '• متابعة المستخدمين لكسب نجوم ⭐ ودية\n'
            '• إعجاب بالملفات الشخصية\n'
            '• ترك تعليقات\n'
            '• مشاركة الملفات الشخصية',
            style: TextStyle(height: 1.5),
          ),
        ],
      ),
    );
  }
}
