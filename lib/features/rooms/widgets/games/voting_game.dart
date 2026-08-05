import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';
import '../../../../theme/design_tokens.dart';

class VotingGame extends StatefulWidget {
  final String roomId;
  final Map<String, dynamic> gameData;
  final bool hasPower;

  const VotingGame({
    super.key,
    required this.roomId,
    required this.gameData,
    required this.hasPower,
  });

  @override
  State<VotingGame> createState() => _VotingGameState();
}

class _VotingGameState extends State<VotingGame> {
  final String _myUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void dispose() {
    _questionController.dispose();
    for (var c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String status = widget.gameData['status'] ?? 'setup';

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
                Colors.black.withValues(alpha: 0.75),
                const Color(0xFF0F1B25).withValues(alpha: 0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: DesignTokens.primaryGold.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 15,
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              if (status == 'setup') _buildSetupUI(),
              if (status == 'voting' || status == 'ended') _buildVotingUI(status),
              const SizedBox(height: 12),
              _buildFooter(status),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.how_to_vote_rounded, color: DesignTokens.primaryGold, size: 20),
        SizedBox(width: 10),
        Text("نظام التصويت الملكي",
            style: TextStyle(
              color: Colors.white, 
              fontSize: 16, 
              fontWeight: FontWeight.bold,
              fontFamily: DesignTokens.primaryFont,
            )),
      ],
    );
  }

  Widget _buildSetupUI() {
    if (!widget.hasPower) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: const Column(
          children: [
            Icon(Icons.hourglass_empty_rounded, color: Colors.amber, size: 40),
            SizedBox(height: 12),
            Text("بانتظار المشرف لبدء التصويت... ⏳",
                style: TextStyle(color: Colors.white70, fontSize: 13, fontStyle: FontStyle.italic)),
          ],
        ),
      );
    }

    return Column(
      children: [
        TextField(
          controller: _questionController,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: "ما هو موضوع التصويت؟",
            hintStyle: const TextStyle(color: Colors.white30, fontSize: 13),
            filled: true,
            isDense: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Colors.white10),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: DesignTokens.primaryGold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(_optionControllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              controller: _optionControllers[index],
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: "الخيار ${index + 1}",
                hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
                filled: true,
                isDense: true,
                prefixIcon: const Icon(Icons.circle, color: Colors.amber, size: 8),
                fillColor: Colors.white.withValues(alpha: 0.03),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          );
        }),
        if (_optionControllers.length < 4)
          TextButton.icon(
            onPressed: () => setState(() => _optionControllers.add(TextEditingController())),
            icon: const Icon(Icons.add_circle_outline, size: 16),
            label: const Text("إضافة خيار آخر", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            style: TextButton.styleFrom(foregroundColor: DesignTokens.primaryGold),
          ),
      ],
    );
  }

  Widget _buildVotingUI(String status) {
    String question = widget.gameData['question'] ?? '';
    List<dynamic> options = widget.gameData['options'] ?? [];
    Map<String, dynamic> votes = widget.gameData['votes'] ?? {};
    int? myVote = votes[_myUid];
    int totalVotes = votes.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: DesignTokens.primaryGold.withValues(alpha: 0.1)),
          ),
          child: Text(question,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: DesignTokens.primaryGold, 
                fontSize: 15, 
                fontWeight: FontWeight.bold,
                fontFamily: DesignTokens.primaryFont,
              )),
        ),
        const SizedBox(height: 20),
        ...List.generate(options.length, (index) {
          int count = votes.values.where((v) => v == index).length;
          double percent = totalVotes == 0 ? 0 : count / totalVotes;
          bool isSelected = myVote == index;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: status == 'voting' ? () => _castVote(index) : null,
              child: Stack(
                children: [
                  Container(
                    height: 44,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? DesignTokens.primaryGold : Colors.white10,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    height: 44,
                    width: (MediaQuery.of(context).size.width - 64) * percent,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          DesignTokens.primaryGold.withValues(alpha: 0.3),
                          DesignTokens.primaryGold.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(options[index],
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: isSelected ? Colors.white : Colors.white70,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text("${(percent * 100).toInt()}%",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            Text("$count صوت",
                                style: const TextStyle(color: Colors.white38, fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isSelected && status == 'voting')
                    const Positioned(
                      left: -10,
                      top: -10,
                      child: Icon(Icons.check_circle, color: DesignTokens.primaryGold, size: 20),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFooter(String status) {
    if (status == 'setup' && widget.hasPower) {
      return Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: const LinearGradient(colors: [DesignTokens.primaryGold, DesignTokens.primaryGoldLight]),
        ),
        child: ElevatedButton(
          onPressed: _startVoting,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          child: const Text("بدء التصويت الآن 🚀", 
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14)),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (status == 'voting' && widget.hasPower)
          ElevatedButton(
            onPressed: _endVoting,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.withValues(alpha: 0.1),
              foregroundColor: Colors.amber,
              side: const BorderSide(color: Colors.amber),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text("إنهاء التصويت", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        const SizedBox(width: 12),
        TextButton(
          onPressed: _closeGame,
          child: const Text("إغلاق", style: TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  void _startVoting() async {
    String question = _questionController.text.trim();
    List<String> options = _optionControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (question.isEmpty || options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("يرجى إدخال سؤال وخيارين على الأقل")));
      return;
    }

    await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
      'activeGame.status': 'voting',
      'activeGame.question': question,
      'activeGame.options': options,
      'activeGame.votes': {},
    });
  }

  void _castVote(int index) async {
    HapticFeedback.lightImpact();
    await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
      'activeGame.votes.$_myUid': index,
    });
  }

  void _endVoting() async {
    await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
      'activeGame.status': 'ended',
    });
  }

  void _closeGame() async {
    await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
      'activeGame': FieldValue.delete(),
    });
  }
}

