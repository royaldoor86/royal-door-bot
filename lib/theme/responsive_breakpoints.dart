/// نظام الاستجابة والتكيف (Responsive Breakpoints)
/// تحسين العرض على جميع أحجام الشاشات
library;

import 'package:flutter/material.dart';

class ResponsiveBreakpoints {
  // ============================================
  // تعريف نقاط الفصل (Breakpoints)
  // ============================================

  /// النقاط المعيارية بالبكسل
  static const double extraSmallMax = 320; // أجهزة قديمة جداً
  static const double smallMax = 480; // هواتف صغيرة (iPhone SE)
  static const double mediumMax = 768; // أجهزة لوحية صغيرة، هواتف كبيرة
  static const double largeMax = 1024; // أجهزة لوحية قياسية
  static const double extraLargeMax = 1440; // شاشات كبيرة
  static const double ultraLargeMax = 2560; // شاشات فائقة (4K)

  // ============================================
  // دوال التحقق من حجم الشاشة
  // ============================================

  /// التحقق من أن الشاشة صغيرة جداً
  static bool isExtraSmall(BuildContext context) {
    return MediaQuery.sizeOf(context).width <= extraSmallMax;
  }

  /// التحقق من أن الشاشة صغيرة
  static bool isSmall(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width > extraSmallMax && width <= smallMax;
  }

  /// التحقق من أن الشاشة متوسطة
  static bool isMedium(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width > smallMax && width <= mediumMax;
  }

  /// التحقق من أن الشاشة كبيرة
  static bool isLarge(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width > mediumMax && width <= largeMax;
  }

  /// التحقق من أن الشاشة كبيرة جداً
  static bool isExtraLarge(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width > largeMax && width <= extraLargeMax;
  }

  /// التحقق من أن الشاشة فائقة
  static bool isUltraLarge(BuildContext context) {
    return MediaQuery.sizeOf(context).width > extraLargeMax;
  }

  /// التحقق من أن الجهاز هاتف (عرض < 768)
  static bool isPhone(BuildContext context) {
    return MediaQuery.sizeOf(context).width < mediumMax;
  }

  /// التحقق من أن الجهاز جهاز لوحي (عرض >= 768)
  static bool isTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= mediumMax &&
        MediaQuery.sizeOf(context).width < extraLargeMax;
  }

  /// التحقق من أن الجهاز سطح مكتب (عرض >= 1024)
  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= largeMax;
  }

  /// التحقق من أن الاتجاه أفقي
  static bool isLandscape(BuildContext context) {
    return MediaQuery.orientationOf(context) == Orientation.landscape;
  }

  /// التحقق من أن الاتجاه عمودي
  static bool isPortrait(BuildContext context) {
    return MediaQuery.orientationOf(context) == Orientation.portrait;
  }

  // ============================================
  // دوال الحصول على الأبعاد الديناميكية
  // ============================================

  /// الحصول على عرض الشاشة
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.sizeOf(context).width;
  }

  /// الحصول على ارتفاع الشاشة
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.sizeOf(context).height;
  }

  /// الحصول على padding آمن (Safe Area)
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return EdgeInsets.only(
      top: mediaQuery.padding.top,
      bottom: mediaQuery.padding.bottom,
      left: mediaQuery.padding.left,
      right: mediaQuery.padding.right,
    );
  }

  /// الحصول على ارتفاع شريط النظام العلوي
  static double getStatusBarHeight(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }

  /// الحصول على ارتفاع شريط التنقل السفلي
  static double getBottomNavBarHeight(BuildContext context) {
    return MediaQuery.of(context).padding.bottom;
  }

  // ============================================
  // نسب الأبعاد الديناميكية
  // ============================================

  /// الحصول على عرض ديناميكي (نسبة من عرض الشاشة)
  static double responsiveWidth(BuildContext context, double percentage) {
    return MediaQuery.sizeOf(context).width * (percentage / 100);
  }

  /// الحصول على ارتفاع ديناميكي (نسبة من ارتفاع الشاشة)
  static double responsiveHeight(BuildContext context, double percentage) {
    return MediaQuery.sizeOf(context).height * (percentage / 100);
  }

  /// الحصول على حجم خط ديناميكي
  static double responsiveFontSize(BuildContext context, double baseSize) {
    if (isExtraSmall(context)) {
      return baseSize * 0.75;
    } else if (isSmall(context)) {
      return baseSize * 0.85;
    } else if (isMedium(context)) {
      return baseSize * 0.95;
    } else if (isLarge(context)) {
      return baseSize;
    } else if (isExtraLarge(context)) {
      return baseSize * 1.1;
    } else {
      return baseSize * 1.2;
    }
  }

  /// الحصول على حجم أيقونة ديناميكي
  static double responsiveIconSize(BuildContext context, double baseSize) {
    if (isExtraSmall(context)) {
      return baseSize * 0.8;
    } else if (isSmall(context)) {
      return baseSize * 0.9;
    } else {
      return baseSize;
    }
  }

  /// الحصول على مسافة ديناميكية
  static double responsiveSpacing(BuildContext context, double baseSpacing) {
    if (isExtraSmall(context)) {
      return baseSpacing * 0.75;
    } else if (isSmall(context)) {
      return baseSpacing * 0.85;
    } else {
      return baseSpacing;
    }
  }

  // ============================================
  // تخطيط الشبكة (Grid Layout)
  // ============================================

  /// الحصول على عدد الأعمدة حسب حجم الشاشة
  static int getGridColumns(BuildContext context) {
    if (isPhone(context)) {
      return 2; // هاتف: عمودين
    } else if (isTablet(context)) {
      return 3; // جهاز لوحي: 3 أعمدة
    } else {
      return 4; // سطح مكتب: 4 أعمدة
    }
  }

  /// الحصول على حجم عنصر الشبكة
  static double getGridItemSize(BuildContext context) {
    final width = getScreenWidth(context);
    final columns = getGridColumns(context);
    const padding = 16.0;

    return (width - (padding * 2)) / columns - (padding / 2);
  }

  // ============================================
  // تخطيط الأعمدة (Column Layout)
  // ============================================

  /// الحصول على عرض الحاوية الرئيسية
  static double getContainerWidth(BuildContext context) {
    final width = getScreenWidth(context);

    if (isPhone(context)) {
      return width - 32; // هاتف: 16px padding على الجانبين
    } else if (isTablet(context)) {
      return width - 48; // جهاز لوحي: 24px padding
    } else if (isLarge(context)) {
      return 1200; // سطح مكتب: عرض أقصى
    } else {
      return 1400;
    }
  }

  // ============================================
  // حالات الاستخدام الشائعة
  // ============================================

  /// هل يجب عرض القائمة الجانبية؟
  static bool shouldShowSidebar(BuildContext context) {
    return isDesktop(context);
  }

  /// هل يجب عرض شريط التنقل السفلي؟
  static bool shouldShowBottomNav(BuildContext context) {
    return isPhone(context);
  }

  /// هل يجب عرض شريط التنقل العلوي المخفي؟
  static bool shouldHideAppBar(BuildContext context) {
    return isSmall(context);
  }

  /// الحصول على عدد العناصر في الصف الواحد
  static int getItemsPerRow(BuildContext context, {int mobileCount = 1}) {
    if (isPhone(context)) {
      return mobileCount;
    } else if (isTablet(context)) {
      return 2;
    } else {
      return 3;
    }
  }
}

/// Widget مساعد للقيام بإجراءات استجابية
class ResponsiveBuilder extends StatelessWidget {
  final WidgetBuilder phone;
  final WidgetBuilder? tablet;
  final WidgetBuilder? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.phone,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (ResponsiveBreakpoints.isDesktop(context)) {
      return desktop != null ? desktop!(context) : tablet!(context);
    } else if (ResponsiveBreakpoints.isTablet(context)) {
      return tablet != null ? tablet!(context) : phone(context);
    } else {
      return phone(context);
    }
  }
}

/// Widget للعرض الشرطي حسب حجم الشاشة
class VisibleOn extends StatelessWidget {
  final Widget child;
  final bool Function(BuildContext) condition;

  const VisibleOn({
    super.key,
    required this.child,
    required this.condition,
  });

  @override
  Widget build(BuildContext context) {
    return condition(context) ? child : const SizedBox.shrink();
  }
}

/// Widget للإخفاء الشرطي حسب حجم الشاشة
class HiddenOn extends StatelessWidget {
  final Widget child;
  final bool Function(BuildContext) condition;

  const HiddenOn({
    super.key,
    required this.child,
    required this.condition,
  });

  @override
  Widget build(BuildContext context) {
    return !condition(context) ? child : const SizedBox.shrink();
  }
}
