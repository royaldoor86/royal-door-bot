import 'package:flutter/material.dart';

class AnimatedCounter extends StatefulWidget {
  final int value;
  final TextStyle? style;
  final Duration duration;
  const AnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;
  int _oldValue = 0;

  @override
  void initState() {
    super.initState();
    _oldValue = widget.value;
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = IntTween(
      begin: _oldValue,
      end: widget.value,
    ).animate(_controller);
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _oldValue = oldWidget.value;
      _animation = IntTween(
        begin: _oldValue,
        end: widget.value,
      ).animate(_controller);
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) =>
          Text(_animation.value.toString(), style: widget.style),
    );
  }
}
