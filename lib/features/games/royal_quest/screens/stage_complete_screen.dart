import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../providers/game_provider.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
import '../services/sound_service.dart';
import 'home_screen.dart';
import 'category_selection_screen.dart';

class StageCompleteScreen extends StatefulWidget {
  const StageCompleteScreen({super.key});

  @override
  State<StageCompleteScreen> createState() => _StageCompleteScreenState();
}

class _StageCompleteScreenState extends State<StageCompleteScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 5));

    // Start confetti and play win sound after a short delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.play();
      SoundService.playWinSound();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
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
          ),
          // Confetti overlay
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              blastDirectionality: BlastDirectionality.explosive,
              particleDrag: 0.05,
              emissionFrequency: 0.05,
              numberOfParticles: 50,
              gravity: 0.1,
              shouldLoop: false,
              colors: const [
                AppTheme.goldAccent,
                AppTheme.goldLight,
                AppTheme.silverAccent,
                Colors.red,
                Colors.blue,
                Colors.green,
              ],
            ),
          ),
          SafeArea(
            child: Consumer<GameProvider>(
              builder: (context, gameProvider, child) {
                final state = gameProvider.state;
                final currencyIcon =
                    state.selectedCurrency == CurrencyType.gems ? '💎' : '🪙';

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 16),
                        _buildSuccessIcon(),
                        const SizedBox(height: 16),
                        _buildTitle(context),
                        const SizedBox(height: 10),
                        _buildStageInfo(context, state),
                        const SizedBox(height: 16),
                        _buildWinningsCard(context, state, currencyIcon),
                        const SizedBox(height: 24),
                        _buildActionButtons(context, gameProvider),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessIcon() {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppTheme.goldAccent, AppTheme.goldLight],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.goldAccent.withValues(alpha: 0.5),
            blurRadius: 30,
            spreadRadius: 10,
          ),
        ],
      ),
      child: const Icon(
        Icons.check_circle,
        size: 80,
        color: AppTheme.primaryDark,
      ),
    ).animate().scale(duration: 800.ms, curve: Curves.elasticOut);
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      'أكملت المرحلة!',
      style: Theme.of(context).textTheme.displayLarge?.copyWith(
            color: AppTheme.goldLight,
          ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3);
  }

  Widget _buildStageInfo(BuildContext context, GameState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryNavy.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            'المرحلة ${state.currentStage - 1}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.goldLight,
                ),
          ),
          Text(
            '${state.totalQuestionsAnswered} أسئلة أجبت عليها',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.silverAccent,
                ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 600.ms);
  }

  Widget _buildWinningsCard(
      BuildContext context, GameState state, String currencyIcon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
      decoration: BoxDecoration(
        color: AppTheme.secondaryNavy.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Text(
            'أرباحك الحالية',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.silverAccent,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                currencyIcon,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Text(
                '${state.currentWinnings}',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppTheme.goldLight,
                      fontSize: 48,
                    ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 600.ms).scale();
  }

  Widget _buildActionButtons(BuildContext context, GameProvider gameProvider) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () async {
            await gameProvider.withdrawWinnings();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: Provider.of<GameProvider>(context, listen: false),
                  child: const HomeScreen(),
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(250, 60),
            backgroundColor: AppTheme.goldAccent,
            foregroundColor: AppTheme.primaryDark,
          ),
          child: const Text(
            'انسحاب بأرباحك',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ).animate().fadeIn(delay: 600.ms, duration: 600.ms).scale(),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            gameProvider.continueToNextStage();
            Navigator.pop(context);
            // Navigate back to category selection
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: Provider.of<GameProvider>(context, listen: false),
                  child: const CategorySelectionScreen(),
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(250, 60),
            backgroundColor: AppTheme.secondaryNavy,
            foregroundColor: AppTheme.textWhite,
            side: const BorderSide(color: AppTheme.goldAccent),
          ),
          child: const Text(
            'اكمل للمرحلة التالية',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ).animate().fadeIn(delay: 800.ms, duration: 600.ms).scale(),
      ],
    );
  }
}
