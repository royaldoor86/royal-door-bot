import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../widgets/feature_lock_wrapper.dart';

class PointsPage extends StatefulWidget {
  const PointsPage({super.key});

  @override
  State<PointsPage> createState() => _PointsPageState();
}

class _PointsPageState extends State<PointsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  String _getPopularityRank(int points) {
    if (points >= 50000) return "أسطورة رويال الاجتماعية 👑✨";
    if (points >= 25000) return "سفير النجوم فوق العادة 🏛️";
    if (points >= 10000) return "سفير النجوم الملكي 🕊️";
    if (points >= 5000) return "نجم النجوم المتلألئ 🌟";
    if (points >= 2500) return "مؤثر رويال ذهبي 🏅";
    if (points >= 1000) return "محب النجوم 💖";
    return "عضو اجتماعي متألق 😊";
  }

  Color _getRankColor(int points) {
    if (points >= 25000) return const Color(0xFFFFD700);
    if (points >= 10000) return Colors.cyanAccent;
    if (points >= 5000) return Colors.purpleAccent;
    if (points >= 1000) return Colors.pinkAccent;
    return Colors.orangeAccent;
  }

  @override
  Widget build(BuildContext context) {
    final userAuth = FirebaseAuth.instance.currentUser;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: FeatureLockWrapper(
        lockField: 'isLeaderboardLocked',
        child: StreamBuilder<UserModel>(
          stream: userAuth != null
              ? _firestoreService.streamUserData(userAuth.uid)
              : null,
          builder: (context, snapshot) {
            final userData = snapshot.data;
            if (userData == null) {
              return const Scaffold(
                  backgroundColor: Color(0xFF0F0F1A),
                  body: Center(child: CircularProgressIndicator()));
            }

            int points = userData.agentData?['friendlyCoins'] ??
                (userData.userLevel * 125);

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
                        _buildSectionHeader(
                            "أكثر الأعضاء تألقاً ⭐", Icons.leaderboard),
                        _buildFriendlyLeaderboard(),
                        _buildInfoSection(),
                        _buildSectionHeader(
                            "سجل التألق والتقدير", Icons.history),
                        _buildFriendlyHistory(userData.uid),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: _buildExchangeButton(points, userData.uid),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSliverHeader(UserModel user, int points) {
    return SliverAppBar(
      expandedHeight: 320.0,
      pinned: true,
      backgroundColor: const Color(0xFF0F0F1A),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF6B4EE0), Color(0xFF0F0F1A)],
                ),
              ),
            ),
            // دوائر زخرفية
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      shape: BoxShape.circle)),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: _getRankColor(points), width: 2),
                        boxShadow: [
                          BoxShadow(
                              color:
                                  _getRankColor(points).withValues(alpha: 0.2),
                              blurRadius: 20,
                              spreadRadius: 5)
                        ],
                      ),
                    ),
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.white24,
                      backgroundImage: user.profilePic.isNotEmpty
                          ? NetworkImage(user.profilePic)
                          : null,
                      child: user.profilePic.isEmpty
                          ? const Icon(Icons.person,
                              size: 40, color: Colors.white)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                const Text('رصيد مكافأة الصداقة 💎',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        letterSpacing: 1.1)),
                Text('$points',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 52,
                        fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getRankColor(points).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: _getRankColor(points).withValues(alpha: 0.3)),
                  ),
                  child: Text(_getPopularityRank(points),
                      style: TextStyle(
                          color: _getRankColor(points),
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendlyLeaderboard() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('users')
          .orderBy('agentData.friendlyCoins', descending: true)
          .limit(3)
          .snapshots(),
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
                        backgroundImage:
                            (user['profilePic'] ?? "").toString().isNotEmpty
                                ? NetworkImage(user['profilePic'])
                                : null,
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                            color: index == 0 ? Colors.amber : Colors.grey,
                            shape: BoxShape.circle),
                        child: Text("${index + 1}",
                            style: const TextStyle(
                                fontSize: 10, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(user['name'] ?? "مستخدم",
                      style:
                          const TextStyle(color: Colors.white, fontSize: 10)),
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
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
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
                const Text('تقدمك الاجتماعي (XP)',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: (points % 1000) / 1000,
                    backgroundColor: Colors.white10,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(_getRankColor(points)),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 5),
                Text('بقي ${1000 - (points % 1000)} XP للرتبة التالية',
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 10)),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.stars_rounded, color: Colors.amber, size: 18),
              SizedBox(width: 8),
              Text('دليل مكافأة الصداقة 💎',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          _buildRewardInfoRow(
              Icons.card_giftcard, "كل 20 مكافأة ملكية", "1 XP"),
          _buildRewardInfoRow(Icons.favorite, "كل 50 تفاعل ملكي", "10 كوينز"),
          _buildRewardInfoRow(
              Icons.person_add, "كل 5 إضافات أصدقاء", "10 كوينز"),
          _buildRewardInfoRow(Icons.room, "كل 10 متابعة للغرف", "10 كوينز"),
          const Divider(color: Colors.white10, height: 30),
          Text(
            'استخدم "تحويل الود" لتحويل الكوينزات إلى محفظتك الشخصية. XP تتحول تلقائياً إلى المستوى الملكي.',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 11,
                height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardInfoRow(IconData icon, String label, String reward) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white38, size: 16),
              const SizedBox(width: 10),
              Text(label,
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
          Text(reward,
              style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFriendlyHistory(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('users')
          .doc(uid)
          .collection('friendly_logs')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
              height: 100, child: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(40.0),
            child: Text(
                'لا يوجد سجل تفاعلات اجتماعية حالياً.. ابدأ بالتفاعل! 🌱',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white10, fontSize: 12)),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final log =
                snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final String type = log['action'] ?? 'social';
            IconData icon = Icons.star;
            Color iconColor = Colors.amber;

            if (type == 'like') {
              icon = Icons.favorite;
              iconColor = Colors.pink;
            }
            if (type == 'friend_request') {
              icon = Icons.person_add;
              iconColor = Colors.blue;
            }
            if (type == 'follow') {
              icon = Icons.check_circle;
              iconColor = Colors.cyan;
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(15),
                child: ListTile(
                  leading: CircleAvatar(
                      backgroundColor: iconColor.withValues(alpha: 0.1),
                      child: Icon(icon, color: iconColor, size: 16)),
                  title: Text(log['message'] ?? 'مكافأة اجتماعية',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                  subtitle: Text(_formatTimestamp(log['timestamp']),
                      style:
                          const TextStyle(color: Colors.white24, fontSize: 10)),
                  trailing: Text('+${log['points']} XP',
                      style: TextStyle(
                          color: iconColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12)),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatTimestamp(dynamic ts) {
    if (ts == null) return '';
    if (ts is Timestamp) {
      final date = ts.toDate();
      return "${date.hour}:${date.minute.toString().padLeft(2, '0')}";
    }
    return '';
  }

  Widget _buildExchangeButton(int points, String uid) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: points >= 50 ? () => _exchangePoints(points, uid) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            disabledBackgroundColor: Colors.white10,
            minimumSize: const Size(double.infinity, 55),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: const Text('تحويل الود إلى كوينزات ملكية 💎',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  void _exchangePoints(int points, String uid) async {
    // تحويل النقاط إلى كوينزات (كل نقطة = 1 كوينز)
    int coinsToReceive = points;

    // حساب XP من النقاط (كل 20 نقطة = 1 XP)
    int xpToReceive = (points / 20).floor();

    await _db.runTransaction((tx) async {
      final userRef = _db.collection('users').doc(uid);

      // تحويل الكوينزات إلى المحفظة الشخصية
      tx.update(userRef, {
        'stars': FieldValue.increment(coinsToReceive),
        'coins': FieldValue.increment(coinsToReceive),
        'royalXP': FieldValue.increment(xpToReceive),
        'agentData.friendlyCoins': 0,
      });
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'مبروك! تم تحويل رصيدك إلى $coinsToReceive كوينز 💎 و $xpToReceive XP للترقية'),
          backgroundColor: Colors.amber));
    }
  }
}
