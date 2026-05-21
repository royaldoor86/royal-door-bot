import 'package:flutter/material.dart';
import '../../services/challenges_service.dart';

/// صفحة إدارة التحديات الإدارية (عالمية)

class AdminChallengesPage extends StatelessWidget {
  const AdminChallengesPage({super.key});

  void _showChallengeDialog(BuildContext context,
      {Map<String, dynamic>? challenge, String? challengeId}) {
    final titleController =
        TextEditingController(text: challenge?['title'] ?? '');
    final descController =
        TextEditingController(text: challenge?['description'] ?? '');
    final rewardController =
        TextEditingController(text: challenge?['reward']?.toString() ?? '');
    final durationController =
        TextEditingController(text: challenge?['duration']?.toString() ?? '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool loading = false;
        String? errorMsg;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text(challenge == null ? 'إضافة تحدي جديد' : 'تعديل التحدي'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'العنوان'),
                  ),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'الوصف'),
                  ),
                  TextField(
                    controller: rewardController,
                    decoration:
                        const InputDecoration(labelText: 'المكافأة (نجوم ⭐)'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: durationController,
                    decoration:
                        const InputDecoration(labelText: 'المدة (أيام)'),
                    keyboardType: TextInputType.number,
                  ),
                  if (loading) ...[
                    const SizedBox(height: 12),
                    const CircularProgressIndicator(),
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
                        });
                        final data = {
                          'title': titleController.text.trim(),
                          'description': descController.text.trim(),
                          'reward': int.tryParse(rewardController.text) ?? 0,
                          'duration':
                              int.tryParse(durationController.text) ?? 0,
                        };
                        try {
                          if (challenge == null) {
                            // إضافة createdAt عند الإضافة فقط
                            final res =
                                await ChallengesService.manageChallenge({
                              'action': 'add',
                              'challengeData': {
                                ...data,
                                'createdAt':
                                    DateTime.now().toUtc().toIso8601String(),
                              },
                            });
                            if (res['success'] != true) {
                              setState(() {
                                errorMsg = res['message'] ?? 'فشل الإضافة';
                              });
                              return;
                            }
                          } else {
                            final res =
                                await ChallengesService.manageChallenge({
                              'action': 'update',
                              'challengeId': challengeId,
                              'challengeData': data,
                            });
                            if (res['success'] != true) {
                              setState(() {
                                errorMsg = res['message'] ?? 'فشل التعديل';
                              });
                              return;
                            }
                          }
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
                child: Text(challenge == null ? 'إضافة' : 'تعديل'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة التحديات'),
      ),
      body: Column(
        children: [
          // تم حذف مربعات النقاط والخبرة من إدارة التحديات
          Expanded(
            child: StreamBuilder(
              stream: ChallengesService.challengesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('حدث خطأ: ${snapshot.error}'));
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(child: Text('لا توجد تحديات حالياً.'));
                }
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data();
                    return Card(
                      margin: const EdgeInsets.all(12),
                      child: ListTile(
                        title: Text(data['title'] ?? ''),
                        subtitle: Text(data['description'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () {
                                _showChallengeDialog(context,
                                    challenge: data, challengeId: docs[i].id);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('تأكيد الحذف'),
                                    content: const Text(
                                        'هل أنت متأكد من حذف هذا التحدي؟'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('إلغاء'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('حذف'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  if (context.mounted) {
                                    await ChallengesService.manageChallenge({
                                      'action': 'delete',
                                      'challengeId': docs[i].id,
                                    });
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showChallengeDialog(context);
        },
        tooltip: 'إضافة تحدي جديد',
        child: const Icon(Icons.add),
      ),
    );
  }
}
