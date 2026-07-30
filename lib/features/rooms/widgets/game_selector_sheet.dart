import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 11)),
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
      await FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
        'activeGame': {
          'id': gameId,
          'name': label,
          'startTime': FieldValue.serverTimestamp(),
          'status': 'starting',
        }
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
