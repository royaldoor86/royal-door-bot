import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// صفحة إدارة صلاحيات المشرفين الملكية
class AdminRolesPermissionsPage extends StatelessWidget {
  const AdminRolesPermissionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('صلاحيات المشرفين')),
      body: StreamBuilder(
        stream:
            FirebaseFirestore.instance.collection('admin_roles').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('خطأ في جلب الصلاحيات'));
          }
          final roles = snapshot.data?.docs ?? [];
          return ListView.builder(
            itemCount: roles.length,
            itemBuilder: (context, i) {
              final r = roles[i].data();
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  title: Text(r['name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('الوصف: ${r['description'] ?? ''}',
                          style: const TextStyle(color: Colors.blue)),
                      const Text('الصلاحيات:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Wrap(
                        spacing: 8,
                        children: (r['permissions'] as List<dynamic>? ?? [])
                            .map((p) => Chip(label: Text(p.toString())))
                            .toList(),
                      ),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      _showEditRoleDialog(context, roles[i].id, r);
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
          _showEditRoleDialog(context, null, null);
        },
        tooltip: 'إضافة صلاحية جديدة',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEditRoleDialog(
      BuildContext context, String? docId, Map<String, dynamic>? roleData) {
    final nameController = TextEditingController(text: roleData?['name'] ?? '');
    final descController =
        TextEditingController(text: roleData?['description'] ?? '');
    final permissionsController = TextEditingController(
        text: (roleData?['permissions'] as List<dynamic>? ?? []).join(", "));
    showDialog(
      context: context,
      builder: (ctx) {
        bool loading = false;
        String? errorMsg;
        bool success = false;
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title:
                Text(docId == null ? 'إضافة صلاحية جديدة' : 'تعديل الصلاحية'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'اسم الدور'),
                  ),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'الوصف'),
                  ),
                  TextField(
                    controller: permissionsController,
                    decoration: const InputDecoration(
                        labelText: 'الصلاحيات (مفصولة بفاصلة)'),
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
                          if (nameController.text.trim().isEmpty) {
                            setState(() {
                              errorMsg = 'يجب إدخال اسم الدور';
                            });
                            return;
                          }
                          final permissionsList = permissionsController.text
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toList();
                          if (docId == null) {
                            await FirebaseFirestore.instance
                                .collection('admin_roles')
                                .add({
                              'name': nameController.text.trim(),
                              'description': descController.text.trim(),
                              'permissions': permissionsList,
                            });
                          } else {
                            await FirebaseFirestore.instance
                                .collection('admin_roles')
                                .doc(docId)
                                .update({
                              'name': nameController.text.trim(),
                              'description': descController.text.trim(),
                              'permissions': permissionsList,
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
