import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../models/family_model.dart';
import '../../../../services/storage_service.dart';

class AdminFamiliesPage extends StatefulWidget {
  const AdminFamiliesPage({Key? key}) : super(key: key);

  @override
  State<AdminFamiliesPage> createState() => _AdminFamiliesPageState();
}

class _AdminFamiliesPageState extends State<AdminFamiliesPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";

  final Color primaryDark = const Color(0xFF0A1F1C);
  final Color accentGold = const Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: primaryDark,
        appBar: AppBar(
          backgroundColor: const Color(0xFF051211),
          elevation: 0,
          title: Text('إدارة العائلات الملكية', style: TextStyle(color: accentGold, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: Column(
          children: [
            _buildAddHeader(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _db.collection('families').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.amber));
                  }

                  final docs = snapshot.data?.docs ?? [];
                  final filtered = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return (data['name'] ?? '').toString().toLowerCase().contains(_searchText.toLowerCase());
                  }).toList();

                  if (filtered.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final family = FamilyModel.fromFirestore(filtered[index] as DocumentSnapshot<Map<String, dynamic>>);
                      return _buildFamilyCard(family);
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF051211),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: () => _showCreateFamilyDialog(),
            icon: const Icon(Icons.add_home_work_rounded, color: Colors.black),
            label: const Text('تأسيس عائلة ملكية جديدة', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: accentGold, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'ابحث عن عائلة...',
              hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
              prefixIcon: Icon(Icons.search, color: accentGold, size: 20),
              filled: true, fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
            onChanged: (v) => setState(() => _searchText = v),
          ),
        ],
      ),
    );
  }

  void _showCreateFamilyDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final sloganCtrl = TextEditingController();
    File? selectedLogo;
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25), side: BorderSide(color: accentGold.withOpacity(0.3))),
          title: Text('تأسيس عائلة جديدة', style: TextStyle(color: accentGold, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final img = await picker.pickImage(source: ImageSource.gallery);
                    if (img != null) setModalState(() => selectedLogo = File(img.path));
                  },
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white10,
                    backgroundImage: selectedLogo != null ? FileImage(selectedLogo!) : null,
                    child: selectedLogo == null ? Icon(Icons.add_a_photo, color: accentGold) : null,
                  ),
                ),
                const SizedBox(height: 20),
                _buildRoyalField(nameCtrl, 'اسم العائلة', Icons.castle),
                const SizedBox(height: 12),
                _buildRoyalField(sloganCtrl, 'شعار العائلة القصير', Icons.format_quote),
                const SizedBox(height: 12),
                _buildRoyalField(descCtrl, 'وصف العائلة', Icons.description, maxLines: 2),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.white38))),
            if (isLoading) const CircularProgressIndicator()
            else ElevatedButton(
              onPressed: () async {
                if (nameCtrl.text.isEmpty || selectedLogo == null) return;
                setModalState(() => isLoading = true);
                try {
                  final familyId = _db.collection('families').doc().id;
                  final logoUrl = await StorageService.uploadFamilyLogo(familyId, selectedLogo!);
                  
                  await _db.collection('families').doc(familyId).set({
                    'name': nameCtrl.text.trim(),
                    'logoUrl': logoUrl,
                    'slogan': sloganCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'creatorId': 'ADMIN',
                    'level': 1,
                    'memberCount': 1,
                    'totalPoints': 0,
                    'isVerified': true,
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  Navigator.pop(ctx);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
                } finally {
                  setModalState(() => isLoading = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: accentGold, foregroundColor: Colors.black),
              child: const Text('تأسيس الآن'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoyalField(TextEditingController ctrl, String hint, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
        prefixIcon: Icon(icon, color: accentGold, size: 18),
        filled: true, fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildFamilyCard(FamilyModel family) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: accentGold.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: Colors.black,
          backgroundImage: family.logoUrl.isNotEmpty ? NetworkImage(family.logoUrl) : null,
          child: family.logoUrl.isEmpty ? Icon(Icons.castle, color: accentGold) : null,
        ),
        title: Text(family.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(family.slogan, style: TextStyle(color: accentGold.withOpacity(0.5), fontSize: 11)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
          onPressed: () => _confirmDelete(family),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(FamilyModel family) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2A0000),
        title: const Text('حذف العائلة', style: TextStyle(color: Colors.redAccent)),
        content: Text('هل أنت متأكد من حذف عائلة (${family.name}) نهائياً؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('حذف')),
        ],
      ),
    );
    if (confirm == true) await _db.collection('families').doc(family.id).delete();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.castle_rounded, size: 80, color: accentGold.withOpacity(0.1)),
          const SizedBox(height: 16),
          const Text('لا توجد عائلات مسجلة حالياً', style: TextStyle(color: Colors.white24, fontSize: 16)),
          const SizedBox(height: 10),
          TextButton(onPressed: _seedDemoFamily, child: Text('توليد عائلة تجريبية ✨', style: TextStyle(color: accentGold))),
        ],
      ),
    );
  }

  Future<void> _seedDemoFamily() async {
    await _db.collection('families').add({
      'name': 'عائلة رويال دور',
      'logoUrl': '',
      'slogan': 'الملوك لا ينحنون',
      'description': 'العائلة الرسمية لتطبيق رويال دور',
      'creatorId': 'ADMIN',
      'level': 10,
      'memberCount': 50,
      'isVerified': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
