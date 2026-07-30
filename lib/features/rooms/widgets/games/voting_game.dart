import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A242F).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.3), width: 2),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 15)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          if (status == 'setup') _buildSetupUI(),
          if (status == 'voting' || status == 'ended') _buildVotingUI(status),
          const SizedBox(height: 20),
          _buildFooter(status),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.how_to_vote, color: Colors.purpleAccent),
        SizedBox(width: 10),
        Text("نظام التصويت الملكي 🗳️",
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSetupUI() {
    if (!widget.hasPower) {
      return const Center(
        child: Text("بانتظار المشرف لبدء التصويت... ⏳",
            style: TextStyle(color: Colors.white70)),
      );
    }

    return Column(
      children: [
        TextField(
          controller: _questionController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "ما هو موضوع التصويت؟",
            hintStyle: const TextStyle(color: Colors.white30),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 15),
        ...List.generate(_optionControllers.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TextField(
              controller: _optionControllers[index],
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "الخيار ${index + 1}",
                hintStyle: const TextStyle(color: Colors.white30),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          );
        }),
        if (_optionControllers.length < 4)
          TextButton.icon(
            onPressed: () => setState(() => _optionControllers.add(TextEditingController())),
            icon: const Icon(Icons.add, color: Colors.purpleAccent),
            label: const Text("إضافة خيار", style: TextStyle(color: Colors.purpleAccent)),
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
        Text(question,
            style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
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
                    height: 45,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? Colors.purpleAccent : Colors.white10,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    height: 45,
                    width: MediaQuery.of(context).size.width * percent * 0.7, // Adjust based on parent
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Container(
                    height: 45,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(options[index],
                            style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        Text("${(percent * 100).toInt()}% ($count)",
                            style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
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
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _startVoting,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.purple,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          ),
          child: const Text("بدء التصويت الآن", style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (status == 'voting' && widget.hasPower)
          TextButton(
            onPressed: _endVoting,
            child: const Text("إنهاء وإظهار النتائج", style: TextStyle(color: Colors.amber)),
          ),
        TextButton(
          onPressed: _closeGame,
          child: const Text("إغلاق اللعبة", style: TextStyle(color: Colors.redAccent)),
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
