import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/storage_service.dart';
import '../services/family_service.dart';
import '../app_theme.dart';
import '../theme/design_tokens.dart';
import '../theme/reusable_widgets.dart';

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
  String? _selectedRoomId;
  String? _selectedRoomName;
  bool _isLoading = false;
  final int _familyCreationCost = 10000;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _familyImage = File(image.path));
  }

  void _showRoomPicker() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A050E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rooms')
            .where('ownerId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const RoyalLoadingIndicator();
          final rooms = snapshot.data!.docs;

          if (rooms.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.meeting_room_outlined,
                      color: Colors.white24, size: 50),
                  SizedBox(height: 15),
                  Text(
                      'لا تملك أي غرف حالياً. يرجى إنشاء غرفة أولاً لتكون مقراً للعائلة.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text('اختر مقر العائلة الرسمي 🏰',
                    style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: rooms.length,
                  itemBuilder: (context, index) {
                    final room = rooms[index].data() as Map<String, dynamic>;
                    final roomId = rooms[index].id;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            (room['image'] != null && room['image'] != '')
                                ? NetworkImage(room['image'])
                                : null,
                        child: (room['image'] == null || room['image'] == '')
                            ? const Icon(Icons.meeting_room)
                            : null,
                      ),
                      title: Text(room['name'] ?? 'غرفة بدون اسم',
                          style: const TextStyle(color: Colors.white)),
                      subtitle: Text('ID: ${roomId.substring(0, 8)}',
                          style: const TextStyle(
                              color: Colors.white24, fontSize: 10)),
                      onTap: () {
                        setState(() {
                          _selectedRoomId = roomId;
                          _selectedRoomName = room['name'];
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Future<void> _submitRequest() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_nameController.text.trim().isEmpty || _familyImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('يرجى إكمال البيانات واختيار شعار العائلة')));
      return;
    }

    if (_selectedRoomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يجب اختيار غرفة لتكون مقراً للعائلة')));
      return;
    }

    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF3D0B16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text('مرسوم تأسيس عائلة',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
            'هل توافق على خصم $_familyCreationCost جوهرة 💎 مقابل تأسيس عائلة (${_nameController.text})؟',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  const Text('تراجع', style: TextStyle(color: Colors.white24))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.primaryGold),
            child: const Text('تأكيد الدفع',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final userRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final userSnap = await transaction.get(userRef);
        final gemsValue = userSnap.data()?['gems'] ?? 0;
        final currentGems = gemsValue is num ? gemsValue.toInt() : 0;
        if (currentGems < _familyCreationCost) throw Exception('رصيد غير كافٍ');
        transaction
            .update(userRef, {'gems': currentGems - _familyCreationCost});
      });

      final logoUrl =
          await StorageService.uploadFamilyLogo(user.uid, _familyImage!);

      await FamilyService().createFamily(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        slogan: _sloganController.text.trim(),
        logoUrl: logoUrl,
        roomId: _selectedRoomId,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('تم تأسيس العائلة بنجاح! 🎉'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('حدث خطأ أثناء العملية: $e'),
            backgroundColor: Colors.red));
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
          title: const Text('تأسيس عائلة ملكية',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Container(
          decoration: const BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF3D0B16), Color(0xFF1A050E)])),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                AppTheme.glassContainer(
                  opacity: 0.05,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.diamond,
                          color: Colors.blueAccent, size: 20),
                      const SizedBox(width: 10),
                      Text('تكلفة التأسيس: $_familyCreationCost جوهرة',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                      border:
                          Border.all(color: DesignTokens.primaryGold, width: 2),
                      image: _familyImage != null
                          ? DecorationImage(
                              image: FileImage(_familyImage!),
                              fit: BoxFit.cover)
                          : null,
                    ),
                    child: _familyImage == null
                        ? const Icon(Icons.add_a_photo_outlined,
                            color: DesignTokens.primaryGold, size: 40)
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                const Text('اختيار شعار العائلة',
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
                const SizedBox(height: 40),
                AppTheme.royalInputField(
                    controller: _nameController,
                    hint: 'اسم العائلة الملكية',
                    icon: Icons.shield_rounded),
                const SizedBox(height: 15),
                AppTheme.royalInputField(
                    controller: _sloganController,
                    hint: 'شعار العائلة (Slogan)',
                    icon: Icons.star_outline_rounded),
                const SizedBox(height: 15),

                // إضافة خيار اختيار الغرفة
                GestureDetector(
                  onTap: _showRoomPicker,
                  child: AppTheme.glassContainer(
                    padding: const EdgeInsets.all(15),
                    opacity: 0.05,
                    child: Row(
                      children: [
                        const Icon(Icons.meeting_room,
                            color: DesignTokens.primaryGold),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('مقر العائلة الرسمي',
                                  style: TextStyle(
                                      color: Colors.white38, fontSize: 10)),
                              Text(
                                  _selectedRoomName ??
                                      'اضغط لاختيار غرفتك المفضلة',
                                  style: TextStyle(
                                      color: _selectedRoomName != null
                                          ? Colors.white
                                          : Colors.white24,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_drop_down,
                            color: Colors.white24),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                _isLoading
                    ? const RoyalLoadingIndicator()
                    : AppTheme.gradientButton(
                        text: 'دفع الجواهر وتأسيس العائلة',
                        onPressed: _submitRequest),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
