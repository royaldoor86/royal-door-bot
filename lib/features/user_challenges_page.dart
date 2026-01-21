import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/challenges_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserChallengesPage extends StatefulWidget {
  const UserChallengesPage({super.key});

  @override
  State<UserChallengesPage> createState() => _UserChallengesPageState();
}

class _UserChallengesPageState extends State<UserChallengesPage> with SingleTickerProviderStateMixin {
  String filter = 'active'; // active, ended
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF15050B),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFF2D0B16), Color(0xFF15050B)],
            ),
          ),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildRoyalAppBar(),
              SliverToBoxAdapter(child: _buildFilterTabs()),
              _buildChallengesList(user),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoyalAppBar() {
    return SliverAppBar(
      expandedHeight: 180.0,
      pinned: true,
      backgroundColor: const Color(0xFF2D0B16),
      flexibleSpace: FlexibleSpaceBar(
        background: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.military_tech_rounded, size: 60, color: Colors.amber),
            const Text('الساحة الملكية للتحديات', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            Text('أكمل مهامك اليومية واحصد الجوائز 🏆', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _filterChip('النشطة', 'active'),
          const SizedBox(width: 15),
          _filterChip('المنتهية', 'ended'),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    bool isSelected = filter == value;
    return GestureDetector(
      onTap: () => setState(() => filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.3), blurRadius: 10)] : [],
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.black : Colors.white54, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildChallengesList(User? user) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: ChallengesService.challengesStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: Colors.amber)));
        
        final docs = snapshot.data!.docs;
        final now = DateTime.now();
        
        final filteredDocs = docs.where((doc) {
          final end = doc.data()['endAt'] != null ? (doc.data()['endAt'] as Timestamp).toDate() : null;
          final isEnded = end != null && end.isBefore(now);
          return filter == 'active' ? !isEnded : isEnded;
        }).toList();

        if (filteredDocs.isEmpty) {
          return const SliverFillRemaining(child: Center(child: Text('لا توجد تحديات في هذا القسم حالياً', style: TextStyle(color: Colors.white24))));
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildChallengeCard(filteredDocs[index], user),
            childCount: filteredDocs.length,
          ),
        );
      },
    );
  }

  Widget _buildChallengeCard(QueryDocumentSnapshot<Map<String, dynamic>> doc, User? user) {
    final data = doc.data();
    final String challengeId = doc.id;

    return StreamBuilder<DocumentSnapshot>(
      stream: user != null ? _db.collection('challenge_logs').doc(user.uid).collection('logs').doc(challengeId).snapshots() : null,
      builder: (context, logSnap) {
        final logData = logSnap.data?.data() as Map<String, dynamic>?;
        final int progress = logData?['progress'] ?? 0;
        final int target = data['targetCount'] ?? 1;
        final bool isClaimed = logData?['isClaimed'] ?? false;
        final bool isCompleted = progress >= target;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: isCompleted ? Colors.green.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(15)),
                          child: Icon(isCompleted ? Icons.workspace_premium : Icons.bolt, color: Colors.amber, size: 28),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(data['title'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              Text(data['description'] ?? '', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
                            ],
                          ),
                        ),
                        if (isCompleted && !isClaimed)
                          _buildClaimButton(challengeId)
                        else if (isClaimed)
                          const Icon(Icons.check_circle, color: Colors.green, size: 30)
                        else
                          Text('$progress/$target', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildProgressBar(progress, target, isCompleted),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildProgressBar(int current, int target, bool isCompleted) {
    double value = (current / target).clamp(0.0, 1.0);
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(isCompleted ? Colors.green : Colors.amber),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('التقدم: ${(value * 100).toInt()}%', style: const TextStyle(color: Colors.white24, fontSize: 10)),
            Text('الجائزة: ${100} 🪙', style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        )
      ],
    );
  }

  Widget _buildClaimButton(String id) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 15)),
      onPressed: () async {
        try {
          await ChallengesService.claimChallengeReward({'challengeId': id});
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('مبروك! تم استلام المكافأة الملكية 💰'), backgroundColor: Colors.green));
        } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أو تم الاستلام مسبقاً')));
        }
      },
      child: const Text('استلام', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
