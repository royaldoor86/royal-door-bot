import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui';
import '../../../../theme/design_tokens.dart';

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
  bool _isDrawing = false;

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
      
      final dynamic startData = widget.gameData['startTime'];
      if (startData == null) {
        if (_secondsLeft != 30) setState(() => _secondsLeft = 30);
        return;
      }
      
      final DateTime startTime;
      if (startData is Timestamp) {
        startTime = startData.toDate();
      } else {
        startTime = DateTime.now();
      }

      final now = DateTime.now();
      final diff = now.difference(startTime).inSeconds;
      final remaining = 30 - diff;

      final newSeconds = remaining > 0 ? remaining : 0;
      if (_secondsLeft != newSeconds) {
        setState(() {
          _secondsLeft = newSeconds;
        });
      }

      if (_secondsLeft <= 0 && widget.gameData['status'] == 'betting' && widget.hasPower && !_isDrawing) {
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

    return ClipRRect(
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
                const Color(0xFF1A242F).withValues(alpha: 0.8),
                const Color(0xFF0F1B25).withValues(alpha: 0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: DesignTokens.primaryGold.withValues(alpha: 0.3), width: 1.5),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 15)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(status),
              const SizedBox(height: 16),
              _buildFruitGrid(status, winnerId, selections),
              const SizedBox(height: 16),
              _buildStatusArea(status, winnerId),
              if (widget.hasPower) ...[
                const SizedBox(height: 12),
                _buildAdminControls(status),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Row(
          children: [
            Icon(Icons.videogame_asset_rounded, color: DesignTokens.primaryGold, size: 20),
            SizedBox(width: 8),
            Text("حرب الفواكه الملكية", 
              style: TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.bold, 
                fontSize: 15,
                fontFamily: DesignTokens.primaryFont,
              )),
          ],
        ),
        if (status == 'betting')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Colors.redAccent, Colors.red]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.3), blurRadius: 8)],
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_sharp, color: Colors.white, size: 12),
                const SizedBox(width: 4),
                Text("$_secondsLeft ثانية", 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
              ],
            ),
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
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: _fruits.length,
      itemBuilder: (context, index) {
        final fruit = _fruits[index];
        bool isSelected = _myChoice == fruit['id'];
        bool isWinner = status == 'result' && winnerId == fruit['id'];
        
        int betCount = 0;
        selections.forEach((key, value) {
          if (value == fruit['id']) betCount++;
        });

        return GestureDetector(
          onTap: status == 'betting' ? () => _selectFruit(fruit['id']) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              color: isWinner 
                  ? fruit['color'].withValues(alpha: 0.3) 
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isWinner 
                    ? DesignTokens.primaryGold 
                    : (isSelected ? fruit['color'] : Colors.white10),
                width: isWinner || isSelected ? 2.5 : 1.0,
              ),
              boxShadow: isWinner ? [
                BoxShadow(color: fruit['color'].withValues(alpha: 0.4), blurRadius: 10)
              ] : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(fruit['icon'], style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: 4),
                    Text(fruit['name'], 
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white54, 
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                      )),
                  ],
                ),
                if (betCount > 0)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6), 
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white10, width: 0.5),
                      ),
                      child: Text("$betCount", style: const TextStyle(color: Colors.amber, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                  ),
                if (isSelected)
                  const Positioned(top: 6, left: 6, child: Icon(Icons.check_circle, color: Colors.greenAccent, size: 16)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusArea(String status, String? winnerId) {
    if (status == 'betting') {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: DesignTokens.primaryGold.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: DesignTokens.primaryGold.withValues(alpha: 0.1)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.stars, color: DesignTokens.primaryGold, size: 16),
            SizedBox(width: 8),
            Text("توقع الفاكهة الرابحة واحصد الجوائز!", 
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }
    
    if (status == 'result' && winnerId != null) {
      final winner = _fruits.firstWhere((f) => f['id'] == winnerId, orElse: () => _fruits[0]);
      bool iWon = _myChoice == winnerId;
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
            winner['color'].withValues(alpha: 0.2),
            Colors.black.withValues(alpha: 0.4),
          ]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: winner['color'].withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: winner['color'].withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Text(winner['icon'], style: const TextStyle(fontSize: 40)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("الفاكهة الرابحة: ${winner['name']}", 
                    style: TextStyle(color: winner['color'], fontWeight: FontWeight.w900, fontSize: 18)),
                  const SizedBox(height: 4),
                  Text(iWon ? "تهانينا! لقد ربحت الرهان 🏆" : "حظاً أوفر في الجولة القادمة 🚩",
                      style: TextStyle(color: iWon ? Colors.greenAccent : Colors.white38, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildAdminControls(String status) {
    return Row(
      children: [
        if (status == 'result')
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _restartGame,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text("جولة جديدة", style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.withValues(alpha: 0.8),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        const SizedBox(width: 12),
        TextButton(
          onPressed: _endGame,
          style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
          child: const Text("إنهاء اللعبة", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ],
    );
  }

  void _selectFruit(String fruitId) async {
    HapticFeedback.lightImpact();
    final docRef = FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);
    await docRef.update({
      'activeGame.selections.$_myUid': fruitId,
    });
  }

  void _drawWinner() async {
    if (!widget.hasPower || _isDrawing) return;
    
    if (widget.gameData['status'] != 'betting') return;

    setState(() => _isDrawing = true);
    try {
      final winner = _fruits[Random().nextInt(_fruits.length)];
      await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
        'activeGame.status': 'result',
        'activeGame.winnerId': winner['id'],
      });
    } catch (e) {
      debugPrint("Error drawing winner: $e");
    } finally {
      if (mounted) setState(() => _isDrawing = false);
    }
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

