import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'design_tokens.dart';
import 'responsive_breakpoints.dart';

/// نظام الثيمات الموحد للتطبيق
/// يوفر ثيمات فاتحة وداكنة مع دعم كامل للتصميم الموحد
class AppTheme {
  // ============================================
  // 1️⃣ الثيمة الفاتحة (Light Theme)
  // ============================================

  static ThemeData get light => ThemeData(
        useMaterial3: true,

        // الألوان الأساسية
        primaryColor: DesignTokens.primaryColors.gold,
        primaryColorLight: DesignTokens.primaryColors.goldLight,
        primaryColorDark: DesignTokens.primaryColors.goldDark,
        scaffoldBackgroundColor: DesignTokens.backgroundLightSurface,
        canvasColor: DesignTokens.backgroundLightSurface,

        // نظام الألوان
        colorScheme: ColorScheme.light(
          primary: DesignTokens.primaryGold,
          primaryContainer: DesignTokens.primaryEmerald,
          secondary: DesignTokens.primarySapphire,
          secondaryContainer: DesignTokens.primaryRuby,
          tertiary: DesignTokens.primaryAmethyst,
          tertiaryContainer: DesignTokens.primarySapphire,
          surface: DesignTokens.backgroundLightSurface,
          surfaceContainerHighest: DesignTokens.backgroundLightOverlay,
          error: DesignTokens.semanticError,
          errorContainer: DesignTokens.semanticError,
          onPrimary: DesignTokens.neutralWhite,
          onPrimaryContainer: DesignTokens.neutralBlack,
          onSecondary: DesignTokens.neutralWhite,
          onSecondaryContainer: DesignTokens.neutralBlack,
          onTertiary: DesignTokens.neutralWhite,
          onTertiaryContainer: DesignTokens.neutralBlack,
          onSurface: DesignTokens.neutralBlack,
          onSurfaceVariant: DesignTokens.neutralGray600,
          onError: DesignTokens.neutralWhite,
          onErrorContainer: DesignTokens.neutralWhite,
          outline: DesignTokens.neutralGray400,
          outlineVariant: DesignTokens.neutralGray300,
          shadow: DesignTokens.neutralGray200,
          scrim: DesignTokens.neutralBlack.withValues(alpha: 0.32),
          inverseSurface: DesignTokens.neutralGray900,
          onInverseSurface: DesignTokens.neutralWhite,
          inversePrimary: DesignTokens.primaryEmerald,
          surfaceTint: DesignTokens.primaryGold.withValues(alpha: 0.05),
        ),

        // نظام الخطوط
        fontFamily: 'Cairo',
        textTheme: _buildTextTheme(false),
        primaryTextTheme: _buildTextTheme(false),

        // نظام الأزرار
        elevatedButtonTheme: _buildElevatedButtonTheme(false),
        outlinedButtonTheme: _buildOutlinedButtonTheme(false),
        textButtonTheme: _buildTextButtonTheme(false),
        filledButtonTheme: _buildFilledButtonTheme(false),

        // نظام الإدخال
        inputDecorationTheme: _buildInputDecorationTheme(false),

        // نظام البطاقات
        cardTheme: _buildCardTheme(false),

        // نظام التطبيق العلوي
        appBarTheme: _buildAppBarTheme(false),

        // نظام التنقل السفلي
        bottomNavigationBarTheme: _buildBottomNavigationBarTheme(false),

        // نظام التبويبات
        tabBarTheme: _buildTabBarTheme(false),

        // نظام مربعات الحوار
        dialogTheme: _buildDialogTheme(false),

        // نظام القوائم
        listTileTheme: _buildListTileTheme(false),

        // نظام التنبيهات
        snackBarTheme: _buildSnackBarTheme(false),

        // نظام الرموز
        iconTheme: _buildIconTheme(false),

        // نظام الظلال
        shadowColor: DesignTokens.neutralGray200,

        // نظام الانتقالات
        pageTransitionsTheme: _buildPageTransitionsTheme(),

        // نظام التمرير
        scrollbarTheme: _buildScrollbarTheme(false),

        // نظام التحديد
        textSelectionTheme: _buildTextSelectionTheme(false),

        // نظام الشرائح
        sliderTheme: _buildSliderTheme(false),

        // نظام خانات الاختيار
        checkboxTheme: _buildCheckboxTheme(false),

        // نظام أزرار الراديو
        radioTheme: _buildRadioTheme(false),

        // نظام المفاتيح
        switchTheme: _buildSwitchTheme(false),

        // نظام التقدم
        progressIndicatorTheme: _buildProgressIndicatorTheme(false),

        // نظام التوسع
        expansionTileTheme: _buildExpansionTileTheme(false),

        // نظام التلميحات
        tooltipTheme: _buildTooltipTheme(false),

        // نظام القائمة المنسدلة
        dropdownMenuTheme: _buildDropdownMenuTheme(false),

        // نظام التنبؤ
        searchBarTheme: _buildSearchBarTheme(false),
        searchViewTheme: _buildSearchViewTheme(false),

        // نظام التمدد
        floatingActionButtonTheme: _buildFloatingActionButtonTheme(false),

        // نظام التنبيهات
        bannerTheme: _buildBannerTheme(false),

        // نظام التنقل
        navigationBarTheme: _buildNavigationBarTheme(false),
        navigationDrawerTheme: _buildNavigationDrawerTheme(false),
        navigationRailTheme: _buildNavigationRailTheme(false),

        // نظام التمرير
        drawerTheme: _buildDrawerTheme(false),

        // نظام الطباعة
        cupertinoOverrideTheme: _buildCupertinoOverrideTheme(false),

        // نظام التمدد
        bottomSheetTheme: _buildBottomSheetTheme(false),

        // نظام الطبقات
        popupMenuTheme: _buildPopupMenuTheme(false),

        // نظام التحديث
        // refreshIndicatorTheme: _buildRefreshIndicatorTheme(false),

        // نظام التمرير
        // scrollBehavior: _buildScrollBehavior(),

        // نظام التحديد
        chipTheme: _buildChipTheme(false),

        // نظام البيانات
        dataTableTheme: _buildDataTableTheme(false),

        // نظام التقويم
        datePickerTheme: _buildDatePickerTheme(false),

        // نظام الوقت
        timePickerTheme: _buildTimePickerTheme(false),

        // نظام التحديد
        menuTheme: _buildMenuTheme(false),

        // نظام التحديد
        menuBarTheme: _buildMenuBarTheme(false),

        // نظام التحديد
        menuButtonTheme: _buildMenuButtonTheme(false),

        // نظام التحديد
        segmentedButtonTheme: _buildSegmentedButtonTheme(false),

        // نظام التحديد
        badgeTheme: _buildBadgeTheme(false),

        // نظام التحديد
        dividerTheme: _buildDividerTheme(false),
      );

  // ============================================
  // 2️⃣ الثيمة الداكنة (Dark Theme)
  // ============================================

  static ThemeData get dark => ThemeData(
        useMaterial3: true,

        // الألوان الأساسية
        primaryColor: DesignTokens.primaryGold,
        primaryColorLight: DesignTokens.primaryGoldLight,
        primaryColorDark: DesignTokens.primaryGoldDark,
        scaffoldBackgroundColor: DesignTokens.backgroundDarkMedium,
        canvasColor: DesignTokens.backgroundDarkMedium,

        // نظام الألوان
        colorScheme: const ColorScheme.dark(
          primary: DesignTokens.primaryGold,
          primaryContainer: DesignTokens.primaryGoldDark,
          secondary: DesignTokens.primarySapphire,
          secondaryContainer: DesignTokens.primarySapphireDark,
          tertiary: DesignTokens.primaryAmethyst,
          tertiaryContainer: DesignTokens.primaryAmethystDark,
          surface: DesignTokens.backgroundDarkMedium,
          surfaceContainerHighest: DesignTokens.backgroundDarkLight,
          error: DesignTokens.semanticError,
          errorContainer: DesignTokens.semanticErrorDark,
          onPrimary: DesignTokens.neutralWhite,
          onPrimaryContainer: DesignTokens.primaryGoldLight,
          onSecondary: DesignTokens.neutralWhite,
          onSecondaryContainer: DesignTokens.primarySapphireLight,
          onTertiary: DesignTokens.neutralWhite,
          onTertiaryContainer: DesignTokens.primaryAmethystLight,
          onSurface: DesignTokens.neutralWhite,
          onSurfaceVariant: DesignTokens.neutralGray300,
          onError: DesignTokens.neutralWhite,
          onErrorContainer: DesignTokens.semanticErrorLight,
          outline: DesignTokens.neutralGray500,
          outlineVariant: DesignTokens.neutralGray600,
          shadow: DesignTokens.neutralGray800,
          scrim: Color(0x52000000), // neutralBlack with 0.32 opacity
          inverseSurface: DesignTokens.neutralGray100,
          onInverseSurface: DesignTokens.neutralBlack,
          inversePrimary: DesignTokens.primaryGoldDark,
          surfaceTint: Color(0x0DFFD700), // primaryGold with 0.05 opacity
        ),

        // نظام الخطوط
        fontFamily: 'Cairo',
        textTheme: _buildTextTheme(true),
        primaryTextTheme: _buildTextTheme(true),

        // نظام الأزرار
        elevatedButtonTheme: _buildElevatedButtonTheme(true),
        outlinedButtonTheme: _buildOutlinedButtonTheme(true),
        textButtonTheme: _buildTextButtonTheme(true),
        filledButtonTheme: _buildFilledButtonTheme(true),

        // نظام الإدخال
        inputDecorationTheme: _buildInputDecorationTheme(true),

        // نظام البطاقات
        cardTheme: _buildCardTheme(true),

        // نظام التطبيق العلوي
        appBarTheme: _buildAppBarTheme(true),

        // نظام التنقل السفلي
        bottomNavigationBarTheme: _buildBottomNavigationBarTheme(true),

        // نظام التبويبات
        tabBarTheme: _buildTabBarTheme(true),

        // نظام مربعات الحوار
        dialogTheme: _buildDialogTheme(true),

        // نظام القوائم
        listTileTheme: _buildListTileTheme(true),

        // نظام التنبيهات
        snackBarTheme: _buildSnackBarTheme(true),

        // نظام الرموز
        iconTheme: _buildIconTheme(true),

        // نظام الظلال
        shadowColor: DesignTokens.neutralGray800,

        // نظام الانتقالات
        pageTransitionsTheme: _buildPageTransitionsTheme(),

        // نظام التمرير
        scrollbarTheme: _buildScrollbarTheme(true),

        // نظام التحديد
        textSelectionTheme: _buildTextSelectionTheme(true),

        // نظام الشرائح
        sliderTheme: _buildSliderTheme(true),

        // نظام خانات الاختيار
        checkboxTheme: _buildCheckboxTheme(true),

        // نظام أزرار الراديو
        radioTheme: _buildRadioTheme(true),

        // نظام المفاتيح
        switchTheme: _buildSwitchTheme(true),

        // نظام التقدم
        progressIndicatorTheme: _buildProgressIndicatorTheme(true),

        // نظام التوسع
        expansionTileTheme: _buildExpansionTileTheme(true),

        // نظام التلميحات
        tooltipTheme: _buildTooltipTheme(true),

        // نظام القائمة المنسدلة
        dropdownMenuTheme: _buildDropdownMenuTheme(true),

        // نظام التنبؤ
        searchBarTheme: _buildSearchBarTheme(true),
        searchViewTheme: _buildSearchViewTheme(true),

        // نظام التمدد
        floatingActionButtonTheme: _buildFloatingActionButtonTheme(true),

        // نظام التنبيهات
        bannerTheme: _buildBannerTheme(true),

        // نظام التنقل
        navigationBarTheme: _buildNavigationBarTheme(true),
        navigationDrawerTheme: _buildNavigationDrawerTheme(true),
        navigationRailTheme: _buildNavigationRailTheme(true),

        // نظام التمرير
        drawerTheme: _buildDrawerTheme(true),

        // نظام الطباعة
        cupertinoOverrideTheme: _buildCupertinoOverrideTheme(true),

        // نظام التمدد
        bottomSheetTheme: _buildBottomSheetTheme(true),

        // نظام الطبقات
        popupMenuTheme: _buildPopupMenuTheme(true),

        // نظام التحديث
        // refreshIndicatorTheme: _buildRefreshIndicatorTheme(true),

        // نظام التمرير
        // scrollBehavior: _buildScrollBehavior(),

        // نظام التحديد
        chipTheme: _buildChipTheme(true),

        // نظام البيانات
        dataTableTheme: _buildDataTableTheme(true),

        // نظام التقويم
        datePickerTheme: _buildDatePickerTheme(true),

        // نظام الوقت
        timePickerTheme: _buildTimePickerTheme(true),

        // نظام التحديد
        menuTheme: _buildMenuTheme(true),

        // نظام التحديد
        menuBarTheme: _buildMenuBarTheme(true),

        // نظام التحديد
        menuButtonTheme: _buildMenuButtonTheme(true),

        // نظام التحديد
        segmentedButtonTheme: _buildSegmentedButtonTheme(true),

        // نظام التحديد
        badgeTheme: _buildBadgeTheme(true),

        // نظام التحديد
        dividerTheme: _buildDividerTheme(true),
      );

  // ============================================
  // 3️⃣ وظائف البناء المساعدة (Helper Functions)
  // ============================================

  /// بناء نظام النصوص
  static TextTheme _buildTextTheme(bool isDark) => TextTheme(
        displayLarge: TextStyle(
          fontSize: DesignTokens.displayLarge,
          fontWeight: DesignTokens.bold,
          height: DesignTokens.tight,
          color: isDark ? DesignTokens.neutralWhite : DesignTokens.neutralBlack,
        ),
        displayMedium: TextStyle(
          fontSize: DesignTokens.displayMedium,
          fontWeight: DesignTokens.bold,
          height: DesignTokens.tight,
          color: isDark ? DesignTokens.neutralWhite : DesignTokens.neutralBlack,
        ),
        displaySmall: TextStyle(
          fontSize: DesignTokens.displaySmall,
          fontWeight: DesignTokens.bold,
          height: DesignTokens.tight,
          color: isDark ? DesignTokens.neutralWhite : DesignTokens.neutralBlack,
        ),
        headlineLarge: TextStyle(
          fontSize: DesignTokens.headlineLarge,
          fontWeight: DesignTokens.semiBold,
          height: DesignTokens.tight,
          color: isDark ? DesignTokens.neutralWhite : DesignTokens.neutralBlack,
        ),
        headlineMedium: TextStyle(
          fontSize: DesignTokens.headlineMedium,
          fontWeight: DesignTokens.semiBold,
          height: DesignTokens.tight,
          color: isDark ? DesignTokens.neutralWhite : DesignTokens.neutralBlack,
        ),
        headlineSmall: TextStyle(
          fontSize: DesignTokens.headlineSmall,
          fontWeight: DesignTokens.semiBold,
          height: DesignTokens.tight,
          color: isDark ? DesignTokens.neutralWhite : DesignTokens.neutralBlack,
        ),
        titleLarge: TextStyle(
          fontSize: DesignTokens.titleLarge,
          fontWeight: DesignTokens.medium,
          height: DesignTokens.normal,
          color: isDark ? DesignTokens.neutralWhite : DesignTokens.neutralBlack,
        ),
        titleMedium: TextStyle(
          fontSize: DesignTokens.titleMedium,
          fontWeight: DesignTokens.medium,
          height: DesignTokens.normal,
          color: isDark ? DesignTokens.neutralWhite : DesignTokens.neutralBlack,
        ),
        titleSmall: TextStyle(
          fontSize: DesignTokens.titleSmall,
          fontWeight: DesignTokens.medium,
          height: DesignTokens.normal,
          color: isDark ? DesignTokens.neutralWhite : DesignTokens.neutralBlack,
        ),
        bodyLarge: TextStyle(
          fontSize: DesignTokens.bodyLarge,
          fontWeight: DesignTokens.regular,
          height: DesignTokens.normal,
          color: isDark ? DesignTokens.neutralGray100 : DesignTokens.neutralGray900,
        ),
        bodyMedium: TextStyle(
          fontSize: DesignTokens.bodyMedium,
          fontWeight: DesignTokens.regular,
          height: DesignTokens.normal,
          color: isDark ? DesignTokens.neutralGray100 : DesignTokens.neutralGray900,
        ),
        bodySmall: TextStyle(
          fontSize: DesignTokens.bodySmall,
          fontWeight: DesignTokens.regular,
          height: DesignTokens.normal,
          color: isDark ? DesignTokens.neutralGray200 : DesignTokens.neutralGray800,
        ),
        labelLarge: TextStyle(
          fontSize: DesignTokens.labelLarge,
          fontWeight: DesignTokens.medium,
          height: DesignTokens.normal,
          color: isDark ? DesignTokens.neutralGray100 : DesignTokens.neutralGray900,
        ),
        labelMedium: TextStyle(
          fontSize: DesignTokens.labelMedium,
          fontWeight: DesignTokens.medium,
          height: DesignTokens.normal,
          color: isDark ? DesignTokens.neutralGray100 : DesignTokens.neutralGray900,
        ),
        labelSmall: TextStyle(
          fontSize: DesignTokens.labelSmall,
          fontWeight: DesignTokens.medium,
          height: DesignTokens.normal,
          color: isDark ? DesignTokens.neutralGray200 : DesignTokens.neutralGray800,
        ),
      );

  /// بناء نظام الأزرار المرتفعة
  static ElevatedButtonThemeData _buildElevatedButtonTheme(bool isDark) => ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: DesignTokens.elevation2,
          shadowColor: isDark ? DesignTokens.neutralGray800 : DesignTokens.neutralGray200,
          backgroundColor: DesignTokens.primaryGold,
          foregroundColor: DesignTokens.neutralWhite,
          disabledBackgroundColor: DesignTokens.neutralGray300,
          disabledForegroundColor: DesignTokens.neutralGray500,
          minimumSize: const Size(double.infinity, DesignTokens.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingMd,
            vertical: DesignTokens.spacingSm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: DesignTokens.labelLarge,
            fontWeight: DesignTokens.medium,
            height: DesignTokens.normal,
          ),
        ),
      );

  /// بناء نظام الأزرار المحددة
  static OutlinedButtonThemeData _buildOutlinedButtonTheme(bool isDark) => OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: DesignTokens.primaryGold,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: DesignTokens.neutralGray400,
          side: const BorderSide(
            color: DesignTokens.primaryGold,
            width: 1.5,
          ),
          minimumSize: const Size(double.infinity, DesignTokens.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingMd,
            vertical: DesignTokens.spacingSm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: DesignTokens.labelLarge,
            fontWeight: DesignTokens.medium,
            height: DesignTokens.normal,
          ),
        ),
      );

  /// بناء نظام الأزرار النصية
  static TextButtonThemeData _buildTextButtonTheme(bool isDark) => TextButtonThemeData(
        style: TextButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: DesignTokens.primaryGold,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: DesignTokens.neutralGray400,
          minimumSize: const Size(double.infinity, DesignTokens.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingMd,
            vertical: DesignTokens.spacingSm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: DesignTokens.labelLarge,
            fontWeight: DesignTokens.medium,
            height: DesignTokens.normal,
          ),
        ),
      );

  /// بناء نظام الأزرار المملوءة
  static FilledButtonThemeData _buildFilledButtonTheme(bool isDark) => FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: DesignTokens.primaryGold,
          foregroundColor: DesignTokens.neutralWhite,
          disabledBackgroundColor: DesignTokens.neutralGray300,
          disabledForegroundColor: DesignTokens.neutralGray500,
          minimumSize: const Size(double.infinity, DesignTokens.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingMd,
            vertical: DesignTokens.spacingSm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: DesignTokens.labelLarge,
            fontWeight: DesignTokens.medium,
            height: DesignTokens.normal,
          ),
        ),
      );

  /// بناء نظام الإدخال
  static InputDecorationTheme _buildInputDecorationTheme(bool isDark) => InputDecorationTheme(
        filled: true,
        fillColor: isDark ? DesignTokens.backgroundDarkMedium : DesignTokens.backgroundLightOverlay,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingMd,
          vertical: DesignTokens.spacingSm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
          borderSide: BorderSide(
            color: isDark ? DesignTokens.neutralGray600 : DesignTokens.neutralGray300,
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
          borderSide: BorderSide(
            color: isDark ? DesignTokens.neutralGray600 : DesignTokens.neutralGray300,
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
          borderSide: const BorderSide(
            color: DesignTokens.primaryGold,
            width: 2.0,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
          borderSide: const BorderSide(
            color: DesignTokens.semanticError,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
          borderSide: const BorderSide(
            color: DesignTokens.semanticError,
            width: 2.0,
          ),
        ),
        labelStyle: TextStyle(
          fontSize: DesignTokens.labelMedium,
          fontWeight: DesignTokens.medium,
          color: isDark ? DesignTokens.neutralGray300 : DesignTokens.neutralGray700,
        ),
        hintStyle: const TextStyle(
          fontSize: DesignTokens.bodyMedium,
          fontWeight: DesignTokens.regular,
          color: DesignTokens.neutralGray500,
        ),
        errorStyle: const TextStyle(
          fontSize: DesignTokens.labelSmall,
          fontWeight: DesignTokens.regular,
          color: DesignTokens.semanticError,
        ),
        prefixIconColor: isDark ? DesignTokens.neutralGray400 : DesignTokens.neutralGray600,
        suffixIconColor: isDark ? DesignTokens.neutralGray400 : DesignTokens.neutralGray600,
      );

  /// بناء نظام البطاقات
  static CardThemeData _buildCardTheme(bool isDark) => CardThemeData(
        color: isDark ? DesignTokens.backgroundDarkMedium : DesignTokens.backgroundLightSurface,
        shadowColor: isDark ? DesignTokens.neutralGray800 : DesignTokens.neutralGray200,
        elevation: DesignTokens.elevation1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusLg),
        ),
        margin: const EdgeInsets.all(DesignTokens.spacingSm),
      );

  /// بناء نظام التطبيق العلوي
  static AppBarTheme _buildAppBarTheme(bool isDark) => AppBarTheme(
        backgroundColor: isDark ? DesignTokens.backgroundDarkMedium : DesignTokens.backgroundLightSurface,
        foregroundColor: isDark ? DesignTokens.neutralWhite : DesignTokens.neutralBlack,
        elevation: DesignTokens.elevation2,
        shadowColor: isDark ? DesignTokens.neutralGray800 : DesignTokens.neutralGray200,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: DesignTokens.titleLarge,
          fontWeight: DesignTokens.semiBold,
          height: DesignTokens.tight,
          color: isDark ? DesignTokens.neutralWhite : DesignTokens.neutralBlack,
        ),
        iconTheme: IconThemeData(
          color: isDark ? DesignTokens.neutralWhite : DesignTokens.neutralBlack,
          size: DesignTokens.iconSizeMd,
        ),
        actionsIconTheme: IconThemeData(
          color: isDark ? DesignTokens.neutralWhite : DesignTokens.neutralBlack,
          size: DesignTokens.iconSizeMd,
        ),
      );

  /// بناء نظام التنقل السفلي
  static BottomNavigationBarThemeData _buildBottomNavigationBarTheme(bool isDark) => BottomNavigationBarThemeData(
        backgroundColor: isDark ? DesignTokens.backgroundDarkMedium : DesignTokens.backgroundLightSurface,
        selectedItemColor: DesignTokens.primaryGold,
        unselectedItemColor: isDark ? DesignTokens.neutralGray400 : DesignTokens.neutralGray600,
        selectedIconTheme: const IconThemeData(
          size: DesignTokens.iconSizeMd,
          color: DesignTokens.primaryGold,
        ),
        unselectedIconTheme: IconThemeData(
          size: DesignTokens.iconSizeMd,
          color: isDark ? DesignTokens.neutralGray400 : DesignTokens.neutralGray600,
        ),
        selectedLabelStyle: const TextStyle(
          fontSize: DesignTokens.labelSmall,
          fontWeight: DesignTokens.medium,
          height: DesignTokens.normal,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: DesignTokens.labelSmall,
          fontWeight: DesignTokens.regular,
          height: DesignTokens.normal,
        ),
        elevation: DesignTokens.elevation4,
        type: BottomNavigationBarType.fixed,
      );

  /// بناء نظام التبويبات
  static TabBarThemeData _buildTabBarTheme(bool isDark) => TabBarThemeData(
        labelColor: DesignTokens.primaryGold,
        unselectedLabelColor: isDark ? DesignTokens.neutralGray400 : DesignTokens.neutralGray600,
        labelStyle: const TextStyle(
          fontSize: DesignTokens.labelMedium,
          fontWeight: DesignTokens.medium,
          height: DesignTokens.normal,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: DesignTokens.labelMedium,
          fontWeight: DesignTokens.regular,
          height: DesignTokens.normal,
        ),
        indicatorColor: DesignTokens.primaryGold,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: isDark ? DesignTokens.neutralGray700 : DesignTokens.neutralGray200,
      );

  /// بناء نظام مربعات الحوار
  static DialogThemeData _buildDialogTheme(bool isDark) => DialogThemeData(
        backgroundColor: isDark ? DesignTokens.backgroundDarkMedium : DesignTokens.backgroundLightSurface,
        elevation: DesignTokens.elevation8,
        shadowColor: isDark ? DesignTokens.neutralGray800 : DesignTokens.neutralGray200,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusLg),
        ),
        titleTextStyle: TextStyle(
          fontSize: DesignTokens.headlineSmall,
          fontWeight: DesignTokens.semiBold,
          height: DesignTokens.tight,
          color: isDark ? DesignTokens.neutralWhite : DesignTokens.neutralBlack,
        ),
        contentTextStyle: TextStyle(
          fontSize: DesignTokens.bodyMedium,
          fontWeight: DesignTokens.regular,
          height: DesignTokens.normal,
          color: isDark ? DesignTokens.neutralGray100 : DesignTokens.neutralGray900,
        ),
      );

  /// بناء نظام القوائم
  static ListTileThemeData _buildListTileTheme(bool isDark) => ListTileThemeData(
        tileColor: isDark ? DesignTokens.backgroundDarkLight : DesignTokens.backgroundLightOverlay,
        selectedTileColor: DesignTokens.primaryGold.withValues(alpha: 0.1),
        textColor: isDark ? DesignTokens.neutralWhite : DesignTokens.neutralBlack,
        iconColor: isDark ? DesignTokens.neutralGray300 : DesignTokens.neutralGray700,
        selectedColor: DesignTokens.primaryGold,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingMd,
          vertical: DesignTokens.spacingSm,
        ),
        titleTextStyle: TextStyle(
          fontSize: DesignTokens.bodyLarge,
          fontWeight: DesignTokens.medium,
          height: DesignTokens.normal,
          color: isDark ? DesignTokens.neutralWhite : DesignTokens.neutralBlack,
        ),
        subtitleTextStyle: TextStyle(
          fontSize: DesignTokens.bodyMedium,
          fontWeight: DesignTokens.regular,
          height: DesignTokens.normal,
          color: isDark ? DesignTokens.neutralGray300 : DesignTokens.neutralGray700,
        ),
        leadingAndTrailingTextStyle: TextStyle(
          fontSize: DesignTokens.labelMedium,
          fontWeight: DesignTokens.medium,
          height: DesignTokens.normal,
          color: isDark ? DesignTokens.neutralGray300 : DesignTokens.neutralGray700,
        ),
      );

  /// بناء نظام التنبيهات
  static SnackBarThemeData _buildSnackBarTheme(bool isDark) => SnackBarThemeData(
        backgroundColor: isDark ? DesignTokens.backgroundDarkMedium : DesignTokens.backgroundLightSurface,
        contentTextStyle: TextStyle(
          fontSize: DesignTokens.bodyMedium,
          fontWeight: DesignTokens.regular,
          height: DesignTokens.normal,
          color: isDark ? DesignTokens.neutralWhite : DesignTokens.neutralBlack,
        ),
        actionTextColor: DesignTokens.primaryGold,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
        ),
        elevation: DesignTokens.elevation4,
        behavior: SnackBarBehavior.floating,
      );

  /// بناء نظام الرموز
  static IconThemeData _buildIconTheme(bool isDark) => IconThemeData(
        color: isDark ? DesignTokens.neutralWhite : DesignTokens.neutralBlack,
        size: DesignTokens.iconSizeMd,
      );

  /// بناء نظام الانتقالات
  static PageTransitionsTheme _buildPageTransitionsTheme() => const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        },
      );

  /// بناء نظام التمرير
  static ScrollbarThemeData _buildScrollbarTheme(bool isDark) => ScrollbarThemeData(
        thickness: WidgetStateProperty.all(6.0),
        radius: const Radius.circular(3.0),
        thumbColor: WidgetStateProperty.all(
          isDark ? DesignTokens.neutralGray600 : DesignTokens.neutralGray400,
        ),
        trackColor: WidgetStateProperty.all(
          isDark ? DesignTokens.neutralGray800 : DesignTokens.neutralGray200,
        ),
        crossAxisMargin: 2.0,
        mainAxisMargin: 2.0,
      );

  /// بناء نظام التحديد
  static TextSelectionThemeData _buildTextSelectionTheme(bool isDark) => TextSelectionThemeData(
        cursorColor: DesignTokens.primaryGold,
        selectionColor: DesignTokens.primaryGold.withValues(alpha: 0.3),
        selectionHandleColor: DesignTokens.primaryGold,
      );

  /// بناء نظام الشرائح
  static SliderThemeData _buildSliderTheme(bool isDark) => SliderThemeData(
        activeTrackColor: DesignTokens.primaryGold,
        inactiveTrackColor: isDark ? DesignTokens.neutralGray600 : DesignTokens.neutralGray300,
        thumbColor: DesignTokens.primaryGold,
        overlayColor: DesignTokens.primaryGold.withValues(alpha: 0.2),
        valueIndicatorColor: DesignTokens.primaryGold,
        valueIndicatorTextStyle: const TextStyle(
          fontSize: DesignTokens.labelSmall,
          fontWeight: DesignTokens.medium,
          color: DesignTokens.neutralWhite,
        ),
      );

  /// بناء نظام خانات الاختيار
  static CheckboxThemeData _buildCheckboxTheme(bool isDark) => CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return DesignTokens.primaryGold;
          }
          return isDark ? DesignTokens.neutralGray600 : DesignTokens.neutralGray300;
        }),
        checkColor: WidgetStateProperty.all(DesignTokens.neutralWhite),
        overlayColor: WidgetStateProperty.all(
          DesignTokens.primaryGold.withValues(alpha: 0.1),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusSm),
        ),
        side: BorderSide(
          color: isDark ? DesignTokens.neutralGray500 : DesignTokens.neutralGray400,
          width: 2.0,
        ),
      );

  /// بناء نظام أزرار الراديو
  static RadioThemeData _buildRadioTheme(bool isDark) => RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return DesignTokens.primaryGold;
          }
          return isDark ? DesignTokens.neutralGray600 : DesignTokens.neutralGray300;
        }),
        overlayColor: WidgetStateProperty.all(
          DesignTokens.primaryGold.withValues(alpha: 0.1),
        ),
      );

  /// بناء نظام المفاتيح
  static SwitchThemeData _buildSwitchTheme(bool isDark) => SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return DesignTokens.primaryGold;
          }
          return isDark ? DesignTokens.neutralGray400 : DesignTokens.neutralGray600;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return DesignTokens.primaryGold.withValues(alpha: 0.5);
          }
          return isDark ? DesignTokens.neutralGray700 : DesignTokens.neutralGray300;
        }),
        trackOutlineColor: WidgetStateProperty.all(
          isDark ? DesignTokens.neutralGray600 : DesignTokens.neutralGray400,
        ),
        overlayColor: WidgetStateProperty.all(
          DesignTokens.primaryGold.withValues(alpha: 0.1),
        ),
      );

  /// بناء نظام التقدم
  static ProgressIndicatorThemeData _buildProgressIndicatorTheme(bool isDark) => ProgressIndicatorThemeData(
        color: DesignTokens.primaryGold,
        linearTrackColor: isDark ? DesignTokens.neutralGray700 : DesignTokens.neutralGray300,
        circularTrackColor: isDark ? DesignTokens.neutralGray700 : DesignTokens.neutralGray300,
        refreshBackgroundColor: isDark ? DesignTokens.backgroundDarkMedium : DesignTokens.backgroundLightSurface,
      );

  /// بناء نظام التوسع
  static ExpansionTileThemeData _buildExpansionTileTheme(bool isDark) => ExpansionTileThemeData(
        backgroundColor: isDark ? DesignTokens.backgroundDarkLight : DesignTokens.backgroundLightOverlay,
        collapsedBackgroundColor: isDark ? DesignTokens.backgroundDarkMedium : DesignTokens.backgroundLightSurface,
        textColor: isDark ? DesignTokens.neutralWhite : DesignTokens.neutralBlack,
        collapsedTextColor: isDark ? DesignTokens.neutralGray300 : DesignTokens.neutralGray700,
        iconColor: isDark ? DesignTokens.neutralGray300 : DesignTokens.neutralGray700,
        collapsedIconColor: DesignTokens.neutralGray500,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
        ),
      );

  /// بناء نظام التلميحات
  static TooltipThemeData _buildTooltipTheme(bool isDark) => TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? DesignTokens.neutralGray800 : DesignTokens.neutralGray100,
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusSm),
          boxShadow: [
            BoxShadow(
              color: DesignTokens.neutralBlack.withValues(alpha: 0.1),
              blurRadius: 4.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        textStyle: TextStyle(
          fontSize: DesignTokens.labelSmall,
          fontWeight: DesignTokens.regular,
          color: isDark ? DesignTokens.neutralWhite : DesignTokens.neutralBlack,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingSm,
          vertical: DesignTokens.spacingXs,
        ),
        margin: const EdgeInsets.all(DesignTokens.spacingSm),
        showDuration: const Duration(milliseconds: 1500),
        waitDuration: const Duration(milliseconds: 500),
      );

  /// بناء نظام القائمة المنسدلة
  static DropdownMenuThemeData _buildDropdownMenuTheme(bool isDark) => DropdownMenuThemeData(
        textStyle: TextStyle(
          fontSize: DesignTokens.bodyMedium,
          fontWeight: DesignTokens.regular,
          color: isDark ? DesignTokens.neutralWhite : DesignTokens.neutralBlack,
        ),
        inputDecorationTheme: _buildInputDecorationTheme(isDark),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(
            isDark ? DesignTokens.backgroundDarkMedium : DesignTokens.backgroundLightSurface,
          ),
          shadowColor: WidgetStateProperty.all(
            isDark ? DesignTokens.neutralGray800 : DesignTokens.neutralGray200,
          ),
          elevation: WidgetStateProperty.all(DesignTokens.elevation4),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
            ),
          ),
        ),
      );

  /// بناء نظام التنبؤ
  static SearchBarThemeData _buildSearchBarTheme(bool isDark) => SearchBarThemeData(
        backgroundColor: WidgetStateProperty.all(
          isDark ? DesignTokens.backgroundDarkLight : DesignTokens.backgroundLightOverlay,
        ),
        elevation: WidgetStateProperty.all(DesignTokens.elevation2),
        shadowColor: WidgetStateProperty.all(
          isDark ? DesignTokens.neutralGray800 : DesignTokens.neutralGray200,
        ),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.borderRadiusLg),
          ),
        ),
        textStyle: WidgetStateProperty.all(
          TextStyle(
            fontSize: DesignTokens.bodyMedium,
            fontWeight: DesignTokens.regular,
            color: isDark ? DesignTokens.neutralWhite : DesignTokens.neutralBlack,
          ),
        ),
        hintStyle: WidgetStateProperty.all(
          const TextStyle(
            fontSize: DesignTokens.bodyMedium,
            fontWeight: DesignTokens.regular,
            color: DesignTokens.neutralGray500,
          ),
        ),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingMd,
            vertical: DesignTokens.spacingSm,
          ),
        ),
      );

  /// بناء نظام عرض التنبؤ
  static SearchViewThemeData _buildSearchViewTheme(bool isDark) => SearchViewThemeData(
        backgroundColor: isDark ? DesignTokens.backgroundDarkMedium : DesignTokens.backgroundLightSurface,
        surfaceTintColor: DesignTokens.primaryGold.withValues(alpha: 0.05),
        elevation: DesignTokens.elevation8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusLg),
        ),
        headerTextStyle: TextStyle(
          fontSize: DesignTokens.titleMedium,
          fontWeight: DesignTokens.semiBold,
          color: isDark ? DesignTokens.neutralWhite : DesignTokens.neutralBlack,
        ),
        dividerColor: isDark ? DesignTokens.neutralGray700 : DesignTokens.neutralGray200,
      );

  /// بناء نظام الزر العائم
  static FloatingActionButtonThemeData _buildFloatingActionButtonTheme(bool isDark) => FloatingActionButtonThemeData(
        backgroundColor: DesignTokens.primaryGold,
        foregroundColor: DesignTokens.neutralWhite,
        elevation: DesignTokens.elevation6,
        focusElevation: DesignTokens.elevation8,
        hoverElevation: DesignTokens.elevation10,
        disabledElevation: 0,
        highlightElevation: DesignTokens.elevation12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusLg),
        ),
        extendedTextStyle: const TextStyle(
          fontSize: DesignTokens.labelLarge,
          fontWeight: DesignTokens.medium,
          height: DesignTokens.normal,
        ),
      );

  /// بناء نظام اللافتات
  static MaterialBannerThemeData _buildBannerTheme(bool isDark) => const MaterialBannerThemeData(
        backgroundColor: DesignTokens.primaryGold,
        contentTextStyle: TextStyle(
          fontSize: DesignTokens.bodyMedium,
          fontWeight: DesignTokens.regular,
          color: DesignTokens.neutralWhite,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingMd,
          vertical: DesignTokens.spacingSm,
        ),
        leadingPadding: EdgeInsets.only(right: DesignTokens.spacingMd),
      );

  /// بناء نظام شريط التنقل
  static NavigationBarThemeData _buildNavigationBarTheme(bool isDark) => NavigationBarThemeData(
        backgroundColor: isDark ? DesignTokens.backgroundDarkMedium : DesignTokens.backgroundLightSurface,
        elevation: DesignTokens.elevation2,
        shadowColor: isDark ? DesignTokens.neutralGray800 : DesignTokens.neutralGray200,
        surfaceTintColor: DesignTokens.primaryGold.withValues(alpha: 0.05),
        indicatorColor: DesignTokens.primaryGold.withValues(alpha: 0.1),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: DesignTokens.labelSmall,
              fontWeight: DesignTokens.medium,
              height: DesignTokens.normal,
              color: DesignTokens.primaryGold,
            );
          }
          return TextStyle(
            fontSize: DesignTokens.labelSmall,
            fontWeight: DesignTokens.regular,
            height: DesignTokens.normal,
            color: isDark ? DesignTokens.neutralGray400 : DesignTokens.neutralGray600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              size: DesignTokens.iconSizeMd,
              color: DesignTokens.primaryGold,
            );
          }
          return IconThemeData(
            size: DesignTokens.iconSizeMd,
            color: isDark ? DesignTokens.neutralGray400 : DesignTokens.neutralGray600,
          );
        }),
      );

  /// بناء نظام درج التنقل
  static NavigationDrawerThemeData _buildNavigationDrawerTheme(bool isDark) => NavigationDrawerThemeData(
        backgroundColor: isDark ? DesignTokens.backgroundDarkMedium : DesignTokens.backgroundLightSurface,
        elevation: DesignTokens.elevation4,
        shadowColor: isDark ? DesignTokens.neutralGray800 : DesignTokens.neutralGray200,
        surfaceTintColor: DesignTokens.primaryGold.withValues(alpha: 0.05),
        indicatorColor: DesignTokens.primaryGold.withValues(alpha: 0.1),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: DesignTokens.bodyMedium,
              fontWeight: DesignTokens.medium,
              height: DesignTokens.normal,
              color: DesignTokens.primaryGold,
            );
          }
          return TextStyle(
            fontSize: DesignTokens.bodyMedium,
            fontWeight: DesignTokens.regular,
            height: DesignTokens.normal,
            color: isDark ? DesignTokens.neutralGray100 : DesignTokens.neutralGray900,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              size: DesignTokens.iconSizeMd,
              color: DesignTokens.primaryGold,
            );
          }
          return IconThemeData(
            size: DesignTokens.iconSizeMd,
            color: isDark ? DesignTokens.neutralGray300 : DesignTokens.neutralGray700,
          );
        }),
      );

  /// بناء نظام سكة التنقل
  static NavigationRailThemeData _buildNavigationRailTheme(bool isDark) => NavigationRailThemeData(
        backgroundColor: isDark ? DesignTokens.backgroundDarkMedium : DesignTokens.backgroundLightSurface,
        elevation: DesignTokens.elevation2,
        selectedIconTheme: const IconThemeData(
          size: DesignTokens.iconSizeMd,
          color: DesignTokens.primaryGold,
        ),
        unselectedIconTheme: IconThemeData(
          size: DesignTokens.iconSizeMd,
          color: isDark ? DesignTokens.neutralGray400 : DesignTokens.neutralGray600,
        ),
        selectedLabelTextStyle: const TextStyle(
          fontSize: DesignTokens.labelSmall,
          fontWeight: DesignTokens.medium,
          height: DesignTokens.normal,
          color: DesignTokens.primaryGold,
        ),
        unselectedLabelTextStyle: TextStyle(
          fontSize: DesignTokens.labelSmall,
          fontWeight: DesignTokens.regular,
          height: DesignTokens.normal,
          color: isDark ? DesignTokens.neutralGray400 : DesignTokens.neutralGray600,
        ),
        indicatorColor: DesignTokens.primaryGold.withValues(alpha: 0.1),
        useIndicator: true,
      );

  /// بناء نظام الدرج
  static DrawerThemeData _buildDrawerTheme(bool isDark) => DrawerThemeData(
        backgroundColor: isDark ? DesignTokens.backgroundDarkMedium : DesignTokens.backgroundLightSurface,
        elevation: DesignTokens.elevation4,
        shadowColor: isDark ? DesignTokens.neutralGray800 : DesignTokens.neutralGray200,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(DesignTokens.borderRadiusLg),
            bottomRight: Radius.circular(DesignTokens.borderRadiusLg),
          ),
        ),
        width: 304.0,
      );

  /// بناء نظام كوبرتينو
  static CupertinoThemeData _buildCupertinoOverrideTheme(bool isDark) => CupertinoThemeData(
        primaryColor: DesignTokens.primaryGold,
        brightness: isDark ? Brightness.dark : Brightness.light,
        textTheme: CupertinoTextThemeData(
          primaryColor: DesignTokens.primaryGold,
          textStyle: TextStyle(
            fontSize: DesignTokens.bodyMedium,
            fontWeight: DesignTokens.regular,
            height: DesignTokens.tight,
            color: isDark ? DesignTokens.neutralWhite : DesignTokens.neutralBlack,
          ),
          navTitleTextStyle: TextStyle(
            fontSize: DesignTokens.titleLarge,
            fontWeight: DesignTokens.semiBold,
            height: DesignTokens.tight,
            color: isDark ? DesignTokens.neutralWhite : DesignTokens.neutralBlack,
          ),
          navLargeTitleTextStyle: TextStyle(
            fontSize: DesignTokens.displaySmall,
            fontWeight: DesignTokens.bold,
            height: DesignTokens.tight,
            color: isDark ? DesignTokens.neutralWhite : DesignTokens.neutralBlack,
          ),
        ),
      );

  /// بناء نظام الورقة السفلية
  static BottomSheetThemeData _buildBottomSheetTheme(bool isDark) => BottomSheetThemeData(
        backgroundColor: isDark ? DesignTokens.backgroundDarkMedium : DesignTokens.backgroundLightSurface,
        elevation: DesignTokens.elevation8,
        shadowColor: isDark ? DesignTokens.neutralGray800 : DesignTokens.neutralGray200,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(DesignTokens.borderRadiusLg),
            topRight: Radius.circular(DesignTokens.borderRadiusLg),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: isDark ? DesignTokens.neutralGray500 : DesignTokens.neutralGray400,
        dragHandleSize: const Size(32, 4),
      );

  /// بناء نظام القائمة المنبثقة
  static PopupMenuThemeData _buildPopupMenuTheme(bool isDark) => PopupMenuThemeData(
        color: isDark ? DesignTokens.backgroundDarkMedium : DesignTokens.backgroundLightSurface,
        elevation: DesignTokens.elevation4,
        shadowColor: isDark ? DesignTokens.neutralGray800 : DesignTokens.neutralGray200,
        surfaceTintColor: DesignTokens.primaryGold.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
        ),
        textStyle: TextStyle(
          fontSize: DesignTokens.bodyMedium,
          fontWeight: DesignTokens.regular,
          height: DesignTokens.normal,
          color: isDark ? DesignTokens.neutralWhite : DesignTokens.neutralBlack,
        ),
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(
            fontSize: DesignTokens.labelMedium,
            fontWeight: DesignTokens.medium,
            height: DesignTokens.normal,
            color: isDark ? DesignTokens.neutralGray300 : DesignTokens.neutralGray700,
          ),
        ),
      );

  // RefreshIndicatorThemeData and ScrollBehavior helper methods removed to ensure compatibility with older Flutter SDK versions.
  // Their usages in ThemeData have been commented out.

  /// بناء نظام الرقائق
  static ChipThemeData _buildChipTheme(bool isDark) => ChipThemeData(
        backgroundColor: isDark ? DesignTokens.backgroundDarkLight : DesignTokens.backgroundLightOverlay,
        deleteIconColor: isDark ? DesignTokens.neutralGray300 : DesignTokens.neutralGray700,
        disabledColor: DesignTokens.neutralGray300,
        selectedColor: DesignTokens.primaryGold.withValues(alpha: 0.1),
        secondarySelectedColor: DesignTokens.primarySapphire.withValues(alpha: 0.1),
        shadowColor: isDark ? DesignTokens.neutralGray800 : DesignTokens.neutralGray200,
        surfaceTintColor: DesignTokens.primaryGold.withValues(alpha: 0.05),
        selectedShadowColor: DesignTokens.primaryGold.withValues(alpha: 0.2),
        showCheckmark: true,
        checkmarkColor: DesignTokens.primaryGold,
        labelPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingSm,
          vertical: DesignTokens.spacingXs,
        ),
        padding: const EdgeInsets.all(DesignTokens.spacingSm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusLg),
        ),
        side: BorderSide(
          color: isDark ? DesignTokens.neutralGray600 : DesignTokens.neutralGray300,
          width: 1.0,
        ),
        labelStyle: TextStyle(
          fontSize: DesignTokens.labelMedium,
          fontWeight: DesignTokens.medium,
          height: DesignTokens.normal,
          color: isDark ? DesignTokens.neutralWhite : DesignTokens.neutralBlack,
        ),
        secondaryLabelStyle: TextStyle(
          fontSize: DesignTokens.labelMedium,
          fontWeight: DesignTokens.medium,
          height: DesignTokens.normal,
          color: isDark ? DesignTokens.neutralGray100 : DesignTokens.neutralGray900,
        ),
        brightness: isDark ? Brightness.dark : Brightness.light,
        elevation: DesignTokens.elevation1,
        pressElevation: DesignTokens.elevation2,
      );

  /// بناء نظام جداول البيانات
  static DataTableThemeData _buildDataTableTheme(bool isDark) => DataTableThemeData(
        decoration: BoxDecoration(
          color: isDark ? DesignTokens.backgroundDarkLight : DesignTokens.backgroundLightSurface,
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
        ),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return DesignTokens.primaryGold.withValues(alpha: 0.1);
          }
          return Colors.transparent;
        }),
        dataRowMinHeight: 48.0,
        dataRowMaxHeight: 48.0,
        dataTextStyle: TextStyle(
          fontSize: DesignTokens.fontSizeBase,
          fontWeight: DesignTokens.regular,
          height: DesignTokens.normal,
          color: isDark ? DesignTokens.neutralWhite : DesignTokens.neutralBlack,
        ),
        headingRowColor: WidgetStateProperty.all(
          isDark ? DesignTokens.backgroundDarkLight : DesignTokens.backgroundLightOverlay,
        ),
        headingRowHeight: 56.0,
        headingTextStyle: TextStyle(
          fontSize: DesignTokens.fontSizeLg,
          fontWeight: DesignTokens.fontWeightSemiBold,
          height: DesignTokens.normal,
          color: isDark ? DesignTokens.neutralWhite : DesignTokens.neutralBlack,
        ),
        horizontalMargin: DesignTokens.spacingMd,
        columnSpacing: DesignTokens.spacingLg,
        dividerThickness: 1.0,
        checkboxHorizontalMargin: DesignTokens.spacingSm,
      );

  /// بناء نظام منتقي التواريخ
  static DatePickerThemeData _buildDatePickerTheme(bool isDark) => DatePickerThemeData(
        backgroundColor: isDark ? DesignTokens.backgroundDarkMedium : DesignTokens.backgroundLightSurface,
        elevation: DesignTokens.elevation8,
        shadowColor: isDark ? DesignTokens.neutralGray800 : DesignTokens.neutralGray200,
        surfaceTintColor: DesignTokens.primaryGold.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusLg),
        ),
        headerBackgroundColor: DesignTokens.primaryGold,
        headerForegroundColor: DesignTokens.neutralWhite,
        headerHeadlineStyle: const TextStyle(
          fontSize: DesignTokens.headlineSmall,
          fontWeight: DesignTokens.semiBold,
          height: DesignTokens.tight,
          color: DesignTokens.neutralWhite,
        ),
        headerHelpStyle: TextStyle(
          fontSize: DesignTokens.bodyMedium,
          fontWeight: DesignTokens.regular,
          height: DesignTokens.normal,
          color: DesignTokens.neutralWhite.withValues(alpha: 0.8),
        ),
        weekdayStyle: TextStyle(
          fontSize: DesignTokens.labelMedium,
          fontWeight: DesignTokens.medium,
          height: DesignTokens.normal,
          color: isDark ? DesignTokens.neutralGray300 : DesignTokens.neutralGray700,
        ),
        dayStyle: TextStyle(
          fontSize: DesignTokens.bodyMedium,
          fontWeight: DesignTokens.regular,
          height: DesignTokens.normal,
          color: isDark ? DesignTokens.neutralWhite : DesignTokens.neutralBlack,
        ),
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return DesignTokens.neutralWhite;
          }
          return isDark ? DesignTokens.neutralWhite : DesignTokens.neutralBlack;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return DesignTokens.primaryGold;
          }
          return Colors.transparent;
        }),
        dayOverlayColor: WidgetStateProperty.all(
          DesignTokens.primaryGold.withValues(alpha: 0.1),
        ),
        todayForegroundColor: WidgetStateProperty.all(DesignTokens.primaryGold),
        todayBackgroundColor: WidgetStateProperty.all(
          DesignTokens.primaryGold.withValues(alpha: 0.1),
        ),
        todayBorder: const BorderSide(
          color: DesignTokens.primaryGold,
          width: 1.0,
        ),
        yearStyle: TextStyle(
          fontSize: DesignTokens.bodyMedium,
          fontWeight: DesignTokens.regular,
          height: DesignTokens.normal,
          color: isDark ? DesignTokens.neutralWhite : DesignTokens.neutralBlack,
        ),
        yearForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return DesignTokens.neutralWhite;
          }
          return isDark ? DesignTokens.neutralWhite : DesignTokens.neutralBlack;
        }),
        yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return DesignTokens.primaryGold;
          }
          return Colors.transparent;
        }),
        yearOverlayColor: WidgetStateProperty.all(
          DesignTokens.primaryGold.withValues(alpha: 0.1),
        ),
        rangePickerBackgroundColor: isDark ? DesignTokens.backgroundDarkMedium : DesignTokens.backgroundLightSurface,
        rangePickerElevation: DesignTokens.elevation8,
        rangePickerShadowColor: isDark ? DesignTokens.neutralGray800 : DesignTokens.neutralGray200,
        rangePickerSurfaceTintColor: DesignTokens.primaryGold.withValues(alpha: 0.05),
        rangePickerShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusLg),
        ),
        rangePickerHeaderBackgroundColor: DesignTokens.primaryGold,
        rangePickerHeaderForegroundColor: DesignTokens.neutralWhite,
        rangePickerHeaderHeadlineStyle: const TextStyle(
          fontSize: DesignTokens.headlineSmall,
          fontWeight: DesignTokens.semiBold,
          height: DesignTokens.tight,
          color: DesignTokens.neutralWhite,
        ),
        rangePickerHeaderHelpStyle: TextStyle(
          fontSize: DesignTokens.fontSizeBase,
          fontWeight: DesignTokens.regular,
          height: DesignTokens.normal,
          color: DesignTokens.neutralWhite.withValues(alpha: 0.8),
        ),
        rangeSelectionBackgroundColor: DesignTokens.primaryGold.withValues(alpha: 0.1),
        rangeSelectionOverlayColor: WidgetStateProperty.all(
          DesignTokens.primaryGold.withValues(alpha: 0.2),
        ),
      );

  /// بناء نظام منتقي الأوقات
  static TimePickerThemeData _buildTimePickerTheme(bool isDark) => TimePickerThemeData(
        backgroundColor: isDark ? DesignTokens.backgroundDarkMedium : DesignTokens.backgroundLightSurface,
        elevation: DesignTokens.elevation8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusLg),
        ),
        hourMinuteShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
        ),
        hourMinuteColor: isDark ? DesignTokens.backgroundDarkLight : DesignTokens.backgroundLightOverlay,
        hourMinuteTextColor: isDark ? DesignTokens.neutralWhite : DesignTokens.neutralBlack,
        hourMinuteTextStyle: const TextStyle(
          fontSize: DesignTokens.displaySmall,
          fontWeight: DesignTokens.bold,
          height: DesignTokens.tight,
        ),
        dayPeriodShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
        ),
        dayPeriodColor: isDark ? DesignTokens.backgroundDarkLight : DesignTokens.backgroundLightOverlay,
        dayPeriodTextColor: isDark ? DesignTokens.neutralWhite : DesignTokens.neutralBlack,
        dayPeriodTextStyle: const TextStyle(
          fontSize: DesignTokens.bodyLarge,
          fontWeight: DesignTokens.medium,
          height: DesignTokens.normal,
        ),
        dialHandColor: DesignTokens.primaryGold,
        dialBackgroundColor: isDark ? DesignTokens.backgroundDarkLight : DesignTokens.backgroundLightOverlay,
        dialTextColor: isDark ? DesignTokens.neutralWhite : DesignTokens.neutralBlack,
        dialTextStyle: const TextStyle(
          fontSize: DesignTokens.bodyLarge,
          fontWeight: DesignTokens.medium,
          height: DesignTokens.normal,
        ),
        entryModeIconColor: isDark ? DesignTokens.neutralGray300 : DesignTokens.neutralGray700,
        helpTextStyle: TextStyle(
          fontSize: DesignTokens.bodyMedium,
          fontWeight: DesignTokens.regular,
          height: DesignTokens.normal,
          color: isDark ? DesignTokens.neutralGray300 : DesignTokens.neutralGray700,
        ),
      );

  /// بناء نظام القوائم
  static MenuThemeData _buildMenuTheme(bool isDark) => MenuThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(
            isDark ? DesignTokens.backgroundDarkLight : DesignTokens.backgroundLightSurface,
          ),
          shadowColor: WidgetStateProperty.all(
            isDark ? DesignTokens.neutralGray800 : DesignTokens.neutralGray200,
          ),
          elevation: WidgetStateProperty.all(DesignTokens.elevation4),
          surfaceTintColor: WidgetStateProperty.all(
            DesignTokens.primaryGold.withValues(alpha: 0.05),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
            ),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingXs,
              vertical: DesignTokens.spacingXs,
            ),
          ),
        ),
      );

  /// بناء نظام شريط القوائم
  static MenuBarThemeData _buildMenuBarTheme(bool isDark) => MenuBarThemeData(
        style: MenuStyle(
          backgroundColor: WidgetStateProperty.all(
            isDark ? DesignTokens.backgroundDarkLight : DesignTokens.backgroundLightSurface,
          ),
          shadowColor: WidgetStateProperty.all(
            isDark ? DesignTokens.neutralGray800 : DesignTokens.neutralGray200,
          ),
          elevation: WidgetStateProperty.all(DesignTokens.elevation2),
          surfaceTintColor: WidgetStateProperty.all(
            DesignTokens.primaryGold.withValues(alpha: 0.05),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
            ),
          ),
        ),
      );

  /// بناء نظام زر القوائم
  static MenuButtonThemeData _buildMenuButtonTheme(bool isDark) => MenuButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return DesignTokens.primaryGold.withValues(alpha: 0.1);
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.all(
            isDark ? DesignTokens.neutralWhite : DesignTokens.neutralBlack,
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(
              fontSize: DesignTokens.fontSizeBase,
              fontWeight: DesignTokens.regular,
              height: DesignTokens.normal,
            ),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingMd,
              vertical: DesignTokens.spacingSm,
            ),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.borderRadiusSm),
            ),
          ),
        ),
      );

  /// بناء نظام الأزرار المقسمة
  static SegmentedButtonThemeData _buildSegmentedButtonTheme(bool isDark) => SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return DesignTokens.primaryGold;
            }
            return isDark ? DesignTokens.backgroundDarkLight : DesignTokens.backgroundLightOverlay;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return DesignTokens.neutralWhite;
            }
            return isDark ? DesignTokens.neutralWhite : DesignTokens.neutralBlack;
          }),
          textStyle: WidgetStateProperty.all(
            const TextStyle(
              fontSize: DesignTokens.fontSizeSm,
              fontWeight: DesignTokens.medium,
              height: DesignTokens.normal,
            ),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(
              horizontal: DesignTokens.spacingMd,
              vertical: DesignTokens.spacingSm,
            ),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
            ),
          ),
          side: WidgetStateProperty.all(
            BorderSide(
              color: isDark ? DesignTokens.neutralGray600 : DesignTokens.neutralGray300,
              width: 1.0,
            ),
          ),
        ),
      );

  /// بناء نظام الشارات
  static BadgeThemeData _buildBadgeTheme(bool isDark) => const BadgeThemeData(
        backgroundColor: DesignTokens.primaryGold,
        textColor: DesignTokens.neutralWhite,
        smallSize: 6.0,
        largeSize: 16.0,
        textStyle: TextStyle(
          fontSize: DesignTokens.fontSizeXs,
          fontWeight: DesignTokens.medium,
          height: DesignTokens.normal,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingXs,
          vertical: DesignTokens.spacingXs,
        ),
        alignment: Alignment.topRight,
        offset: Offset(4, -4),
      );

  /// بناء نظام الفواصل
  static DividerThemeData _buildDividerTheme(bool isDark) => DividerThemeData(
        color: isDark ? DesignTokens.neutralGray700 : DesignTokens.neutralGray200,
        thickness: 1.0,
        indent: 0.0,
        endIndent: 0.0,
        space: 16.0,
      );

  // Additional static colors for compatibility
  static Color backgroundDark = DesignTokens.backgroundDarkDeep;
  static const Color accentWarm = DesignTokens.primaryGold;
  static Color primaryColor = DesignTokens.primaryGold;

  // Background wrapper widget
  static Widget background({required Widget child}) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [DesignTokens.backgroundDarkDeep, DesignTokens.backgroundDarkMedium],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: child,
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
          color: Colors.white.withValues(alpha: 0.08),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.orangeAccent, size: 22),
            const SizedBox(width: 12),
            Expanded(
                child: Text(text,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold))),
            const Icon(Icons.chevron_left, color: Colors.white30),
          ],
        ),
      ),
    );
  }

  // إضافة دوال مساعدة لضمان التوافق مع lib/app_theme.dart
  static Widget glassContainer({
    required Widget child,
    EdgeInsetsGeometry? padding,
    double opacity = 0.1,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(8),
      ),
      child: child,
    );
  }

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
          prefixIcon: Icon(icon, color: DesignTokens.primaryGold, size: 20),
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        ),
      ),
    );
  }

  // ============================================
  // 🔹 أدوات مساعدة للواجهة (UI Utilities)
  // ============================================

  /// إنشاء زر بتدرج لوني
  static Widget gradientButton({
    required String text,
    required VoidCallback? onPressed,
    double? width,
    double height = 50,
    List<Color>? colors,
    IconData? icon,
    bool isLoading = false,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors ??
              [
                DesignTokens.primaryGold,
                DesignTokens.primaryGold.withValues(alpha: 0.7),
              ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.borderRadiusLg),
        boxShadow: DesignTokens.shadowMd,
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.borderRadiusLg),
          ),
          padding: EdgeInsets.zero,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: DesignTokens.fontWeightBold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// إنشاء تدرج خلفية ملكي
  static Gradient createBackgroundGradient({bool isRoyalMode = true}) {
    if (isRoyalMode) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          DesignTokens.backgroundDarkDeep,
          DesignTokens.backgroundDarkMedium,
          DesignTokens.backgroundDarkDeep,
        ],
        stops: [0.0, 0.5, 1.0],
      );
    }
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        DesignTokens.backgroundLightSurface,
        DesignTokens.backgroundLightOverlay,
      ],
    );
  }

  /// الحصول على الحواف المناسبة للشاشة (Responsive Padding)
  static EdgeInsets getPaddingForScreen(BuildContext context) {
    if (ResponsiveBreakpoints.isPhone(context)) {
      return const EdgeInsets.all(DesignTokens.spacingMd);
    } else if (ResponsiveBreakpoints.isTablet(context)) {
      return const EdgeInsets.all(DesignTokens.spacingLg);
    } else {
      return const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingXl2,
        vertical: DesignTokens.spacingLg,
      );
    }
  }

  /// عرض رسالة نجاح
  static void showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontFamily: 'Cairo', color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: DesignTokens.primaryEmerald,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// عرض رسالة خطأ
  static void showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontFamily: 'Cairo', color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: DesignTokens.semanticError,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// عرض رسالة تنبيه/معلومات
  static void showInfoSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontFamily: 'Cairo', color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: DesignTokens.primarySapphire,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
