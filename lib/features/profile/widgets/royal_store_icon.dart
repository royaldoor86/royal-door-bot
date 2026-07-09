import 'package:flutter/material.dart';

class RoyalStoreIcon extends StatefulWidget {
  const RoyalStoreIcon({super.key, this.size = 28});
  final double size;

  @override
  State<RoyalStoreIcon> createState() => _RoyalStoreIconState();
}

class _RoyalStoreIconState extends State<RoyalStoreIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotation;
  late Animation<Color?> _color;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _rotation = Tween<double>(
      begin: -0.1,
      end: 0.1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _color = ColorTween(
      begin: Colors.pinkAccent,
      end: Colors.purpleAccent,
    ).animate(_controller);
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
        return Transform.rotate(
          angle: _rotation.value,
          child: Icon(
            Icons.shopping_bag_rounded,
            color: _color.value,
            size: widget.size,
            shadows: [
              Shadow(
                color: Colors.pinkAccent.withValues(alpha: 0.5),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
              Shadow(
                color: Colors.purpleAccent.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
        );
      },
    );
  }
}
