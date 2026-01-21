import 'dart:ui'; // إضافة هذا الاستيراد لحل مشكلة ImageFilter
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- الألوان الملكية الزرقاء الجديدة ---
  static const Color primaryBlue = Color(0xFF0D1B3E); // الأزرق الملكي العميق
  static const Color backgroundBlack = Color(0xFF020A1A); // الأسود العميق
  static const Color royalGold = Color(0xFFD4AF37); // الذهب الملكي
  static const Color accentCyan = Color(0xFF00E5FF); // السماوي المشع للمسات الجمالية

  static const LinearGradient mainGradient = LinearGradient(
    colors: [primaryBlue, backgroundBlack],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData themeData() {
    return ThemeData(
      textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme),
      scaffoldBackgroundColor: backgroundBlack,
      primaryColor: primaryBlue,
      colorScheme: const ColorScheme.dark(
        primary: royalGold,
        secondary: accentCyan,
        surface: primaryBlue,
      ),
    );
  }

  // خلفية ملكية متدرجة موحدة لكل الصفحات
  static Widget background({required Widget child}) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D1B3E), Color(0xFF020A1A), Color(0xFF000000)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: child,
    );
  }

  // حاوية زجاجية فخمة (Glassmorphism)
  static Widget glassContainer({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    BorderRadius? borderRadius,
    double opacity = 0.05,
    bool borderGlow = false,
    double? width,
    double? height,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: width,
          height: height,
          margin: margin,
          padding: padding ?? const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: borderRadius ?? BorderRadius.circular(25),
            color: Colors.white.withValues(alpha: opacity),
            border: Border.all(
              color: borderGlow ? royalGold.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              if (borderGlow)
                BoxShadow(color: royalGold.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 2),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  // زر متدرج ذهبي فخم
  static Widget gradientButton({
    required String text,
    required VoidCallback? onPressed,
    double height = 55,
    double? width,
    IconData? icon,
  }) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: goldGradient,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) Icon(icon, color: Colors.black, size: 22),
            if (icon != null) const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  // حقل إدخال ملكي
  static Widget royalInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
  }) {
    return glassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      opacity: 0.03,
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          prefixIcon: Icon(icon, color: royalGold, size: 20),
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        ),
      ),
    );
  }
}
