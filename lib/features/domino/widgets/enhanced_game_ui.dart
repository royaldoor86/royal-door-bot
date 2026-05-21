import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Professional gaming table background with premium effects
class EnhancedGameTableBackground extends StatelessWidget {
  final Widget child;
  final double opacity;

  const EnhancedGameTableBackground({
    super.key,
    required this.child,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1B5E20).withValues(alpha: opacity),
            const Color(0xFF0D3311).withValues(alpha: opacity),
            const Color(0xFF051a0f).withValues(alpha: opacity),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Radial gradient overlay for depth
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  const Color(0xFF2E7D32).withValues(alpha: 0.1),
                  const Color(0xFF1B5E20).withValues(alpha: 0.3),
                  const Color(0xFF0D3311).withValues(alpha: 0.5),
                ],
              ),
            ),
          ),
          // Subtle felt texture pattern
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: _buildFeltPattern(),
                repeat: ImageRepeat.repeat,
                opacity: 0.08,
              ),
            ),
          ),
          // Noise/grain texture for premium feel
          Opacity(
            opacity: 0.03,
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: List.generate(
                    8,
                    (i) => Colors.white.withValues(alpha: (i % 2) * 0.3),
                  ),
                ),
              ),
            ),
          ),
          // Main content
          child,
        ],
      ),
    );
  }

  // Generate a simple canvas-based felt pattern
  static ImageProvider _buildFeltPattern() {
    return MemoryImage(
      _generatePatternImageBytes(),
    );
  }

  static Uint8List _generatePatternImageBytes() {
    // Return a 2x2 pixel pattern (can be expanded)
    // Green to darker green gradient
    return Uint8List.fromList([
      46, 125, 50, 255, // Green
      13, 71, 17, 255, // Dark green
      13, 71, 17, 255,
      46, 125, 50, 255,
    ]);
  }
}

/// Enhanced game info card with glassmorphism effect
class EnhancedGameInfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color primaryColor;
  final bool isReverse;
  final VoidCallback? onTap;

  const EnhancedGameInfoCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.primaryColor,
    this.isReverse = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          // Glassmorphism effect
          gradient: LinearGradient(
            colors: [
              Colors.black.withValues(alpha: 0.15),
              Colors.white.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.3),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withValues(alpha: 0.2),
              blurRadius: 12,
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: isReverse
              ? [
                  Text(
                    value,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: const Offset(1, 1),
                          blurRadius: 3,
                          color: Colors.black.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          primaryColor,
                          primaryColor.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ]
              : [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          primaryColor,
                          primaryColor.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    value,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          offset: const Offset(1, 1),
                          blurRadius: 3,
                          color: Colors.black.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
                ],
        ),
      ),
    );
  }
}

/// Enhanced rounded button with premium styling
class EnhancedRoundButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isActive;

  const EnhancedRoundButton({
    super.key,
    required this.icon,
    required this.color,
    required this.onTap,
    this.isActive = true,
  });

  @override
  State<EnhancedRoundButton> createState() => _EnhancedRoundButtonState();
}

class _EnhancedRoundButtonState extends State<EnhancedRoundButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.isActive ? widget.onTap : null,
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 0.9).animate(_controller),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                widget.color,
                widget.color.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.5),
                blurRadius: 12,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            widget.icon,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}

/// Premium timer ring with gradient
class EnhancedTimerRing extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final Duration totalDuration;
  final Color color;

  const EnhancedTimerRing({
    super.key,
    required this.value,
    required this.totalDuration,
    this.color = Colors.amber,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background ring
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(
                Colors.white.withValues(alpha: 0.15),
              ),
            ),
          ),
          // Progress ring with gradient
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              value: value,
              strokeWidth: 5,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation(
                color.withValues(alpha: 0.8),
              ),
            ),
          ),
          // Inner content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${(totalDuration.inSeconds * value).toStringAsFixed(0)}s',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
