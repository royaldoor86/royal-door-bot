import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/family_service.dart';
import '../app_theme.dart';
import '../models/family_daily_reward_model.dart';

class FamilyDailyRewardsPage extends StatefulWidget {
  final String familyId;
  const FamilyDailyRewardsPage({super.key, required this.familyId});

  @override
  State<FamilyDailyRewardsPage> createState() => _FamilyDailyRewardsPageState();
}

class _FamilyDailyRewardsPageState extends State<FamilyDailyRewardsPage> {
  final FamilyService _familyService = FamilyService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A050E),
        appBar: AppBar(
          title: const Text('المكافآت اليومية',
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3D0B16), Color(0xFF1A050E)],
            ),
          ),
          child: Column(
            children: [
              // Daily Login Reward
              AppTheme.glassContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('مكافأة تسجيل الدخول اليومي',
                        style: TextStyle(
                            color: Colors.amber,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    StreamBuilder<DocumentSnapshot>(
                      stream: _db
                          .collection('family_daily_rewards')
                          .doc('${widget.familyId}_login')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.amber));
                        }

                        final data =
                            snapshot.data!.data() as Map<String, dynamic>?;
                        final lastClaimed = data?['lastClaimed'] as Timestamp?;
                        final canClaim = lastClaimed == null ||
                            lastClaimed.toDate().day != DateTime.now().day ||
                            lastClaimed.toDate().month !=
                                DateTime.now().month ||
                            lastClaimed.toDate().year != DateTime.now().year;

                        return Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: Colors.cyan.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.card_giftcard,
                                      color: Colors.cyan, size: 30),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('مكافأة يومية',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold)),
                                      Text('1 جوهرة 💎 + 2 عملات 🪙',
                                          style: const TextStyle(
                                              color: Colors.white38,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            if (canClaim)
                              ElevatedButton(
                                onPressed: () => _claimLoginReward(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                                child: const Text('استلام المكافأة',
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold)),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.green),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: Colors.green),
                                    SizedBox(width: 10),
                                    Text('تم استلام المكافأة اليوم',
                                        style: TextStyle(color: Colors.green)),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Activity Rewards
              AppTheme.glassContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('مكافآت النشاط',
                        style: TextStyle(
                            color: Colors.amber,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    StreamBuilder<DocumentSnapshot>(
                      stream: _db
                          .collection('family_daily_rewards')
                          .doc('${widget.familyId}_activity')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.amber));
                        }

                        final data =
                            snapshot.data!.data() as Map<String, dynamic>?;
                        final lastClaimed = data?['lastClaimed'] as Timestamp?;
                        final activityMinutes = data?['activityMinutes'] ?? 0;
                        final canClaim = activityMinutes >= 30 &&
                            (lastClaimed == null ||
                                lastClaimed.toDate().day !=
                                    DateTime.now().day ||
                                lastClaimed.toDate().month !=
                                    DateTime.now().month ||
                                lastClaimed.toDate().year !=
                                    DateTime.now().year);

                        return Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.local_activity,
                                      color: Colors.orange, size: 30),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('مكافأة النشاط (30 دقيقة)',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold)),
                                      Text('2 عملات 🪙 + 1 جوهرة 💎',
                                          style: const TextStyle(
                                              color: Colors.white38,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),

                            // Progress Bar
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('التقدم: $activityMinutes/30 دقيقة',
                                        style: const TextStyle(
                                            color: Colors.white38,
                                            fontSize: 12)),
                                    Text(
                                        '${((activityMinutes / 30) * 100).toInt()}%',
                                        style: const TextStyle(
                                            color: Colors.amber, fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value:
                                        (activityMinutes / 30).clamp(0.0, 1.0),
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.1),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            Colors.amber),
                                    minHeight: 10,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),

                            if (canClaim)
                              ElevatedButton(
                                onPressed: () =>
                                    _claimActivityReward(activityMinutes),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber,
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                                child: const Text('استلام المكافأة',
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold)),
                              )
                            else if (activityMinutes < 30)
                              Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.hourglass_empty,
                                        color: Colors.white38),
                                    SizedBox(width: 10),
                                    Text('اكمل 30 دقيقة من النشاط',
                                        style:
                                            TextStyle(color: Colors.white38)),
                                  ],
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.green),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: Colors.green),
                                    SizedBox(width: 10),
                                    Text('تم استلام المكافأة اليوم',
                                        style: TextStyle(color: Colors.green)),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Rewards History
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _db
                      .collection('family_daily_rewards')
                      .where('familyId', isEqualTo: widget.familyId)
                      .orderBy('lastClaimed', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                          child:
                              CircularProgressIndicator(color: Colors.amber));
                    }

                    final rewards = snapshot.data!.docs;

                    if (rewards.isEmpty) {
                      return const Center(
                        child: Text('لا توجد مكافآت تم استلامها',
                            style: TextStyle(color: Colors.white38)),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: rewards.length,
                      itemBuilder: (context, index) {
                        final reward = FamilyDailyRewardModel.fromFirestore(
                            rewards[index]);
                        return _buildRewardCard(reward);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _claimLoginReward() async {
    try {
      await _familyService.claimDailyLoginReward(widget.familyId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم استلام المكافأة! 🎉 (1 جوهرة + 2 عملات)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    }
  }

  Future<void> _claimActivityReward(int activityMinutes) async {
    try {
      await _familyService.claimActivityReward(
          widget.familyId, activityMinutes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم استلام المكافأة! 🎉 (2 عملات + 1 جوهرة)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    }
  }

  Widget _buildRewardCard(FamilyDailyRewardModel reward) {
    return AppTheme.glassContainer(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: reward.isLoginReward
                  ? Colors.cyan.withValues(alpha: 0.2)
                  : Colors.orange.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              reward.isLoginReward ? Icons.card_giftcard : Icons.local_activity,
              color: reward.isLoginReward ? Colors.cyan : Colors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.isLoginReward
                      ? 'مكافأة تسجيل الدخول'
                      : 'مكافأة النشاط',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                if (reward.claimedAt != null)
                  Text(
                    'تم الاستلام: ${_formatDate(reward.claimedAt!)}',
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
