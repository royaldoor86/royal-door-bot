import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../app_theme.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();
  final TextEditingController _referralController = TextEditingController(); // خانة كود الدعوة

  bool _isLoading = false;
  final bool _obscurePass = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final pass = _passController.text.trim();
    final inviteCode = _referralController.text.trim();

    setState(() => _isLoading = true);

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: pass);
      final user = cred.user;
      if (user == null) throw Exception('لم يتم إنشاء المستخدم.');

      await user.updateDisplayName(name);

      // 1. إنشاء مستند المستخدم الجديد
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await userRef.set({
        'name': name,
        'displayName': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'gems': 0,
        'stars': 0,
        'userLevel': 1,
        'royalId': user.uid.substring(0, 8),
        'role': 'user',
        'isAgent': false,
      }, SetOptions(merge: true));

      // 2. منطق كود الدعوة (الربط الحقيقي)
      if (inviteCode.isNotEmpty) {
        final ambassadorQuery = await FirebaseFirestore.instance.collection('users')
            .where('royalId', isEqualTo: inviteCode).limit(1).get();

        if (ambassadorQuery.docs.isNotEmpty) {
          final ambassadorDoc = ambassadorQuery.docs.first;
          final ambassadorRef = ambassadorDoc.reference;

          await FirebaseFirestore.instance.runTransaction((tx) async {
            // أ- منح السفير مكافأة (مثلاً 500 نجمة ⭐)
            tx.update(ambassadorRef, {
              'stars': FieldValue.increment(500),
              'agentData.invitedCount': FieldValue.increment(1),
              'agentData.referralEarnings': FieldValue.increment(500),
            });

            // ب- تسجيل المستخدم الجديد في قائمة المدعوين لدى السفير
            final referralRef = ambassadorRef.collection('referrals').doc(user.uid);
            tx.set(referralRef, {
              'name': name,
              'joinedAt': FieldValue.serverTimestamp(),
              'uid': user.uid,
            });
          });
        }
      }

      await user.sendEmailVerification();
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, '/verify-email');
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? 'خطأ في التسجيل'), backgroundColor: Colors.redAccent));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AppTheme.background(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    AppTheme.glassContainer(
                      padding: const EdgeInsets.all(20),
                      borderRadius: BorderRadius.circular(30),
                      child: Column(
                        children: [
                          Container(
                            width: 100, height: 100,
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.amber, width: 2), image: const DecorationImage(image: AssetImage('assets/images/app_icon.png'), fit: BoxFit.cover)),
                          ),
                          const SizedBox(height: 15),
                          const Text("انضم إلى رويال دور", style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    _inputField(controller: _nameController, hint: 'الاسم الملكي', icon: Icons.person_outline),
                    const SizedBox(height: 12),
                    _inputField(controller: _emailController, hint: 'البريد الإلكتروني', icon: Icons.alternate_email, keyboard: TextInputType.emailAddress),
                    const SizedBox(height: 12),
                    _inputField(controller: _passController, hint: 'كلمة المرور', icon: Icons.lock_outline, obscure: _obscurePass),
                    const SizedBox(height: 12),
                    _inputField(controller: _referralController, hint: 'كود الدعوة الملكي (اختياري)', icon: Icons.stars, color: Colors.amber.withValues(alpha: 0.5)),
                    const SizedBox(height: 30),
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.amber)
                        : AppTheme.gradientButton(text: 'إنشاء حساب ملكي', onPressed: _register),
                    const SizedBox(height: 20),
                    TextButton(onPressed: () => Navigator.pushReplacementNamed(context, '/login'), child: const Text('لديك حساب بالفعل؟ سجل دخولك', style: TextStyle(color: Colors.amber))),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField({required TextEditingController controller, required String hint, required IconData icon, bool obscure = false, Color? color, TextInputType keyboard = TextInputType.text}) {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      borderRadius: BorderRadius.circular(20),
      opacity: 0.1,
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          prefixIcon: Icon(icon, color: color ?? Colors.amber, size: 20),
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
        ),
      ),
    );
  }
}
