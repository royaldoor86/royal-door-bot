import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/storage_service.dart';

class AdminRoomThemesPage extends StatefulWidget {
  const AdminRoomThemesPage({super.key});

  @override
  State<AdminRoomThemesPage> createState() => _AdminRoomThemesPageState();
}

class _AdminRoomThemesPageState extends State<AdminRoomThemesPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Color accentGold = const Color(0xFFC5A059);
  final Color primaryDark = const Color(0xFF042F2C);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF021412),
        appBar: AppBar(
          backgroundColor: primaryDark,
          elevation: 0,
          title: Text('خزانة ثيمات الرومات', style: TextStyle(color: accentGold, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: accentGold,
          onPressed: _showAddThemeDialog,
          child: const Icon(Icons.add_photo_alternate_rounded, color: Colors.black),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _db.collection('room_themes').orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.amber));
            
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) return _buildEmptyState();

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                return _buildThemeCard(docs[index].id, data);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildThemeCard(String id, Map<String, dynamic> data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: accentGold.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
              child: Image.network(
                data['imageUrl'] ?? '',
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(color: Colors.white10, child: const Icon(Icons.image_not_supported, color: Colors.white24)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Text(data['name'] ?? 'بدون اسم', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('${data['price'] ?? 0} نجمة ⭐', style: TextStyle(color: accentGold, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                IconButton(
                  icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 20),
                  onPressed: () => _confirmDelete(id),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddThemeDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    File? selectedImage;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25), side: BorderSide(color: accentGold.withValues(alpha: 0.3))),
          title: Text('إصدار ثيم ملكي جديد', style: TextStyle(color: accentGold, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final img = await ImagePicker().pickImage(source: ImageSource.gallery);
                    if (img != null) setModalState(() => selectedImage = File(img.path));
                  },
                  child: Container(
                    height: 120, width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accentGold.withValues(alpha: 0.2)),
                      image: selectedImage != null ? DecorationImage(image: FileImage(selectedImage!), fit: BoxFit.cover) : null,
                    ),
                    child: selectedImage == null ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_rounded, color: accentGold, size: 30),
                        const SizedBox(height: 8),
                        const Text('اختر خلفية الروم', style: TextStyle(color: Colors.white38, fontSize: 10)),
                      ],
                    ) : null,
                  ),
                ),
                const SizedBox(height: 20),
                _buildField(nameCtrl, 'اسم الثيم', Icons.title),
                const SizedBox(height: 12),
                _buildField(priceCtrl, 'السعر بالنجوم', Icons.stars, isNumber: true),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.white38))),
            if (isUploading) const CircularProgressIndicator()
            else ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isNotEmpty && selectedImage != null) {
                  setModalState(() => isUploading = true);
                  try {
                    final url = await StorageService.uploadRoomTheme(nameCtrl.text, selectedImage!);
                    await _db.collection('room_themes').add({
                      'name': nameCtrl.text.trim(),
                      'imageUrl': url,
                      'price': int.parse(priceCtrl.text),
                      'createdAt': FieldValue.serverTimestamp()
                    });
                    Navigator.pop(ctx);
                  } catch (e) {
                    setModalState(() => isUploading = false);
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: accentGold, foregroundColor: Colors.black),
              child: const Text('حفظ ونشر', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
        prefixIcon: Icon(icon, color: accentGold, size: 18),
        filled: true, fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Future<void> _confirmDelete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('حذف الثيم', style: TextStyle(color: Colors.white)),
        content: const Text('هل تريد إزالة هذا الثيم من المتجر نهائياً؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('تراجع')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('حذف')),
        ],
      ),
    );
    if (confirm == true) await _db.collection('room_themes').doc(id).delete();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.palette_outlined, size: 80, color: accentGold.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          const Text('خزانة الثيمات فارغة حالياً', style: TextStyle(color: Colors.white24, fontSize: 16)),
        ],
      ),
    );
  }
}
