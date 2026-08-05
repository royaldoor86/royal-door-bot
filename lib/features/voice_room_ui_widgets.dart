import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class VoiceRoomUIWidgets {
  static Widget buildModernMenuItem(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.03),
          ],
        ),
        border: Border.all(color: Colors.white10, width: 0.5),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          highlightColor: color.withValues(alpha: 0.1),
          splashColor: color.withValues(alpha: 0.2),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white24, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget buildBackground(String? dynamicBgImage) {
    final bool hasValidBg = dynamicBgImage != null &&
        dynamicBgImage.trim().isNotEmpty &&
        Uri.tryParse(dynamicBgImage)?.host.isNotEmpty == true;

    return Stack(
      children: [
        // 1. Base Layer: Gradient (Always visible as fallback)
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0F1B25), Color(0xFF051211)],
            ),
          ),
        ),
        // 2. Middle Layer: Default Room Asset
        if (!hasValidBg)
          Image.asset(
            'assets/images/room_global.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        // 3. Top Layer: Dynamic Theme Image
        if (hasValidBg)
          CachedNetworkImage(
            imageUrl: dynamicBgImage,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            fadeInDuration: const Duration(milliseconds: 700),
            placeholder: (context, url) => Container(
              color: Colors.black26,
              child: const Center(
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.amber)),
            ),
            errorWidget: (context, url, error) => Image.asset(
              'assets/images/room_global.jpg',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
      ],
    );
  }

  static Widget buildRoomNotice(String? roomNoticeText) {
    if (roomNoticeText == null || roomNoticeText.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber, width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.amber, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              roomNoticeText,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildAutoScaleText(String text, TextStyle style,
      {double maxFontSize = 16, double minFontSize = 10}) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        style: style.copyWith(fontSize: maxFontSize),
        maxLines: 1,
      ),
    );
  }
}
