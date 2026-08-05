import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui';
import '../../../../theme/design_tokens.dart';

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
      final startTimeData = widget.gameData['startTime'];
      if (startTimeData == null) return;
      
      final startTime = (startTimeData as Timestamp).toDate();
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
                Colors.black.withValues(alpha: 0.7),
                const Color(0xFF1A0505).withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isHoldingBomb 
                  ? Colors.redAccent.withValues(alpha: 0.5) 
                  : DesignTokens.primaryGold.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isHoldingBomb ? Colors.redAccent : Colors.black).withValues(alpha: 0.2),
                blurRadius: 15,
                spreadRadius: 2,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(status),
              const SizedBox(height: 12),
              if (status == 'playing') _buildBombUI(isHoldingBomb, currentHolderName),
              if (status == 'exploded') _buildExplosionUI(loserName),
              const SizedBox(height: 12),
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
            const Icon(Icons.timer_outlined, color: Colors.redAccent, size: 18),
            const SizedBox(width: 8),
            Text(status == 'playing' ? "القنبلة الموقوتة" : "انتهى التحدي",
                style: const TextStyle(
                  color: Colors.white, 
                  fontSize: 15, 
                  fontWeight: FontWeight.bold,
                  fontFamily: DesignTokens.primaryFont,
                )),
          ],
        ),
        if (status == 'playing')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.redAccent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
            ),
            child: Text(
              "$_secondsLeft ثانية",
              style: const TextStyle(
                color: Colors.redAccent, 
                fontSize: 12, 
                fontWeight: FontWeight.w900,
                fontFamily: DesignTokens.primaryFont,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBombUI(bool isHoldingBomb, String? holderName) {
    return Column(
      children: [
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _shakeController,
          builder: (context, child) {
            double shake = isHoldingBomb ? 5.0 : 1.0;
            return Transform.translate(
              offset: Offset(sin(_shakeController.value * pi * 8) * shake, 0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isHoldingBomb)
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 80),
                  const Icon(Icons.bolt, color: Colors.redAccent, size: 60),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(15),
          ),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: const TextStyle(fontFamily: DesignTokens.primaryFont, fontSize: 14),
              children: [
                const TextSpan(text: "القنبلة مع: ", style: TextStyle(color: Colors.white70)),
                TextSpan(
                  text: holderName ?? '...', 
                  style: const TextStyle(color: DesignTokens.primaryGold, fontWeight: FontWeight.bold)
                ),
              ],
            ),
          ),
        ),
        if (isHoldingBomb) ...[
          const SizedBox(height: 20),
          const Text("مرر القنبلة بسرعة! 🔥", 
            style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 12),
          _buildTransferControls(),
        ],
      ],
    );
  }

  Widget _buildTransferControls() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 40, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
        
        final roomData = snapshot.data!.data() as Map<String, dynamic>;
        
        // جلب المتحدثين من مجموعة فرعية mic_seats
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).collection('mic_seats').snapshots(),
          builder: (context, micSnap) {
            if (!micSnap.hasData) return const SizedBox();
            
            List<Map<String, dynamic>> otherSpeakers = [];
            for (var doc in micSnap.data!.docs) {
              final seat = doc.data() as Map<String, dynamic>;
              if (seat['userId'] != null && seat['userId'] != _myUid) {
                otherSpeakers.add({'uid': seat['userId'], 'name': seat['name'] ?? 'مستخدم'});
              }
            }

            if (otherSpeakers.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(12),
                child: const Text("لا يوجد متحدثون آخرون لنقل القنبلة!", 
                  style: TextStyle(color: Colors.white38, fontSize: 12, fontStyle: FontStyle.italic)),
              );
            }

            return SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: otherSpeakers.length,
                itemBuilder: (context, index) {
                  final s = otherSpeakers[index];
                  return GestureDetector(
                    onTap: () => _transferBomb(s['uid'], s['name']),
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircleAvatar(
                            radius: 20,
                            backgroundColor: Colors.white10,
                            child: Icon(Icons.person, color: Colors.white38),
                          ),
                          const SizedBox(height: 8),
                          Text(s['name'], 
                            maxLines: 1, 
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildExplosionUI(String? loserName) {
    return Column(
      children: [
        const SizedBox(height: 10),
        const Icon(Icons.flash_on, color: Colors.amber, size: 70),
        const SizedBox(height: 16),
        const Text("انفجرت القنبلة في:", 
          style: TextStyle(color: Colors.white70, fontSize: 14, fontFamily: DesignTokens.primaryFont)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
          ),
          child: Text(loserName ?? "أحدهم",
              style: const TextStyle(
                color: Colors.redAccent, 
                fontSize: 22, 
                fontWeight: FontWeight.w900,
                fontFamily: DesignTokens.primaryFont,
              )),
        ),
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
            icon: const Icon(Icons.close_rounded, size: 16, color: Colors.white38),
            label: const Text("إغلاق اللعبة", 
              style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  void _transferBomb(String targetUid, String targetName) async {
    HapticFeedback.mediumImpact();
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

