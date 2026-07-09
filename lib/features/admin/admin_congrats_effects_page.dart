import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// صفحة إدارة التهاني والمؤثرات الملكية
class AdminCongratsEffectsPage extends StatelessWidget {
  const AdminCongratsEffectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التهاني والمؤثرات')),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('congrats_effects')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('خطأ في جلب التهاني'));
          }
          final effects = snapshot.data?.docs ?? [];
          return ListView.builder(
            itemCount: effects.length,
            itemBuilder: (context, i) {
              final e = effects[i].data();
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  title: Text(e['title'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('النص: ${e['text'] ?? ''}',
                          style: const TextStyle(color: Colors.blue)),
                      Text('المؤثر: ${e['effect'] ?? ''}',
                          style: const TextStyle(color: Colors.green)),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      _showEditEffectDialog(context, effects[i].id, e);
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
          _showEditEffectDialog(context, null, null);
        },
        tooltip: 'إضافة تهنئة/مؤثر جديد',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEditEffectDialog(
      BuildContext context, String? docId, Map<String, dynamic>? effectData) {
    final titleController =
        TextEditingController(text: effectData?['title'] ?? '');
    final textController =
        TextEditingController(text: effectData?['text'] ?? '');
    final effectController =
        TextEditingController(text: effectData?['effect'] ?? '');
    showDialog(
      context: context,
      builder: (ctx) {
        bool loading = false;
        String? errorMsg;
        bool success = false;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(docId == null
                ? 'إضافة تهنئة/مؤثر جديد'
                : 'تعديل التهنئة/المؤثر'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'العنوان'),
                  ),
                  TextField(
                    controller: textController,
                    decoration: const InputDecoration(labelText: 'النص'),
                  ),
                  TextField(
                    controller: effectController,
                    decoration: const InputDecoration(
                        labelText: 'المؤثر (اسم أو رابط)'),
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
                          if (titleController.text.trim().isEmpty) {
                            setState(() {
                              errorMsg = 'يجب إدخال عنوان التهنئة';
                            });
                            return;
                          }
                          if (docId == null) {
                            await FirebaseFirestore.instance
                                .collection('congrats_effects')
                                .add({
                              'title': titleController.text.trim(),
                              'text': textController.text.trim(),
                              'effect': effectController.text.trim(),
                            });
                          } else {
                            await FirebaseFirestore.instance
                                .collection('congrats_effects')
                                .doc(docId)
                                .update({
                              'title': titleController.text.trim(),
                              'text': textController.text.trim(),
                              'effect': effectController.text.trim(),
                            });
                          }
                          setState(() {
                            success = true;
                          });
                          await Future.delayed(const Duration(seconds: 1));
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            setState(() {
                              errorMsg = 'خطأ: $e';
                            });
                          }
                        } finally {
                          if (context.mounted) {
                            setState(() {
                              loading = false;
                            });
                          }
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
