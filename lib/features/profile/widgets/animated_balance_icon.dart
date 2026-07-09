import 'package:flutter/material.dart';

class AnimatedBalanceIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final double size;
  const AnimatedBalanceIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 28,
  });

  @override
  State<AnimatedBalanceIcon> createState() => _AnimatedBalanceIconState();
}

class _AnimatedBalanceIconState extends State<AnimatedBalanceIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _rotation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _rotation = Tween<double>(
      begin: -0.07,
      end: 0.07,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
      builder: (context, child) => Transform.rotate(
        angle: _rotation.value,
        child: Transform.scale(
          scale: _scale.value,
          child: Icon(
            widget.icon,
            color: widget.color,
            size: widget.size,
            shadows: [
              Shadow(
                color: widget.color.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
