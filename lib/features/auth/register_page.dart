import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:country_picker/country_picker.dart';
import '../../app_theme.dart';
import '../../services/user_bootstrap_service.dart';
import '../../services/auth_service.dart';
import '../../services/session_tracking_service.dart';

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
  final TextEditingController _referralController =
      TextEditingController(); // خانة كود الدعوة
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _isLoading = false;
  final bool _obscurePass = true;

  // مفتاح الدولة الافتراضي (العراق)
  String _selectedCountryCode = "+964";
  String _countryEmoji = "🇮🇶";

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    _referralController.dispose();
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

  Future<void> _registerWithGoogle() async {
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
        final sessionService = SessionTrackingService();
        await sessionService.initialize();
        if (mounted) {
          Navigator.pushReplacementNamed(context, "/home");
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

  Future<void> _registerWithPhone() async {
    String phone = _phoneController.text.trim();
    if (phone.startsWith('0')) phone = phone.substring(1);
    final fullPhoneNumber = "$_selectedCountryCode$phone";

    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      // استخدام نظام OTP المحسّن
      await authService.sendOTP(
        phone,
        countryCode: _selectedCountryCode,
        allowAnonymous: true,
      );

      setState(() {
        _isLoading = false;
      });
      _showOtpDialog(fullPhoneNumber);
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack("فشل إرسال الكود: $e");
    }
  }

  void _showPhoneRegisterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("التسجيل برقم الهاتف",
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
                          setState(() {});
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
                _registerWithPhone();
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
              _signInWithPhoneCredential(fullPhone);
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.royalGold),
            child: const Text("تأكيد", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Future<void> _signInWithPhoneCredential(String fullPhone) async {
    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final smsCode = _otpController.text.trim();

      // استخدام نظام OTP المحسّن
      final verified = await authService.verifyOTP(smsCode, allowAnonymous: true);

      if (verified) {
        await UserBootstrapService.bootstrapUser();
        final sessionService = SessionTrackingService();
        await sessionService.initialize();
        if (mounted) {
          Navigator.pushReplacementNamed(context, "/home");
        }
      } else {
        _showSnack("كود التحقق غير صحيح");
      }
    } catch (e) {
      _showSnack("حدث خطأ: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final pass = _passController.text.trim();
    final inviteCode = _referralController.text.trim();

    setState(() => _isLoading = true);

    try {
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: pass);
      final user = cred.user;
      if (user == null) throw Exception('لم يتم إنشاء المستخدم.');

      await user.updateDisplayName(name);

      // 1. إنشاء مستند المستخدم الجديد مع جميع الحقول المطلوبة
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      await userRef.set({
        'name': name,
        'displayName': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'joinDate': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
        'gems': 0,
        'stars': 0,
        'coins': 0,
        'userLevel': 1,
        'royalId': user.uid.substring(0, 8),
        'role': 'user',
        'isAgent': false,
        'isPrivate': false,
        'isVerified': false,
        // إعدادات الإشعارات
        'internalNotificationsEnabled': true,
        'pushNotificationsEnabled': true,
        'followNotificationsEnabled': true,
        'likeNotificationsEnabled': true,
        'commentNotificationsEnabled': true,
        'giftNotificationsEnabled': true,
        'badgeNotificationsEnabled': true,
        'friendRequestNotificationsEnabled': true,
        'chatNotificationsEnabled': true,
        'systemNotificationsEnabled': true,
        // إعدادات الخصوصية
        'profileVisibilityPublic': true,
        'allowMessagesFromEveryone': true,
        'allowMessagesFromFriendsOnly': false,
        'allowMessagesFromNoOne': false,
        'showOnlineStatus': true,
        'allowFriendRequests': true,
        'notificationsFromNonFriends': true,
        // إعدادات المظهر
        'darkMode': true,
        'fontSize': 16.0,
        'theme': 'royal',
        // إعدادات الغرف الصوتية
        'autoJoinEnabled': false,
        'micAutoEnabled': true,
        'speakerAutoEnabled': true,
        'micVolume': 0.8,
        'speakerVolume': 1.0,
        'noiseCancellation': true,
        'echoCancellation': true,
        // إحصائيات الاستخدام
        'totalPosts': 0,
        'totalLikes': 0,
        'totalComments': 0,
        'totalFriends': 0,
        'totalFollowers': 0,
        'totalFollowing': 0,
        'totalGiftsReceived': 0,
        'totalGiftsSent': 0,
        'totalBadges': 0,
        'totalVoiceRooms': 0,
        // إعدادات 2FA
        'twoFactorEnabled': false,
        'phoneNumber': '',
      }, SetOptions(merge: true));

      // 2. منطق كود الدعوة (الربط الحقيقي)
      if (inviteCode.isNotEmpty) {
        final ambassadorQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('royalId', isEqualTo: inviteCode)
            .limit(1)
            .get();

        if (ambassadorQuery.docs.isNotEmpty) {
          final ambassadorDoc = ambassadorQuery.docs.first;
          final ambassadorRef = ambassadorDoc.reference;

          await FirebaseFirestore.instance.runTransaction((tx) async {
            // أ- منح السفير مكافأة (5 جواهر + 5 كوينز)
            tx.update(ambassadorRef, {
              'gems': FieldValue.increment(5),
              'stars': FieldValue.increment(5),
              'coins': FieldValue.increment(5),
              'agentData.invitedCount': FieldValue.increment(1),
              'agentData.referralEarnings': FieldValue.increment(5),
            });

            // ب- تسجيل المستخدم الجديد في قائمة المدعوين لدى السفير
            final referralRef =
                ambassadorRef.collection('referrals').doc(user.uid);
            tx.set(referralRef, {
              'name': name,
              'joinedAt': FieldValue.serverTimestamp(),
              'uid': user.uid,
              'reward': 5,
            });
          });
        }
      }

      // 3. تهيئة بيانات المستخدم
      await UserBootstrapService.bootstrapUser();

      // 4. تتبع الجلسة
      final sessionService = SessionTrackingService();
      await sessionService.initialize();

      await user.sendEmailVerification();
      if (!context.mounted) return;
      Navigator.pushReplacementNamed(context, '/verify-email');
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message ?? 'خطأ في التسجيل'),
          backgroundColor: Colors.redAccent));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('حدث خطأ: $e'), backgroundColor: Colors.redAccent));
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
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.amber, width: 2),
                                image: const DecorationImage(
                                    image: AssetImage(
                                        'assets/images/app_icon.png'),
                                    fit: BoxFit.cover)),
                          ),
                          const SizedBox(height: 15),
                          const Text("انضم إلى رويال دور",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    _inputField(
                        controller: _nameController,
                        hint: 'الاسم الملكي',
                        icon: Icons.person_outline),
                    const SizedBox(height: 12),
                    _inputField(
                        controller: _emailController,
                        hint: 'البريد الإلكتروني',
                        icon: Icons.alternate_email,
                        keyboard: TextInputType.emailAddress),
                    const SizedBox(height: 12),
                    _inputField(
                        controller: _passController,
                        hint: 'كلمة المرور',
                        icon: Icons.lock_outline,
                        obscure: _obscurePass),
                    const SizedBox(height: 12),
                    _inputField(
                        controller: _referralController,
                        hint: 'كود الدعوة الملكي (اختياري)',
                        icon: Icons.stars,
                        color: Colors.amber.withValues(alpha: 0.5)),
                    const SizedBox(height: 30),
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.amber)
                        : AppTheme.gradientButton(
                            text: 'إنشاء حساب ملكي', onPressed: _register),
                    const SizedBox(height: 30),
                    const Row(
                      children: [
                        Expanded(child: Divider(color: Colors.white10)),
                        Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text("أو سجل باستخدام",
                                style: TextStyle(
                                    color: Colors.white24, fontSize: 11))),
                        Expanded(child: Divider(color: Colors.white10)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _isLoading ? () {} : _registerWithGoogle,
                            borderRadius: BorderRadius.circular(15),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: const Center(
                                child: Icon(Icons.g_mobiledata,
                                    color: Color(0xFF4285F4), size: 28),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: InkWell(
                            onTap:
                                _isLoading ? () {} : _showPhoneRegisterDialog,
                            borderRadius: BorderRadius.circular(15),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: Colors.white10),
                              ),
                              child: const Center(
                                child: Icon(Icons.phone,
                                    color: Color(0xFF25D366), size: 24),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/login'),
                        child: const Text('لديك حساب بالفعل؟ سجل دخولك',
                            style: TextStyle(color: Colors.amber))),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputField(
      {required TextEditingController controller,
      required String hint,
      required IconData icon,
      bool obscure = false,
      Color? color,
      TextInputType keyboard = TextInputType.text}) {
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
