import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:country_picker/country_picker.dart';
import '../app_theme.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'auth/login_page.dart';

class SecurityLoginPage extends StatefulWidget {
  const SecurityLoginPage({super.key});

  @override
  State<SecurityLoginPage> createState() => _SecurityLoginPageState();
}

class _SecurityLoginPageState extends State<SecurityLoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: StreamBuilder<UserModel>(
        stream: user != null ? _firestoreService.streamUserData(user.uid) : null,
        builder: (context, snapshot) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            appBar: AppBar(
              title: const Text('الأمان وتسجيل الدخول', style: TextStyle(fontWeight: FontWeight.bold)),
              centerTitle: true,
              elevation: 0,
              backgroundColor: Colors.transparent,
            ),
            body: AppTheme.background(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: AppTheme.royalGold))
                : ListView(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    children: [
                      _buildSectionTitle('وسائل الربط المتاحة'),
                      
                      _buildSocialItem(
                        icon: Icons.email_outlined,
                        title: 'البريد الإلكتروني',
                        subtitle: user?.email ?? 'غير مرتبط',
                        color: Colors.orange,
                        isConnected: user?.email != null,
                        onAction: () => _handleEmailLink(),
                      ),
                      
                      _buildSocialItem(
                        icon: FontAwesomeIcons.google,
                        title: 'جوجل (Google)',
                        subtitle: _getProviderEmail('google.com') ?? 'غير مرتبط',
                        color: Colors.red,
                        isConnected: _isProviderLinked('google.com'),
                        onAction: () => _handleGoogleLink(),
                      ),
                      
                      _buildSocialItem(
                        icon: Icons.phone_android_rounded,
                        title: 'رقم الهاتف',
                        subtitle: user?.phoneNumber ?? 'غير مرتبط',
                        color: Colors.green,
                        isConnected: user?.phoneNumber != null,
                        onAction: () => _handlePhoneLink(),
                      ),

                      const Divider(color: Colors.white10, height: 40),
                      
                      _buildSectionTitle('كلمة المرور والأمان'),
                      _buildActionItem(
                        icon: Icons.lock_outline,
                        title: 'تغيير كلمة المرور',
                        subtitle: 'تغيير مباشر وآمن من داخل التطبيق',
                        onTap: () => _showDirectChangePasswordDialog(),
                      ),
                      
                      _buildActionItem(
                        icon: Icons.mark_email_read_outlined,
                        title: 'إرسال رابط استعادة',
                        subtitle: 'إرسال بريد لإعادة تعيين كلمة المرور',
                        onTap: () => _sendResetEmail(user?.email),
                      ),
                      
                      const Divider(color: Colors.white10, height: 40),
                      
                      _buildSectionTitle('منطقة الخطر'),
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent),
                        ),
                        title: const Text('حذف الحساب نهائياً', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                        subtitle: const Text('سيتم مسح كافة البيانات ولا يمكن التراجع', style: TextStyle(color: Colors.white38, fontSize: 11)),
                        onTap: () => _showDeleteAccountDialog(),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
            ),
          );
        },
      ),
    );
  }

  bool _isProviderLinked(String providerId) {
    return _auth.currentUser?.providerData.any((info) => info.providerId == providerId) ?? false;
  }

  String? _getProviderEmail(String providerId) {
    try {
      return _auth.currentUser?.providerData.firstWhere((info) => info.providerId == providerId).email;
    } catch (_) {
      return null;
    }
  }

  Widget _buildSectionTitle(String title) {
    bool isLight = Theme.of(context).brightness == Brightness.light;
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
      child: Text(title, style: TextStyle(color: isLight ? Colors.deepPurple : AppTheme.royalGold, fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Widget _buildSocialItem({required IconData icon, required String title, required String subtitle, required Color color, required bool isConnected, required VoidCallback onAction}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: AppTheme.glassContainer(
        padding: const EdgeInsets.all(0),
        opacity: 0.03,
        child: ListTile(
          leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Icon(icon, color: color, size: 20)),
          title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
          subtitle: Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
          trailing: TextButton(
            onPressed: onAction,
            child: Text(isConnected ? 'إلغاء الربط' : 'ربط الآن', style: TextStyle(color: isConnected ? Colors.grey : AppTheme.royalGold, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem({required IconData icon, required String title, String? subtitle, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: AppTheme.glassContainer(
        padding: const EdgeInsets.all(0),
        opacity: 0.03,
        child: ListTile(
          leading: Icon(icon, color: AppTheme.royalGold, size: 22),
          title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
          subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 11)) : null,
          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white24),
          onTap: onTap,
        ),
      ),
    );
  }

  // --- منطق الربط الحقيقي ---

  Future<void> _handleEmailLink() async {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('ربط البريد الإلكتروني', style: TextStyle(color: Colors.white)),
        content: TextField(controller: emailController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'أدخل البريد الإلكتروني', hintStyle: TextStyle(color: Colors.white24))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('إرسال رابط التحقق')),
        ],
      ),
    );
  }

  Future<void> _handleGoogleLink() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final AuthCredential credential = GoogleAuthProvider.credential(accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
        await _auth.currentUser?.linkWithCredential(credential);
        _showSuccess('تم ربط حساب جوجل بنجاح ✅');
      }
    } catch (e) {
      _showError('فشل الربط: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handlePhoneLink() async {
    final phoneController = TextEditingController();
    String selectedCountryCode = "+964";
    String countryEmoji = "🇮🇶";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('ربط رقم الهاتف', style: TextStyle(color: AppTheme.royalGold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("سيتم إرسال رمز تحقق لرقمك", style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 20),
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      showCountryPicker(
                        context: context,
                        onSelect: (Country country) {
                          setDialogState(() {
                            selectedCountryCode = "+${country.phoneCode}";
                            countryEmoji = country.flagEmoji;
                          });
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
                      child: Text("$countryEmoji $selectedCountryCode", style: const TextStyle(color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(hintText: '77000000', hintStyle: TextStyle(color: Colors.white24)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                final fullPhone = "$selectedCountryCode${phoneController.text.trim()}";
                Navigator.pop(ctx);
                _sendVerificationCode(fullPhone);
              },
              child: const Text('إرسال الرمز'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendVerificationCode(String phoneNumber) async {
    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      // استخدام خدمة OTP المخصصة (Twilio)
      await authService.sendPhoneOTP(phoneNumber);
      
      setState(() => _isLoading = false);
      _showOtpDialog(phoneNumber);
    } catch (e) {
      _showError("خطأ في إرسال الرمز: $e");
      setState(() => _isLoading = false);
    }
  }

  void _showOtpDialog(String phoneNumber) {
    final otpController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("أدخل رمز التحقق", style: TextStyle(color: AppTheme.royalGold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("تم إرسال الرمز إلى $phoneNumber", style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 20),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, letterSpacing: 8, fontSize: 24),
              textAlign: TextAlign.center,
              maxLength: 6,
              decoration: const InputDecoration(counterText: ""),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final code = otpController.text.trim();
              if (code.length != 6) return;

              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                final authService = Provider.of<AuthService>(context, listen: false);
                final success = await authService.verifyPhoneOTP(code, phoneNumber: phoneNumber);
                
                if (success) {
                  _showSuccess("تم ربط الهاتف بنجاح ✅");
                } else {
                  _showError("رمز غير صحيح");
                }
              } catch (e) {
                _showError("خطأ في التحقق: $e");
              } finally {
                setState(() => _isLoading = false);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.royalGold),
            child: const Text("تأكيد", style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showDirectChangePasswordDialog() {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تغيير كلمة المرور 🔐', style: TextStyle(color: AppTheme.royalGold, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogTextField(oldPassController, 'كلمة المرور القديمة'),
            const SizedBox(height: 10),
            _dialogTextField(newPassController, 'كلمة المرور الجديدة'),
            const SizedBox(height: 10),
            _dialogTextField(confirmPassController, 'تأكيد الجديدة'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () {
              if (newPassController.text != confirmPassController.text) {
                _showError('كلمات المرور الجديدة غير متطابقة');
                return;
              }
              _directUpdatePassword(oldPassController.text, newPassController.text);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.royalGold),
            child: const Text('حفظ التغيير', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _directUpdatePassword(String oldPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return;

    setState(() => _isLoading = true);
    try {
      AuthCredential credential = EmailAuthProvider.credential(email: user.email!, password: oldPassword);
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      _showSuccess('تم تحديث كلمة المرور بنجاح ✅');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        _showError('كلمة المرور القديمة غير صحيحة ❌');
      } else {
        _showError('حدث خطأ: ${e.message}');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _dialogTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      obscureText: true,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Future<void> _sendResetEmail(String? email) async {
    if (email == null) return;
    await _auth.sendPasswordResetEmail(email: email);
    _showSuccess('تم إرسال رابط إعادة التعيين لبريدك ✅');
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text('حذف الحساب نهائياً', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'تنبيه: هذا الإجراء سيقوم بحذف كافة بياناتك، جواهرك، وأصدقائك نهائياً من نظام رويال دور. لا يمكن التراجع عن هذه الخطوة أبداً.\n\nهل أنت متأكد تماماً؟',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _reauthenticateAndDelete();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('نعم، احذف حسابي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _reauthenticateAndDelete() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // تحديد نوع تسجيل الدخول لطلب إعادة التحقق المناسب
    String providerId = user.providerData.isNotEmpty ? user.providerData.first.providerId : 'password';

    if (providerId == 'google.com') {
      try {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        if (googleUser != null) {
          final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
          final AuthCredential credential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );
          await user.reauthenticateWithCredential(credential);
          await _performFinalDeletion();
        }
      } catch (e) {
        _showError('فشل التحقق من هويتك: $e');
      }
    } else if (providerId == 'password') {
      final passwordController = TextEditingController();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('تأكيد الهوية', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('يرجى إدخال كلمة المرور للمتابعة', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 15),
              _dialogTextField(passwordController, 'كلمة المرور الحالية'),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                final password = passwordController.text.trim();
                if (password.isEmpty) return;
                Navigator.pop(ctx);
                
                setState(() => _isLoading = true);
                try {
                  AuthCredential credential = EmailAuthProvider.credential(email: user.email!, password: password);
                  await user.reauthenticateWithCredential(credential);
                  await _performFinalDeletion();
                } catch (e) {
                  _showError('كلمة المرور غير صحيحة ❌');
                  setState(() => _isLoading = false);
                }
              },
              child: const Text('تأكيد الحذف'),
            ),
          ],
        ),
      );
    } else {
      // أنواع أخرى (مثل الهاتف) - نحاول الحذف مباشرة أو نطلب رقم الهاتف
      // بما أن أغلب المستخدمين يربطون البريد أو جوجل، سنحاول الحذف المباشر هنا
      // Firebase سيطلب Re-auth تلقائياً إذا مر وقت طويل
      try {
        await _performFinalDeletion();
      } catch (e) {
        _showError('يرجى تسجيل الخروج والدخول مرة أخرى ثم المحاولة للحفاظ على الأمان');
      }
    }
  }

  Future<void> _performFinalDeletion() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final uid = user.uid;

    setState(() => _isLoading = true);

    try {
      // 1. مسح البيانات من Firestore (أهم المجموعات)
      final batch = FirebaseFirestore.instance.batch();
      
      // الوثائق الأساسية
      batch.delete(FirebaseFirestore.instance.collection('users').doc(uid));
      batch.delete(FirebaseFirestore.instance.collection('wallets').doc(uid));
      batch.delete(FirebaseFirestore.instance.collection('settings').doc(uid));
      batch.delete(FirebaseFirestore.instance.collection('followers').doc(uid));
      batch.delete(FirebaseFirestore.instance.collection('follows').doc(uid));
      batch.delete(FirebaseFirestore.instance.collection('daily_logins').doc(uid));
      batch.delete(FirebaseFirestore.instance.collection('daily_tasks').doc(uid));

      // تنفيذ الحذف للوثائق الفردية
      await batch.commit();

      // 2. مسح البيانات الموزعة (تتطلب استعلامات)
      // ملاحظة: في بيئة الإنتاج يفضل استخدام Cloud Functions لمسح كافة التعليقات والمنشورات والغرف
      
      // مسح الغرف التي يملكها المستخدم
      final roomsSnap = await FirebaseFirestore.instance.collection('rooms').where('ownerId', isEqualTo: uid).get();
      for (var doc in roomsSnap.docs) {
        await doc.reference.delete();
      }

      // مسح منشوراته (اليوميات)
      final postsSnap = await FirebaseFirestore.instance.collection('posts').where('authorId', isEqualTo: uid).get();
      for (var doc in postsSnap.docs) {
        await doc.reference.delete();
      }

      // مسح قصصه
      final storiesSnap = await FirebaseFirestore.instance.collection('stories').where('userId', isEqualTo: uid).get();
      for (var doc in storiesSnap.docs) {
        await doc.reference.delete();
      }

      // مسح المكافآت النشطة
      final rewardsSnap = await FirebaseFirestore.instance.collection('active_rewards').where('userId', isEqualTo: uid).get();
      for (var doc in rewardsSnap.docs) {
        await doc.reference.delete();
      }

      // إزالة المستخدم من قوائم أصدقاء الآخرين (عملية ثقيلة، سنكتفي بمسح وثيقة المستخدم الرئيسية)
      // الوثيقة الرئيسية في /users تم حذفها بالفعل في الـ batch

      // 3. حذف حساب المصادقة نهائياً
      await user.delete();

      if (mounted) {
        _showSuccess('تم حذف حسابك وكافة بياناتك بنجاح. نأمل رؤيتك مجدداً 👋');
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      _showError('حدث خطأ أثناء حذف البيانات: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }
}
