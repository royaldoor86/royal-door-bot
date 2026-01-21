import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AdminInvestmentsPage extends StatefulWidget {
  const AdminInvestmentsPage({super.key});

  @override
  State<AdminInvestmentsPage> createState() => _AdminInvestmentsPageState();
}

class _AdminInvestmentsPageState extends State<AdminInvestmentsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _chargeUsd(
      String uid, String userName, double currentUsd) async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            backgroundColor: const Color(0xFF1B0233),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('شحن رصيد مالي (USD) لـ $userName',
                style: const TextStyle(color: Colors.white, fontSize: 16)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('المبلغ بالدولار \$',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 10),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                      decimal: true, signed: true),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'مثال: 100 أو -50',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('إلغاء',
                      style: TextStyle(color: Colors.white54))),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, controller.text),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent),
                child: const Text('شحن الآن',
                    style: TextStyle(color: Colors.black)),
              ),
            ],
          ),
        );
      },
    );

    if (result == null || result.isEmpty) return;
    final amount = double.tryParse(result);
    if (amount == null || amount == 0) return;

    try {
      await _db.collection('users').doc(uid).update({
        'balance_usd': FieldValue.increment(amount),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('تم تحديث الرصيد بنجاح لـ $userName'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AppTheme.background(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('إدارة الاستثمارات المالية 💰',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'ابحث (بالاسم، الايميل، أو الآيدي الملكي)...',
                    hintStyle: const TextStyle(color: Colors.white54),
                    prefixIcon:
                        const Icon(Icons.search, color: Colors.greenAccent),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.06),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _db.collection('users').snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const Center(child: CircularProgressIndicator());

                    var docs = snapshot.data!.docs;
                    if (_searchText.isNotEmpty) {
                      docs = docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = (data['name'] ?? data['displayName'] ?? '')
                            .toString()
                            .toLowerCase();
                        final email =
                            (data['email'] ?? '').toString().toLowerCase();
                        final royalId = (data['royalId'] ?? '').toString().toLowerCase();
                        return name.contains(_searchText) ||
                            email.contains(_searchText) ||
                            royalId.contains(_searchText) ||
                            doc.id.contains(_searchText);
                      }).toList();
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final uid = docs[index].id;
                        final name = data['name'] ?? data['displayName'] ?? 'مستخدم';
                        final royalId = data['royalId'] ?? 'بدون آيدي';
                        final usd = (data['balance_usd'] ?? 0).toDouble();

                        return Card(
                          color: Colors.white.withOpacity(0.05),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green.withOpacity(0.2),
                              child: const Icon(Icons.person,
                                  color: Colors.greenAccent),
                            ),
                            title: Text(name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('الآيدي الملكي: $royalId', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                Text('رصيد الاستثمار: \$$usd',
                                    style:
                                        const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            trailing: ElevatedButton(
                              onPressed: () => _chargeUsd(uid, name, usd),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.greenAccent,
                                  foregroundColor: Colors.black),
                              child: const Text('شحن \$',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
