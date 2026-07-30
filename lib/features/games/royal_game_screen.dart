import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_embed_unity/flutter_embed_unity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoyalGameScreen extends StatefulWidget {
  const RoyalGameScreen({super.key});

  @override
  State<RoyalGameScreen> createState() => _RoyalGameScreenState();
}

class _RoyalGameScreenState extends State<RoyalGameScreen> {
  static const MethodChannel _unityChannel = MethodChannel('com.royaldoor.unity');
  bool _isUnityLoaded = false;

  @override
  void initState() {
    super.initState();
    _syncBalanceWithUnity();
  }

  Future<void> _syncBalanceWithUnity() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final int gems = (userDoc.data()?['gems'] ?? 0).toInt();

    try {
      await _unityChannel.invokeMethod('setGemsBalance', {
        'balance': gems,
        'target': 'GameManager',
      });
    } catch (e) {
      debugPrint("Error syncing balance with Unity: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          EmbedUnity(
            onMessageFromUnity: (String message) {
              debugPrint("Message from Unity: $message");
              if (message == "RequestBalance") {
                _syncBalanceWithUnity();
              }
            },
          ),
          Positioned(
            top: 40,
            right: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black45,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          if (!_isUnityLoaded)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFFFFD700)),
                  SizedBox(height: 20),
                  Text(
                    'جاري تحميل اللعبة الملكية...',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
