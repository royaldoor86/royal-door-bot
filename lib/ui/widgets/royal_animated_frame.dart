import 'package:flutter/material.dart';
import 'dart:math' as math;

class RoyalAnimatedFrame extends StatefulWidget {
  final Widget child; // الصورة الشخصية
  final String frameUrl;
  final double size;

  const RoyalAnimatedFrame({
    super.key,
    required this.child,
    required this.frameUrl,
    this.size = 100,
  });

  @override
  State<RoyalAnimatedFrame> createState() => _RoyalAnimatedFrameState();
}

class _RoyalAnimatedFrameState extends State<RoyalAnimatedFrame>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _shouldAnimate = false;

  @override
  void initState() {
    super.initState();
    _shouldAnimate = widget.frameUrl.toLowerCase().endsWith('.gif');
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    if (_shouldAnimate) {
      _controller.repeat();
    }
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
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. الصورة الشخصية في المنتصف (يجب أن تظل قابلة للنقر)
          SizedBox(
            width: widget.size * 0.75,
            height: widget.size * 0.75,
            child: widget.child,
          ),

          // 2. طبقة التوهج الملكي (نستخدم IgnorePointer لكي لا تمنع النقر)
          if (_shouldAnimate)
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Container(
                    width: widget.size * 0.9,
                    height: widget.size * 0.9,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.2 +
                              (0.1 *
                                  math.sin(_controller.value * 2 * math.pi))),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          // 3. الإطار (نستخدم IgnorePointer لكي "تخترق" النقرة الإطار وتصل للصورة)
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                double scale = 1.0;
                if (_shouldAnimate) {
                  scale =
                      1.0 + (0.03 * math.sin(_controller.value * 2 * math.pi));
                }

                return Transform.scale(
                  scale: scale,
                  child: Image.network(
                    widget.frameUrl,
                    width: widget.size,
                    height: widget.size,
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => const SizedBox(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
