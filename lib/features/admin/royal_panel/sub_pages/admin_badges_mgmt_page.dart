import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminBadgesMgmtPage extends StatefulWidget {
  const AdminBadgesMgmtPage({super.key});

  @override
  State<AdminBadgesMgmtPage> createState() => _AdminBadgesMgmtPageState();
}

class _AdminBadgesMgmtPageState extends State<AdminBadgesMgmtPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _nameController = TextEditingController();
  final _iconController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedCategory = 'badge'; // badge (فخري), achievement (إنجازات), activity (نشاط)

  void _addBadge() async {
    if (_nameController.text.isEmpty || _iconController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إكمال جميع الحقول')));
      return;
    }

    await _db.collection('badges_templates').add({
      'name': _nameController.text,
      'icon': _iconController.text,
      'price': int.parse(_priceController.text),
      'category': _selectedCategory,
      'createdAt': FieldValue.serverTimestamp(),
    });

    _nameController.clear();
    _iconController.clear();
    _priceController.clear();
    if (mounted) Navigator.pop(context);
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('إضافة شارة جديدة', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'اسم الشارة', labelStyle: TextStyle(color: Colors.white70))),
            TextField(controller: _iconController, decoration: const InputDecoration(labelText: 'الأيقونة (إيموجي)', labelStyle: TextStyle(color: Colors.white70))),
            TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'السعر (كوينز)', labelStyle: TextStyle(color: Colors.white70))),
            const SizedBox(height: 15),
            DropdownButton<String>(
              value: _selectedCategory,
              dropdownColor: const Color(0xFF1A1A2E),
              style: const TextStyle(color: Colors.amber),
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: 'badge', child: Text('فخري (متجر)')),
                DropdownMenuItem(value: 'achievement', child: Text('إنجازات (وطنية)')),
                DropdownMenuItem(value: 'activity', child: Text('نشاط (تفاعل)')),
              ],
              onChanged: (val) => setState(() => _selectedCategory = val!),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _addBadge, style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, minimumSize: const Size(double.infinity, 45)), child: const Text('حفظ الشارة', style: TextStyle(color: Colors.black))),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A12),
        appBar: AppBar(title: const Text('إدارة الشارات'), backgroundColor: const Color(0xFF1A1A2E)),
        floatingActionButton: FloatingActionButton(onPressed: _showAddDialog, backgroundColor: Colors.amber, child: const Icon(Icons.add, color: Colors.black)),
        body: StreamBuilder<QuerySnapshot>(
          stream: _db.collection('badges_templates').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final badges = snapshot.data!.docs;
            return ListView.builder(
              itemCount: badges.length,
              itemBuilder: (context, index) {
                final badge = badges[index].data() as Map<String, dynamic>;
                return ListTile(
                  leading: Text(badge['icon'], style: const TextStyle(fontSize: 30)),
                  title: Text(badge['name'], style: const TextStyle(color: Colors.white)),
                  subtitle: Text('السعر: ${badge['price']} | القسم: ${badge['category']}', style: const TextStyle(color: Colors.white54)),
                  trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _db.collection('badges_templates').doc(badges[index].id).delete()),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
