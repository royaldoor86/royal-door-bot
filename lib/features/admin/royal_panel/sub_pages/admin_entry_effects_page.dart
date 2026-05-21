import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AdminEntryEffectsPage extends StatefulWidget {
  const AdminEntryEffectsPage({super.key});

  @override
  State<AdminEntryEffectsPage> createState() => _AdminEntryEffectsPageState();
}

class _AdminEntryEffectsPageState extends State<AdminEntryEffectsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Color primaryDark = const Color(0xFF0A1F1C);
  final Color accentGold = const Color(0xFFC5A059);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF021412),
        appBar: AppBar(
          backgroundColor: const Color(0xFF042F2C),
          elevation: 0,
          title: Text('إدارة مؤثرات الشاشة الكاملة', style: TextStyle(color: accentGold, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: Column(
          children: [
            _buildAddHeader(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _db.collection('entry_effects').orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.amber));
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) return _buildEmptyState();

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      return _buildEffectCard(docs[index].id, data);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF042F2C),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: ElevatedButton.icon(
        onPressed: () => _showAddEffectDialog(),
        icon: const Icon(Icons.auto_fix_high_rounded, color: Colors.black),
        label: const Text('إضافة مؤثر دخول جديد', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGold,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }

  Widget _buildEffectCard(String id, Map<String, dynamic> data) {
    final String url = data['lottieUrl'] ?? '';
    final bool isLottie = url.contains('.json');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: accentGold.withValues(alpha: 0.1)),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: isLottie 
                      ? Lottie.network(url, fit: BoxFit.contain)
                      : CachedNetworkImage(imageUrl: url, fit: BoxFit.contain, placeholder: (c,u) => const Icon(Icons.movie, color: Colors.white10)),
                  ),
                ),
                const SizedBox(height: 10),
                Text(data['name'] ?? 'بدون اسم', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                Text('${data['price'] ?? 0} نجمة ⭐', style: TextStyle(color: accentGold, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Positioned(
            top: 5, right: 5,
            child: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
              onPressed: () => _db.collection('entry_effects').doc(id).delete(),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEffectDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    File? pickedFile;
    bool isLottie = false;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('تخصيص مؤثر شاشة كاملة', style: TextStyle(color: accentGold, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                
                GestureDetector(
                  onTap: () async {
                    // اختيار ملف (GIF من الاستوديو أو JSON من الملفات)
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.custom,
                      allowedExtensions: ['json', 'gif'],
                    );
                    if (result != null) {
                      setModalState(() {
                        pickedFile = File(result.files.single.path!);
                        isLottie = result.files.single.extension == 'json';
                      });
                    }
                  },
                  child: Container(
                    height: 150, width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: accentGold.withValues(alpha: 0.3), style: BorderStyle.solid),
                    ),
                    child: pickedFile != null 
                      ? (isLottie 
                          ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.data_object, color: Colors.amber, size: 40), Text(pickedFile!.path.split('/').last, style: const TextStyle(color: Colors.white70, fontSize: 10))]))
                          : ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.file(pickedFile!, fit: BoxFit.contain)))
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload_outlined, color: accentGold, size: 50),
                            const Text('انقر لرفع ملف (GIF أو Lottie JSON)', style: TextStyle(color: Colors.white38, fontSize: 12)),
                          ],
                        ),
                  ),
                ),

                const SizedBox(height: 20),
                _buildInput(nameCtrl, 'اسم المؤثر (مثلاً: دخول التنين)', Icons.title),
                const SizedBox(height: 15),
                _buildInput(priceCtrl, 'السعر بالنجوم ⭐', Icons.stars, isNum: true),
                const SizedBox(height: 25),
                
                if (isLoading)
                  const CircularProgressIndicator(color: Colors.amber)
                else
                  ElevatedButton(
                    onPressed: () async {
                      if (nameCtrl.text.isEmpty || pickedFile == null || priceCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إكمال جميع البيانات')));
                        return;
                      }
                      
                      setModalState(() => isLoading = true);
                      try {
                        final ext = isLottie ? 'json' : 'gif';
                        final ref = FirebaseStorage.instance.ref().child('entry_effects/${DateTime.now().millisecondsSinceEpoch}.$ext');
                        await ref.putFile(pickedFile!, SettableMetadata(contentType: isLottie ? 'application/json' : 'image/gif'));
                        final downloadUrl = await ref.getDownloadURL();

                        await _db.collection('entry_effects').add({
                          'name': nameCtrl.text.trim(),
                          'lottieUrl': downloadUrl,
                          'price': int.parse(priceCtrl.text),
                          'isActive': true,
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                        if (mounted) Navigator.pop(ctx);
                      } catch (e) {
                        setModalState(() => isLoading = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل الرفع: $e')));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentGold, 
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text('نشر المؤثر في المتجر ✨', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String hint, IconData icon, {bool isNum = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
        prefixIcon: Icon(icon, color: accentGold, size: 20),
        filled: true, fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_fix_high_rounded, size: 80, color: accentGold.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          const Text('لا توجد تأثيرات دخول حالياً', style: TextStyle(color: Colors.white24, fontSize: 16)),
        ],
      ),
    );
  }
}
