import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AdminRoomThemesPage extends StatefulWidget {
  const AdminRoomThemesPage({super.key});

  @override
  State<AdminRoomThemesPage> createState() => _AdminRoomThemesPageState();
}

class _AdminRoomThemesPageState extends State<AdminRoomThemesPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedCurrency = 'coins';
  String? _imageUrl;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await _uploadImage(image);
    }
  }

  Future<void> _uploadImage(XFile image) async {
    try {
      final file = File(image.path);
      final fileName = 'room_themes/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child(fileName);
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      setState(() {
        _imageUrl = url;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل رفع الصورة: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _addTheme() async {
    if (_nameController.text.isEmpty || _imageUrl == null || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      await _db.collection('room_themes').add({
        'name': _nameController.text,
        'imageUrl': _imageUrl,
        'price': double.parse(_priceController.text),
        'currencyType': _selectedCurrency,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      _nameController.clear();
      _priceController.clear();
      setState(() {
        _imageUrl = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة الموضوع بنجاح ✅'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل إضافة الموضوع: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteTheme(String themeId) async {
    try {
      await _db.collection('room_themes').doc(themeId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الموضوع بنجاح ✅'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل حذف الموضوع: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _editTheme(String themeId, Map<String, dynamic> currentData) async {
    final nameController = TextEditingController(text: currentData['name'] ?? '');
    final priceController = TextEditingController(text: (currentData['price'] ?? 0).toString());
    String selectedCurrency = currentData['currencyType'] ?? 'coins';
    String? imageUrl = currentData['imageUrl'];

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF042F2C),
          title: const Text('تعديل الموضوع', style: TextStyle(color: Color(0xFFC5A059))),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'اسم الموضوع',
                    labelStyle: const TextStyle(color: Color(0xFFC5A059)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFC5A059)),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'السعر',
                    labelStyle: const TextStyle(color: Color(0xFFC5A059)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFC5A059)),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedCurrency,
                  decoration: InputDecoration(
                    labelText: 'العملة',
                    labelStyle: const TextStyle(color: Color(0xFFC5A059)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFC5A059)),
                    ),
                  ),
                  dropdownColor: const Color(0xFF042F2C),
                  style: const TextStyle(color: Colors.white),
                  items: const [
                    DropdownMenuItem(value: 'coins', child: Text('كوينز')),
                    DropdownMenuItem(value: 'gems', child: Text('جواهر')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCurrency = value!;
                    });
                  },
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      await _uploadImage(image);
                      setDialogState(() {
                        imageUrl = _imageUrl;
                      });
                    }
                  },
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFC5A059)),
                    ),
                    child: imageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(imageUrl!, fit: BoxFit.cover),
                          )
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, color: Color(0xFFC5A059), size: 40),
                                SizedBox(height: 8),
                                Text(
                                  'اضغط لرفع صورة',
                                  style: TextStyle(color: Color(0xFFC5A059)),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || imageUrl == null || priceController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('يرجى ملء جميع الحقول'), backgroundColor: Colors.red),
                  );
                  return;
                }

                try {
                  await _db.collection('room_themes').doc(themeId).update({
                    'name': nameController.text,
                    'imageUrl': imageUrl,
                    'price': double.parse(priceController.text),
                    'currencyType': selectedCurrency,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم تعديل الموضوع بنجاح ✅'), backgroundColor: Colors.green),
                    );
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('فشل تعديل الموضوع: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC5A059),
                foregroundColor: Colors.black,
              ),
              child: const Text('حفظ', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF021412),
        appBar: AppBar(
          backgroundColor: const Color(0xFF042F2C),
          title: const Text(
            'إدارة موضوعات الغرف',
            style: TextStyle(color: Color(0xFFC5A059), fontWeight: FontWeight.bold),
          ),
          iconTheme: const IconThemeData(color: Color(0xFFC5A059)),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildAddThemeForm(),
              const Divider(color: Color(0xFFC5A059), height: 1),
              _buildThemesList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddThemeForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF042F2C),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'إضافة موضوع جديد',
            style: TextStyle(
              color: Color(0xFFC5A059),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'اسم الموضوع',
              labelStyle: const TextStyle(color: Color(0xFFC5A059)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFC5A059)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFC5A059)),
              ),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'السعر',
              labelStyle: const TextStyle(color: Color(0xFFC5A059)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFC5A059)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFC5A059)),
              ),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _selectedCurrency,
            decoration: InputDecoration(
              labelText: 'العملة',
              labelStyle: const TextStyle(color: Color(0xFFC5A059)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFC5A059)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFC5A059)),
              ),
            ),
            dropdownColor: const Color(0xFF042F2C),
            style: const TextStyle(color: Colors.white),
            items: const [
              DropdownMenuItem(value: 'coins', child: Text('كوينز')),
              DropdownMenuItem(value: 'gems', child: Text('جواهر')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedCurrency = value!;
              });
            },
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickImage,
            child:Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFC5A059)),
              ),
              child: _imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(_imageUrl!, fit: BoxFit.cover),
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate, color: Color(0xFFC5A059), size: 40),
                          SizedBox(height: 8),
                          Text(
                            'اضغط لرفع صورة',
                            style: TextStyle(color: Color(0xFFC5A059)),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _addTheme,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC5A059),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'إضافة الموضوع',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('room_themes').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFC5A059)));
        }
        if (snapshot.hasError) {
          return Center(child: Text('خطأ: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(
            child: Text('لا توجد موضوعات بعد', style: TextStyle(color: Color(0xFFC5A059))),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final String imageUrl = data['imageUrl'] ?? '';
            final String name = data['name'] ?? '';
            final double price = (data['price'] ?? 0).toDouble();
            final String currencyType = data['currencyType'] ?? 'coins';

            return Card(
              color: const Color(0xFF042F2C),
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          width: 80,
                          height: 80,
                          color: Colors.white10,
                          child: const Icon(Icons.image, color: Colors.white24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Flexible(
                            child: Row(
                              children: [
                                Icon(
                                  currencyType == 'gems' ? Icons.diamond : Icons.monetization_on,
                                  color: currencyType == 'gems' ? Colors.cyan : Colors.amber,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '$price ${currencyType == 'gems' ? 'جواهر' : 'كوينز'}',
                                    style: const TextStyle(color: Color(0xFFC5A059)),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editTheme(docs[index].id, data),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteTheme(docs[index].id),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
