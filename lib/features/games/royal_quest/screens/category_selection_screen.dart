import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/game_state.dart';
import '../models/question.dart';
import '../theme/app_theme.dart';
import '../services/sound_service.dart';
import 'game_screen.dart';
import 'currency_selection_screen.dart';
import 'result_screen.dart';

class CategorySelectionScreen extends StatelessWidget {
  const CategorySelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        constraints: const BoxConstraints.expand(),
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/quest1.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Consumer<GameProvider>(
            builder: (context, gameProvider, child) {
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Text(
                        'اختر نمط اللعبة',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: AppTheme.goldLight,
                              fontWeight: FontWeight.bold,
                            ),
                      ).animate().fadeIn(duration: 500.ms),
                      const SizedBox(height: 32),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 24,
                        crossAxisSpacing: 24,
                        childAspectRatio: 1.3,
                        children: [
                          _buildCategoryCard(
                            context,
                            gameProvider,
                            QuestionCategory.general,
                            '📚',
                            'أسئلة عامة',
                            AppTheme.goldAccent,
                          ),
                          _buildCategoryCard(
                            context,
                            gameProvider,
                            QuestionCategory.religious,
                            '🕌',
                            'أسئلة دينية',
                            AppTheme.goldAccent,
                          ),
                          _buildCategoryCard(
                            context,
                            gameProvider,
                            QuestionCategory.sports,
                            '⚽',
                            'رياضة',
                            AppTheme.goldAccent,
                          ),
                          _buildCategoryCard(
                            context,
                            gameProvider,
                            QuestionCategory.historyGeography,
                            '🌍',
                            'تاريخ وجغرافيا',
                            AppTheme.goldAccent,
                          ),
                          _buildCategoryCard(
                            context,
                            gameProvider,
                            QuestionCategory.intelligenceLogic,
                            '🧠',
                            'ذكاء ومنطق',
                            AppTheme.goldAccent,
                          ),
                          _buildCategoryCard(
                            context,
                            gameProvider,
                            QuestionCategory.civilizationsAntiquities,
                            '🏛️',
                            'حضارات وآثار',
                            AppTheme.goldAccent,
                          ),
                        ],
                      ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    GameProvider gameProvider,
    QuestionCategory category,
    String icon,
    String label,
    Color color,
  ) {
    final canPlay = gameProvider.state.canAffordEntry;

    return GestureDetector(
      onTap: canPlay
          ? () async {
              SoundService.playMicSound();
              await gameProvider.selectCategory(category);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: gameProvider,
                    child: const GameScreen(),
                  ),
                ),
              );
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: canPlay
              ? AppTheme.secondaryNavy.withValues(alpha: 0.8)
              : AppTheme.secondaryNavy.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: canPlay ? color : color.withValues(alpha: 0.3),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  canPlay ? color.withValues(alpha: 0.3) : Colors.transparent,
              blurRadius: 15,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              icon,
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: canPlay
                    ? AppTheme.textWhite
                    : AppTheme.textWhite.withValues(alpha: 0.5),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
