import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui';
import '../../../../theme/design_tokens.dart';

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
    _rotationController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final startTimeData = widget.gameData['startTime'];
      if (startTimeData == null) return;

      final startTime = (startTimeData as Timestamp).toDate();
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
                const Color(0xFF0F1B25).withValues(alpha: 0.8),
                const Color(0xFF051211).withValues(alpha: 0.9),
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
              const SizedBox(height: 20),
              if (status == 'ongoing') _buildOngoingUI(isParticipating, participants.length),
              if (status == 'ended') _buildWinnerUI(winnerId, winnerName),
              const SizedBox(height: 20),
              _buildFooter(status),
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
        Row(
          children: [
            const Icon(Icons.auto_awesome_rounded, color: DesignTokens.primaryGold, size: 20),
            const SizedBox(width: 8),
            Text(status == 'ongoing' ? "سحب الحظ الملكي" : "انتهى السحب", 
              style: const TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.bold, 
                fontSize: 16,
                fontFamily: DesignTokens.primaryFont,
              )),
          ],
        ),
        if (status == 'ongoing')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: DesignTokens.primaryGold.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, color: DesignTokens.primaryGold, size: 14),
                const SizedBox(width: 6),
                Text("$_secondsLeft ثانية", 
                  style: const TextStyle(color: DesignTokens.primaryGold, fontWeight: FontWeight.w900, fontSize: 12)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildOngoingUI(bool isParticipating, int count) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            RotationTransition(
              turns: _rotationController,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      DesignTokens.primaryGold.withValues(alpha: 0.1),
                      DesignTokens.primaryGold,
                      DesignTokens.primaryGold.withValues(alpha: 0.1),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              width: 85,
              height: 80,
              decoration: const BoxDecoration(color: Color(0xFF0F1B25), shape: BoxShape.circle),
              child: const Icon(Icons.stars_rounded, color: DesignTokens.primaryGold, size: 45),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.group_rounded, color: Colors.white54, size: 16),
              const SizedBox(width: 8),
              Text("المشاركون: $count", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (!isParticipating)
          Container(
            width: 220,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              gradient: const LinearGradient(colors: [DesignTokens.primaryGold, DesignTokens.primaryGoldLight]),
              boxShadow: [BoxShadow(color: DesignTokens.primaryGold.withValues(alpha: 0.3), blurRadius: 12)],
            ),
            child: ElevatedButton(
              onPressed: _joinDraw,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
              ),
              child: const Text("دخول مجاناً 🎫", 
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14)),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1), 
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 18),
                SizedBox(width: 8),
                Text("أنت مشارك في السحب ✅", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildWinnerUI(String? id, String? name) {
    bool iWon = id == _myUid;
    return Column(
      children: [
        const Icon(Icons.emoji_events_rounded, color: DesignTokens.primaryGold, size: 70),
        const SizedBox(height: 16),
        const Text("الفائز المحظوظ في هذه الجولة:", 
          style: TextStyle(color: Colors.white70, fontSize: 14, fontFamily: DesignTokens.primaryFont)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          decoration: BoxDecoration(
            color: DesignTokens.primaryGold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: DesignTokens.primaryGold.withValues(alpha: 0.3)),
          ),
          child: Text(name ?? "مستخدم",
              style: const TextStyle(
                color: DesignTokens.primaryGold, 
                fontSize: 22, 
                fontWeight: FontWeight.w900,
                fontFamily: DesignTokens.primaryFont,
              )),
        ),
        const SizedBox(height: 12),
        Text(iWon ? "تهانينا! لقد حصلت على الجائزة 🏆" : "حظاً أوفر في السحب القادم ✨",
            style: TextStyle(color: iWon ? Colors.greenAccent : Colors.white38, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildFooter(String status) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.hasPower)
          TextButton.icon(
            onPressed: _closeGame,
            icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white24),
            label: const Text("إغلاق السحب", 
              style: TextStyle(color: Colors.white24, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  void _joinDraw() async {
    HapticFeedback.mediumImpact();
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

