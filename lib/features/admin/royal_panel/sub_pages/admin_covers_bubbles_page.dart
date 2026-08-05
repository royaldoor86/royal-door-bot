import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../../../services/store_service.dart';

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
  final TextEditingController _gemsPriceController = TextEditingController();
  final TextEditingController _coinsPriceController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;
  bool _useImageUpload = false;

  Future<void> _pickImage() async {
    final XFile? image =
        await _imagePicker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<String?> _uploadImage(File image) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${widget.type}';
      final ref =
          FirebaseStorage.instance.ref().child('${widget.type}/$fileName');
      await ref.putFile(image);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  void _showAddEditDialog([String? id, Map<String, dynamic>? data]) {
    if (data != null) {
      _nameController.text = data['name'] ?? '';
      _urlController.text = data['url'] ?? '';
      _gemsPriceController.text = (data['gemsPrice'] ?? 0).toString();
      _coinsPriceController.text =
          (data['coinsPrice'] ?? data['price'] ?? 0).toString();
      _useImageUpload = false;
      _selectedImage = null;
    } else {
      _nameController.clear();
      _urlController.clear();
      _gemsPriceController.clear();
      _coinsPriceController.clear();
      _useImageUpload = false;
      _selectedImage = null;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: Text(id == null ? 'إضافة عنصر جديد' : 'تعديل العنصر',
              style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                        labelText: 'الاسم',
                        labelStyle: TextStyle(color: Colors.white70)),
                    style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Radio<bool>(
                      value: false,
                      groupValue: _useImageUpload,
                      onChanged: (value) {
                        setDialogState(() {
                          _useImageUpload = value!;
                          _selectedImage = null;
                        });
                      },
                      activeColor: const Color(0xFFD4AF37),
                    ),
                    const Text('رابط الصورة',
                        style: TextStyle(color: Colors.white70)),
                    const SizedBox(width: 20),
                    Radio<bool>(
                      value: true,
                      groupValue: _useImageUpload,
                      onChanged: (value) {
                        setDialogState(() {
                          _useImageUpload = value!;
                          _urlController.clear();
                        });
                      },
                      activeColor: const Color(0xFFD4AF37),
                    ),
                    const Text('رفع صورة',
                        style: TextStyle(color: Colors.white70)),
                  ],
                ),
                const SizedBox(height: 8),
                if (_useImageUpload) ...[
                  if (_selectedImage != null)
                    Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.file(_selectedImage!, fit: BoxFit.cover),
                    )
                  else
                    ElevatedButton.icon(
                      onPressed: () async {
                        await _pickImage();
                        setDialogState(() {});
                      },
                      icon: const Icon(Icons.upload),
                      label: const Text('اختر صورة'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4AF37)),
                    ),
                ] else
                  TextField(
                      controller: _urlController,
                      decoration: const InputDecoration(
                          labelText: 'رابط الصورة',
                          labelStyle: TextStyle(color: Colors.white70)),
                      style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 16),
                TextField(
                    controller: _gemsPriceController,
                    decoration: const InputDecoration(
                        labelText: 'السعر (جواهر)',
                        labelStyle: TextStyle(color: Colors.white70)),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 8),
                TextField(
                    controller: _coinsPriceController,
                    decoration: const InputDecoration(
                        labelText: 'السعر (كوينز)',
                        labelStyle: TextStyle(color: Colors.white70)),
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                String? finalImageUrl = _urlController.text;

                if (_useImageUpload && _selectedImage != null) {
                  finalImageUrl = await _uploadImage(_selectedImage!);
                }

                final Map<String, dynamic> item = {
                  'name': _nameController.text,
                  'url': finalImageUrl ?? '',
                  'gemsPrice': int.tryParse(_gemsPriceController.text) ?? 0,
                  'coinsPrice': int.tryParse(_coinsPriceController.text) ?? 0,
                  'price': int.tryParse(_coinsPriceController.text) ?? 0,
                  'isActive': true,
                };

                if (id == null) {
                  await _db.collection(widget.type).add(item);
                } else {
                  await _db.collection(widget.type).doc(id).update(item);
                }

                setState(() {
                  _selectedImage = null;
                });

                if (!mounted) return;
                Navigator.pop(context);
              },
              child: const Text('حفظ'),
            ),
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
        backgroundColor: const Color(0xFF0A1F1C),
        appBar: AppBar(
          backgroundColor: const Color(0xFF051211),
          title: Text(
              widget.type == 'covers'
                  ? 'إدارة الأغلفة الملكية'
                  : 'إدارة فقاعات الدردشة',
              style: const TextStyle(color: Color(0xFFD4AF37))),
          actions: [
            if (widget.type == 'bubbles')
              IconButton(
                icon: const Icon(Icons.sync, color: Color(0xFFD4AF37)),
                onPressed: () async {
                  if (!mounted) return;
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: const Color(0xFF1A1A2E),
                      title: const Text('تحديث الفقاعات القديمة',
                          style: TextStyle(color: Colors.white)),
                      content: const Text(
                          'هل تريد تحديث الفقاعات القديمة لإضافة gemsPrice و coinsPrice؟',
                          style: TextStyle(color: Colors.white70)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('إلغاء',
                              style: TextStyle(color: Colors.white)),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD4AF37)),
                          child: const Text('تحديث',
                              style: TextStyle(color: Colors.black)),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    try {
                      await StoreService.updateBubblesWithDualPricing();
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('تم تحديث الفقاعات بنجاح ✨'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('حدث خطأ: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                tooltip: 'تحديث الفقاعات القديمة',
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddEditDialog(),
          backgroundColor: const Color(0xFFD4AF37),
          child: const Icon(Icons.add, color: Colors.black),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _db.collection(widget.type).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data!.docs;
            return GridView.builder(
              padding: const EdgeInsets.all(15),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 0.8),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final id = docs[index].id;
                return Container(
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10)),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20)),
                          child: CachedNetworkImage(
                              imageUrl: data['url'] ?? '',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              placeholder: (c, u) => const Icon(Icons.image,
                                  color: Colors.white10)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Text(data['name'] ?? '',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                            if (data['gemsPrice'] != null &&
                                data['gemsPrice'] > 0)
                              Text('${data['gemsPrice']} جواهر',
                                  style: const TextStyle(
                                      color: Colors.cyan, fontSize: 10)),
                            if (data['coinsPrice'] != null &&
                                data['coinsPrice'] > 0)
                              Text('${data['coinsPrice']} كوينز',
                                  style: const TextStyle(
                                      color: Colors.amber, fontSize: 10)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blueAccent, size: 18),
                                    onPressed: () =>
                                        _showAddEditDialog(id, data)),
                                IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.redAccent, size: 18),
                                    onPressed: () async {
                                      bool? confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (ctx) => AlertDialog(
                                                backgroundColor:
                                                    const Color(0xFF1A1A2E),
                                                title: const Text('تأكيد الحذف',
                                                    style: TextStyle(
                                                        color: Colors.white)),
                                                content: const Text(
                                                    'هل تريد حذف هذا العنصر؟'),
                                                actions: [
                                                  TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              ctx, false),
                                                      child:
                                                          const Text('إلغاء')),
                                                  TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              ctx, true),
                                                      child: const Text('حذف',
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .redAccent))),
                                                ],
                                              ));
                                      if (confirm == true) {
                                        await _db
                                            .collection(widget.type)
                                            .doc(id)
                                            .delete();
                                      }
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
