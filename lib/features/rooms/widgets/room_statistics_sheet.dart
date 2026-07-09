import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoomStatisticsSheet extends StatefulWidget {
  final String roomId;
  const RoomStatisticsSheet({super.key, required this.roomId});

  @override
  State<RoomStatisticsSheet> createState() => _RoomStatisticsSheetState();
}

class _RoomStatisticsSheetState extends State<RoomStatisticsSheet> {
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
            'إحصائيات الغرفة 📊',
            style: TextStyle(
                color: Colors.purple, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rooms')
                  .doc(widget.roomId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final roomData = snapshot.data!.data() as Map<String, dynamic>?;
                if (roomData == null) {
                  return const Center(
                    child: Text(
                      'لا توجد بيانات',
                      style: TextStyle(color: Colors.white38),
                    ),
                  );
                }
                
                final totalVisitors = roomData['totalVisitors'] ?? 0;
                final totalGifts = roomData['totalGifts'] ?? 0;
                final totalBattles = roomData['totalBattles'] ?? 0;
                final exp = roomData['exp'] ?? roomData['points'] ?? 0;
                final level = roomData['level'] ?? 1;
                
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _statCard(Icons.people, 'إجمالي الزوار', totalVisitors.toString(), Colors.blue),
                    _statCard(Icons.card_giftcard, 'إجمالي الهدايا', totalGifts.toString(), Colors.amber),
                    _statCard(Icons.flash_on, 'إجمالي المعارك', totalBattles.toString(), Colors.red),
                    _statCard(Icons.star, 'الخبرة', exp.toString(), Colors.green),
                    _statCard(Icons.military_tech, 'المستوى', level.toString(), Colors.purple),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _statCard(IconData icon, String title, String value, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    value,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
