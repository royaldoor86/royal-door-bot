import 'package:flutter/material.dart';
import 'mic_modes_sheet.dart';

class RoomSettingsSheet extends StatefulWidget {
  const RoomSettingsSheet({super.key});

  @override
  State<RoomSettingsSheet> createState() => _RoomSettingsSheetState();
}

class _RoomSettingsSheetState extends State<RoomSettingsSheet> {
  bool _noiseReduction = true;
  bool _eyeComfort = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Color(0xFF0F1A24),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildTopActions(),
            const SizedBox(height: 20),
            _buildSectionHeader("إعدادات الغرفة"),
            _buildGrid(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildTopActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildActionItem(Icons.reply, "مشاركة"),
          _buildActionItem(Icons.report_problem_outlined, "مشكلات الصوت"),
          _buildToggleItem(Icons.waves, "تقليل الضوضاء", _noiseReduction, (v) => setState(() => _noiseReduction = v)),
          _buildActionItem(Icons.card_giftcard, "إعدادات الهدايا"),
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label) {
    return Column(children: [Icon(icon, color: Colors.cyan, size: 28), const SizedBox(height: 6), Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10))]);
  }

  Widget _buildToggleItem(IconData icon, String label, bool value, Function(bool) onChanged) {
    return Column(
      children: [
        Icon(icon, color: Colors.cyan, size: 28),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        Transform.scale(scale: 0.7, child: Switch(value: value, onChanged: onChanged, activeColor: Colors.green)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(alignment: Alignment.centerRight, child: Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5), decoration: const BoxDecoration(color: Color(0xFF1B2B38), borderRadius: BorderRadius.only(topLeft: Radius.circular(15), bottomLeft: Radius.circular(15))), child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))));
  }

  Widget _buildGrid() {
    return GridView.count(
      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 4, mainAxisSpacing: 20,
      children: [
        _buildGridItem(Icons.mic, "نمط المايكات", Colors.amber, onTap: () => _showMicModes(context)),
        _buildGridItem(Icons.lock, "قفل الغرفة", Colors.amber),
        _buildGridItem(Icons.palette, "موضوع", Colors.orange),
        _buildGridItem(Icons.settings, "الإعدادات", Colors.grey),
      ],
    );
  }

  Widget _buildGridItem(IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return GestureDetector(onTap: onTap, child: Column(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.black26, shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)), const SizedBox(height: 6), Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 10))]));
  }

  void _showMicModes(BuildContext context) {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) => const MicModesSheet());
  }
}
