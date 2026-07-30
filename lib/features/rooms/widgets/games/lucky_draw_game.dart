import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:math';

class LuckyDrawGame extends StatefulWidget {
  final String roomId;
  final Map<String, dynamic> gameData;
  final bool hasPower;

  const LuckyDrawGame({
    super.key,
    required this.roomId,
    required this.gameData,
    required this.hasPower,
  });

  @override
  State<LuckyDrawGame> createState() => _LuckyDrawGameState();
}

class _LuckyDrawGameState extends State<LuckyDrawGame> with SingleTickerProviderStateMixin {
  final String _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  late AnimationController _rotationController;
  Timer? _timer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final startTime = (widget.gameData['startTime'] as Timestamp).toDate();
      final duration = widget.gameData['duration'] ?? 60;
      final diff = DateTime.now().difference(startTime).inSeconds;
      final remaining = duration - diff;

      setState(() {
        _secondsLeft = remaining > 0 ? remaining : 0;
      });

      if (remaining <= 0 && widget.gameData['status'] == 'ongoing' && widget.hasPower) {
        _drawWinner();
      }
    });
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String status = widget.gameData['status'] ?? 'ongoing';
    List<dynamic> participants = widget.gameData['participants'] ?? [];
    String? winnerId = widget.gameData['winnerId'];
    String? winnerName = widget.gameData['winnerName'];
    bool isParticipating = participants.contains(_myUid);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C3E50), Color(0xFF000000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.5), width: 2),
        boxShadow: [BoxShadow(color: Colors.orangeAccent.withValues(alpha: 0.2), blurRadius: 20)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          if (status == 'ongoing') _buildOngoingUI(isParticipating, participants.length),
          if (status == 'ended') _buildWinnerUI(winnerId, winnerName),
          const SizedBox(height: 20),
          _buildFooter(status),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text("سحب الحظ الملكي 🎁✨",
            style: TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold)),
        if (widget.gameData['status'] == 'ongoing')
          Text("الوقت المتبقي: $_secondsLeft ثانية",
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildOngoingUI(bool isParticipating, int count) {
    return Column(
      children: [
        RotationTransition(
          turns: _rotationController,
          child: const Icon(Icons.stars, color: Colors.amber, size: 80),
        ),
        const SizedBox(height: 20),
        Text("المشاركون: $count", style: const TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 15),
        if (!isParticipating)
          ElevatedButton(
            onPressed: _joinDraw,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text("دخول السحب مجاناً 🎫", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
            child: const Text("تم تسجيل دخولك ✅", style: TextStyle(color: Colors.greenAccent)),
          ),
      ],
    );
  }

  Widget _buildWinnerUI(String? id, String? name) {
    bool iWon = id == _myUid;
    return Column(
      children: [
        const Icon(Icons.card_membership, color: Colors.amber, size: 80),
        const SizedBox(height: 15),
        const Text("الفائز المحظوظ هو:", style: TextStyle(color: Colors.white70)),
        const SizedBox(height: 5),
        Text(name ?? "مستخدم ملكي",
            style: const TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Text(iWon ? "مبروك! لقد ربحت 🏆👑" : "حظاً أوفر للجميع! ✨",
            style: TextStyle(color: iWon ? Colors.greenAccent : Colors.white38)),
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
            child: const Text("إغلاق السحب", style: TextStyle(color: Colors.redAccent)),
          ),
      ],
    );
  }

  void _joinDraw() async {
    await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
      'activeGame.participants': FieldValue.arrayUnion([_myUid]),
    });
  }

  void _drawWinner() async {
    if (!widget.hasPower) return;
    
    List<dynamic> participants = widget.gameData['participants'] ?? [];
    if (participants.isEmpty) {
      await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
        'activeGame': FieldValue.delete(),
      });
      return;
    }

    final winnerId = participants[Random().nextInt(participants.length)];
    final userSnap = await FirebaseFirestore.instance.collection('users').doc(winnerId).get();
    final winnerName = userSnap.data()?['name'] ?? 'مستخدم';

    await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
      'activeGame.status': 'ended',
      'activeGame.winnerId': winnerId,
      'activeGame.winnerName': winnerName,
    });
  }

  void _closeGame() async {
    await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
      'activeGame': FieldValue.delete(),
    });
  }
}
