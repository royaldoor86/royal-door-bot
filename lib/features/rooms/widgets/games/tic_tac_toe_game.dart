import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class TicTacToeGame extends StatefulWidget {
  final String roomId;
  final Map<String, dynamic> gameData;
  final bool hasPower;

  const TicTacToeGame({
    super.key,
    required this.roomId,
    required this.gameData,
    required this.hasPower,
  });

  @override
  State<TicTacToeGame> createState() => _TicTacToeGameState();
}

class _TicTacToeGameState extends State<TicTacToeGame> with TickerProviderStateMixin {
  final String _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  late AnimationController _animController;
  
  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  bool get _isPlayerX => widget.gameData['playerX'] == _myUid;
  bool get _isPlayerO => widget.gameData['playerO'] == _myUid;
  bool get _isMyTurn => widget.gameData['turn'] == _myUid;
  bool get _isSpectator => !_isPlayerX && !_isPlayerO;

  @override
  Widget build(BuildContext context) {
    List<dynamic> board = List.from(widget.gameData['board'] ?? List.filled(9, null));
    String status = widget.gameData['status'] ?? 'waiting';
    String? winner = widget.gameData['winner'];

    return ScaleTransition(
      scale: CurvedAnimation(parent: _animController, curve: Curves.backOut),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A242F).withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3), width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 5)
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(status, winner),
            const SizedBox(height: 20),
            _buildBoard(board, status),
            const SizedBox(height: 20),
            _buildFooter(status),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String status, String? winner) {
    String title = "تيك تاك تو الملكية ⚔️";
    Color titleColor = Colors.amber;

    if (status == 'waiting') {
      title = "بانتظار المنافس... ⏳";
    } else if (status == 'playing') {
      title = _isMyTurn ? "دورك الآن! 🔥" : "دور الخصم... ⌛";
      titleColor = _isMyTurn ? Colors.greenAccent : Colors.white70;
    } else if (status == 'ended') {
      if (winner == 'draw') {
        title = "تعادل! 🤝";
      } else {
        bool iWon = winner == _myUid;
        title = iWon ? "لقد فزت! 🏆👑" : "حظاً أوفر! 🚩";
        titleColor = iWon ? Colors.goldAccent : Colors.redAccent;
      }
    }

    return Text(title,
        style: TextStyle(color: titleColor, fontSize: 18, fontWeight: FontWeight.bold));
  }

  Widget _buildBoard(List<dynamic> board, String status) {
    return AspectRatio(
      aspectRatio: 1,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: 9,
        itemBuilder: (context, index) {
          String? val = board[index];
          return GestureDetector(
            onTap: () => _handleMove(index, board, status),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: val == null ? Colors.white10 : (val == 'X' ? Colors.blue : Colors.red),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  val ?? '',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: val == 'X' ? Colors.blue : Colors.red,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFooter(String status) {
    if (status == 'waiting' && _isSpectator) {
      return ElevatedButton(
        onPressed: _joinGame,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: const Text("تحدي الآن!", style: TextStyle(fontWeight: FontWeight.bold)),
      );
    }

    if (widget.hasPower || status == 'ended') {
      return TextButton(
        onPressed: _resetGame,
        child: const Text("إنهاء اللعبة", style: TextStyle(color: Colors.redAccent)),
      );
    }

    return const SizedBox.shrink();
  }

  void _joinGame() async {
    final docRef = FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      final data = snap.data()?['activeGame'] ?? {};
      
      if (data['playerO'] == null) {
        data['playerO'] = _myUid;
        data['status'] = 'playing';
        tx.update(docRef, {'activeGame': data});
      }
    });
  }

  void _handleMove(int index, List<dynamic> board, String status) async {
    if (status != 'playing' || board[index] != null || !_isMyTurn) return;

    board[index] = _isPlayerX ? 'X' : 'O';
    
    // Check for winner
    String? winner;
    if (_checkWinner(board, 'X')) winner = widget.gameData['playerX'];
    if (_checkWinner(board, 'O')) winner = widget.gameData['playerO'];
    
    bool isDraw = !board.contains(null) && winner == null;

    final nextTurn = _isPlayerX ? widget.gameData['playerO'] : widget.gameData['playerX'];

    await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
      'activeGame.board': board,
      'activeGame.turn': (winner != null || isDraw) ? null : nextTurn,
      'activeGame.status': (winner != null || isDraw) ? 'ended' : 'playing',
      'activeGame.winner': isDraw ? 'draw' : winner,
    });
  }

  bool _checkWinner(List<dynamic> b, String p) {
    const wins = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // cols
      [0, 4, 8], [2, 4, 6]             // diags
    ];
    return wins.any((w) => b[w[0]] == p && b[w[1]] == p && b[w[2]] == p);
  }

  void _resetGame() {
    FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
      'activeGame': FieldValue.delete(),
    });
  }
}
