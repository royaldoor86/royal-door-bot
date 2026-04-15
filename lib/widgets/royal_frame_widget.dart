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
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    if (frameUrl == null || frameUrl!.isEmpty) return SizedBox(width: size, height: size, child: Center(child: child));

    final String url = frameUrl!.toLowerCase();
    final bool isLottie = url.contains('.json');
    final bool isLocal = !url.startsWith('http');

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // المحتوى الداخلي (صورة المستخدم)
          child,

          // الإطار المتحرك أو الثابت
          Positioned.fill(
            child: IgnorePointer(
              child: isLottie
                  ? (isLocal
                      ? Lottie.asset(frameUrl!, fit: BoxFit.contain, errorBuilder: (c, e, s) => const SizedBox.shrink())
                      : Lottie.network(frameUrl!, fit: BoxFit.contain, errorBuilder: (c, e, s) => const SizedBox.shrink()))
                  : (isLocal
                      ? Image.asset(frameUrl!, fit: BoxFit.contain, errorBuilder: (c, e, s) => const SizedBox.shrink())
                      : CachedNetworkImage(
                          imageUrl: frameUrl!,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => const SizedBox.shrink(),
                          errorWidget: (context, url, error) => const SizedBox.shrink(),
                        )),
            ),
          ),
        ],
      ),
    );
  }
}
