import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:cached_network_image/cached_network_image.dart';

class RoyalFrameWidget extends StatelessWidget {
  final String? frameUrl;
  final Widget child;
  final double size;

  const RoyalFrameWidget({
    super.key,
    this.frameUrl,
    required this.child,
    this.size = 180,
  });

  @override
  Widget build(BuildContext context) {
    if (frameUrl == null || frameUrl!.isEmpty) {
      return SizedBox(width: size, height: size, child: Center(child: child));
    }

    final String url = frameUrl!.toLowerCase();
    final bool isLottie = url.contains('.json');
    final bool isLocal = !url.startsWith('http');
    final bool isValidRemote =
        !isLocal && Uri.tryParse(frameUrl!)?.host.isNotEmpty == true;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none, // يسمح للإطار بالبروز الضخم خارج حدود الصورة
        alignment: Alignment.center,
        children: [
          // الطبقة الأولى: الصورة الشخصية ( Avatar )
          // جعلناها بحجم كبير (50% من المساحة) لكي لا تبدو مصغرة
          SizedBox(
            width: size * 0.50,
            height: size * 0.50,
            child: ClipOval(child: child),
          ),

          // الطبقة الثانية: الإطار الملكي الاحترافي
          Positioned.fill(
            child: OverflowBox(
              // تحديد قيم دنيا صفرية لتجنّب "non-normalized" constraints
              minWidth: 0,
              minHeight: 0,
              // تم تصحيح النسبة من 512% إلى 110% لتناسب حجم الصورة ومنع انهيار الذاكرة
              maxWidth: size * 1.10,
              maxHeight: size * 1.10,
              child: SizedBox(
                width: size * 1.10,
                height: size * 1.10,
                child: IgnorePointer(
                  child: isLottie
                      ? (isLocal
                          ? Lottie.asset(frameUrl!,
                              fit: BoxFit.contain,
                              animate: false,
                              repeat: false)
                          : (isValidRemote
                              ? Lottie.network(frameUrl!,
                                  fit: BoxFit.contain,
                                  animate: false,
                                  repeat: false)
                              : const SizedBox.shrink()))
                      : (isLocal
                          ? Image.asset(frameUrl!, fit: BoxFit.contain)
                          : (isValidRemote
                              ? CachedNetworkImage(
                                  imageUrl: frameUrl!,
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) =>
                                      const SizedBox.shrink(),
                                  errorWidget: (context, url, error) =>
                                      const SizedBox.shrink(),
                                )
                              : const SizedBox.shrink())),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
