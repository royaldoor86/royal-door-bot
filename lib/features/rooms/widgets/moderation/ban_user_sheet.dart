import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BanUserSheet extends StatelessWidget {
  final String roomId;
  final String userId;
  final String userName;

  const BanUserSheet({super.key, required this.roomId, required this.userId, required this.userName});

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
          Text("حظر $userName نهائياً", style: const TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("سيتم طرد المستخدم ومنعه من دخول الغرفة مجدداً", style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  onPressed: () async {
                    await FirebaseFirestore.instance.collection('rooms').doc(roomId).collection('bans').doc(userId).set({
                      'bannedAt': FieldValue.serverTimestamp(),
                    });
                    // طرد من الغرفة فوراً
                    await FirebaseFirestore.instance.collection('rooms').doc(roomId).collection('online_users').doc(userId).delete();
                    Navigator.pop(context);
                  },
                  child: const Text("تأكيد الحظر", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("إلغاء", style: TextStyle(color: Colors.white54)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
