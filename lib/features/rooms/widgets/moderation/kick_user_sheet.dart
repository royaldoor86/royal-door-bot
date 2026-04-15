import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class KickUserSheet extends StatelessWidget {
  final String roomId;
  final String userId;
  final String userName;

  const KickUserSheet({super.key, required this.roomId, required this.userId, required this.userName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Color(0xFF1A242F), borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text("طرد $userName من الغرفة", style: const TextStyle(color: Colors.orangeAccent, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('rooms').doc(roomId).collection('online_users').doc(userId).delete();
              Navigator.pop(context);
            },
            child: const Text("تأكيد الطرد", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء", style: TextStyle(color: Colors.white54))),
        ],
      ),
    );
  }
}
