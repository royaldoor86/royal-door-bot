import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' as intl;
import '../../../app_theme.dart';

class RoomGiftLogSheet extends StatefulWidget {
  final String roomId;
  const RoomGiftLogSheet({super.key, required this.roomId});

  @override
  State<RoomGiftLogSheet> createState() => _RoomGiftLogSheetState();
}

class _RoomGiftLogSheetState extends State<RoomGiftLogSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF0F1B25),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 45,
            height: 5,
            decoration: BoxDecoration(
                color: Colors.white12, borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(height: 20),
          const Text('سجل هدايا الغرفة 🎁',
              style: TextStyle(
                  color: AppTheme.royalGold,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('sent_gifts')
                  .where('roomId', isEqualTo: widget.roomId)
                  .orderBy('sentAt', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final logs = snapshot.data!.docs;
                if (logs.isEmpty) {
                  return const Center(
                    child: Text('لا توجد هدايا مسجلة لهذه الغرفة بعد 🕊️',
                        style: TextStyle(color: Colors.white38)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final data = logs[index].data() as Map<String, dynamic>;
                    final sender = data['senderName'] ?? 'مستخدم';
                    final receiver = data['receiverName'] ?? 'الجميع';
                    final giftName = data['giftName'] ?? 'هدية';
                    final count = data['count'] ?? 1;
                    final price = data['totalCost'] ?? 0;
                    final ts = data['sentAt'] as Timestamp?;
                    final timeStr = ts != null ? intl.DateFormat('HH:mm').format(ts.toDate()) : '--:--';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.black26,
                              shape: BoxShape.circle
                            ),
                            child: const Icon(Icons.card_giftcard, color: Colors.amber, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                RichText(text: TextSpan(children: [
                                  TextSpan(text: sender, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
                                  const TextSpan(text: ' أهدى ', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                  TextSpan(text: receiver, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 13)),
                                ])),
                                const SizedBox(height: 4),
                                Text('$giftName x$count ($price 💎)', 
                                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
                              ],
                            ),
                          ),
                          Text(timeStr, style: const TextStyle(color: Colors.white24, fontSize: 10)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
