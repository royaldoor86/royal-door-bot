import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../terms_of_service_page.dart';
import '../privacy_policy_page.dart';
import '../../services/notifications_service.dart';
import 'enhanced_phone_verification_page.dart';

class SignupPage extends StatefulWidget {
  final VoidCallback? onLoginTap; 
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
  bool _phoneVerified = false;
  bool _termsAccepted = false;
  DateTime? _birthDate;
  String? _verifiedPhoneNumber;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: isError ? Colors.redAccent : AppTheme.royalGold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  int _calculateAge(DateTime birthDate) {
    DateTime now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.amber,
              onPrimary: Colors.black,
              surface: Color(0xFF1A0533),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim().toLowerCase(); 
    final pass = _passController.text.trim();
    final inviteCode = _referralController.text.trim();

    if (_birthDate == null) {
      _showSnack("يرجى تحديد تاريخ ميلادك للمتابعة 📅");
      return;
    }

    if (_calculateAge(_birthDate!) < 17) {
      _showSnack("عذراً، يجب أن يكون عمرك 17 عاماً أو أكثر لاستخدام رويال دور 🛡️");
      return;
    }

    if (!_termsAccepted) {
      _showSnack("يرجى الموافقة على شروط الخدمة وسياسة الخصوصية ⚖️");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. التحقق من القائمة السوداء
      final bannedCheck = await FirebaseFirestore.instance.collection('banned_emails').doc(email).get();
      if (bannedCheck.exists) {
        if (mounted) {
          _showSnack("عذراً، هذا البريد الإلكتروني محظور من الانضمام لرويال دور نهائياً 🚫");
          setState(() => _isLoading = false);
        }
        return;
      }

      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: pass);
      final user = cred.user;
      if (user == null) throw Exception('فشل إنشاء المستخدم');

      await user.updateDisplayName(name);

      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      String myRoyalId = user.uid.substring(0, 8);

      await userRef.set({
        'uid': user.uid,
        'name': name,
        'email': email,
        'profilePic': '',
        'gems': inviteCode.isNotEmpty ? 50 : 0, // مكافأة ترحيبية للمدعو
        'stars': inviteCode.isNotEmpty ? 50 : 0, 
        'coins': inviteCode.isNotEmpty ? 50 : 0, 
        'royalXP': 0,
        'userLevel': 1,
        'accountLevel': 1,
        'royalId': myRoyalId,
        'isAgent': false,
        'isVerified': false,
        'isActive': true,
        'isBanned': false,
        'createdAt': FieldValue.serverTimestamp(),
        'phoneNumber': _verifiedPhoneNumber,
        'phoneVerified': _phoneVerified,
        'birthDate': Timestamp.fromDate(_birthDate!),
        'privilegeSettings': {},
        'friends': [],
        'followers': [],
        'following': [],
        'blockedUsers': [],
      }, SetOptions(merge: true));

      if (inviteCode.isNotEmpty) {
        final ambassadorQuery = await FirebaseFirestore.instance.collection('users')
            .where('royalId', isEqualTo: inviteCode).limit(1).get();

        if (ambassadorQuery.docs.isNotEmpty) {
          final ambassadorDoc = ambassadorQuery.docs.first;
          final ambassadorRef = ambassadorDoc.reference;
          final ambassadorUid = ambassadorDoc.id;

          await FirebaseFirestore.instance.runTransaction((tx) async {
            tx.update(ambassadorRef, {
              'gems': FieldValue.increment(50),
              'stars': FieldValue.increment(50),
              'coins': FieldValue.increment(50),
              'agentData.invitedCount': FieldValue.increment(1),
              'agentData.referralEarnings': FieldValue.increment(50), // احتساب الجواهر كمكافأة ربح
            });

            final referralRef = ambassadorRef.collection('referrals').doc(user.uid);
            tx.set(referralRef, {
              'name': name,
              'joinedAt': FieldValue.serverTimestamp(),
              'uid': user.uid,
              'reward': 50,
            });
          });

          // إرسال إشعار فوري للسفير
          NotificationsService.sendNotification(
            userId: ambassadorUid,
            title: 'مكافأة سفير ملكي! 👑',
            message: 'لقد انضم صديقك ($name) عن طريقك. حصلت على 50 جوهرة و 50 نجمة ⭐',
            type: 'referral_reward',
          );
        }
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMsg = "فشل إنشاء الحساب";
        if (e.code == 'email-already-in-use') {
          errorMsg = "البريد الإلكتروني مستخدم بالفعل";
        } else if (e.code == 'weak-password') {
          errorMsg = "كلمة المرور ضعيفة جداً";
        }
        _showSnack(errorMsg);
      }
    } catch (e) {
      if (mounted) _showSnack("حدث خطأ: $e");
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
                    _inputField(
                      controller: _nameController, 
                      hint: 'الاسم الملكي', 
                      icon: Icons.person_outline,
                      validator: (v) => (v == null || v.isEmpty) ? "يرجى إدخل الاسم" : null,
                    ),
                    const SizedBox(height: 15),
                    _inputField(
                      controller: _emailController, 
                      hint: 'البريد الإلكتروني', 
                      icon: Icons.alternate_email, 
                      keyboard: TextInputType.emailAddress,
                      validator: (v) => (v == null || !v.contains('@')) ? "بريد غير صحيح" : null,
                    ),
                    const SizedBox(height: 15),
                    _inputField(
                      controller: _passController, 
                      hint: 'كلمة المرور', 
                      icon: Icons.lock_outline, 
                      obscure: _obscurePass,
                      validator: (v) => (v == null || v.length < 6) ? "كلمة المرور قصيرة جداً" : null,
                      suffix: IconButton(
                        icon: Icon(_obscurePass ? Icons.visibility_off : Icons.visibility, color: Colors.white38),
                        onPressed: () => setState(() => _obscurePass = !_obscurePass),
                      ),
                    ),
                    const SizedBox(height: 15),
                    _inputField(
                      controller: _referralController, 
                      hint: 'كود الدعوة الملكي (اختياري)', 
                      icon: Icons.stars_rounded, 
                      color: Colors.amber.withValues(alpha: 0.6)
                    ),
                    const SizedBox(height: 15),
                    _buildBirthDateSection(),
                    const SizedBox(height: 15),
                    _buildPhoneVerificationSection(),
                    const SizedBox(height: 15),
                    _buildTermsCheckbox(),
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

  Widget _buildBirthDateSection() {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: BorderRadius.circular(20),
      opacity: 0.15,
      child: InkWell(
        onTap: _selectBirthDate,
        child: Row(
          children: [
            const Icon(Icons.cake_rounded, color: Colors.amber),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("تاريخ الميلاد", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(
                    _birthDate == null 
                        ? "يرجى تحديد تاريخ ميلادك" 
                        : "${_birthDate!.year}/${_birthDate!.month}/${_birthDate!.day} (العمر: ${_calculateAge(_birthDate!)} سنة)",
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.calendar_month_rounded, color: Colors.amber, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Row(
      children: [
        Checkbox(
          value: _termsAccepted,
          activeColor: Colors.amber,
          checkColor: Colors.black,
          onChanged: (v) => setState(() => _termsAccepted = v ?? false),
        ),
        Expanded(
          child: Wrap(
            children: [
              const Text("أوافق على ", style: TextStyle(color: Colors.white70, fontSize: 12)),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsOfServicePage())),
                child: const Text("شروط الخدمة", style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
              ),
              const Text(" و ", style: TextStyle(color: Colors.white70, fontSize: 12)),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyPage())),
                child: const Text("سياسة الخصوصية", style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
              ),
              const Text(" لرويال دور.", style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneVerificationSection() {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: BorderRadius.circular(20),
      opacity: 0.15,
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _phoneVerified ? Icons.verified_user_rounded : Icons.phone_android_rounded,
                color: _phoneVerified ? Colors.greenAccent : Colors.amber,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _phoneVerified ? "تم توثيق الهاتف الملكي" : "توثيق رقم الهاتف",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    if (_phoneVerified)
                      Text(
                        _verifiedPhoneNumber ?? "",
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      )
                    else
                      const Text(
                        "اختياري - يمكنك التوثيق الآن أو لاحقاً من ملفك الشخصي",
                        style: TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                  ],
                ),
              ),
              if (!_phoneVerified)
                TextButton(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EnhancedPhoneVerificationPage(isRegistration: true),
                      ),
                    );
                    if (result != null && result is String) {
                      setState(() {
                        _phoneVerified = true;
                        _verifiedPhoneNumber = result;
                      });
                    }
                  },
                  child: const Text("تحقق الآن", style: TextStyle(color: Colors.amber)),
                )
              else
                const Icon(Icons.check_circle, color: Colors.greenAccent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _inputField({required TextEditingController controller, required String hint, required IconData icon, bool obscure = false, Color? color, TextInputType keyboard = TextInputType.text, String? Function(String?)? validator, Widget? suffix}) {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      borderRadius: BorderRadius.circular(20),
      opacity: 0.1,
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        keyboardType: keyboard,
        validator: validator,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          prefixIcon: Icon(icon, color: color ?? Colors.amber, size: 20),
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
          suffixIcon: suffix,
        ),
      ),
    );
  }
}
