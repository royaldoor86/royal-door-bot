import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final TextEditingController searchController = TextEditingController();
  String _searchText = "";

  final Color primaryDark = const Color(0xFF0A1F1C);
  final Color accentGold = const Color(0xFFD4AF37);

  Future<void> _deleteUserAndBan(String uid, String name, String? email) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.redAccent, width: 0.5)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text("حذف وحظر نهائي",
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
            "هل أنت متأكد من حذف $name؟\n\nسيتم مسح كافة البيانات وحظر البريد الإلكتروني (${email ?? 'غير متوفر'}) من التسجيل مجدداً نهائياً 🚫.",
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  const Text("إلغاء", style: TextStyle(color: Colors.white38))),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: const Text("حذف وحظر",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // 1. حظر البريد الإلكتروني في القائمة السوداء
        if (email != null && email.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('banned_emails')
              .doc(email)
              .set({
            'uid': uid,
            'name': name,
            'bannedAt': FieldValue.serverTimestamp(),
            'reason': 'Deleted and banned by admin through Users Management',
          });
        }

        // 2. الحذف من Auth عبر Cloud Function (adminBanUser يعطل الحساب حالياً)
        try {
          await FirebaseFunctions.instance
              .httpsCallable('adminBanUser')
              .call({'uid': uid, 'reason': 'Permanent Deletion & Ban'}).timeout(
                  const Duration(seconds: 5));
        } catch (e) {
          debugPrint("Cloud function error: $e");
        }

        // 3. الحذف من Firestore
        await FirebaseFirestore.instance.collection('users').doc(uid).delete();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("تم حذف المستخدم وحظر بريده بنجاح ✅"),
              backgroundColor: Colors.green));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("خطأ أثناء التنفيذ: $e"),
              backgroundColor: Colors.red));
        }
      }
    }
  }

  void _showBalanceEditor(
      BuildContext context, String uid, Map<String, dynamic> userData) {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    String selectedCurrency = 'stars'; // stars, gems, harvest_wallet
    String operationType = 'increase'; // increase, decrease

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (context, dialogSetState) {
        num currentVal = 0;
        String label = "";
        if (selectedCurrency == 'stars') {
          currentVal = (userData['stars'] ?? userData['coins'] ?? 0);
          label = "نجمة ⭐";
        } else if (selectedCurrency == 'gems') {
          currentVal = (userData['gems'] ?? 0);
          label = "جوهرة 💎";
        } else if (selectedCurrency == 'harvest_wallet') {
          currentVal = (userData['harvest_wallet'] ?? 0);
          label = "محفظة الحصاد";
        }

        return AlertDialog(
          backgroundColor: const Color(0xFF0F1B25),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: accentGold, width: 0.5)),
          title: Text('تعديل اقتصاد المستخدم: ${userData['name']}',
              style: TextStyle(
                  color: accentGold, fontSize: 15, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _choiceChip('نجوم', 'stars', selectedCurrency,
                        (val) => dialogSetState(() => selectedCurrency = val)),
                    _choiceChip('جواهر', 'gems', selectedCurrency,
                        (val) => dialogSetState(() => selectedCurrency = val)),
                    _choiceChip('حصاد', 'harvest_wallet', selectedCurrency,
                        (val) => dialogSetState(() => selectedCurrency = val)),
                  ],
                ),
                const Divider(color: Colors.white10, height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _opButton('شحن', 'increase', operationType, Colors.green,
                        () => dialogSetState(() => operationType = 'increase')),
                    const SizedBox(width: 15),
                    _opButton('خصم', 'decrease', operationType, Colors.red,
                        () => dialogSetState(() => operationType = 'decrease')),
                  ],
                ),
                const SizedBox(height: 20),
                Text('الرصيد الحالي: ${currentVal.toStringAsFixed(0)} $label',
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 15),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'المبلغ',
                    labelStyle: const TextStyle(color: Colors.white38),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.attach_money,
                        color: Colors.amber, size: 20),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: reasonController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'السبب (اختياري)',
                    labelStyle: const TextStyle(color: Colors.white38),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
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
                final amt = double.tryParse(amountController.text) ?? 0;
                if (amt <= 0) return;
                final finalAmt = operationType == 'increase' ? amt : -amt;

                final updates = <String, dynamic>{
                  selectedCurrency: FieldValue.increment(finalAmt),
                  'lastAdminAdjustment': {
                    'amount': finalAmt,
                    'currency': selectedCurrency,
                    'reason': reasonController.text,
                    'timestamp': FieldValue.serverTimestamp(),
                  }
                };
                // Sync stars/coins
                if (selectedCurrency == 'stars') {
                  updates['coins'] = FieldValue.increment(finalAmt);
                }

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .update(updates);

                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('تم تحديث الرصيد بنجاح ✅'),
                      backgroundColor: Colors.green));
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor:
                      operationType == 'increase' ? Colors.green : Colors.red),
              child: Text(
                  operationType == 'increase' ? 'تأكيد الشحن' : 'تأكيد الخصم',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      }),
    );
  }

  Widget _choiceChip(
      String label, String value, String current, Function(String) onSelect) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 10)),
      selected: current == value,
      onSelected: (s) => onSelect(value),
      selectedColor: accentGold.withValues(alpha: 0.3),
      labelStyle:
          TextStyle(color: current == value ? accentGold : Colors.white54),
    );
  }

  Widget _opButton(String label, String type, String current, Color color,
      VoidCallback onTap) {
    bool isSel = current == type;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSel ? color : Colors.white12),
        ),
        child: Text(label,
            style: TextStyle(
                color: isSel ? color : Colors.white38,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showUserActions(String uid, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final bool isBanned = data['isBanned'] ?? false;
        final bool isAdminUser =
            data['role'] == 'admin' || data['role'] == 'owner';

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (_, controller) => Container(
            decoration: const BoxDecoration(
              color: Color(0xFF161B22),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                    child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundImage: (data['profilePic'] ?? '').isNotEmpty
                          ? NetworkImage(data['profilePic'])
                          : null,
                      child: (data['profilePic'] ?? '').isEmpty
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['name'] ?? 'مستخدم',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18)),
                          Text(
                              "ID: ${data['royalId']} | ${data['email'] ?? 'بدون بريد'}",
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                _buildActionGroup("الإدارة المالية", [
                  _actionItem(Icons.account_balance_wallet,
                      "تعديل الرصيد والشحن", Colors.greenAccent, () {
                    Navigator.pop(ctx);
                    _showBalanceEditor(context, uid, data);
                  }),
                  _actionItem(
                      Icons.history, "سجل التحويلات", Colors.blueAccent, () {}),
                ]),
                _buildActionGroup("الحماية والتحكم", [
                  _actionItem(
                      isBanned ? Icons.lock_open : Icons.lock,
                      isBanned ? "فك الحظر" : "حظر الحساب",
                      isBanned ? Colors.green : Colors.orangeAccent, () {
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .update({'isBanned': !isBanned});
                    Navigator.pop(ctx);
                  }),
                  _actionItem(Icons.gavel, "تعيين كمستخدم عادي", Colors.grey,
                      () {
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .update({'role': 'user'});
                    Navigator.pop(ctx);
                  }, show: isAdminUser),
                  _actionItem(
                      Icons.admin_panel_settings, "ترقية لمسؤول", Colors.amber,
                      () {
                    FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .update({'role': 'admin'});
                    Navigator.pop(ctx);
                  }, show: !isAdminUser),
                ]),
                _buildActionGroup("منطقة الخطر", [
                  _actionItem(Icons.delete_forever, "حذف وحظر نهائي 🚫",
                      Colors.redAccent, () {
                    Navigator.pop(ctx);
                    _deleteUserAndBan(
                        uid, data['name'] ?? 'مستخدم', data['email']);
                  }),
                ]),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionGroup(String title, List<Widget> children) {
    List<Widget> visible = children.where((c) {
      if (c is _ActionItemWrapper) return c.show;
      return true;
    }).toList();

    if (visible.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 8, top: 15),
          child: Text(title,
              style: TextStyle(
                  color: accentGold,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
        ),
        Container(
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(15)),
          child: Column(children: visible),
        ),
      ],
    );
  }

  Widget _actionItem(
      IconData icon, String title, Color color, VoidCallback onTap,
      {bool show = true}) {
    return _ActionItemWrapper(
      show: show,
      child: ListTile(
        leading: Icon(icon, color: color, size: 22),
        title: Text(title,
            style: const TextStyle(color: Colors.white, fontSize: 14)),
        trailing: const Icon(Icons.arrow_forward_ios,
            color: Colors.white10, size: 12),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      appBar: AppBar(
        title: const Text('إدارة رعية رويال دور',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'ابحث (ID / اسم / بريد)...',
                hintStyle: const TextStyle(color: Colors.white24),
                prefixIcon: Icon(Icons.search, color: accentGold),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => _searchText = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                      child: CircularProgressIndicator(color: accentGold));
                }
                var docs = snapshot.data!.docs;
                if (_searchText.isNotEmpty) {
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return (data['name'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(_searchText) ||
                        (data['royalId'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(_searchText) ||
                        (data['email'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(_searchText) ||
                        doc.id.toLowerCase().contains(_searchText);
                  }).toList();
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final uid = docs[index].id;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.05))),
                      child: ListTile(
                        onTap: () => _showUserActions(uid, data),
                        leading: CircleAvatar(
                            radius: 24,
                            backgroundImage:
                                (data['profilePic'] ?? '').isNotEmpty
                                    ? NetworkImage(data['profilePic'])
                                    : null,
                            child: (data['profilePic'] ?? '').isEmpty
                                ? Icon(Icons.person, color: accentGold)
                                : null),
                        title: Text(data['name'] ?? 'مستخدم',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                "ID: ${data['royalId']} | ${data['email'] ?? 'بدون بريد'}",
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 10)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _miniStat(
                                    Icons.stars,
                                    "${data['stars'] ?? data['coins'] ?? 0}",
                                    Colors.amber),
                                const SizedBox(width: 8),
                                _miniStat(Icons.diamond, "${data['gems'] ?? 0}",
                                    Colors.blue),
                                const SizedBox(width: 8),
                                _miniStat(
                                    Icons.account_balance_wallet,
                                    "${data['harvest_wallet'] ?? 0}",
                                    Colors.green),
                              ],
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.more_vert,
                            color: Colors.white24, size: 18),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(IconData icon, String val, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 10),
        const SizedBox(width: 2),
        Text(val,
            style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: 9,
                fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _ActionItemWrapper extends StatelessWidget {
  final Widget child;
  final bool show;
  const _ActionItemWrapper({required this.child, required this.show});
  @override
  Widget build(BuildContext context) => show ? child : const SizedBox.shrink();
}
