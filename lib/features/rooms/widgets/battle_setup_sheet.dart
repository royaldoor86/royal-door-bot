import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BattleSetupSheet extends StatefulWidget {
  final String roomId;
  const BattleSetupSheet({super.key, required this.roomId});

  @override
  State<BattleSetupSheet> createState() => _BattleSetupSheetState();
}

class _BattleSetupSheetState extends State<BattleSetupSheet> {
  int _selectedDuration = 5;
  String _selectedTeam = 'none'; // 'none', 'red', 'blue'

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1F26),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  'معركة بين الأحمر والأزرق، وسيكون صاحب قيمة PK الأعلى هو الفائز!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 20),
                _buildTeamPreview(),
                const SizedBox(height: 30),
                _buildDurationSelection(),
                const SizedBox(height: 30),
                _buildTeamSelection(),
                const SizedBox(height: 40),
                _buildStartButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue, Colors.purple, Colors.red]),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Stack(
        children: [
          const Center(
            child: Text(
              'معركة الفريق',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Positioned(
            left: 15,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Icon(Icons.help_outline, color: Colors.white),
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
        _buildMiniTeam(Colors.blue, 4),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Icon(Icons.flash_on, color: Colors.amber, size: 40),
        ),
        _buildMiniTeam(Colors.red, 4),
      ],
    );
  }

  Widget _buildMiniTeam(Color color, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: List.generate(count, (index) => 
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(Icons.chair, color: color, size: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildDurationSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text('الوقت لكل جولة', style: TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [30, 15, 5].map((d) => Padding(
            padding: const EdgeInsets.only(left: 10),
            child: ChoiceChip(
              label: Text('$d دقيقة', style: TextStyle(color: _selectedDuration == d ? Colors.white : Colors.white70)),
              selected: _selectedDuration == d,
              onSelected: (selected) {
                if (selected) setState(() => _selectedDuration = d);
              },
              selectedColor: Colors.green,
              backgroundColor: Colors.white10,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildTeamSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text('سأنضم إلى', style: TextStyle(color: Colors.white, fontSize: 16)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _teamRadio('الفريق الأزرق', 'blue'),
            _teamRadio('الفريق الأحمر', 'red'),
            _teamRadio('ولا واحد', 'none'),
          ],
        ),
      ],
    );
  }

  Widget _teamRadio(String label, String value) {
    return GestureDetector(
      onTap: () => setState(() => _selectedTeam = value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          Radio<String>(
            value: value,
            groupValue: _selectedTeam,
            onChanged: (v) => setState(() => _selectedTeam = v!),
            activeColor: Colors.green,
          ),
        ],
      ),
    );
  }

  void _startBattle() async {
    final startTime = DateTime.now();
    final endTime = startTime.add(Duration(minutes: _selectedDuration));

    await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
      'battle': {
        'active': true,
        'startTime': startTime,
        'endTime': endTime,
        'redPoints': 0,
        'bluePoints': 0,
        'duration': _selectedDuration,
      }
    });

    if (mounted) Navigator.pop(context);
  }

  Widget _buildStartButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        ),
        onPressed: _startBattle,
        child: const Text('موافق', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
