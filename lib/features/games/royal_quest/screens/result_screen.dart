import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import '../providers/game_provider.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 5));

    // Start confetti after a short delay
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameProvider = Provider.of<GameProvider>(context, listen: false);
      if (gameProvider.state.status == GameStatus.winner) {
        _confettiController.play();
      }
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
            child: SingleChildScrollView(
              child: Consumer<GameProvider>(
                builder: (context, gameProvider, child) {
                  final isWinner =
                      gameProvider.state.status == GameStatus.winner;
                  final winnings = gameProvider.state.currentWinnings;
                  final currencyIcon =
                      gameProvider.state.selectedCurrency == CurrencyType.gems
                          ? '💎'
                          : '🪙';

                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 16),
                        _buildResultIcon(isWinner),
                        const SizedBox(height: 16),
                        _buildResultTitle(isWinner),
                        const SizedBox(height: 10),
                        _buildPrizeDisplay(winnings, currencyIcon),
                        const SizedBox(height: 24),
                        _buildActionButtons(context, gameProvider),
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultIcon(bool isWinner) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: isWinner
              ? [AppTheme.goldAccent, AppTheme.goldLight]
              : [AppTheme.silverAccent, AppTheme.primaryNavy],
        ),
        boxShadow: [
          BoxShadow(
            color: (isWinner ? AppTheme.goldAccent : AppTheme.silverAccent)
                .withValues(alpha: 0.5),
            blurRadius: 30,
            spreadRadius: 10,
          ),
        ],
      ),
      child: Icon(
        isWinner ? Icons.emoji_events : Icons.sentiment_dissatisfied,
        size: 80,
        color: AppTheme.primaryDark,
      ),
    ).animate().scale(duration: 800.ms, curve: Curves.elasticOut);
  }

  Widget _buildResultTitle(bool isWinner) {
    return Text(
      isWinner ? 'مبروك! لقد فزت' : 'انتهت اللعبة',
      style: Theme.of(context).textTheme.displayLarge?.copyWith(
            color: isWinner ? AppTheme.goldLight : AppTheme.textWhite,
          ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.3);
  }

  Widget _buildPrizeDisplay(int winnings, String currencyIcon) {
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
            'المجموع',
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
                '$winnings',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      color: AppTheme.goldLight,
                      fontSize: 48,
                    ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 600.ms).scale();
  }

  Widget _buildActionButtons(BuildContext context, GameProvider gameProvider) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () {
            gameProvider.resetGame();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: gameProvider,
                  child: const HomeScreen(),
                ),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(200, 60),
            backgroundColor: AppTheme.goldAccent,
            foregroundColor: AppTheme.primaryDark,
          ),
          child: const Text(
            'العودة للقائمة',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            gameProvider.resetGame();
            Navigator.popUntil(context, (route) => route.isFirst);
          },
          child: const Text(
            'العب مرة أخرى',
            style: TextStyle(
              color: AppTheme.goldLight,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
      ],
    );
  }
}
