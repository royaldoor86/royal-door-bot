import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class CrocodileGame extends StatefulWidget {
  final String roomId;
  final Map<String, dynamic> gameData;
  final bool hasPower;

  const CrocodileGame({
    super.key,
    required this.roomId,
    required this.gameData,
    required this.hasPower,
  });

  @override
  State<CrocodileGame> createState() => _CrocodileGameState();
}

class _CrocodileGameState extends State<CrocodileGame> {
  final String _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    String status = widget.gameData['status'] ?? 'playing';
    List<dynamic> pickedTeeth = widget.gameData['pickedTeeth'] ?? [];
    String? loserId = widget.gameData['loserId'];
    String? loserName = widget.gameData['loserName'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1B5E20).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("طبيب أسنان التمساح 🐊🦷",
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("احذر من السن المصاب!", style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 20),
          _buildTeethGrid(status, pickedTeeth, loserId),
          if (status == 'bitten') ...[
            const SizedBox(height: 20),
            Text("آخ! عض التمساح ${loserName ?? 'أحدهم'}! 😵",
                style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          ],
          const SizedBox(height: 20),
          _buildFooter(status),
        ],
      ),
    );
  }

  Widget _buildTeethGrid(String status, List<dynamic> picked, String? loserId) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: 10,
      itemBuilder: (context, index) {
        bool isPicked = picked.contains(index);
        bool isLoserTooth = status == 'bitten' && index == widget.gameData['soreTooth'];

        return GestureDetector(
          onTap: (status == 'playing' && !isPicked) ? () => _pickTooth(index) : null,
          child: Container(
            decoration: BoxDecoration(
              color: isLoserTooth ? Colors.red : (isPicked ? Colors.black26 : Colors.white),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black12),
            ),
            child: isLoserTooth
                ? const Icon(Icons.close, color: Colors.white)
                : (isPicked ? null : Container(margin: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)))),
          ),
        );
      },
    );
  }

  Widget _buildFooter(String status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (status == 'bitten' && widget.hasPower)
          ElevatedButton(
            onPressed: _resetGame,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text("محاولة جديدة", style: TextStyle(color: Colors.black)),
          ),
        const SizedBox(width: 10),
        TextButton(
          onPressed: _closeGame,
          child: const Text("إغلاق", style: TextStyle(color: Colors.white54)),
        ),
      ],
    );
  }

  void _pickTooth(int index) async {
    final soreTooth = widget.gameData['soreTooth'] as int;
    final docRef = FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);

    if (index == soreTooth) {
      // Bitten!
      final userSnap = await FirebaseFirestore.instance.collection('users').doc(_myUid).get();
      final name = userSnap.data()?['name'] ?? 'مستخدم';
      
      await docRef.update({
        'activeGame.status': 'bitten',
        'activeGame.loserId': _myUid,
        'activeGame.loserName': name,
        'activeGame.pickedTeeth': FieldValue.arrayUnion([index]),
      });
    } else {
      await docRef.update({
        'activeGame.pickedTeeth': FieldValue.arrayUnion([index]),
      });
    }
  }

  void _resetGame() async {
    await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
      'activeGame.status': 'playing',
      'activeGame.pickedTeeth': [],
      'activeGame.loserId': null,
      'activeGame.loserName': null,
      'activeGame.soreTooth': Random().nextInt(10),
    });
  }

  void _closeGame() async {
    await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
      'activeGame': FieldValue.delete(),
    });
  }
}
