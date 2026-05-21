import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/domino_controller.dart';
import '../widgets/domino_tile_widget.dart';

class RoyalDominoPage extends StatefulWidget {
  const RoyalDominoPage({super.key});

  @override
  State<RoyalDominoPage> createState() => _RoyalDominoPageState();
}

class _RoyalDominoPageState extends State<RoyalDominoPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DominoController>().initGame(2);
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<DominoController>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [Color(0xFF004D40), Color(0xFF00241B), Colors.black],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(game),
              Expanded(
                child: _buildGameBoard(game),
              ),
              _buildPlayerArea(game),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(DominoController game) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.between,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFD4AF37)),
          ),
          const Text(
            "ROYAL DOMINO",
            style: TextStyle(
              color: Color(0xFFD4AF37),
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              fontFamily: 'Serif',
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD4AF37), width: 0.5),
            ),
            child: Row(
              children: [
                const Icon(Icons.layers, color: Colors.amber, size: 16),
                const SizedBox(width: 5),
                Text(
                  "${game.stock.length}",
                  style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGameBoard(DominoController game) {
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 50),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (game.selectedTile != null && game.board.isNotEmpty)
              _buildDropZone(game, 'left'),
            ...game.board.map((tile) => Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: RotatedBox(
                    quarterTurns: tile.isDouble ? 0 : 1,
                    child: RoyalDominoTile(tile: tile, isSmall: true),
                  ),
                )),
            if (game.selectedTile != null && game.board.isNotEmpty)
              _buildDropZone(game, 'right'),
            if (game.board.isEmpty && game.selectedTile != null)
              _buildDropZone(game, 'center'),
          ],
        ),
      ),
    );
  }

  Widget _buildDropZone(DominoController game, String side) {
    return GestureDetector(
      onTap: () {
        bool success = game.playMove(game.selectedTile!, side == 'center' ? 'left' : side);
        if (!success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Invalid Move!"), duration: Duration(seconds: 1)),
          );
        }
      },
      child: Container(
        width: 60,
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.amber.withOpacity(0.5), width: 2),
          boxShadow: [
            BoxShadow(color: Colors.amber.withOpacity(0.2), blurRadius: 10, spreadRadius: 2),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.amber, size: 30),
      ),
    );
  }

  Widget _buildPlayerArea(DominoController game) {
    final player = game.players.isNotEmpty ? game.players[0] : null;
    if (player == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: const Color(0xFFD4AF37).withOpacity(0.3), width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  player.isCurrentPlayer ? "YOUR TURN" : "WAITING...",
                  style: TextStyle(
                    color: player.isCurrentPlayer ? Colors.amber : Colors.white54,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  "Tiles: ${player.hand.length}",
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: player.hand.length,
              itemBuilder: (context, index) {
                final tile = player.hand[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: RoyalDominoTile(
                    tile: tile,
                    isSelected: game.selectedTile?.id == tile.id,
                    onTap: player.isCurrentPlayer ? () => game.selectTile(tile) : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                label: "DRAW",
                icon: Icons.refresh,
                onPressed: game.stock.isNotEmpty && player.isCurrentPlayer
                    ? () => game.drawFromStock()
                    : null,
              ),
              _buildActionButton(
                label: "RESET",
                icon: Icons.restore,
                onPressed: () => _showResetDialog(game),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Opacity(
        opacity: onPressed == null ? 0.4 : 1.0,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD4AF37)),
                gradient: const LinearGradient(
                  colors: [Color(0xFFD4AF37), Color(0xFFB8860B)],
                ),
              ],
              child: Icon(icon, color: Colors.black, size: 20),
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetDialog(DominoController game) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text("Reset Game?", style: TextStyle(color: Color(0xFFD4AF37))),
        content: const Text("Are you sure you want to start over?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              game.resetGame();
              Navigator.pop(context);
            },
            child: const Text("RESET", style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }
}
