import 'package:flutter/material.dart';
import '../../services/challenges_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// صفحة إدارة نظام النقاط والخبرة الملكي
class PointsXPSystemPage extends StatelessWidget {
  const PointsXPSystemPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('نظام النقاط والخبرة')),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('خطأ في جلب المستخدمين'));
          }
          final users = snapshot.data?.docs ?? [];
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, i) {
              final u = users[i].data();
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  title: Text(u['name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('نقاط: ${u['coins'] ?? 0}',
                          style: const TextStyle(color: Colors.blue)),
                      Text('خبرة: ${u['xp'] ?? 0}',
                          style: const TextStyle(color: Colors.green)),
                      Text('مستوى: ${u['level'] ?? 1}',
                          style: const TextStyle(color: Colors.orange)),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      _showUpdatePointsXPDialog(context, users[i].id, u);
                    },
                    style: ElevatedButton.styleFrom(
                        minimumSize: const Size(100, 36)),
                    child: const Text('تحديث'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

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
                    ElevatedButton.styleFrom(minimumSize: const Size(100, 36)),
                child: const Text('تحديث'),
              ),
            ],
          ),
        );
      },
    );
  }
}
