import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../features/profile/daily_rewards_page.dart';

class DailyRewardPopup extends StatelessWidget {
  final Map<String, dynamic> nextReward;
  const DailyRewardPopup({super.key, required this.nextReward});

  static void show(BuildContext context, Map<String, dynamic> reward) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withValues(alpha: 0.75),
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => DailyRewardPopup(nextReward: reward),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 45),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(35),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.12),
                    Colors.white.withValues(alpha: 0.03),
                  ],
                ),
                borderRadius: BorderRadius.circular(35),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  )
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Enhanced Icon Area
                    _buildAnimatedIcon(),
                    const SizedBox(height: 25),
                    const Text(
                      'الكنز اليومي جاهز!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'مكافأة اليوم ${nextReward['day']} بانتظارك',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 25),
                    // Refined Reward Preview
                    _buildRewardBox(),
                    const SizedBox(height: 30),
                    // Action Button
                    _buildActionButton(context),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(100, 40),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      child: Text(
                        'لاحقاً',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedIcon() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutBack,
      builder: (context, double value, child) {
        return Transform.scale(
          scale: value,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Glow Effect
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.2 * value),
                      blurRadius: 25,
                      spreadRadius: 5,
                    )
                  ],
                ),
              ),
              // Background Circles
              Container(
                width: 85,
                height: 85,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amber.withValues(alpha: 0.08),
                  border: Border.all(
                    color: Colors.amber.withValues(alpha: 0.2),
                    width: 2,
                  ),
                ),
              ),
              // Main Icon
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.amber, Colors.orangeAccent],
                ).createShader(bounds),
                child: const Icon(
                  Icons.card_giftcard_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRewardBox() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.8, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.elasticOut,
      builder: (context, double scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.amber.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    nextReward['val'].toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _buildRewardIcon(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRewardIcon() {
    final String type = nextReward['type'] ?? 'star';
    final bool isMixed = type == 'mixed';
    final bool isGem = type == 'gem';

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: (isGem ? Colors.cyan : Colors.amber).withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(
        isMixed
            ? Icons.auto_awesome_rounded
            : (isGem ? Icons.diamond_rounded : Icons.stars_rounded),
        color: isGem ? Colors.cyanAccent : Colors.amber,
        size: 24,
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Colors.amber, Color(0xFFFFB300)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DailyRewardsPage()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: const Text(
          'اذهب للاستلام الآن',
          style: TextStyle(
            color: Colors.black,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            fontFamily: 'Cairo',
          ),
        ),
      ),
    );
  }
}
