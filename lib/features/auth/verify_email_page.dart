// lib/pages/auth/verify_email_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../app_theme.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool _checking = false;
  bool _sending = false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AppTheme.background(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text("تأكيد الهوية الملكية 🛡️",
                style: TextStyle(
                    color: Colors.amber, fontWeight: FontWeight.bold)),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: AppTheme.glassContainer(
                  padding: const EdgeInsets.all(30),
                  borderRadius: BorderRadius.circular(30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.mark_email_read_outlined,
                          size: 80, color: Colors.amber),
                      const SizedBox(height: 25),
                      const Text(
                        "تفعيل الحساب الملكي",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "لقد أرسلنا رسالة تأكيد إلى بريدك الإلكتروني.\n\n"
                        "افتح الرسالة واضغط على رابط التفعيل، ثم عد إلى هنا لتأكيد دخولك للمملكة.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 40),
                      if (_checking)
                        const CircularProgressIndicator(
                            color: Colors.amber, strokeWidth: 3)
                      else ...[
                        AppTheme.gradientButton(
                          text: "تم التفعيل، دخول المملكة 👑",
                          onPressed: _onCheckVerified,
                        ),
                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: _sending ? null : _onResendEmail,
                          child: _sending
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.amber,
                                  ),
                                )
                              : const Text(
                                  "إعادة إرسال رمز التفعيل",
                                  style: TextStyle(
                                      color: Colors.amberAccent,
                                      fontWeight: FontWeight.bold),
                                ),
                        ),
                        const Divider(color: Colors.white10, height: 40),
                        TextButton(
                          onPressed: () => Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/login',
                            (route) => false,
                          ),
                          child: const Text(
                            "استخدام حساب ملكي آخر",
                            style:
                                TextStyle(color: Colors.white38, fontSize: 13),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onCheckVerified() async {
    setState(() => _checking = true);
    final auth = context.read<AuthService>();

    final ok = await auth.refreshEmailVerified();

    setState(() => _checking = false);

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("تم تأكيد هويتك بنجاح، أهلاً بك في المملكة! 👑"),
            backgroundColor: Colors.green),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("لم يتم تفعيل البريد بعد، يرجى مراجعة بريدك الإلكتروني."),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _onResendEmail() async {
    setState(() => _sending = true);
    final auth = context.read<AuthService>();
    final msg = await auth.sendVerificationEmailAgain();
    setState(() => _sending = false);

    if (!mounted) return;

    if (msg == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("تم إرسال رسالة التفعيل مرة أخرى ✅"),
            backgroundColor: Colors.amber),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ: $msg"), backgroundColor: Colors.redAccent),
      );
    }
  }
}
