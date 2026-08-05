import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class TimerWidget extends StatelessWidget {
  final int remainingTime;
  final int totalTime;

  const TimerWidget({
    super.key,
    required this.remainingTime,
    required this.totalTime,
  });

  @override
  Widget build(BuildContext context) {
    final progress = remainingTime / totalTime;
    
    // Calculate color based on remaining time
    Color timerColor;
    if (progress > 0.6) {
      timerColor = const Color(0xFF4CAF50); // Green
    } else if (progress > 0.3) {
      timerColor = const Color(0xFFFFC107); // Yellow
    } else {
      timerColor = const Color(0xFFF44336); // Red
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.secondaryNavy.withValues(alpha: 0.4),
            AppTheme.secondaryNavy.withValues(alpha: 0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: timerColor,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: timerColor.withValues(alpha: 0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                Icons.access_time,
                color: timerColor,
                size: 24,
                shadows: [
                  Shadow(
                    color: timerColor,
                    blurRadius: 8,
                  ),
                ],
              ),
              Text(
                '$remainingTime ثانية',
                style: TextStyle(
                  color: timerColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: timerColor,
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppTheme.primaryDark,
              valueColor: AlwaysStoppedAnimation<Color>(timerColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
