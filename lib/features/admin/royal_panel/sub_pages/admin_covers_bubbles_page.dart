import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AdminCoversBubblesPage extends StatefulWidget {
  final String type; // 'covers' or 'bubbles'
  const AdminCoversBubblesPage({super.key, required this.type});

  @override
  State<AdminCoversBubblesPage> createState() => _AdminCoversBubblesPageState();
}

class _AdminCoversBubblesPageState extends State<AdminCoversBubblesPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  void _showAddEditDialog([String? id, Map<String, dynamic>? data]) {
    if (data != null) {
      _nameController.text = data['name'] ?? '';
      _urlController.text = data['url'] ?? '';
      _priceController.text = (data['price'] ?? 0).toString();
    } else {
      _nameController.clear();
      _urlController.clear();
      _priceController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(id == null ? 'إضافة عنصر جديد' : 'تعديل العنصر', style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'الاسم', labelStyle: TextStyle(color: Colors.white70)), style: const TextStyle(color: Colors.white)),
              TextField(controller: _urlController, decoration: const InputDecoration(labelText: 'رابط الصورة', labelStyle: TextStyle(color: Colors.white70)), style: const TextStyle(color: Colors.white)),
              TextField(controller: _priceController, decoration: const InputDecoration(labelText: 'السعر (نجوم ⭐)', labelStyle: TextStyle(color: Colors.white70)), keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              final Map<String, dynamic> item = {
                'name': _nameController.text,
                'url': _urlController.text,
                'price': int.tryParse(_priceController.text) ?? 0,
                'isActive': true,
              };
              if (id == null) {
                await _db.collection(widget.type).add(item);
              } else {
                await _db.collection(widget.type).doc(id).update(item);
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A1F1C),
        appBar: AppBar(
          backgroundColor: const Color(0xFF051211),
          title: Text(widget.type == 'covers' ? 'إدارة الأغلفة الملكية' : 'إدارة فقاعات الدردشة', style: const TextStyle(color: Color(0xFFD4AF37))),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddEditDialog(),
          backgroundColor: const Color(0xFFD4AF37),
          child: const Icon(Icons.add, color: Colors.black),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _db.collection(widget.type).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snapshot.data!.docs;
            return GridView.builder(
              padding: const EdgeInsets.all(15),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.8),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final id = docs[index].id;
                return Container(
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                          child: CachedNetworkImage(imageUrl: data['url'] ?? '', fit: BoxFit.cover, width: double.infinity, placeholder: (c,u) => const Icon(Icons.image, color: Colors.white10)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Text(data['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                            Text('${data['price']} ⭐', style: const TextStyle(color: Colors.amber, fontSize: 10)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 18), onPressed: () => _showAddEditDialog(id, data)),
                                IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18), onPressed: () async {
                                  bool? confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                                    backgroundColor: const Color(0xFF1A1A2E),
                                    title: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white)),
                                    content: const Text('هل تريد حذف هذا العنصر؟'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
                                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.redAccent))),
                                    ],
                                  ));
                                  if (confirm == true) await _db.collection(widget.type).doc(id).delete();
                                }),
                              ],
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
