import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_theme.dart';

class VoiceRoomSettingsPage extends StatefulWidget {
  const VoiceRoomSettingsPage({super.key});

  @override
  State<VoiceRoomSettingsPage> createState() => _VoiceRoomSettingsPageState();
}

class _VoiceRoomSettingsPageState extends State<VoiceRoomSettingsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  bool _autoJoinEnabled = false;
  bool _micAutoEnabled = true;
  bool _speakerAutoEnabled = true;
  double _micVolume = 0.8;
  double _speakerVolume = 1.0;
  bool _noiseCancellation = true;
  bool _echoCancellation = true;

  @override
  void initState() {
    super.initState();
    _loadVoiceSettings();
  }

  Future<void> _loadVoiceSettings() async {
    try {
      final doc = await _db.collection('users').doc(_currentUserId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _autoJoinEnabled = data['autoJoinEnabled'] ?? false;
          _micAutoEnabled = data['micAutoEnabled'] ?? true;
          _speakerAutoEnabled = data['speakerAutoEnabled'] ?? true;
          _micVolume = (data['micVolume'] ?? 0.8).toDouble();
          _speakerVolume = (data['speakerVolume'] ?? 1.0).toDouble();
          _noiseCancellation = data['noiseCancellation'] ?? true;
          _echoCancellation = data['echoCancellation'] ?? true;
        });
      }
    } catch (e) {
      debugPrint('Error loading voice settings: $e');
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    try {
      await _db.collection('users').doc(_currentUserId).update({key: value});
      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('Error updating voice setting: $e');
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
            'إعدادات الغرف الصوتية',
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
              // إعدادات الدخول
              _buildSectionHeader('إعدادات الدخول'),
              _buildSwitchCard(
                icon: Icons.login,
                title: 'الدخول التلقائي',
                subtitle: 'الدخول تلقائياً إلى الغرف الصوتية',
                value: _autoJoinEnabled,
                onChanged: (val) {
                  setState(() => _autoJoinEnabled = val);
                  _updateSetting('autoJoinEnabled', val);
                },
              ),
              const SizedBox(height: 30),

              // إعدادات الميكروفون
              _buildSectionHeader('إعدادات الميكروفون'),
              _buildSwitchCard(
                icon: Icons.mic,
                title: 'تفعيل الميكروفون تلقائياً',
                subtitle: 'تشغيل الميكروفون عند الدخول للغرفة',
                value: _micAutoEnabled,
                onChanged: (val) {
                  setState(() => _micAutoEnabled = val);
                  _updateSetting('micAutoEnabled', val);
                },
              ),
              _buildSliderCard(
                icon: Icons.volume_up,
                title: 'مستوى صوت الميكروفون',
                subtitle: '${(_micVolume * 100).toInt()}%',
                value: _micVolume,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                onChanged: (val) {
                  setState(() => _micVolume = val);
                  _updateSetting('micVolume', val);
                },
              ),
              _buildSwitchCard(
                icon: Icons.graphic_eq,
                title: 'إلغاء الضوضاء',
                subtitle: 'تقليل الضوضاء الخلفية',
                value: _noiseCancellation,
                onChanged: (val) {
                  setState(() => _noiseCancellation = val);
                  _updateSetting('noiseCancellation', val);
                },
              ),
              _buildSwitchCard(
                icon: Icons.waves,
                title: 'إلغاء الصدى',
                subtitle: 'تقليل الصدى في المكالمات',
                value: _echoCancellation,
                onChanged: (val) {
                  setState(() => _echoCancellation = val);
                  _updateSetting('echoCancellation', val);
                },
              ),
              const SizedBox(height: 30),

              // إعدادات السماعات
              _buildSectionHeader('إعدادات السماعات'),
              _buildSwitchCard(
                icon: Icons.headset,
                title: 'تفعيل السماعات تلقائياً',
                subtitle: 'تشغيل السماعات عند الدخول للغرفة',
                value: _speakerAutoEnabled,
                onChanged: (val) {
                  setState(() => _speakerAutoEnabled = val);
                  _updateSetting('speakerAutoEnabled', val);
                },
              ),
              _buildSliderCard(
                icon: Icons.volume_down,
                title: 'مستوى صوت السماعات',
                subtitle: '${(_speakerVolume * 100).toInt()}%',
                value: _speakerVolume,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                onChanged: (val) {
                  setState(() => _speakerVolume = val);
                  _updateSetting('speakerVolume', val);
                },
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

  Future<void> _resetToDefaults() async {
    setState(() {
      _autoJoinEnabled = false;
      _micAutoEnabled = true;
      _speakerAutoEnabled = true;
      _micVolume = 0.8;
      _speakerVolume = 1.0;
      _noiseCancellation = true;
      _echoCancellation = true;
    });

    await _db.collection('users').doc(_currentUserId).update({
      'autoJoinEnabled': false,
      'micAutoEnabled': true,
      'speakerAutoEnabled': true,
      'micVolume': 0.8,
      'speakerVolume': 1.0,
      'noiseCancellation': true,
      'echoCancellation': true,
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
