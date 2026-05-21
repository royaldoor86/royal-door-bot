import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app_theme.dart';

class LuckyBoxDialog extends StatefulWidget {
  final String roomId;
  final int userGems;
  final int userStars;
  final Function(String type, String currency, int cost, Map<String, dynamic> gift) onPurchase;

  const LuckyBoxDialog({
    super.key,
    required this.roomId,
    required this.userGems,
    required this.userStars,
    required this.onPurchase,
  });

  @override
  State<LuckyBoxDialog> createState() => _LuckyBoxDialogState();
}

class _LuckyBoxDialogState extends State<LuckyBoxDialog>
    with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late AnimationController _openingController;
  late AnimationController _glowController;
  late PageController _pageController;

  int _currentPage = 1;
  bool _isOpening = false;
  Map<String, dynamic>? _wonGift;

  final List<Map<String, dynamic>> _boxes = [
    {
      'type': 'برونزي',
      'cost': 100,
      'currency': 'stars',
      'color': Colors.brown,
      'image': 'assets/images/box_bronze.png'
    },
    {
      'type': 'فضي',
      'cost': 500,
      'currency': 'stars',
      'color': Colors.blueGrey,
      'image': 'assets/images/box_silver.png'
    },
    {
      'type': 'ذهبي',
      'cost': 1000,
      'currency': 'stars',
      'color': Colors.amber,
      'image': 'assets/images/box_gold.png'
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1, viewportFraction: 0.7);
    _shakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _openingController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));
    _glowController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _shakeController.dispose();
    _openingController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  // خوارزمية اختيار هدية عشوائية باحترافية
  Future<Map<String, dynamic>?> _pickRandomGift(int boxCost) async {
    try {
      final giftsSnap = await FirebaseFirestore.instance
          .collection('gifts')
          .where('showInStore', isEqualTo: true)
          .get();

      if (giftsSnap.docs.isEmpty) return null;

      // تصفية الهدايا وتحويلها لقائمة
      List<Map<String, dynamic>> possibleGifts =
          giftsSnap.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();

      // خلط الهدايا واختيار واحدة عشوائياً
      possibleGifts.shuffle();
      return possibleGifts.first;
    } catch (e) {
      return null;
    }
  }

  void _confirmPurchase(Map<String, dynamic> box) async {
    final int cost = box['cost'];
    final String currency = box['currency'];

    if (currency == 'gems' && widget.userGems < cost) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('رصيد الجواهر غير كافٍ لفتح هذا الصندوق 💎'),
          backgroundColor: Colors.redAccent));
      return;
    } else if (currency == 'stars' && widget.userStars < cost) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('رصيد النجوم غير كافٍ لفتح هذا الصندوق ⭐'),
          backgroundColor: Colors.redAccent));
      return;
    }

    _wonGift = await _pickRandomGift(box['cost']);
    if (_wonGift == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('عذراً، الصناديق فارغة حالياً!')));
      return;
    }

    _startOpening(box);
  }

  void _startOpening(Map<String, dynamic> box) async {
    setState(() => _isOpening = true);

    _shakeController.repeat(reverse: true);
    await Future.delayed(const Duration(seconds: 2));
    _shakeController.stop();

    _openingController.forward();

    // تنفيذ عملية الشراء والخصم في الواجهة الخلفية
    widget.onPurchase(box['type'], box['currency'], box['cost'], _wonGift!);

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) Navigator.pop(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: _isOpening ? _buildOpeningSequence() : _buildSelectionScreen(),
        ),
      ),
    );
  }

  Widget _buildSelectionScreen() {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        padding: const EdgeInsets.symmetric(vertical: 25),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0F1B25),
              const Color(0xFF0A121A).withValues(alpha: 0.9)
            ],
          ),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
              color: AppTheme.royalGold.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 30,
                spreadRadius: 5)
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('صندوق المفاجآت الملكي 👑',
                style: TextStyle(
                    color: AppTheme.royalGold,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('رصيدك: ',
                    style: TextStyle(color: Colors.white54, fontSize: 13)),
                Text('${widget.userStars}',
                    style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const Icon(Icons.stars_rounded, color: Colors.amber, size: 14),
                const SizedBox(width: 10),
                Text('${widget.userGems}',
                    style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const Icon(Icons.diamond, color: Colors.cyanAccent, size: 14),
              ],
            ),
            const SizedBox(height: 25),
            SizedBox(
              height: 220,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _boxes.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (context, index) {
                  bool isSelected = _currentPage == index;
                  return _buildBoxItem(_boxes[index], isSelected);
                },
              ),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: () => _confirmPurchase(_boxes[_currentPage]),
              style: ElevatedButton.styleFrom(
                backgroundColor: _boxes[_currentPage]['color'],
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 60, vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
                elevation: 10,
                shadowColor:
                    _boxes[_currentPage]['color'].withValues(alpha: 0.5),
              ),
              child: const Text('افتح الصندوق الآن',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'نسب الفوز: هدايا عادية (%80)، هدايا نادرة (%15)، هدايا ملكية (%5).',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white24, fontSize: 10),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Text('ربما لاحقاً',
                  style: TextStyle(color: Colors.white24, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoxItem(Map<String, dynamic> box, bool isSelected) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 300),
      scale: isSelected ? 1.1 : 0.8,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (isSelected)
                AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, _) => Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                            color: box['color'].withValues(
                                alpha: (0.4 * _glowController.value)
                                    .clamp(0.0, 1.0)),
                            blurRadius: 20,
                            spreadRadius: 10),
                      ],
                    ),
                  ),
                ),
              const Icon(Icons.inventory_2_rounded,
                  size: 120, color: Colors.white10),
              Image.asset(
                box['image'],
                width: 140,
                height: 140,
                errorBuilder: (c, e, s) => Icon(Icons.auto_awesome_motion,
                    color: box['color'], size: 100),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(box['type'],
              style: TextStyle(
                  color: box['color'],
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${box['cost']}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  Icon(
                      box['currency'] == 'gems'
                          ? Icons.diamond
                          : Icons.stars_rounded,
                      color: box['currency'] == 'gems'
                          ? Colors.cyanAccent
                          : Colors.amber,
                      size: 14),
                ],
              ),
        ],
      ),
    );
  }

  Widget _buildOpeningSequence() {
    return AnimatedBuilder(
        animation: _openingController,
        builder: (context, _) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _shakeController,
                builder: (context, child) {
                  final double offset =
                      math.sin(_shakeController.value * math.pi * 15) * 10;
                  return Transform.translate(
                    offset: Offset(offset, 0),
                    child: child,
                  );
                },
                child: Image.asset(_boxes[_currentPage]['image'],
                    width: 180,
                    height: 180,
                    errorBuilder: (c, e, s) => const Icon(Icons.card_giftcard,
                        color: Colors.amber, size: 100)),
              ),
              const SizedBox(height: 40),
              if (_openingController.value > 0.1)
                FadeTransition(
                  opacity: _openingController,
                  child: Column(
                    children: [
                      const Text('جاري سحب جائزتك...',
                          style: TextStyle(
                              color: Colors.amber,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.none)),
                      const SizedBox(height: 20),
                      if (_wonGift != null) ...[
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle),
                          child: CachedNetworkImage(
                            imageUrl: _wonGift!['imageUrl'],
                            width: 100,
                            height: 100,
                            placeholder: (c, u) =>
                                const CircularProgressIndicator(
                                    color: AppTheme.royalGold),
                            errorWidget: (c, u, e) => const Icon(
                                Icons.broken_image,
                                color: Colors.white24,
                                size: 50),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text('لقد فزت بـ ${_wonGift!['name']}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.none)),
                      ],
                    ],
                  ),
                ),
            ],
          );
        });
  }
}
