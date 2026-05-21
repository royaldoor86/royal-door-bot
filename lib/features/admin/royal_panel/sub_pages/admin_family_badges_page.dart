import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../services/storage_service.dart';
import '../../../../app_theme.dart';

class AdminFamilyBadgesPage extends StatefulWidget {
  const AdminFamilyBadgesPage({super.key});

  @override
  State<AdminFamilyBadgesPage> createState() => _AdminFamilyBadgesPageState();
}

class _AdminFamilyBadgesPageState extends State<AdminFamilyBadgesPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  final _minContributionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  File? _selectedImage;
  String _selectedType = 'purchase';
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  Future<void> _addBadge() async {
    if (_nameController.text.trim().isEmpty ||
        _descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إكمال البيانات المطلوبة')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String imageUrl = _imageUrlController.text.trim();

      if (_selectedImage != null) {
        imageUrl = await StorageService.uploadFamilyBadge(
          DateTime.now().millisecondsSinceEpoch.toString(),
          _selectedImage!,
        );
      } else if (imageUrl.isEmpty) {
        throw 'يرجى اختيار صورة أو إدخال رابط';
      }

      final cost = int.tryParse(_costController.text) ?? 0;
      final minContribution =
          int.tryParse(_minContributionController.text) ?? 0;

      await _db.collection('family_badges').add({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'imageUrl': imageUrl,
        'type': _selectedType,
        'cost': cost,
        'minContribution': minContribution,
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      _clearForm();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم إضافة الشارة بنجاح ✅'),
              backgroundColor: Colors.green),
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
    _minContributionController.clear();
    _imageUrlController.clear();
    setState(() {
      _selectedImage = null;
      _selectedType = 'purchase';
    });
  }

  Future<void> _deleteBadge(String badgeId) async {
    await _db.collection('family_badges').doc(badgeId).delete();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('تم حذف الشارة'), backgroundColor: Colors.orange),
      );
    }
  }

  Future<void> _toggleBadgeStatus(String badgeId, bool currentStatus) async {
    await _db.collection('family_badges').doc(badgeId).update({
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
          title: const Text('إدارة شارات العائلات',
              style: TextStyle(color: Colors.white)),
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
                    const Text('إضافة شارة جديدة',
                        style: TextStyle(
                            color: Colors.amber,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    // Image Picker
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                          border: Border.all(color: Colors.amber, width: 2),
                          image: _selectedImage != null
                              ? DecorationImage(
                                  image: FileImage(_selectedImage!),
                                  fit: BoxFit.cover)
                              : null,
                        ),
                        child: _selectedImage == null
                            ? const Icon(Icons.add_a_photo,
                                color: Colors.amber, size: 40)
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
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 15),

                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'اسم الشارة',
                        labelStyle: const TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 15),

                    TextField(
                      controller: _descriptionController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'وصف الشارة',
                        labelStyle: const TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      style: const TextStyle(color: Colors.white),
                      dropdownColor: const Color(0xFF3D0B16),
                      decoration: InputDecoration(
                        labelText: 'نوع الشارة',
                        labelStyle: const TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'purchase', child: Text('شراء من الخزينة')),
                        DropdownMenuItem(
                            value: 'war_reward', child: Text('جائزة حرب')),
                        DropdownMenuItem(
                            value: 'contributor', child: Text('مساهم كبير')),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedType = value!),
                    ),
                    const SizedBox(height: 15),

                    if (_selectedType == 'purchase')
                      TextField(
                        controller: _costController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'التكلفة (جواهر)',
                          labelStyle: const TextStyle(color: Colors.white38),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),

                    if (_selectedType == 'contributor')
                      TextField(
                        controller: _minContributionController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'حد المساهمة الأدنى',
                          labelStyle: const TextStyle(color: Colors.white38),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _addBadge,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.black)
                                : const Text('إضافة الشارة',
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: _clearForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white24,
                            padding: const EdgeInsets.symmetric(
                                vertical: 15, horizontal: 20),
                          ),
                          child: const Text('مسح',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Badges List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _db
                      .collection('family_badges')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                          child:
                              CircularProgressIndicator(color: Colors.amber));
                    }

                    final badges = snapshot.data!.docs;

                    if (badges.isEmpty) {
                      return const Center(
                        child: Text('لا توجد شارات حالياً',
                            style: TextStyle(color: Colors.white38)),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: badges.length,
                      itemBuilder: (context, index) {
                        final badge =
                            badges[index].data() as Map<String, dynamic>;
                        final badgeId = badges[index].id;
                        final isActive = badge['isActive'] ?? true;

                        return AppTheme.glassContainer(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.all(15),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundImage: badge['imageUrl'] != null &&
                                        badge['imageUrl'].isNotEmpty
                                    ? NetworkImage(badge['imageUrl'])
                                    : null,
                                child: (badge['imageUrl'] == null ||
                                        badge['imageUrl'].isEmpty)
                                    ? const Icon(Icons.emoji_events,
                                        color: Colors.amber)
                                    : null,
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(badge['name'] ?? '',
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                    Text(badge['description'] ?? '',
                                        style: const TextStyle(
                                            color: Colors.white38,
                                            fontSize: 12)),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        _getTypeBadge(badge['type']),
                                        const SizedBox(width: 10),
                                        if (badge['cost'] != null &&
                                            badge['cost'] > 0)
                                          Text('${badge['cost']} 💎',
                                              style: const TextStyle(
                                                  color: Colors.cyan,
                                                  fontSize: 12)),
                                        if (badge['minContribution'] != null &&
                                            badge['minContribution'] > 0)
                                          Text(
                                              'مساهمة: ${badge['minContribution']}',
                                              style: const TextStyle(
                                                  color: Colors.green,
                                                  fontSize: 12)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              Switch(
                                value: isActive,
                                onChanged: (value) =>
                                    _toggleBadgeStatus(badgeId, isActive),
                                activeColor: Colors.green,
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteBadge(badgeId),
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
      case 'purchase':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('شراء',
              style: TextStyle(color: Colors.blue, fontSize: 10)),
        );
      case 'war_reward':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('حرب',
              style: TextStyle(color: Colors.red, fontSize: 10)),
        );
      case 'contributor':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text('مساهم',
              style: TextStyle(color: Colors.green, fontSize: 10)),
        );
      default:
        return const SizedBox();
    }
  }
}
