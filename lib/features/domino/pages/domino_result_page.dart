import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/domino_controller.dart';

class DominoResultPage extends StatelessWidget {
  const DominoResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.read<DominoController>();
    final isWinner = game.winner?.id == (game.players.isNotEmpty ? game.players[0].id : '');
    final rewards = game.getCalculatedRewards();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isWinner 
              ? [const Color(0xFFD4AF37).withOpacity(0.3), Colors.black]
              : [Colors.red.withOpacity(0.2), Colors.black],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(isWinner ? '🎉' : '😔', style: const TextStyle(fontSize: 100)),
            const SizedBox(height: 10),
            Text(
              isWinner ? "مبروك أيها الملك!" : "انتهت اللعبة",
              style: TextStyle(
                color: isWinner ? const Color(0xFFD4AF37) : Colors.white70,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontFamily: 'Serif',
              ),
            ),
            const SizedBox(height: 30),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(color: (isWinner ? Colors.amber : Colors.red).withOpacity(0.1), blurRadius: 20),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _rewardItem('💎', rewards['gems']!, 'جواهر'),
                  _rewardItem('🪙', rewards['coins']!, 'كوينز'),
                  _rewardItem('⭐', rewards['points']!, 'نقاط'),
                ],
              ),
            ),
            const SizedBox(height: 50),
            _buildButton(
              context,
              label: "العب مرة أخرى",
              isPrimary: true,
              onPressed: () {
                game.initGame(2, mode: game.gameMode, type: game.playType);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 15),
            _buildButton(
              context,
              label: "العودة للقائمة",
              isPrimary: false,
              onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rewardItem(String icon, int value, String label) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 35)),
        const SizedBox(height: 8),
        Text("$value", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
      ],
    );
  }

  Widget _buildButton(BuildContext context, {required String label, required bool isPrimary, required VoidCallback onPressed}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 50),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? const Color(0xFFD4AF37) : Colors.transparent,
          foregroundColor: isPrimary ? Colors.black : Colors.white,
          minimumSize: const Size(double.infinity, 55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: isPrimary ? BorderSide.none : const BorderSide(color: Colors.white24),
          ),
          elevation: isPrimary ? 5 : 0,
        ),
        child: Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
