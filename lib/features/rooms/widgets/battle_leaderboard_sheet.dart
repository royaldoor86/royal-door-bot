import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BattleLeaderboardSheet extends StatefulWidget {
  const BattleLeaderboardSheet({super.key});

  @override
  State<BattleLeaderboardSheet> createState() => _BattleLeaderboardSheetState();
}

class _BattleLeaderboardSheetState extends State<BattleLeaderboardSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F1B25),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 45,
            height: 5,
            decoration: BoxDecoration(
                color: Colors.white12, borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(height: 20),
          const Text(
            'تصنيف المعارك الملكية ⚔️',
            style: TextStyle(
                color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('battle_history')
                  .orderBy('timestamp', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final battles = snapshot.data!.docs;
                if (battles.isEmpty) {
                  return const Center(
                    child: Text(
                      'لا توجد معارك مسجلة بعد',
                      style: TextStyle(color: Colors.white38),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: battles.length,
                  itemBuilder: (context, index) {
                    final battle = battles[index].data() as Map<String, dynamic>;
                    final redPoints = battle['redPoints'] ?? 0;
                    final bluePoints = battle['bluePoints'] ?? 0;
                    final winnerTeam = battle['winnerTeam'] ?? '';
                    final mode = battle['mode'] ?? 'team';
                    final roomName = battle['roomName'] ?? 'غرفة';
                    final timestamp = battle['timestamp'] as Timestamp?;
                    final date = timestamp?.toDate() ?? DateTime.now();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      color: Colors.white.withValues(alpha: 0.05),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  roomName,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  _formatDate(date),
                                  style: const TextStyle(
                                      color: Colors.white38, fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'أحمر: $redPoints',
                                        style: const TextStyle(
                                            color: Colors.red, fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'أزرق: $bluePoints',
                                        style: const TextStyle(
                                            color: Colors.blue, fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: winnerTeam == 'red'
                                        ? Colors.red.withValues(alpha: 0.3)
                                        : Colors.blue.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.emoji_events,
                                        color: winnerTeam == 'red'
                                            ? Colors.red
                                            : Colors.blue,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        winnerTeam == 'red' ? 'الأحمر' : 'الأزرق',
                                        style: TextStyle(
                                            color: winnerTeam == 'red'
                                                ? Colors.red
                                                : Colors.blue,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Text(
                              mode == 'team' ? 'معركة فريق' : 'تحدي فردي',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'اليوم';
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} أيام';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
