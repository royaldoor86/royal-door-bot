import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MicModesSheet extends StatefulWidget {
  final String roomId;
  final String currentMode;

  const MicModesSheet(
      {super.key, required this.roomId, required this.currentMode});

  @override
  State<MicModesSheet> createState() => _MicModesSheetState();
}

class _MicModesSheetState extends State<MicModesSheet> {
  late String _selectedMode;

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.currentMode;
  }

  Future<void> _saveMode() async {
    try {
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .update({'micMode': _selectedMode});
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حفظ نمط المايكات بنجاح ✅')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('فشل في حفظ النمط: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20)
          .copyWith(bottom: MediaQuery.of(context).padding.bottom + 20),
      decoration: const BoxDecoration(
        color: Color(0xFF0F1B25),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        border: Border(top: BorderSide(color: Colors.cyanAccent, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("نمط المايكات",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 15,
            runSpacing: 15,
            children: [
              _buildModeCard("دردشة - 5 مايكات", "chat-5", [5]),
              _buildModeCard("بث - 5 مايكات", "broadcast-5", [1, 4]),
              _buildModeCard("فريق - 10 مايكات", "2-4-4", [2, 4, 4]),
              _buildModeCard("دردشة - 10 مايكات", "normal", [5, 5]),
              _buildModeCard("دردشة - 15 مايك", "chat-15", [5, 5, 5],
                  isLocked: true),
              _buildModeCard("بث - 11 مايك", "broadcast-11", [1, 4, 6]),
            ],
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: _saveMode,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25)),
            ),
            child: const Text("تأكيد",
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard(String title, String mode, List<int> rows,
      {bool isLocked = false}) {
    bool isSelected = _selectedMode == mode;
    return GestureDetector(
      onTap: isLocked ? null : () => setState(() => _selectedMode = mode),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black26,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
              color: isSelected ? Colors.greenAccent : Colors.white10,
              width: 2),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isSelected)
                  const Icon(Icons.check_circle,
                      color: Colors.greenAccent, size: 16),
                if (isLocked)
                  const Icon(Icons.lock, color: Colors.white24, size: 16),
                Expanded(
                  child: Text(title,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isLocked ? Colors.white24 : Colors.white70)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Column(
              children: rows
                  .map((count) => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                            count,
                            (index) => Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: isLocked
                                        ? Colors.white10
                                        : (isSelected
                                            ? Colors.greenAccent
                                            : Colors.white38),
                                    shape: BoxShape.circle,
                                  ),
                                )),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
