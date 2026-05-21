/// نظام الرموز التصميمية الموحد
/// Design Tokens System - جميع الثوابت البصرية في مكان واحد
library design_tokens;

import 'package:flutter/material.dart';

abstract class PrimaryColors {
  static const Color gold = Color(0xFFFFD700);
  static const Color goldLight = Color(0xFFFFE55C);
  static const Color goldDark = Color(0xFFE6C200);
  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldLight = Color(0xFF34D399);
  static const Color emeraldDark = Color(0xFF059669);
  static const Color sapphire = Color(0xFF0EA5E9);
  static const Color sapphireLight = Color(0xFF38BDF8);
  static const Color sapphireDark = Color(0xFF0284C7);
  static const Color ruby = Color(0xFFEC4899);
  static const Color rubyLight = Color(0xFFF472B6);
  static const Color rubyDark = Color(0xFFDB2777);
  static const Color amethyst = Color(0xFFA855F7);
  static const Color amethystLight = Color(0xFFC084FC);
  static const Color amethystDark = Color(0xFF9333EA);
}

abstract class NeutralColors {
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);
}

abstract class SemanticColors {
  static const Color success = Color(0xFF059669);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFFD4E4E);
  static const Color info = Color(0xFF0EA5E9);
  static const Color disabled = Color(0xFF9CA3AF);
}

abstract class BackgroundColors {
  static const Color darkDeep = Color(0xFF0F172A);
  static const Color darkMedium = Color(0xFF1E293B);
  static const Color darkLight = Color(0xFF334155);
  static const Color lightSurface = Color(0xFFF1F5F9);
  static const Color lightOverlay = Color(0xFFE2E8F0);
}

abstract class FontSizes {
  static const double xs = 12;
  static const double sm = 14;
  static const double base = 16;
  static const double lg = 18;
  static const double xl = 20;
  static const double xl2 = 24;
  static const double xl3 = 30;
  static const double xl4 = 36;
  static const double xl5 = 48;
  static const double xl6 = 60;
}

abstract class FontWeights {
  static const FontWeight thin = FontWeight.w100;
  static const FontWeight extraLight = FontWeight.w200;
  static const FontWeight light = FontWeight.w300;
  static const FontWeight normal = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
  static const FontWeight black = FontWeight.w900;
}

abstract class LineHeights {
  static const double tight = 1.25;
  static const double snug = 1.375;
  static const double normal = 1.5;
  static const double relaxed = 1.625;
  static const double loose = 2.0;
}

abstract class Spacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xl2 = 24;
  static const double xl3 = 32;
  static const double xl4 = 40;
  static const double xl5 = 48;
  static const double xl6 = 64;
}

abstract class BorderRadii {
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xl2 = 20;
  static const double xl3 = 24;
  static const double full = 9999;
}

abstract class IconSizes {
  static const double xs = 16;
  static const double sm = 20;
  static const double md = 24;
  static const double lg = 32;
  static const double xl = 40;
  static const double xl2 = 48;
  static const double xl3 = 56;
}

abstract class Shadows {
  static const List<BoxShadow> xs = [
    BoxShadow(
      color: Color(0x0F000000),
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x1F000000),
      offset: Offset(0, 1),
      blurRadius: 3,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x29000000),
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -1,
    ),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x33000000),
      offset: Offset(0, 10),
      blurRadius: 15,
      spreadRadius: -3,
    ),
  ];

  static const List<BoxShadow> xl = [
    BoxShadow(
      color: Color(0x3D000000),
      offset: Offset(0, 20),
      blurRadius: 25,
      spreadRadius: -5,
    ),
  ];

  static const List<BoxShadow> glow = [
    BoxShadow(
      color: Color(0x80FFD700),
      offset: Offset(0, 0),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];
}

abstract class DurationTokens {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);
  static const Duration slower = Duration(milliseconds: 500);
  static const Duration slowest = Duration(milliseconds: 700);
}

class DesignTokens {
  // ============================================
  // 1️⃣ نظام الألوان الموحد (Color Palette)
  // ============================================

  /// الألوان الأساسية (Primary Colors)
  static const Color primaryGold = PrimaryColors.gold;
  static const Color primaryGoldLight = PrimaryColors.goldLight;
  static const Color primaryGoldDark = PrimaryColors.goldDark;
  static const Color primaryEmerald = PrimaryColors.emerald;
  static const Color primaryEmeraldLight = PrimaryColors.emeraldLight;
  static const Color primaryEmeraldDark = PrimaryColors.emeraldDark;
  static const Color primarySapphire = PrimaryColors.sapphire;
  static const Color primarySapphireLight = PrimaryColors.sapphireLight;
  static const Color primarySapphireDark = PrimaryColors.sapphireDark;
  static const Color primaryRuby = PrimaryColors.ruby;
  static const Color primaryRubyLight = PrimaryColors.rubyLight;
  static const Color primaryRubyDark = PrimaryColors.rubyDark;
  static const Color primaryAmethyst = PrimaryColors.amethyst;
  static const Color primaryAmethystLight = PrimaryColors.amethystLight;
  static const Color primaryAmethystDark = PrimaryColors.amethystDark;

  /// الألوان الخلفية (Background Colors)
  static const Color backgroundDarkDeep = BackgroundColors.darkDeep;
  static const Color backgroundDarkMedium = BackgroundColors.darkMedium;
  static const Color backgroundDarkLight = BackgroundColors.darkLight;
  static const Color backgroundLightSurface = BackgroundColors.lightSurface;
  static const Color backgroundLightOverlay = BackgroundColors.lightOverlay;

  /// الألوان المحايدة (Neutral Colors)
  static const Color neutralWhite = NeutralColors.white;
  static const Color neutralBlack = NeutralColors.black;
  static const Color neutralGray50 = NeutralColors.gray50;
  static const Color neutralGray100 = NeutralColors.gray100;
  static const Color neutralGray200 = NeutralColors.gray200;
  static const Color neutralGray300 = NeutralColors.gray300;
  static const Color neutralGray400 = NeutralColors.gray400;
  static const Color neutralGray500 = NeutralColors.gray500;
  static const Color neutralGray600 = NeutralColors.gray600;
  static const Color neutralGray700 = NeutralColors.gray700;
  static const Color neutralGray800 = NeutralColors.gray800;
  static const Color neutralGray900 = NeutralColors.gray900;

  /// الألوان الدلالية (Semantic Colors)
  static const Color semanticSuccess = SemanticColors.success;
  static const Color semanticWarning = SemanticColors.warning;
  static const Color semanticError = SemanticColors.error;
  static const Color semanticErrorLight = Color(0xFFFF8A8A); // Added if missing
  static const Color semanticErrorDark = Color(0xFFC62828); // Added if missing
  static const Color semanticInfo = SemanticColors.info;
  static const Color semanticDisabled = SemanticColors.disabled;

  // ============================================
  // 2️⃣ نظام الفقرات والخطوط (Typography)
  // ============================================

  static const double fontSizeXs = FontSizes.xs;
  static const double fontSizeSm = FontSizes.sm;
  static const double fontSizeBase = FontSizes.base;
  static const double fontSizeLg = FontSizes.lg;
  static const double fontSizeXl = FontSizes.xl;
  static const double fontSizeXl2 = FontSizes.xl2;
  static const double fontSizeXl3 = FontSizes.xl3;
  static const double fontSizeXl4 = FontSizes.xl4;
  static const double fontSizeXl5 = FontSizes.xl5;
  static const double fontSizeXl6 = FontSizes.xl6;

  static const FontWeight fontWeightThin = FontWeights.thin;
  static const FontWeight fontWeightExtralight = FontWeights.extraLight;
  static const FontWeight fontWeightLight = FontWeights.light;
  static const FontWeight fontWeightNormal = FontWeights.normal;
  static const FontWeight fontWeightMedium = FontWeights.medium;
  static const FontWeight fontWeightSemiBold = FontWeights.semiBold;
  static const FontWeight fontWeightBold = FontWeights.bold;
  static const FontWeight fontWeightExtrabold = FontWeights.extraBold;
  static const FontWeight fontWeightBlack = FontWeights.black;

  static const double lineHeightTight = LineHeights.tight;
  static const double lineHeightSnug = LineHeights.snug;
  static const double lineHeightNormal = LineHeights.normal;
  static const double lineHeightRelaxed = LineHeights.relaxed;
  static const double lineHeightLoose = LineHeights.loose;

  static const String primaryFont = 'Cairo';
  static const String secondaryFont = 'Orbitron';
  static const String monoFont = 'Courier New';

  // Material Design Text Styles (backward compatibility)
  static const double displayLarge = 57;
  static const double displayMedium = 45;
  static const double displaySmall = 36;
  static const double headlineLarge = 32;
  static const double headlineMedium = 28;
  static const double headlineSmall = 24;
  static const double titleLarge = 22;
  static const double titleMedium = 16;
  static const double titleSmall = 14;
  static const double bodyLarge = 16;
  static const double bodyMedium = 14;
  static const double bodySmall = 12;
  static const double labelLarge = 14;
  static const double labelMedium = 12;
  static const double labelSmall = 11;

  // Font Weights (backward compatibility)
  static const FontWeight thin = FontWeights.thin;
  static const FontWeight extraLight = FontWeights.extraLight;
  static const FontWeight light = FontWeights.light;
  static const FontWeight regular = FontWeights.normal;
  static const FontWeight medium = FontWeights.medium;
  static const FontWeight semiBold = FontWeights.semiBold;
  static const FontWeight bold = FontWeights.bold;
  static const FontWeight extraBold = FontWeights.extraBold;
  static const FontWeight black = FontWeights.black;

  // Line Heights (backward compatibility)
  static const double tight = LineHeights.tight;
  static const double snug = LineHeights.snug;
  static const double normal = LineHeights.normal;
  static const double relaxed = LineHeights.relaxed;
  static const double loose = LineHeights.loose;

  // ============================================
  // 3️⃣ نظام المسافات (Spacing Scale)
  // ============================================

  static const double spacingXs = Spacing.xs;
  static const double spacingSm = Spacing.sm;
  static const double spacingMd = Spacing.md;
  static const double spacingLg = Spacing.lg;
  static const double spacingXl = Spacing.xl;
  static const double spacingXl2 = Spacing.xl2;
  static const double spacingXl3 = Spacing.xl3;
  static const double spacingXl4 = Spacing.xl4;
  static const double spacingXl5 = Spacing.xl5;
  static const double spacingXl6 = Spacing.xl6;

  // ============================================
  // 4️⃣ نظام الزوايا المستديرة (Border Radius)
  // ============================================

  static const double borderRadiusXs = BorderRadii.xs;
  static const double borderRadiusSm = BorderRadii.sm;
  static const double borderRadiusMd = BorderRadii.md;
  static const double borderRadiusLg = BorderRadii.lg;
  static const double borderRadiusXl = BorderRadii.xl;
  static const double borderRadiusXl2 = BorderRadii.xl2;
  static const double borderRadiusXl3 = BorderRadii.xl3;
  static const double borderRadiusFull = BorderRadii.full;

  // ============================================
  // 5️⃣ نظام الارتفاعات (Elevation)
  // ============================================

  static const double elevation0 = 0;
  static const double elevation1 = 1;
  static const double elevation2 = 3;
  static const double elevation3 = 6;
  static const double elevation4 = 8;
  static const double elevation5 = 12;
  static const double elevation6 = 16;
  static const double elevation7 = 24;
  static const double elevation8 = 32;
  static const double elevation9 = 40;
  static const double elevation10 = 48;
  static const double elevation11 = 56;
  static const double elevation12 = 64;

  static const List<BoxShadow> shadowXs = Shadows.xs;
  static const List<BoxShadow> shadowSm = Shadows.sm;
  static const List<BoxShadow> shadowMd = Shadows.md;
  static const List<BoxShadow> shadowLg = Shadows.lg;
  static const List<BoxShadow> shadowXl = Shadows.xl;
  static const List<BoxShadow> shadowGlow = Shadows.glow;

  // ============================================
  // 6️⃣ نظام المدد الزمنية (Duration)
  // ============================================

  static const Duration durationFast = DurationTokens.fast;
  static const Duration durationBase = DurationTokens.normal;
  static const Duration durationSlow = DurationTokens.slow;
  static const Duration durationSlower = DurationTokens.slower;
  static const Duration durationSlowest = DurationTokens.slowest;

  // ============================================
  // 7️⃣ نظام الانحناءات (Curves)
  // ============================================

  static const Curve curveEaseIn = Curves.easeIn;
  static const Curve curveEaseOut = Curves.easeOut;
  static const Curve curveEaseInOut = Curves.easeInOut;
  static const Curve curveLinear = Curves.linear;
  static const Curve curveBounceIn = Curves.bounceIn;
  static const Curve curveBounceOut = Curves.bounceOut;

  // ============================================
  // 8️⃣ نظام الرموز (Icon Sizes)
  // ============================================

  static const double iconSizeXs = IconSizes.xs;
  static const double iconSizeSm = IconSizes.sm;
  static const double iconSizeMd = IconSizes.md;
  static const double iconSizeLg = IconSizes.lg;
  static const double iconSizeXl = IconSizes.xl;
  static const double iconSizeXl2 = IconSizes.xl2;
  static const double iconSizeXl3 = IconSizes.xl3;

  // ============================================
  // 9️⃣ ثوابت إضافية
  // ============================================

  /// الشفافية المعيارية
  static const double opacityDisabled = 0.5;
  static const double opacityHover = 0.8;
  static const double opacityActive = 1.0;
  static const double opacityGlass = 0.1;

  /// ارتفاعات عناصر الواجهة
  static const double appBarHeight = 56;
  static const double bottomNavHeight = 56;
  static const double buttonHeight = 44;
  static const double inputHeight = 44;
  static const double chipHeight = 32;

  /// عمق النصوص (Text Scale)
  static const double textScaleFactor = 1.0;

  // Compatibility classes that don't use instances anymore for better const support
  // Note: These classes are now abstract with static members.
  // We provide these "proxy" objects for backward compatibility with instance access,
  // but they will NOT work in const expressions. For const, use the class directly (e.g., PrimaryColors.gold).
  static const _PrimaryColorsCompat primaryColors = _PrimaryColorsCompat();
  static const _NeutralColorsCompat neutralColors = _NeutralColorsCompat();
  static const _SemanticColorsCompat semanticColors = _SemanticColorsCompat();
  static const _BackgroundColorsCompat backgroundColors =
      _BackgroundColorsCompat();
  static const _FontSizesCompat fontSizes = _FontSizesCompat();
  static const _FontWeightsCompat fontWeights = _FontWeightsCompat();
  static const _LineHeightsCompat lineHeights = _LineHeightsCompat();
  static const _SpacingCompat spacing = _SpacingCompat();
  static const _BorderRadiiCompat borderRadii = _BorderRadiiCompat();
  static const _IconSizesCompat iconSizes = _IconSizesCompat();
  static const _ShadowsCompat shadows = _ShadowsCompat();
  static const _DurationTokensCompat durations =
      _DurationTokensCompat(); // Alias
  static const _DurationTokensCompat durationTokens = _DurationTokensCompat();
}

// Compatibility wrappers for non-const instance access
class _PrimaryColorsCompat {
  const _PrimaryColorsCompat();
  Color get gold => PrimaryColors.gold;
  Color get goldLight => PrimaryColors.goldLight;
  Color get goldDark => PrimaryColors.goldDark;
  Color get emerald => PrimaryColors.emerald;
  Color get emeraldLight => PrimaryColors.emeraldLight;
  Color get emeraldDark => PrimaryColors.emeraldDark;
  Color get sapphire => PrimaryColors.sapphire;
  Color get sapphireLight => PrimaryColors.sapphireLight;
  Color get sapphireDark => PrimaryColors.sapphireDark;
  Color get ruby => PrimaryColors.ruby;
  Color get rubyLight => PrimaryColors.rubyLight;
  Color get rubyDark => PrimaryColors.rubyDark;
  Color get amethyst => PrimaryColors.amethyst;
  Color get amethystLight => PrimaryColors.amethystLight;
  Color get amethystDark => PrimaryColors.amethystDark;
}

class _NeutralColorsCompat {
  const _NeutralColorsCompat();
  Color get white => NeutralColors.white;
  Color get black => NeutralColors.black;
  Color get gray50 => NeutralColors.gray50;
  Color get gray100 => NeutralColors.gray100;
  Color get gray200 => NeutralColors.gray200;
  Color get gray300 => NeutralColors.gray300;
  Color get gray400 => NeutralColors.gray400;
  Color get gray500 => NeutralColors.gray500;
  Color get gray600 => NeutralColors.gray600;
  Color get gray700 => NeutralColors.gray700;
  Color get gray800 => NeutralColors.gray800;
  Color get gray900 => NeutralColors.gray900;
}

class _SemanticColorsCompat {
  const _SemanticColorsCompat();
  Color get success => SemanticColors.success;
  Color get warning => SemanticColors.warning;
  Color get error => SemanticColors.error;
  Color get info => SemanticColors.info;
  Color get disabled => SemanticColors.disabled;
}

class _BackgroundColorsCompat {
  const _BackgroundColorsCompat();
  Color get darkDeep => BackgroundColors.darkDeep;
  Color get darkMedium => BackgroundColors.darkMedium;
  Color get darkLight => BackgroundColors.darkLight;
  Color get lightSurface => BackgroundColors.lightSurface;
  Color get lightOverlay => BackgroundColors.lightOverlay;
}

class _FontSizesCompat {
  const _FontSizesCompat();
  double get xs => FontSizes.xs;
  double get sm => FontSizes.sm;
  double get base => FontSizes.base;
  double get lg => FontSizes.lg;
  double get xl => FontSizes.xl;
  double get xl2 => FontSizes.xl2;
  double get xl3 => FontSizes.xl3;
  double get xl4 => FontSizes.xl4;
  double get xl5 => FontSizes.xl5;
  double get xl6 => FontSizes.xl6;
}

class _FontWeightsCompat {
  const _FontWeightsCompat();
  FontWeight get thin => FontWeights.thin;
  FontWeight get extraLight => FontWeights.extraLight;
  FontWeight get light => FontWeights.light;
  FontWeight get normal => FontWeights.normal;
  FontWeight get medium => FontWeights.medium;
  FontWeight get semiBold => FontWeights.semiBold;
  FontWeight get semibold => FontWeights.semiBold; // Alias for typo
  FontWeight get bold => FontWeights.bold;
  FontWeight get extraBold => FontWeights.extraBold;
  FontWeight get black => FontWeights.black;
}

class _LineHeightsCompat {
  const _LineHeightsCompat();
  double get tight => LineHeights.tight;
  double get snug => LineHeights.snug;
  double get normal => LineHeights.normal;
  double get relaxed => LineHeights.relaxed;
  double get loose => LineHeights.loose;
}

class _SpacingCompat {
  const _SpacingCompat();
  double get xs => Spacing.xs;
  double get sm => Spacing.sm;
  double get md => Spacing.md;
  double get lg => Spacing.lg;
  double get xl => Spacing.xl;
  double get xl2 => Spacing.xl2;
  double get xl3 => Spacing.xl3;
  double get xl4 => Spacing.xl4;
  double get xl5 => Spacing.xl5;
  double get xl6 => Spacing.xl6;
}

class _BorderRadiiCompat {
  const _BorderRadiiCompat();
  double get xs => BorderRadii.xs;
  double get sm => BorderRadii.sm;
  double get md => BorderRadii.md;
  double get lg => BorderRadii.lg;
  double get xl => BorderRadii.xl;
  double get xl2 => BorderRadii.xl2;
  double get xl3 => BorderRadii.xl3;
  double get full => BorderRadii.full;
}

class _IconSizesCompat {
  const _IconSizesCompat();
  double get xs => IconSizes.xs;
  double get sm => IconSizes.sm;
  double get md => IconSizes.md;
  double get lg => IconSizes.lg;
  double get xl => IconSizes.xl;
  double get xl2 => IconSizes.xl2;
  double get xl3 => IconSizes.xl3;
}

class _ShadowsCompat {
  const _ShadowsCompat();
  List<BoxShadow> get xs => Shadows.xs;
  List<BoxShadow> get sm => Shadows.sm;
  List<BoxShadow> get md => Shadows.md;
  List<BoxShadow> get lg => Shadows.lg;
  List<BoxShadow> get xl => Shadows.xl;
  List<BoxShadow> get glow => Shadows.glow;
}

class _DurationTokensCompat {
  const _DurationTokensCompat();
  Duration get fast => DurationTokens.fast;
  Duration get normal => DurationTokens.normal;
  Duration get slow => DurationTokens.slow;
  Duration get slower => DurationTokens.slower;
  Duration get slowest => DurationTokens.slowest;
}
