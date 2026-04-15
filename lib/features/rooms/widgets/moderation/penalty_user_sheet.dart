import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PenaltyUserSheet extends StatelessWidget {
  final String roomId;
  final String userId;
  final String userName;

  const PenaltyUserSheet({super.key, required this.roomId, required this.userId, required this.userName});

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
          Text("تطبيق عقوبة على $userName", style: const TextStyle(color: Colors.purpleAccent, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _penaltyOption(context, "خصم 100 كوينز 🪙", 100, "coins"),
          _penaltyOption(context, "خصم 500 كوينز 🪙", 500, "coins"),
          _penaltyOption(context, "خصم 10 ألماس 💎", 10, "gems"),
        ],
      ),
    );
  }

  Widget _penaltyOption(BuildContext context, String title, int amount, String field) {
    return ListTile(
      leading: Icon(Icons.money_off, color: Colors.redAccent),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () async {
        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          field: FieldValue.increment(-amount),
        });
        Navigator.pop(context);
      },
    );
  }
}
