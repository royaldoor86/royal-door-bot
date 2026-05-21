import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../services/storage_service.dart';
import '../../../../app_theme.dart';

class AdminFamilyStorePage extends StatefulWidget {
  const AdminFamilyStorePage({super.key});

  @override
  State<AdminFamilyStorePage> createState() => _AdminFamilyStorePageState();
}

class _AdminFamilyStorePageState extends State<AdminFamilyStorePage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _durationController = TextEditingController();
  final _effectIdController = TextEditingController();
  File? _selectedImage;
  String _selectedType = 'perk';
  String _selectedCurrency = 'family_gems';
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  Future<void> _addStoreItem() async {
    if (_nameController.text.trim().isEmpty || _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إكمال البيانات المطلوبة')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String imageUrl = _imageUrlController.text.trim();
      
      if (_selectedImage != null) {
        imageUrl = await StorageService.uploadRoomImage(_selectedImage!);
      } else if (imageUrl.isEmpty) {
        throw 'يرجى اختيار صورة أو إدخال رابط';
      }

      final cost = int.tryParse(_costController.text) ?? 0;
      final durationDays = int.tryParse(_durationController.text);

      await _db.collection('family_store_items').add({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': imageUrl,
        'cost': cost,
        'currency': _selectedCurrency,
        'type': _selectedType,
        'effectId': _effectIdController.text.trim().isEmpty ? null : _effectIdController.text.trim(),
        'durationDays': durationDays,
        'isActive': true,
        'purchaseCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _clearForm();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة العنصر بنجاح ✅'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _costController.clear();
    _imageUrlController.clear();
    _durationController.clear();
    _effectIdController.clear();
    setState(() {
      _selectedImage = null;
      _selectedType = 'perk';
      _selectedCurrency = 'family_gems';
    });
  }

  Future<void> _deleteItem(String itemId) async {
    await _db.collection('family_store_items').doc(itemId).delete();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف العنصر'), backgroundColor: Colors.orange),
      );
    }
  }

  Future<void> _toggleItemStatus(String itemId, bool currentStatus) async {
    await _db.collection('family_store_items').doc(itemId).update({
      'isActive': !currentStatus,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A050E),
        appBar: AppBar(
          title: const Text('إدارة متجر العائلات', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3D0B16), Color(0xFF1A050E)],
            ),
          ),
          child: Column(
            children: [
              // Form Section
              AppTheme.glassContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('إضافة عنصر جديد', style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    
                    // Image Picker
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                          border: Border.all(color: Colors.amber, width: 2),
                          image: _selectedImage != null
                              ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                              : null,
                        ),
                        child: _selectedImage == null
                            ? const Icon(Icons.add_a_photo, color: Colors.amber, size: 30)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    TextField(
                      controller: _imageUrlController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'رابط الصورة (اختياري)',
                        labelStyle: const TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'اسم العنصر',
                        labelStyle: const TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    TextField(
                      controller: _descriptionController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'وصف العنصر',
                        labelStyle: const TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    TextField(
                      controller: _costController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'التكلفة',
                        labelStyle: const TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      style: const TextStyle(color: Colors.white),
                      dropdownColor: const Color(0xFF3D0B16),
                      decoration: InputDecoration(
                        labelText: 'العملة',
                        labelStyle: const TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'family_gems', child: Text('جواهر العائلة 💎')),
                        DropdownMenuItem(value: 'family_stars', child: Text('نجوم العائلة ⭐')),
                      ],
                      onChanged: (value) => setState(() => _selectedCurrency = value!),
                    ),
                    const SizedBox(height: 15),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      style: const TextStyle(color: Colors.white),
                      dropdownColor: const Color(0xFF3D0B16),
                      decoration: InputDecoration(
                        labelText: 'نوع العنصر',
                        labelStyle: const TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'perk', child: Text('ميزة')),
                        DropdownMenuItem(value: 'hand_effect', child: Text('تأثير إيدات')),
                        DropdownMenuItem(value: 'entertainment', child: Text('عنصر ترفيهي')),
                        DropdownMenuItem(value: 'badge', child: Text('شارة')),
                      ],
                      onChanged: (value) => setState(() => _selectedType = value!),
                    ),
                    const SizedBox(height: 15),
                    
                    if (_selectedType == 'hand_effect')
                      TextField(
                        controller: _effectIdController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'معرف التأثير (Effect ID)',
                          labelStyle: const TextStyle(color: Colors.white38),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    
                    if (_selectedType == 'perk')
                      TextField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'المدة (بالأيام)',
                          labelStyle: const TextStyle(color: Colors.white38),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    
                    const SizedBox(height: 20),
                    
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _addStoreItem,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.black)
                                : const Text('إضافة العنصر', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _clearForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white24,
                            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                          ),
                          child: const Text('مسح', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Items List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _db.collection('family_store_items').orderBy('createdAt', descending: true).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: Colors.amber));
                    }
                    
                    final items = snapshot.data!.docs;
                    
                    if (items.isEmpty) {
                      return const Center(
                        child: Text('لا توجد عناصر حالياً', style: TextStyle(color: Colors.white38)),
                      );
                    }
                    
                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index].data() as Map<String, dynamic>;
                        final itemId = items[index].id;
                        final isActive = item['isActive'] ?? true;
                        
                        return AppTheme.glassContainer(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.all(15),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundImage: item['imageUrl'] != null && item['imageUrl'].isNotEmpty
                                    ? NetworkImage(item['imageUrl'])
                                    : null,
                                child: (item['imageUrl'] == null || item['imageUrl'].isEmpty)
                                    ? const Icon(Icons.shopping_bag, color: Colors.amber)
                                    : null,
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    Text(item['description'] ?? '', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Text('${item['cost']} ${item['currency'] == 'family_gems' ? '💎' : '⭐'}', style: const TextStyle(color: Colors.cyan, fontSize: 12)),
                                        const SizedBox(width: 10),
                                        _getTypeBadge(item['type']),
                                        const SizedBox(width: 10),
                                        Text('شراء: ${item['purchaseCount'] ?? 0}', style: const TextStyle(color: Colors.green, fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Switch(
                                value: isActive,
                                onChanged: (value) => _toggleItemStatus(itemId, isActive),
                                activeColor: Colors.green,
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteItem(itemId),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getTypeBadge(String? type) {
    switch (type) {
      case 'perk':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('ميزة', style: TextStyle(color: Colors.blue, fontSize: 10)),
        );
      case 'hand_effect':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.purple.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('إيدات', style: TextStyle(color: Colors.purple, fontSize: 10)),
        );
      case 'entertainment':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('ترفيه', style: TextStyle(color: Colors.orange, fontSize: 10)),
        );
      case 'badge':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('شارة', style: TextStyle(color: Colors.green, fontSize: 10)),
        );
      default:
        return const SizedBox();
    }
  }
}
