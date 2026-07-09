import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:country_picker/country_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // مفتاح الدولة الافتراضي (العراق)
  String _selectedCountryCode = "+964";
  String _countryEmoji = "🇮🇶";

  // Firebase Phone Auth
  String? _verificationId;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _showSnack(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  Future<void> _loginWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();

    setState(() => _isLoading = true);
    try {
      final cred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: pass);
      await cred.user?.reload();
      await UserBootstrapService.bootstrapUser();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, "/home", (r) => false);
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg = "فشل تسجيل الدخول";
      if (e.code == 'user-not-found') {
        errorMsg = "الحساب غير موجود";
      } else if (e.code == 'wrong-password') {
        errorMsg = "كلمة المرور خاطئة";
      } else if (e.code == 'invalid-email') {
        errorMsg = "البريد الإلكتروني غير صحيح";
      }
      _showSnack(errorMsg);
    } catch (e) {
      _showSnack("حدث خطأ غير متوقع");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final result = await auth.loginWithGoogle();
      if (result == "CANCELLED") {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }
      if (result == null) {
        await UserBootstrapService.bootstrapUser();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, "/home", (r) => false);
        }
      } else {
        if (mounted) {
          _showSnack(result);
        }
      }
    } catch (e) {
      _showSnack("حدث خطأ أثناء الاتصال بـ Google");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithFacebook() async {
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final result = await auth.loginWithFacebook();
      if (result == "CANCELLED") {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }
      if (result == null) {
        await UserBootstrapService.bootstrapUser();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, "/home", (r) => false);
        }
      } else {
        if (mounted) {
          _showSnack(result);
        }
      }
    } catch (e) {
      _showSnack("حدث خطأ أثناء الاتصال بـ Facebook");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithTwitter() async {
    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final result = await auth.loginWithTwitter();
      if (result == "CANCELLED") {
        if (mounted) {
          setState(() => _isLoading = false);
        }
        return;
      }
      if (result == null) {
        await UserBootstrapService.bootstrapUser();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, "/home", (r) => false);
        }
      } else {
        if (mounted) {
          _showSnack(result);
        }
      }
    } catch (e) {
      _showSnack("حدث خطأ أثناء الاتصال بـ Twitter");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- نافذة إدخال رقم الهاتف مع اختيار الدولة ---

  Future<void> _showPhoneLoginDialog() async {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("الدخول برقم الهاتف",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.royalGold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("اختر الدولة وأدخل رقم هاتفك",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Row(
                children: [
                  // زر اختيار الدولة
                  InkWell(
                    onTap: () {
                      showCountryPicker(
                        context: context,
                        showPhoneCode: true,
                        onSelect: (Country country) {
                          setDialogState(() {
                            _selectedCountryCode = "+${country.phoneCode}";
                            _countryEmoji = country.flagEmoji;
                          });
                          setState(
                              () {}); // لتحديث الحالة خارج الـ dialog أيضاً
                        },
                        countryListTheme: CountryListThemeData(
                          backgroundColor: const Color(0xFF1A1A1A),
                          textStyle: const TextStyle(color: Colors.white),
                          bottomSheetHeight: 500,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20)),
                          inputDecoration: InputDecoration(
                            hintText: 'ابحث عن دولتك',
                            hintStyle: const TextStyle(color: Colors.white38),
                            prefixIcon: const Icon(Icons.search,
                                color: AppTheme.royalGold),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.05),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(15),
                                borderSide: BorderSide.none),
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 15),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          Text(_countryEmoji,
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text(_selectedCountryCode,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          const Icon(Icons.arrow_drop_down,
                              color: AppTheme.royalGold),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // حقل إدخال الرقم
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "770 000 0000",
                        hintStyle: const TextStyle(
                            color: Colors.white24, fontSize: 14),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("إلغاء",
                    style: TextStyle(color: Colors.white38))),
            ElevatedButton(
              onPressed: () {
                if (_phoneController.text.trim().isEmpty) {
                  _showSnack("يرجى إدخال رقم الهاتف");
                  return;
                }
                Navigator.pop(context);
                _verifyPhone();
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppTheme.royalGold),
              child: const Text("إرسال الكود",
                  style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _verifyPhone() async {
    String phone = _phoneController.text.trim();
    if (phone.startsWith('0')) phone = phone.substring(1);
    final fullPhoneNumber = "$_selectedCountryCode$phone";

    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      // استخدام Firebase Phone Auth المباشر
      await authService.verifyPhoneNumber(
        phoneNumber: fullPhoneNumber,
        onCodeSent: (String verificationId) {
          setState(() {
            _verificationId = verificationId;
            _isLoading = false;
          });
          _showOtpDialog(fullPhoneNumber);
        },
        onVerificationFailed: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          String errorMsg = "فشل إرسال الكود";
          if (e.code == 'invalid-phone-number') {
            errorMsg = "رقم الهاتف غير صحيح";
          } else if (e.code == 'too-many-requests') {
            errorMsg = "محاولات كثيرة، حاول لاحقاً";
          }
          _showSnack(errorMsg);
        },
        onVerificationCompleted: (PhoneAuthCredential credential) async {
          // عند التحقق التلقائي (Android) - تسجيل الدخول مباشرة
          try {
            final result =
                await FirebaseAuth.instance.signInWithCredential(credential);
            final user = result.user;
            if (user != null) {
              await UserBootstrapService.bootstrapUser();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, "/home", (r) => false);
              }
            }
          } catch (e) {
            setState(() => _isLoading = false);
            _showSnack("فشل التحقق التلقائي: $e");
          }
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack("فشل إرسال الكود: $e");
    }
  }

  void _showOtpDialog(String fullPhone) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("رمز التحقق",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.royalGold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("تم إرسال الرمز إلى $fullPhone",
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 15),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontSize: 24, letterSpacing: 10),
              maxLength: 6,
              decoration: InputDecoration(
                counterText: "",
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("تعديل الرقم",
                  style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _signInWithCredential(fullPhone);
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.royalGold),
            child: const Text("تأكيد", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Future<void> _signInWithCredential(String fullPhone) async {
    if (_verificationId == null) {
      _showSnack("يرجى إرسال الكود أولاً");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final smsCode = _otpController.text.trim();

      // استخدام Firebase Phone Auth للتحقق من الكود
      final user = await authService.signInWithPhone(_verificationId!, smsCode);

      if (user != null) {
        await UserBootstrapService.bootstrapUser();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, "/home", (r) => false);
        }
      } else {
        _showSnack("كود التحقق غير صحيح");
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg = "كود التحقق غير صحيح";
      if (e.code == 'invalid-verification-code') {
        errorMsg = "كود التحقق غير صحيح";
      } else if (e.code == 'code-expired') {
        errorMsg = "الكود منتهي، أعد الإرسال";
      }
      _showSnack(errorMsg);
    } catch (e) {
      _showSnack("حدث خطأ: $e");
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
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 50),
                    _buildHeaderLogo(),
                    const SizedBox(height: 50),
                    _emailInputField(),
                    const SizedBox(height: 16),
                    _buildPasswordInput(),
                    _buildForgotPasswordBtn(),
                    const SizedBox(height: 30),
                    _isLoading
                        ? const CircularProgressIndicator(
                            color: AppTheme.royalGold)
                        : AppTheme.gradientButton(
                            text: "تسجيل الدخول الملكي",
                            onPressed: _loginWithEmail),
                    const SizedBox(height: 40),
                    _buildDivider(),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _ColoredSocialButton(
                          iconPath:
                              'https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg', // Official Google G Logo
                          label: 'Google',
                          color: const Color(0xFF4285F4),
                          onPressed: _isLoading ? () {} : _loginWithGoogle,
                        ),
                        _ColoredSocialButton(
                          iconPath:
                              'https://upload.wikimedia.org/wikipedia/commons/5/51/Facebook_f_logo_%282019%29.svg', // Official Facebook Logo
                          label: 'Facebook',
                          color: const Color(0xFF1877F2),
                          onPressed: _isLoading ? () {} : _loginWithFacebook,
                        ),
                        _ColoredSocialButton(
                          iconPath:
                              'https://upload.wikimedia.org/wikipedia/commons/6/6e/X_logo_2023.svg', // Official X (Twitter) Logo
                          label: 'Twitter/X',
                          color: Colors.black,
                          onPressed: _isLoading ? () {} : _loginWithTwitter,
                        ),
                        _ColoredSocialButton(
                          iconPath:
                              'https://cdn-icons-png.flaticon.com/512/724/724664.png', // Phone Icon
                          label: 'Phone',
                          color: const Color(0xFF25D366),
                          onPressed: _isLoading ? () {} : _showPhoneLoginDialog,
                          isPng: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    _buildSignupBtn(),
                  ],
                ),
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
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
                color: AppTheme.royalGold.withValues(alpha: 0.5), width: 2),
            boxShadow: [
              BoxShadow(
                  color: AppTheme.royalGold.withValues(alpha: 0.2),
                  blurRadius: 30)
            ],
          ),
          child: ClipOval(
              child: Image.asset('assets/app/app_icon.png',
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const Icon(Icons.stars,
                      color: AppTheme.royalGold, size: 50))),
        ),
        const SizedBox(height: 20),
        const Text("ROYAL DOOR",
            style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                fontFamily: 'Serif')),
        Text("عالم النخبة والمنافسة الملكية",
            style: TextStyle(
                color: AppTheme.royalGold.withValues(alpha: 0.7),
                fontSize: 13)),
      ],
    );
  }

  Widget _emailInputField() {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      opacity: 0.03,
      child: TextFormField(
        controller: _emailController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        validator: (v) =>
            (v == null || !v.contains('@')) ? "بريد غير صحيح" : null,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: "البريد الإلكتروني",
          hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
          prefixIcon:
              Icon(Icons.alternate_email, color: AppTheme.royalGold, size: 20),
        ),
      ),
    );
  }

  Widget _buildPasswordInput() {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      opacity: 0.03,
      child: TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        validator: (v) =>
            (v == null || v.length < 6) ? "كلمة المرور ضعيفة" : null,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: "كلمة المرور",
          hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
          prefixIcon: const Icon(Icons.lock_person_outlined,
              color: AppTheme.royalGold, size: 20),
          suffixIcon: IconButton(
            icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.white38,
                size: 18),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
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
        child: const Text("نسيت كلمة المرور؟",
            style: TextStyle(
                color: Colors.white38,
                fontSize: 12,
                decoration: TextDecoration.underline)),
      ),
    );
  }

  Widget _buildDivider() {
    return const Row(
      children: [
        Expanded(child: Divider(color: Colors.white10)),
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text("أو تابع باستخدام",
                style: TextStyle(color: Colors.white24, fontSize: 11))),
        Expanded(child: Divider(color: Colors.white10)),
      ],
    );
  }

  Widget _buildSignupBtn() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("ليس لديك حساب ملكي؟",
            style: TextStyle(color: Colors.white54, fontSize: 13)),
        TextButton(
          onPressed: widget.onRegisterTap ??
              () => Navigator.pushNamed(context, "/signup"),
          child: const Text("سجل الآن",
              style: TextStyle(
                  color: AppTheme.royalGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 14)),
        ),
      ],
    );
  }
}

class _SocialIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onPressed;
  const _SocialIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white10),
        ),
        child: Center(child: icon),
      ),
    );
  }
}

class _ColoredSocialButton extends StatelessWidget {
  final String iconPath;
  final String label;
  final Color color;
  final VoidCallback onPressed;
  final bool isPng;

  const _ColoredSocialButton({
    required this.iconPath,
    required this.label,
    required this.color,
    required this.onPressed,
    this.isPng = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: isPng
                    ? Image.network(
                        iconPath,
                        fit: BoxFit.contain,
                        errorBuilder: (c, e, s) =>
                            Icon(Icons.star, color: color),
                      )
                    : SvgPicture.network(
                        iconPath,
                        fit: BoxFit.contain,
                        placeholderBuilder: (context) =>
                            Icon(Icons.star, color: color),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
