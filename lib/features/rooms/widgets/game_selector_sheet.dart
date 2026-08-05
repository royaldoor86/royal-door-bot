import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class GameSelectorSheet extends StatelessWidget {
  final String roomId;
  final bool hasPower;

  const GameSelectorSheet({
    super.key,
    required this.roomId,
    required this.hasPower,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
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
          const Text('مركز الألعاب الملكي 🎮',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.all(20),
              crossAxisCount: 3,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              children: [
                _buildGameItem(context, 'حرب الفواكه', Icons.apple, Colors.red, 'fruit_war'),
                _buildGameItem(context, 'تيك تاك تو', Icons.grid_3x3, Colors.blue, 'tic_tac_toe'),
                _buildGameItem(context, 'صندوق الحظ', Icons.card_giftcard, Colors.orange, 'lucky_draw'),
                _buildGameItem(context, 'التصويت', Icons.how_to_vote, Colors.purple, 'voting'),
                _buildGameItem(context, 'القنبلة', Icons.error_outline, Colors.yellow, 'bomb'),
                _buildGameItem(context, 'التمساح', Icons.pets, Colors.green, 'crocodile'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameItem(BuildContext context, String label, IconData icon, Color color, String gameId) {
    return GestureDetector(
      onTap: () => _startGame(context, gameId, label),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.2),
                  color.withValues(alpha: 0.05),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.1),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  void _startGame(BuildContext context, String gameId, String label) async {
    if (!hasPower) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('عذراً، تشغيل الألعاب مخصص للمشرفين فقط 👑')));
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      Map<String, dynamic> gameData = {
        'id': gameId,
        'name': label,
        'startTime': FieldValue.serverTimestamp(),
        'status': 'starting',
      };

      if (gameId == 'tic_tac_toe') {
        gameData['playerX'] = user?.uid;
        gameData['playerO'] = null;
        gameData['turn'] = user?.uid;
        gameData['status'] = 'waiting';
        gameData['board'] = List.filled(9, null);
      } else if (gameId == 'fruit_war') {
        gameData['status'] = 'betting';
        gameData['selections'] = {};
        gameData['winnerId'] = null;
      } else if (gameId == 'voting') {
        gameData['status'] = 'setup';
        gameData['question'] = '';
        gameData['options'] = [];
        gameData['votes'] = {};
      } else if (gameId == 'lucky_draw') {
        gameData['status'] = 'ongoing';
        gameData['participants'] = [];
        gameData['duration'] = 60; // 60 seconds
      } else if (gameId == 'bomb') {
        gameData['status'] = 'playing';
        gameData['startTime'] = FieldValue.serverTimestamp();
        gameData['duration'] = 15 + Random().nextInt(15); // Random explosion time
        gameData['currentHolderId'] = user?.uid;
        gameData['currentHolderName'] = 'المالك';
      } else if (gameId == 'crocodile') {
        gameData['status'] = 'playing';
        gameData['pickedTeeth'] = [];
        gameData['soreTooth'] = Random().nextInt(10);
      }

      await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
        'activeGame': gameData
      });
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('فشل تشغيل اللعبة: $e')));
      }
    }
  }
}
