import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// الفئة المحسّنة من AppTheme مع دعم النظام الجديد
/// Enhanced AppTheme class with support for the new design system
class AppTheme {
  // --- ألوان الثيم الافتراضي (Galaxy Blue) ---
  static const Color backgroundDeep = Color(0xFF0F172A);
  static const Color cardBlue = Color(0xFF1E293B);
  static const Color royalGold = Color(0xFFFFD700);
  static const Color accentCyan = Color(0xFF38BDF8);

  // --- ألوان الثيم الملكي (بنفسجي زهري) ---
  static const Color royalPink = Color(0xFFC026D3);
  static const Color royalPurple = Color(0xFF4C1D95);

  // --- ألوان الوضع الزمردي الملكي (الصباحي - مطابق لنظام المكافآت) ---
  static const Color emeraldMain = Color(0xFF0B2D16); // زمردي ملكي داكن وفخم
  static const Color emeraldSurface = Color(0xFF0D3D1D); // أسطح زمردية
  static const Color emeraldLight =
      Color(0xFF10B981); // لون زمردي مشع للتنبيهات

  // --- مسميات قديمة لضمان توافق الكود ---
  static const Color backgroundBlack = backgroundDeep;
  static const Color primaryBlue = cardBlue;
  static const Color primaryWarm = backgroundDeep;

  static ThemeData themeData(
      {bool isRoyal = false, ThemeMode mode = ThemeMode.dark}) {
    bool isLight = mode == ThemeMode.light;

    return ThemeData(
      brightness: isLight ? Brightness.light : Brightness.dark,
      textTheme: GoogleFonts.cairoTextTheme(
          isLight ? ThemeData.light().textTheme : ThemeData.dark().textTheme),
      scaffoldBackgroundColor: isLight
          ? emeraldMain
          : (isRoyal ? const Color(0xFF2D0B2D) : backgroundDeep),
      primaryColor:
          isRoyal ? royalPink : (isLight ? emeraldLight : backgroundDeep),
      colorScheme: ColorScheme(
        brightness: isLight ? Brightness.light : Brightness.dark,
        primary: isLight ? emeraldLight : (isRoyal ? royalPink : royalGold),
        onPrimary: Colors.white,
        secondary: isLight
            ? Colors.white70
            : (isRoyal ? Colors.pinkAccent : accentCyan),
        onSecondary: Colors.white,
        error: Colors.red,
        onError: Colors.white,
        surface: isLight
            ? emeraldSurface
            : (isRoyal ? const Color(0xFF3D123D) : cardBlue),
        onSurface: Colors.white,
      ),
    );
  }

  // خلفية تكتشف الثيم والوضع تلقائياً وتطبق التدرج الزمردي أو البنفسجي أو الأزرق
  static Widget background({required Widget child, bool? isRoyal}) {
    return Builder(builder: (context) {
      bool isLight = Theme.of(context).brightness == Brightness.light;
      bool effectiveRoyal =
          isRoyal ?? (Theme.of(context).primaryColor == royalPink);

      return Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isLight
                    ? [const Color(0xFF0B2D16), const Color(0xFF05150B)]
                    : (effectiveRoyal
                        ? [
                            const Color(0xFF4C1D95),
                            const Color(0xFF2D0B2D),
                            Colors.black
                          ]
                        : [
                            const Color(0xFF1E293B),
                            const Color(0xFF0F172A),
                            const Color(0xFF020617)
                          ]),
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // جزيئات ذهبية متطايرة ببطء للخلفية الملكية
          if (!isLight)
            const Positioned.fill(
              child: IgnorePointer(
                child: _RoyalFloatingParticles(),
              ),
            ),
          child,
        ],
      );
    });
  }

  static Widget glassContainer({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
    double opacity = 0.1,
    bool borderGlow = false,
    bool? isRoyal,
    double? width,
    double? height,
  }) {
    return Builder(builder: (context) {
      bool isLight = Theme.of(context).brightness == Brightness.light;
      bool effectiveRoyal =
          isRoyal ?? (Theme.of(context).primaryColor == royalPink);

      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            width: width,
            height: height,
            margin: margin,
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: borderRadius ?? BorderRadius.circular(20),
              color: isLight
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: opacity),
              border: Border.all(
                color: borderGlow
                    ? (effectiveRoyal
                            ? Colors.pinkAccent
                            : (isLight ? emeraldLight : royalGold))
                        .withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
              boxShadow: [
                if (borderGlow)
                  BoxShadow(
                      color: (effectiveRoyal
                              ? Colors.pinkAccent
                              : (isLight ? emeraldLight : royalGold))
                          .withValues(alpha: 0.1),
                      blurRadius: 25,
                      spreadRadius: 2),
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2), blurRadius: 10),
              ],
            ),
            child: child,
          ),
        ),
      );
    });
  }

  static Widget gradientButton({
    required String text,
    required VoidCallback? onPressed,
    double height = 50,
    double? width,
    IconData? icon,
    bool? isRoyal,
    Color? color,
    List<Color>? customColors,
  }) {
    return Builder(builder: (context) {
      bool isLight = Theme.of(context).brightness == Brightness.light;
      bool effectiveRoyal =
          isRoyal ?? (Theme.of(context).primaryColor == royalPink);

      List<Color> buttonColors;
      if (customColors != null) {
        buttonColors = customColors;
      } else if (color != null) {
        buttonColors = [color, color.withValues(alpha: 0.7)];
      } else {
        buttonColors = effectiveRoyal
            ? [const Color(0xFFC026D3), const Color(0xFF701A75)]
            : (isLight
                ? [const Color(0xFF10B981), const Color(0xFF064E3B)]
                : [const Color(0xFFFFD700), const Color(0xFFB8860B)]);
      }

      return Container(
        width: width ?? double.infinity,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: buttonColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: (customColors != null
                        ? customColors.first
                        : (color ??
                            (effectiveRoyal
                                ? Colors.pinkAccent
                                : (isLight ? emeraldLight : royalGold))))
                    .withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 4))
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) Icon(icon, color: Colors.white, size: 20),
              if (icon != null) const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  static Widget royalInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    bool? isRoyal,
  }) {
    return Builder(builder: (context) {
      bool isLight = Theme.of(context).brightness == Brightness.light;
      bool effectiveRoyal =
          isRoyal ?? (Theme.of(context).primaryColor == royalPink);

      return glassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        opacity: 0.05,
        isRoyal: effectiveRoyal,
        child: TextFormField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: hint,
            prefixIcon: Icon(icon,
                color: isLight
                    ? emeraldLight
                    : (effectiveRoyal ? Colors.pinkAccent : royalGold)
                        .withValues(alpha: 0.8),
                size: 20),
            hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ),
      );
    });
  }
}

class _RoyalFloatingParticles extends StatefulWidget {
  const _RoyalFloatingParticles();

  @override
  State<_RoyalFloatingParticles> createState() => _RoyalFloatingParticlesState();
}

class _RoyalFloatingParticlesState extends State<_RoyalFloatingParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    for (int i = 0; i < 20; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 2 + 1,
        speed: _random.nextDouble() * 0.02 + 0.01,
      ));
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
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlePainter(_particles, _controller.value),
        );
      },
    );
  }
}

class _Particle {
  double x, y, size, speed;
  _Particle({required this.x, required this.y, required this.size, required this.speed});
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double animationValue;

  _ParticlePainter(this.particles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    for (var p in particles) {
      double curY = (p.y - (animationValue * p.speed * 10)) % 1.0;
      canvas.drawCircle(
        Offset(p.x * size.width, curY * size.height),
        p.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
