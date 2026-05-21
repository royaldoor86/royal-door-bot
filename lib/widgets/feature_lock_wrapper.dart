import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeatureLockWrapper extends StatelessWidget {
  final String lockField;
  final Widget child;
  final String? customMessage;

  const FeatureLockWrapper({
    super.key,
    required this.lockField,
    required this.child,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return child;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('system_settings')
          .doc('global')
          .snapshots(),
      builder: (context, systemSnap) {
        if (!systemSnap.hasData || !systemSnap.data!.exists) return child;

        final systemData = systemSnap.data!.data() as Map<String, dynamic>;
        final bool isLocked = systemData[lockField] ?? false;

        if (!isLocked) return child;

        // التحقق مما إذا كان المستخدم مديراً لتجاوز القفل
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, userSnap) {
            if (userSnap.hasData && userSnap.data!.exists) {
              final userData = userSnap.data!.data() as Map<String, dynamic>;
              final String role = userData['role'] ?? 'user';
              final bool isAdmin = userData['isAdmin'] ?? false;
              final bool isOwner = userData['isOwner'] ?? false;

              if (isAdmin || isOwner || ['admin', 'owner', 'developer', 'staff'].contains(role)) {
                return child;
              }
            }

            return _buildLockedScreen(context);
          },
        );
      },
    );
  }

  Widget _buildLockedScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1F1C),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  size: 100, color: Color(0xFFD4AF37)),
              const SizedBox(height: 30),
              const Text(
                'قريباً ستكتمل تطويرها 👑',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Text(
                customMessage ?? "نحن نعمل حالياً على تحسين هذه الميزة لتليق بمستوى رويال دور. ترقبوها قريباً ✨",
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 50),
              const CircularProgressIndicator(color: Color(0xFFD4AF37)),
            ],
          ),
        ),
      ),
    );
  }
}
