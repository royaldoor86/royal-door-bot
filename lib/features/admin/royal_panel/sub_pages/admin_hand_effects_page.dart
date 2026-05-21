import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../services/storage_service.dart';
import '../../../../app_theme.dart';

class AdminHandEffectsPage extends StatefulWidget {
  const AdminHandEffectsPage({super.key});

  @override
  State<AdminHandEffectsPage> createState() => _AdminHandEffectsPageState();
}

class _AdminHandEffectsPageState extends State<AdminHandEffectsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _animationUrlController = TextEditingController();
  File? _selectedImage;
  File? _selectedAnimation;
  String _selectedType = 'global';
  String _selectedCurrency = 'gems';
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  Future<void> _pickAnimation() async {
    final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() => _selectedAnimation = File(video.path));
    }
  }

  Future<void> _addHandEffect() async {
    if (_nameController.text.trim().isEmpty || _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إكمال البيانات المطلوبة')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String imageUrl = _imageUrlController.text.trim();
      String animationUrl = _animationUrlController.text.trim();
      
      if (_selectedImage != null) {
        imageUrl = await StorageService.uploadRoomImage(_selectedImage!);
      } else if (imageUrl.isEmpty) {
        throw 'يرجى اختيار صورة أو إدخال رابط';
      }

      if (_selectedAnimation != null) {
        animationUrl = await StorageService.uploadRoomTheme('hand_effect', _selectedAnimation!);
      }

      final cost = int.tryParse(_costController.text) ?? 0;

      await _db.collection('hand_effects').add({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': imageUrl,
        'animationUrl': animationUrl,
        'cost': cost,
        'currency': _selectedCurrency,
        'type': _selectedType,
        'isActive': true,
        'purchaseCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _clearForm();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة التأثير بنجاح ✅'), backgroundColor: Colors.green),
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
    _animationUrlController.clear();
    setState(() {
      _selectedImage = null;
      _selectedAnimation = null;
      _selectedType = 'global';
      _selectedCurrency = 'gems';
    });
  }

  Future<void> _deleteEffect(String effectId) async {
    await _db.collection('hand_effects').doc(effectId).delete();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف التأثير'), backgroundColor: Colors.orange),
      );
    }
  }

  Future<void> _toggleEffectStatus(String effectId, bool currentStatus) async {
    await _db.collection('hand_effects').doc(effectId).update({
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
          title: const Text('إدارة تأثيرات الإيدات', style: TextStyle(color: Colors.white)),
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
                    const Text('إضافة تأثير جديد', style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
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
                    
                    // Animation Picker
                    GestureDetector(
                      onTap: _pickAnimation,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          border: Border.all(color: Colors.amber, width: 2),
                        ),
                        child: _selectedAnimation == null
                            ? const Icon(Icons.video_library, color: Colors.amber, size: 30)
                            : const Icon(Icons.check_circle, color: Colors.green, size: 30),
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    TextField(
                      controller: _animationUrlController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'رابط الأنيميشن (اختياري)',
                        labelStyle: const TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'اسم التأثير',
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
                        labelText: 'وصف التأثير',
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
                        DropdownMenuItem(value: 'gems', child: Text('جواهر 💎')),
                        DropdownMenuItem(value: 'stars', child: Text('نجوم ⭐')),
                      ],
                      onChanged: (value) => setState(() => _selectedCurrency = value!),
                    ),
                    const SizedBox(height: 15),
                    
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      style: const TextStyle(color: Colors.white),
                      dropdownColor: const Color(0xFF3D0B16),
                      decoration: InputDecoration(
                        labelText: 'نوع التأثير',
                        labelStyle: const TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'global', child: Text('عام للجميع')),
                        DropdownMenuItem(value: 'family', child: Text('خاص للعائلة')),
                      ],
                      onChanged: (value) => setState(() => _selectedType = value!),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _addHandEffect,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.black)
                                : const Text('إضافة التأثير', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
              
              // Effects List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _db.collection('hand_effects').orderBy('createdAt', descending: true).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: Colors.amber));
                    }
                    
                    final effects = snapshot.data!.docs;
                    
                    if (effects.isEmpty) {
                      return const Center(
                        child: Text('لا توجد تأثيرات حالياً', style: TextStyle(color: Colors.white38)),
                      );
                    }
                    
                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: effects.length,
                      itemBuilder: (context, index) {
                        final effect = effects[index].data() as Map<String, dynamic>;
                        final effectId = effects[index].id;
                        final isActive = effect['isActive'] ?? true;
                        
                        return AppTheme.glassContainer(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.all(15),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundImage: effect['imageUrl'] != null && effect['imageUrl'].isNotEmpty
                                    ? NetworkImage(effect['imageUrl'])
                                    : null,
                                child: (effect['imageUrl'] == null || effect['imageUrl'].isEmpty)
                                    ? const Icon(Icons.waving_hand, color: Colors.amber)
                                    : null,
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(effect['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    Text(effect['description'] ?? '', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Text('${effect['cost']} ${effect['currency'] == 'gems' ? '💎' : '⭐'}', style: const TextStyle(color: Colors.cyan, fontSize: 12)),
                                        const SizedBox(width: 10),
                                        _getTypeBadge(effect['type']),
                                        const SizedBox(width: 10),
                                        Text('شراء: ${effect['purchaseCount'] ?? 0}', style: const TextStyle(color: Colors.green, fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Switch(
                                value: isActive,
                                onChanged: (value) => _toggleEffectStatus(effectId, isActive),
                                activeColor: Colors.green,
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteEffect(effectId),
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
      case 'global':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('عام', style: TextStyle(color: Colors.blue, fontSize: 10)),
        );
      case 'family':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.purple.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('عائلة', style: TextStyle(color: Colors.purple, fontSize: 10)),
        );
      default:
        return const SizedBox();
    }
  }
}
