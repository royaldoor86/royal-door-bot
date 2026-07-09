import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Enhanced animations for Domino game
class EnhancedDominoAnimations {
  // Tile placement animation with bounce and shine
  static Widget placementAnimation(Widget child) {
    return child
        .animate()
        .scale(
          begin: const Offset(0.3, 0.3),
          end: const Offset(1.0, 1.0),
          duration: 400.ms,
          curve: Curves.elasticOut,
        )
        .fade(begin: 0, end: 1, duration: 400.ms)
        .shimmer(
          duration: 600.ms,
          color: Colors.white.withValues(alpha: 0.3),
        );
  }

  // Score pop-up animation
  static Widget scorePopupAnimation(String text, {Color color = Colors.amber}) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: color,
        shadows: [
          Shadow(
            offset: const Offset(2, 2),
            blurRadius: 4,
            color: Colors.black.withValues(alpha: 0.5),
          ),
        ],
      ),
    )
        .animate()
        .scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1.2, 1.2),
          duration: 300.ms,
          curve: Curves.elasticOut,
        )
        .then()
        .fadeOut(duration: 500.ms, delay: 800.ms)
        .slideY(
          begin: 0,
          end: -3,
          duration: 1300.ms,
          curve: Curves.easeOut,
        );
  }

  // Card flip animation
  static Widget flipAnimation(
    Widget child, {
    bool isFlipped = false,
  }) {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateY(isFlipped ? 3.14159 : 0),
      child: child,
    );
  }

  // Pulse effect for current player indicator
  static Widget pulseAnimation(Widget child) {
    return child
        .animate(onPlay: (controller) => controller.repeat())
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.15, 1.15),
          duration: 800.ms,
          curve: Curves.easeInOut,
        )
        .then()
        .scale(
          begin: const Offset(1.15, 1.15),
          end: const Offset(1.0, 1.0),
          duration: 800.ms,
          curve: Curves.easeInOut,
        );
  }

  // Confetti/celebration animation for winning
  static Widget celebrationAnimation(Widget child) {
    return child
        .animate()
        .scale(
          begin: const Offset(0, 0),
          end: const Offset(1, 1),
          duration: 600.ms,
          curve: Curves.elasticOut,
        )
        .rotate(
          begin: -0.3,
          end: 0,
          duration: 600.ms,
          curve: Curves.elasticOut,
        )
        .shimmer(
          duration: 1.2.seconds,
          color: Colors.amber,
        );
  }

  // Slide-in animation for UI elements
  static Widget slideInAnimation(Widget child, {bool fromTop = true}) {
    return child
        .animate()
        .slideY(
          begin: fromTop ? -1 : 1,
          end: 0,
          duration: 500.ms,
          curve: Curves.easeOutCubic,
        )
        .fade(begin: 0, end: 1, duration: 500.ms);
  }

  // Shake animation for invalid move
  static Widget shakeAnimation(Widget child) {
    return child.animate().shake(
          hz: 8,
          offset: const Offset(10, 0),
          duration: 400.ms,
          curve: Curves.easeInOut,
        );
  }
}

/// Particle effect widget for tile placement
class TilePlacementParticles extends StatefulWidget {
  final Offset position;
  final Duration duration;

  const TilePlacementParticles({
    super.key,
    required this.position,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<TilePlacementParticles> createState() => _TilePlacementParticlesState();
}

class _TilePlacementParticlesState extends State<TilePlacementParticles>
    with TickerProviderStateMixin {
  late List<AnimationController> controllers;

  @override
  void initState() {
    super.initState();
    controllers = List.generate(
      8,
      (index) => AnimationController(
        duration: widget.duration,
        vsync: this,
      ),
    );
    for (var controller in controllers) {
      controller.forward();
    }
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(
        8,
        (index) {
          final angle = (index * 45) * 3.14159 / 180;
          const distance = 80.0;
          final endX = widget.position.dx + distance * math.cos(angle);
          final endY = widget.position.dy + distance * math.sin(angle);

          return AnimatedBuilder(
            animation: controllers[index],
            builder: (context, child) {
              final value = controllers[index].value;
              return Positioned(
                left: widget.position.dx +
                    (endX - widget.position.dx) * value -
                    8,
                top: widget.position.dy +
                    (endY - widget.position.dy) * value -
                    8,
                child: Opacity(
                  opacity: 1 - value,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.amber.withValues(alpha: 0.8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withValues(alpha: 0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Math helper
class Math {
  static double cos(double radians) => math.cos(radians);
  static double sin(double radians) => math.sin(radians);
}
