import 'package:flutter/material.dart';

class MicModesSheet extends StatelessWidget {
  const MicModesSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFFE0F2F1), // خلفية فاتحة كما في الصورة
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("نمط المايكات", style: TextStyle(color: Color(0xFF004D40), fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 15,
            runSpacing: 15,
            children: [
              _buildModeCard("دردشة - 5 مايكات", false),
              _buildModeCard("بث - 5 مايكات", false),
              _buildModeCard("فريق - 10 مايكات", false),
              _buildModeCard("دردشة - 10 مايكات", true), // المختار
              _buildModeCard("دردشة - 15 مايك", false, isLocked: true),
              _buildModeCard("بث - 11 مايك", false),
            ],
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
            ),
            child: const Text("تأكيد", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard(String title, bool isSelected, {bool isLocked = false}) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isSelected ? const Color(0xFF00BFA5) : Colors.transparent, width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF00BFA5), size: 16),
              if (isLocked) const Icon(Icons.lock, color: Colors.grey, size: 16),
              Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          const Icon(Icons.grid_view, color: Color(0xFFB2DFDB), size: 40),
        ],
      ),
    );
  }
}
