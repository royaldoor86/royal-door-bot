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
    return SafeArea(
      child: Container(
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
            _penaltyOption(context, "خصم 100 كوينز ⭐", 100, "coins"),
            _penaltyOption(context, "خصم 500 كوينز ⭐", 500, "coins"),
            _penaltyOption(context, "خصم 100 جوهرة 💎", 10, "gems"),
          ],
        ),
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
              // Get room data to find owner
              final roomRef = FirebaseFirestore.instance.collection('rooms').doc(roomId);
              final roomSnap = await transaction.get(roomRef);
              if (!roomSnap.exists) return;
              
              final roomData = roomSnap.data() as Map<String, dynamic>;
              final roomOwnerId = roomData['ownerId'] as String?;
              
              // Apply penalty
              final userRef =
                  FirebaseFirestore.instance.collection('users').doc(userId);
              
              // تحديد الحقول الصحيحة للخصم
              Map<String, dynamic> updates = {};
              if (field == 'coins') {
                // خصم من الكوينز
                updates['coins'] = FieldValue.increment(-amount);
                updates['rewardStars'] = FieldValue.increment(-amount);
              } else if (field == 'gems') {
                // خصم من الجواهر
                updates['gems'] = FieldValue.increment(-amount);
                updates['rewardGems'] = FieldValue.increment(-amount);
              }
              
              transaction.update(userRef, updates);

              // Add deducted amount to room owner's wallet
              if (roomOwnerId != null && roomOwnerId.isNotEmpty) {
                final ownerRef = FirebaseFirestore.instance.collection('users').doc(roomOwnerId);
                Map<String, dynamic> ownerUpdates = {};
                if (field == 'coins') {
                  // إضافة للكوينز
                  ownerUpdates['coins'] = FieldValue.increment(amount);
                  ownerUpdates['rewardStars'] = FieldValue.increment(amount);
                } else if (field == 'gems') {
                  // إضافة للجواهر
                  ownerUpdates['gems'] = FieldValue.increment(amount);
                  ownerUpdates['rewardGems'] = FieldValue.increment(amount);
                }
                transaction.update(ownerRef, ownerUpdates);
              }

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
                'roomOwnerId': roomOwnerId,
                'transferredToOwner': roomOwnerId != null,
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
