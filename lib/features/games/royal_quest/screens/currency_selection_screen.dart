import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/game_state.dart';
import '../theme/app_theme.dart';
import '../services/sound_service.dart';
import 'category_selection_screen.dart';

class CurrencySelectionScreen extends StatelessWidget {
  const CurrencySelectionScreen({super.key});

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
                  padding: const EdgeInsets.all(36.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 200),
                      Text(
                        'اختر العملة',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                      ).animate().fadeIn(duration: 500.ms),
                      const SizedBox(height: 60),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 140,
                            height: 95,
                            child: _buildCurrencyCard(
                              context,
                              gameProvider,
                              CurrencyType.gems,
                              '💎',
                              'الجواهر',
                              gameProvider.state.playerBalance.gems,
                              GameState.entryFeeGems,
                              Colors.cyan,
                            ).animate().fadeIn(delay: 200.ms, duration: 600.ms),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 140,
                            height: 95,
                            child: _buildCurrencyCard(
                              context,
                              gameProvider,
                              CurrencyType.coins,
                              '🪙',
                              'الكوينز',
                              gameProvider.state.playerBalance.coins,
                              GameState.entryFeeCoins,
                              const Color(0xFFFFD700),
                            ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
                          ),
                        ],
                      ),
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

  Widget _buildCurrencyCard(
    BuildContext context,
    GameProvider gameProvider,
    CurrencyType currency,
    String icon,
    String label,
    int balance,
    int entryFee,
    Color color,
  ) {
    final canAfford = balance >= entryFee;

    return GestureDetector(
      onTap: canAfford
          ? () {
              SoundService.playCoinSound();
              gameProvider.selectCurrency(currency);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider.value(
                    value: gameProvider,
                    child: const CategorySelectionScreen(),
                  ),
                ),
              );
            }
          : null,
      child: Container(
        decoration: BoxDecoration(
          color: canAfford
              ? color.withValues(alpha: 0.8)
              : color.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                canAfford ? Colors.white : Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'رصيدك: $balance',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'التكلفة: $entryFee',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
