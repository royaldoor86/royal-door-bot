import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/domino_models.dart';
import '../services/domino_sound_service.dart';

class DominoController extends ChangeNotifier {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance.ref();
  
  List<DominoPlayer> players = [];
  int currentPlayerIndex = 0;
  List<DominoTile> board = [];
  List<DominoTile> stock = [];
  DominoTile? selectedTile;
  bool isGameOver = false;
  DominoPlayer? winner;
  
  DominoTile? lastPlacedTile;
  Offset nextLeftPos = Offset.zero;
  Offset nextRightPos = Offset.zero;
  double nextLeftRot = 0;
  double nextRightRot = 0;

  bool get canCurrentPlayerMove {
    if (board.isEmpty) return true;
    final hand = players[currentPlayerIndex].hand;
    return hand.any((t) => 
      t.left == board.first.left || t.right == board.first.left ||
      t.left == board.last.right || t.right == board.last.right
    );
  }

  GameMode gameMode = GameMode.solo;
  PlayType playType = PlayType.offline;
  String? onlineRoomId;

  static const int tilesPerPlayer = 7;
  static const int maxTileValue = 6;

  final Map<GameMode, Map<String, dynamic>> configs = {
    GameMode.solo: {'gems': 25, 'coins': 50, 'points': 2, 'maxPlayers': 2},
    GameMode.duo: {'gems': 50, 'coins': 100, 'points': 5, 'maxPlayers': 3},
    GameMode.trio: {'gems': 100, 'coins': 150, 'points': 10, 'maxPlayers': 4},
    GameMode.quad: {'gems': 200, 'coins': 300, 'points': 15, 'maxPlayers': 4},
  };

  void initGame(int playerCount, {GameMode mode = GameMode.solo, PlayType type = PlayType.offline}) {
    gameMode = mode;
    playType = type;
    board.clear();
    stock.clear();
    isGameOver = false;
    winner = null;
    selectedTile = null;

    DominoSoundService.playStart();

    List<DominoTile> allTiles = [];
    for (int i = 0; i <= maxTileValue; i++) {
      for (int j = i; j <= maxTileValue; j++) {
        allTiles.add(DominoTile(id: 'tile-$i-$j', left: i, right: j, isDouble: i == j));
      }
    }
    allTiles.shuffle();

    List<List<DominoTile>> playerHands = List.generate(playerCount, (i) => []);
    int tileIndex = 0;
    for (int i = 0; i < tilesPerPlayer; i++) {
      for (int p = 0; p < playerCount; p++) {
        playerHands[p].add(allTiles[tileIndex++]);
      }
    }

    stock = allTiles.sublist(tileIndex);

    int startingPlayerIdx = 0;
    DominoTile? startingTile;
    int highestDouble = -1;

    for (int i = 0; i < playerCount; i++) {
      for (var tile in playerHands[i]) {
        if (tile.isDouble && tile.left > highestDouble) {
          highestDouble = tile.left;
          startingPlayerIdx = i;
          startingTile = tile;
        }
      }
    }

    startingTile ??= playerHands[0][0];

    players = List.generate(playerCount, (index) => DominoPlayer(
      id: index == 0 ? (_auth.currentUser?.uid ?? 'player-0') : 'ai-$index',
      username: index == 0 ? 'الملك' : 'الخصم $index',
      hand: playerHands[index],
    ));

    players[startingPlayerIdx].hand.removeWhere((t) => t.id == startingTile!.id);
    board.add(startingTile);
    _updateBoardPositions();

    currentPlayerIndex = (startingPlayerIdx + 1) % playerCount;
    players[currentPlayerIndex].isCurrentPlayer = true;

    if (type == PlayType.online) {
      _createFirebaseRoom();
    }
    
    notifyListeners();

    if (playType == PlayType.offline && players[currentPlayerIndex].id.startsWith('ai')) {
      Future.delayed(const Duration(seconds: 1), () => _makeAIMove());
    }
  }

  void resetGame() {
    initGame(players.length, mode: gameMode, type: playType);
  }

  Future<void> _createFirebaseRoom() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final roomRef = _db.child('domino_rooms').push();
    onlineRoomId = roomRef.key;

    await roomRef.set({
      'host_id': user.uid,
      'mode': gameMode.name,
      'status': 'active',
      'board': board.map((e) => e.toJson()).toList(),
      'current_player_index': currentPlayerIndex,
      'last_action_time': ServerValue.timestamp,
    });

    _listenToFirebaseRoom();
  }

  void _listenToFirebaseRoom() {
    if (onlineRoomId == null) return;
    _db.child('domino_rooms').child(onlineRoomId!).onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null && currentPlayerIndex != 0) {
        _syncFromFirebase(Map<String, dynamic>.from(data));
      }
    });
  }

  void _syncFromFirebase(Map<String, dynamic> data) {
    if (data['board'] != null) {
      board = (data['board'] as List).map((e) => DominoTile.fromJson(Map<String, dynamic>.from(e))).toList();
      _updateBoardPositions();
    }
    currentPlayerIndex = data['current_player_index'] ?? 0;
    notifyListeners();
  }

  bool playMove(DominoTile tile, String side) {
    bool success = false;
    if (board.isEmpty) {
      board.add(tile);
      success = true;
    } else {
      if (side == 'left') {
        if (tile.right == board.first.left) {
          board.insert(0, tile);
          success = true;
        } else if (tile.left == board.first.left) {
          tile.flip();
          board.insert(0, tile);
          success = true;
        }
      } else if (side == 'right') {
        if (tile.left == board.last.right) {
          board.add(tile);
          success = true;
        } else if (tile.right == board.last.right) {
          tile.flip();
          board.add(tile);
          success = true;
        }
      }
    }

    if (success) {
      lastPlacedTile = tile;
      _updateBoardPositions();
      DominoSoundService.playPlaceTile();
      players[currentPlayerIndex].hand.removeWhere((t) => t.id == tile.id);
      
      if (players[currentPlayerIndex].hand.isEmpty) {
        isGameOver = true;
        winner = players[currentPlayerIndex];
        _handleGameEnd();
      } else {
        _nextTurn();
        _checkPlayerCanMove();
      }
      
      if (playType == PlayType.online) _updateFirebaseBoard();
      
      selectedTile = null;
      notifyListeners();
    } else {
      DominoSoundService.playError();
    }
    return success;
  }

  void _updateBoardPositions() {
    if (board.isEmpty) return;

    double curX = 0;
    double curY = 0;
    int dir = 0; // 0: Down, 1: Right, 2: Up, 3: Left
    
    const double tileW = 40.0;
    const double tileH = 80.0;
    const double spacing = 2.0;

    for (int i = 0; i < board.length; i++) {
      DominoTile tile = board[i];
      
      // 1. Set Rotation
      if (tile.isDouble) {
        tile.rotation = (dir == 0 || dir == 2) ? 1.5708 : 0;
      } else {
        switch (dir) {
          case 0: tile.rotation = 0; break;
          case 1: tile.rotation = -1.5708; break;
          case 2: tile.rotation = 3.14159; break;
          case 3: tile.rotation = 1.5708; break;
        }
      }

      // 2. Set Position
      tile.x = curX;
      tile.y = curY;

      // 3. Prepare for Next Tile
      if (i < board.length - 1) {
        DominoTile next = board[i + 1];
        
        int nextDir = dir;
        // Determine if we need to turn
        if (dir == 0 && curY > 160) {
          nextDir = 1;
        } else if (dir == 1 && curX > 140) nextDir = 2;
        else if (dir == 2 && curY < -160) nextDir = 3;
        else if (dir == 3 && curX < -140) nextDir = 0;

        double dist;
        if (nextDir == dir) {
          // Linear movement
          double currentHalf = tile.isDouble ? tileW / 2 : tileH / 2;
          double nextHalf = next.isDouble ? tileW / 2 : tileH / 2;
          dist = currentHalf + nextHalf + spacing;
          
          if (dir == 0) {
            curY += dist;
          } else if (dir == 1) curX += dist;
          else if (dir == 2) curY -= dist;
          else if (dir == 3) curX -= dist;
        } else {
          // Elbow turn
          // When turning, we connect to the corner/side area
          double currentHalf = tile.isDouble ? tileW / 2 : tileH / 2;
          double nextHalf = next.isDouble ? tileW / 2 : tileH / 2;
          
          // Move to the edge of current, then shift by half of next in new direction
          if (dir == 0 && nextDir == 1) { // Down -> Right
             curY += currentHalf + spacing;
             curX += nextHalf + spacing;
          } else if (dir == 1 && nextDir == 2) { // Right -> Up
             curX += currentHalf + spacing;
             curY -= nextHalf + spacing;
          } else if (dir == 2 && nextDir == 3) { // Up -> Left
             curY -= currentHalf + spacing;
             curX -= nextHalf + spacing;
          } else if (dir == 3 && nextDir == 0) { // Left -> Down
             curX -= currentHalf + spacing;
             curY += nextHalf + spacing;
          }
          dir = nextDir;
        }
      }
    }
    
    if (board.isNotEmpty) {
      DominoTile first = board.first;
      DominoTile last = board.last;
      // Heuristic for drop zones
      nextLeftPos = Offset(first.x, first.y - 70); 
      nextRightPos = Offset(last.x, last.y + 70);
    }
  }

  void _checkPlayerCanMove() {
    if (isGameOver) return;
    
    DominoPlayer current = players[currentPlayerIndex];
    bool canMove = current.hand.any((t) => 
      t.left == board.first.left || t.right == board.first.left ||
      t.left == board.last.right || t.right == board.last.right);
      
    if (!canMove) {
      if (stock.isNotEmpty) {
        if (current.id.startsWith('ai')) {
          Future.delayed(const Duration(milliseconds: 500), () {
            drawFromStock();
            _checkPlayerCanMove();
          });
        }
      } else {
        _nextTurn();
        _checkGameBlock();
      }
    } else if (current.id.startsWith('ai')) {
      Future.delayed(const Duration(seconds: 1), () => _makeAIMove());
    }
  }

  void _handleGameEnd() {
    final user = _auth.currentUser;
    if (user != null && winner?.id == user.uid) {
      DominoSoundService.playWin();
      DominoSoundService.playCoins();
      _distributeRewards();
    } else {
      DominoSoundService.playLose();
    }
  }

  void _updateFirebaseBoard() async {
    if (onlineRoomId == null) return;
    await _db.child('domino_rooms').child(onlineRoomId!).update({
      'board': board.map((e) => e.toJson()).toList(),
      'current_player_index': currentPlayerIndex,
      'status': isGameOver ? 'finished' : 'active',
      'last_action_time': ServerValue.timestamp,
    });
  }

  void _makeAIMove() {
    if (isGameOver) return;
    DominoPlayer ai = players[currentPlayerIndex];
    
    List<Map<String, dynamic>> possibleMoves = [];

    for (var tile in ai.hand) {
      if (tile.left == board.first.left || tile.right == board.first.left) {
        possibleMoves.add({'tile': tile, 'side': 'left'});
      }
      if (tile.left == board.last.right || tile.right == board.last.right) {
        possibleMoves.add({'tile': tile, 'side': 'right'});
      }
    }

    if (possibleMoves.isNotEmpty) {
      possibleMoves.sort((a, b) {
        DominoTile tA = a['tile'];
        DominoTile tB = b['tile'];
        if (tA.isDouble && !tB.isDouble) return -1;
        if (!tA.isDouble && tB.isDouble) return 1;
        return (tB.left + tB.right).compareTo(tA.left + tA.right);
      });

      var bestMove = possibleMoves.first;
      playMove(bestMove['tile'], bestMove['side']);
    } else if (stock.isNotEmpty) {
      drawFromStock();
      Future.delayed(const Duration(milliseconds: 500), () => _makeAIMove());
    } else {
      _nextTurn();
      _checkGameBlock();
    }
  }

  void _checkGameBlock() {
    bool canAnyoneMove = false;
    for (var player in players) {
      for (var tile in player.hand) {
        if (tile.left == board.first.left || tile.right == board.first.left ||
            tile.left == board.last.right || tile.right == board.last.right) {
          canAnyoneMove = true;
          break;
        }
      }
      if (canAnyoneMove) break;
    }

    if (!canAnyoneMove && stock.isEmpty) {
      _finishBlockedGame();
    }
  }

  void _finishBlockedGame() {
    isGameOver = true;
    players.sort((a, b) {
      int scoreA = a.hand.fold(0, (sum, t) => sum + t.left + t.right);
      int scoreB = b.hand.fold(0, (sum, t) => sum + t.left + t.right);
      return scoreA.compareTo(scoreB);
    });
    winner = players.first;
    _handleGameEnd();
    notifyListeners();
  }

  Future<void> joinRoom(String roomId) async {
    onlineRoomId = roomId;
    playType = PlayType.online;
    final snapshot = await _db.child('domino_rooms').child(roomId).get();
    if (snapshot.exists) {
      _listenToFirebaseRoom();
    }
  }

  void _nextTurn() {
    players[currentPlayerIndex].isCurrentPlayer = false;
    currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
    players[currentPlayerIndex].isCurrentPlayer = true;
    if (currentPlayerIndex == 0) {
      DominoSoundService.playTurn();
    }
  }

  void drawFromStock() {
    if (stock.isNotEmpty) {
      DominoSoundService.playDrawTile();
      players[currentPlayerIndex].hand.add(stock.removeAt(0));
      notifyListeners();
      
      if (players[currentPlayerIndex].id.startsWith('ai')) {
         _checkPlayerCanMove();
      }
    }
  }

  void selectTile(DominoTile? tile) {
    selectedTile = (selectedTile?.id == tile?.id) ? null : tile;
    notifyListeners();
  }

  void _distributeRewards() async {
    final user = _auth.currentUser;
    if (user != null && winner?.id == user.uid) {
      final config = configs[gameMode]!;
      try {
        final walletRef = _db.child('users').child(user.uid).child('wallet');
        await walletRef.runTransaction((Object? wallet) {
          if (wallet == null) return Transaction.abort();
          Map<String, dynamic> walletData = Map<String, dynamic>.from(wallet as Map);
          walletData['coins'] = (walletData['coins'] ?? 0) + (config['coins'] * 2);
          walletData['gems'] = (walletData['gems'] ?? 0) + (config['gems'] * 2);
          return Transaction.success(walletData);
        });
      } catch (e) {
        debugPrint("Reward Error: $e");
      }
    }
  }

  Map<String, int> getCalculatedRewards() {
    final config = configs[gameMode]!;
    bool isWinner = winner?.id == (_auth.currentUser?.uid ?? 'player-0');
    return {
      'gems': isWinner ? config['gems']! * 2 : 0,
      'coins': isWinner ? config['coins']! * 2 : 0,
      'points': isWinner ? config['points']! : 0,
    };
  }
}
