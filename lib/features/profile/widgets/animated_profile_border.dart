import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedProfileBorder extends StatefulWidget {
  final Widget child;
  final double size;
  final bool isVip;
  const AnimatedProfileBorder({
    super.key,
    required this.child,
    this.size = 88,
    this.isVip = false,
  });

  @override
  State<AnimatedProfileBorder> createState() => _AnimatedProfileBorderState();
}

class _AnimatedProfileBorderState extends State<AnimatedProfileBorder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _ProfileBorderPainter(
              _controller.value,
              isVip: widget.isVip,
            ),
            child: Center(child: widget.child),
          );
        },
      ),
    );
  }
}

class _ProfileBorderPainter extends CustomPainter {
  final double progress;
  final bool isVip;
  _ProfileBorderPainter(this.progress, {this.isVip = false});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = SweepGradient(
      startAngle: 0.0,
      endAngle: math.pi * 2,
      colors: isVip
          ? [
              Colors.amber,
              Colors.purple,
              Colors.amber,
              Colors.purple,
              Colors.amber,
            ]
          : [Colors.blue, Colors.cyan, Colors.blue, Colors.cyan, Colors.blue],
      stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      transform: GradientRotation(progress * math.pi * 2),
    );
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(size.center(Offset.zero), size.width / 2 - 4, paint);
  }

  @override
  bool shouldRepaint(covariant _ProfileBorderPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isVip != isVip;
}
