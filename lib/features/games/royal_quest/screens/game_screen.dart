import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
import '../services/sound_service.dart';
import '../widgets/timer_widget.dart';
import '../widgets/answer_button.dart';
import 'result_screen.dart';
import 'stage_complete_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _isNavigating = false;

  @override
  void dispose() {
    SoundService.stopAll();
    super.dispose();
  }

  void _navigateIfAllowed(BuildContext context, Widget screen) {
    if (_isNavigating) return;
    _isNavigating = true;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => screen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isNavigating) return false;
        final gameProvider = Provider.of<GameProvider>(context, listen: false);
        await gameProvider.endGameWithLoss();
        _navigateIfAllowed(
          context,
          ChangeNotifierProvider.value(
            value: gameProvider,
            child: const ResultScreen(),
          ),
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppTheme.goldLight),
            onPressed: () async {
              if (_isNavigating) return;
              final gameProvider =
                  Provider.of<GameProvider>(context, listen: false);
              await gameProvider.endGameWithLoss();
              _navigateIfAllowed(
                context,
                ChangeNotifierProvider.value(
                  value: gameProvider,
                  child: const ResultScreen(),
                ),
              );
            },
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryNavy,
                AppTheme.primaryDark,
              ],
            ),
          ),
          child: SafeArea(
            child: Consumer<GameProvider>(
              builder: (context, gameProvider, child) {
                final state = gameProvider.state;

                // Check if game is over
                if (state.status == GameStatus.gameOver ||
                    state.status == GameStatus.winner) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!_isNavigating && mounted) {
                      _navigateIfAllowed(
                        context,
                        ChangeNotifierProvider.value(
                          value:
                              Provider.of<GameProvider>(context, listen: false),
                          child: const ResultScreen(),
                        ),
                      );
                    }
                  });
                }

                // Check if stage is complete
                if (state.status == GameStatus.stageComplete) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!_isNavigating && mounted) {
                      _navigateIfAllowed(
                        context,
                        ChangeNotifierProvider.value(
                          value:
                              Provider.of<GameProvider>(context, listen: false),
                          child: const StageCompleteScreen(),
                        ),
                      );
                    }
                  });
                }

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        _buildHeader(state),
                        const SizedBox(height: 16),
                        _buildStageProgress(state),
                        const SizedBox(height: 24),
                        _buildQuestionCard(state),
                        const SizedBox(height: 32),
                        _buildTimer(gameProvider),
                        const SizedBox(height: 32),
                        _buildAnswerButtons(state, gameProvider),
                        const SizedBox(height: 32),
                        _buildLifelines(state, gameProvider),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(GameState state) {
    final currencyIcon =
        state.selectedCurrency == CurrencyType.gems ? '💎' : '🪙';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.secondaryNavy.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(
                currencyIcon,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 6),
              Text(
                '${state.currentWinnings}',
                style: const TextStyle(
                  color: AppTheme.goldLight,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Text(
          'المرحلة ${state.currentStage}',
          style: const TextStyle(
            color: AppTheme.textWhite,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '${state.currentQuestionInStage}/10',
          style: const TextStyle(
            color: AppTheme.silverAccent,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStageProgress(GameState state) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'المرحلة ${state.currentStage}',
              style: const TextStyle(
                color: AppTheme.goldLight,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'السؤال ${state.currentQuestionInStage}/${GameState.questionsPerStage}',
              style: const TextStyle(
                color: AppTheme.textWhite,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: state.currentQuestionInStage / GameState.questionsPerStage,
            backgroundColor: AppTheme.primaryDark,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppTheme.goldAccent,
            ),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(GameState state) {
    final question = state.currentQuestion;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 120),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.secondaryNavy.withValues(alpha: 0.95),
            AppTheme.secondaryNavy.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppTheme.goldAccent.withValues(alpha: 0.7), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldAccent.withValues(alpha: 0.4),
            blurRadius: 25,
            spreadRadius: 3,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: AppTheme.goldAccent.withValues(alpha: 0.2),
            blurRadius: 40,
            spreadRadius: 8,
          ),
        ],
      ),
      child: Center(
        child: Text(
          question.question,
          style: const TextStyle(
            color: AppTheme.textWhite,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            height: 1.5,
            shadows: [
              Shadow(
                color: AppTheme.goldAccent,
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          maxLines: null,
          overflow: TextOverflow.visible,
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).scale();
  }

  Widget _buildTimer(GameProvider gameProvider) {
    return TimerWidget(
      remainingTime: gameProvider.state.remainingTime,
      totalTime: GameState.questionTime,
    );
  }

  Widget _buildAnswerButtons(GameState state, GameProvider gameProvider) {
    final question = state.currentQuestion;

    // Only disable if showing result or game is not playing
    final canInteract =
        state.status == GameStatus.playing && !state.showingAnswerResult;

    return Center(
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.2,
        children: List.generate(question.answers.length, (index) {
          final canTap = canInteract &&
              !state.removedAnswers.contains(index) &&
              state.selectedAnswer == null;
          return AnswerButton(
            answer: question.answers[index],
            index: index,
            isSelected: state.selectedAnswer == index,
            isCorrect:
                state.isAnswerCorrect == true && state.selectedAnswer == index,
            isWrong:
                state.isAnswerCorrect == false && state.selectedAnswer == index,
            isRemoved: state.removedAnswers.contains(index),
            showingResult: state.showingAnswerResult,
            isAnswerSelected: state.isAnswerSelected,
            onTap: canTap
                ? () {
                    SoundService.playMicSound();
                    gameProvider.selectAnswer(index);
                  }
                : () {},
          );
        }),
      ),
    );
  }

  Widget _buildLifelines(GameState state, GameProvider gameProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSmallLifelineButton(
          Icons.remove_circle_outline,
          'حذف إجابتين',
          state.fiftyFiftyUsed,
          state.canAffordLifeline,
          () {
            SoundService.playLifelineSound();
            gameProvider.useFiftyFifty();
          },
        ),
        const SizedBox(width: 20),
        _buildSmallLifelineButton(
          Icons.refresh,
          'تغيير السؤال',
          state.changeQuestionUsed,
          state.canAffordLifeline,
          () {
            SoundService.playLifelineSound();
            gameProvider.useChangeQuestion();
          },
        ),
      ],
    );
  }

  Widget _buildSmallLifelineButton(
    IconData icon,
    String label,
    bool isUsed,
    bool canAfford,
    VoidCallback onTap,
  ) {
    final isActive = !isUsed && canAfford;

    return GestureDetector(
      onTap: isActive ? onTap : null,
      child: Container(
        width: 140,
        height: 50,
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.secondaryNavy.withValues(alpha: 0.9),
                    AppTheme.secondaryNavy.withValues(alpha: 0.7),
                  ],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.secondaryNavy.withValues(alpha: 0.3),
                    AppTheme.secondaryNavy.withValues(alpha: 0.2),
                  ],
                ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? AppTheme.goldAccent
                : AppTheme.silverAccent.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppTheme.goldAccent.withValues(alpha: 0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: AppTheme.goldAccent.withValues(alpha: 0.1),
                    blurRadius: 25,
                    spreadRadius: 4,
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isActive
                  ? AppTheme.goldAccent
                  : AppTheme.silverAccent.withValues(alpha: 0.5),
              size: 20,
              shadows: isActive
                  ? [
                      const Shadow(
                        color: AppTheme.goldAccent,
                        blurRadius: 8,
                      ),
                    ]
                  : [],
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? AppTheme.textWhite
                    : AppTheme.textWhite.withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.bold,
                shadows: isActive
                    ? [
                        const Shadow(
                          color: AppTheme.goldAccent,
                          blurRadius: 6,
                        ),
                      ]
                    : [],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
