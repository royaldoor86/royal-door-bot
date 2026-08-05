import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class AudiencePollDialog extends StatelessWidget {
  final Map<int, int> pollResults;

  const AudiencePollDialog({
    super.key,
    required this.pollResults,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.secondaryNavy,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.goldAccent, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.poll,
              color: AppTheme.goldAccent,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'استطلاع رأي الجمهور',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.goldLight,
                  ),
            ),
            const SizedBox(height: 24),
            ...List.generate(4, (index) {
              final percentage = pollResults[index] ?? 0;
              final letter = String.fromCharCode(65 + index);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'الإجابة $letter',
                          style: const TextStyle(
                            color: AppTheme.textWhite,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$percentage%',
                          style: const TextStyle(
                            color: AppTheme.goldLight,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: AppTheme.primaryDark,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppTheme.goldAccent,
                        ),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: (index * 100).ms, duration: 300.ms);
            }),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldAccent,
                foregroundColor: AppTheme.primaryDark,
              ),
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    ).animate().scale(duration: 300.ms);
  }
}
