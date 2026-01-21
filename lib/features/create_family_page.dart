import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/storage_service.dart';
import '../app_theme.dart';

class CreateFamilyPage extends StatefulWidget {
  const CreateFamilyPage({super.key});

  @override
  State<CreateFamilyPage> createState() => _CreateFamilyPageState();
}

class _CreateFamilyPageState extends State<CreateFamilyPage> {
  File? _familyImage;
  final _nameController = TextEditingController();
  final _sloganController = TextEditingController();
  final _descController = TextEditingController();
  bool _isLoading = false;
  final int _familyCreationCost = 500;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _familyImage = File(image.path));
  }

  Future<void> _submitRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_nameController.text.trim().isEmpty || _familyImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إكمال البيانات واختيار شعار العائلة')));
      return;
    }

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF3D0B16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text('مرسوم تأسيس عائلة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text('هل توافق على خصم $_familyCreationCost جوهرة 💎 مقابل تأسيس عائلة (${_nameController.text})؟', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('تراجع', style: TextStyle(color: Colors.white24))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.royalGold),
            child: const Text('تأكيد الدفع', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final requestId = FirebaseFirestore.instance.collection('family_requests').doc().id;

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userSnap = await transaction.get(userRef);
        final currentGems = (userSnap.data()?['gems'] ?? 0) as int;
        if (currentGems < _familyCreationCost) throw Exception('رصيدك غير كافٍ');
        transaction.update(userRef, {'gems': currentGems - _familyCreationCost});
      });

      final logoUrl = await StorageService.uploadFamilyLogo(requestId, _familyImage!);

      await FirebaseFirestore.instance.collection('family_requests').doc(requestId).set({
        'id': requestId,
        'name': _nameController.text.trim(),
        'slogan': _sloganController.text.trim(),
        'description': _descController.text.trim(),
        'logoUrl': logoUrl,
        'creatorId': user.uid,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال طلب التأسيس بنجاح! سيتم المراجعة من قبل الإدارة ✅'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حدث خطأ أثناء العملية')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A050E),
        appBar: AppBar(
          title: const Text('تأسيس عائلة ملكية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3D0B16), Color(0xFF1A050E)])),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                AppTheme.glassContainer(
                  opacity: 0.05,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.diamond, color: Colors.blueAccent, size: 20),
                      const SizedBox(width: 10),
                      Text('تكلفة التأسيس: $_familyCreationCost جوهرة', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 130, height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                      border: Border.all(color: AppTheme.royalGold, width: 2),
                      image: _familyImage != null ? DecorationImage(image: FileImage(_familyImage!), fit: BoxFit.cover) : null,
                    ),
                    child: _familyImage == null ? const Icon(Icons.add_a_photo_outlined, color: AppTheme.royalGold, size: 40) : null,
                  ),
                ),
                const SizedBox(height: 10),
                const Text('اختيار شعار العائلة', style: TextStyle(color: Colors.white38, fontSize: 12)),
                const SizedBox(height: 40),
                AppTheme.royalInputField(controller: _nameController, hint: 'اسم العائلة الملكية', icon: Icons.shield_rounded),
                const SizedBox(height: 15),
                AppTheme.royalInputField(controller: _sloganController, hint: 'شعار العائلة (Slogan)', icon: Icons.star_outline_rounded),
                const SizedBox(height: 30),
                _isLoading
                    ? const CircularProgressIndicator(color: AppTheme.royalGold)
                    : AppTheme.gradientButton(text: 'دفع الجواهر وتأسيس العائلة', onPressed: _submitRequest),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
