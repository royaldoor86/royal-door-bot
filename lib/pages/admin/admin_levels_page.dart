import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';

class AdminLevelsPage extends StatefulWidget {
  const AdminLevelsPage({super.key});

  @override
  State<AdminLevelsPage> createState() => _AdminLevelsPageState();
}

class _AdminLevelsPageState extends State<AdminLevelsPage> {
  final _db = FirebaseFirestore.instance;
  final _levelController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1B0233),
      appBar: AppBar(
          title: const Text("إدارة مستويات المتجر"),
          backgroundColor: Colors.transparent),
      body: Column(
        children: [
          _buildAddForm(),
          const Divider(color: Colors.white10),
          Expanded(child: _buildLevelsList()),
        ],
      ),
    );
  }

  Widget _buildAddForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          const Text("صنع مستوى جديد للمتجر",
              style:
                  TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                  child: _adminInput(_levelController, "رقم المستوى",
                      Icons.trending_up, TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(
                  child: _adminInput(_priceController, "السعر بالجواهر",
                      Icons.diamond, TextInputType.number)),
            ],
          ),
          const SizedBox(height: 15),
          AppTheme.gradientButton(
            text: _isSaving ? "جاري الحفظ..." : "إضافة المستوى للمتجر 🚀",
            onPressed: _isSaving ? null : _saveLevel,
          ),
        ],
      ),
    );
  }

  Widget _adminInput(TextEditingController controller, String hint,
      IconData icon, TextInputType type) {
    return TextField(
      controller: controller,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 12),
        prefixIcon: Icon(icon, color: Colors.amber, size: 18),
        filled: true,
        fillColor: Colors.black26,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
    );
  }

  Future<void> _saveLevel() async {
    final lvl = int.tryParse(_levelController.text);
    final prc = int.tryParse(_priceController.text);

    if (lvl == null || prc == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("يرجى إدخال قيم صحيحة")));
      return;
    }

    setState(() => _isSaving = true);
    try {
      // حفظ المستوى في مجموعة خاصة بمتجر المستويات
      await _db.collection('store_levels').doc('lvl_$lvl').set({
        'levelValue': lvl,
        'price': prc,
        'name': "ترقية للمستوى $lvl",
        'category': 'levels',
        'currencyType': 'gems',
        'createdAt': FieldValue.serverTimestamp(),
      });

      _levelController.clear();
      _priceController.clear();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("تمت إضافة المستوى بنجاح ✅")));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("خطأ: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildLevelsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('store_levels').orderBy('levelValue').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return ListTile(
              leading: CircleAvatar(
                  backgroundColor: Colors.amber,
                  child: Text("${data['levelValue']}",
                      style: const TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold))),
              title: Text(data['name'],
                  style: const TextStyle(color: Colors.white)),
              subtitle: Text("السعر: ${data['price']} جوهرة",
                  style: const TextStyle(color: Colors.white54)),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () => docs[i].reference.delete(),
              ),
            );
          },
        );
      },
    );
  }
}
