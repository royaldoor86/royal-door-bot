import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

class PointsPage extends StatefulWidget {
  const PointsPage({super.key});

  @override
  State<PointsPage> createState() => _PointsPageState();
}

class _PointsPageState extends State<PointsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  String _getPopularityRank(int points) {
    if (points >= 10000) return "سفير الود الملكي 🕊️";
    if (points >= 5000) return "نجم المجتمع 🌟";
    if (points >= 1000) return "محبوب الجماهير 💖";
    return "عضو ودود 😊";
  }

  Color _getRankColor(int points) {
    if (points >= 10000) return Colors.amber;
    if (points >= 5000) return Colors.purpleAccent;
    if (points >= 1000) return Colors.pinkAccent;
    return Colors.orangeAccent;
  }

  @override
  Widget build(BuildContext context) {
    final userAuth = FirebaseAuth.instance.currentUser;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: StreamBuilder<UserModel>(
        stream: userAuth != null ? _firestoreService.streamUserData(userAuth.uid) : null,
        builder: (context, snapshot) {
          final userData = snapshot.data;
          if (userData == null) return const Scaffold(backgroundColor: Color(0xFF0F0F1A), body: Center(child: CircularProgressIndicator()));

          int points = userData.agentData?['friendlyPoints'] ?? (userData.userLevel * 125); 

          return Scaffold(
            backgroundColor: const Color(0xFF0F0F1A),
            body: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverHeader(userData, points),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildRankCard(points),
                      _buildSectionHeader("أكثر الأعضاء وداً 🏆", Icons.leaderboard),
                      _buildFriendlyLeaderboard(), // إضافة لوحة المتصدرين الجديدة
                      _buildInfoSection(),
                      _buildSectionHeader("سجل الود والتقدير", Icons.history),
                      _buildFriendlyHistory(userData.uid),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
            bottomNavigationBar: _buildExchangeButton(points, userData.uid),
          );
        }
      ),
    );
  }

  Widget _buildSliverHeader(UserModel user, int points) {
    return SliverAppBar(
      expandedHeight: 280.0,
      pinned: true,
      backgroundColor: const Color(0xFF1A1A2E),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF57C00), Color(0xFF0F0F1A)],
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                CircleAvatar(
                  radius: 45,
                  backgroundColor: Colors.white24,
                  backgroundImage: user.profilePic.isNotEmpty ? NetworkImage(user.profilePic) : null,
                  child: user.profilePic.isEmpty ? const Icon(Icons.person, size: 40, color: Colors.white) : null,
                ),
                const SizedBox(height: 15),
                const Text('رصيد النقاط الودية', style: TextStyle(color: Colors.white70, fontSize: 14)),
                Text('$points', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900)),
                Text(_getPopularityRank(points), style: TextStyle(color: Colors.amber.withValues(alpha: 0.8), fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendlyLeaderboard() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('users').orderBy('agentData.friendlyPoints', descending: true).limit(3).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 100);
        final topUsers = snapshot.data!.docs;

        return Container(
          height: 120,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(topUsers.length, (index) {
              final user = topUsers[index].data() as Map<String, dynamic>;
              return Column(
                children: [
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      CircleAvatar(
                        radius: index == 0 ? 35 : 28,
                        backgroundColor: Colors.amber.withValues(alpha: 0.2),
                        backgroundImage: (user['profilePic'] ?? "").toString().isNotEmpty ? NetworkImage(user['profilePic']) : null,
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: index == 0 ? Colors.amber : Colors.grey, shape: BoxShape.circle),
                        child: Text("${index + 1}", style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(user['name'] ?? "مستخدم", style: const TextStyle(color: Colors.white, fontSize: 10)),
                ],
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 10),
      child: Row(
        children: [
          Icon(icon, color: Colors.amber, size: 20),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRankCard(int points) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: _getRankColor(points).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.stars_rounded, color: _getRankColor(points), size: 40),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('تقدمك الاجتماعي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (points % 1000) / 1000,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(_getRankColor(points)),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 5),
                Text('بقي ${1000 - (points % 1000)} نقطة للرتبة التالية', style: const TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('عن النقاط الودية', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text(
            'هي عملة التقدير في رويال دور. يمنحك إياها الآخرون تعبيراً عن حبهم واحترامهم لتفاعلك الراقي في الرومات.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendlyHistory(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('users').doc(uid).collection('friendly_logs').orderBy('timestamp', descending: true).limit(5).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(40.0),
            child: Text('لا يوجد سجل تفاعلات حالياً', style: TextStyle(color: Colors.white10)),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final log = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: const CircleAvatar(backgroundColor: Colors.white10, child: Icon(Icons.favorite, color: Colors.pink, size: 18)),
              title: Text(log['senderName'] ?? 'محب مجهول', style: const TextStyle(color: Colors.white, fontSize: 14)),
              subtitle: Text(log['action'] ?? 'منحك نقاط ودية', style: const TextStyle(color: Colors.white38, fontSize: 12)),
              trailing: const Text('+10', style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
            );
          },
        );
      },
    );
  }

  Widget _buildExchangeButton(int points, String uid) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: points >= 1000 ? () => _exchangePoints(points, uid) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            disabledBackgroundColor: Colors.white10,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: const Text('تحويل الود إلى كوينز ملكية 🪙', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  void _exchangePoints(int points, String uid) async {
    int coinsToReceive = (points / 10).floor(); 
    
    await _db.runTransaction((tx) async {
      final userRef = _db.collection('users').doc(uid);
      tx.update(userRef, {
        'coins': FieldValue.increment(coinsToReceive),
        'agentData.friendlyPoints': 0, 
      });
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('مبروك! تم تحويل نقاطك إلى $coinsToReceive كوينز 💰'), backgroundColor: Colors.amber));
    }
  }
}
