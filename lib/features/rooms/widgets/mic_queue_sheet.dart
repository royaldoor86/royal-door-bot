import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MicQueueSheet extends StatelessWidget {
  final String roomId;
  final bool hasPower;
  final Function(String userId, String name, String photoUrl) onApprove;

  const MicQueueSheet({
    super.key,
    required this.roomId,
    required this.hasPower,
    required this.onApprove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F1B25),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 15),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          const Text('قائمة انتظار المايك 🎤',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rooms')
                  .doc(roomId)
                  .collection('mic_requests')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final requests = snapshot.data!.docs;
                if (requests.isEmpty) {
                  return const Center(
                    child: Text('لا توجد طلبات حالياً',
                        style: TextStyle(color: Colors.white38)),
                  );
                }

                return ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final data = requests[index].data() as Map<String, dynamic>;
                    final userId = data['userId'];
                    final name = data['name'] ?? 'مستخدم ملكي';
                    final photoUrl = data['photoUrl'] ?? '';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: photoUrl.isNotEmpty
                            ? CachedNetworkImageProvider(photoUrl)
                            : null,
                        child: photoUrl.isEmpty ? const Icon(Icons.person) : null,
                      ),
                      title: Text(name, style: const TextStyle(color: Colors.white)),
                      subtitle: const Text('طلب الصعود للمايك',
                          style: TextStyle(color: Colors.white38, fontSize: 12)),
                      trailing: hasPower
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.check_circle,
                                      color: Colors.green),
                                  onPressed: () => onApprove(userId, name, photoUrl),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.cancel, color: Colors.red),
                                  onPressed: () => _rejectRequest(userId),
                                ),
                              ],
                            )
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _rejectRequest(String userId) {
    FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .collection('mic_requests')
        .doc(userId)
        .delete();
  }
}
