import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_model.dart';

class ManageAgentsPage extends StatefulWidget {
  const ManageAgentsPage({super.key});

  @override
  State<ManageAgentsPage> createState() => _ManageAgentsPageState();
}

class _ManageAgentsPageState extends State<ManageAgentsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Color primaryDark = const Color(0xFF0A1F1C);
  final Color accentGold = const Color(0xFFC5A059);

  void _showAddAgentDialog([UserModel? agent]) {
    final nameController =
        TextEditingController(text: agent?.agentData?['agencyName'] ?? '');
    final idController = TextEditingController(text: agent?.royalId ?? '');
    File? selectedLogo;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: primaryDark,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
            border:
                Border.all(color: accentGold.withValues(alpha: 0.3), width: 1),
          ),
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                        color: accentGold.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 20),
                Text(
                  agent == null
                      ? 'إصدار مرسوم وكالة ملكية'
                      : 'تحديث بيانات الوكالة',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: accentGold),
                ),
                const SizedBox(height: 30),
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final img =
                        await picker.pickImage(source: ImageSource.gallery);
                    if (img != null) {
                      setModalState(() => selectedLogo = File(img.path));
                    }
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: accentGold, width: 2)),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white10,
                          backgroundImage: selectedLogo != null
                              ? FileImage(selectedLogo!)
                              : null,
                          child: selectedLogo == null
                              ? Icon(Icons.add_a_photo_rounded,
                                  size: 35, color: accentGold)
                              : null,
                        ),
                      ),
                      Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                  color: accentGold, shape: BoxShape.circle),
                              child: const Icon(Icons.edit,
                                  size: 15, color: Colors.black))),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                _buildRoyalTextField(
                    idController, 'الآيدي الملكي للمستخدم', Icons.badge_rounded,
                    enabled: agent == null),
                const SizedBox(height: 15),
                _buildRoyalTextField(nameController, 'اسم الوكالة التجارية',
                    Icons.stars_rounded),
                const SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () async {
                    if (idController.text.isNotEmpty &&
                        nameController.text.isNotEmpty) {
                      final userSnap = await _db
                          .collection('users')
                          .where('royalId', isEqualTo: idController.text.trim())
                          .limit(1)
                          .get();

                      if (userSnap.docs.isEmpty) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'عذراً، هذا الآيدي الملكي غير موجود')));
                        }
                        return;
                      }

                      final userDoc = userSnap.docs.first;
                      final int starsAmount = agent?.agencyStars ?? 0;
                      await userDoc.reference.update({
                        'isAgent': true,
                        'agencyGems': agent?.agencyGems ?? 0,
                        'agencyStars': starsAmount,
                        'agencyCoins': starsAmount, // Sync for legacy
                        'agentData': {
                          'agencyName': nameController.text.trim(),
                          'totalCharged':
                              agent?.agentData?['totalCharged'] ?? 0,
                          'createdAt': agent?.agentData?['createdAt'] ??
                              FieldValue.serverTimestamp(),
                        }
                      });
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('تم اعتماد الوكيل بنجاح ✅'),
                                backgroundColor: Colors.green));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentGold,
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                  child: const Text('اعتماد الوكيل الآن',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoyalTextField(
      TextEditingController controller, String label, IconData icon,
      {bool enabled = true}) {
    return TextField(
      controller: controller,
      enabled: enabled,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: accentGold.withValues(alpha: 0.5), fontSize: 13),
        prefixIcon: Icon(icon, color: accentGold),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: accentGold.withValues(alpha: 0.2))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(color: accentGold)),
      ),
    );
  }

  void _showChargeDialog(UserModel agent, String type) {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: primaryDark,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
            side: BorderSide(color: accentGold.withValues(alpha: 0.3))),
        title: Text('شحن رصيد الوكالة (رصيد البيع)',
            style: TextStyle(
                color: accentGold, fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'سيتم إضافة الرصيد إلى محفظة الوكالة الخاصة بـ: ${agent.agentData?['agencyName']}',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 20),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'أدخل الكمية...',
                hintStyle: const TextStyle(color: Colors.white24),
                prefixIcon: Icon(
                    type == 'gems' ? Icons.diamond : Icons.stars_rounded,
                    color: accentGold),
                filled: true,
                fillColor: Colors.white10,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('إلغاء', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () async {
              int amount = int.tryParse(amountController.text) ?? 0;
              if (amount > 0) {
                final Map<String, dynamic> updates = {};
                if (type == 'gems') {
                  updates['agencyGems'] = FieldValue.increment(amount);
                } else {
                  updates['agencyStars'] = FieldValue.increment(amount);
                  updates['agencyCoins'] =
                      FieldValue.increment(amount); // Keep in sync
                }
                await _db.collection('users').doc(agent.uid).update(updates);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('تمت إضافة الرصيد لمحفظة الوكالة بنجاح ✅'),
                      backgroundColor: Colors.green));
                }
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: accentGold, foregroundColor: Colors.black),
            child: const Text('شحن الوكالة'),
          ),
        ],
      ),
    );
  }

  void _removeAgent(String uid, String agencyName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A0000),
        title: const Text('إلغاء اعتماد وكالة',
            style: TextStyle(color: Colors.redAccent)),
        content: Text('هل أنت متأكد من سحب صلاحيات الوكالة من ($agencyName)؟'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('تراجع')),
          ElevatedButton(
            onPressed: () async {
              await _db.collection('users').doc(uid).update({
                'isAgent': false,
                'agentData': FieldValue.delete(),
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('إلغاء الآن'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: primaryDark,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('إدارة الوكلاء المعتمدين',
              style: TextStyle(color: accentGold, fontWeight: FontWeight.bold)),
          centerTitle: true,
          actions: [
            IconButton(
                onPressed: () => _showAddAgentDialog(),
                icon: Icon(Icons.person_add_alt_1_rounded, color: accentGold)),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _db
              .collection('users')
              .where('isAgent', isEqualTo: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                  child: Text('لا يوجد وكلاء مسجلون في الديوان',
                      style: TextStyle(color: Colors.white24)));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final agentDoc = snapshot.data!.docs[index];
                final agent = UserModel.fromMap(
                    agentDoc.data() as Map<String, dynamic>, agentDoc.id);

                return Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(25),
                    border:
                        Border.all(color: accentGold.withValues(alpha: 0.1)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(15),
                    leading: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: accentGold, width: 1.5)),
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.black,
                        backgroundImage: agent.profilePic.isNotEmpty
                            ? NetworkImage(agent.profilePic)
                            : null,
                        child: agent.profilePic.isEmpty
                            ? Icon(Icons.business_center_rounded,
                                color: accentGold)
                            : null,
                      ),
                    ),
                    title: Text(agent.agentData?['agencyName'] ?? 'وكالة ملكية',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ID الملكي: ${agent.royalId}',
                            style: TextStyle(
                                color: accentGold.withValues(alpha: 0.7),
                                fontSize: 11)),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            _balanceChip('${agent.agencyGems}', Icons.diamond,
                                Colors.blue),
                            const SizedBox(width: 10),
                            _balanceChip('${agent.agencyStars}',
                                Icons.stars_rounded, Colors.amber),
                          ],
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        PopupMenuButton<String>(
                          icon:
                              Icon(Icons.more_vert_rounded, color: accentGold),
                          color: primaryDark,
                          onSelected: (val) {
                            if (val == 'gems') _showChargeDialog(agent, 'gems');
                            if (val == 'stars') {
                              _showChargeDialog(agent, 'stars');
                            }
                            if (val == 'edit') _showAddAgentDialog(agent);
                            if (val == 'delete') {
                              _removeAgent(agent.uid,
                                  agent.agentData?['agencyName'] ?? '');
                            }
                          },
                          itemBuilder: (ctx) => [
                            _popItem('gems', 'شحن جواهر الوكالة', Icons.diamond,
                                Colors.blue),
                            _popItem('stars', 'شحن نجوم ⭐ الوكالة',
                                Icons.stars_rounded, Colors.amber),
                            _popItem('edit', 'تعديل البيانات', Icons.edit,
                                Colors.grey),
                            _popItem('delete', 'إلغاء الوكالة',
                                Icons.delete_forever, Colors.red),
                          ],
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
    );
  }

  Widget _balanceChip(String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(val,
            style: TextStyle(
                color: color, fontSize: 10, fontWeight: FontWeight.bold))
      ]),
    );
  }

  PopupMenuItem<String> _popItem(
      String val, String text, IconData icon, Color color) {
    return PopupMenuItem(
        value: val,
        child: Row(children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12))
        ]));
  }
}
