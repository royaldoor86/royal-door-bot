import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import '../../../../theme/design_tokens.dart';

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
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
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
      scale: CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0F1B25).withValues(alpha: 0.8),
                  Colors.black.withValues(alpha: 0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: DesignTokens.primaryGold.withValues(alpha: 0.3), width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20)
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(status, winner),
                const SizedBox(height: 20),
                _buildBoard(board, status),
                const SizedBox(height: 16),
                _buildFooter(status),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String status, String? winner) {
    String title = "تيك تاك تو الملكية ⚔️";
    Color titleColor = DesignTokens.primaryGold;

    if (status == 'waiting') {
      title = "بانتظار المنافس... ⏳";
      titleColor = Colors.amber;
    } else if (status == 'playing') {
      title = _isMyTurn ? "دورك الآن! 🔥" : "دور الخصم... ⌛";
      titleColor = _isMyTurn ? Colors.greenAccent : Colors.white70;
    } else if (status == 'ended') {
      if (winner == 'draw') {
        title = "انتهت الجولة بالتعادل! 🤝";
        titleColor = Colors.white70;
      } else {
        bool iWon = winner == _myUid;
        title = iWon ? "تهانينا! لقد انتصرت 🏆" : "حظاً أوفر في المرة القادمة! 🚩";
        titleColor = iWon ? DesignTokens.primaryGold : Colors.redAccent;
      }
    }

    return Text(title,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: titleColor, 
          fontSize: 15, 
          fontWeight: FontWeight.bold,
          fontFamily: DesignTokens.primaryFont,
        ));
  }

  Widget _buildBoard(List<dynamic> board, String status) {
    return SizedBox(
      width: 200,
      height: 200,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: 9,
        itemBuilder: (context, index) {
          String? val = board[index];
          return GestureDetector(
            onTap: () => _handleMove(index, board, status),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: val == null ? Colors.white10 : (val == 'X' ? Colors.blueAccent : Colors.redAccent),
                  width: val == null ? 1.0 : 2.0,
                ),
                boxShadow: val != null ? [
                  BoxShadow(color: (val == 'X' ? Colors.blueAccent : Colors.redAccent).withValues(alpha: 0.2), blurRadius: 8)
                ] : null,
              ),
              child: Center(
                child: Text(
                  val ?? '',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: val == 'X' ? Colors.blueAccent : Colors.redAccent,
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
      return Container(
        width: 180,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(colors: [DesignTokens.primaryGold, DesignTokens.primaryGoldLight]),
        ),
        child: ElevatedButton(
          onPressed: _joinGame,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          ),
          child: const Text("تحدي الآن!", 
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13)),
        ),
      );
    }

    if (widget.hasPower || status == 'ended') {
      return TextButton.icon(
        onPressed: _resetGame,
        icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white24),
        label: const Text("إغلاق اللعبة", style: TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold)),
      );
    }

    return const SizedBox.shrink();
  }

  void _joinGame() async {
    HapticFeedback.mediumImpact();
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

    HapticFeedback.lightImpact();
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

