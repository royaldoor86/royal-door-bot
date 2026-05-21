import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// صفحة إدارة نظام المستويات والخبرة الملكي
class PointsXPSystemPage extends StatelessWidget {
  const PointsXPSystemPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E), // متوافق مع ثيم لوحة التحكم
      appBar: AppBar(
        title: const Text('نظام المستويات والخبرة 🏆'),
        backgroundColor: const Color(0xFF16002B),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.amber));
          }
          if (snapshot.hasError) {
            return const Center(
                child: Text('خطأ في جلب المستخدمين',
                    style: TextStyle(color: Colors.white54)));
          }
          final users = snapshot.data?.docs ?? [];
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: users.length,
            itemBuilder: (context, i) {
              final u = users[i].data() as Map<String, dynamic>;
              return Card(
                color: Colors.white.withValues(alpha: 0.05),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  title: Text(u['name'] ?? 'مستخدم',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Wrap(
                      // تم تغيير Row إلى Wrap لإصلاح الـ Horizontal Overflow
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _statText(
                            'نجوم ⭐: ${u['stars'] ?? u['coins'] ?? 0}', Colors.blueAccent),
                        _statText('خبرة XP: ${u['royalXP'] ?? u['xp'] ?? 0}', Colors.greenAccent),
                        _statText(
                            'مستوى: ${u['level'] ?? 1}', Colors.orangeAccent),
                      ],
                    ),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      _showUpdatePointsXPDialog(context, users[i].id, u);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: const Size(60, 32)),
                    child: const Text('تحديث', style: TextStyle(fontSize: 12)),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _statText(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(text,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w500)),
    );
  }

  void _showUpdatePointsXPDialog(
      BuildContext context, String userId, Map<String, dynamic> userData) {
    final coinsController =
        TextEditingController(text: (userData['stars'] ?? userData['coins'] ?? 0).toString());
    final xpController =
        TextEditingController(text: userData['xp']?.toString() ?? '0');
    final levelController =
        TextEditingController(text: userData['level']?.toString() ?? '1');

    bool loading = false;
    bool success = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A2E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text('تحديث المستوى والخبرة XP',
                  style: TextStyle(color: Colors.white, fontSize: 18)),
              content: ConstrainedBox(
                // إضافة قيود لإصلاح الـ Vertical Overflow
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTextField(
                          coinsController, 'النجوم ⭐', TextInputType.number),
                      const SizedBox(height: 12),
                      _buildTextField(
                          xpController, 'خبرة XP', TextInputType.number),
                      const SizedBox(height: 12),
                      _buildTextField(
                          levelController, 'المستوى', TextInputType.number),
                      if (loading) ...[
                        const SizedBox(height: 20),
                        const CircularProgressIndicator(color: Colors.amber),
                      ],
                      if (success) ...[
                        const SizedBox(height: 15),
                        const Text('تم التحديث بنجاح 🎉',
                            style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold)),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: loading ? null : () => Navigator.pop(ctx),
                  child: const Text('إلغاء',
                      style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          setState(() {
                            loading = true;
                            success = false;
                          });
                          try {
                            final int newStars = int.tryParse(coinsController.text) ?? (userData['stars'] ?? userData['coins'] ?? 0);
                            final int newXP = int.tryParse(xpController.text) ?? (userData['royalXP'] ?? userData['xp'] ?? 0);
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(userId)
                                .update({
                              'stars': newStars,
                              'coins': newStars, // Sync for legacy
                              'royalXP': newXP,
                              'xp': newXP, // Sync for legacy
                              'level': int.tryParse(levelController.text) ??
                                  userData['level'],
                            });

                            setState(() {
                              success = true;
                            });
                            await Future.delayed(
                                const Duration(milliseconds: 800));
                            if (ctx.mounted) Navigator.pop(ctx);
                          } catch (e) {
                            // Error handled by state if needed, but removed unused errorMsg
                          } finally {
                            setState(() {
                              loading = false;
                            });
                          }
                        },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black),
                  child: const Text('حفظ التعديلات'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, TextInputType type) {
    return TextField(
      controller: controller,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.amber, fontSize: 14),
        enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.white24)),
        focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.amber)),
      ),
    );
  }
}
