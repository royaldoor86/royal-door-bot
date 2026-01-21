import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../app_theme.dart';
import '../../services/user_bootstrap_service.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback? onRegisterTap;
  const LoginPage({super.key, this.onRegisterTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.royalGold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  Future<void> _loginWithEmail() async {
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();
    if (email.isEmpty || pass.isEmpty) { _showSnack("يرجى إدخال البيانات كاملة"); return; }

    setState(() => _isLoading = true);
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: pass);
      await cred.user?.reload();
      await UserBootstrapService.bootstrapUser();
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, "/home", (r) => false);
    } on FirebaseAuthException catch (e) {
      _showSnack(e.message ?? "حدث خطأ في الدخول");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      await auth.loginWithGoogle();
      await UserBootstrapService.bootstrapUser();
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, "/home", (r) => false);
    } catch (e) {
      _showSnack("خطأ Google: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: AppTheme.background(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  _buildHeaderLogo(),
                  const SizedBox(height: 50),
                  AppTheme.royalInputField(controller: _emailController, hint: "البريد الإلكتروني", icon: Icons.alternate_email),
                  const SizedBox(height: 16),
                  _buildPasswordInput(),
                  _buildForgotPasswordBtn(),
                  const SizedBox(height: 30),
                  _isLoading
                      ? const CircularProgressIndicator(color: AppTheme.royalGold)
                      : AppTheme.gradientButton(text: "تسجيل الدخول الملكي", onPressed: _loginWithEmail),
                  const SizedBox(height: 40),
                  _buildDivider(),
                  const SizedBox(height: 30),
                  _SocialButton(
                    text: 'الدخول بواسطة Google',
                    icon: const FaIcon(FontAwesomeIcons.google, color: Colors.white, size: 18),
                    color1: Colors.white.withValues(alpha: 0.1),
                    onPressed: _isLoading ? () {} : _loginWithGoogle,
                  ),
                  const SizedBox(height: 40),
                  _buildSignupBtn(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderLogo() {
    return Column(
      children: [
        Container(
          width: 110, height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.royalGold.withValues(alpha: 0.5), width: 2),
            boxShadow: [BoxShadow(color: AppTheme.royalGold.withValues(alpha: 0.2), blurRadius: 30)],
          ),
          child: ClipOval(child: Image.asset('assets/images/app_icon.png', fit: BoxFit.cover)),
        ),
        const SizedBox(height: 20),
        const Text("ROYAL DOOR", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2, fontFamily: 'Serif')),
        Text("عالم النخبة والمنافسة الملكية", style: TextStyle(color: AppTheme.royalGold.withValues(alpha: 0.7), fontSize: 13)),
      ],
    );
  }

  Widget _buildPasswordInput() {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      opacity: 0.03,
      child: TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: "كلمة المرور",
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
          prefixIcon: const Icon(Icons.lock_person_outlined, color: AppTheme.royalGold, size: 20),
          suffixIcon: IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.white38, size: 18),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordBtn() {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton(
        onPressed: () => Navigator.pushNamed(context, "/forgot-password"),
        child: const Text("نسيت كلمة المرور؟", style: TextStyle(color: Colors.white38, fontSize: 12, decoration: TextDecoration.underline)),
      ),
    );
  }

  Widget _buildDivider() {
    return const Row(
      children: [
        Expanded(child: Divider(color: Colors.white10)),
        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("أو تابع باستخدام", style: TextStyle(color: Colors.white24, fontSize: 11))),
        Expanded(child: Divider(color: Colors.white10)),
      ],
    );
  }

  Widget _buildSignupBtn() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("ليس لديك حساب ملكي؟", style: TextStyle(color: Colors.white54, fontSize: 13)),
        TextButton(
          onPressed: widget.onRegisterTap ?? () => Navigator.pushNamed(context, "/signup"),
          child: const Text("سجل الآن", style: TextStyle(color: AppTheme.royalGold, fontWeight: FontWeight.bold, fontSize: 14)),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String text;
  final Widget icon;
  final Color color1;
  final VoidCallback onPressed;
  const _SocialButton({required this.text, required this.icon, required this.color1, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(color: color1, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
