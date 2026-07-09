// lib/pages/admin/admin_announcement_page.dart
import 'package:flutter/material.dart';

import '../../models/app_announcement.dart';
import '../../services/announcement_service.dart';

class AdminAnnouncementPage extends StatefulWidget {
  const AdminAnnouncementPage({super.key});

  @override
  State<AdminAnnouncementPage> createState() => _AdminAnnouncementPageState();
}

class _AdminAnnouncementPageState extends State<AdminAnnouncementPage> {
  final _textController = TextEditingController();
  final _imageUrlController = TextEditingController();
  bool _isActive = false;
  double _speed = 40.0;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrent();
  }

  @override
  void dispose() {
    _textController.dispose();
    _imageUrlController.dispose();
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
    } catch (_) {
      // ممكن تضيف سناك بار لو تريد
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ الشريط الإعلاني بنجاح ✅')),
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
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان القسم داخل لوحة التحكم
          const Row(
            children: [
              Icon(Icons.campaign_rounded, color: Colors.amberAccent),
              SizedBox(width: 8),
              Text(
                'الشريط الإعلاني المتحرك',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Card(
            color: Colors.white.withValues(alpha: 0.04),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text(
                      'تفعيل الشريط الإعلاني',
                      style: TextStyle(color: Colors.white),
                    ),
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _textController,
                    maxLines: 3,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'نص الإعلان',
                      labelStyle: TextStyle(color: Colors.white70),
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                      hintText:
                          'اكتب هنا نص الشريط (مثل عروض، تنبيهات، تحديثات...)',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _imageUrlController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'رابط صورة صغيرة (اختياري)',
                      labelStyle: TextStyle(color: Colors.white70),
                      border: OutlineInputBorder(),
                      hintText: 'https://example.com/image.png',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'سرعة الحركة',
                        style: TextStyle(color: Colors.white),
                      ),
                      Expanded(
                        child: Slider(
                          value: _speed,
                          min: 10,
                          max: 100,
                          divisions: 9,
                          label: _speed.toStringAsFixed(0),
                          onChanged: (v) => setState(() => _speed = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 45,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
                      label: const Text('حفظ التغييرات'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
