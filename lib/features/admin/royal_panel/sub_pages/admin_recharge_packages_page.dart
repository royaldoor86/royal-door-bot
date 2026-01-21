import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminRechargePackagesPage extends StatefulWidget {
  final String initialType; // 'coins' or 'gems'
  const AdminRechargePackagesPage({Key? key, required this.initialType}) : super(key: key);

  @override
  State<AdminRechargePackagesPage> createState() => _AdminRechargePackagesPageState();
}

class _AdminRechargePackagesPageState extends State<AdminRechargePackagesPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Color primaryDark = const Color(0xFF0A1F1C);
  final Color accentGold = const Color(0xFFC5A059);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: widget.initialType == 'coins' ? 0 : 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: primaryDark,
        appBar: AppBar(
          backgroundColor: const Color(0xFF051211),
          elevation: 0,
          title: Text('إدارة باقات الشحن', style: TextStyle(color: accentGold, fontWeight: FontWeight.bold)),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: accentGold,
            labelColor: accentGold,
            unselectedLabelColor: Colors.white38,
            tabs: const [
              Tab(text: 'باقات الكوينز 🪙'),
              Tab(text: 'باقات الجواهر 💎'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPackagesList('coins'),
            _buildPackagesList('gems'),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: accentGold,
          onPressed: () => _showAddPackageDialog(_tabController.index == 0 ? 'coins' : 'gems'),
          child: const Icon(Icons.add, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildPackagesList(String type) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('recharge_packages').where('type', isEqualTo: type).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        
        if (docs.isEmpty) {
          return Center(child: Text('لا توجد باقات مضافة حالياً', style: TextStyle(color: Colors.white.withOpacity(0.3))));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final id = docs[index].id;
            return _buildPackageItem(id, data, type);
          },
        );
      },
    );
  }

  Widget _buildPackageItem(String id, Map<String, dynamic> data, String type) {
    final color = type == 'coins' ? Colors.amber : Colors.cyanAccent;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: ListTile(
        leading: Icon(type == 'coins' ? Icons.monetization_on : Icons.diamond, color: color, size: 30),
        title: Text('${data['amount']} ${type == 'coins' ? 'كوينز' : 'جوهرة'}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text('السعر: ${data['price']} \$', style: const TextStyle(color: Colors.greenAccent)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit, color: Colors.white54), onPressed: () => _showAddPackageDialog(type, packageId: id, existingData: data)),
            IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: () => _db.collection('recharge_packages').doc(id).delete()),
          ],
        ),
      ),
    );
  }

  void _showAddPackageDialog(String type, {String? packageId, Map<String, dynamic>? existingData}) {
    final amountCtrl = TextEditingController(text: existingData?['amount']?.toString() ?? '');
    final priceCtrl = TextEditingController(text: existingData?['price']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(packageId == null ? 'إضافة باقة جديدة' : 'تعديل الباقة', style: TextStyle(color: accentGold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(labelText: 'الكمية (${type == 'coins' ? 'كوينز' : 'جواهر'})', labelStyle: const TextStyle(color: Colors.white54)),
            ),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'السعر بالدولار (\$)', labelStyle: TextStyle(color: Colors.white54)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (amountCtrl.text.isNotEmpty && priceCtrl.text.isNotEmpty) {
                final data = {
                  'amount': int.parse(amountCtrl.text),
                  'price': double.parse(priceCtrl.text),
                  'type': type,
                  'updatedAt': FieldValue.serverTimestamp(),
                };
                if (packageId == null) {
                  await _db.collection('recharge_packages').add(data);
                } else {
                  await _db.collection('recharge_packages').doc(packageId).update(data);
                }
                Navigator.pop(ctx);
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
