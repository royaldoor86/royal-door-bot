import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class AdminGiftsPage extends StatefulWidget {
  final String initialPlacement; // 'room' or 'chat'
  const AdminGiftsPage({super.key, this.initialPlacement = 'room'});

  @override
  State<AdminGiftsPage> createState() => _AdminGiftsPageState();
}

class _AdminGiftsPageState extends State<AdminGiftsPage> {
  bool _isSaving = false;
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _imageUrlCtrl = TextEditingController();
  
  String? _editingGiftId;
  String _currencyType = 'gems';
  String _giftType = 'image'; // 'image', 'gif', 'video'
  
  // الأقسام الجديدة
  final List<String> _categories = ['رويال', 'نادي الأعضاء', 'النشاط', 'كلاسيكي'];
  String _selectedCategory = 'كلاسيكي';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  void _openGiftForm({Map<String, dynamic>? gift, String? id}) {
    _editingGiftId = id;
    _nameCtrl.text = gift?['name'] ?? '';
    _priceCtrl.text = gift?['price']?.toString() ?? '';
    _imageUrlCtrl.text = gift?['imageUrl'] ?? '';
    _currencyType = gift?['currencyType'] ?? 'gems';
    _giftType = gift?['giftType'] ?? 'image';
    _selectedCategory = gift?['category'] ?? 'كلاسيكي';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
              child: Container(
                decoration: const BoxDecoration(
                    color: Color(0xFF16002B),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
                        ),
                        const SizedBox(height: 20),
                        Text(_editingGiftId == null ? "صنع هدية جديدة 🎁" : "تعديل الهدية",
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 25),

                        _buildLabel("قسم الهدية (التصنيف)"),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _categories.map((cat) => Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: _buildChoiceChip(cat, cat, _selectedCategory, (v) => setModalState(() => _selectedCategory = v)),
                            )).toList(),
                          ),
                        ),
                        const SizedBox(height: 15),

                        _buildLabel("نوع الوسائط"),
                        Row(
                          children: [
                            _buildChoiceChip('صورة ثابتة', 'image', _giftType, (v) => setModalState(() => _giftType = v)),
                            const SizedBox(width: 8),
                            _buildChoiceChip('فيديو', 'video', _giftType, (v) => setModalState(() => _giftType = v)),
                          ],
                        ),
                        const SizedBox(height: 15),

                        _buildLabel("نوع العملة"),
                        Row(
                          children: [
                            _buildChoiceChip('مجوهرات 💎', 'gems', _currencyType, (v) => setModalState(() => _currencyType = v)),
                            const SizedBox(width: 10),
                            _buildChoiceChip('نجوم ⭐', 'coins', _currencyType, (v) => setModalState(() => _currencyType = v)),
                          ],
                        ),
                        const SizedBox(height: 20),

                        _buildTextField(controller: _nameCtrl, label: "اسم الهدية"),
                        const SizedBox(height: 15),
                        _buildTextField(controller: _priceCtrl, label: "السعر", keyboardType: TextInputType.number),
                        const SizedBox(height: 15),

                        _buildLabel("رابط ملف الهدية"),
                        Row(
                          children: [
                            Expanded(child: _buildTextField(controller: _imageUrlCtrl, label: "الرابط")),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: () => _pickAndUploadFile(setModalState),
                              icon: const Icon(Icons.upload, size: 18),
                              label: const Text("رفع"),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 30),
                        _isSaving 
                          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
                          : ElevatedButton(
                              onPressed: () => _saveGift(sheetContext),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                              child: Text(_editingGiftId == null ? "صنع ونشر الهدية" : "حفظ التعديلات", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                            ),
                        const SizedBox(height: 10),
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

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: const TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold)));

  Widget _buildChoiceChip(String label, String value, String current, Function(String) onSelect) {
    bool selected = current == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: selected ? Colors.black : Colors.white, fontSize: 12)),
      selected: selected,
      onSelected: (_) => onSelect(value),
      selectedColor: Colors.amber,
      backgroundColor: Colors.white10,
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, TextInputType keyboardType = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Future<void> _pickAndUploadFile(Function setModalState) async {
    FileType type = _giftType == 'video' ? FileType.video : FileType.image;
    final result = await FilePicker.platform.pickFiles(type: type);
    if (result == null) return;

    if (mounted) setState(() => _isSaving = true);
    try {
      final file = File(result.files.single.path!);
      final ref = FirebaseStorage.instance.ref().child("gifts/${DateTime.now().millisecondsSinceEpoch}");
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      setModalState(() => _imageUrlCtrl.text = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ في الرفع: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _saveGift(BuildContext sheetContext) async {
    if (_nameCtrl.text.isEmpty || _priceCtrl.text.isEmpty || _imageUrlCtrl.text.isEmpty) return;
    final data = {
      'name': _nameCtrl.text.trim(),
      'price': int.tryParse(_priceCtrl.text) ?? 0,
      'imageUrl': _imageUrlCtrl.text.trim(),
      'currencyType': _currencyType,
      'giftType': _giftType,
      'category': _selectedCategory, // الحقل الجديد
      'giftPlacement': widget.initialPlacement,
      'showInStore': widget.initialPlacement == 'room',
      'isActive': true,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    try {
      if (_editingGiftId == null) {
        await FirebaseFirestore.instance.collection('gifts').add(data);
      } else {
        await FirebaseFirestore.instance.collection('gifts').doc(_editingGiftId).update(data);
      }
      if (sheetContext.mounted) {
        Navigator.pop(sheetContext);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("خطأ في الحفظ: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = widget.initialPlacement == 'room' ? "إدارة هدايا الغرف والماركت 👑" : "مصنع هدايا المحادثات 🎨";
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0018),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openGiftForm(),
          backgroundColor: Colors.amber,
          icon: const Icon(Icons.add, color: Colors.black),
          label: const Text("صنع هدية", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('gifts').orderBy('updatedAt', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));
            
            final allDocs = snapshot.data!.docs;
            final docs = allDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final placement = data['giftPlacement'];
              if (widget.initialPlacement == 'room') {
                return placement == 'room' || placement == null;
              } else {
                return placement == 'chat';
              }
            }).toList();

            if (docs.isEmpty) return const Center(child: Text("لا توجد هدايا حالياً", style: TextStyle(color: Colors.white54)));
            
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final id = docs[index].id;
                return _buildGiftItem(id, data);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildGiftItem(String id, Map<String, dynamic> data) {
    final bool isVideo = data['giftType'] == 'video';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: ListTile(
        leading: Container(width: 50, height: 50, decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)), child: isVideo ? const Icon(Icons.videocam, color: Colors.amber) : Image.network(data['imageUrl'], fit: BoxFit.contain, errorBuilder: (c, e, s) => const Icon(Icons.broken_image))),
        title: Text(data['name'] ?? 'هدية', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Text("${data['price']} ", style: const TextStyle(color: Colors.amber, fontSize: 12)), Icon(data['currencyType'] == 'gems' ? Icons.diamond : Icons.stars, size: 10, color: Colors.amber)]),
            Text("القسم: ${data['category'] ?? 'غير مصنف'}", style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: const Icon(Icons.edit, color: Colors.white70, size: 20), onPressed: () => _openGiftForm(gift: data, id: id)), IconButton(icon: const Icon(Icons.delete_forever, color: Colors.redAccent, size: 20), onPressed: () => FirebaseFirestore.instance.collection('gifts').doc(id).delete())]),
      ),
    );
  }
}
