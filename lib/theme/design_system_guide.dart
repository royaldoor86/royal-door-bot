// ============================================
// 📚 دليل استخدام نظام التصميم الموحد
// Royal Design System Usage Guide
// ============================================

/*
هذا الملف يوضح كيفية استخدام نظام التصميم الموحد في جميع أنحاء التطبيق.

## 1️⃣ استخدام الرموز التصميمية (Design Tokens)
======================================

import 'theme/design_tokens.dart';

// الألوان
Color goldColor = DesignTokens.primaryColors.gold;
Color emeraldColor = DesignTokens.primaryColors.emerald;
Color backgroundColor = DesignTokens.backgroundColors.darkDeep;

// الفقرات والخطوط
double fontSize = DesignTokens.fontSizes.lg;
FontWeight fontWeight = DesignTokens.fontWeights.bold;
double lineHeight = DesignTokens.lineHeights.relaxed;

// المسافات
double spacing = DesignTokens.spacing.lg;
double padding = DesignTokens.spacing.xl2;

// الزوايا المستديرة
double borderRadius = DesignTokens.borderRadii.lg;

// الظلال
List<BoxShadow> shadows = DesignTokens.shadows.md;

// الأيقونات
double iconSize = DesignTokens.iconSizes.lg;

// المدد والانحناءات
Duration duration = DesignTokens.durations.base;
Curve curve = DesignTokens.curves.easeInOut;

---

## 2️⃣ استخدام نظام الاستجابة (Responsive System)
======================================

import 'theme/responsive_breakpoints.dart';

// التحقق من حجم الشاشة
if (ResponsiveBreakpoints.isPhone(context)) {
  // واجهة الهاتف
}

if (ResponsiveBreakpoints.isTablet(context)) {
  // واجهة الجهاز اللوحي
}

if (ResponsiveBreakpoints.isDesktop(context)) {
  // واجهة سطح المكتب
}

// الحصول على الأبعاد الديناميكية
double screenWidth = ResponsiveBreakpoints.getScreenWidth(context);
double screenHeight = ResponsiveBreakpoints.getScreenHeight(context);
double responsiveWidth = ResponsiveBreakpoints.responsiveWidth(context, 80);
double responsiveHeight = ResponsiveBreakpoints.responsiveHeight(context, 50);

// حجم خط ديناميكي
double fontSize = ResponsiveBreakpoints.responsiveFontSize(context, 24);

// حجم أيقونة ديناميكي
double iconSize = ResponsiveBreakpoints.responsiveIconSize(context, 32);

// مسافة ديناميكية
double spacing = ResponsiveBreakpoints.responsiveSpacing(context, 16);

// معلومات الشبكة
int columns = ResponsiveBreakpoints.getGridColumns(context);
double itemSize = ResponsiveBreakpoints.getGridItemSize(context);

---

## 3️⃣ استخدام المكونات القابلة لإعادة الاستخدام (Reusable Widgets)
======================================

import 'theme/reusable_widgets.dart';

// الأزرار
RoyalButton(
  label: 'اضغط هنا',
  onPressed: () {},
  icon: Icons.arrow_forward,
  height: 48,
  width: double.infinity,
)

SecondaryButton(
  label: 'إلغاء',
  onPressed: () {},
  icon: Icons.close,
)

// البطاقات
GlassCard(
  child: Text('محتوى البطاقة الزجاجية'),
  padding: EdgeInsets.all(16),
  onTap: () {},
)

RoyalCard(
  child: Text('محتوى البطاقة الملكية'),
  backgroundColor: DesignTokens.backgroundColors.darkMedium,
)

// النصوص
DisplayText('عنوان كبير جداً'),

HeadingText('عنوان متوسط'),

BodyText('نص عادي مع محاذاة صحيحة وارتفاع سطر مناسب'),

CaptionText('نص صغير جداً للملاحظات'),

// حقول الإدخال
RoyalTextField(
  hintText: 'أدخل اسمك',
  labelText: 'الاسم',
  prefixIcon: Icons.person,
  keyboardType: TextInputType.text,
)

// الفواصل
RoyalDivider(
  color: Colors.white.withValues(alpha: 0.2),
  thickness: 1,
)

// مؤشرات التحميل
RoyalLoadingIndicator(
  message: 'جاري التحميل...',
  color: DesignTokens.primaryColors.gold,
)

// شرائط التقدم
RoyalProgressBar(
  value: 0.7,
  label: 'التقدم: 70%',
  valueColor: DesignTokens.primaryColors.gold,
)

// حالات فارغة
EmptyStateWidget(
  icon: Icons.inbox,
  title: 'لا توجد بيانات',
  subtitle: 'حاول لاحقاً',
  iconColor: DesignTokens.neutralColors.white.withValues(alpha: 0.3),
)

---

## 4️⃣ استخدام نظام التصميم الموحد (Design System)
======================================

import 'theme/design_system.dart';

// إنشاء موضوع التطبيق
ThemeData theme = RoyalDesignSystem.createTheme(
  isDarkMode: true,
  isRoyalMode: false,
);

// إنشاء تدرج لوني
LinearGradient gradient = RoyalDesignSystem.createBackgroundGradient(
  isDarkMode: true,
  isRoyalMode: false,
);

// أنماط النصوص
TextStyle headline = RoyalDesignSystem.getHeadlineStyle(
  size: 24,
  weight: FontWeight.bold,
);

TextStyle body = RoyalDesignSystem.getBodyStyle(
  size: 16,
  weight: FontWeight.normal,
);

TextStyle caption = RoyalDesignSystem.getCaptionStyle(
  size: 12,
);

// المسافات الديناميكية
EdgeInsets padding = RoyalDesignSystem.getPaddingForScreen(context);
EdgeInsets margin = RoyalDesignSystem.getMarginForScreen(context);

// الديكوريشن
BoxDecoration glassDecoration = RoyalDesignSystem.createGlassDecoration();
BoxDecoration cardDecoration = RoyalDesignSystem.createCardDecoration();

// عرض الرسائل
RoyalDesignSystem.showErrorSnackbar(context, 'حدث خطأ');
RoyalDesignSystem.showSuccessSnackbar(context, 'تم بنجاح');
RoyalDesignSystem.showInfoSnackbar(context, 'معلومة');

---

## 5️⃣ مثال عملي شامل (Complete Example)
======================================

import 'package:flutter/material.dart';
import 'theme/design_tokens.dart';
import 'theme/responsive_breakpoints.dart';
import 'theme/reusable_widgets.dart';
import 'theme/design_system.dart';

class ExamplePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.backgroundColors.darkDeep,
      appBar: AppBar(
        title: HeadingText('صفحة مثال'),
        backgroundColor: DesignTokens.backgroundColors.darkDeep,
      ),
      body: ResponsiveBuilder(
        phone: _buildPhoneLayout(context),
        tablet: _buildTabletLayout(context),
        desktop: _buildDesktopLayout(context),
      ),
    );
  }

  Widget _buildPhoneLayout(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          GlassCard(
            child: BodyText('محتوى على الهاتف'),
            margin: EdgeInsets.all(DesignTokens.spacing.lg),
          ),
          RoyalButton(
            label: 'اضغط هنا',
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            child: BodyText('الجزء الأول'),
          ),
        ),
        Expanded(
          child: GlassCard(
            child: BodyText('الجزء الثاني'),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return GridView.count(
      crossAxisCount: ResponsiveBreakpoints.getGridColumns(context),
      children: List.generate(
        6,
        (index) => GlassCard(
          child: BodyText('بطاقة $index'),
        ),
      ),
    );
  }
}

---

## 6️⃣ تطبيق نظام التصميم على صفحة المكافآت
======================================

// rewards_page.dart
import 'theme/design_tokens.dart';
import 'theme/responsive_breakpoints.dart';
import 'theme/reusable_widgets.dart';

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: DesignTokens.backgroundColors.darkDeep,
    body: Container(
      decoration: BoxDecoration(
        gradient: RoyalDesignSystem.createBackgroundGradient(),
      ),
      child: SingleChildScrollView(
        padding: RoyalDesignSystem.getPaddingForScreen(context),
        child: Column(
          children: [
            DisplayText('سوق المكافآت الملكي'),
            SizedBox(height: DesignTokens.spacing.xl),
            GridView.count(
              crossAxisCount: ResponsiveBreakpoints.getGridColumns(context),
              mainAxisSpacing: DesignTokens.spacing.lg,
              crossAxisSpacing: DesignTokens.spacing.lg,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              children: rewards.map((reward) {
                return GlassCard(
                  child: Column(
                    children: [
                      HeadingText(reward.name),
                      SizedBox(height: DesignTokens.spacing.md),
                      BodyText(reward.description),
                      SizedBox(height: DesignTokens.spacing.lg),
                      RoyalButton(
                        label: 'شراء الآن',
                        onPressed: () => buyReward(reward),
                        height: 40,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    ),
  );
}

---

## 7️⃣ قائمة التحقق (Checklist)
======================================

✅ استخدام DesignTokens لجميع الألوان والفوافل
✅ استخدام ResponsiveBreakpoints للتكيف مع الشاشات
✅ استخدام المكونات المعاد استخدامها بدلاً من بناء عناصر جديدة
✅ توحيد هوامش ومسافات جميع الصفحات
✅ تطبيق الظلال والتأثيرات بشكل متسق
✅ اختبار جميع الصفحات على أحجام شاشات مختلفة
✅ استخدام ResponsiveBuilder للعرض الشرطي
✅ تطبيق Dark Mode بشكل صحيح
✅ التأكد من سهولة القراءة على جميع الأجهزة
✅ توثيق أي تخصيصات غير قياسية

---

## 8️⃣ أفضل الممارسات (Best Practices)
======================================

❌ تجنب:
- استخدام ألوان مباشرة (Color(0xFF...))
- تحديد هوامش ومسافات يدوية
- بناء مكونات معقدة دون إعادة استخدام
- تحديد أحجام الخطوط بشكل عشوائي
- عدم اختبار الاستجابة

✅ افعل:
- استخدم DesignTokens.colors دائماً
- استخدم ResponsiveBreakpoints.getResponsiveSpacing()
- استخدم المكونات المعاد استخدامها
- استخدم ResponsiveBreakpoints.responsiveFontSize()
- اختبر على أحجام شاشات متعددة

*/
