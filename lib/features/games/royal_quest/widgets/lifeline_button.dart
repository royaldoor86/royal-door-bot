import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class LifelineButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final int cost;
  final bool isUsed;
  final bool canAfford;
  final VoidCallback onTap;

  const LifelineButton({
    super.key,
    required this.icon,
    required this.label,
    required this.cost,
    required this.isUsed,
    required this.canAfford,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final canUse = !isUsed && canAfford;

    return GestureDetector(
      onTap: canUse ? onTap : null,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: isUsed
              ? AppTheme.secondaryNavy.withValues(alpha: 0.2)
              : canAfford
                  ? AppTheme.goldAccent.withValues(alpha: 0.2)
                  : AppTheme.secondaryNavy.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUsed
                ? AppTheme.silverAccent.withValues(alpha: 0.2)
                : canAfford
                    ? AppTheme.goldAccent
                    : AppTheme.silverAccent.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isUsed
                  ? AppTheme.silverAccent.withValues(alpha: 0.3)
                  : canAfford
                      ? AppTheme.goldAccent
                      : AppTheme.silverAccent.withValues(alpha: 0.5),
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isUsed
                    ? AppTheme.silverAccent.withValues(alpha: 0.3)
                    : canAfford
                        ? AppTheme.goldLight
                        : AppTheme.silverAccent.withValues(alpha: 0.5),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '💎$cost',
              style: TextStyle(
                color: isUsed
                    ? AppTheme.silverAccent.withValues(alpha: 0.3)
                    : canAfford
                        ? AppTheme.goldLight
                        : AppTheme.silverAccent.withValues(alpha: 0.5),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ).animate().scale(duration: 300.ms),
    );
  }
}
