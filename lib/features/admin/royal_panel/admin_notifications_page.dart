import 'package:flutter/material.dart';
import '../../../services/notifications_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// صفحة إدارة الإشعارات الملكية (إرسال إشعار + سجل)
class AdminNotificationsPage extends StatefulWidget {
  const AdminNotificationsPage({Key? key}) : super(key: key);

  @override
  State<AdminNotificationsPage> createState() => _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends State<AdminNotificationsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _uidController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  String? _type;
  bool _loading = false;
  String? _resultMsg;

  void _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _resultMsg = null;
    });
    try {
      final res = await NotificationsService.sendPushNotification({
        'targetUid': _uidController.text.trim(),
        'title': _titleController.text.trim(),
        'body': _bodyController.text.trim(),
        'type': _type ?? 'general',
      });
      setState(() {
        _resultMsg =
            res['success'] == true ? 'تم الإرسال بنجاح' : 'فشل الإرسال';
      });
    } catch (e) {
      setState(() {
        _resultMsg = 'خطأ: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الإشعارات الملكية')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _uidController,
                    decoration: const InputDecoration(
                        labelText: 'معرّف المستخدم (uid)'),
                    validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                  ),
                  TextFormField(
                    controller: _titleController,
                    decoration:
                        const InputDecoration(labelText: 'عنوان الإشعار'),
                    validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                  ),
                  TextFormField(
                    controller: _bodyController,
                    decoration:
                        const InputDecoration(labelText: 'محتوى الإشعار'),
                    validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
                  ),
                  DropdownButtonFormField<String>(
                    value: _type,
                    items: const [
                      DropdownMenuItem(value: 'general', child: Text('عام')),
                      DropdownMenuItem(value: 'system', child: Text('نظام')),
                      DropdownMenuItem(value: 'promo', child: Text('تسويقي')),
                    ],
                    onChanged: (v) => setState(() => _type = v),
                    decoration: const InputDecoration(labelText: 'نوع الإشعار'),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _loading ? null : _sendNotification,
                    child: _loading
                        ? const CircularProgressIndicator()
                        : const Text('إرسال إشعار'),
                  ),
                  if (_resultMsg != null) ...[
                    const SizedBox(height: 8),
                    Text(_resultMsg!, style: TextStyle(color: Colors.green)),
                  ]
                ],
              ),
            ),
            const Divider(height: 32),
            const Text('سجل آخر الإشعارات:'),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: NotificationsService.notificationsStream(
                    _uidController.text.trim()),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Text('لا يوجد إشعارات بعد');
                  }
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final n = docs[i].data();
                      return ListTile(
                        title: Text(n['title'] ?? ''),
                        subtitle: Text(n['body'] ?? ''),
                        trailing: Text(n['type'] ?? ''),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
