import 'package:flutter/material.dart';

// ملاحظة: الإشعارات تظهر مباشرة عند استقبالها (foreground/background) عبر flutter_local_notifications.
// يمكن توسيع هذه الصفحة لاحقًا لعرض سجل الإشعارات من Firestore.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الإشعارات')),
      body: const Center(child: Text('صفحة الإشعارات')),
    );
  }
}
