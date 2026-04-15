import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminInvestmentMgmtPage extends StatefulWidget {
  final String type; // 'coins', 'gems', 'financial'
  const AdminInvestmentMgmtPage({super.key, required this.type});

  @override
  State<AdminInvestmentMgmtPage> createState() => _AdminInvestmentMgmtPageState();
}

class _AdminInvestmentMgmtPageState extends State<AdminInvestmentMgmtPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Color goldColor = const Color(0xFFD4AF37);
  final Color bgColor = const Color(0xFF0A1F1C);

  @override
  Widget build(BuildContext context) {
    String title = widget.type == 'coins' 
        ? 'إدارة استثمار الكوينز' 
        : (widget.type == 'gems' ? 'إدارة استثمار الجواهر' : 'إدارة الاستثمار المالي');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: const Color(0xFF051211),
          title: Text(title, style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.greenAccent),
              onPressed: () => _showAddPackageDialog(),
            ),
            IconButton(
              icon: const Icon(Icons.account_balance_wallet, color: Colors.amberAccent),
              onPressed: () => _showRechargeUserDialog(),
            ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _db.collection('investment_packages').where('type', isEqualTo: widget.type).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final packages = snapshot.data!.docs;
            if (packages.isEmpty) return const Center(child: Text('لا توجد باقات حالياً', style: TextStyle(color: Colors.white54)));

            return ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: packages.length,
              itemBuilder: (context, index) {
                final pkg = packages[index].data() as Map<String, dynamic>;
                final docId = packages[index].id;
                return Container(
                  margin: const EdgeInsets.bottom(12),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: goldColor.withOpacity(0.2)),
                  ),
                  child: ListTile(
                    title: Text(pkg['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('التكلفة: ${pkg['cost']} | الربح: ${pkg['totalProfit']}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blueAccent), onPressed: () => _showAddPackageDialog(docId: docId, existingData: pkg)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _deletePackage(docId)),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _showAddPackageDialog({String? docId, Map<String, dynamic>? existingData}) {
    final titleController = TextEditingController(text: existingData?['title']);
    final costController = TextEditingController(text: existingData?['cost']?.toString());
    final weeklyProfitController = TextEditingController(text: existingData?['weeklyProfit']);
    final totalProfitController = TextEditingController(text: existingData?['totalProfit']);
    final daysController = TextEditingController(text: existingData?['days']?.toString() ?? '30');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF051211),
        title: Text(docId == null ? 'إضافة باقة استثمار' : 'تعديل باقة', style: TextStyle(color: goldColor)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildField(titleController, 'اسم الباقة'),
              _buildField(costController, 'التكلفة', keyboardType: TextInputType.number),
              _buildField(weeklyProfitController, 'الربح الأسبوعي (مثلاً 5%)'),
              _buildField(totalProfitController, 'إجمالي الربح (مثلاً 20%)'),
              _buildField(daysController, 'عدد الأيام', keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.white24))),
          ElevatedButton(
            onPressed: () async {
              final data = {
                'title': titleController.text,
                'cost': num.tryParse(costController.text) ?? 0,
                'weeklyProfit': weeklyProfitController.text,
                'totalProfit': totalProfitController.text,
                'days': int.tryParse(daysController.text) ?? 30,
                'type': widget.type,
                'updatedAt': FieldValue.serverTimestamp(),
              };
              if (docId == null) {
                await _db.collection('investment_packages').add(data);
              } else {
                await _db.collection('investment_packages').doc(docId).update(data);
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: goldColor),
            child: const Text('حفظ', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showRechargeUserDialog() {
    final royalIdController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF051211),
        title: Text('شحن محفظة استثمار ${widget.type}', style: TextStyle(color: goldColor)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildField(royalIdController, 'الآيدي الملكي للمستخدم'),
            _buildField(amountController, 'المبلغ', keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.white24))),
          ElevatedButton(
            onPressed: () async {
              final snap = await _db.collection('users').where('royalId', isEqualTo: royalIdController.text).limit(1).get();
              if (snap.docs.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('المستخدم غير موجود')));
                return;
              }
              final userDoc = snap.docs.first;
              final amount = num.tryParse(amountController.text) ?? 0;
              final walletField = widget.type == 'coins' 
                  ? 'coins_investment_wallet' 
                  : (widget.type == 'gems' ? 'gems_investment_wallet' : 'financial_investment_wallet');
              
              await _db.collection('users').doc(userDoc.id).update({
                walletField: FieldValue.increment(amount)
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الشحن بنجاح ✅'), backgroundColor: Colors.green));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
            child: const Text('شحن الآن', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePackage(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        title: const Text('حذف الباقة', style: TextStyle(color: Colors.redAccent)),
        content: const Text('هل أنت متأكد من حذف هذه الباقة الاستثمارية؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), child: const Text('حذف')),
        ],
      ),
    );
    if (confirm == true) await _db.collection('investment_packages').doc(id).delete();
  }

  Widget _buildField(TextEditingController controller, String label, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          focusedBorder: BorderSide(color: goldColor),
        ),
      ),
    );
  }
}
