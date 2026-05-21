import 'package:flutter/material.dart';
import '../models/domino_models.dart';
import 'domino_tile_widget.dart';

class DominoSnakeBoard extends StatelessWidget {
  final List<DominoTile> board;
  const DominoSnakeBoard({super.key, required this.board});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: -15, // Overlap for more natural look
          runSpacing: 20,
          children: board.map((tile) {
            return RoyalDominoTile(tile: tile, isSmall: true);
          }).toList(),
        ),
      ),
    );
  }
}
