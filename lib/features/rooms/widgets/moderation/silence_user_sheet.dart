import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SilenceUserSheet extends StatelessWidget {
  final String roomId;
  final String userId;
  final String userName;

  const SilenceUserSheet({super.key, required this.roomId, required this.userId, required this.userName});

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
          Text("إصمات $userName", style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _option(context, "10 دقائق", 10),
          _option(context, "ساعة واحدة", 60),
          _option(context, "يوم كامل", 1440),
          _option(context, "إلغاء الإصمات", 0, isRemove: true),
        ],
      ),
    );
  }

  Widget _option(BuildContext context, String title, int minutes, {bool isRemove = false}) {
    return ListTile(
      leading: Icon(isRemove ? Icons.chat : Icons.timer, color: isRemove ? Colors.green : Colors.orange),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () async {
        if (isRemove) {
          await FirebaseFirestore.instance.collection('rooms').doc(roomId).collection('silenced').doc(userId).delete();
        } else {
          await FirebaseFirestore.instance.collection('rooms').doc(roomId).collection('silenced').doc(userId).set({
            'until': DateTime.now().add(Duration(minutes: minutes)),
            'at': FieldValue.serverTimestamp(),
          });
        }
        Navigator.pop(context);
      },
    );
  }
}
