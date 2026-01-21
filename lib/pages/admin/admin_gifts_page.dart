// lib/pages/admin/admin_gifts_page.dart

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AdminGiftsPage extends StatefulWidget {
  const AdminGiftsPage({super.key});

  @override
  State<AdminGiftsPage> createState() => _AdminGiftsPageState();
}

class _AdminGiftsPageState extends State<AdminGiftsPage> {
  bool _isSaving = false;
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _categoryCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _salePriceCtrl = TextEditingController();
  final TextEditingController _imageUrlCtrl = TextEditingController();
  final TextEditingController _lottieUrlCtrl = TextEditingController();

  String? _editingGiftId;
  bool _isActive = true;
  bool _showInStore = true;
  bool _onSale = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _priceCtrl.dispose();
    _salePriceCtrl.dispose();
    _imageUrlCtrl.dispose();
    _lottieUrlCtrl.dispose();
    super.dispose();
  }

  void _openGiftForm({AdminGift? gift}) {
    _editingGiftId = gift?.id;
    _nameCtrl.text = gift?.name ?? '';
    _categoryCtrl.text = gift?.category ?? '';
    _priceCtrl.text = gift != null ? gift.price.toString() : '';
    _salePriceCtrl.text = gift != null ? gift.salePrice.toString() : '';
    _imageUrlCtrl.text = gift?.imageUrl ?? '';
    _lottieUrlCtrl.text =
        gift?.lottieUrl ?? ''; // Fixed: now defined in AdminGift
    _showInStore = gift?.showInStore ?? true; // Fixed: now defined in AdminGift
    _isActive = gift?.isActive ?? true;
    _onSale = gift?.onSale ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
              child: Container(
                decoration: const BoxDecoration(
                    color: Color(0xFF16002B),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24))),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                            _editingGiftId == null
                                ? "إضافة هدية ملكية جديدة 👑"
                                : "تعديل الهدية",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 20),

                        // Dynamic Image Preview
                        Container(
                          height: 120,
                          width: 120,
                          decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.white10)),
                          child: _imageUrlCtrl.text.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(15),
                                  child: Image.network(_imageUrlCtrl.text,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                          Icons.broken_image,
                                          color: Colors.red)))
                              : const Icon(Icons.image_outlined,
                                  color: Colors.white24, size: 50),
                        ),
                        const SizedBox(height: 15),

                        _buildTextField(
                            controller: _nameCtrl, label: "اسم الهدية"),
                        const SizedBox(height: 12),
                        _buildTextField(
                            controller: _categoryCtrl,
                            label: "الفئة (مثل: رومانسية، VIP)"),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                                child: _buildTextField(
                                    controller: _priceCtrl,
                                    label: "السعر 💎",
                                    keyboardType: TextInputType.number)),
                            const SizedBox(width: 12),
                            Expanded(
                                child: _buildTextField(
                                    controller: _salePriceCtrl,
                                    label: "سعر الخصم",
                                    keyboardType: TextInputType.number,
                                    enabled: _onSale)),
                          ],
                        ),
                        const SizedBox(height: 12),

                        SwitchListTile.adaptive(
                          value: _onSale,
                          onChanged: (v) => setModalState(() => _onSale = v),
                          title: const Text("عرض خصم",
                              style: TextStyle(color: Colors.white)),
                        ),

                        Row(
                          children: [
                            Expanded(
                                child: _buildTextField(
                                    controller: _imageUrlCtrl,
                                    label: "رابط الصورة / GIF")),
                            IconButton(
                                onPressed: () =>
                                    _pickAndUploadImage(setModalState),
                                icon: const Icon(Icons.upload_file,
                                    color: Colors.amber)),
                          ],
                        ),
                        const SizedBox(height: 24),

                        Row(
                          children: [
                            Expanded(
                                child: OutlinedButton(
                                    onPressed: () =>
                                        Navigator.pop(sheetContext),
                                    child: const Text("إلغاء",
                                        style:
                                            TextStyle(color: Colors.white)))),
                            const SizedBox(width: 12),
                            Expanded(
                                child: ElevatedButton(
                                    onPressed: _isSaving
                                        ? null
                                        : () => _saveGift(sheetContext),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.amber),
                                    child: Text(
                                        _editingGiftId == null
                                            ? "إضافة"
                                            : "تعديل",
                                        style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold)))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        });
      },
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String label,
      TextInputType keyboardType = TextInputType.text,
      bool enabled = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        TextField(
            controller: controller,
            keyboardType: keyboardType,
            enabled: enabled,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white10,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none))),
      ],
    );
  }

  Future<void> _pickAndUploadImage(Function setModalState) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result == null) return;
    final file = File(result.files.single.path!);
    final ref = FirebaseStorage.instance
        .ref()
        .child("gifts/${DateTime.now().millisecondsSinceEpoch}");
    setState(() => _isSaving = true);
    await ref.putFile(file);
    final url = await ref.getDownloadURL();
    setModalState(() => _imageUrlCtrl.text = url);
    setState(() => _isSaving = false);
  }

  Future<void> _saveGift(BuildContext sheetContext) async {
    final data = {
      'name': _nameCtrl.text.trim(),
      'category': _categoryCtrl.text.trim(),
      'price': int.tryParse(_priceCtrl.text) ?? 0,
      'salePrice': int.tryParse(_salePriceCtrl.text) ?? 0,
      'onSale': _onSale,
      'imageUrl': _imageUrlCtrl.text.trim(),
      'lottieUrl': _lottieUrlCtrl.text.trim(),
      'isActive': _isActive,
      'showInStore': _showInStore,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (_editingGiftId == null) {
      await FirebaseFirestore.instance.collection('gifts').add(data);
    } else {
      await FirebaseFirestore.instance
          .collection('gifts')
          .doc(_editingGiftId)
          .update(data);
    }
    Navigator.pop(sheetContext);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0018),
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text("إدارة الهدايا والثيمات 👑")),
      floatingActionButton: FloatingActionButton(
          onPressed: () => _openGiftForm(),
          backgroundColor: Colors.amber,
          child: const Icon(Icons.add, color: Colors.black)),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('gifts').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final gifts =
              snapshot.data!.docs.map((d) => AdminGift.fromDoc(d)).toList();
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: gifts.length,
            itemBuilder: (context, index) => _AdminGiftTile(
                gift: gifts[index],
                onEdit: () => _openGiftForm(gift: gifts[index])),
          );
        },
      ),
    );
  }
}

class AdminGift {
  final String id, name, category, imageUrl, lottieUrl;
  final int price, salePrice;
  final bool onSale, isActive, showInStore;

  AdminGift(
      {required this.id,
      required this.name,
      required this.category,
      required this.imageUrl,
      required this.lottieUrl,
      required this.price,
      required this.salePrice,
      required this.onSale,
      required this.isActive,
      required this.showInStore});

  factory AdminGift.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AdminGift(
        id: doc.id,
        name: d['name'] ?? '',
        category: d['category'] ?? '',
        imageUrl: d['imageUrl'] ?? '',
        lottieUrl: d['lottieUrl'] ?? '',
        price: d['price'] ?? 0,
        salePrice: d['salePrice'] ?? 0,
        onSale: d['onSale'] ?? false,
        isActive: d['isActive'] ?? true,
        showInStore: d['showInStore'] ?? true);
  }
}

class _AdminGiftTile extends StatelessWidget {
  final AdminGift gift;
  final VoidCallback onEdit;
  const _AdminGiftTile({required this.gift, required this.onEdit});
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white10,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: gift.imageUrl.isNotEmpty
                ? Image.network(gift.imageUrl,
                    width: 50, height: 50, fit: BoxFit.cover)
                : const Icon(Icons.card_giftcard, color: Colors.amber)),
        title: Text(gift.name,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text("${gift.price} 💎",
            style: const TextStyle(color: Colors.amber)),
        trailing: IconButton(
            onPressed: onEdit,
            icon: const Icon(Icons.edit, color: Colors.white70)),
      ),
    );
  }
}
