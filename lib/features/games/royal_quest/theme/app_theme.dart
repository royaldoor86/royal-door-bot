import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryDark = Color(0xFF0A1929);
  static const Color primaryNavy = Color(0xFF1A237E);
  static const Color secondaryNavy = Color(0xFF283593);
  static const Color goldAccent = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFFFD700);
  static const Color silverAccent = Color(0xFFC0C0C0);
  static const Color correctGreen = Color(0xFF4CAF50);
  static const Color wrongRed = Color(0xFFE53935);
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textGold = Color(0xFFFFD700);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: goldAccent,
        secondary: silverAccent,
        surface: primaryDark,
        error: wrongRed,
      ),
      scaffoldBackgroundColor: primaryDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryNavy,
        foregroundColor: textWhite,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: const CardThemeData(
        color: secondaryNavy,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: goldAccent,
          foregroundColor: primaryDark,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textWhite,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textWhite,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textGold,
        ),
        bodyLarge: TextStyle(
          fontSize: 18,
          color: textWhite,
        ),
        bodyMedium: TextStyle(
          fontSize: 16,
          color: textWhite,
        ),
      ),
    );
  }
}
