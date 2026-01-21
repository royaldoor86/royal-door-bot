import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../admin/user_profile_page.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final TextEditingController searchController = TextEditingController();
  String _searchText = "";

  Future<void> _deleteUser(String uid, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B0233),
        title: const Text("حذف المستخدم نهائياً",
            style: TextStyle(color: Colors.redAccent)),
        content: Text(
            "هل أنت متأكد من حذف $name؟ لا يمكن التراجع عن هذا الإجراء وسيتم مسح كافة بياناته.",
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("إلغاء")),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("حذف نهائي")),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFunctions.instance
            .httpsCallable('adminDeleteUser')
            .call({'targetUid': uid, 'hard': true});
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("تم حذف المستخدم بنجاح"),
              backgroundColor: Colors.green));
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("خطأ: $e"), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _addRoomToUser(String uid, String name) async {
    final nameController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B0233),
        title: Text("إضافة غرفة لـ $name",
            style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "اسم الغرفة...",
            hintStyle: TextStyle(color: Colors.white24),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("إلغاء")),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("إنشاء")),
        ],
      ),
    );

    if (confirm == true && nameController.text.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('rooms').add({
          'name': nameController.text.trim(),
          'ownerId': uid,
          'creatorId': uid,
          'membersCount': 0,
          'isClosed': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("تم إنشاء الغرفة للمستخدم"),
              backgroundColor: Colors.green));
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("خطأ: $e"), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'ابحث عن مستخدم (الاسم، UID، الإيميل)...',
              hintStyle: const TextStyle(color: Colors.white24),
              prefixIcon: const Icon(Icons.search, color: Colors.amber),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none),
            ),
            onChanged: (v) => setState(() => _searchText = v.toLowerCase()),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(
                    child: CircularProgressIndicator(color: Colors.amber));

              var docs = snapshot.data!.docs;
              if (_searchText.isNotEmpty) {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name =
                      (data['displayName'] ?? '').toString().toLowerCase();
                  final email = (data['email'] ?? '').toString().toLowerCase();
                  final shortId =
                      (data['shortId'] ?? '').toString().toLowerCase();
                  return name.contains(_searchText) ||
                      email.contains(_searchText) ||
                      doc.id.contains(_searchText) ||
                      shortId.contains(_searchText);
                }).toList();
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final uid = docs[index].id;
                  final name = data['displayName'] ?? 'مستخدم';
                  final bool isBanned = data['isBanned'] ?? false;
                  final String shortId =
                      (data['shortId'] ?? '---').toString().toUpperCase();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      leading: CircleAvatar(
                          backgroundImage: data['photoUrl'] != null
                              ? NetworkImage(data['photoUrl'])
                              : null,
                          child: data['photoUrl'] == null
                              ? const Icon(Icons.person)
                              : null),
                      title: Text(name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text("ID الصغير: $shortId",
                              style: const TextStyle(
                                  color: Colors.amberAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                          Text("ID الكبير: $uid",
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 9)),
                          const SizedBox(height: 2),
                          Text(isBanned ? "الحالة: محظور 🚫" : "الحالة: نشط ✅",
                              style: TextStyle(
                                  color: isBanned
                                      ? Colors.redAccent
                                      : Colors.greenAccent,
                                  fontSize: 11)),
                        ],
                      ),
                      isThreeLine: true,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: "إضافة غرفة",
                            icon: const Icon(Icons.add_home_work,
                                color: Colors.amberAccent, size: 20),
                            onPressed: () => _addRoomToUser(uid, name),
                          ),
                          IconButton(
                            icon: Icon(isBanned ? Icons.lock_open : Icons.block,
                                color: isBanned
                                    ? Colors.greenAccent
                                    : Colors.orangeAccent,
                                size: 20),
                            onPressed: () => FirebaseFirestore.instance
                                .collection('users')
                                .doc(uid)
                                .update({'isBanned': !isBanned}),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_forever,
                                color: Colors.redAccent, size: 20),
                            onPressed: () => _deleteUser(uid, name),
                          ),
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
    );
  }
}
