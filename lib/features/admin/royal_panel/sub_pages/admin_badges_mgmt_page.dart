import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../services/media_uploader.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path/path.dart' as path;

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
  String _selectedCategory = 'badge';
  File? _selectedImage;
  bool _isUploading = false;

  void _addBadge() async {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إكمال جميع الحقول')));
      return;
    }

    if (_selectedImage == null && _iconController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء اختيار صورة أو إدخال إيموجي')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? imageUrl;
      if (_selectedImage != null) {
        final extension = path.extension(_selectedImage!.path).toLowerCase();
        
        // إذا كانت الصورة GIF، نرفعها مباشرة بدون ضغط JPEG للحفاظ على الحركة
        if (extension == '.gif') {
          final ref = FirebaseStorage.instance.ref().child('badges/${DateTime.now().millisecondsSinceEpoch}.gif');
          final uploadTask = await ref.putFile(_selectedImage!, SettableMetadata(contentType: 'image/gif'));
          imageUrl = await uploadTask.ref.getDownloadURL();
        } else {
          // الصور العادية نستخدم الرفع المضغوط لتوفير المساحة
          imageUrl = await MediaUploader.uploadCompressedImage(
            file: _selectedImage!,
            pathInStorage: 'badges/${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
        }
      }

      await _db.collection('badges_templates').add({
        'name': _nameController.text,
        'icon': imageUrl ?? _iconController.text,
        'isImage': imageUrl != null,
        'isAnimated': imageUrl?.contains('.gif') ?? false,
        'price': int.parse(_priceController.text),
        'category': _selectedCategory,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _nameController.clear();
      _iconController.clear();
      _priceController.clear();
      setState(() {
        _selectedImage = null;
        _isUploading = false;
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('حدث خطأ: $e')));
    }
  }

  void _showAddDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('إضافة شارة ملكية (تدعم GIF)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                      if (pickedFile != null) {
                        setModalState(() {
                          _selectedImage = File(pickedFile.path);
                        });
                      }
                    },
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white10,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                      ),
                      child: _selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.file(_selectedImage!, fit: BoxFit.cover),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, color: Colors.amber, size: 40),
                                Text('صورة (JPG/GIF)', style: TextStyle(color: Colors.white54, fontSize: 12)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'اسم الشارة', labelStyle: TextStyle(color: Colors.white70))),
                  TextField(controller: _iconController, decoration: const InputDecoration(labelText: 'الأيقونة (إيموجي - اختياري)', labelStyle: TextStyle(color: Colors.white70))),
                  TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'السعر (نجوم ⭐)', labelStyle: TextStyle(color: Colors.white70))),
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
                    onChanged: (val) => setModalState(() => _selectedCategory = val!),
                  ),
                  const SizedBox(height: 20),
                  _isUploading
                      ? const CircularProgressIndicator(color: Colors.amber)
                      : ElevatedButton(
                          onPressed: _addBadge,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, minimumSize: const Size(double.infinity, 45)),
                          child: const Text('حفظ الشارة', style: TextStyle(color: Colors.black)),
                        ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    ).then((_) {
      setState(() => _selectedImage = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A12),
        appBar: AppBar(title: const Text('إدارة الشارات المتحركة'), backgroundColor: const Color(0xFF1A1A2E)),
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
                final bool isImage = badge['isImage'] ?? false;
                final String iconData = badge['icon'] ?? '';

                return ListTile(
                  leading: isImage
                      ? CachedNetworkImage(
                          imageUrl: iconData,
                          width: 45,
                          height: 45,
                          placeholder: (context, url) => const CircularProgressIndicator(strokeWidth: 2),
                          errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
                        )
                      : Text(iconData, style: const TextStyle(fontSize: 30)),
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
