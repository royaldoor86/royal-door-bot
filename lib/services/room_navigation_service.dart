import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/voice_room_page.dart';

class RoomNavigationService {
  static Future<void> joinRoom(BuildContext context, Map<String, dynamic> room) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final String roomId = room['id'] ?? room['roomId'];
    final String roomName = room['name'] ?? room['roomName'] ?? 'غرفة صوتية';
    final String? roomImage = room['roomImage'] ?? room['image'];
    final String ownerId = room['ownerId'] ?? '';
    final String? password = room['password'];

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
    final userData = userDoc.data();
    if (userData?['canBypassLocks'] == true) {
      _navigateToRoom(context, roomId, roomName, roomImage, ownerId);
      return;
    }

    // 3. المشرفون يدخلون مباشرة
    final List moderators = room['moderators'] ?? [];
    if (moderators.contains(user.uid)) {
      _navigateToRoom(context, roomId, roomName, roomImage, ownerId);
      return;
    }

    // 4. إذا كانت الغرفة مقفلة بكلمة مرور
    if (password != null && password.isNotEmpty) {
      _showPasswordDialog(context, roomId, roomName, roomImage, ownerId, password);
    } else {
      _navigateToRoom(context, roomId, roomName, roomImage, ownerId);
    }
  }

  static void _navigateToRoom(BuildContext context, String roomId, String roomName, String? roomImage, String ownerId) {
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

  static void _showPasswordDialog(BuildContext context, String roomId, String roomName, String? roomImage, String ownerId, String correctPassword) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.lock, color: Colors.amber),
            const SizedBox(width: 10),
            const Text('الغرفة مقفلة',
                style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('هذه الغرفة محمية بكلمة مرور، يرجى إدخال الكود للمتابعة.',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              obscureText: true,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, letterSpacing: 4),
              decoration: InputDecoration(
                hintText: 'كلمة المرور',
                hintStyle: const TextStyle(color: Colors.white24, letterSpacing: 0),
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
