import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ويدجت لعرض تحديات النمو النشطة في الألعاب
class GrowthChallengeWidget extends StatefulWidget {
  const GrowthChallengeWidget({super.key});

  @override
  State<GrowthChallengeWidget> createState() => _GrowthChallengeWidgetState();
}

class _GrowthChallengeWidgetState extends State<GrowthChallengeWidget> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('guild_challenges')
          .where('status', isEqualTo: 'active')
          .where('endTime', isGreaterThan: Timestamp.now())
          .orderBy('endTime', descending: false)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final challenge =
            snapshot.data!.docs.first.data() as Map<String, dynamic>;
        final currentUser = FirebaseAuth.instance.currentUser;
        final String? uid = currentUser?.uid;
        return _buildChallengeCard(challenge, uid);
      },
    );
  }

  Widget _buildChallengeCard(Map<String, dynamic> challenge, String? uid) {
    final String title = challenge['title'] ?? 'تحدي النمو';
    final int prize = challenge['prize'] ?? 0;
    final String currency = challenge['currency'] ?? 'gems';
    final String guildName = challenge['guildName'] ?? 'بيت الدعم';
    final Timestamp endTime = challenge['endTime'] as Timestamp;
    final DateTime endDateTime = endTime.toDate();
    final Duration remaining = endDateTime.difference(DateTime.now());

    final String prizeText =
        currency == 'gems' ? '$prize جوهرة 💎' : '$prize كوينز 🪙';
    final String timeText = remaining.inHours > 0
        ? '${remaining.inHours} ساعة'
        : '${remaining.inMinutes} دقيقة';

    final int userProgress = uid != null
        ? ((challenge['participantProgress'] ?? {})[uid] ?? 0).toInt()
        : 0;
    final int goal =
        (challenge['targetValue'] ?? challenge['goal'] ?? 100).toInt();
    final double userFraction =
        goal > 0 ? (userProgress / goal).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.amber.withValues(alpha: 0.3),
            Colors.orange.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // صورة التحدي
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.asset(
              'assets/images/challenge_banner.png',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: Colors.amber,
                    size: 40,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'من قبل: $guildName',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildPrizeItem(
                        'الجائزة', prizeText, Icons.workspace_premium),
                    _buildPrizeItem('المتبقي', timeText, Icons.timer),
                  ],
                ),
                const SizedBox(height: 8),
                // شريط زمن التحدي
                LinearProgressIndicator(
                  value: remaining.inHours > 0
                      ? (remaining.inHours / 24.0).clamp(0.0, 1.0)
                      : (remaining.inMinutes / 60.0).clamp(0.0, 1.0),
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Colors.orange),
                  minHeight: 4,
                ),
                const SizedBox(height: 8),
                // شريط تقدم المستخدم
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('تقدمك',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12)),
                        Text('$userProgress / $goal',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: userFraction,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.green),
                      minHeight: 8,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrizeItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.amber, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}
