import 'package:flutter/material.dart';
import 'royal_xo_game.dart';
import 'royal_xo_provider.dart';
import '../royal_quest/theme/app_theme.dart';

class RoyalXoInviteDialog extends StatelessWidget {
  final Map<String, dynamic> data;
  final String notificationId;

  const RoyalXoInviteDialog({
    super.key,
    required this.data,
    required this.notificationId,
  });

  static void show(BuildContext context, Map<String, dynamic> data, String notificationId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => RoyalXoInviteDialog(data: data, notificationId: notificationId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roomId = data['roomId'] as String?;
    final currency = data['currency'] as String? ?? 'gems';
    final entryCost = (data['entryCost'] as num? ?? 25).toInt();
    final rewardAmount = (data['rewardAmount'] as num? ?? 37).toInt();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.primaryNavy,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppTheme.goldAccent, width: 2),
          boxShadow: [
            BoxShadow(color: AppTheme.goldAccent.withValues(alpha: 0.4), blurRadius: 30),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videogame_asset, color: AppTheme.goldAccent, size: 60),
            const SizedBox(height: 20),
            const Text(
              'دعوة مبارزة ملكية ⚔️',
              style: TextStyle(color: AppTheme.goldLight, fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'صديقك يتحداك في مباراة XO بقيمة $entryCost ${currency == 'gems' ? 'جوهرة' : 'كوينز'}',
              style: const TextStyle(color: Colors.white70, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      if (roomId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RoyalXoGame(
                              mode: GameMode.online,
                              currency: currency,
                              entryCost: entryCost,
                              rewardAmount: rewardAmount,
                              joinRoomId: roomId,
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text('قبول التحدي', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.silverAccent,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: const Text('لاحقاً'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
