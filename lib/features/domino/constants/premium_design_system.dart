import 'package:flutter/material.dart';

/// Premium Color System for Professional Domino Game
class PremiumColorPalette {
  // Primary Table Colors
  static const Color tableGreen = Color(0xFF1B5E20);
  static const Color tableDarkGreen = Color(0xFF0D3311);
  static const Color tableAccent = Color(0xFF2E7D32);

  // Premium Accent Colors
  static const Color goldAccent = Color(0xFFFFB81C);
  static const Color amberAccent = Color(0xFFFFA500);
  static const Color sapphireAccent = Color(0xFF1E88E5);
  static const Color emeraldAccent = Color(0xFF00BCD4);

  // Card/UI Colors
  static const Color cardDark = Color(0xFF1A1A1A);
  static const Color cardLight = Color(0xFF2D2D2D);

  // Text Colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textAccent = Color(0xFFFFB81C);

  // Status Colors
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color errorRed = Color(0xFFF44336);
  static const Color infoBlue = Color(0xFF2196F3);

  // Gradients
  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFB81C), Color(0xFFFFA500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient victoryGradient = LinearGradient(
    colors: [Color(0xFFFFB81C), Color(0xFFFFC107)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Typography System for Professional UI
class PremiumTypography {
  // Display Styles
  static const TextStyle heading1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: PremiumColorPalette.textPrimary,
    letterSpacing: 0.5,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: PremiumColorPalette.textPrimary,
    letterSpacing: 0.3,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: PremiumColorPalette.textPrimary,
  );

  // Body Styles
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: PremiumColorPalette.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: PremiumColorPalette.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: PremiumColorPalette.textSecondary,
  );

  // Button Styles
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    letterSpacing: 0.5,
  );

  static const TextStyle buttonSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  // Special Styles
  static const TextStyle scoreValue = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: PremiumColorPalette.goldAccent,
    letterSpacing: 1,
  );

  static const TextStyle pointsValue = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: PremiumColorPalette.amberAccent,
  );

  static TextStyle victoryText = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    shadows: [
      Shadow(
        offset: const Offset(2, 2),
        blurRadius: 8,
        color: PremiumColorPalette.goldAccent.withValues(alpha: 0.6),
      ),
      Shadow(
        offset: const Offset(4, 4),
        blurRadius: 16,
        color: Colors.black.withValues(alpha: 0.4),
      ),
    ],
  );
}

/// Spacing System for Consistent Layout
class PremiumSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Border Radius System
class PremiumBorderRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 100;
}

/// Shadow System for Depth
class PremiumShadows {
  static const BoxShadow subtle = BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 4,
    offset: Offset(0, 2),
  );

  static const BoxShadow medium = BoxShadow(
    color: Color(0x26000000),
    blurRadius: 12,
    offset: Offset(0, 8),
  );

  static const BoxShadow large = BoxShadow(
    color: Color(0x33000000),
    blurRadius: 24,
    offset: Offset(0, 16),
  );

  static final List<BoxShadow> elevated = [
    const BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
    const BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];

  static final List<BoxShadow> premium = [
    const BoxShadow(
      color: Color(0x26000000),
      blurRadius: 12,
      offset: Offset(0, 6),
    ),
    const BoxShadow(
      color: Color(0x0F000000),
      blurRadius: 20,
      offset: Offset(0, 12),
    ),
  ];

  static final List<BoxShadow> glow = [
    BoxShadow(
      color: PremiumColorPalette.goldAccent.withValues(alpha: 0.3),
      blurRadius: 16,
      spreadRadius: 2,
    ),
    const BoxShadow(
      color: Color(0x26000000),
      blurRadius: 12,
      offset: Offset(0, 8),
    ),
  ];
}

/// Premium Card Style with Glassmorphism
class PremiumCardDecoration {
  static BoxDecoration get standard => BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.1),
            Colors.white.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: PremiumShadows.premium,
      );

  static BoxDecoration get elevated => BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.15),
            Colors.white.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
        boxShadow: PremiumShadows.glow,
      );

  static BoxDecoration withGradient(LinearGradient gradient) => BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: PremiumShadows.premium,
      );

  static BoxDecoration get dark => BoxDecoration(
        color: PremiumColorPalette.cardDark.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
        boxShadow: const [PremiumShadows.medium],
      );
}

/// Premium Button Decorations
class PremiumButtonDecoration {
  static BoxDecoration get primary => BoxDecoration(
        gradient: PremiumColorPalette.goldGradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: PremiumShadows.glow,
      );

  static BoxDecoration get secondary => BoxDecoration(
        gradient: LinearGradient(
          colors: [
            PremiumColorPalette.sapphireAccent,
            PremiumColorPalette.sapphireAccent.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: PremiumShadows.premium,
      );

  static BoxDecoration get success => BoxDecoration(
        gradient: LinearGradient(
          colors: [
            PremiumColorPalette.successGreen,
            PremiumColorPalette.successGreen.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: PremiumShadows.premium,
      );

  static BoxDecoration get danger => BoxDecoration(
        gradient: LinearGradient(
          colors: [
            PremiumColorPalette.errorRed,
            PremiumColorPalette.errorRed.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: PremiumShadows.premium,
      );

  static BoxDecoration get disabled => BoxDecoration(
        color: Colors.grey[600],
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 8,
          ),
        ],
      );
}

/// Opacity Levels for Professional UI
class PremiumOpacity {
  static const double disabled = 0.5;
  static const double secondary = 0.7;
  static const double tertiary = 0.6;
  static const double hover = 0.9;
  static const double focus = 0.95;
  static const double full = 1.0;
}

/// Animation Durations
class PremiumAnimationDuration {
  static const Duration instant = Duration(milliseconds: 150);
  static const Duration fast = Duration(milliseconds: 250);
  static const Duration normal = Duration(milliseconds: 400);
  static const Duration slow = Duration(milliseconds: 600);
  static const Duration verySlow = Duration(milliseconds: 1000);
}
