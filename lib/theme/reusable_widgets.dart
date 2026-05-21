/// مكونات قابلة لإعادة الاستخدام (Reusable Components)
/// مطابقة لنظام التصميم الموحد
library;
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:shimmer/shimmer.dart';
import 'design_tokens.dart';
import 'responsive_breakpoints.dart';

// ============================================
// الأزرار المعاد استخدامها
// ============================================

/// زر بتدرج لوني (Gradient Button)
class RoyalButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isDisabled;
  final double height;
  final double? width;
  final double? fontSize;
  final List<Color>? gradient;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;

  const RoyalButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isDisabled = false,
    this.height = 48,
    this.width,
    this.fontSize,
    this.gradient,
    this.borderRadius,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final bool actuallyDisabled = isDisabled || isLoading || onPressed == null;
    
    final defaultGradient = gradient ??
        [
          DesignTokens.primaryGold,
          DesignTokens.primaryGold.withValues(alpha: 0.7),
        ];

    return SizedBox(
      height: height,
      width: width ?? double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: actuallyDisabled ? null : onPressed,
          borderRadius: borderRadius ??
              BorderRadius.circular(DesignTokens.borderRadiusLg),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: actuallyDisabled
                    ? [
                        DesignTokens.semanticDisabled,
                        DesignTokens.semanticDisabled
                            .withValues(alpha: 0.6),
                      ]
                    : defaultGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: borderRadius ??
                  BorderRadius.circular(DesignTokens.borderRadiusLg),
              boxShadow: actuallyDisabled ? [] : DesignTokens.shadowLg,
            ),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          DesignTokens.neutralWhite,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: DesignTokens.neutralWhite),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: TextStyle(
                            color: DesignTokens.neutralWhite,
                            fontSize: fontSize ?? DesignTokens.fontSizeBase,
                            fontWeight: DesignTokens.fontWeightSemiBold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// زر ثانوي (Secondary Button)
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final double height;
  final double? width;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color,
    this.height = 44,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = color ?? DesignTokens.primarySapphire;

    return SizedBox(
      height: height,
      width: width ?? double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: buttonColor, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DesignTokens.borderRadiusLg),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: buttonColor),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: buttonColor,
                fontSize: DesignTokens.fontSizeBase,
                fontWeight: DesignTokens.fontWeightSemiBold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// بطاقات وحاويات
// ============================================

/// بطاقة زجاجية (Glass Card)
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? shadows;
  final bool hasBorder;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.onTap,
    this.borderRadius,
    this.shadows,
    this.hasBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final br =
        borderRadius ?? BorderRadius.circular(DesignTokens.borderRadiusXl2);

    return Container(
      width: width,
      height: height,
      margin: margin ?? EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: br,
          child: ClipRRect(
            borderRadius: br,
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: padding ?? const EdgeInsets.all(DesignTokens.spacingLg),
                decoration: BoxDecoration(
                  borderRadius: br,
                  color:
                      Colors.white.withValues(alpha: DesignTokens.opacityGlass),
                  border: hasBorder
                      ? Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        )
                      : null,
                  boxShadow: shadows ?? DesignTokens.shadowMd,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// بطاقة ملكية (Royal Card)
class RoyalCard extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final List<BoxShadow>? shadows;

  const RoyalCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.all(DesignTokens.spacingMd),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius ??
              BorderRadius.circular(DesignTokens.borderRadiusXl),
          child: Container(
            padding: padding ?? const EdgeInsets.all(DesignTokens.spacingLg),
            decoration: BoxDecoration(
              color:
                  backgroundColor ?? DesignTokens.backgroundDarkMedium,
              borderRadius: borderRadius ??
                  BorderRadius.circular(DesignTokens.borderRadiusXl),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: shadows ?? DesignTokens.shadowMd,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ============================================
// النصوص والعناوين
// ============================================

/// نص العنوان الكبير (Display Text)
class DisplayText extends StatelessWidget {
  final String text;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const DisplayText(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign ?? TextAlign.center,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        fontSize: ResponsiveBreakpoints.responsiveFontSize(
            context, DesignTokens.fontSizeXl5),
        fontWeight: DesignTokens.fontWeightBold,
        color: color ?? DesignTokens.neutralWhite,
        fontFamily: DesignTokens.secondaryFont,
        letterSpacing: 1.2,
      ),
    );
  }
}

/// نص العنوان (Heading)
class HeadingText extends StatelessWidget {
  final String text;
  final Color? color;
  final TextAlign? textAlign;
  final double? fontSize;
  final double? lineHeight;
  final int? maxLines;
  final TextOverflow? overflow;
  final FontWeight? fontWeight;

  const HeadingText(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.fontSize,
    this.lineHeight,
    this.maxLines,
    this.overflow,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign ?? TextAlign.right,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        fontSize: ResponsiveBreakpoints.responsiveFontSize(
          context,
          fontSize ?? DesignTokens.fontSizeXl2,
        ),
        fontWeight: fontWeight ?? DesignTokens.fontWeightBold,
        color: color ?? DesignTokens.neutralWhite,
        fontFamily: DesignTokens.primaryFont,
      ),
    );
  }
}

/// نص الجسم (Body Text)
class BodyText extends StatelessWidget {
  final String text;
  final Color? color;
  final TextAlign? textAlign;
  final double? fontSize;
  final double? lineHeight;
  final int? maxLines;
  final TextOverflow? overflow;
  final FontWeight? fontWeight;

  const BodyText(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.fontSize,
    this.lineHeight,
    this.maxLines,
    this.overflow,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign ?? TextAlign.justify,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        fontSize: ResponsiveBreakpoints.responsiveFontSize(
          context,
          fontSize ?? DesignTokens.fontSizeBase,
        ),
        fontWeight: fontWeight ?? DesignTokens.fontWeightNormal,
        color: color ?? DesignTokens.neutralWhite.withValues(alpha: 0.8),
        fontFamily: DesignTokens.primaryFont,
        height: lineHeight ?? DesignTokens.lineHeights.relaxed,
      ),
    );
  }
}

/// نص صغير (Caption)
class CaptionText extends StatelessWidget {
  final String text;
  final Color? color;
  final TextAlign? textAlign;
  final double? fontSize;
  final int? maxLines;
  final FontWeight? fontWeight;

  const CaptionText(
    this.text, {
    super.key,
    this.color,
    this.textAlign,
    this.fontSize,
    this.maxLines,
    this.fontWeight,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign ?? TextAlign.center,
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : null,
      style: TextStyle(
        fontSize: fontSize ?? DesignTokens.fontSizeSm,
        fontWeight: fontWeight ?? DesignTokens.fontWeightNormal,
        color: color ?? DesignTokens.neutralGray400,
        fontFamily: DesignTokens.primaryFont,
      ),
    );
  }
}

// ============================================
// حقول الإدخال
// ============================================

/// حقل إدخال ملكي (Royal Input Field)
class RoyalTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final TextInputType keyboardType;
  final int? maxLines;
  final int? minLines;
  final TextAlign textAlign;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool obscureText;

  const RoyalTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.minLines,
    this.textAlign = TextAlign.right,
    this.validator,
    this.onChanged,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: minLines,
      obscureText: obscureText,
      validator: validator,
      onChanged: onChanged,
      textAlign: textAlign,
      style: const TextStyle(
        color: DesignTokens.neutralWhite,
        fontSize: DesignTokens.fontSizeBase,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: DesignTokens.neutralGray500,
        ),
        labelText: labelText,
        labelStyle: const TextStyle(
          color: DesignTokens.primaryGold,
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, color: DesignTokens.primaryGold)
            : null,
        suffixIcon: suffixIcon != null
            ? GestureDetector(
                onTap: onSuffixTap,
                child: Icon(suffixIcon, color: DesignTokens.primaryGold),
              )
            : null,
        filled: true,
        fillColor: DesignTokens.backgroundDarkMedium,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusLg),
          borderSide: BorderSide(
            color: DesignTokens.neutralWhite.withValues(alpha: 0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusLg),
          borderSide: BorderSide(
            color: DesignTokens.neutralWhite.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusLg),
          borderSide: const BorderSide(
            color: DesignTokens.primaryGold,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.all(DesignTokens.spacingLg),
      ),
    );
  }
}

// ============================================
// الفواصل والتقسيمات
// ============================================

/// فاصل ديناميكي (Dynamic Divider)
class RoyalDivider extends StatelessWidget {
  final Color? color;
  final double? thickness;
  final double? indent;
  final double? endIndent;
  final Axis direction;

  const RoyalDivider({
    super.key,
    this.color,
    this.thickness,
    this.indent,
    this.endIndent,
    this.direction = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    if (direction == Axis.horizontal) {
      return Divider(
        color: color ?? DesignTokens.neutralWhite.withValues(alpha: 0.1),
        thickness: thickness ?? 1,
        indent: indent ?? DesignTokens.spacingLg,
        endIndent: endIndent ?? DesignTokens.spacingLg,
      );
    } else {
      return VerticalDivider(
        color: color ?? DesignTokens.neutralWhite.withValues(alpha: 0.1),
        thickness: thickness ?? 1,
        indent: indent ?? DesignTokens.spacingLg,
        endIndent: endIndent ?? DesignTokens.spacingLg,
      );
    }
  }
}

// ============================================
// أيقونات العملات الملكية
// ============================================

/// أيقونة الدرهم الذهبي الملكي (الكوينز)
class RoyalCoinIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const RoyalCoinIcon({
    super.key,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/golden_dirham.png',
      width: size,
      height: size,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.stars_rounded, // Fallback to stars instead of dollar
        size: size,
        color: color ?? DesignTokens.primaryGold,
      ),
    );
  }
}

// ============================================
// مؤشرات التحميل وتأثيرات Shimmer
// ============================================

/// حاوية Shimmer أساسية
class RoyalShimmer extends StatelessWidget {
  final Widget child;
  final bool enabled;

  const RoyalShimmer({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return Shimmer.fromColors(
      baseColor: Colors.white.withValues(alpha: 0.05),
      highlightColor: Colors.white.withValues(alpha: 0.1),
      period: const Duration(milliseconds: 1500),
      child: child,
    );
  }
}

/// هيكل تحميل لقائمة (Shimmer List Skeleton)
class RoyalShimmerList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;

  const RoyalShimmerList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      padding: const EdgeInsets.all(DesignTokens.spacingMd),
      itemBuilder: (context, index) => RoyalShimmer(
        child: Container(
          margin: const EdgeInsets.only(bottom: DesignTokens.spacingMd),
          height: itemHeight,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(DesignTokens.borderRadiusLg),
          ),
        ),
      ),
    );
  }
}

/// هيكل تحميل لشبكة (Shimmer Grid Skeleton)
class RoyalShimmerGrid extends StatelessWidget {
  final int itemCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final int crossAxisCount;
  final double childAspectRatio;

  const RoyalShimmerGrid({
    super.key,
    this.itemCount = 6,
    this.crossAxisSpacing = DesignTokens.spacingMd,
    this.mainAxisSpacing = DesignTokens.spacingMd,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(DesignTokens.spacingMd),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: crossAxisSpacing,
        mainAxisSpacing: mainAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => RoyalShimmer(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(DesignTokens.borderRadiusLg),
          ),
        ),
      ),
    );
  }
}

/// مؤشر تحميل ملكي (Royal Loading Indicator)
class RoyalLoadingIndicator extends StatelessWidget {
  final Color? color;
  final double? size;
  final String? message;

  const RoyalLoadingIndicator({
    super.key,
    this.color,
    this.size,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size ?? 50,
            height: size ?? 50,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? DesignTokens.primaryGold,
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: DesignTokens.spacingMd),
            BodyText(
              message!,
              color: DesignTokens.neutralWhite.withValues(alpha: 0.7),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================
// الشرائط والعلامات
// ============================================

/// شريط تقدم ملكي (Royal Progress Bar)
class RoyalProgressBar extends StatelessWidget {
  final double value; // من 0 إلى 1
  final Color? backgroundColor;
  final Color? valueColor;
  final double? height;
  final BorderRadius? borderRadius;
  final String? label;

  const RoyalProgressBar({
    super.key,
    required this.value,
    this.backgroundColor,
    this.valueColor,
    this.height,
    this.borderRadius,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          BodyText(label!, fontSize: DesignTokens.fontSizeSm),
          const SizedBox(height: DesignTokens.spacingSm),
        ],
        ClipRRect(
          borderRadius: borderRadius ??
              BorderRadius.circular(DesignTokens.borderRadiusFull),
          child: LinearProgressIndicator(
            minHeight: height ?? 8,
            value: value.clamp(0.0, 1.0),
            backgroundColor: backgroundColor ??
                DesignTokens.backgroundDarkLight.withValues(alpha: 0.5),
            valueColor: AlwaysStoppedAnimation<Color>(
              valueColor ?? DesignTokens.primaryGold,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================
// شريط فارغ (Empty State)
// ============================================

/// حالة فارغة (Empty State Widget)
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? actionButton;
  final Color? iconColor;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionButton,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: DesignTokens.iconSizeXl3,
            color: iconColor ??
                DesignTokens.neutralWhite.withValues(alpha: 0.3),
          ),
          const SizedBox(height: DesignTokens.spacingXl),
          HeadingText(title),
          if (subtitle != null) ...[
            const SizedBox(height: DesignTokens.spacingMd),
            BodyText(
              subtitle!,
              color: DesignTokens.neutralWhite.withValues(alpha: 0.6),
            ),
          ],
          if (actionButton != null) ...[
            const SizedBox(height: DesignTokens.spacingXl),
            actionButton!,
          ],
        ],
      ),
    );
  }
}

/// حوار تأكيد ملكي (Royal Confirmation Dialog)
/// يستخدم لتأكيد العمليات الحساسة مثل الشراء أو الحذف
class RoyalConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final IconData icon;
  final Color? iconColor;
  final List<Widget>? details;

  const RoyalConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    this.confirmLabel = 'تأكيد',
    this.cancelLabel = 'تراجع',
    this.icon = Icons.help_outline,
    this.iconColor,
    this.details,
  });

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          padding: const EdgeInsets.all(DesignTokens.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  color: iconColor ?? DesignTokens.primaryGold,
                  size: 48),
              const SizedBox(height: DesignTokens.spacingMd),
              HeadingText(title, fontSize: 20),
              const SizedBox(height: DesignTokens.spacingMd),
              BodyText(message, textAlign: TextAlign.center),
              if (details != null && details!.isNotEmpty) ...[
                const SizedBox(height: DesignTokens.spacingLg),
                ...details!,
              ],
              const SizedBox(height: DesignTokens.spacingXl2),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: cancelLabel,
                      onPressed: () => Navigator.pop(context),
                      height: 42,
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacingMd),
                  Expanded(
                    child: RoyalButton(
                      label: confirmLabel,
                      onPressed: () {
                        Navigator.pop(context);
                        onConfirm();
                      },
                      height: 42,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
