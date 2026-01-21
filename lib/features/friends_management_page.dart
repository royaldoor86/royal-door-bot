import 'package:flutter/material.dart';

class FriendsManagementPage extends StatelessWidget {
  const FriendsManagementPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إدارة الأصدقاء')),
      body: const Center(child: Text('صفحة إدارة الأصدقاء')),
    );
  }
}
