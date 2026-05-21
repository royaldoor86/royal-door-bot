import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/design_tokens.dart';
import '../controllers/domino_controller.dart';
import '../models/domino_models.dart';
import '../widgets/domino_tile_widget.dart';

class RoyalDominoPage extends StatefulWidget {
  const RoyalDominoPage({super.key});

  @override
  State<RoyalDominoPage> createState() => _RoyalDominoPageState();
}

class _RoyalDominoPageState extends State<RoyalDominoPage> with TickerProviderStateMixin {
  final TransformationController _transformationController = TransformationController();
  int _lastTileCount = 0;

  @override
  void initState() {
    super.initState();
    // Start with a centered view
    _transformationController.value = Matrix4.identity()
      ..scale(0.7, 0.7)
      ..translate(-650.0, -600.0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DominoController>().initGame(2);
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _fitCameraToBoard(List<DominoTile> tiles) {
    if (tiles.isEmpty) return;
    
    // Calculate bounding box of all tiles
    double minX = 0, maxX = 0, minY = 0, maxY = 0;
    for (var tile in tiles) {
      if (tile.x < minX) minX = tile.x;
      if (tile.x > maxX) maxX = tile.x;
      if (tile.y < minY) minY = tile.y;
      if (tile.y > maxY) maxY = tile.y;
    }

    final Size screenSize = MediaQuery.of(context).size;
    // Add some padding around the tiles
    final double boardWidth = maxX - minX + 250; 
    final double boardHeight = maxY - minY + 250;

    // Calculate scale to fit the board in view
    double scaleX = screenSize.width / boardWidth;
    double scaleY = (screenSize.height - 350) / boardHeight; // Account for top/bottom UI
    double targetScale = (scaleX < scaleY ? scaleX : scaleY).clamp(0.4, 1.0);

    // Calculate center point
    double centerX = (minX + maxX) / 2;
    double centerY = (minY + maxY) / 2;

    final Matrix4 endMatrix = Matrix4.identity()
      ..scale(targetScale, targetScale)
      ..translate(
        -1000.0 - centerX + (screenSize.width / (2 * targetScale)),
        -1000.0 - centerY + ((screenSize.height - 180) / (2 * targetScale))
      );

    final AnimationController controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    final Animation<Matrix4> animation = Matrix4Tween(
      begin: _transformationController.value,
      end: endMatrix,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOutCubic));

    animation.addListener(() {
      _transformationController.value = animation.value;
    });

    controller.forward().then((_) => controller.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<DominoController>();

    // Update camera whenever board size changes
    if (game.board.length != _lastTileCount) {
      _lastTileCount = game.board.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitCameraToBoard(game.board);
      });
    }

    if (game.isGameOver) {
      final controller = context.read<DominoController>();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showWinOverlay(context, controller);
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          _buildTableBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(game),
                Expanded(child: _buildGameBoard(game)),
                _buildPlayerHandArea(game),
              ],
            ),
          ),
          _buildPlayerInfo(game, isTop: true),
          _buildPlayerInfo(game, isTop: false),
        ],
      ),
    );
  }

  Widget _buildTableBackground() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF1B4D3E),
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
            Color(0xFF225F4D),
            Color(0xFF13362A),
            Color(0xFF0A1F18),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(DominoController game) {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A3A).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  _buildTopIcon(Icons.card_giftcard, Colors.greenAccent),
                  const SizedBox(width: 15),
                  _buildTopStat("الجولة", "5"),
                  const SizedBox(width: 15),
                  _buildTopStat("المتبقية", "${game.stock.length}"),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: FittedBox(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  "100 نمط المضاعف",
                  style: TextStyle(color: Colors.yellowAccent, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Row(
            children: [
              _buildTopIcon(Icons.help_outline, Colors.amber),
              const SizedBox(width: 8),
              _buildTopIcon(Icons.settings, Colors.blueGrey[200]!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopIcon(IconData icon, Color color) => Icon(icon, color: color, size: 24);

  Widget _buildTopStat(String label, String value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 9)),
        Text(value, style: const TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  Widget _buildPlayerInfo(DominoController game, {required bool isTop}) {
    final player = isTop ? (game.players.length > 1 ? game.players[1] : null) : (game.players.isNotEmpty ? game.players[0] : null);
    if (player == null) return const SizedBox();

    return Positioned(
      top: isTop ? 100 : null,
      bottom: isTop ? null : 160,
      right: 20,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (player.isCurrentPlayer)
                const SizedBox(
                  width: 68,
                  height: 68,
                  child: CircularProgressIndicator(
                    value: 0.7,
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(DesignTokens.primaryGold),
                  ),
                ),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  color: Colors.white24,
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 40),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(player.username, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          Text("Points: ${player.score}", style: const TextStyle(color: DesignTokens.primaryGold, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildPlayerHandArea(DominoController game) {
    final player = game.players.isNotEmpty ? game.players[0] : null;
    if (player == null) return const SizedBox();

    return Container(
      height: 120,
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          if (!game.canCurrentPlayerMove && game.stock.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: _buildDrawButton(game),
            ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: player.hand.length,
              itemBuilder: (context, index) {
                final tile = player.hand[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: RoyalDominoTile(
                    tile: tile,
                    isSmall: false,
                    isSelected: game.selectedTile?.id == tile.id,
                    onTap: player.isCurrentPlayer ? () => game.selectTile(tile) : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawButton(DominoController game) {
    return GestureDetector(
      onTap: () => game.drawFromStock(),
      child: Container(
        width: 60,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.amber.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.amber, width: 2),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_box, color: Colors.amber, size: 30),
            Text("سحب", style: TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildGameBoard(DominoController game) {
    return InteractiveViewer(
      transformationController: _transformationController,
      constrained: false,
      boundaryMargin: const EdgeInsets.all(1500),
      minScale: 0.15,
      maxScale: 2.0,
      child: SizedBox(
        width: 2000,
        height: 2000,
        child: Stack(
          children: [
            ...game.board.map((tile) => Positioned(
                  left: 1000 + tile.x - 20,
                  top: 1000 + tile.y - 40,
                  child: RoyalDominoTile(
                    tile: tile,
                    isSmall: true,
                    rotation: tile.rotation,
                  ),
                )),
            if (game.selectedTile != null && game.board.isNotEmpty) ...[
              _buildPositionedDropZone(game, 'left'),
              _buildPositionedDropZone(game, 'right'),
            ],
            if (game.board.isEmpty && game.selectedTile != null)
              _buildPositionedDropZone(game, 'center'),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionedDropZone(DominoController game, String side) {
    double x = 0, y = 0;
    if (side == 'center') { x = 0; y = 0; }
    else if (side == 'left') { x = game.nextLeftPos.dx; y = game.nextLeftPos.dy; }
    else if (side == 'right') { x = game.nextRightPos.dx; y = game.nextRightPos.dy; }

    return Positioned(
      left: 1000 + x - 20,
      top: 1000 + y - 20,
      child: GestureDetector(
        onTap: () => game.playMove(game.selectedTile!, side == 'center' ? 'left' : side),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.4),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.3), blurRadius: 10)],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 30),
        ),
      ),
    );
  }

  void _showWinOverlay(BuildContext context, DominoController game) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      pageBuilder: (context, _, __) {
        final rewards = game.getCalculatedRewards();
        final bool isWinner = game.winner?.id == (game.players.isNotEmpty ? game.players[0].id : '');
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 100),
                Text(isWinner ? "لقد انتصرت!" : "حظاً أوفر", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Text("Gems: ${rewards['gems']} | Coins: ${rewards['coins']}", style: const TextStyle(color: Colors.amber)),
                const SizedBox(height: 30),
                ElevatedButton(onPressed: () { game.resetGame(); Navigator.pop(context); }, child: const Text("العب مرة أخرى")),
              ],
            ),
          ),
        );
      },
    );
  }
}
