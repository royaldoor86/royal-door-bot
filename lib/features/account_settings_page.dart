import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_manager.dart';
import '../app_theme.dart';
import '../theme/design_tokens.dart';
import '../theme/reusable_widgets.dart';
import '../services/firestore_service.dart';
import '../services/localization_service.dart';
import '../models/user_model.dart';
import 'edit_profile_page.dart';
import 'security_login_page.dart';
import 'app_appearance_page.dart';
import 'language_selection_page.dart';
import 'block_list_page.dart';
import 'auth/login_page.dart';
import 'admin/royal_admin_panel_entry.dart';
import 'about_app_page.dart';
import '../main.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  // bool _isDataSaverEnabled = false; // Removed unused field
  String _cacheSize = "0.0 MB";
  final FirestoreService _firestoreService = FirestoreService();
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  final String _ownerEmail = "royaldoor86@gmail.com";

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _getCacheSize();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = AdManager().getBannerAd(
      size: AdSize.banner,
      onAdLoaded: () {
        setState(() {
          _isAdLoaded = true;
        });
      },
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    // final prefs = await SharedPreferences.getInstance();
    // setState(() {
    //   _isDataSaverEnabled = prefs.getBool('data_saver_enabled') ?? false;
    // });
  }

  /* // Removed unused method
  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
  */

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
    final trans = Translations.of(context);
    showDialog(
      context: context,
      builder: (context) => RoyalConfirmDialog(
        title: trans.get('logout').contains('خروج') ? 'مسح ذاكرة التخزين المؤقت' : 'Clear Cache',
        message: trans.get('logout').contains('خروج')
            ? 'سيتم حذف الملفات المؤقتة لتسريع التطبيق.'
            : 'Temporary files will be deleted to speed up the app.',
        confirmLabel: trans.get('logout').contains('خروج') ? 'مسح الآن' : 'Clear Now',
        cancelLabel: trans.get('logout').contains('خروج') ? 'إلغاء' : 'Cancel',
        icon: Icons.delete_sweep_outlined,
        onConfirm: () async {
          final tempDir = await getTemporaryDirectory();
          if (tempDir.existsSync()) {
            tempDir.deleteSync(recursive: true);
          }
          await _getCacheSize();
        },
      ),
    );
  }

  Future<void> _handleLogout() async {
    final trans = Translations.of(context);
    showDialog(
      context: context,
      builder: (context) => RoyalConfirmDialog(
        title: trans.get('logout'),
        message: trans.get('logout').contains('خروج')
            ? 'هل أنت متأكد من المغادرة؟'
            : 'Are you sure you want to leave?',
        confirmLabel: trans.get('logout').contains('خروج') ? 'خروج' : 'Logout',
        cancelLabel: trans.get('logout').contains('خروج') ? 'إلغاء' : 'Cancel',
        onConfirm: () async {
          await FirebaseAuth.instance.signOut();
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginPage()),
              (route) => false,
            );
          }
        },
        icon: Icons.logout_rounded,
        iconColor: DesignTokens.semanticError,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Locale currentLocale = Localizations.localeOf(context);
    String languageText =
        currentLocale.languageCode == 'ar' ? 'العربية' : 'English';
    final user = FirebaseAuth.instance.currentUser;
    final trans = Translations.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        bottomNavigationBar: _isAdLoaded && _bannerAd != null
            ? Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                height: _bannerAd!.size.height.toDouble(),
                width: _bannerAd!.size.width.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              )
            : null,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(trans.get('account_settings'),
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: AppTheme.background(
          child: StreamBuilder<UserModel>(
              stream: user != null
                  ? _firestoreService.streamUserData(user.uid)
                  : null,
              builder: (context, snapshot) {
                final userData = snapshot.data;
                if (snapshot.connectionState == ConnectionState.waiting ||
                    userData == null) {
                  return const RoyalLoadingIndicator();
                }
                final bool isOwner =
                    user?.email == _ownerEmail || userData.isOwner;

                return ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  children: [
                    if (isOwner) ...[
                      _buildSectionTitle(
                          ' السيادة والتحكم الملكي / Admin Panel'),
                      _buildSettingCard(
                        icon: Icons.shield_moon_rounded,
                        title: 'Royal Control Panel',
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const RoyalAdminPanelEntry()));
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                    _buildSectionTitle(trans.get('account_settings')),
                    _buildSettingCard(
                      icon: Icons.person_outline,
                      title: trans.get('edit_profile'),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const EditProfilePage())),
                    ),
                    _buildSettingCard(
                      icon: Icons.security_outlined,
                      title: trans.get('privacy_and_security'),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SecurityLoginPage())),
                    ),
                    _buildSettingCard(
                      icon: Icons.palette_outlined,
                      title: trans.get('appearance_settings'),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AppAppearancePage())),
                    ),
                    _buildSectionTitle(trans.get('privacy')),
                    _buildSwitchCard(
                      icon: Icons.privacy_tip_outlined,
                      title: trans.get('privacy'),
                      value: userData.isPrivate,
                      onChanged: (val) {
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(userData.uid)
                            .update({'isPrivate': val});
                      },
                    ),
                    _buildSettingCard(
                      icon: Icons.block_flipped,
                      title: 'Block List',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const BlockListPage())),
                    ),
                    _buildSectionTitle(trans.get('notifications')),
                    _buildSwitchCard(
                      icon: Icons.notifications_active_outlined,
                      title: trans.get('notifications'),
                      value: userData.notificationEnabled,
                      onChanged: (val) {
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(userData.uid)
                            .update({'notificationEnabled': val});
                      },
                    ),
                    _buildSwitchCard(
                      icon: Icons.volume_up_outlined,
                      title: 'Sound Effects',
                      value: userData.soundEnabled,
                      onChanged: (val) {
                        FirebaseFirestore.instance
                            .collection('users')
                            .doc(userData.uid)
                            .update({'soundEnabled': val});
                      },
                    ),
                    _buildSectionTitle('Data & Cache'),
                    _buildSettingCard(
                      icon: Icons.delete_sweep_outlined,
                      title: 'Clear Cache',
                      trailing: Text(_cacheSize,
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 12)),
                      onTap: _handleClearCache,
                    ),
                    _buildSectionTitle(trans.get('language')),
                    _buildSettingCard(
                      icon: Icons.language,
                      title: trans.get('language'),
                      trailing: Text(languageText,
                          style: const TextStyle(
                              color: DesignTokens.primaryGold, fontSize: 12)),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => LanguageSelectionPage(
                                      currentLocale: currentLocale,
                                      onLanguageChanged: (Locale newLocale) =>
                                          MyApp.updateConfig(context,
                                              newLocale: newLocale),
                                    )));
                      },
                    ),
                    _buildSettingCard(
                        icon: Icons.info_outline,
                        title: trans.get('about_app'),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AboutAppPage()));
                        }),
                    const SizedBox(height: 30),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: RoyalButton(
                        label: trans.get('logout'),
                        onPressed: _handleLogout,
                        icon: Icons.logout_rounded,
                      ),
                    ),
                    const SizedBox(height: 100),
                  ],
                );
              }),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 20, 25, 10),
      child: HeadingText(title,
          color: DesignTokens.primaryGold,
          fontWeight: FontWeight.bold,
          fontSize: 13),
    );
  }

  Widget _buildSettingCard(
      {required IconData icon,
      required String title,
      Widget? trailing,
      required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: GlassCard(
        padding: const EdgeInsets.all(0),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: DesignTokens.primaryGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: DesignTokens.primaryGold, size: 20),
          ),
          title: Text(title,
              style: const TextStyle(
                  color: DesignTokens.neutralWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          trailing: trailing ??
              const Icon(Icons.arrow_forward_ios,
                  size: 14, color: Colors.white24),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildSwitchCard(
      {required IconData icon,
      required String title,
      required bool value,
      required Function(bool) onChanged}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: GlassCard(
        padding: const EdgeInsets.all(0),
        child: SwitchListTile(
          secondary: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: DesignTokens.primaryGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: DesignTokens.primaryGold, size: 20),
          ),
          title: Text(title,
              style: const TextStyle(
                  color: DesignTokens.neutralWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          value: value,
          activeThumbColor: DesignTokens.primaryGold,
          inactiveTrackColor: Colors.white10,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
