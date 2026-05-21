import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/family_model.dart';

class AdminFamiliesPage extends StatefulWidget {
  const AdminFamiliesPage({super.key});

  @override
  State<AdminFamiliesPage> createState() => _AdminFamiliesPageState();
}

class _AdminFamiliesPageState extends State<AdminFamiliesPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text("إدارة العائلات الملكية 🏰",
            style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('families')
                .orderBy('totalExp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final families = snapshot.data!.docs;

              return ListView.builder(
                itemCount: families.length,
                itemBuilder: (context, index) {
                  final family = FamilyModel.fromFirestore(families[index]
                      as DocumentSnapshot<Map<String, dynamic>>);
                  return _familyAdminTile(family);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _familyAdminTile(FamilyModel family) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(family.logoUrl)),
        title: Text(family.name,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text("المستوى ${family.level} | ${family.memberCount} عضو",
            style: const TextStyle(color: Colors.white54, fontSize: 11)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                  family.isVerified
                      ? Icons.verified
                      : Icons.verified_user_outlined,
                  color: family.isVerified ? Colors.blue : Colors.white24),
              onPressed: () => _toggleVerify(family),
              tooltip: "توثيق العائلة",
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _deleteFamilyConfirm(family),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleVerify(FamilyModel family) async {
    await _db
        .collection('families')
        .doc(family.id)
        .update({'isVerified': !family.isVerified});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              family.isVerified ? "تم إلغاء التوثيق" : "تم توثيق العائلة ✅")));
    }
  }

  void _deleteFamilyConfirm(FamilyModel family) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A0A10),
        title: const Text("حذف عائلة", style: TextStyle(color: Colors.red)),
        content: Text(
            "هل أنت متأكد من حذف عائلة '${family.name}' نهائياً من قبل الإدارة؟"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () async {
              await _db.collection('families').doc(family.id).delete();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("حذف نهائي"),
          ),
        ],
      ),
    );
  }
}
