import 'package:flutter/material.dart';
import '../../app_theme.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            // استخدام الخلفية الملكية الزرقاء الموحدة
            AppTheme.background(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // الشعار بلمسة توهج ذهبي
                    Container(
                      width: 180, height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: AppTheme.royalGold.withValues(alpha: 0.3), blurRadius: 40, spreadRadius: 5),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.stars_rounded, size: 100, color: AppTheme.royalGold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      'Royal Door',
                      style: TextStyle(fontSize: 55, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 3, fontFamily: 'Serif'),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'أهلاً بكم في عالم النخبة والملوك',
                      style: TextStyle(fontSize: 18, color: Colors.white54, fontWeight: FontWeight.w300),
                    ),
                    const SizedBox(height: 60),
                    const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppTheme.royalGold)),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Designed with Excellence', style: TextStyle(color: AppTheme.royalGold.withValues(alpha: 0.6), fontSize: 12)),
                    const SizedBox(height: 5),
                    const Text('By Amjid Hadi', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
