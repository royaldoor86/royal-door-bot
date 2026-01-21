import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../models/entry_effect_model.dart';
import '../../../../services/storage_service.dart';

class AdminEntryEffectsPage extends StatefulWidget {
  const AdminEntryEffectsPage({Key? key}) : super(key: key);

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
          title: Text('إدارة تأثيرات الدخول', style: TextStyle(color: accentGold, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: Column(
          children: [
            _buildAddHeader(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _db.collection('entry_effects').orderBy('price', descending: false).snapshots(),
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
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final effect = EntryEffectModel.fromFirestore(docs[index] as DocumentSnapshot<Map<String, dynamic>>);
                      return _buildEffectCard(effect);
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
        label: const Text('إضافة تأثير دخول جديد', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGold,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }

  Widget _buildEffectCard(EntryEffectModel effect) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: accentGold.withOpacity(0.1)),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.rocket_launch_rounded, color: accentGold, size: 40),
                const SizedBox(height: 10),
                Text(effect.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text('${effect.price} كوينز 🪙', style: TextStyle(color: accentGold, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Positioned(
            top: 5, right: 5,
            child: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
              onPressed: () => _db.collection('entry_effects').doc(effect.id).delete(),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEffectDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final linkCtrl = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25), side: BorderSide(color: accentGold.withOpacity(0.3))),
          title: Text('تخصيص تأثير دخول', style: TextStyle(color: accentGold, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('اسم التأثير'),
                _buildInput(nameCtrl, 'مثال: دخول البرق الملكي', Icons.title),
                const SizedBox(height: 15),
                _buildLabel('السعر بالكوينز'),
                _buildInput(priceCtrl, '0', Icons.monetization_on, isNum: true),
                const SizedBox(height: 15),
                _buildLabel('رابط ملف التأثير (Lottie/GIF)'),
                _buildInput(linkCtrl, 'https://...', Icons.link),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.white38))),
            if (isLoading) const CircularProgressIndicator()
            else ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty || linkCtrl.text.isEmpty) return;
                setModalState(() => isLoading = true);
                await _db.collection('entry_effects').add({
                  'name': nameCtrl.text.trim(),
                  'lottieUrl': linkCtrl.text.trim(),
                  'price': int.parse(priceCtrl.text),
                  'isActive': true,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: accentGold, foregroundColor: Colors.black),
              child: const Text('نشر في المتجر'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8, right: 5), child: Text(text, style: TextStyle(color: accentGold.withOpacity(0.7), fontSize: 12)));

  Widget _buildInput(TextEditingController ctrl, String hint, IconData icon, {bool isNum = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
        prefixIcon: Icon(icon, color: accentGold, size: 20),
        filled: true, fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_fix_high_rounded, size: 80, color: accentGold.withOpacity(0.1)),
          const SizedBox(height: 16),
          const Text('لا توجد تأثيرات دخول حالياً', style: TextStyle(color: Colors.white24, fontSize: 16)),
        ],
      ),
    );
  }
}
