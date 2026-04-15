import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_theme.dart';

class IncomingCallOverlay extends StatelessWidget {
  final Map<String, dynamic> callData;
  final String callId;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const IncomingCallOverlay({
    super.key,
    required this.callData,
    required this.callId,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final String callerId = callData['callerId'] ?? '';
    final bool isVideo = callData['type'] == 'video';

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black.withValues(alpha: 0.8),
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(callerId).snapshots(),
          builder: (context, snapshot) {
            String callerName = "مكالمة ملكية";
            String? callerPic;

            if (snapshot.hasData && snapshot.data!.exists) {
              final data = snapshot.data!.data() as Map<String, dynamic>;
              callerName = data['name'] ?? callerName;
              callerPic = data['profilePic'];
            }

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.royalGold, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: (callerPic != null && callerPic.isNotEmpty)
                        ? CachedNetworkImageProvider(callerPic)
                        : null,
                    child: (callerPic == null || callerPic.isEmpty)
                        ? const Icon(Icons.person, size: 60, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  callerName,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  isVideo ? "مكالمة فيديو واردة..." : "مكالمة صوتية واردة...",
                  style: const TextStyle(color: AppTheme.royalGold, fontSize: 16),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 100),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _callActionBtn(
                        icon: Icons.close,
                        color: Colors.redAccent,
                        label: "رفض",
                        onTap: onDecline,
                      ),
                      _callActionBtn(
                        icon: isVideo ? Icons.videocam : Icons.call,
                        color: Colors.greenAccent,
                        label: "قبول",
                        onTap: onAccept,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _callActionBtn({required IconData icon, required Color color, required String label, required VoidCallback onTap}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 2),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      ],
    );
  }
}
