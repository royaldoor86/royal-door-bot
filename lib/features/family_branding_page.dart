import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/family_service.dart';
import '../services/storage_service.dart';
import '../app_theme.dart';

class FamilyBrandingPage extends StatefulWidget {
  final String familyId;
  const FamilyBrandingPage({super.key, required this.familyId});

  @override
  State<FamilyBrandingPage> createState() => _FamilyBrandingPageState();
}

class _FamilyBrandingPageState extends State<FamilyBrandingPage> {
  final FamilyService _familyService = FamilyService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();
  final _primaryColorController = TextEditingController();
  final _secondaryColorController = TextEditingController();
  final _musicUrlController = TextEditingController();
  File? _selectedBackground;
  File? _selectedMusic;
  bool _isLoading = false;

  Future<void> _pickBackground() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedBackground = File(image.path));
    }
  }

  Future<void> _pickMusic() async {
    final XFile? audio = await _picker.pickVideo(source: ImageSource.gallery);
    if (audio != null) {
      setState(() => _selectedMusic = File(audio.path));
    }
  }

  Future<void> _purchaseBackground() async {
    if (_selectedBackground == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار صورة الخلفية')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final imageUrl =
          await StorageService.uploadRoomImage(_selectedBackground!);
      await _familyService.purchaseFamilyBackground(widget.familyId, imageUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم شراء الخلفية بنجاح! 🎨 (1000 جوهرة)'),
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

  Future<void> _purchaseMusic() async {
    String musicUrl = _musicUrlController.text.trim();

    if (_selectedMusic != null) {
      musicUrl =
          await StorageService.uploadRoomTheme('family_music', _selectedMusic!);
    } else if (musicUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار ملف موسيقى أو إدخال رابط')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _familyService.purchaseFamilyMusic(widget.familyId, musicUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم شراء الموسيقى بنجاح! 🎵 (5000 جوهرة)')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateColors() async {
    if (_primaryColorController.text.trim().isEmpty ||
        _secondaryColorController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال الألوان')),
      );
      return;
    }

    try {
      await _familyService.updateFamilyColors(
        widget.familyId,
        _primaryColorController.text.trim(),
        _secondaryColorController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم تحديث الألوان بنجاح ✅'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A050E),
        appBar: AppBar(
          title: const Text('العلامات التجارية',
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
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Current Branding Status
              StreamBuilder<DocumentSnapshot>(
                stream:
                    _db.collection('families').doc(widget.familyId).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();

                  final family = snapshot.data!.data() as Map<String, dynamic>;
                  final hasCustomBackground =
                      family['hasCustomBackground'] ?? false;
                  final hasCustomMusic = family['hasCustomMusic'] ?? false;
                  final primaryColor = family['primaryColor'];
                  final secondaryColor = family['secondaryColor'];
                  final backgroundUrl = family['backgroundUrl'];
                  final musicUrl = family['musicUrl'];

                  return AppTheme.glassContainer(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('الحالة الحالية',
                            style: TextStyle(
                                color: Colors.amber,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 15),
                        if (primaryColor != null || secondaryColor != null)
                          Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: primaryColor != null
                                      ? Color(int.parse(primaryColor
                                          .replaceFirst('#', '0xFF')))
                                      : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: secondaryColor != null
                                      ? Color(int.parse(secondaryColor
                                          .replaceFirst('#', '0xFF')))
                                      : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text('الألوان المخصصة',
                                  style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        const SizedBox(height: 10),
                        if (hasCustomBackground)
                          Row(
                            children: [
                              const Icon(Icons.wallpaper, color: Colors.green),
                              const SizedBox(width: 10),
                              const Text('خلفية مخصصة',
                                  style: TextStyle(color: Colors.green)),
                              if (backgroundUrl != null &&
                                  backgroundUrl.isNotEmpty)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(backgroundUrl,
                                          height: 50, fit: BoxFit.cover),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        const SizedBox(height: 10),
                        if (hasCustomMusic)
                          Row(
                            children: [
                              const Icon(Icons.music_note, color: Colors.green),
                              const SizedBox(width: 10),
                              const Text('موسيقى مخصصة',
                                  style: TextStyle(color: Colors.green)),
                            ],
                          ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Colors Section
              AppTheme.glassContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('تخصيص الألوان',
                        style: TextStyle(
                            color: Colors.amber,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _primaryColorController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'اللون الأساسي (#RRGGBB)',
                              labelStyle:
                                  const TextStyle(color: Colors.white38),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: TextField(
                            controller: _secondaryColorController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'اللون الثانوي (#RRGGBB)',
                              labelStyle:
                                  const TextStyle(color: Colors.white38),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: _updateColors,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: const Text('تحديث الألوان',
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Background Section
              AppTheme.glassContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('خلفية مخصصة',
                        style: TextStyle(
                            color: Colors.amber,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    GestureDetector(
                      onTap: _pickBackground,
                      child: Container(
                        width: double.infinity,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          border: Border.all(color: Colors.amber, width: 2),
                          borderRadius: BorderRadius.circular(10),
                          image: _selectedBackground != null
                              ? DecorationImage(
                                  image: FileImage(_selectedBackground!),
                                  fit: BoxFit.cover)
                              : null,
                        ),
                        child: _selectedBackground == null
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate,
                                        color: Colors.amber, size: 40),
                                    SizedBox(height: 10),
                                    Text('اضغط لاختيار صورة',
                                        style:
                                            TextStyle(color: Colors.white38)),
                                  ],
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info, color: Colors.amber),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text('التكلفة: 1000 جوهرة 💎',
                                style: const TextStyle(color: Colors.amber)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _purchaseBackground,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text('شراء الخلفية',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Music Section
              AppTheme.glassContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('موسيقى مخصصة',
                        style: TextStyle(
                            color: Colors.amber,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    GestureDetector(
                      onTap: _pickMusic,
                      child: Container(
                        width: double.infinity,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          border: Border.all(color: Colors.amber, width: 2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: _selectedMusic == null
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.music_note,
                                        color: Colors.amber, size: 40),
                                    SizedBox(height: 10),
                                    Text('اضغط لاختيار ملف موسيقى',
                                        style:
                                            TextStyle(color: Colors.white38)),
                                  ],
                                ),
                              )
                            : const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: Colors.green, size: 40),
                                    SizedBox(height: 10),
                                    Text('تم اختيار الملف',
                                        style: TextStyle(color: Colors.green)),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _musicUrlController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'رابط الموسيقى (اختياري)',
                        labelStyle: const TextStyle(color: Colors.white38),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info, color: Colors.amber),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text('التكلفة: 5000 جوهرة 💎',
                                style: const TextStyle(color: Colors.amber)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _purchaseMusic,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.black)
                          : const Text('شراء الموسيقى',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
