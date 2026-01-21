import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_theme.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import 'edit_profile_page.dart';
import 'security_login_page.dart';
import 'app_appearance_page.dart';
import 'language_selection_page.dart';
import 'block_list_page.dart';
import 'auth/login_page.dart';
import 'admin/royal_admin_panel_entry.dart';
import '../main.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  bool _isNotificationEnabled = true;
  bool _isSoundEnabled = true;
  bool _isPrivateAccount = false;
  bool _isDataSaverEnabled = false;
  String _cacheSize = "0.0 MB";
  final FirestoreService _firestoreService = FirestoreService();

  final String _ownerEmail = "royaldoor86@gmail.com";

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _getCacheSize();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isSoundEnabled = prefs.getBool('sound_enabled') ?? true;
      _isDataSaverEnabled = prefs.getBool('data_saver_enabled') ?? false;
      _isPrivateAccount = prefs.getBool('private_account') ?? false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _getCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      double totalSize = 0;
      if (tempDir.existsSync()) {
        tempDir.listSync(recursive: true, followLinks: false).forEach((entity) {
          if (entity is File) {
            totalSize += entity.lengthSync();
          }
        });
      }
      setState(() {
        _cacheSize = "${(totalSize / (1024 * 1024)).toStringAsFixed(2)} MB";
      });
    } catch (e) {
      debugPrint("Error calculating cache: $e");
    }
  }

  Future<void> _handleClearCache() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.primaryBlue,
        title: const Text('مسح التخزين المؤقت', style: TextStyle(color: Colors.white)),
        content: const Text('سيتم حذف الملفات المؤقتة لتسريع التطبيق.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.white24))),
          TextButton(
            onPressed: () async {
              final tempDir = await getTemporaryDirectory();
              if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
              await _getCacheSize();
              Navigator.pop(context);
            },
            child: const Text('مسح الآن', style: TextStyle(color: AppTheme.royalGold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.primaryBlue,
        title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.white)),
        content: const Text('هل أنت متأكد من مغادرة الديوان الملكي؟', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء', style: TextStyle(color: Colors.white24))),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            child: const Text('خروج', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Locale currentLocale = Localizations.localeOf(context);
    String languageText = currentLocale.languageCode == 'ar' ? 'العربية' : 'English';
    final user = FirebaseAuth.instance.currentUser;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundBlack,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('إعدادات الحساب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: AppTheme.background(
          child: StreamBuilder<UserModel>(
            stream: user != null ? _firestoreService.streamUserData(user.uid) : null,
            builder: (context, snapshot) {
              final userData = snapshot.data;
              final bool isOwner = user?.email == _ownerEmail || (userData?.isOwner ?? false);

              return ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: [
                  if (isOwner) ...[
                    _buildSectionTitle('السيادة والتحكم الملكي'),
                    _buildSettingCard(
                      icon: Icons.shield_moon_rounded,
                      title: 'لوحة التحكم الملكية العالمية',
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const RoyalAdminPanelEntry()));
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                  _buildSectionTitle('الحساب والأمان'),
                  _buildSettingCard(
                    icon: Icons.person_outline,
                    title: 'تعديل الملف الشخصي',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilePage())),
                  ),
                  _buildSettingCard(
                    icon: Icons.security_outlined,
                    title: 'الأمان وتسجيل الدخول',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SecurityLoginPage())),
                  ),
                  _buildSettingCard(
                    icon: Icons.palette_outlined,
                    title: 'مظهر التطبيق',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AppAppearancePage())),
                  ),
                  
                  _buildSectionTitle('الخصوصية'),
                  _buildSwitchCard(
                    icon: Icons.privacy_tip_outlined,
                    title: 'حساب خاص',
                    value: _isPrivateAccount,
                    onChanged: (val) {
                      setState(() => _isPrivateAccount = val);
                      _saveSetting('private_account', val);
                    },
                  ),
                  _buildSettingCard(
                    icon: Icons.block_flipped,
                    title: 'قائمة الحظر',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BlockListPage())),
                  ),

                  _buildSectionTitle('التنبيهات والأصوات'),
                  _buildSwitchCard(
                    icon: Icons.notifications_active_outlined,
                    title: 'إشعارات التطبيق',
                    value: _isNotificationEnabled,
                    onChanged: (val) => setState(() => _isNotificationEnabled = val),
                  ),
                  _buildSwitchCard(
                    icon: Icons.volume_up_outlined,
                    title: 'أصوات التطبيق',
                    value: _isSoundEnabled,
                    onChanged: (val) {
                      setState(() => _isSoundEnabled = val);
                      _saveSetting('sound_enabled', val);
                    },
                  ),

                  _buildSectionTitle('إعدادات البيانات'),
                  _buildSwitchCard(
                    icon: Icons.data_usage,
                    title: 'توفير البيانات',
                    value: _isDataSaverEnabled,
                    onChanged: (val) {
                      setState(() => _isDataSaverEnabled = val);
                      _saveSetting('data_saver_enabled', val);
                    },
                  ),
                  _buildSettingCard(
                    icon: Icons.delete_sweep_outlined,
                    title: 'مسح التخزين المؤقت',
                    trailing: Text(_cacheSize, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                    onTap: _handleClearCache,
                  ),

                  _buildSectionTitle('عام'),
                  _buildSettingCard(
                    icon: Icons.language,
                    title: 'اللغة',
                    trailing: Text(languageText, style: const TextStyle(color: AppTheme.royalGold, fontSize: 12)),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => LanguageSelectionPage(
                        currentLocale: currentLocale,
                        onLanguageChanged: (Locale newLocale) => MyApp.updateConfig(context, newLocale: newLocale),
                      )));
                    },
                  ),
                  _buildSettingCard(icon: Icons.info_outline, title: 'حول التطبيق', onTap: () {}),
                  
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: AppTheme.gradientButton(
                      text: 'تسجيل الخروج الملكي',
                      onPressed: _handleLogout,
                      icon: Icons.logout_rounded,
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              );
            }
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
      child: Text(title, style: const TextStyle(color: AppTheme.royalGold, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.1)),
    );
  }

  Widget _buildSettingCard({required IconData icon, required String title, Widget? trailing, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: AppTheme.glassContainer(
        padding: const EdgeInsets.all(0),
        opacity: 0.03,
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.royalGold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppTheme.royalGold, size: 20),
          ),
          title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white24),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildSwitchCard({required IconData icon, required String title, required bool value, required Function(bool) onChanged}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: AppTheme.glassContainer(
        padding: const EdgeInsets.all(0),
        opacity: 0.03,
        child: SwitchListTile(
          secondary: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.royalGold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppTheme.royalGold, size: 20),
          ),
          title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          value: value,
          activeColor: AppTheme.royalGold,
          inactiveTrackColor: Colors.white10,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
