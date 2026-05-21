import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminHarvestWalletMgmtPage extends StatefulWidget {
  const AdminHarvestWalletMgmtPage({super.key});

  @override
  State<AdminHarvestWalletMgmtPage> createState() =>
      _AdminHarvestWalletMgmtPageState();
}

class _AdminHarvestWalletMgmtPageState
    extends State<AdminHarvestWalletMgmtPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Color goldColor = const Color(0xFFD4AF37);
  final Color bgColor = const Color(0xFF0A1F1C);
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: const Color(0xFF051211),
          title: Text('شحن وتعديل أرصدة الرعية',
              style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.search, color: Colors.white70),
              onPressed: () => _showSearchDialog(),
            ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _db.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final users = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = data['name']?.toString().toLowerCase() ?? '';
              final royalId = data['royalId']?.toString().toLowerCase() ?? '';
              final query = _searchQuery.toLowerCase();
              return name.contains(query) || royalId.contains(query);
            }).toList();

            if (users.isEmpty) {
              return Center(
                child: Text(
                  _searchQuery.isEmpty
                      ? 'لا يوجد مستخدمون'
                      : 'لا توجد نتائج للبحث',
                  style: const TextStyle(color: Colors.white54),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final userDoc = users[index];
                final data = userDoc.data() as Map<String, dynamic>;

                final stars = _parseDouble(data['stars'] ?? data['coins'] ?? 0);
                final gems = _parseDouble(data['gems'] ?? 0);
                final harvestWallet = _parseDouble(data['harvest_wallet'] ?? 0);

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: goldColor.withValues(alpha: 0.2)),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: goldColor.withValues(alpha: 0.1),
                      backgroundImage: (data['profilePic'] ?? '').isNotEmpty
                          ? NetworkImage(data['profilePic'])
                          : null,
                      child: (data['profilePic'] ?? '').isEmpty
                          ? Icon(Icons.person, color: goldColor)
                          : null,
                    ),
                    title: Text(
                      data['name'] ?? 'مستخدم جديد',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ID: ${data['royalId'] ?? userDoc.id.substring(0, 8)}',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 10),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 10,
                          runSpacing: 4,
                          children: [
                            _miniStat(Icons.stars,
                                "${stars.toStringAsFixed(0)} ⭐", Colors.amber),
                            _miniStat(Icons.diamond,
                                "${gems.toStringAsFixed(0)} 💎", Colors.cyan),
                            _miniStat(
                                Icons.account_balance_wallet,
                                "${harvestWallet.toStringAsFixed(0)} 💰",
                                Colors.greenAccent),
                          ],
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded,
                          color: Colors.greenAccent, size: 32),
                      onPressed: () => _showAdjustDialog(
                          userDoc.id, data['name'] ?? 'مستخدم', data),
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

  Widget _miniStat(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                color: color.withValues(alpha: 0.9),
                fontSize: 10,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF051211),
        title: Text('البحث عن مستخدم', style: TextStyle(color: goldColor)),
        content: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'اسم المستخدم أو الآيدي الملكي',
            hintStyle: const TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: goldColor.withValues(alpha: 0.5)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: goldColor),
            ),
          ),
          onChanged: (value) => setState(() => _searchQuery = value),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _searchController.clear();
              });
              Navigator.pop(ctx);
            },
            child: const Text('مسح البحث',
                style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: goldColor),
            child: const Text('إغلاق', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  void _showAdjustDialog(
      String userId, String userName, Map<String, dynamic> userData) {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    String selectedWallet = 'stars'; // stars, gems, harvest_wallet
    String operationType = 'increase'; // increase, decrease

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, dialogSetState) {
          double currentBalance = 0;
          String currencyName = "";

          if (selectedWallet == 'stars') {
            currentBalance =
                _parseDouble(userData['stars'] ?? userData['coins'] ?? 0);
            currencyName = "نجمة ⭐";
          } else if (selectedWallet == 'gems') {
            currentBalance = _parseDouble(userData['gems'] ?? 0);
            currencyName = "جوهرة 💎";
          } else if (selectedWallet == 'harvest_wallet') {
            currentBalance = _parseDouble(userData['harvest_wallet'] ?? 0);
            currencyName = "رصيد الحصاد";
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF0F1B25),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
                side: BorderSide(color: goldColor, width: 0.5)),
            title: Text(
              'شحن حساب: $userName',
              style: TextStyle(
                  color: goldColor, fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    alignment: WrapAlignment.center,
                    children: [
                      _choiceChip('نجوم', 'stars', selectedWallet,
                          (v) => dialogSetState(() => selectedWallet = v)),
                      _choiceChip('جواهر', 'gems', selectedWallet,
                          (v) => dialogSetState(() => selectedWallet = v)),
                      _choiceChip('حصاد', 'harvest_wallet', selectedWallet,
                          (v) => dialogSetState(() => selectedWallet = v)),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _opBtn(
                          'شحن رصيد',
                          'increase',
                          operationType,
                          Colors.green,
                          () =>
                              dialogSetState(() => operationType = 'increase')),
                      const SizedBox(width: 10),
                      _opBtn(
                          'خصم رصيد',
                          'decrease',
                          operationType,
                          Colors.red,
                          () =>
                              dialogSetState(() => operationType = 'decrease')),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'الرصيد الحالي: ${currentBalance.toStringAsFixed(0)} $currencyName',
                    style: TextStyle(
                        color: goldColor.withValues(alpha: 0.8), fontSize: 13),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'المبلغ المراد تعديله',
                      labelStyle:
                          const TextStyle(color: Colors.white38, fontSize: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15)),
                      prefixIcon: const Icon(Icons.monetization_on_rounded,
                          color: Colors.amber),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: reasonController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'سبب العملية (اختياري)',
                      labelStyle:
                          const TextStyle(color: Colors.white38, fontSize: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('إلغاء',
                      style: TextStyle(color: Colors.white24))),
              ElevatedButton(
                onPressed: () async {
                  final amt =
                      double.tryParse(amountController.text.trim())?.abs() ?? 0;
                  if (amt <= 0) {
                    return;
                  }

                  final finalAdjustment =
                      operationType == 'increase' ? amt : -amt;

                  try {
                    await _db.runTransaction((transaction) async {
                      final userRef = _db.collection('users').doc(userId);

                      Map<String, dynamic> updates = {
                        selectedWallet: FieldValue.increment(finalAdjustment),
                      };

                      if (selectedWallet == 'stars') {
                        updates['coins'] =
                            FieldValue.increment(finalAdjustment);
                      }

                      transaction.update(userRef, updates);

                      // سجل العملية
                      final transferRef =
                          _db.collection('harvest_transfers').doc();
                      transaction.set(transferRef, {
                        'userId': userId,
                        'amount': amt,
                        'currency': selectedWallet,
                        'type': 'admin_adjustment',
                        'subType': operationType,
                        'reason': reasonController.text.isEmpty
                            ? 'تعديل من إدارة الاقتصاد'
                            : reasonController.text,
                        'timestamp': FieldValue.serverTimestamp(),
                      });
                    });

                    if (context.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('تم تنفيذ العملية بنجاح ✅'),
                          backgroundColor: Colors.green));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('خطأ: $e'),
                          backgroundColor: Colors.red));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      operationType == 'increase' ? Colors.green : Colors.red,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                    operationType == 'increase' ? 'تأكيد الشحن' : 'تأكيد الخصم',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _choiceChip(
      String label, String value, String current, Function(String) onSel) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 10)),
      selected: current == value,
      onSelected: (s) => onSel(value),
      selectedColor: goldColor.withValues(alpha: 0.3),
      labelStyle:
          TextStyle(color: current == value ? goldColor : Colors.white54),
    );
  }

  Widget _opBtn(String label, String type, String current, Color color,
      VoidCallback onTap) {
    bool isSel = current == type;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSel ? color : Colors.white12),
        ),
        child: Text(label,
            style: TextStyle(
                color: isSel ? color : Colors.white38,
                fontWeight: FontWeight.bold,
                fontSize: 11)),
      ),
    );
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
