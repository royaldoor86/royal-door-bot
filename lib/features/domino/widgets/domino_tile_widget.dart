import 'package:flutter/material.dart';
import '../models/domino_models.dart';

class RoyalDominoTile extends StatelessWidget {
  final DominoTile tile;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool isSmall;

  const RoyalDominoTile({
    super.key,
    required this.tile,
    this.onTap,
    this.isSelected = false,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    double width = isSmall ? 40 : 60;
    double height = isSmall ? 80 : 120;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1A1A), Color(0xFF333333)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.amber : const Color(0xFFD4AF37),
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected ? Colors.amber.withOpacity(0.5) : Colors.black.withOpacity(0.3),
              blurRadius: isSelected ? 15 : 5,
              spreadRadius: isSelected ? 2 : 1,
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Container(
                width: width * 0.8,
                height: 2,
                color: const Color(0xFFD4AF37).withOpacity(0.3),
              ),
            ),
            Column(
              children: [
                Expanded(child: _buildDots(tile.left, isSmall)),
                Expanded(child: _buildDots(tile.right, isSmall)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDots(int count, bool small) {
    return Center(
      child: CustomPaint(
        size: Size(small ? 25 : 40, small ? 25 : 40),
        painter: DominoDotsPainter(count: count, isSmall: small),
      ),
    );
  }
}

class DominoDotsPainter extends CustomPainter {
  final int count;
  final bool isSmall;
  DominoDotsPainter({required this.count, this.isSmall = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    double radius = isSmall ? 2.5 : 4.0;
    _drawDots(canvas, size, paint, radius);
  }

  void _drawDots(Canvas canvas, Size size, Paint paint, double radius) {
    double w = size.width;
    double h = size.height;

    if (count == 1) canvas.drawCircle(Offset(w / 2, h / 2), radius, paint);
    if (count == 2) {
      canvas.drawCircle(Offset(w * 0.25, h * 0.25), radius, paint);
      canvas.drawCircle(Offset(w * 0.75, h * 0.75), radius, paint);
    }
    if (count == 3) {
      canvas.drawCircle(Offset(w * 0.25, h * 0.25), radius, paint);
      canvas.drawCircle(Offset(w / 2, h / 2), radius, paint);
      canvas.drawCircle(Offset(w * 0.75, h * 0.75), radius, paint);
    }
    if (count == 4 || count == 5 || count == 6) {
      canvas.drawCircle(Offset(w * 0.25, h * 0.25), radius, paint);
      canvas.drawCircle(Offset(w * 0.75, h * 0.25), radius, paint);
      canvas.drawCircle(Offset(w * 0.25, h * 0.75), radius, paint);
      canvas.drawCircle(Offset(w * 0.75, h * 0.75), radius, paint);
    }
    if (count == 5) canvas.drawCircle(Offset(w / 2, h / 2), radius, paint);
    if (count == 6) {
      canvas.drawCircle(Offset(w * 0.25, h / 2), radius, paint);
      canvas.drawCircle(Offset(w * 0.75, h / 2), radius, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
