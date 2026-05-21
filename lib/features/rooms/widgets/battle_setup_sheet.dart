import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BattleSetupSheet extends StatefulWidget {
  final String roomId;
  const BattleSetupSheet({super.key, required this.roomId});

  @override
  State<BattleSetupSheet> createState() => _BattleSetupSheetState();
}

class _BattleSetupSheetState extends State<BattleSetupSheet> {
  int _selectedDuration = 5;
  String _battleMode = 'team'; // 'team' or 'individual'
  String? _selectedRivalId;
  String? _selectedRivalName;
  String? _selectedRivalImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F1B25),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(top: BorderSide(color: Colors.amber, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  _buildModeSelection(),
                  const SizedBox(height: 25),
                  if (_battleMode == 'team') ...[
                    const Text(
                      'معركة ملكية بين الأحمر والأزرق 🔥\nتعتمد على المقاعد (فردي ضد زوجي)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    _buildTeamPreview(),
                  ] else ...[
                    const Text(
                      'تحدي فردي 1 ضد 1 ⚔️\nاختر خصمك من الموجودين في الغرفة الآن',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                    ),
                    const SizedBox(height: 20),
                    _buildRivalSelection(),
                  ],
                  const SizedBox(height: 30),
                  _buildSectionTitle('الوقت لكل جولة'),
                  const SizedBox(height: 15),
                  _buildDurationSelection(),
                  const SizedBox(height: 40),
                  _buildStartButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelection() {
    return Row(
      children: [
        _modeTab('معركة الفريق', 'team', Icons.groups),
        const SizedBox(width: 10),
        _modeTab('تحدي 1 ضد 1', 'individual', Icons.person),
      ],
    );
  }

  Widget _modeTab(String title, String mode, IconData icon) {
    bool isSelected = _battleMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _battleMode = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.amber.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: isSelected ? Colors.amber : Colors.white10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.amber : Colors.white38, size: 18),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: isSelected ? Colors.amber : Colors.white38, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRivalSelection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).collection('online_users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const CircularProgressIndicator();
        final users = snapshot.data!.docs.where((doc) => doc.id != FirebaseAuth.instance.currentUser?.uid).toList();
        
        if (users.isEmpty) {
          return const Text('لا يوجد مستخدمون آخرون في الغرفة حالياً', style: TextStyle(color: Colors.white38, fontSize: 12));
        }

        return SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index].data() as Map<String, dynamic>;
              final uid = users[index].id;
              bool isSelected = _selectedRivalId == uid;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedRivalId = uid;
                    _selectedRivalName = user['name'] ?? 'مستخدم';
                    _selectedRivalImage = user['profilePic'] ?? '';
                  });
                },
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: user['profilePic'] != null && user['profilePic'] != '' 
                                ? NetworkImage(user['profilePic']) 
                                : null,
                            child: user['profilePic'] == null || user['profilePic'] == '' 
                                ? const Icon(Icons.person, color: Colors.white) 
                                : null,
                          ),
                          if (isSelected)
                            const Positioned(
                              right: 0, bottom: 0,
                              child: CircleAvatar(radius: 10, backgroundColor: Colors.green, child: Icon(Icons.check, size: 12, color: Colors.white)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(user['name'] ?? '...', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isSelected ? Colors.amber : Colors.white70, fontSize: 10)),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(title, style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(width: 10),
        Container(width: 4, height: 16, decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(2))),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade800, Colors.purple.shade900, Colors.red.shade800],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10)],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Text(
            'تجهيز المعركة الملكية ⚔️',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Positioned(
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.close, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamPreview() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildVisualTeam(Colors.blue, Icons.shield_rounded, 'الأزرق'),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Icon(Icons.bolt, color: Colors.amber, size: 50),
              Text('VS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24, fontStyle: FontStyle.italic)),
            ],
          ),
        ),
        _buildVisualTeam(Colors.red, Icons.shield_rounded, 'الأحمر'),
      ],
    );
  }

  Widget _buildVisualTeam(Color color, IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.1)]),
            border: Border.all(color: color, width: 2),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Icon(icon, color: color, size: 45),
        ),
        const SizedBox(height: 10),
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }

  Widget _buildDurationSelection() {
    return Row(
      children: [30, 15, 5].map((d) {
        bool isSelected = _selectedDuration == d;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedDuration = d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 5),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: isSelected ? const LinearGradient(colors: [Colors.amber, Colors.orange]) : null,
                color: isSelected ? null : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: isSelected ? Colors.white : Colors.white10),
                boxShadow: isSelected ? [BoxShadow(color: Colors.orange.withValues(alpha: 0.3), blurRadius: 10)] : [],
              ),
              child: Center(
                child: Text(
                  '$d دقيقة',
                  style: TextStyle(color: isSelected ? Colors.black : Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _startBattle() async {
    if (_battleMode == 'individual' && _selectedRivalId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى اختيار الخصم أولاً!')));
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final startTime = DateTime.now();
    final endTime = startTime.add(Duration(minutes: _selectedDuration));

    await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
      'battle': {
        'active': true,
        'mode': _battleMode,
        'startTime': startTime,
        'endTime': endTime,
        'redPoints': 0,
        'bluePoints': 0,
        'redPool': 0, 
        'bluePool': 0, 
        'duration': _selectedDuration,
        'starterId': currentUser.uid,
        'redId': currentUser.uid, // في الفردي، البادئ هو الأحمر
        'blueId': _battleMode == 'individual' ? _selectedRivalId : null,
        'redName': currentUser.displayName ?? 'مستخدم',
        'blueName': _battleMode == 'individual' ? _selectedRivalName : 'الفريق الأزرق',
        'redImage': currentUser.photoURL ?? '',
        'blueImage': _battleMode == 'individual' ? _selectedRivalImage : '',
      }
    });

    // إرسال إشعار في الدردشة
    await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).collection('chat').add({
      'senderId': 'system',
      'senderName': 'نظام',
      'text': '⚔️ بدأت الآن معركة ${_battleMode == 'team' ? 'الفريق' : 'التحدي الفردي'}! ${_battleMode == 'individual' ? 'بين ${currentUser.displayName} و $_selectedRivalName' : ''}',
      'isSystem': true,
      'timestamp': FieldValue.serverTimestamp(),
    });

    if (mounted) Navigator.pop(context);
  }

  Widget _buildStartButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [Colors.green, Colors.teal]),
        boxShadow: [BoxShadow(color: Colors.green.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        onPressed: _startBattle,
        child: const Text('بدء التحدي الملكي ⚔️', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
