import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PenaltyUserSheet extends StatelessWidget {
  final String roomId;
  final String userId;
  final String userName;

  const PenaltyUserSheet(
      {super.key,
      required this.roomId,
      required this.userId,
      required this.userName});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding + 20),
      decoration: const BoxDecoration(
          color: Color(0xFF1A242F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text("تطبيق عقوبة على $userName",
              style: const TextStyle(
                  color: Colors.purpleAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _penaltyOption(context, "خصم 100 نجمة ⭐", 100, "coins"),
          _penaltyOption(context, "خصم 500 نجمة ⭐", 500, "coins"),
          _penaltyOption(context, "خصم 100 ألماس 💎", 10, "gems"),
        ],
      ),
    );
  }

  Widget _penaltyOption(
      BuildContext context, String title, int amount, String field) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        leading: const Icon(Icons.money_off, color: Colors.redAccent),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        onTap: () async {
          final currentUser = FirebaseAuth.instance.currentUser;
          if (currentUser == null) return;

          try {
            await FirebaseFirestore.instance
                .runTransaction((transaction) async {
              // Apply penalty
              final userRef =
                  FirebaseFirestore.instance.collection('users').doc(userId);
              
              // تحديد الحقول الصحيحة للخصم
              Map<String, dynamic> updates = {};
              if (field == 'coins') {
                // خصم من النجوم
                updates['rewardStars'] = FieldValue.increment(-amount);
                updates['harvest_stars_wallet'] = FieldValue.increment(-amount);
                updates['starsHarvestWallet'] = FieldValue.increment(-amount);
              } else if (field == 'gems') {
                // خصم من الجواهر
                updates['rewardGems'] = FieldValue.increment(-amount);
                updates['harvest_wallet'] = FieldValue.increment(-amount);
                updates['harvestWallet'] = FieldValue.increment(-amount);
              }
              
              transaction.update(userRef, updates);

              // Log the penalty
              final logRef = FirebaseFirestore.instance
                  .collection('rooms')
                  .doc(roomId)
                  .collection('penalty_logs')
                  .doc();
              transaction.set(logRef, {
                'userId': userId,
                'userName': userName,
                'moderatorId': currentUser.uid,
                'moderatorName': currentUser.displayName ?? 'مستخدم',
                'penaltyType': field == 'coins' ? 'stars' : 'gems',
                'amount': amount,
                'reason': 'عقوبة من المشرف',
                'timestamp': FieldValue.serverTimestamp(),
              });
            });

            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم تطبيق العقوبة بنجاح ✅')),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('فشل في تطبيق العقوبة: $e')),
              );
            }
          }
        },
      ),
    );
  }
}
