import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:math';

class BombGame extends StatefulWidget {
  final String roomId;
  final Map<String, dynamic> gameData;
  final bool hasPower;

  const BombGame({
    super.key,
    required this.roomId,
    required this.gameData,
    required this.hasPower,
  });

  @override
  State<BombGame> createState() => _BombGameState();
}

class _BombGameState extends State<BombGame> with SingleTickerProviderStateMixin {
  final String _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  late AnimationController _shakeController;
  Timer? _explosionTimer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 100))..repeat(reverse: true);
    _startTimer();
  }

  void _startTimer() {
    _explosionTimer?.cancel();
    _explosionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final startTime = (widget.gameData['startTime'] as Timestamp).toDate();
      final duration = widget.gameData['duration'] ?? 20;
      final diff = DateTime.now().difference(startTime).inSeconds;
      final remaining = duration - diff;

      setState(() {
        _secondsLeft = remaining > 0 ? remaining : 0;
      });

      if (remaining <= 0 && widget.gameData['status'] == 'playing' && widget.hasPower) {
        _explode();
      }
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _explosionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String status = widget.gameData['status'] ?? 'playing';
    String? currentHolderId = widget.gameData['currentHolderId'];
    String? currentHolderName = widget.gameData['currentHolderName'];
    String? loserName = widget.gameData['loserName'];
    bool isHoldingBomb = currentHolderId == _myUid;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3), width: 2),
        boxShadow: [BoxShadow(color: Colors.redAccent.withValues(alpha: 0.1), blurRadius: 20)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(status),
          const SizedBox(height: 20),
          if (status == 'playing') _buildBombUI(isHoldingBomb, currentHolderName),
          if (status == 'exploded') _buildExplosionUI(loserName),
          const SizedBox(height: 20),
          _buildFooter(status),
        ],
      ),
    );
  }

  Widget _buildHeader(String status) {
    return Column(
      children: [
        const Text("تحدي القنبلة الموقوتة 💣🔥",
            style: TextStyle(color: Colors.redAccent, fontSize: 18, fontWeight: FontWeight.bold)),
        if (status == 'playing')
          Text("الوقت يمر... $_secondsLeft ثانية",
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildBombUI(bool isHoldingBomb, String? holderName) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _shakeController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(sin(_shakeController.value * pi * 10) * 2, 0),
              child: const Icon(Icons.error, color: Colors.redAccent, size: 80),
            );
          },
        ),
        const SizedBox(height: 20),
        Text(isHoldingBomb ? "القنبلة معك! انقلها بسرعة! 😱" : "القنبلة مع: ${holderName ?? 'مجهول'}",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: isHoldingBomb ? Colors.redAccent : Colors.white,
                fontSize: 16,
                fontWeight: isHoldingBomb ? FontWeight.bold : FontWeight.normal)),
        const SizedBox(height: 15),
        if (isHoldingBomb) _buildTransferControls(),
      ],
    );
  }

  Widget _buildTransferControls() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final roomData = snapshot.data!.data() as Map<String, dynamic>;
        final seats = roomData['micSeats'] as List<dynamic>? ?? [];
        
        List<Map<String, dynamic>> otherSpeakers = [];
        for (var seat in seats) {
          if (seat['uid'] != null && seat['uid'] != _myUid) {
            otherSpeakers.add({'uid': seat['uid'], 'name': seat['name'] ?? 'مستخدم'});
          }
        }

        if (otherSpeakers.isEmpty) {
          return const Text("لا يوجد أحد لنقل القنبلة إليه!", style: TextStyle(color: Colors.white54, fontSize: 12));
        }

        return Wrap(
          spacing: 10,
          children: otherSpeakers.map((s) {
            return ActionChip(
              backgroundColor: Colors.redAccent.withValues(alpha: 0.2),
              label: Text(s['name'], style: const TextStyle(color: Colors.white, fontSize: 10)),
              onPressed: () => _transferBomb(s['uid'], s['name']),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildExplosionUI(String? loserName) {
    return Column(
      children: [
        const Icon(Icons.flash_on, color: Colors.yellow, size: 100),
        const SizedBox(height: 15),
        const Text("بوم! 💥 انفجرت القنبلة في:", style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 5),
        Text(loserName ?? "مستخدم سيء الحظ",
            style: const TextStyle(color: Colors.redAccent, fontSize: 22, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildFooter(String status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.hasPower)
          TextButton(
            onPressed: _closeGame,
            child: const Text("إغلاق اللعبة", style: TextStyle(color: Colors.white38)),
          ),
      ],
    );
  }

  void _transferBomb(String targetUid, String targetName) async {
    await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
      'activeGame.currentHolderId': targetUid,
      'activeGame.currentHolderName': targetName,
    });
  }

  void _explode() async {
    if (!widget.hasPower) return;
    
    final currentHolderName = widget.gameData['currentHolderName'];

    await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
      'activeGame.status': 'exploded',
      'activeGame.loserName': currentHolderName,
    });
  }

  void _closeGame() async {
    await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
      'activeGame': FieldValue.delete(),
    });
  }
}
