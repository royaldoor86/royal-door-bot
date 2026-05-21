import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// صفحة إدارة النصوص واللغات الملكية
class TextsLanguagesSystemPage extends StatelessWidget {
  const TextsLanguagesSystemPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('النصوص واللغات')),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('app_texts').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('خطأ في جلب النصوص'));
          }
          final texts = snapshot.data?.docs ?? [];
          return ListView.builder(
            itemCount: texts.length,
            itemBuilder: (context, i) {
              final t = texts[i].data();
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  title: Text(t['key'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('العربية: ${t['ar'] ?? ''}',
                            style: const TextStyle(color: Colors.blue)),
                        Text('الإنجليزية: ${t['en'] ?? ''}',
                            style: const TextStyle(color: Colors.green)),
                      ],
                    ),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      _showEditTextDialog(context, texts[i].id, t);
                    },
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(100, 36)),
                    child: const Text('تعديل'),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showEditTextDialog(context, null, null);
        },
        tooltip: 'إضافة نص جديد',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEditTextDialog(
      BuildContext context, String? docId, Map<String, dynamic>? textData) {
    final keyController = TextEditingController(text: textData?['key'] ?? '');
    final arController = TextEditingController(text: textData?['ar'] ?? '');
    final enController = TextEditingController(text: textData?['en'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) {
        bool loading = false;
        String? errorMsg;
        bool success = false;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(docId == null ? 'إضافة نص جديد' : 'تعديل النص'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: keyController,
                    decoration: const InputDecoration(labelText: 'المفتاح'),
                  ),
                  TextField(
                    controller: arController,
                    decoration: const InputDecoration(labelText: 'النص العربي'),
                  ),
                  TextField(
                    controller: enController,
                    decoration:
                        const InputDecoration(labelText: 'النص الإنجليزي'),
                  ),
                  if (loading) ...[
                    const SizedBox(height: 12),
                    const CircularProgressIndicator(),
                  ],
                  if (success) ...[
                    const SizedBox(height: 8),
                    const Text('تم الحفظ بنجاح 🎉',
                        style: TextStyle(
                            color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                  if (errorMsg != null) ...[
                    const SizedBox(height: 8),
                    Text(errorMsg!, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: loading ? null : () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: loading
                    ? null
                    : () async {
                        setState(() {
                          loading = true;
                          errorMsg = null;
                          success = false;
                        });
                        try {
                          if (keyController.text.trim().isEmpty) {
                            setState(() {
                              errorMsg = 'يجب إدخال مفتاح النص';
                            });
                            return;
                          }
                          if (docId == null) {
                            await FirebaseFirestore.instance
                                .collection('app_texts')
                                .add({
                              'key': keyController.text.trim(),
                              'ar': arController.text.trim(),
                              'en': enController.text.trim(),
                            });
                          } else {
                            await FirebaseFirestore.instance
                                .collection('app_texts')
                                .doc(docId)
                                .update({
                              'key': keyController.text.trim(),
                              'ar': arController.text.trim(),
                              'en': enController.text.trim(),
                            });
                          }
                          setState(() {
                            success = true;
                          });
                          await Future.delayed(const Duration(seconds: 1));
                          Navigator.pop(ctx);
                        } catch (e) {
                          setState(() {
                            errorMsg = 'خطأ: $e';
                          });
                        } finally {
                          setState(() {
                            loading = false;
                          });
                        }
                      },
                style:
                    ElevatedButton.styleFrom(minimumSize: const Size(100, 36)),
                child: const Text('حفظ'),
              ),
            ],
          ),
        );
      },
    );
  }
}
