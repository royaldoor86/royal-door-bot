import 'package:flutter/material.dart';
import 'dart:async';

class RoyalGiftAnimation extends StatefulWidget {
  final String giftName;
  final String giftImageUrl;
  final String senderName;
  final String receiverName;
  final int count;
  final VoidCallback onComplete;

  const RoyalGiftAnimation({
    super.key,
    required this.giftName,
    required this.giftImageUrl,
    required this.senderName,
    required this.receiverName,
    required this.count,
    required this.onComplete,
  });

  @override
  State<RoyalGiftAnimation> createState() => _RoyalGiftAnimationState();
}

class _RoyalGiftAnimationState extends State<RoyalGiftAnimation> with TickerProviderStateMixin {
  late AnimationController _entryController;
  late AnimationController _glowController;
  late AnimationController _sparkleController;
  
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    
    _entryController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _glowController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _sparkleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..repeat();

    _scaleAnimation = CurvedAnimation(parent: _entryController, curve: Curves.elasticOut);
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _entryController, curve: const Interval(0.0, 0.5)));
    _rotationAnimation = Tween<double>(begin: -0.2, end: 0.0).animate(CurvedAnimation(parent: _entryController, curve: Curves.easeOut));

    _entryController.forward();

    // Auto-remove after 4 seconds
    Timer(const Duration(seconds: 4), () {
      if (mounted) {
        _entryController.reverse().then((_) => widget.onComplete());
      }
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _glowController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _entryController,
        builder: (context, child) {
          return Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Explosion Glow Effect
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _glowController,
                          builder: (context, _) {
                            return Container(
                              width: 250, height: 250,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.amber.withOpacity(0.6 * _glowController.value),
                                    Colors.orange.withOpacity(0.3 * _glowController.value),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        // Gift Image
                        Container(
                          width: 150, height: 150,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(color: Colors.amber.withOpacity(0.5), blurRadius: 30, spreadRadius: 5)
                            ],
                          ),
                          child: Image.network(
                            widget.giftImageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (c, e, s) => const Icon(Icons.card_giftcard, color: Colors.amber, size: 80),
                          ),
                        ),
                        // Sparkles
                        ...List.generate(8, (index) {
                          return AnimatedBuilder(
                            animation: _sparkleController,
                            builder: (context, _) {
                              double angle = (index * 45) * 3.14 / 180;
                              double offset = 100 + (20 * _sparkleController.value);
                              return Transform.translate(
                                offset: Offset(offset * MediaQuery.of(context).size.width / 400 * (index % 2 == 0 ? 1 : -1) , 0), // Simulating radial movement
                                child: Icon(Icons.star, color: Colors.white.withOpacity(1 - _sparkleController.value), size: 10),
                              );
                            },
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Colors.black87, Color(0xFF1B2B38), Colors.black87]),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.amberAccent, width: 1),
                        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(widget.senderName, style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                              const Text(' أهدى ', style: TextStyle(color: Colors.white70, fontSize: 14)),
                              Text(widget.giftName, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('إلى ', style: TextStyle(color: Colors.white70, fontSize: 14)),
                              Text(widget.receiverName, style: const TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(width: 8),
                              Text('x${widget.count}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.black, fontSize: 20, fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
