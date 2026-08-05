import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../theme/design_tokens.dart';

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
  late AnimationController _floatController;
  late PageController _pageController;

  int _currentPage = 1;
  bool _isOpening = false;
  bool _isRevealed = false;
  Map<String, dynamic>? _wonGift;

  final List<Map<String, dynamic>> _boxes = [
    {
      'type': 'صندوق برونزي',
      'cost': 100,
      'currency': 'stars',
      'color': const Color(0xFFCD7F32),
      'image': 'assets/images/box_bronze.png',
      'icon': Icons.inventory_2_outlined,
      'gradient': [const Color(0xFF8B4513), const Color(0xFFCD7F32)],
    },
    {
      'type': 'صندوق فضي',
      'cost': 500,
      'currency': 'stars',
      'color': const Color(0xFFC0C0C0),
      'image': 'assets/images/box_silver.png',
      'icon': Icons.inventory_2_rounded,
      'gradient': [const Color(0xFF708090), const Color(0xFFC0C0C0)],
    },
    {
      'type': 'صندوق ذهبي',
      'cost': 1000,
      'currency': 'stars',
      'color': const Color(0xFFFFD700),
      'image': 'assets/images/box_gold.png',
      'icon': Icons.auto_awesome,
      'gradient': [const Color(0xFFDAA520), const Color(0xFFFFD700)],
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1, viewportFraction: 0.75);
    _shakeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _openingController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000));
    _glowController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _floatController =
        AnimationController(vsync: this, duration: const Duration(seconds: 3))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _shakeController.dispose();
    _openingController.dispose();
    _glowController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _pickRandomGift(int boxCost) async {
    try {
      final giftsSnap = await FirebaseFirestore.instance
          .collection('gifts')
          .where('showInStore', isEqualTo: true)
          .get();

      if (giftsSnap.docs.isEmpty) return null;

      List<Map<String, dynamic>> possibleGifts =
          giftsSnap.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();

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
      _showError('رصيد الجواهر غير كافٍ 💎');
      return;
    } else if (currency == 'stars' && widget.userStars < cost) {
      _showError('رصيد الكوينز غير كافٍ ⭐');
      return;
    }

    HapticFeedback.heavyImpact();
    _wonGift = await _pickRandomGift(box['cost']);
    if (_wonGift == null) {
      _showError('حدث خطأ في السحب، حاول لاحقاً');
      return;
    }

    _startOpening(box);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: DesignTokens.primaryFont)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))));
  }

  void _startOpening(Map<String, dynamic> box) async {
    setState(() => _isOpening = true);

    _shakeController.repeat(reverse: true);
    await Future.delayed(const Duration(seconds: 1));
    _shakeController.stop();

    _openingController.forward();
    
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() => _isRevealed = true);
      HapticFeedback.vibrate();
    }

    widget.onPurchase(box['type'], box['currency'], box['cost'], _wonGift!);

    await Future.delayed(const Duration(seconds: 4));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 600),
          switchInCurve: Curves.easeInOutBack,
          child: _isOpening ? _buildOpeningSequence() : _buildSelectionScreen(),
        ),
      ),
    );
  }

  Widget _buildSelectionScreen() {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.92,
        padding: const EdgeInsets.symmetric(vertical: 30),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F1B25), Color(0xFF051211)],
          ),
          borderRadius: BorderRadius.circular(35),
          border: Border.all(
              color: DesignTokens.primaryGold.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.7),
                blurRadius: 30,
                spreadRadius: 5)
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                const Opacity(
                  opacity: 0.05,
                  child: Icon(Icons.stars,
                      color: DesignTokens.primaryGold, size: 100),
                ),
                Column(
                  children: [
                    const Text('صندوق الحظ الملكي',
                        style: TextStyle(
                            color: DesignTokens.primaryGold,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            fontFamily: DesignTokens.primaryFont,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Container(
                      width: 60,
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Colors.transparent, DesignTokens.primaryGold, Colors.transparent]),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildBalanceHeader(),
            const SizedBox(height: 30),
            SizedBox(
              height: 300,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _boxes.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (context, index) {
                  return _buildBoxItem(_boxes[index], _currentPage == index);
                },
              ),
            ),
            const SizedBox(height: 30),
            _buildActionButtons(),
            const SizedBox(height: 20),
            const Text(
              'افتح الصندوق واكتشف الهدايا الملكية النادرة 🎁✨',
              style: TextStyle(color: Colors.white24, fontSize: 10, fontFamily: DesignTokens.primaryFont),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _balanceItem(widget.userStars, Icons.stars_rounded, DesignTokens.primaryGold),
          Container(width: 1, height: 15, color: Colors.white10, margin: const EdgeInsets.symmetric(horizontal: 12)),
          _balanceItem(widget.userGems, Icons.diamond, Colors.cyanAccent),
        ],
      ),
    );
  }

  Widget _balanceItem(int val, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Text('$val', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildBoxItem(Map<String, dynamic> box, bool isSelected) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        double float = isSelected ? math.sin(_floatController.value * math.pi * 2) * 10 : 0;
        return Transform.translate(
          offset: Offset(0, float),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 600),
            scale: isSelected ? 1.0 : 0.75,
            curve: Curves.easeOutBack,
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isSelected)
                      AnimatedBuilder(
                        animation: _glowController,
                        builder: (context, _) => Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                  color: box['color'].withValues(alpha: 0.25 * _glowController.value),
                                  blurRadius: 40,
                                  spreadRadius: 15),
                            ],
                          ),
                        ),
                      ),
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [box['color'].withValues(alpha: 0.15), Colors.transparent]
                        ),
                        shape: BoxShape.circle,
                      ),
                    ),
                    Image.asset(
                      box['image'],
                      width: 130,
                      height: 130,
                      errorBuilder: (c, e, s) => Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: box['color'].withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: box['color'].withValues(alpha: 0.3)),
                        ),
                        child: Icon(box['icon'], color: box['color'], size: 70),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(box['type'],
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: DesignTokens.primaryFont,
                        shadows: [Shadow(color: box['color'], blurRadius: 10)])),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: box['color'].withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${box['cost']}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                      const SizedBox(width: 6),
                      Icon(box['currency'] == 'gems' ? Icons.diamond : Icons.stars_rounded,
                          color: box['currency'] == 'gems' ? Colors.cyanAccent : DesignTokens.primaryGold, size: 14),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildActionButtons() {
    final box = _boxes[_currentPage];
    return Column(
      children: [
        GestureDetector(
          onTap: () => _confirmPurchase(box),
          child: AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Container(
                width: 260,
                height: 58,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: box['gradient'] as List<Color>,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: box['color'].withValues(alpha: 0.4 * _glowController.value),
                      blurRadius: 20,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: const Center(
                  child: Text('افتح الآن 🗝️',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18, fontFamily: DesignTokens.primaryFont)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 15),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ربما لاحقاً', style: TextStyle(color: Colors.white24, fontSize: 15, fontFamily: DesignTokens.primaryFont)),
        ),
      ],
    );
  }

  Widget _buildOpeningSequence() {
    final box = _boxes[_currentPage];
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withValues(alpha: 0.95),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_isRevealed)
            TweenAnimationBuilder<double>(
              duration: const Duration(seconds: 2),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Container(
                  width: MediaQuery.of(context).size.width * 2 * value,
                  height: MediaQuery.of(context).size.width * 2 * value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        box['color'].withValues(alpha: 0.5 * (1 - value)),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),

          if (!_isRevealed)
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _shakeController,
                  builder: (context, child) {
                    final double offset = math.sin(_shakeController.value * math.pi * 15) * 15;
                    return Transform.translate(
                      offset: Offset(offset, 0),
                      child: child,
                    );
                  },
                  child: Image.asset(box['image'],
                      width: 240,
                      height: 240,
                      errorBuilder: (c, e, s) =>
                          Icon(box['icon'], color: box['color'], size: 160)),
                ),
                const SizedBox(height: 40),
                const Text('جاري فتح الصندوق الملكي...',
                    style: TextStyle(
                        color: DesignTokens.primaryGold,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: DesignTokens.primaryFont,
                        decoration: TextDecoration.none)),
              ],
            ),

          if (_isRevealed && _wonGift != null)
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1500),
              tween: Tween(begin: 0.0, end: 1.0),
              curve: Curves.elasticOut,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value.clamp(0, 1),
                  child: Transform.scale(
                    scale: 0.3 + (0.7 * value),
                    child: child,
                  ),
                );
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Center(
                    child: CachedNetworkImage(
                      imageUrl: _wonGift!['imageUrl'],
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: MediaQuery.of(context).size.height * 0.5,
                      fit: BoxFit.contain,
                      placeholder: (c, u) => const CircularProgressIndicator(color: DesignTokens.primaryGold),
                    ),
                  ),
                  const Positioned(
                    top: 100,
                    child: Column(
                      children: [
                        Text('تهانينا! 🎉',
                            style: TextStyle(
                                color: DesignTokens.primaryGold,
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                fontFamily: DesignTokens.primaryFont,
                                decoration: TextDecoration.none,
                                shadows: [Shadow(color: Colors.black, blurRadius: 20)])),
                        SizedBox(height: 8),
                        Text('لقد حصلت على هدية ملكية فخمة',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: DesignTokens.primaryFont,
                                decoration: TextDecoration.none)),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 120,
                    child: Column(
                      children: [
                        Text(_wonGift!['name'] ?? 'هدية ملكية',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                fontFamily: DesignTokens.primaryFont,
                                decoration: TextDecoration.none)),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [DesignTokens.primaryGold, DesignTokens.primaryGoldLight]),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
                          ),
                          child: const Text('تمت الإضافة لحقيبتك 🎒',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: DesignTokens.primaryFont,
                                  decoration: TextDecoration.none)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  static Shader _goldGradient(Rect bounds) {
    return const LinearGradient(
      colors: [Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFFFD700)],
    ).createShader(bounds);
  }
}
