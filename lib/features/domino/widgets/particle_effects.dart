import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Advanced particle effects system for Domino game
class ParticleEffectsSystem {
  static const int particleCount = 20;

  /// Win/celebration particles
  static Widget celebrationParticles({
    required Offset centerPosition,
    required Duration duration,
    Color color = Colors.amber,
  }) {
    return _ParticleEmitter(
      position: centerPosition,
      duration: duration,
      particleCount: particleCount,
      particleBuilder: (context, value, angle, distance) {
        final progress = value;
        final x = centerPosition.dx + math.cos(angle) * distance * progress;
        final y = centerPosition.dy + math.sin(angle) * distance * progress;

        return Positioned(
          left: x - 8,
          top: y - 8,
          child: Opacity(
            opacity: (1 - progress).clamp(0, 1).toDouble(),
            child: Transform.rotate(
              angle: progress * 6.28,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      color.withValues(alpha: 0.8),
                      color.withValues(alpha: 0.3),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Score gain particles (ascending numbers)
  static Widget scoreGainParticles({
    required Offset position,
    required int score,
    required Duration duration,
  }) {
    return _ParticleEmitter(
      position: position,
      duration: duration,
      particleCount: 5,
      particleBuilder: (context, value, angle, distance) {
        final y = position.dy - (distance * value);
        return Positioned(
          left: position.dx - 25,
          top: y,
          child: Opacity(
            opacity: 1 - value,
            child: Text(
              '+$score',
              style: TextStyle(
                fontSize: 24 - (value * 10),
                fontWeight: FontWeight.bold,
                color: Colors.green[300],
                shadows: [
                  Shadow(
                    offset: const Offset(1, 1),
                    blurRadius: 4,
                    color: Colors.black.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Combo multiplier particles
  static Widget comboParticles({
    required Offset position,
    required int combo,
    required Duration duration,
  }) {
    return _ParticleEmitter(
      position: position,
      duration: duration,
      particleCount: 8,
      particleBuilder: (context, value, angle, distance) {
        final x = position.dx + math.cos(angle) * distance * value;
        final y = position.dy + math.sin(angle) * distance * value;
        final size = 8 + (value * 4);

        return Positioned(
          left: x - size / 2,
          top: y - size / 2,
          child: Opacity(
            opacity: 1 - value,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.orange,
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.8),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Tile placement pulse/wave
  static Widget tilePlacementWave({
    required Offset position,
    required Duration duration,
  }) {
    return _ParticleEmitter(
      position: position,
      duration: duration,
      particleCount: 3,
      particleBuilder: (context, value, angle, distance) {
        final waveRadius = value * 100;
        return Positioned(
          left: position.dx - waveRadius,
          top: position.dy - waveRadius,
          child: Container(
            width: waveRadius * 2,
            height: waveRadius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: (1 - value) * 0.4),
                width: 3,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Error/shake particles
  static Widget errorParticles({
    required Offset position,
    required Duration duration,
  }) {
    return _ParticleEmitter(
      position: position,
      duration: duration,
      particleCount: 12,
      particleBuilder: (context, value, angle, distance) {
        final x = position.dx + math.cos(angle) * distance * value * 0.3;
        final y = position.dy + math.sin(angle) * distance * value * 0.3;

        return Positioned(
          left: x - 6,
          top: y - 6,
          child: Opacity(
            opacity: (1 - value) * 0.6,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.7),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Internal particle emitter widget
class _ParticleEmitter extends StatefulWidget {
  final Offset position;
  final Duration duration;
  final int particleCount;
  final Widget Function(
    BuildContext,
    double, // progress value (0-1)
    double, // angle
    double, // distance
  ) particleBuilder;

  const _ParticleEmitter({
    required this.position,
    required this.duration,
    required this.particleCount,
    required this.particleBuilder,
  });

  @override
  State<_ParticleEmitter> createState() => _ParticleEmitterState();
}

class _ParticleEmitterState extends State<_ParticleEmitter>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late List<double> _angles;
  late List<double> _distances;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    final random = math.Random();
    _angles = List.generate(
      widget.particleCount,
      (_) => random.nextDouble() * math.pi * 2,
    );
    _distances = List.generate(
      widget.particleCount,
      (_) => 40 + random.nextDouble() * 80,
    );

    _animations = List.generate(
      widget.particleCount,
      (_) => Tween<double>(begin: 0, end: 1).animate(_controller),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(
        widget.particleCount,
        (index) => AnimatedBuilder(
          animation: _animations[index],
          builder: (context, _) {
            return widget.particleBuilder(
              context,
              _animations[index].value,
              _angles[index],
              _distances[index],
            );
          },
        ),
      ),
    );
  }
}

/// Floating text effect widget
class FloatingTextEffect extends StatefulWidget {
  final String text;
  final Offset startPosition;
  final Duration duration;
  final TextStyle style;
  final Color shadowColor;

  const FloatingTextEffect({
    super.key,
    required this.text,
    required this.startPosition,
    this.duration = const Duration(seconds: 2),
    required this.style,
    this.shadowColor = Colors.black,
  });

  @override
  State<FloatingTextEffect> createState() => _FloatingTextEffectState();
}

class _FloatingTextEffectState extends State<FloatingTextEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.startPosition.dx,
      top: widget.startPosition.dy,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final value = _controller.value;
          return Transform.translate(
            offset: Offset(0, -50 * value),
            child: Opacity(
              opacity: 1 - value,
              child: child,
            ),
          );
        },
        child: Text(
          widget.text,
          style: widget.style.copyWith(
            shadows: [
              Shadow(
                offset: const Offset(2, 2),
                blurRadius: 4,
                color: widget.shadowColor.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pulsing glow effect
class PulsingGlow extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final Duration duration;

  const PulsingGlow({
    super.key,
    required this.child,
    required this.glowColor,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<PulsingGlow> createState() => _PulsingGlowState();
}

class _PulsingGlowState extends State<PulsingGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);
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
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color:
                    widget.glowColor.withValues(alpha: 0.3 * _controller.value),
                blurRadius: 20 * _controller.value,
                spreadRadius: 5 * _controller.value,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
