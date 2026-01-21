import 'package:flutter/material.dart';

class SecurityLoginPage extends StatefulWidget {
  const SecurityLoginPage({super.key});

  @override
  State<SecurityLoginPage> createState() => _SecurityLoginPageState();
}

class _SecurityLoginPageState extends State<SecurityLoginPage> {
  // حالات الاتصال (وهمية للعرض التفاعلي)
  bool _isGoogleConnected = true;
  bool _isFacebookConnected = false;
  bool _isPhoneConnected = true;
  bool _isEmailConnected = true;
  bool _isTwoFactorEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الأمان وتسجيل الدخول'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _buildSectionTitle('وسائل تسجيل الدخول'),
          _buildSocialItem(
            icon: Icons.email_outlined,
            title: 'البريد الإلكتروني',
            subtitle: _isEmailConnected ? 'royal.door@example.com' : 'غير مرتبط',
            color: Colors.orange,
            isConnected: _isEmailConnected,
            onToggle: () => _toggleConnection('البريد الإلكتروني', _isEmailConnected, (val) => _isEmailConnected = val),
          ),
          _buildSocialItem(
            icon: Icons.g_mobiledata,
            title: 'جوجل (Google)',
            subtitle: _isGoogleConnected ? 'user@gmail.com' : 'غير مرتبط',
            color: Colors.red,
            isConnected: _isGoogleConnected,
            onToggle: () => _toggleConnection('جوجل', _isGoogleConnected, (val) => _isGoogleConnected = val),
          ),
          _buildSocialItem(
            icon: Icons.facebook,
            title: 'فيسبوك (Facebook)',
            subtitle: _isFacebookConnected ? 'Royal Door FB' : 'غير مرتبط',
            color: Colors.blue,
            isConnected: _isFacebookConnected,
            onToggle: () => _toggleConnection('فيسبوك', _isFacebookConnected, (val) => _isFacebookConnected = val),
          ),
          _buildSocialItem(
            icon: Icons.phone,
            title: 'رقم الهاتف',
            subtitle: _isPhoneConnected ? '+964 *******88' : 'غير مرتبط',
            color: Colors.green,
            isConnected: _isPhoneConnected,
            onToggle: () => _toggleConnection('رقم الهاتف', _isPhoneConnected, (val) => _isPhoneConnected = val),
          ),
          const Divider(),
          _buildSectionTitle('كلمة المرور والأمان'),
          _buildActionItem(
            icon: Icons.lock_outline,
            title: 'تغيير كلمة المرور',
            onTap: () => _showChangePasswordDialog(),
          ),
          _buildActionItem(
            icon: Icons.verified_user_outlined,
            title: 'المصادقة الثنائية',
            subtitle: _isTwoFactorEnabled ? 'نشط' : 'قيد الإيقاف',
            onTap: () => _showTwoFactorDialog(),
          ),
          const Divider(),
          _buildSectionTitle('الأجهزة والجلسات'),
          _buildActionItem(
            icon: Icons.devices,
            title: 'الأجهزة النشطة',
            subtitle: 'Samsung S24 Ultra (هذا الجهاز)',
            onTap: () => _showActiveSessionsDialog(),
          ),
          const Divider(),
          _buildSectionTitle('منطقة الخطر'),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('حذف الحساب نهائياً', style: TextStyle(color: Colors.red)),
            subtitle: const Text('سيتم مسح كافة بياناتك ولا يمكن التراجع'),
            onTap: () => _showDeleteDialog(context),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.deepPurple,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildSocialItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isConnected,
    required VoidCallback onToggle,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: TextButton(
        onPressed: onToggle,
        child: Text(
          isConnected ? 'إلغاء الربط' : 'ربط الآن',
          style: TextStyle(color: isConnected ? Colors.grey : Colors.deepPurple, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.deepPurple),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  // --- دوال الأكشن التفاعلية ---

  void _toggleConnection(String name, bool currentState, Function(bool) updateState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(currentState ? 'إلغاء ربط $name' : 'ربط $name'),
        content: Text(currentState 
          ? 'هل أنت متأكد من إلغاء ربط حسابك بـ $name؟' 
          : 'سيتم توجيهك لتسجيل الدخول وربط حسابك بـ $name.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              setState(() => updateState(!currentState));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(currentState ? 'تم إلغاء الربط بنجاح' : 'تم الربط بنجاح')),
              );
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تغيير كلمة المرور'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: oldPassController, decoration: const InputDecoration(labelText: 'كلمة المرور القديمة'), obscureText: true),
            TextField(controller: newPassController, decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة'), obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تغيير كلمة المرور بنجاح')));
            },
            child: const Text('تحديث'),
          ),
        ],
      ),
    );
  }

  void _showTwoFactorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('المصادقة الثنائية'),
        content: Text(_isTwoFactorEnabled 
          ? 'هل تريد إيقاف المصادقة الثنائية؟' 
          : 'تفعيل المصادقة الثنائية يزيد من أمان حسابك عبر إرسال رمز تحقق لهاتفك عند تسجيل الدخول.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              setState(() => _isTwoFactorEnabled = !_isTwoFactorEnabled);
              Navigator.pop(context);
            },
            child: Text(_isTwoFactorEnabled ? 'إيقاف' : 'تفعيل'),
          ),
        ],
      ),
    );
  }

  void _showActiveSessionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('الأجهزة والجلسات'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone_android, color: Colors.green),
              title: const Text('Samsung S24 Ultra'),
              subtitle: const Text('نشط الآن - العراق، بغداد'),
            ),
            ListTile(
              leading: const Icon(Icons.laptop, color: Colors.grey),
              title: const Text('Windows PC'),
              subtitle: const Text('آخر نشاط: منذ يومين'),
              trailing: TextButton(onPressed: () {}, child: const Text('إنهاء', style: TextStyle(color: Colors.red))),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
          TextButton(onPressed: () {}, child: const Text('إنهاء جميع الجلسات', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الحساب نهائياً', style: TextStyle(color: Colors.red)),
        content: const Text('تحذير: هذا الإجراء سيؤدي إلى حذف كافة الجواهر، الكوينز، الأصدقاء، والبيانات بشكل نهائي ولا يمكن التراجع عنه.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال طلب حذف الحساب')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف الحساب', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
