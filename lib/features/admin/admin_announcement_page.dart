// lib/pages/admin/admin_announcement_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marquee/marquee.dart';

import '../../models/app_announcement.dart';
import '../../services/announcement_service.dart';
import '../../theme/design_tokens.dart';
import '../../theme/reusable_widgets.dart';

class AdminAnnouncementPage extends StatefulWidget {
  const AdminAnnouncementPage({super.key});

  @override
  State<AdminAnnouncementPage> createState() => _AdminAnnouncementPageState();
}

class _AdminAnnouncementPageState extends State<AdminAnnouncementPage>
    with SingleTickerProviderStateMixin {
  final _textController = TextEditingController();
  final _imageUrlController = TextEditingController();
  bool _isActive = false;
  double _speed = 40.0;
  bool _isLoading = true;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _loadCurrent();
  }

  @override
  void dispose() {
    _textController.dispose();
    _imageUrlController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrent() async {
    try {
      final ann = await AnnouncementService.instance.getAnnouncementOnce();
      if (ann != null) {
        _textController.text = ann.text;
        _imageUrlController.text = ann.imageUrl ?? '';
        _isActive = ann.isActive;
        _speed = ann.speed;
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      _fadeController.forward();
    }
  }

  Future<void> _save() async {
    final ann = AppAnnouncement(
      text: _textController.text.trim(),
      isActive: _isActive,
      imageUrl: _imageUrlController.text.trim().isEmpty
          ? null
          : _imageUrlController.text.trim(),
      speed: _speed,
    );

    try {
      await AnnouncementService.instance.saveAnnouncement(ann);
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ مرسوم الشريط الإعلاني بنجاح ✅'),
          backgroundColor: DesignTokens.primarySapphire,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const RoyalLoadingIndicator();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عنوان القسم داخل لوحة التحكم
            const Row(
              children: [
                Icon(Icons.campaign_rounded, color: DesignTokens.primaryGold),
                SizedBox(width: 8),
                HeadingText(
                  'إدارة الشريط الإعلاني الملكي',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // إضافة معاينة حية (Live Preview) لزيادة السلاسة
            _buildLivePreview(),
            const SizedBox(height: 20),

            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const HeadingText(
                      'تفعيل الشريط الإعلاني للمواطنين',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    subtitle: const BodyText(
                        'سيظهر الشريط في أعلى الصفحات الرئيسية',
                        fontSize: 11),
                    value: _isActive,
                    activeThumbColor: DesignTokens.primaryGold,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _isActive = v);
                    },
                  ),
                  const SizedBox(height: 24),

                  // تحسين حقول الإدخال لتناسب السحب والمرونة
                  RoyalTextField(
                    controller: _textController,
                    maxLines: 3,
                    onChanged: (v) => setState(() {}),
                    labelText: 'نص المرسوم الإعلاني',
                    hintText: 'اكتب هنا نص الشريط (مثل عروض، تنبيهات، تحديثات...)',
                  ),
                  const SizedBox(height: 20),

                  RoyalTextField(
                    controller: _imageUrlController,
                    labelText: 'رابط أيقونة الإعلان (اختياري)',
                    prefixIcon: Icons.link,
                    hintText: 'https://example.com/icon.png',
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      const Icon(Icons.speed_rounded,
                          color: DesignTokens.primaryGold, size: 18),
                      const SizedBox(width: 10),
                      const BodyText('سرعة التنقل', fontSize: 13),
                      Expanded(
                        child: Slider(
                          value: _speed,
                          min: 10,
                          max: 150,
                          activeColor: DesignTokens.primaryGold,
                          inactiveColor: Colors.white10,
                          divisions: 14,
                          label: _speed.toStringAsFixed(0),
                          onChanged: (v) {
                            if ((v - _speed).abs() > 5) {
                              HapticFeedback.selectionClick();
                            }
                            setState(() => _speed = v);
                          },
                        ),
                      ),
                      Text(_speed.toStringAsFixed(0),
                          style: const TextStyle(
                              color: DesignTokens.primaryGold,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 30),

                  RoyalButton(
                    label: 'حفظ وتعميم الإعلان',
                    onPressed: _save,
                    icon: Icons.auto_awesome_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLivePreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(right: 8, bottom: 8),
          child: CaptionText('معاينة حية للنظام:', fontSize: 11),
        ),
        Container(
          height: 45,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: _isActive
                    ? DesignTokens.primaryGold.withValues(alpha: 0.3)
                    : Colors.white10),
          ),
          child: _textController.text.isEmpty
              ? const Center(
                  child: BodyText('اكتب شيئاً للمعاينة...',
                      fontSize: 12))
              : Marquee(
                  text: _textController.text,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14),
                  scrollAxis: Axis.horizontal,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  blankSpace: 100.0,
                  velocity: _speed,
                  pauseAfterRound: const Duration(seconds: 1),
                  accelerationDuration: const Duration(seconds: 1),
                  accelerationCurve: Curves.linear,
                  decelerationDuration: const Duration(milliseconds: 500),
                  decelerationCurve: Curves.easeOut,
                ),
        ),
      ],
    );
  }
}
