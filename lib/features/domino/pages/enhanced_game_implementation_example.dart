import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/enhanced_game_animations.dart';
import '../widgets/enhanced_game_ui.dart';
import '../widgets/particle_effects.dart';
import '../widgets/domino_tile_widget.dart';
import '../controllers/domino_controller.dart';
import '../services/enhanced_sound_service.dart';
import '../constants/premium_design_system.dart';

/// Example of Implementing Enhanced Domino Game UI
/// This widget demonstrates how to use all the new premium components
class EnhancedDominoGameExample extends StatefulWidget {
  const EnhancedDominoGameExample({super.key});

  @override
  State<EnhancedDominoGameExample> createState() =>
      _EnhancedDominoGameExampleState();
}

class _EnhancedDominoGameExampleState extends State<EnhancedDominoGameExample>
    with TickerProviderStateMixin {
  late AnimationController _timerController;

  @override
  void initState() {
    super.initState();
    // Initialize background music
    EnhancedGameMusicService.startBackgroundMusic(volume: 0.3);

    // Initialize timer animation
    _timerController = AnimationController(
      duration: const Duration(seconds: 15),
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DominoController>().initGame(2);
    });
  }

  @override
  void dispose() {
    _timerController.dispose();
    EnhancedGameMusicService.stopBackgroundMusic();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<DominoController>();

    return Scaffold(
      body: EnhancedGameTableBackground(
        opacity: 1.0,
        child: SafeArea(
          child: Stack(
            children: [
              // Main Game Content
              Column(
                children: [
                  // Top Bar with Enhanced UI
                  _buildTopBar(game),

                  // Game Board Area
                  Expanded(
                    child: _buildGameBoard(game),
                  ),

                  // Player Hand Area
                  _buildPlayerHandArea(game),
                ],
              ),

              // Player Info with Premium Styling
              _buildPlayerInfoCards(game),

              // Particle Effects Layer (conditionally shown)
              if (game.isGameOver) _buildWinParticles(game),
            ],
          ),
        ),
      ),
    );
  }

  /// Top Bar with Settings and Game Info
  Widget _buildTopBar(DominoController game) {
    return Padding(
      padding: const EdgeInsets.all(PremiumSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Settings and Help Buttons
          Row(
            children: [
              EnhancedRoundButton(
                icon: Icons.settings,
                color: PremiumColorPalette.goldAccent,
                onTap: () {
                  EnhancedDominoSoundService.playTileHover();
                  // Open settings
                },
              ),
              const SizedBox(width: PremiumSpacing.md),
              EnhancedRoundButton(
                icon: Icons.help_outline,
                color: PremiumColorPalette.sapphireAccent,
                onTap: () {
                  EnhancedDominoSoundService.playTileHover();
                  // Open help
                },
              ),
            ],
          ),

          // Game Info Cards
          const Row(
            children: [
              EnhancedGameInfoCard(
                icon: Icons.layers,
                label: 'المستوى',
                value: '14',
                primaryColor: PremiumColorPalette.sapphireAccent,
                isReverse: true,
              ),
              SizedBox(width: PremiumSpacing.sm),
              EnhancedGameInfoCard(
                icon: Icons.emoji_events,
                label: 'البطولة',
                value: 'الدوري',
                primaryColor: PremiumColorPalette.goldAccent,
                isReverse: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Main Game Board Display
  Widget _buildGameBoard(DominoController game) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Board tiles with animations
          if (game.board.isNotEmpty)
            EnhancedDominoAnimations.placementAnimation(
              _buildBoardTiles(game),
            ),

          // Center Multiplier/Status Indicator
          if (game.players[game.currentPlayerIndex].isCurrentPlayer)
            EnhancedTimerRing(
              value: _timerController.value,
              totalDuration: const Duration(seconds: 15),
              color: PremiumColorPalette.goldAccent,
            ),
        ],
      ),
    );
  }

  /// Build board tiles layout
  Widget _buildBoardTiles(DominoController game) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: game.board.map((tile) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: RoyalDominoTile(
              tile: tile,
              isSelected: false,
              rotation: tile.rotation.toDouble(),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Player Hand Area
  Widget _buildPlayerHandArea(DominoController game) {
    final currentPlayer = game.players[game.currentPlayerIndex];

    return Container(
      margin: const EdgeInsets.all(PremiumSpacing.md),
      padding: const EdgeInsets.all(PremiumSpacing.md),
      decoration: PremiumCardDecoration.standard,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Player name and score
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currentPlayer.username,
                style: PremiumTypography.heading3,
              ),
              Text(
                'النقاط: ${currentPlayer.score}',
                style: PremiumTypography.scoreValue,
              ),
            ],
          ),
          const SizedBox(height: PremiumSpacing.md),

          // Hand tiles
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: currentPlayer.hand.map((tile) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: GestureDetector(
                    onTap: () {
                      EnhancedDominoSoundService.playTilePlaced();
                      // Handle play move
                    },
                    child: RoyalDominoTile(
                      tile: tile,
                      isSmall: true,
                      isSelected: game.selectedTile?.id == tile.id,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Player Info Cards (Top and Bottom)
  Widget _buildPlayerInfoCards(DominoController game) {
    final opponents = game.players.where((p) => !p.isCurrentPlayer).toList();

    return Stack(
      children: [
        // Top opponent
        if (opponents.isNotEmpty)
          Positioned(
            top: PremiumSpacing.lg,
            right: PremiumSpacing.lg,
            child: _buildPlayerCard(opponents[0], isTop: true),
          ),

        // Bottom player (self)
        if (game.players.isNotEmpty)
          Positioned(
            bottom: PremiumSpacing.lg,
            right: PremiumSpacing.lg,
            child: _buildPlayerCard(game.players[0], isTop: false),
          ),
      ],
    );
  }

  /// Individual Player Card with Pulsing Effect
  Widget _buildPlayerCard(dynamic player, {required bool isTop}) {
    return PulsingGlow(
      glowColor: player.isCurrentPlayer
          ? PremiumColorPalette.goldAccent
          : Colors.white,
      child: Container(
        width: 100,
        height: 100,
        decoration: PremiumCardDecoration.elevated,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: PremiumColorPalette.sapphireAccent,
              child: Text(
                player.username[0],
                style: PremiumTypography.heading2.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: PremiumSpacing.sm),
            Text(
              '${player.hand.length} بطاقات',
              style: PremiumTypography.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  /// Win Celebration with Particles
  Widget _buildWinParticles(DominoController game) {
    final centerX = MediaQuery.of(context).size.width / 2;
    final centerY = MediaQuery.of(context).size.height / 2;

    return Positioned.fill(
      child: Stack(
        children: [
          // Celebration particles
          ParticleEffectsSystem.celebrationParticles(
            centerPosition: Offset(centerX, centerY),
            duration: const Duration(seconds: 2),
            color: PremiumColorPalette.goldAccent,
          ),

          // Victory text
          Center(
            child: FloatingTextEffect(
              text: '🎉 فزت! 🎉',
              startPosition: Offset(centerX - 50, centerY),
              duration: const Duration(seconds: 3),
              style: PremiumTypography.victoryText,
            ),
          ),
        ],
      ),
    );
  }
}

/// Integration Tips:
/// 1. Replace your current domino_game_page.dart with this enhanced version
/// 2. Make sure all imports are correct
/// 3. Ensure audio files exist in assets/sounds/ and assets/music/
/// 4. Test on different screen sizes
/// 5. Performance test on lower-end devices

// Example usage in main app:
/*
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ChangeNotifierProvider(
        create: (_) => DominoController(),
        child: const EnhancedDominoGameExample(),
      ),
    );
  }
}
*/
