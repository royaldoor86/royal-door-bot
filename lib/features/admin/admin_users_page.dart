import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

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

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم نسخ $label بنجاح ✅'), backgroundColor: Colors.deepPurple));
  }

  void _showEditTitlesSheet(String uid, Map<String, dynamic> currentData) {
    final titleCtrl = TextEditingController(text: currentData['honoraryTitle'] ?? '');
    final nobleCtrl = TextEditingController(text: currentData['nobleLevel'] ?? 'N1');
    final charmCtrl = TextEditingController(text: (currentData['charm'] ?? 0).toString());
    final wealthCtrl = TextEditingController(text: (currentData['wealth'] ?? 0).toString());
    final contribCtrl = TextEditingController(text: (currentData['contribution'] ?? 0).toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text("تعديل ألقاب وإحصائيات: ${currentData['name']}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 25),
              _adminTextField(titleCtrl, "اللقب الشرفي (مثال: أسطورة الدعم)", Icons.workspace_premium),
              const SizedBox(height: 15),
              _adminTextField(nobleCtrl, "الرتبة النبيلة (N1, N2, VIP...)", Icons.stars),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(child: _adminTextField(charmCtrl, "القلوب", Icons.favorite, isNumber: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _adminTextField(wealthCtrl, "الماس", Icons.diamond, isNumber: true)),
                ],
              ),
              const SizedBox(height: 15),
              _adminTextField(contribCtrl, "نقاط الدعم/الدرع", Icons.shield, isNumber: true),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('users').doc(uid).update({
                    'honoraryTitle': titleCtrl.text.trim(),
                    'nobleLevel': nobleCtrl.text.trim(),
                    'charm': int.tryParse(charmCtrl.text) ?? 0,
                    'wealth': int.tryParse(wealthCtrl.text) ?? 0,
                    'contribution': int.tryParse(contribCtrl.text) ?? 0,
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث البيانات بنجاح 👑'), backgroundColor: Colors.green));
                },
                style: ElevatedButton.styleFrom(backgroundColor: accentGold, minimumSize: const Size(double.infinity, 55), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                child: const Text("تحديث البيانات الملكية", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _adminTextField(TextEditingController ctrl, String label, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54, fontSize: 12),
        prefixIcon: Icon(icon, color: accentGold, size: 20),
        filled: true, fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'ابحث عن ملك (الاسم، الايدي، UID)...',
                hintStyle: const TextStyle(color: Colors.white24),
                prefixIcon: Icon(Icons.search, color: accentGold),
                filled: true, fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => _searchText = v.toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                var docs = snapshot.data!.docs;
                if (_searchText.isNotEmpty) {
                  docs = docs.where((doc) {
                    final data = doc.data() as Map;
                    return (data['name'] ?? '').toString().toLowerCase().contains(_searchText) ||
                           (data['royalId'] ?? '').toString().toLowerCase().contains(_searchText) ||
                           doc.id.toLowerCase().contains(_searchText);
                  }).toList();
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final uid = docs[index].id;
                    final bool isBanned = data['isBanned'] ?? false;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05))),
                      child: ListTile(
                        leading: CircleAvatar(backgroundImage: (data['profilePic'] ?? '').isNotEmpty ? NetworkImage(data['profilePic']) : null, child: (data['profilePic'] ?? '').isEmpty ? Icon(Icons.person, color: accentGold) : null),
                        title: Text(data['name'] ?? 'مستخدم', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text("ID: ${data['royalId']}", style: TextStyle(color: accentGold, fontSize: 11)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: Icon(Icons.stars, color: accentGold, size: 22), onPressed: () => _showEditTitlesSheet(uid, data), tooltip: "تعديل الألقاب"),
                            IconButton(icon: Icon(isBanned ? Icons.lock_open : Icons.block, color: isBanned ? Colors.green : Colors.orange, size: 20), onPressed: () => FirebaseFirestore.instance.collection('users').doc(uid).update({'isBanned': !isBanned})),
                          ],
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
    );
  }
}
