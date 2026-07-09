import 'package:flutter/material.dart';
import '../models/domino_models.dart';

class RoyalDominoTile extends StatefulWidget {
  final DominoTile tile;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool isSmall;
  final double? rotation;

  const RoyalDominoTile({
    super.key,
    required this.tile,
    this.onTap,
    this.isSelected = false,
    this.isSmall = false,
    this.rotation,
  });

  @override
  State<RoyalDominoTile> createState() => _RoyalDominoTileState();
}

class _RoyalDominoTileState extends State<RoyalDominoTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  late Animation<double> _hoverAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _hoverAnimation = Tween<double>(begin: 0, end: 1).animate(_hoverController);
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovering) {
    if (isHovering) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = widget.isSmall ? 40 : 65;
    double height = widget.isSmall ? 80 : 130;

    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => _onHover(true),
        onExit: (_) => _onHover(false),
        child: Transform.rotate(
          angle: widget.rotation ?? 0,
          child: ScaleTransition(
            scale:
                Tween<double>(begin: 1.0, end: 1.05).animate(_hoverAnimation),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(widget.isSmall ? 6 : 10),
                border: Border.all(
                  color: widget.isSelected
                      ? Colors.amber[600]!
                      : const Color(0xFFD0D0D0),
                  width: widget.isSelected ? 2.5 : 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.isSelected
                        ? Colors.amber[400]!.withValues(alpha: 0.6)
                        : Colors.black.withValues(alpha: 0.2),
                    blurRadius: widget.isSelected ? 15 : 6,
                    spreadRadius: widget.isSelected ? 2 : 1,
                    offset: const Offset(2, 3),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Center divider
                  Center(
                    child: Container(
                      width: width * 0.9,
                      height: 1.0,
                      color: Colors.black.withValues(alpha: 0.15),
                    ),
                  ),
                  // Dots grid
                  Column(
                    children: [
                      Expanded(
                          child: _buildDots(widget.tile.left, widget.isSmall)),
                      Expanded(
                          child: _buildDots(widget.tile.right, widget.isSmall)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDots(int count, bool small) {
    return Center(
      child: CustomPaint(
        size: Size(small ? 16 : 28, small ? 16 : 28),
        painter: ProfessionalDominoDotsPainter(count: count, isSmall: small),
      ),
    );
  }
}

class ProfessionalDominoDotsPainter extends CustomPainter {
  final int count;
  final bool isSmall;

  ProfessionalDominoDotsPainter({required this.count, this.isSmall = false});

  Color _getDotColor(int n) {
    // Use standard black dots for better visibility
    return Colors.black87;
  }

  @override
  void paint(Canvas canvas, Size size) {
    double w = size.width;
    double h = size.height;
    double radius =
        isSmall ? 9.0 : 14.0; // Very large dots for maximum visibility

    final Color dotColor = _getDotColor(count);

    final Paint dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    // Strong shadow for dots
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    void drawDot(double x, double y) {
      canvas.drawCircle(Offset(x, y + 2), radius, shadowPaint);
      canvas.drawCircle(Offset(x, y), radius, dotPaint);
    }

    // Standard domino dot patterns
    if (count == 1) {
      drawDot(w / 2, h / 2);
    } else if (count == 2) {
      drawDot(w * 0.3, h * 0.3);
      drawDot(w * 0.7, h * 0.7);
    } else if (count == 3) {
      drawDot(w * 0.3, h * 0.3);
      drawDot(w / 2, h / 2);
      drawDot(w * 0.7, h * 0.7);
    } else if (count == 4) {
      drawDot(w * 0.3, h * 0.3);
      drawDot(w * 0.7, h * 0.3);
      drawDot(w * 0.3, h * 0.7);
      drawDot(w * 0.7, h * 0.7);
    } else if (count == 5) {
      drawDot(w * 0.3, h * 0.3);
      drawDot(w * 0.7, h * 0.3);
      drawDot(w * 0.3, h * 0.7);
      drawDot(w * 0.7, h * 0.7);
      drawDot(w / 2, h / 2);
    } else if (count == 6) {
      drawDot(w * 0.3, h * 0.25);
      drawDot(w * 0.7, h * 0.25);
      drawDot(w * 0.3, h * 0.5);
      drawDot(w * 0.7, h * 0.5);
      drawDot(w * 0.3, h * 0.75);
      drawDot(w * 0.7, h * 0.75);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
