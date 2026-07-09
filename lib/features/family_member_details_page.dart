import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_theme.dart';
import '../models/user_model.dart';

class FamilyMemberDetailsPage extends StatefulWidget {
  final String memberId;
  final String familyId;

  const FamilyMemberDetailsPage({
    super.key,
    required this.memberId,
    required this.familyId,
  });

  @override
  State<FamilyMemberDetailsPage> createState() =>
      _FamilyMemberDetailsPageState();
}

class _FamilyMemberDetailsPageState extends State<FamilyMemberDetailsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A050E),
        appBar: AppBar(
          title:
              const Text('تفاصيل العضو', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3D0B16), Color(0xFF1A050E), Color(0x00000000)],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildMemberHeader(),
                const SizedBox(height: 20),
                _buildContributionSection(),
                const SizedBox(height: 20),
                _buildJoinDateSection(),
                const SizedBox(height: 20),
                _buildPersonalStatsSection(),
                const SizedBox(height: 20),
                _buildFamilyRewardsSection(),
                const SizedBox(height: 20),
                _buildActivityChart(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMemberHeader() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('users').doc(widget.memberId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.amber));
        }

        final userData = UserModel.fromMap(
          snapshot.data!.data() as Map<String, dynamic>,
          widget.memberId,
        );

        return AppTheme.glassContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: userData.profilePic.isNotEmpty
                    ? NetworkImage(userData.profilePic)
                    : null,
                backgroundColor: Colors.white10,
                child: userData.profilePic.isEmpty
                    ? Text(userData.name[0].toUpperCase(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold))
                    : null,
              ),
              const SizedBox(height: 15),
              Text(userData.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              Text('المستوى: ${userData.calculatedRoyalLevel}',
                  style: const TextStyle(color: Colors.amber, fontSize: 14)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContributionSection() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _db
          .collection('families')
          .doc(widget.familyId)
          .collection('members')
          .doc(widget.memberId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final memberData = snapshot.data!.data() as Map<String, dynamic>?;
        final contribution = memberData?['totalContribution'] ?? 0;

        return AppTheme.glassContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('مساهمة العضو في العائلة',
                  style: TextStyle(
                      color: Colors.amber,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('إجمالي المساهمة',
                      style: TextStyle(color: Colors.white70)),
                  Text('$contribution نقطة',
                      style: const TextStyle(
                          color: Colors.cyanAccent,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: (contribution % 1000) / 1000,
                backgroundColor: Colors.white10,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
              const SizedBox(height: 5),
              Text('${(contribution % 1000)}/1000 نقطة للمستوى التالي',
                  style: const TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildJoinDateSection() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _db
          .collection('families')
          .doc(widget.familyId)
          .collection('members')
          .doc(widget.memberId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final memberData = snapshot.data!.data() as Map<String, dynamic>?;
        final joinDate = memberData?['joinDate'] as Timestamp?;

        return AppTheme.glassContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('تاريخ الانضمام',
                  style: TextStyle(
                      color: Colors.amber,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              if (joinDate != null)
                Text(
                  '${joinDate.toDate().day}/${joinDate.toDate().month}/${joinDate.toDate().year}',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                )
              else
                const Text('غير متاح', style: TextStyle(color: Colors.white38)),
              const SizedBox(height: 10),
              if (joinDate != null)
                Text(
                  'عضو منذ ${_calculateDaysSince(joinDate.toDate())} يوم',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPersonalStatsSection() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('users').doc(widget.memberId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final gems = userData?['gems'] ?? 0;
        final stars = userData?['stars'] ?? 0;
        final coins = userData?['coins'] ?? 0;

        return AppTheme.glassContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('الإحصائيات الشخصية',
                  style: TextStyle(
                      color: Colors.amber,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              _statRow('الجواهر', '$gems 💎', Colors.cyanAccent),
              const SizedBox(height: 10),
              _statRow('النجوم', '$stars ⭐', Colors.amber),
              const SizedBox(height: 10),
              _statRow('الكوينز', '$coins 🪙', Colors.orange),
            ],
          ),
        );
      },
    );
  }

  Widget _statRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        Text(value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildFamilyRewardsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('families')
          .doc(widget.familyId)
          .collection('member_rewards')
          .doc(widget.memberId)
          .collection('rewards')
          .orderBy('awardedAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final rewards = snapshot.data!.docs;

        if (rewards.isEmpty) {
          return AppTheme.glassContainer(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.emoji_events_outlined,
                    size: 50, color: Colors.white24),
                const SizedBox(height: 10),
                const Text('لا توجد جوائز بعد',
                    style: TextStyle(color: Colors.white38)),
              ],
            ),
          );
        }

        return AppTheme.glassContainer(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('الجوائز من العائلة',
                  style: TextStyle(
                      color: Colors.amber,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rewards.length,
                itemBuilder: (context, index) {
                  final reward = rewards[index].data() as Map<String, dynamic>;
                  return _rewardItem(reward);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _rewardItem(Map<String, dynamic> reward) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.card_giftcard, color: Colors.amber, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reward['rewardName'] ?? 'جائزة',
                    style: const TextStyle(color: Colors.white)),
                Text(reward['description'] ?? '',
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          if (reward['awardedAt'] != null)
            Text(
              _formatDate((reward['awardedAt'] as Timestamp).toDate()),
              style: const TextStyle(color: Colors.white24, fontSize: 10),
            ),
        ],
      ),
    );
  }

  Widget _buildActivityChart() {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('نشاط العضو (آخر 7 أيام)',
              style: TextStyle(
                  color: Colors.amber,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bar_chart, size: 50, color: Colors.white24),
                  const SizedBox(height: 10),
                  const Text('رسم بياني للنشاط',
                      style: TextStyle(color: Colors.white38)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _calculateDaysSince(DateTime date) {
    return DateTime.now().difference(date).inDays;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
