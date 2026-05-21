import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminMarqueePage extends StatefulWidget {
  const AdminMarqueePage({super.key});

  @override
  State<AdminMarqueePage> createState() => _AdminMarqueePageState();
}

class _AdminMarqueePageState extends State<AdminMarqueePage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _textController = TextEditingController();
  double _velocity = 40.0;
  List<String> _announcements = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMarqueeSettings();
  }

  Future<void> _loadMarqueeSettings() async {
    final doc = await _db.collection('settings').doc('marquee').get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _velocity = _parseDouble(data['velocity'] ?? 40.0);
        _announcements = List<String>.from(data['messages'] ?? []);
      });
    }
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll('%', '')) ?? 0.0;
    }
    return 0.0;
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      // دمج كافة الإعلانات في نص واحد مفصول بمسافات لضمان التوافق مع الكود القديم إن وجد
      String fullText = _announcements.join("   |   ");

      await _db.collection('settings').doc('marquee').set({
        'text': fullText, // للنظام القديم
        'messages': _announcements, // للنظام الجديد المتعدد
        'velocity': _velocity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حفظ إعدادات الشريط بنجاح ✅')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('فشل الحفظ ❌')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addAnnouncement() {
    if (_textController.text.trim().isEmpty) return;
    setState(() {
      _announcements.add(_textController.text.trim());
      _textController.clear();
    });
  }

  void _editAnnouncement(int index) {
    final editController = TextEditingController(text: _announcements[index]);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF051211),
        title:
            const Text('تعديل الإعلان', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: editController,
          maxLines: null,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'اكتب نص الإعلان هنا...',
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () {
              final updatedText = editController.text.trim();
              if (updatedText.isNotEmpty) {
                setState(() => _announcements[index] = updatedText);
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text('حفظ', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F1A24),
        appBar: AppBar(
          title: const Text('تطوير الشريط الإعلاني الملكي',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF1B5E20),
          elevation: 0,
        ),
        body: Column(
          children: [
            _buildControlPanel(),
            Expanded(child: _buildMessagesList()),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.black26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('إضافة إعلان جديد متسلسل:',
              style: TextStyle(
                  color: Colors.amber,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'اكتب نص الإعلان هنا...',
                    hintStyle: const TextStyle(color: Colors.white24),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _addAnnouncement,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: const Icon(Icons.add, color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Text('سرعة الشريط:',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              Expanded(
                child: Slider(
                  value: _velocity,
                  min: 10,
                  max: 150,
                  activeColor: Colors.amber,
                  inactiveColor: Colors.white10,
                  onChanged: (v) => setState(() => _velocity = v),
                ),
              ),
              Text('${_velocity.toInt()} km/h',
                  style: const TextStyle(
                      color: Colors.amber, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: _announcements.length,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white10)),
          child: ListTile(
            leading: CircleAvatar(
                backgroundColor: Colors.amber.withValues(alpha: 0.1),
                child: Text('${index + 1}',
                    style: const TextStyle(color: Colors.amber))),
            title: Text(_announcements[index],
                style: const TextStyle(color: Colors.white, fontSize: 14)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white70),
                  tooltip: 'تعديل الإعلان',
                  onPressed: () => _editAnnouncement(index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_sweep_outlined,
                      color: Colors.redAccent),
                  tooltip: 'حذف الإعلان',
                  onPressed: () =>
                      setState(() => _announcements.removeAt(index)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          minimumSize: const Size(double.infinity, 55),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: _isLoading ? null : _saveSettings,
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.black)
            : const Text('تفعيل ونشر التحديثات',
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
      ),
    );
  }
}
