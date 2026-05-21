import 'dart:math';
import 'package:flutter/material.dart';
import '../models/domino_models.dart';

class DominoController extends ChangeNotifier {
  List<DominoPlayer> players = [];
  int currentPlayerIndex = 0;
  List<DominoTile> board = [];
  List<DominoTile> stock = [];
  DominoTile? selectedTile;
  bool isGameOver = false;
  DominoPlayer? winner;

  // إعداد اللعبة
  void initGame(int playerCount) {
    board.clear();
    stock.clear();
    List<DominoTile> allTiles = [];
    int id = 0;
    for (int i = 0; i <= 6; i++) {
      for (int j = i; j <= 6; j++) {
        allTiles.add(DominoTile(id: 'tile-$id', left: i, right: j, isDouble: i == j));
        id++;
      }
    }
    allTiles.shuffle();

    players = List.generate(playerCount, (index) => DominoPlayer(
      id: 'p-$index',
      username: 'Royal Player ${index + 1}',
      hand: allTiles.sublist(index * 7, (index + 1) * 7),
    ));

    stock = allTiles.sublist(playerCount * 7);

    currentPlayerIndex = 0;
    players[0].isCurrentPlayer = true;
    isGameOver = false;
    winner = null;
    selectedTile = null;
    notifyListeners();
  }

  // حركة اللاعب
  bool playMove(DominoTile tile, String side) {
    bool canPlay = false;
    if (board.isEmpty) {
      board.add(tile);
      canPlay = true;
    } else {
      if (side == 'left') {
        if (tile.right == board.first.left) {
          board.insert(0, tile);
          canPlay = true;
        } else if (tile.left == board.first.left) {
          tile.flip();
          board.insert(0, tile);
          canPlay = true;
        }
      } else {
        if (tile.left == board.last.right) {
          board.add(tile);
          canPlay = true;
        } else if (tile.right == board.last.right) {
          tile.flip();
          board.add(tile);
          canPlay = true;
        }
      }
    }

    if (canPlay) {
      players[currentPlayerIndex].hand.removeWhere((t) => t.id == tile.id);
      if (players[currentPlayerIndex].hand.isEmpty) {
        isGameOver = true;
        winner = players[currentPlayerIndex];
      } else {
        _nextTurn();
      }
      selectedTile = null;
      notifyListeners();
    }
    return canPlay;
  }

  void _nextTurn() {
    players[currentPlayerIndex].isCurrentPlayer = false;
    currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
    players[currentPlayerIndex].isCurrentPlayer = true;
  }

  void drawFromStock() {
    if (stock.isNotEmpty) {
      players[currentPlayerIndex].hand.add(stock.removeAt(0));
      notifyListeners();
    }
  }

  void selectTile(DominoTile? tile) {
    if (selectedTile?.id == tile?.id) {
      selectedTile = null;
    } else {
      selectedTile = tile;
    }
    notifyListeners();
  }

  void resetGame() {
    initGame(players.length > 0 ? players.length : 2);
  }
}
