import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_theme.dart';
import '../main.dart';

class AppearanceSettingsPage extends StatefulWidget {
  const AppearanceSettingsPage({super.key});

  @override
  State<AppearanceSettingsPage> createState() => _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState extends State<AppearanceSettingsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  bool _darkMode = true;
  double _fontSize = 16.0;
  String _theme = 'royal';

  @override
  void initState() {
    super.initState();
    _loadAppearanceSettings();
  }

  Future<void> _loadAppearanceSettings() async {
    try {
      final doc = await _db.collection('users').doc(_currentUserId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _darkMode = data['darkMode'] ?? true;
          _fontSize = (data['fontSize'] ?? 16.0).toDouble();
          _theme = data['theme'] ?? 'royal';
        });
      }
    } catch (e) {
      debugPrint('Error loading appearance settings: $e');
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    try {
      await _db.collection('users').doc(_currentUserId).update({key: value});
      HapticFeedback.lightImpact();

      // تطبيق التغييرات فوراً على التطبيق
      if (mounted) {
        switch (key) {
          case 'darkMode':
            MyApp.updateConfig(
              context,
              themeMode: value ? ThemeMode.dark : ThemeMode.light,
            );
            break;
          case 'fontSize':
            MyApp.updateConfig(
              context,
              useLargeFont: value > 16.0,
            );
            break;
          case 'theme':
            MyApp.updateConfig(
              context,
              theme: value,
            );
            break;
        }
      }
    } catch (e) {
      debugPrint('Error updating appearance setting: $e');
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
            'إعدادات المظهر',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20)
              .copyWith(bottom: MediaQuery.of(context).padding.bottom + 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // الوضع الليلي
              _buildSectionHeader('الوضع'),
              _buildSwitchCard(
                icon: Icons.dark_mode,
                title: 'الوضع الليلي',
                subtitle: 'استخدام الوضع الداكن للتطبيق',
                value: _darkMode,
                onChanged: (val) {
                  setState(() => _darkMode = val);
                  _updateSetting('darkMode', val);
                },
              ),
              const SizedBox(height: 30),

              // حجم الخط
              _buildSectionHeader('حجم الخط'),
              _buildSliderCard(
                icon: Icons.format_size,
                title: 'حجم الخط',
                subtitle: '${_fontSize.toInt()}',
                value: _fontSize,
                min: 12.0,
                max: 24.0,
                divisions: 12,
                onChanged: (val) {
                  setState(() => _fontSize = val);
                  _updateSetting('fontSize', val);
                },
              ),
              const SizedBox(height: 30),

              // الثيم
              _buildSectionHeader('الثيم'),
              _buildThemeCard(
                icon: Icons.palette,
                title: 'اختيار الثيم',
                options: [
                  ThemeOption('Royal', 'royal', AppTheme.royalGold),
                  ThemeOption('Ocean', 'ocean', Colors.blue),
                  ThemeOption('Forest', 'forest', Colors.green),
                  ThemeOption('Sunset', 'sunset', Colors.orange),
                  ThemeOption('Purple', 'purple', Colors.purple),
                ],
              ),
              const SizedBox(height: 30),

              // زر إعادة التعيين
              Center(
                child: TextButton.icon(
                  onPressed: _resetToDefaults,
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  label: const Text(
                    'إعادة التعيين إلى الافتراضي',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
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
    required Function(bool) onChanged,
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

  Widget _buildSliderCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Function(double) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
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
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: AppTheme.royalGold,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard({
    required IconData icon,
    required String title,
    required List<ThemeOption> options,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: options
                .map((option) => InkWell(
                      onTap: () {
                        setState(() => _theme = option.value);
                        _updateSetting('theme', option.value);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: _theme == option.value
                              ? option.color.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _theme == option.value
                                ? option.color
                                : Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: option.color,
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              option.label,
                              style: TextStyle(
                                color: _theme == option.value
                                    ? Colors.white
                                    : Colors.white70,
                                fontSize: 13,
                                fontWeight: _theme == option.value
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _resetToDefaults() async {
    setState(() {
      _darkMode = true;
      _fontSize = 16.0;
      _theme = 'royal';
    });

    await _db.collection('users').doc(_currentUserId).update({
      'darkMode': true,
      'fontSize': 16.0,
      'theme': 'royal',
    });

    if (mounted) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إعادة التعيين إلى الافتراضي'),
          backgroundColor: AppTheme.royalGold,
        ),
      );
    }
  }
}

class ThemeOption {
  final String label;
  final String value;
  final Color color;

  ThemeOption(this.label, this.value, this.color);
}
