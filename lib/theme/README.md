# 🎨 نظام التصميم الموحد (Royal Design System)

## 📋 نظرة عامة

نظام تصميم شامل وموحد لتطبيق Royal Door يضمن الاتساقية والاستجابة على جميع الأجهزة.

---

## 📁 بنية الملفات

```
lib/
├── theme/
│   ├── design_tokens.dart          # 🎯 الرموز التصميمية (الألوان، الخطوط، المسافات)
│   ├── responsive_breakpoints.dart # 📱 نقاط الفصل والاستجابة
│   ├── reusable_widgets.dart       # 🧩 المكونات القابلة لإعادة الاستخدام
│   ├── design_system.dart          # 🎨 نظام التصميم الموحد
│   ├── design_system_guide.dart    # 📚 دليل الاستخدام
│   └── README.md                   # 📖 هذا الملف
└── app_theme.dart                  # 🔄 الموضوع الرئيسي (محدث)
```

---

## 🎯 المكونات الرئيسية

### 1. رموز التصميم (Design Tokens)
**الملف**: `design_tokens.dart`

توفر جميع الثوابت البصرية في مكان واحد:

#### الألوان (Colors)
```dart
DesignTokens.primaryColors.gold          // ذهب ملكي
DesignTokens.primaryColors.emerald       // زمردي
DesignTokens.primaryColors.sapphire      // ياقوت أزرق
DesignTokens.backgroundColors.darkDeep   // خلفية داكنة
DesignTokens.semanticColors.success      // لون النجاح (أخضر)
DesignTokens.semanticColors.error        // لون الخطأ (أحمر)
```

#### أحجام الخطوط (Font Sizes)
```dart
DesignTokens.fontSizes.xs    // 12
DesignTokens.fontSizes.sm    // 14
DesignTokens.fontSizes.base  // 16
DesignTokens.fontSizes.lg    // 18
DesignTokens.fontSizes.xl    // 20
// ... إلخ
```

#### المسافات (Spacing)
```dart
DesignTokens.spacing.xs   // 4
DesignTokens.spacing.sm   // 8
DesignTokens.spacing.md   // 12
DesignTokens.spacing.lg   // 16
DesignTokens.spacing.xl   // 20
// ... إلخ
```

#### الزوايا المستديرة (Border Radius)
```dart
DesignTokens.borderRadii.sm   // 6
DesignTokens.borderRadii.md   // 8
DesignTokens.borderRadii.lg   // 12
DesignTokens.borderRadii.xl   // 16
DesignTokens.borderRadii.xl2  // 20
```

#### الظلال (Shadows)
```dart
DesignTokens.shadows.xs     // ظل صغير جداً
DesignTokens.shadows.sm     // ظل صغير
DesignTokens.shadows.md     // ظل متوسط
DesignTokens.shadows.lg     // ظل كبير
DesignTokens.shadows.glow   // توهج ذهبي
```

---

### 2. نقاط الفصل والاستجابة (Responsive Breakpoints)
**الملف**: `responsive_breakpoints.dart`

#### نقاط الفصل:
- **الهاتف الصغير جداً**: عرض ≤ 320px
- **الهاتف الصغير**: 320px < عرض ≤ 480px
- **الهاتف العادي**: 480px < عرض ≤ 768px
- **الجهاز اللوحي**: 768px < عرض ≤ 1024px
- **سطح المكتب**: 1024px < عرض ≤ 1440px

#### الدوال الرئيسية:
```dart
// التحقق من حجم الشاشة
ResponsiveBreakpoints.isPhone(context)      // هاتف؟
ResponsiveBreakpoints.isTablet(context)     // جهاز لوحي؟
ResponsiveBreakpoints.isDesktop(context)    // سطح مكتب؟

// الأبعاد الديناميكية
ResponsiveBreakpoints.getScreenWidth(context)
ResponsiveBreakpoints.getScreenHeight(context)
ResponsiveBreakpoints.responsiveWidth(context, 80)    // 80% من العرض
ResponsiveBreakpoints.responsiveHeight(context, 50)   // 50% من الارتفاع

// حجم الخط الديناميكي
ResponsiveBreakpoints.responsiveFontSize(context, 24)

// حجم الأيقونة الديناميكي
ResponsiveBreakpoints.responsiveIconSize(context, 32)

// المسافة الديناميكية
ResponsiveBreakpoints.responsiveSpacing(context, 16)
```

#### الأدوات المساعدة:
```dart
// عرض مختلف حسب حجم الشاشة
ResponsiveBuilder(
  phone: _buildPhone(context),
  tablet: _buildTablet(context),
  desktop: _buildDesktop(context),
)

// إظهار شرطي
VisibleOn(
  child: Text('يظهر على الهواتف فقط'),
  condition: (context) => ResponsiveBreakpoints.isPhone(context),
)

// إخفاء شرطي
HiddenOn(
  child: Text('مخفي على الهواتف'),
  condition: (context) => ResponsiveBreakpoints.isPhone(context),
)
```

---

### 3. المكونات القابلة لإعادة الاستخدام (Reusable Widgets)
**الملف**: `reusable_widgets.dart`

#### الأزرار:
```dart
// زر بتدرج لوني
RoyalButton(
  label: 'اضغط هنا',
  onPressed: () {},
  icon: Icons.arrow_forward,
  height: 48,
  isLoading: false,
  isDisabled: false,
)

// زر ثانوي
SecondaryButton(
  label: 'إلغاء',
  onPressed: () {},
  icon: Icons.close,
)
```

#### البطاقات:
```dart
// بطاقة زجاجية (Glass Card)
GlassCard(
  child: Text('محتوى'),
  padding: EdgeInsets.all(16),
  onTap: () {},
)

// بطاقة ملكية (Royal Card)
RoyalCard(
  child: Text('محتوى'),
  backgroundColor: DesignTokens.backgroundColors.darkMedium,
)
```

#### النصوص:
```dart
// نص عنوان كبير جداً
DisplayText('عنوان كبير')

// نص عنوان
HeadingText('عنوان متوسط')

// نص الجسم
BodyText('نص عادي')

// نص صغير
CaptionText('نص صغير')
```

#### حقول الإدخال:
```dart
RoyalTextField(
  hintText: 'أدخل اسمك',
  labelText: 'الاسم',
  prefixIcon: Icons.person,
  keyboardType: TextInputType.text,
  validator: (value) {
    if (value?.isEmpty ?? true) {
      return 'الحقل مطلوب';
    }
    return null;
  },
)
```

#### أدوات أخرى:
```dart
// الفاصل
RoyalDivider()

// مؤشر التحميل
RoyalLoadingIndicator(message: 'جاري التحميل...')

// شريط التقدم
RoyalProgressBar(value: 0.7, label: 'التقدم: 70%')

// حالة فارغة
EmptyStateWidget(
  icon: Icons.inbox,
  title: 'لا توجد بيانات',
  subtitle: 'حاول لاحقاً',
)
```

---

### 4. نظام التصميم الموحد (Design System)
**الملف**: `design_system.dart`

#### إنشاء الموضوع:
```dart
ThemeData theme = RoyalDesignSystem.createTheme(
  isDarkMode: true,
  isRoyalMode: false,
);
```

#### إنشاء التدرج اللوني:
```dart
LinearGradient gradient = RoyalDesignSystem.createBackgroundGradient(
  isDarkMode: true,
  isRoyalMode: false,
);
```

#### أنماط النصوص:
```dart
TextStyle headline = RoyalDesignSystem.getHeadlineStyle();
TextStyle body = RoyalDesignSystem.getBodyStyle();
TextStyle caption = RoyalDesignSystem.getCaptionStyle();
```

#### عرض الرسائل:
```dart
RoyalDesignSystem.showErrorSnackbar(context, 'حدث خطأ');
RoyalDesignSystem.showSuccessSnackbar(context, 'تم بنجاح');
RoyalDesignSystem.showInfoSnackbar(context, 'معلومة');
```

---

## 🚀 أمثلة عملية

### مثال 1: صفحة بسيطة
```dart
class SimplePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.backgroundColors.darkDeep,
      body: Container(
        decoration: BoxDecoration(
          gradient: RoyalDesignSystem.createBackgroundGradient(),
        ),
        child: Center(
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DisplayText('مرحباً'),
                SizedBox(height: DesignTokens.spacing.lg),
                BodyText('نص عادي'),
                SizedBox(height: DesignTokens.spacing.xl),
                RoyalButton(
                  label: 'اضغط هنا',
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

### مثال 2: صفحة استجابية
```dart
class ResponsivePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          // عمود واحد
        ],
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildContent()),
        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildSidebar()),
        Expanded(
          flex: 3,
          child: _buildContent(),
        ),
      ],
    );
  }
}
```

### مثال 3: شبكة ديناميكية
```dart
Widget _buildGrid(BuildContext context) {
  return GridView.count(
    crossAxisCount: ResponsiveBreakpoints.getGridColumns(context),
    mainAxisSpacing: DesignTokens.spacing.lg,
    crossAxisSpacing: DesignTokens.spacing.lg,
    children: items.map((item) {
      return GlassCard(
        child: Column(
          children: [
            HeadingText(item.name),
            SizedBox(height: DesignTokens.spacing.md),
            BodyText(item.description),
          ],
        ),
      );
    }).toList(),
  );
}
```

---

## 📱 اختبار الاستجابة

### أحجام الشاشات للاختبار:
- **320px** - iPhone SE
- **375px** - iPhone 12
- **414px** - iPhone 12 Pro Max
- **768px** - iPad Mini
- **1024px** - iPad Pro
- **1440px** - سطح مكتب عادي
- **2560px** - شاشات 4K

### الاختبار في Flutter:
```bash
flutter run -d chrome --web-renderer=canvaskit
flutter run -d chrome --web-renderer=html
```

---

## ✅ قائمة التحقق قبل الإطلاق

- [ ] جميع الصفحات تستخدم `DesignTokens`
- [ ] جميع الصفحات تستخدم `ResponsiveBreakpoints`
- [ ] جميع المكونات القابلة لإعادة الاستخدام تُستخدم
- [ ] تم اختبار جميع الصفحات على 3 أحجام شاشات على الأقل
- [ ] المسافات والهوامش موحدة
- [ ] الألوان موحدة
- [ ] الخطوط موحدة
- [ ] الظلال موحدة
- [ ] الأيقونات حجمها مناسب
- [ ] النصوص قابلة للقراءة على جميع الأجهزة

---

## 🐛 استكشاف الأخطاء

### النص صغير جداً على الهاتف:
```dart
// ❌ خطأ
Text('نص', style: TextStyle(fontSize: 12))

// ✅ صحيح
BodyText('نص', fontSize: DesignTokens.fontSizes.base)
```

### الهوامش غير متسقة:
```dart
// ❌ خطأ
Padding(padding: EdgeInsets.all(15))
Padding(padding: EdgeInsets.all(20))

// ✅ صحيح
Padding(padding: EdgeInsets.all(DesignTokens.spacing.lg))
Padding(padding: EdgeInsets.all(DesignTokens.spacing.xl))
```

### الألوان غير موحدة:
```dart
// ❌ خطأ
Container(color: Color(0xFFFFD700))
Container(color: Color(0xFFFDD835))

// ✅ صحيح
Container(color: DesignTokens.primaryColors.gold)
Container(color: DesignTokens.primaryColors.gold)
```

---

## 📞 الدعم والمساعدة

لأي استفسارات أو مشاكل في استخدام نظام التصميم، راجع:
1. `design_system_guide.dart` - دليل الاستخدام المفصل
2. `reusable_widgets.dart` - أمثلة المكونات
3. `design_tokens.dart` - قائمة جميع الرموز

---

**آخر تحديث**: 21 أبريل 2026  
**الإصدار**: 1.0.0  
**الحالة**: ✅ نشط وجاهز للاستخدام
