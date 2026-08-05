import 'package:flutter/material.dart';
import 'rooms/widgets/gift_animation_widget.dart';

class VoiceRoomGiftLogic {
  final String roomId;
  final BuildContext context;
  
  final List<Map<String, dynamic>> _giftQueue = [];
  bool _isGiftPlaying = false;

  VoiceRoomGiftLogic({required this.roomId, required this.context});

  void queueGift(Map<String, dynamic> giftData) {
    _giftQueue.add(giftData);
    _playNextGift();
  }

  void _playNextGift() {
    if (_isGiftPlaying || _giftQueue.isEmpty) return;

    _isGiftPlaying = true;
    final data = _giftQueue.removeAt(0);

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (ctx) => RoyalGiftAnimation(
        giftName: data['giftName'] ?? '',
        giftImageUrl: data['giftImageUrl'] ?? '',
        giftVideoUrl: data['giftVideoUrl'],
        senderName: data['senderName'] ?? '',
        receiverName: data['receiverName'] ?? '',
        count: data['count'] ?? 1,
        giftType: data['giftType'],
        soundUrl: data['soundUrl'],
        onComplete: () {
          if (ctx.mounted) Navigator.pop(ctx);
          _isGiftPlaying = false;
          _playNextGift();
        },
      ),
    );
  }
}
