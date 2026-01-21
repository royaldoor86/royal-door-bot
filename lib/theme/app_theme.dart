import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // الألوان الأرجوانية والوردية الملكية
  static const Color primaryWarm = Color(0xFFFF4D6D); 
  static const Color secondaryWarm = Color(0xFF7C4DFF); 
  static const Color accentWarm = Color(0xFFFFD700); 

  // دعم المسميات للتوافق مع باقي الصفحات
  static const Color primaryPurple = Color(0xFF8E24AA);
  static const Color secondaryPurple = Color(0xFFD81B60);
  static const Color primaryDarkPurple = Color(0xFF4A148C);

  static const Color backgroundTop = Color(0xFF2D142C); 
  static const Color backgroundBottom = Color(0xFF801336); 
  static const Color backgroundDark = Color(0xFF1A0A10);

  static const LinearGradient mainGradient = LinearGradient(
    colors: [secondaryWarm, primaryWarm],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const List<List<Color>> roomThemes = [
    [Color(0xFF2D142C), Color(0xFF801336)],
    [Color(0xFF1A0A10), Color(0xFF4A148C)],
    [Color(0xFF0D0D0D), Color(0xFF1A1A1A)],
    [Color(0xFF6200EA), Color(0xFFD81B60)],
  ];

  static LinearGradient roomThemeGradient(int index) {
    final list = roomThemes[index.clamp(0, roomThemes.length - 1)];
    return LinearGradient(
      colors: list,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static String formatNumber(num value) {
    if (value < 1000) return value.toInt().toString();
    if (value < 1000000) {
      double kValue = value / 1000.0;
      if (value % 1000 == 0) return "${kValue.toInt()}k";
      return "${kValue.toStringAsFixed(1)}k";
    }
    return (value / 1000000.0).toStringAsFixed(1) + "M";
  }

  static ThemeData themeData() {
    return ThemeData(
      textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme),
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryWarm,
        secondary: secondaryWarm,
        surface: backgroundDark,
      ),
    );
  }

  static Widget background({required Widget child}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [backgroundTop, backgroundBottom],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: child,
    );
  }

  static BoxDecoration neuBox({bool isPressed = false}) {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.1)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          offset: const Offset(4, 4),
          blurRadius: 10,
        ),
      ],
    );
  }

  static Widget glassContainer({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
    double opacity = 0.15,
    bool borderGlow = false,
    double? width,
    double? height,
  }) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(24),
        color: Colors.white.withOpacity(opacity),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5)),
          if (borderGlow) BoxShadow(color: accentWarm.withOpacity(0.2), blurRadius: 15, spreadRadius: 2),
        ],
      ),
      child: child,
    );
  }

  static Widget gradientButton({
    required String text,
    required VoidCallback? onPressed,
    double height = 50,
    double? width,
    IconData? icon,
  }) {
    final bool enabled = onPressed != null;
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          gradient: enabled ? mainGradient : const LinearGradient(colors: [Color(0xFF555555), Color(0xFF333333)]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            if (enabled) BoxShadow(color: primaryWarm.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) Icon(icon, color: Colors.white, size: 20),
              if (icon != null) const SizedBox(width: 8),
              Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  static Widget glassButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.white.withOpacity(0.1),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  static Widget glassButtonWide({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white.withOpacity(0.08),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.amberAccent, size: 22),
            const SizedBox(width: 12),
            Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold))),
            const Icon(Icons.chevron_left, color: Colors.white30),
          ],
        ),
      ),
    );
  }
}
