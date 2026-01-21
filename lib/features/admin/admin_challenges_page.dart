import 'package:flutter/material.dart';
import '../../services/challenges_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// صفحة إدارة التحديات الإدارية (عالمية)

class AdminChallengesPage extends StatelessWidget {
  const AdminChallengesPage({Key? key}) : super(key: key);

  void _showUpdatePointsXPDialog(
      BuildContext context, String userId, Map<String, dynamic> userData) {
    final coinsController =
        TextEditingController(text: userData['coins']?.toString() ?? '0');
    final xpController =
        TextEditingController(text: userData['xp']?.toString() ?? '0');
    final levelController =
        TextEditingController(text: userData['level']?.toString() ?? '1');
    showDialog(
      context: context,
      builder: (ctx) {
        bool loading = false;
        String? errorMsg;
        bool success = false;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('تحديث النقاط والخبرة'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: coinsController,
                  decoration: const InputDecoration(labelText: 'النقاط'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: xpController,
                  decoration: const InputDecoration(labelText: 'الخبرة'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: levelController,
                  decoration: const InputDecoration(labelText: 'المستوى'),
                  keyboardType: TextInputType.number,
                ),
                if (loading) ...[
                  const SizedBox(height: 12),
                  const CircularProgressIndicator(),
                ],
                if (success) ...[
                  const SizedBox(height: 8),
                  Text('تم التحديث بنجاح 🎉',
                      style: TextStyle(
                          color: Colors.green, fontWeight: FontWeight.bold)),
                ],
                if (errorMsg != null) ...[
                  const SizedBox(height: 8),
                  Text(errorMsg!, style: const TextStyle(color: Colors.red)),
                ],
              ],
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
                          final res =
                              await ChallengesService.updateUserPointsXP(
                            uid: userId,
                            points: int.tryParse(coinsController.text),
                            xp: int.tryParse(xpController.text),
                            level: int.tryParse(levelController.text),
                          );
                          if (res['success'] == true) {
                            setState(() {
                              success = true;
                            });
                            await Future.delayed(const Duration(seconds: 1));
                            Navigator.pop(ctx);
                          } else {
                            setState(() {
                              errorMsg = res['message'] ?? 'فشل التحديث';
                            });
                          }
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
                    ElevatedButton.styleFrom(minimumSize: const Size(120, 36)),
                child: const Text('تحديث'),
              ),
            ],
          ),
        );
      },
    );
  }

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
                        const InputDecoration(labelText: 'المكافأة (نقاط)'),
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
                                  await ChallengesService.manageChallenge({
                                    'action': 'delete',
                                    'challengeId': docs[i].id,
                                  });
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
        child: const Icon(Icons.add),
        tooltip: 'إضافة تحدي جديد',
      ),
    );
  }
}
