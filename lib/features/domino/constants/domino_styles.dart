import 'package:flutter/material.dart';

class RoyalStyles {
  // تدرجات الذهب الفاخرة (Gold Gradient)
  static const List<Color> goldGradient = [
    Color(0xFFFBBF24), // gold-400
    Color(0xFFF59E0B), // gold-500
    Color(0xFFD97706), // gold-600
  ];

  // تدرجات الأسود الملكي (Dark Gradient)
  static const List<Color> darkGradient = [
    Color(0xFF1A1A1A), // dark-100
    Color(0xFF0F172A), // dark-900
  ];

  static const Color goldColor = Color(0xFFD4AF37);
  static const Color darkBg = Color(0xFF121212);

  // أنماط النصوص
  static const TextStyle goldenTitle = TextStyle(
    color: Color(0xFFFBBF24),
    fontSize: 24,
    fontWeight: FontWeight.bold,
    fontFamily: 'Serif',
    letterSpacing: 1.5,
  );
}
