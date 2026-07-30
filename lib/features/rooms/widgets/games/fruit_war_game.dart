import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:math';

class FruitWarGame extends StatefulWidget {
  final String roomId;
  final Map<String, dynamic> gameData;
  final bool hasPower;

  const FruitWarGame({
    super.key,
    required this.roomId,
    required this.gameData,
    required this.hasPower,
  });

  @override
  State<FruitWarGame> createState() => _FruitWarGameState();
}

class _FruitWarGameState extends State<FruitWarGame> with TickerProviderStateMixin {
  final String _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final List<Map<String, dynamic>> _fruits = [
    {'id': 'apple', 'name': 'تفاح', 'icon': '🍎', 'color': Colors.red},
    {'id': 'banana', 'name': 'موز', 'icon': '🍌', 'color': Colors.yellow},
    {'id': 'grapes', 'name': 'عنب', 'icon': '🍇', 'color': Colors.purple},
    {'id': 'orange', 'name': 'برتقال', 'icon': '🍊', 'color': Colors.orange},
    {'id': 'watermelon', 'name': 'رقي', 'icon': '🍉', 'color': Colors.green},
    {'id': 'strawberry', 'name': 'فراولة', 'icon': '🍓', 'color': Colors.pink},
  ];

  String? _myChoice;
  late AnimationController _pulseController;
  Timer? _localTimer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _startLocalTimer();
  }

  void _startLocalTimer() {
    _localTimer?.cancel();
    _localTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final startTime = (widget.gameData['startTime'] as Timestamp).toDate();
      final now = DateTime.now();
      final diff = now.difference(startTime).inSeconds;
      final remaining = 30 - diff;

      setState(() {
        _secondsLeft = remaining > 0 ? remaining : 0;
      });

      if (remaining <= 0 && widget.gameData['status'] == 'betting' && widget.hasPower) {
        _drawWinner();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _localTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String status = widget.gameData['status'] ?? 'betting';
    String? winnerId = widget.gameData['winnerId'];
    Map<String, dynamic> selections = widget.gameData['selections'] ?? {};
    _myChoice = selections[_myUid];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1A242F), const Color(0xFF0F1B25).withValues(alpha: 0.9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 15)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(status),
          const SizedBox(height: 20),
          _buildFruitGrid(status, winnerId, selections),
          const SizedBox(height: 20),
          _buildStatusText(status, winnerId),
          if (widget.hasPower) _buildAdminControls(status),
        ],
      ),
    );
  }

  Widget _buildHeader(String status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text("حرب الفواكه 🍉", style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 18)),
        if (status == 'betting')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(15)),
            child: Text("$_secondsLeft s", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  Widget _buildFruitGrid(String status, String? winnerId, Map<String, dynamic> selections) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
      ),
      itemCount: _fruits.length,
      itemBuilder: (context, index) {
        final fruit = _fruits[index];
        bool isSelected = _myChoice == fruit['id'];
        bool isWinner = status == 'result' && winnerId == fruit['id'];
        
        // Count total bets for this fruit
        int betCount = 0;
        selections.forEach((key, value) {
          if (value == fruit['id']) betCount++;
        });

        return GestureDetector(
          onTap: status == 'betting' ? () => _selectFruit(fruit['id']) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: isWinner ? fruit['color'].withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isWinner ? Colors.amber : (isSelected ? fruit['color'] : Colors.white10),
                width: isWinner || isSelected ? 3 : 1,
              ),
              boxShadow: isWinner ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.5), blurRadius: 10)] : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(fruit['icon'], style: const TextStyle(fontSize: 32)),
                    const SizedBox(height: 4),
                    Text(fruit['name'], style: const TextStyle(color: Colors.white70, fontSize: 10)),
                  ],
                ),
                if (betCount > 0)
                  Positioned(
                    top: 5,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                      child: Text("$betCount", style: const TextStyle(color: Colors.white, fontSize: 9)),
                    ),
                  ),
                if (isSelected)
                  const Positioned(top: 5, left: 8, child: Icon(Icons.check_circle, color: Colors.green, size: 16)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusText(String status, String? winnerId) {
    if (status == 'betting') {
      return const Text("اختر فاكهتك الملكية واربح!", style: TextStyle(color: Colors.white54, fontSize: 13));
    }
    if (status == 'result') {
      final winner = _fruits.firstWhere((f) => f['id'] == winnerId);
      bool iWon = _myChoice == winnerId;
      return Column(
        children: [
          Text("الفائز هو: ${winner['icon']} ${winner['name']}", 
              style: TextStyle(color: winner['color'], fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text(iWon ? "مبروك! لقد فزت 👑🏆" : "حظاً أوفر في المرة القادمة 🚩",
              style: TextStyle(color: iWon ? Colors.amber : Colors.white38, fontSize: 14)),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildAdminControls(String status) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (status == 'result')
            ElevatedButton(
              onPressed: _restartGame,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: const Text("جولة جديدة"),
            ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: _endGame,
            child: const Text("إغلاق اللعبة", style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _selectFruit(String fruitId) async {
    final docRef = FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);
    await docRef.update({
      'activeGame.selections.$_myUid': fruitId,
    });
  }

  void _drawWinner() async {
    if (!widget.hasPower) return;
    
    final winner = _fruits[Random().nextInt(_fruits.length)];
    
    await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
      'activeGame.status': 'result',
      'activeGame.winnerId': winner['id'],
    });
  }

  void _restartGame() async {
    await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
      'activeGame.status': 'betting',
      'activeGame.winnerId': null,
      'activeGame.selections': {},
      'activeGame.startTime': FieldValue.serverTimestamp(),
    });
  }

  void _endGame() {
    FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
      'activeGame': FieldValue.delete(),
    });
  }
}
