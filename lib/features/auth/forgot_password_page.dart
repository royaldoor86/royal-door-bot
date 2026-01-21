// lib/pages/auth/forgot_password_page.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../app_theme.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("يرجى إدخال البريد الإلكتروني")));
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك ✅"),
            backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("خطأ: $e"), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundBlack,
        body: AppTheme.background(
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // تم حذف الإطار والظلال من هنا ليبقى الشعار فقط
                    ClipOval(
                      child: Image.asset(
                        'assets/images/app_icon.png',
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 30),
                    AppTheme.glassContainer(
                      borderRadius: BorderRadius.circular(28),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: Column(
                        children: [
                          const Text(
                            'استعادة كلمة المرور',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              fontFamily: 'Serif',
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'أدخل بريدك الإلكتروني لإرسال رابط إعادة تعيين كلمة المرور.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white54,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 28),
                          AppTheme.royalInputField(
                            controller: _emailController,
                            hint: 'البريد الإلكتروني',
                            icon: Icons.email_outlined,
                          ),
                          const SizedBox(height: 24),
                          _isLoading
                              ? const CircularProgressIndicator(color: AppTheme.royalGold)
                              : AppTheme.gradientButton(
                                  text: 'إرسال رابط الاستعادة',
                                  onPressed: _resetPassword,
                                ),
                          const SizedBox(height: 20),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('العودة لتسجيل الدخول', style: TextStyle(color: Colors.white38, fontSize: 13)),
                          ),
                        ],
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
}
