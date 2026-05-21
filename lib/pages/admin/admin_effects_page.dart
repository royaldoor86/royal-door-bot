import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/entry_effect_model.dart';
import '../../services/storage_service.dart';

class AdminEffectsPage extends StatefulWidget {
  const AdminEffectsPage({super.key});

  @override
  State<AdminEffectsPage> createState() => _AdminEffectsPageState();
}

class _AdminEffectsPageState extends State<AdminEffectsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  void _showEffectDialog({EntryEffectModel? effect}) {
    final nameCtrl = TextEditingController(text: effect?.name);
    final priceCtrl = TextEditingController(text: effect?.price.toString());
    File? selectedFile;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setST) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: const Color(0xFF1A0A10),
            title: Text(
                effect == null ? "إضافة تأثير دخول جديد" : "تعديل التأثير",
                style: const TextStyle(color: Colors.amber)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final p = await ImagePicker()
                          .pickImage(source: ImageSource.gallery);
                      if (p != null) setST(() => selectedFile = File(p.path));
                    },
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.5))),
                      child: selectedFile != null
                          ? const Icon(Icons.file_present,
                              color: Colors.green, size: 50)
                          : (effect != null
                              ? const Icon(Icons.auto_awesome,
                                  color: Colors.amber, size: 50)
                              : const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                      Icon(Icons.upload_file,
                                          color: Colors.amber, size: 40),
                                      Text("اختر ملف (Lottie/GIF)",
                                          style: TextStyle(
                                              color: Colors.white24,
                                              fontSize: 10))
                                    ])),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _inputField(nameCtrl, "اسم التأثير", Icons.stars),
                  const SizedBox(height: 12),
                  _inputField(priceCtrl, "السعر بالجواهر", Icons.diamond,
                      isNumber: true),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("إلغاء")),
              if (isUploading)
                const CircularProgressIndicator(color: Colors.amber)
              else
                ElevatedButton(
                  onPressed: () async {
                    if (nameCtrl.text.isEmpty ||
                        (effect == null && selectedFile == null)) {
                      return;
                    }

                    setST(() => isUploading = true);
                    try {
                      String finalUrl = effect?.lottieUrl ?? '';
                      if (selectedFile != null) {
                        finalUrl = await StorageService.uploadAvatarFrame(
                            "effect_${DateTime.now().millisecondsSinceEpoch}",
                            selectedFile!);
                      }

                      final data = {
                        'name': nameCtrl.text,
                        'lottieUrl': finalUrl,
                        'price': int.tryParse(priceCtrl.text) ?? 0,
                        'isActive': true,
                        'createdAt': FieldValue.serverTimestamp(),
                      };

                      if (effect == null) {
                        await _db.collection('entry_effects').add(data);
                      } else {
                        await _db
                            .collection('entry_effects')
                            .doc(effect.id)
                            .update(data);
                      }
                      if (mounted) Navigator.pop(ctx);
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text("خطأ: $e")));
                      }
                    } finally {
                      setST(() => isUploading = false);
                    }
                  },
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                  child:
                      const Text("حفظ", style: TextStyle(color: Colors.black)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("إدارة تأثيرات الدخول ✨",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            ElevatedButton.icon(
              onPressed: () => _showEffectDialog(),
              icon: const Icon(Icons.add),
              label: const Text("إضافة"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber, foregroundColor: Colors.black),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _db.collection('entry_effects').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;

              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.1,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final effect = EntryEffectModel.fromFirestore(
                      docs[index] as DocumentSnapshot<Map<String, dynamic>>);
                  return _effectAdminCard(effect);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _effectAdminCard(EntryEffectModel effect) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white10)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, color: Colors.amber, size: 40),
          const SizedBox(height: 10),
          Text(effect.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          Text("${effect.price} 💎",
              style: const TextStyle(color: Colors.amber, fontSize: 11)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                  icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                  onPressed: () => _showEffectDialog(effect: effect)),
              IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 18, color: Colors.redAccent),
                  onPressed: () =>
                      _db.collection('entry_effects').doc(effect.id).delete()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _inputField(TextEditingController ctrl, String hint, IconData icon,
      {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: hint,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.amber, size: 18),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
    );
  }
}
