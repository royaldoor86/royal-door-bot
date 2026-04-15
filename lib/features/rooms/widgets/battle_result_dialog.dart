import 'package:flutter/material.dart';

class BattleResultDialog extends StatefulWidget {
  final int redPoints;
  final int bluePoints;
  const BattleResultDialog({super.key, required this.redPoints, required this.bluePoints});

  @override
  State<BattleResultDialog> createState() => _BattleResultDialogState();
}

class _BattleResultDialogState extends State<BattleResultDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _rotateAnimation = Tween<double>(begin: 0.0, end: 2 * 3.14159).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOutBack));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isRedWinner = widget.redPoints > widget.bluePoints;
    bool isDraw = widget.redPoints == widget.bluePoints;
    Color winnerColor = isDraw ? Colors.amber : (isRedWinner ? Colors.red : Colors.blue);
    String winnerText = isDraw ? "تعادل!" : (isRedWinner ? "الفريق الأحمر فاز!" : "الفريق الأزرق فاز!");

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // الخلفية المتوهجة
            Container(
              width: 280,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F26),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: winnerColor.withOpacity(0.5), width: 2),
                boxShadow: [
                  BoxShadow(color: winnerColor.withOpacity(0.3), blurRadius: 20, spreadRadius: 5),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 50),
                  Text(
                    winnerText,
                    style: TextStyle(color: winnerColor, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildScoreItem("الأزرق", widget.bluePoints, Colors.blue),
                      const Text("VS", style: TextStyle(color: Colors.white24, fontWeight: FontWeight.bold)),
                      _buildScoreItem("الأحمر", widget.redPoints, Colors.red),
                    ],
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: winnerColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                    ),
                    child: const Text("استمرار", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            // التاج أو الكأس المتحرك
            Positioned(
              top: -60,
              child: RotationTransition(
                turns: _controller.drive(CurveTween(curve: Curves.elasticOut)),
                child: Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: winnerColor,
                    boxShadow: [BoxShadow(color: winnerColor.withOpacity(0.5), blurRadius: 15)],
                  ),
                  child: Icon(
                    isDraw ? Icons.star : Icons.emoji_events,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreItem(String team, int points, Color color) {
    return Column(
      children: [
        Text(team, style: TextStyle(color: color, fontSize: 14)),
        const SizedBox(height: 5),
        Text("$points", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
