import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminDailyTasksPage extends StatefulWidget {
  const AdminDailyTasksPage({super.key});

  @override
  State<AdminDailyTasksPage> createState() => _AdminDailyTasksPageState();
}

class _AdminDailyTasksPageState extends State<AdminDailyTasksPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  bool _isAdminOrOwner = false;
  bool _loading = true;
  List categories = [];

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    final data = doc.data() ?? {};
    final email = user.email?.toLowerCase();
    final isOwner = data['isOwner'] == true;
    final isAdmin = data['role'] == 'admin';
    final isRoyalEmail =
        email == 'royaldoor86@gmail.com' || email == 'doorty86@gmail.com';
    setState(() {
      _isAdminOrOwner = isAdmin || isOwner || isRoyalEmail;
    });
    if (_isAdminOrOwner) {
      _loadTasks();
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadTasks() async {
    final doc =
        await _firestore.collection('daily_tasks_templates').doc('ar').get();
    setState(() {
      categories = doc.data()?['tasks'] ?? [];
      _loading = false;
    });
  }

  Future<void> _saveTasks() async {
    try {
      await _firestore
          .collection('daily_tasks_templates')
          .doc('ar')
          .set({'tasks': categories});
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم الحفظ بنجاح')));
        _loadTasks();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ في الحفظ: $e')));
      }
    }
  }

  void _addTask(int catIdx) {
    setState(() {
      categories[catIdx]['tasks'].add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': '',
        'desc': '',
        'type': 'coin',
        'reward': 0,
        'isAd': false,
      });
    });
  }

  void _deleteTask(int catIdx, int taskIdx) {
    setState(() {
      categories[catIdx]['tasks'].removeAt(taskIdx);
    });
  }

  void _addCategory() {
    setState(() {
      categories.add({
        'category': 'تصنيف جديد',
        'tasks': [],
      });
    });
  }

  void _deleteCategory(int catIdx) {
    setState(() {
      categories.removeAt(catIdx);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (!_isAdminOrOwner) {
      return const Scaffold(body: Center(child: Text('غير مصرح لك')));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة المهام اليومية'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box),
            tooltip: 'إضافة تصنيف',
            onPressed: _addCategory,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, catIdx) {
          final cat = categories[catIdx];
          return Card(
            margin: const EdgeInsets.all(12),
            child: ExpansionTile(
              title: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: cat['category'],
                      decoration:
                          const InputDecoration(labelText: 'اسم التصنيف'),
                      onChanged: (v) => setState(() => cat['category'] = v),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'حذف التصنيف',
                    onPressed: () => _deleteCategory(catIdx),
                  ),
                ],
              ),
              children: [
                ...List.generate(cat['tasks'].length, (taskIdx) {
                  final task = cat['tasks'][taskIdx];
                  return ListTile(
                    title: TextFormField(
                      initialValue: task['title'],
                      decoration: const InputDecoration(labelText: 'العنوان'),
                      onChanged: (v) => task['title'] = v,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextFormField(
                          initialValue: task['desc'],
                          decoration: const InputDecoration(labelText: 'الوصف'),
                          onChanged: (v) => task['desc'] = v,
                        ),
                        Row(
                          children: [
                            DropdownButton<String>(
                              value: task['type'],
                              items: const [
                                DropdownMenuItem(
                                    value: 'coin', child: Text('نجوم ⭐')),
                                DropdownMenuItem(
                                    value: 'gem', child: Text('جواهر')),
                                DropdownMenuItem(
                                    value: 'xp', child: Text('XP')),
                              ],
                              onChanged: (v) =>
                                  setState(() => task['type'] = v),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 60,
                              child: TextFormField(
                                initialValue: task['reward'].toString(),
                                decoration: const InputDecoration(
                                    labelText: 'المكافأة'),
                                keyboardType: TextInputType.number,
                                onChanged: (v) =>
                                    task['reward'] = int.tryParse(v) ?? 0,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Checkbox(
                              value: task['isAd'] ?? false,
                              onChanged: (v) =>
                                  setState(() => task['isAd'] = v),
                            ),
                            const Text('إعلان'),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteTask(catIdx, taskIdx),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: () => _addTask(catIdx),
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة مهمة'),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveTasks,
        icon: const Icon(Icons.save),
        label: const Text('حفظ التعديلات'),
      ),
    );
  }
}
