import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LuckyBoxDialog extends StatefulWidget {
  final String roomId;
  final int userGems;
  final Function(String type, int cost) onPurchase;

  const LuckyBoxDialog({
    super.key,
    required this.roomId,
    required this.userGems,
    required this.onPurchase,
  });

  @override
  State<LuckyBoxDialog> createState() => _LuckyBoxDialogState();
}

class _LuckyBoxDialogState extends State<LuckyBoxDialog> with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late AnimationController _openingController;
  bool _isOpening = false;
  String? _selectedType;
  int? _selectedCost;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _openingController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _openingController.dispose();
    super.dispose();
  }

  void _startOpening(String type, int cost) async {
    if (widget.userGems < cost) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رصيد الجواهر غير كافٍ 💎')));
      return;
    }

    setState(() {
      _selectedType = type;
      _selectedCost = cost;
      _isOpening = true;
    });

    // أنيميشن الاهتزاز (التشويق)
    await _shakeController.repeat(reverse: true);
    await Future.delayed(const Duration(seconds: 2));
    _shakeController.stop();

    // أنيميشن الفتح (الانفجار)
    _openingController.forward();
    
    // إتمام العملية برمجياً
    widget.onPurchase(type, cost);

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _isOpening ? _buildOpeningSequence() : _buildSelectionScreen(),
        ),
      ),
    );
  }

  Widget _buildSelectionScreen() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A242F).withOpacity(0.9),
            const Color(0xFF0F1B25).withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.amber.withOpacity(0.3), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30, spreadRadius: 5)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('صندوق المفاجآت الملكي', style: TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
          const SizedBox(height: 10),
          const Text('اختر صندوقك وجرب حظك في الفوز بهدايا أسطورية', style: TextStyle(color: Colors.white70, fontSize: 12, decoration: TextDecoration.none)),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBoxOption('برونزي', 1000, Colors.brown, Icons.redeem),
              _buildBoxOption('فضي', 5000, Colors.blueGrey, Icons.card_giftcard),
              _buildBoxOption('ذهبي', 10000, Colors.amber, Icons.stars),
            ],
          ),
          const SizedBox(height: 30),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق', style: TextStyle(color: Colors.white24))),
        ],
      ),
    );
  }

  Widget _buildBoxOption(String type, int cost, Color color, IconData icon) {
    return GestureDetector(
      onTap: () => _startOpening(type, cost),
      child: Column(
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [color.withOpacity(0.4), Colors.transparent]),
              boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 15, spreadRadius: 2)],
            ),
            child: Icon(icon, color: color, size: 40),
          ),
          const SizedBox(height: 10),
          Text(type, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14, decoration: TextDecoration.none)),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Text('$cost', style: const TextStyle(color: Colors.amber, fontSize: 10, decoration: TextDecoration.none)),
                const SizedBox(width: 2),
                const Icon(Icons.diamond, color: Colors.cyanAccent, size: 10),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildOpeningSequence() {
    return AnimatedBuilder(
      animation: _openingController,
      builder: (context, child) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // الصندوق المهتز
            Transform.translate(
              offset: Offset(math.sin(_shakeController.value * math.pi * 10) * 5, 0),
              child: Transform.scale(
                scale: 1.0 + (_openingController.value * 2),
                child: Opacity(
                  opacity: (1.0 - _openingController.value).clamp(0.0, 1.0),
                  child: const Icon(Icons.inventory_2, color: Colors.amber, size: 120),
                ),
              ),
            ),
            if (_openingController.value > 0.5)
              FadeTransition(
                opacity: _openingController,
                child: Column(
                  children: [
                    const Icon(Icons.auto_awesome, color: Colors.amber, size: 80),
                    const SizedBox(height: 20),
                    Text('تهانينا! تم فتح الصندوق $_selectedType', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, decoration: TextDecoration.none)),
                    const Text('تم إرسال الهدية بنجاح 🎉', style: TextStyle(color: Colors.amber, fontSize: 14, decoration: TextDecoration.none)),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
