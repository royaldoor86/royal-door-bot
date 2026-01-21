import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../app_theme.dart';

class FamilyTasksPage extends StatefulWidget {
  const FamilyTasksPage({super.key});

  @override
  State<FamilyTasksPage> createState() => _FamilyTasksPageState();
}

class _FamilyTasksPageState extends State<FamilyTasksPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A050E),
        appBar: AppBar(
          title: const Text('مهام المملكة الملكية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: AppTheme.background(
          child: StreamBuilder<UserModel>(
            stream: user != null ? _firestoreService.streamUserData(user.uid) : null,
            builder: (context, userSnapshot) {
              final userData = userSnapshot.data;
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.royalGold));
              }

              return Column(
                children: [
                  if (userData?.familyId != null) _buildFamilyProgressHeader(userData!.familyId!),
                  const SizedBox(height: 10),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      // جلب المهام الحقيقية من قاعدة البيانات
                      stream: _db.collection('family_tasks').orderBy('createdAt', descending: true).snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: AppTheme.royalGold));
                        }
                        
                        final tasks = snapshot.data?.docs ?? [];
                        if (tasks.isEmpty) {
                          return const Center(child: Text('لا توجد مهام ملكية نشطة حالياً 🛡️', style: TextStyle(color: Colors.white24)));
                        }

                        return ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            final taskData = tasks[index].data() as Map<String, dynamic>;
                            return _buildTaskCard(taskData);
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFamilyProgressHeader(String familyId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('families').doc(familyId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox.shrink();
        final data = snapshot.data!.data() as Map<String, dynamic>;
        int level = (data['level'] ?? 1).toInt();
        int totalPoints = (data['totalPoints'] ?? 0).toInt();
        int nextLevelPoints = level * level * 10000;
        double progress = totalPoints / nextLevelPoints;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF801336), Color(0xFF3D0B16)]),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [BoxShadow(color: Colors.redAccent.withValues(alpha: 0.2), blurRadius: 15)],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('تقدم مجد العائلة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('LV.$level', style: const TextStyle(color: AppTheme.royalGold, fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              const SizedBox(height: 15),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: Colors.black26,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.royalGold),
                ),
              ),
              const SizedBox(height: 10),
              Text('تبقي ${nextLevelPoints - totalPoints} نقطة للمستوى التالي ✨', style: const TextStyle(fontSize: 11, color: Colors.white38)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    List<String> rewards = [];
    if ((task['gems'] ?? 0) > 0) rewards.add('${task['gems']} 💎');
    if ((task['coins'] ?? 0) > 0) rewards.add('${task['coins']} 🪙');
    if ((task['xp'] ?? 0) > 0) rewards.add('${task['xp']} XP');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: AppTheme.glassContainer(
        padding: const EdgeInsets.all(16),
        opacity: 0.03,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppTheme.royalGold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)),
              child: const Icon(Icons.auto_awesome_mosaic_rounded, color: AppTheme.royalGold, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task['title'] ?? 'مهمة ملكية', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(task['desc'] ?? '', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: rewards.map((r) => Text(r, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.greenAccent))).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('انطلق لإتمام المهمة واثبت ولاءك للعائلة! 🛡️')));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.royalGold,
                foregroundColor: Colors.black,
                minimumSize: const Size(65, 34),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('انطلق', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
