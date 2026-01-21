import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminSpecialIdsPage extends StatefulWidget {
  const AdminSpecialIdsPage({Key? key}) : super(key: key);

  @override
  State<AdminSpecialIdsPage> createState() => _AdminSpecialIdsPageState();
}

class _AdminSpecialIdsPageState extends State<AdminSpecialIdsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  final Color bgColor = const Color(0xFF0A1F1C);
  final Color goldColor = const Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: const Color(0xFF051211),
          title: Text('إدارة المعرفات الملكية', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: goldColor,
            labelColor: goldColor,
            unselectedLabelColor: Colors.white38,
            tabs: const [
              Tab(text: 'سوق المعرفات'),
              Tab(text: 'منح يدوي'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildStoreManagement(),
            _buildManualGrant(),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreManagement() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _showAddIdDialog(),
            icon: const Icon(Icons.add_circle, color: Colors.black),
            label: const Text('إضافة آيدي مميز للمتجر', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: goldColor,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
          ),
        ),
        
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _db.collection('special_ids').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.amber));
              }

              final docs = snapshot.data?.docs ?? [];

              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.badge_outlined, size: 100, color: goldColor.withOpacity(0.2)),
                      const SizedBox(height: 20),
                      const Text('قائمة المعرفات فارغة حالياً', style: TextStyle(color: Colors.white70, fontSize: 18)),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: _seedInitialData,
                        child: Text('انقر هنا لتوليد معرفات تلقائية ✨', style: TextStyle(color: goldColor)),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return _buildIdItem(docs[index].id, data);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildIdItem(String id, Map<String, dynamic> data) {
    final currencyIcon = (data['currencyType'] ?? 'coins') == 'gems' ? Icons.diamond : Icons.monetization_on;
    final currencyColor = (data['currencyType'] ?? 'coins') == 'gems' ? Colors.cyanAccent : Colors.amber;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: goldColor.withOpacity(0.2)),
      ),
      child: ListTile(
        leading: Icon(Icons.tag, color: goldColor, size: 30),
        title: Text(data['royalId'] ?? '---', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        subtitle: Row(
          children: [
            Text('السعر: ${data['price']}', style: const TextStyle(color: Colors.white54)),
            const SizedBox(width: 4),
            Icon(currencyIcon, size: 14, color: currencyColor),
            const Text(' | ', style: TextStyle(color: Colors.white24)),
            Text('الفئة: ${data['category']}', style: const TextStyle(color: Colors.white54)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_forever, color: Colors.redAccent),
          onPressed: () => _db.collection('special_ids').doc(id).delete(),
        ),
      ),
    );
  }

  void _showAddIdDialog() {
    final idController = TextEditingController();
    final priceController = TextEditingController();
    String category = 'ملكي';
    String currencyType = 'coins'; // الافتراضي كوينز

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('إضافة معرف مميز جديد', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('الايدي المميز'),
                TextField(controller: idController, style: const TextStyle(color: Colors.white), decoration: _inputDeco('مثال: 777 أو KING')),
                const SizedBox(height: 15),
                
                _buildLabel('نوع العملة للسعر'),
                Row(
                  children: [
                    _buildChoiceChip('كوينز 🪙', 'coins', currencyType, (val) => setModalState(() => currencyType = val)),
                    const SizedBox(width: 10),
                    _buildChoiceChip('جواهر 💎', 'gems', currencyType, (val) => setModalState(() => currencyType = val)),
                  ],
                ),
                const SizedBox(height: 15),

                _buildLabel('السعر المطللوب'),
                TextField(controller: priceController, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: _inputDeco('أدخل القيمة الرقمية')),
                const SizedBox(height: 15),

                _buildLabel('الفئة الملكية'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: category,
                      dropdownColor: const Color(0xFF1A1A2E),
                      isExpanded: true,
                      items: ['ذهبي', 'ملكي', 'أسطوري'].map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white)))).toList(),
                      onChanged: (v) => setModalState(() => category = v!),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.white38))),
            ElevatedButton(
              onPressed: () async {
                if (idController.text.isNotEmpty && priceController.text.isNotEmpty) {
                  await _db.collection('special_ids').add({
                    'royalId': idController.text.trim(),
                    'price': int.parse(priceController.text),
                    'currencyType': currencyType, // حفظ نوع العملة
                    'category': category,
                    'createdAt': FieldValue.serverTimestamp(),
                    'showInStore': true,
                    'isSold': false,
                  });
                  Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: goldColor),
              child: const Text('حفظ ونشر الآن', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(text, style: TextStyle(color: goldColor.withOpacity(0.7), fontSize: 12)));

  InputDecoration _inputDeco(String hint) => InputDecoration(
    hintText: hint, hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
    filled: true, fillColor: Colors.white.withOpacity(0.05),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
  );

  Widget _buildChoiceChip(String label, String value, String current, Function(String) onSelect) {
    bool selected = current == value;
    return ChoiceChip(
      label: Text(label, style: TextStyle(color: selected ? Colors.black : Colors.white, fontSize: 12)),
      selected: selected,
      onSelected: (_) => onSelect(value),
      selectedColor: goldColor,
      backgroundColor: Colors.white.withOpacity(0.05),
    );
  }

  Widget _buildManualGrant() {
    final userCtrl = TextEditingController();
    final idCtrl = TextEditingController();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          TextField(controller: userCtrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: 'ابحث عن المستخدم (ID الحالي)', labelStyle: TextStyle(color: goldColor))),
          const SizedBox(height: 20),
          TextField(controller: idCtrl, style: const TextStyle(color: Colors.white), decoration: InputDecoration(labelText: 'الايدي الملكي الجديد لمنحه', labelStyle: TextStyle(color: goldColor))),
          const SizedBox(height: 40),
          ElevatedButton(
            onPressed: () => _grantId(userCtrl.text, idCtrl.text),
            style: ElevatedButton.styleFrom(backgroundColor: goldColor, minimumSize: const Size(double.infinity, 55)),
            child: const Text('منح المعرف الآن مجاناً', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _grantId(String oldId, String newId) async {
    if (oldId.isEmpty || newId.isEmpty) return;
    final snap = await _db.collection('users').where('royalId', isEqualTo: oldId).get();
    if (snap.docs.isNotEmpty) {
      await snap.docs.first.reference.update({'royalId': newId});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم منح المعرف الجديد بنجاح ✅')));
    }
  }

  Future<void> _seedInitialData() async {
    await _db.collection('special_ids').add({'royalId': '777', 'price': 5000, 'currencyType': 'coins', 'category': 'ذهبي', 'showInStore': true, 'createdAt': FieldValue.serverTimestamp()});
    await _db.collection('special_ids').add({'royalId': 'ROYAL', 'price': 20000, 'currencyType': 'gems', 'category': 'أسطوري', 'showInStore': true, 'createdAt': FieldValue.serverTimestamp()});
  }
}
