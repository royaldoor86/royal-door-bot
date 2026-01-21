import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../app_theme.dart';

class SignupPage extends StatefulWidget {
  final VoidCallback? onLoginTap; // إضافة الباراميتر المفقود
  const SignupPage({super.key, this.onLoginTap});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePass = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final pass = _passController.text.trim();
    final inviteCode = _referralController.text.trim();

    setState(() => _isLoading = true);

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: pass);
      final user = cred.user;
      if (user == null) throw Exception('فشل إنشاء المستخدم');

      await user.updateDisplayName(name);

      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      String myRoyalId = user.uid.substring(0, 8);

      await userRef.set({
        'name': name,
        'displayName': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'gems': 0,
        'coins': 0,
        'userLevel': 1,
        'royalId': myRoyalId,
        'isAgent': false,
        'role': 'user',
      }, SetOptions(merge: true));

      if (inviteCode.isNotEmpty) {
        final ambassadorQuery = await FirebaseFirestore.instance.collection('users')
            .where('royalId', isEqualTo: inviteCode).limit(1).get();

        if (ambassadorQuery.docs.isNotEmpty) {
          final ambassadorDoc = ambassadorQuery.docs.first;
          final ambassadorRef = ambassadorDoc.reference;

          await FirebaseFirestore.instance.runTransaction((tx) async {
            tx.update(ambassadorRef, {
              'coins': FieldValue.increment(500),
              'agentData.invitedCount': FieldValue.increment(1),
              'agentData.referralEarnings': FieldValue.increment(500),
            });

            final referralRef = ambassadorRef.collection('referrals').doc(user.uid);
            tx.set(referralRef, {
              'name': name,
              'joinedAt': FieldValue.serverTimestamp(),
              'uid': user.uid,
            });
          });
        }
      }

      if (mounted) Navigator.pushReplacementNamed(context, '/home');
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
                    const SizedBox(height: 30),
                    _buildTopLogo(),
                    const SizedBox(height: 30),
                    _inputField(controller: _nameController, hint: 'الاسم الملكي', icon: Icons.person_outline),
                    const SizedBox(height: 15),
                    _inputField(controller: _emailController, hint: 'البريد الإلكتروني', icon: Icons.alternate_email, keyboard: TextInputType.emailAddress),
                    const SizedBox(height: 15),
                    _inputField(controller: _passController, hint: 'كلمة المرور', icon: Icons.lock_outline, obscure: _obscurePass),
                    const SizedBox(height: 15),
                    _inputField(
                      controller: _referralController, 
                      hint: 'كود الدعوة الملكي (اختياري)', 
                      icon: Icons.stars_rounded, 
                      color: Colors.amber.withValues(alpha: 0.6)
                    ),
                    const SizedBox(height: 40),
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.amber)
                        : AppTheme.gradientButton(text: 'إنشاء حساب ملكي جديد', onPressed: _signup),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: widget.onLoginTap ?? () => Navigator.pushReplacementNamed(context, '/login'),
                      child: const Text('لديك حساب بالفعل؟ سجل دخولك', style: TextStyle(color: Colors.white70)),
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

  Widget _buildTopLogo() {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(30),
      child: Column(
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.amber, width: 2), image: const DecorationImage(image: AssetImage('assets/images/app_icon.png'), fit: BoxFit.cover)),
          ),
          const SizedBox(height: 15),
          const Text("انضم إلى رويال دور", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const Text("عالم النخبة والمنافسة الملكية", style: TextStyle(color: Colors.white54, fontSize: 12)),
        ],
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
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
        ),
      ),
    );
  }
}
