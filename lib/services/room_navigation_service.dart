import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/voice_room_page.dart';
import 'firestore_service.dart';

class RoomNavigationService {
  static Future<void> joinRoom(
      BuildContext context, Map<String, dynamic> room) async {
    // التحقق مما إذا كانت البيانات كاملة، وإلا نقوم بجلبها
    if (room['ownerId'] == null || room['ownerId'].toString().isEmpty) {
      final String? rid = room['id'] ?? room['roomId'];
      if (rid != null) {
        final doc =
            await FirebaseFirestore.instance.collection('rooms').doc(rid).get();
        if (doc.exists) {
          room = {...doc.data()!, 'id': doc.id};
        }
      }
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final String roomId = (room['id'] ?? room['roomId'] ?? '').toString();
    final String roomName = room['name'] ?? room['roomName'] ?? 'غرفة صوتية';
    final String? roomImage = room['roomImage'] ?? room['image'];
    final String ownerId = room['ownerId'] ?? '';
    final String? password = room['password']?.toString();
    final int membershipFee = room['membershipFee'] ?? 0;

    if (roomId.isNotEmpty) {
      await FirestoreService().trackRoomVisit(userId: user.uid, roomId: roomId);
    }

    if (!context.mounted) return;

    // 1. صاحب الغرفة يدخل مباشرة
    if (user.uid == ownerId) {
      _navigateToRoom(context, roomId, roomName, roomImage, ownerId);
      return;
    }

    // 2. التحقق من صلاحيات VIP لتجاوز الأقفال (باقة رويال دور)
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final userData = userDoc.data() ?? {};
    if (userData['canBypassLocks'] == true) {
      _navigateToRoom(context, roomId, roomName, roomImage, ownerId);
      return;
    }

    // 3. المشرفون يدخلون مباشرة
    final List moderators = room['moderators'] ?? [];
    if (moderators.contains(user.uid)) {
      _navigateToRoom(context, roomId, roomName, roomImage, ownerId);
      return;
    }

    // 4. التحقق من العضوية ورسوم الدخول
    final memberDoc = await FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .collection('members')
        .doc(user.uid)
        .get();

    if (!memberDoc.exists && membershipFee > 0) {
      final bool? paid = await _showMembershipFeeDialog(
          context, roomId, roomName, membershipFee, userData, ownerId);
      if (paid != true) return;
    }

    // 5. إذا كانت الغرفة مقفلة بكلمة مرور
    if (password != null && password.isNotEmpty) {
      _showPasswordDialog(
          context, roomId, roomName, roomImage, ownerId, password);
    } else {
      _navigateToRoom(context, roomId, roomName, roomImage, ownerId);
    }
  }

  static Future<bool?> _showMembershipFeeDialog(
      BuildContext context,
      String roomId,
      String roomName,
      int fee,
      Map<String, dynamic> userData,
      String ownerId) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('رسوم العضوية 💎',
            style: TextStyle(color: Colors.white, fontSize: 18)),
        content: Text(
            'تتطلب هذه الغرفة رسوم عضوية قدرها $fee جوهرة للانضمام.\nرصيدك الحالي: ${userData['gems'] ?? 0}',
            style: const TextStyle(color: Colors.white70, fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:
                  const Text('إلغاء', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
            onPressed: () async {
              final int currentGems = (userData['gems'] ?? 0).toInt();
              if (currentGems < fee) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('رصيد الجواهر غير كافٍ ❌'),
                    backgroundColor: Colors.redAccent));
                return;
              }

              try {
                final user = FirebaseAuth.instance.currentUser!;
                // خصم الجواهر وإضافة العضوية
                await FirebaseFirestore.instance.runTransaction((tx) async {
                  tx.update(
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid),
                      {'gems': FieldValue.increment(-fee)});

                  // إضافة الجواهر لمالك الغرفة (بعد خصم عمولة بسيطة مثلاً أو كاملة)
                  tx.update(
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(ownerId),
                      {'gems': FieldValue.increment(fee)});

                  tx.set(
                      FirebaseFirestore.instance
                          .collection('rooms')
                          .doc(roomId)
                          .collection('members')
                          .doc(user.uid),
                      {
                        'joinedAt': FieldValue.serverTimestamp(),
                        'role': 'member'
                      });
                });
                if (context.mounted) Navigator.pop(context, true);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('فشل في إتمام العملية ❌')));
                  Navigator.pop(context, false);
                }
              }
            },
            child: const Text('دفع ودخول', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  static void _navigateToRoom(BuildContext context, String roomId,
      String roomName, String? roomImage, String ownerId) {
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VoiceRoomPage(
          roomId: roomId,
          roomName: roomName,
          roomImage: roomImage,
          ownerId: ownerId,
        ),
      ),
    );
  }

  static void _showPasswordDialog(
      BuildContext context,
      String roomId,
      String roomName,
      String? roomImage,
      String ownerId,
      String correctPassword) {
    if (!context.mounted) return;
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock, color: Colors.amber),
            SizedBox(width: 10),
            Text('الغرفة مقفلة',
                style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'هذه الغرفة محمية بكلمة مرور، يرجى إدخال الكود للمتابعة.',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              obscureText: true,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, letterSpacing: 4),
              decoration: InputDecoration(
                hintText: 'كلمة المرور',
                hintStyle:
                    const TextStyle(color: Colors.white24, letterSpacing: 0),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('إلغاء', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber, foregroundColor: Colors.black),
            onPressed: () {
              if (controller.text.trim() == correctPassword) {
                Navigator.pop(context);
                _navigateToRoom(context, roomId, roomName, roomImage, ownerId);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('كلمة المرور غير صحيحة ❌'),
                    backgroundColor: Colors.redAccent));
              }
            },
            child: const Text('دخول'),
          ),
        ],
      ),
    );
  }
}
