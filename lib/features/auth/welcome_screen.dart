import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app_theme.dart';
import '../../services/user_bootstrap_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    _handleStartUp();
  }

  Future<void> _handleStartUp() async {
    // زيادة وقت الانتظار إلى 5 ثواني بناءً على طلب المستخدم
    await Future.delayed(const Duration(seconds: 5));
    
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      try {
        await UserBootstrapService.bootstrapUser();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } catch (e) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Stack(
          children: [
            AppTheme.background(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                          'assets/app/app_icon.png',
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
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 60),
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
