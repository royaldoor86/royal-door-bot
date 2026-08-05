import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import 'dart:ui';
import '../../../../theme/design_tokens.dart';

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

    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1B5E20).withValues(alpha: 0.8),
                const Color(0xFF0D3310).withValues(alpha: 0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3), width: 1.5),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 15)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sentiment_very_satisfied_rounded, color: Colors.greenAccent, size: 20),
                  SizedBox(width: 8),
                  Text("طبيب أسنان التمساح الملكي 🐊",
                      style: TextStyle(
                        color: Colors.white, 
                        fontSize: 15, 
                        fontWeight: FontWeight.bold,
                        fontFamily: DesignTokens.primaryFont,
                      )),
                ],
              ),
              const SizedBox(height: 20),
              _buildTeethGrid(status, pickedTeeth, loserId),
              if (status == 'bitten') ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text("عض التمساح ${loserName ?? '...'}! 😵",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white, 
                              fontWeight: FontWeight.bold, 
                              fontSize: 13,
                              fontFamily: DesignTokens.primaryFont,
                            )),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 20),
                const Text("اختر سنّاً واحذر من العضة! 🦷", 
                  style: TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic)),
              ],
              const SizedBox(height: 20),
              _buildFooter(status),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeethGrid(String status, List<dynamic> picked, String? loserId) {
    return SizedBox(
      width: 250,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.0,
        ),
        itemCount: 10,
        itemBuilder: (context, index) {
          bool isPicked = picked.contains(index);
          bool isLoserTooth = status == 'bitten' && index == widget.gameData['soreTooth'];

          return GestureDetector(
            onTap: (status == 'playing' && !isPicked) ? () => _pickTooth(index) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: isLoserTooth 
                    ? Colors.redAccent 
                    : (isPicked ? Colors.black38 : Colors.white),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isLoserTooth ? Colors.white : (isPicked ? Colors.white10 : Colors.greenAccent.withValues(alpha: 0.2)),
                  width: isLoserTooth ? 2.0 : 1.0,
                ),
                boxShadow: isLoserTooth ? [
                  BoxShadow(color: Colors.redAccent.withValues(alpha: 0.5), blurRadius: 10)
                ] : null,
              ),
              child: isLoserTooth
                  ? const Icon(Icons.close_rounded, color: Colors.white, size: 24)
                  : (isPicked ? null : Center(child: Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))))),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFooter(String status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (status == 'bitten' && widget.hasPower)
          ElevatedButton.icon(
            onPressed: _resetGame,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text("جولة جديدة", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
        const SizedBox(width: 12),
        TextButton(
          onPressed: _closeGame,
          child: const Text("إغلاق اللعبة", 
            style: TextStyle(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  void _pickTooth(int index) async {
    HapticFeedback.selectionClick();
    final soreTooth = widget.gameData['soreTooth'] as int;
    final docRef = FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);

    if (index == soreTooth) {
      HapticFeedback.vibrate();
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

