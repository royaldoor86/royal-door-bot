import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';

class AnswerButton extends StatelessWidget {
  final String answer;
  final int index;
  final bool isRemoved;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final bool showingResult;
  final bool isAnswerSelected;
  final VoidCallback onTap;

  const AnswerButton({
    super.key,
    required this.answer,
    required this.index,
    required this.isRemoved,
    required this.isSelected,
    required this.isCorrect,
    required this.isWrong,
    required this.showingResult,
    required this.isAnswerSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isRemoved) {
      return const SizedBox.shrink();
    }

    Color backgroundColor;
    Color borderColor;
    Color textColor;

    if (showingResult) {
      // Show result colors (green for correct, red for wrong)
      if (isCorrect) {
        backgroundColor = AppTheme.correctGreen.withValues(alpha: 0.5);
        borderColor = AppTheme.correctGreen;
        textColor = AppTheme.textWhite;
      } else if (isWrong) {
        backgroundColor = AppTheme.wrongRed.withValues(alpha: 0.5);
        borderColor = AppTheme.wrongRed;
        textColor = AppTheme.textWhite;
      } else {
        backgroundColor = AppTheme.secondaryNavy.withValues(alpha: 0.5);
        borderColor = AppTheme.silverAccent.withValues(alpha: 0.3);
        textColor = AppTheme.textWhite;
      }
    } else if (isAnswerSelected && isSelected) {
      // Yellow selection state (user just selected)
      backgroundColor = const Color(0xFFFFD700).withValues(alpha: 0.5);
      borderColor = const Color(0xFFFFD700);
      textColor = AppTheme.textWhite;
    } else if (isCorrect) {
      backgroundColor = AppTheme.correctGreen.withValues(alpha: 0.3);
      borderColor = AppTheme.correctGreen;
      textColor = AppTheme.textWhite;
    } else if (isWrong) {
      backgroundColor = AppTheme.wrongRed.withValues(alpha: 0.3);
      borderColor = AppTheme.wrongRed;
      textColor = AppTheme.textWhite;
    } else if (isSelected) {
      backgroundColor = AppTheme.goldAccent.withValues(alpha: 0.3);
      borderColor = AppTheme.goldAccent;
      textColor = AppTheme.goldLight;
    } else {
      backgroundColor = AppTheme.secondaryNavy.withValues(alpha: 0.5);
      borderColor = AppTheme.silverAccent.withValues(alpha: 0.3);
      textColor = AppTheme.textWhite;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: borderColor.withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: borderColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index), // A, B, C, D
                  style: TextStyle(
                    color: isCorrect || isWrong || isSelected
                        ? AppTheme.textWhite
                        : AppTheme.primaryDark,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  answer,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms, delay: (index * 100).ms).slideX(),
    );
  }
}
