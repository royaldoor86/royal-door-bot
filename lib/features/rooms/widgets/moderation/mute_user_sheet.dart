import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MuteUserSheet extends StatelessWidget {
  final String roomId;
  final String userId;
  final String userName;

  const MuteUserSheet({super.key, required this.roomId, required this.userId, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1A242F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text("كتم صوت $userName", style: const TextStyle(color: Colors.blueAccent, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("سيتم كتم ميكروفون المستخدم إدارياً", style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            onPressed: () async {
              // البحث عن المستخدم في المقاعد وكتمه
              final seatsSnap = await FirebaseFirestore.instance.collection('rooms').doc(roomId).collection('mic_seats').where('userId', isEqualTo: userId).get();
              for (var doc in seatsSnap.docs) {
                await doc.reference.update({'isMuted': true});
              }
              Navigator.pop(context);
            },
            child: const Text("تأكيد الكتم", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء", style: TextStyle(color: Colors.white54))),
        ],
      ),
    );
  }
}
