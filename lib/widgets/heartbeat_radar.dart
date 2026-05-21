import 'package:flutter/material.dart';
import 'dart:math' as math;

class HeartbeatRadar extends StatefulWidget {
  final double scale;
  final Color color;
  const HeartbeatRadar({super.key, this.scale = 1.0, this.color = const Color(0xFFFFD700)});

  @override
  State<HeartbeatRadar> createState() => _HeartbeatRadarState();
}

class _HeartbeatRadarState extends State<HeartbeatRadar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(200 * widget.scale, 200 * widget.scale),
          painter: RadarPainter(_controller.value, widget.color),
        );
      },
    );
  }
}

class RadarPainter extends CustomPainter {
  final double animationValue;
  final Color color;
  RadarPainter(this.animationValue, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw background circles
    for (int i = 1; i <= 4; i++) {
      paint.color = color.withValues(alpha: 0.1 * i);
      canvas.drawCircle(center, maxRadius * (i / 4), paint);
    }

    // Draw scanning line
    final Shader scanShader = SweepGradient(
      center: Alignment.center,
      startAngle: 0,
      endAngle: math.pi * 2,
      colors: [
        color.withValues(alpha: 0.0),
        color.withValues(alpha: 0.5),
      ],
      stops: const [0.8, 1.0],
      transform: GradientRotation(animationValue * math.pi * 2),
    ).createShader(Rect.fromCircle(center: center, radius: maxRadius));

    canvas.drawCircle(center, maxRadius, Paint()..shader = scanShader);

    // Draw central heartbeat pulse
    final pulseValue = (math.sin(animationValue * math.pi * 4) + 1) / 2;
    final pulsePaint = Paint()
      ..color =
          color.withValues(alpha: 0.3 * (1 - pulseValue))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, maxRadius * 0.2 * pulseValue, pulsePaint);

    // Crosshair
    final crossPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..strokeWidth = 0.5;
    canvas.drawLine(Offset(0, size.height / 2),
        Offset(size.width, size.height / 2), crossPaint);
    canvas.drawLine(Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height), crossPaint);
  }

  @override
  bool shouldRepaint(RadarPainter oldDelegate) => true;
}
