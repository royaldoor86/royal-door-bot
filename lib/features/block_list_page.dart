import 'package:flutter/material.dart';

class BlockListPage extends StatefulWidget {
  const BlockListPage({super.key});

  @override
  State<BlockListPage> createState() => _BlockListPageState();
}

class _BlockListPageState extends State<BlockListPage> {
  // قائمة وهمية للمستخدمين المحظورين (سيتم ربطها بقاعدة البيانات لاحقاً)
  final List<Map<String, String>> _blockedUsers = [
    {'name': 'مستخدم مزعج 1', 'id': 'ID: 112233'},
    {'name': 'مستخدم مزعج 2', 'id': 'ID: 445566'},
    {'name': 'مستخدم مزعج 3', 'id': 'ID: 778899'},
  ];

  void _unblockUser(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('رفع الحظر'),
        content: Text('هل أنت متأكد من رفع الحظر عن ${_blockedUsers[index]['name']}؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              setState(() {
                _blockedUsers.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم رفع الحظر بنجاح')),
              );
            },
            child: const Text('تأكيد', style: TextStyle(color: Colors.deepPurple)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('قائمة الحظر'),
        centerTitle: true,
      ),
      body: _blockedUsers.isEmpty
          ? const Center(
              child: Text('قائمة الحظر فارغة', style: TextStyle(color: Colors.grey)),
            )
          : ListView.separated(
              itemCount: _blockedUsers.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(_blockedUsers[index]['name']!),
                  subtitle: Text(_blockedUsers[index]['id']!),
                  trailing: OutlinedButton(
                    onPressed: () => _unblockUser(index),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text('رفع الحظر'),
                  ),
                );
              },
            ),
    );
  }
}
