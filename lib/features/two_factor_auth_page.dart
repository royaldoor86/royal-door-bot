import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:country_picker/country_picker.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../app_theme.dart';

class TwoFactorAuthPage extends StatefulWidget {
  const TwoFactorAuthPage({super.key});

  @override
  State<TwoFactorAuthPage> createState() => _TwoFactorAuthPageState();
}

class _TwoFactorAuthPageState extends State<TwoFactorAuthPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  bool _twoFactorEnabled = false;
  String _phoneNumber = '';
  final String _verificationId = '';
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  String _selectedCountryCode = "+964";
  String _selectedCountryFlag = "🇮🇶";

  @override
  void initState() {
    super.initState();
    _loadTwoFactorSettings();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadTwoFactorSettings() async {
    try {
      final doc = await _db.collection('users').doc(_currentUserId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _twoFactorEnabled = data['twoFactorEnabled'] ?? false;
          _phoneNumber = data['phoneNumber'] ?? '';
          _phoneController.text = _phoneNumber;
        });
      }
    } catch (e) {
      debugPrint('Error loading 2FA settings: $e');
    }
  }

  void _toggleTwoFactor(bool value) {
    if (!value) {
      // تعطيل 2FA
      setState(() => _isLoading = true);
      _db.collection('users').doc(_currentUserId).update({
        'twoFactorEnabled': false,
      }).then((_) {
        setState(() {
          _twoFactorEnabled = false;
          _isLoading = false;
        });
        if (mounted) {
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تعطيل التحقق بخطوتين'),
              backgroundColor: AppTheme.royalGold,
            ),
          );
        }
      }).catchError((e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('فشل تعطيل التحقق بخطوتين: $e')),
          );
        }
      });
    } else {
      // تفعيل 2FA - يطلب رقم الهاتف أولاً
      _showPhoneDialog();
    }
  }

  void _showPhoneDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'تفعيل التحقق بخطوتين',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'سيتم إرسال رمز تحقق لرقمك لضمان ملكية الحساب',
                style: TextStyle(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      showCountryPicker(
                        context: context,
                        onSelect: (Country country) {
                          setDialogState(() {
                            _selectedCountryCode = "+${country.phoneCode}";
                            _selectedCountryFlag = country.flagEmoji;
                          });
                          setState(() {
                            _selectedCountryCode = "+${country.phoneCode}";
                            _selectedCountryFlag = country.flagEmoji;
                          });
                        },
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 15),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1))),
                      child: Text("$_selectedCountryFlag $_selectedCountryCode",
                          style: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: '77000000',
                        hintStyle: const TextStyle(color: Colors.white24),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
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
              child:
                  const Text('إلغاء', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _sendVerificationCode();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.royalGold,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('إرسال الرمز',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendVerificationCode() async {
    String phoneInput = _phoneController.text.trim();
    if (phoneInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال رقم الهاتف')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // استخدام النظام الموحد والمؤمن لإرسال الرمز
      await authService.sendOTP(
        phoneInput,
        countryCode: _selectedCountryCode,
        allowAnonymous: false,
      );

      setState(() => _isLoading = false);
      if (mounted) {
        _showCodeDialog();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل إرسال الرمز: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showCodeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'أدخل رمز التحقق',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'رمز التحقق (6 أرقام)',
                labelStyle:
                    TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _verifyCode();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.royalGold,
            ),
            child: const Text('تأكيد', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال رمز تحقق صحيح')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      // التحقق من الرمز
      final verified = await authService.verifyOTP(code);

      if (verified) {
        // تحديث الرقم في Firestore وتفعيل 2FA
        await authService.updateVerifiedPhoneNumber('$_selectedCountryCode${_phoneController.text}');
        
        setState(() {
          _twoFactorEnabled = true;
          _phoneNumber = '$_selectedCountryCode${_phoneController.text}';
          _isLoading = false;
        });

        if (mounted) {
          HapticFeedback.heavyImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم تفعيل التحقق بخطوتين بنجاح ✅'),
              backgroundColor: AppTheme.royalGold,
            ),
          );
        }
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('رمز التحقق غير صحيح ❌'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في التحقق: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A12),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'التحقق بخطوتين (2FA)',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // معلومات 2FA
              _buildInfoCard(
                icon: Icons.security,
                title: 'ما هو التحقق بخطوتين؟',
                content:
                    'التحقق بخطوتين يضيف طبقة أمان إضافية لحسابك. عند تسجيل الدخول، ستحتاج إلى رمز تحقق يتم إرساله إلى هاتفك.',
              ),
              const SizedBox(height: 30),

              // حالة 2FA
              _buildSectionHeader('حالة التحقق بخطوتين'),
              _buildSwitchCard(
                icon: Icons.phonelink_lock,
                title: 'تفعيل التحقق بخطوتين',
                subtitle: _twoFactorEnabled ? 'مفعل' : 'معطل',
                value: _twoFactorEnabled,
                onChanged: _isLoading
                    ? null
                    : (val) {
                        _toggleTwoFactor(val);
                      },
              ),
              if (_twoFactorEnabled) ...[
                const SizedBox(height: 20),
                _buildDetailCard(
                  icon: Icons.phone,
                  title: 'رقم الهاتف المسجل',
                  value: _phoneNumber,
                ),
              ],
              const SizedBox(height: 30),

              // معلومات إضافية
              _buildInfoCard(
                icon: Icons.info_outline,
                title: 'معلومات مهمة',
                content:
                    'لتفعيل التحقق بخطوتين، يجب أن يكون لديك رقم هاتف صالح. سيتم إرسال رمز تحقق عبر SMS.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.royalGold,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSwitchCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required void Function(bool)? onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.royalGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.royalGold, size: 22),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.royalGold,
              ),
            )
          else
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppTheme.royalGold,
              activeTrackColor: AppTheme.royalGold.withValues(alpha: 0.3),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.green, size: 22),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
