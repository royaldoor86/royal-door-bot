import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminVerificationMgmtPage extends StatefulWidget {
  const AdminVerificationMgmtPage({super.key});

  @override
  State<AdminVerificationMgmtPage> createState() => _AdminVerificationMgmtPageState();
}

class _AdminVerificationMgmtPageState extends State<AdminVerificationMgmtPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Color primaryDark = const Color(0xFF0A1F1C);
  final Color accentGold = const Color(0xFFC5A059);
  
  // اللون الأزرق الطبيعي الموحد للتوثيق
  final String standardBlueHex = '#FF2196F3';

  Color _parseColor(String? hex) {
    try {
      String cleanHex = (hex ?? standardBlueHex).replaceAll('#', '').replaceAll('0x', '');
      if (cleanHex.length == 6) cleanHex = 'FF$cleanHex';
      return Color(int.parse(cleanHex, radix: 16));
    } catch (_) {
      return const Color(0xFF2196F3);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: primaryDark,
        appBar: AppBar(
          backgroundColor: const Color(0xFF051211),
          title: Text('إدارة توثيق الحسابات', style: TextStyle(color: accentGold, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _db.collection('verifications').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.amber));
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) return _buildEmptyState();

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      final id = docs[index].id;
                      return _buildVerificationCard(id, data);
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF051211),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: ElevatedButton.icon(
        onPressed: () => _showAddDialog(),
        icon: const Icon(Icons.verified_user_rounded, color: Colors.black),
        label: const Text('إضافة حزمة توثيق جديدة', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGold,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    );
  }

  Widget _buildVerificationCard(String id, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentGold.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        leading: Icon(Icons.verified, color: _parseColor(data['color']), size: 30),
        title: Text(data['name'] ?? 'توثيق حساب', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text('السعر: ${data['price']} نجوم ⭐', style: TextStyle(color: accentGold, fontSize: 13)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: () => _deleteVerification(id),
        ),
      ),
    );
  }

  Future<void> _deleteVerification(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('حذف التوثيق', style: TextStyle(color: Colors.white)),
        content: const Text('هل أنت متأكد من حذف هذه الحزمة؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('حذف', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
    if (confirm == true) {
      await _db.collection('verifications').doc(id).delete();
    }
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text('إنشاء حزمة توثيق', style: TextStyle(color: accentGold, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel('اسم الحزمة (مثال: توثيق رويال)'),
              _buildField(nameCtrl, 'الاسم'),
              const SizedBox(height: 15),
              _buildLabel('السعر بالنجوم ⭐'),
              _buildField(priceCtrl, '0', isNumber: true),
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    const Text('لون علامة التوثيق (أزرق افتراضي)', style: TextStyle(color: Colors.white54, fontSize: 11)),
                    const SizedBox(height: 10),
                    Icon(Icons.verified, color: _parseColor(standardBlueHex), size: 50),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;
              await _db.collection('verifications').add({
                'name': nameCtrl.text.trim(),
                'price': int.parse(priceCtrl.text),
                'color': standardBlueHex,
                'createdAt': FieldValue.serverTimestamp(),
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: accentGold, foregroundColor: Colors.black),
            child: const Text('حفظ ونشر'),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8, right: 5), child: Text(text, style: TextStyle(color: accentGold.withValues(alpha: 0.7), fontSize: 12)));

  Widget _buildField(TextEditingController ctrl, String hint, {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
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
          Icon(Icons.verified_outlined, size: 80, color: accentGold.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          const Text('لا توجد حزم توثيق مضافة', style: TextStyle(color: Colors.white24, fontSize: 16)),
        ],
      ),
    );
  }
}
