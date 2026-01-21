import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminLevelsMgmtPage extends StatefulWidget {
  const AdminLevelsMgmtPage({Key? key}) : super(key: key);

  @override
  State<AdminLevelsMgmtPage> createState() => _AdminLevelsMgmtPageState();
}

class _AdminLevelsMgmtPageState extends State<AdminLevelsMgmtPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Color primaryDark = const Color(0xFF0A1F1C);
  final Color accentGold = const Color(0xFFC5A059);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: primaryDark,
        appBar: AppBar(
          backgroundColor: const Color(0xFF051211),
          title: Text('إدارة مراتب الرعية', style: TextStyle(color: accentGold, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _db.collection('users').orderBy('userLevel', descending: true).limit(50).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.amber));
            }
            final docs = snapshot.data?.docs ?? [];

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final uid = docs[index].id;
                return _buildUserLevelCard(uid, data);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserLevelCard(String uid, Map<String, dynamic> data) {
    int currentLevel = (data['userLevel'] ?? 1).toInt();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentGold.withOpacity(0.1)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: accentGold.withOpacity(0.1),
          backgroundImage: NetworkImage(data['profilePic'] ?? ''),
          child: (data['profilePic'] ?? '').isEmpty ? Icon(Icons.person, color: accentGold) : null,
        ),
        title: Text(data['name'] ?? 'مستخدم ملكي', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text('المستوى الحالي: ROYAL $currentLevel', style: TextStyle(color: accentGold.withOpacity(0.6), fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.keyboard_double_arrow_up_rounded, color: Colors.greenAccent),
              onPressed: () => _updateUserLevel(uid, currentLevel + 1),
              tooltip: 'ترفيع ملكي',
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_double_arrow_down_rounded, color: Colors.redAccent),
              onPressed: () => _updateUserLevel(uid, currentLevel > 1 ? currentLevel - 1 : 1),
              tooltip: 'تخفيض الرتبة',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateUserLevel(String uid, int newLevel) async {
    await _db.collection('users').doc(uid).update({'userLevel': newLevel});
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث الرتبة الملكية بنجاح ✅')));
  }
}
