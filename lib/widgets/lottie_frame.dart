import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class RoyalLottieFrame extends StatelessWidget {
  final String? lottiePath;
  final Widget child;
  final double frameSize;
  final double avatarSize;

  const RoyalLottieFrame({
    super.key,
    this.lottiePath,
    required this.child,
    this.frameSize = 120,
    this.avatarSize = 45,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: frameSize,
      height: frameSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // الصورة الشخصية للمستخدم (أو أي ويدجت آخر)
          child,
          
          // إطار اللوتي المتحرك
          if (lottiePath != null && lottiePath!.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: lottiePath!.startsWith('http') 
                  ? Lottie.network(
                      lottiePath!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    )
                  : Lottie.asset(
                      lottiePath!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
              ),
            ),
        ],
      ),
    );
  }
}
