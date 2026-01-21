import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';

class AdminRoomsPage extends StatefulWidget {
  const AdminRoomsPage({super.key});

  @override
  State<AdminRoomsPage> createState() => _AdminRoomsPageState();
}

class _AdminRoomsPageState extends State<AdminRoomsPage> {
  final _searchController = TextEditingController();
  String _searchText = "";
  bool _isSeeding = false;

  final Map<String, int> vipMicCounts = {
    "ROYALDOOR 👑": 100,
    "الياقوت 💎": 75,
    "اللؤلؤ 💎": 50,
    "المرجان 🛡️": 40,
    "الفيروز ⚔️": 30,
  };

  Future<void> _createVipRoomDialog() async {
    final nameCtrl = TextEditingController();
    final ownerIdCtrl = TextEditingController();
    String selectedRank = "الفيروز ⚔️";

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF1B0233),
          title: const Text("إنشاء غرفة VIP ملكية 👑",
              style: TextStyle(color: Colors.white, fontSize: 16)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: ownerIdCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: "UID المالك",
                      labelStyle: TextStyle(color: Colors.white54)),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: "اسم الغرفة",
                      labelStyle: TextStyle(color: Colors.white54)),
                ),
                const SizedBox(height: 20),
                const Text("اختر الرتبة الملكية (عدد المايكات):",
                    style: TextStyle(color: Colors.amber, fontSize: 12)),
                DropdownButton<String>(
                  value: selectedRank,
                  dropdownColor: const Color(0xFF1B0233),
                  isExpanded: true,
                  items: vipMicCounts.keys
                      .map((rank) => DropdownMenuItem(
                            value: rank,
                            child: Text("$rank (${vipMicCounts[rank]} مايك)",
                                style: const TextStyle(color: Colors.white)),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedRank = val);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("إلغاء",
                    style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              onPressed: () async {
                if (ownerIdCtrl.text.isEmpty || nameCtrl.text.isEmpty) return;
                int mics = vipMicCounts[selectedRank]!;

                try {
                  await FirebaseFirestore.instance.collection('rooms').add({
                    'name': nameCtrl.text.trim(),
                    'description': 'غرفة VIP ملكية - رتبة $selectedRank',
                    'ownerId': ownerIdCtrl.text.trim(),
                    'creatorId': ownerIdCtrl.text.trim(),
                    'membersCount': 1,
                    'likedBy': [],
                    'isAdminRoom': false,
                    'isVipRoom': true,
                    'isVerified': true,
                    'isPrivate': false,
                    'micsCount': mics,
                    'micLayoutPattern': mics >= 100 ? '10x10' : 'standard',
                    'vipRank': selectedRank,
                    'image': 'assets/rooms/room_party.jpg',
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                  if (mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text("تم إنشاء غرفة $selectedRank بنجاح ✅")));
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text("خطأ: $e"), backgroundColor: Colors.red));
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber, foregroundColor: Colors.black),
              child: const Text("تفعيل وإنشاء"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _seedTenRooms() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _isSeeding = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (int i = 1; i <= 10; i++) {
        final roomRef = FirebaseFirestore.instance.collection('rooms').doc();
        batch.set(roomRef, {
          'name': "غرفة رويال دور الملكية $i",
          'description': 'أهلاً بكم في عالم رويال دور الراقي',
          'ownerId': uid,
          'creatorId': uid,
          'membersCount': 1,
          'likedBy': [],
          'isAdminRoom': true,
          'isPrivate': false,
          'image': 'assets/rooms/room_$i.png',
          'micsCount': 10,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("تم إنشاء 10 غرف ملكية بنجاح ✅"),
            backgroundColor: Colors.green));
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("فشل الإنشاء: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  Future<void> _deleteRoom(String roomId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B0233),
        title: const Text("حذف الغرفة نهائياً",
            style: TextStyle(color: Colors.redAccent)),
        content: Text("هل أنت متأكد من حذف غرفة '$name'؟",
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("إلغاء")),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("حذف")),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance.collection('rooms').doc(roomId).delete();
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("تم حذف الغرفة")));
    }
  }

  Future<void> _setRoomPassword(String roomId) async {
    final passController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B0233),
        title: const Text("تعيين رقم سري للغرفة",
            style: TextStyle(color: Colors.white)),
        content: TextField(
            controller: passController,
            style: const TextStyle(color: Colors.white),
            decoration:
                const InputDecoration(hintText: "اتركه فارغاً لإلغاء القفل")),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
          ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('rooms')
                    .doc(roomId)
                    .update({
                  'password': passController.text.trim().isEmpty
                      ? null
                      : passController.text.trim(),
                  'isPrivate': passController.text.trim().isNotEmpty,
                });
                if (mounted) Navigator.pop(ctx);
              },
              child: const Text("حفظ")),
        ],
      ),
    );
  }

  Future<void> _manageMics(String roomId, int currentMics) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B0233),
        title:
            const Text("إدارة المايكات", style: TextStyle(color: Colors.white)),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
                icon: const Icon(Icons.remove_circle, color: Colors.red),
                onPressed: () {
                  if (currentMics > 1)
                    FirebaseFirestore.instance
                        .collection('rooms')
                        .doc(roomId)
                        .update({'micsCount': currentMics - 1});
                  Navigator.pop(ctx);
                }),
            Text("$currentMics مايك",
                style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.green),
                onPressed: () {
                  FirebaseFirestore.instance
                      .collection('rooms')
                      .doc(roomId)
                      .update({'micsCount': currentMics + 1});
                  Navigator.pop(ctx);
                }),
          ],
        ),
      ),
    );
  }

  Future<void> _manageVipRanksDialog() async {
    final nameCtrl = TextEditingController();
    final levelCtrl = TextEditingController();
    final micsCtrl = TextEditingController();
    final friendsCtrl = TextEditingController();
    bool gold = false;
    bool priority = false;

    await showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (c, setModal) => AlertDialog(
                  backgroundColor: const Color(0xFF1B0233),
                  title: const Text('إدارة رتب VIP',
                      style: TextStyle(color: Colors.amber)),
                  content: SingleChildScrollView(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    TextField(
                        controller: nameCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                            labelText: 'اسم الرتبة',
                            labelStyle: TextStyle(color: Colors.white54))),
                    TextField(
                        controller: levelCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                            labelText: 'النقطة (مثال: 75)',
                            labelStyle: TextStyle(color: Colors.white54)),
                        keyboardType: TextInputType.number),
                    TextField(
                        controller: micsCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                            labelText: 'عدد المايكات',
                            labelStyle: TextStyle(color: Colors.white54)),
                        keyboardType: TextInputType.number),
                    TextField(
                        controller: friendsCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                            labelText: 'سقف الأصدقاء',
                            labelStyle: TextStyle(color: Colors.white54)),
                        keyboardType: TextInputType.number),
                    CheckboxListTile(
                        value: gold,
                        onChanged: (v) => setModal(() => gold = v ?? false),
                        title: const Text('شارة ذهبية',
                            style: TextStyle(color: Colors.white))),
                    CheckboxListTile(
                        value: priority,
                        onChanged: (v) => setModal(() => priority = v ?? false),
                        title: const Text('أولوية الظهور',
                            style: TextStyle(color: Colors.white))),
                  ])),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('إلغاء')),
                    ElevatedButton(
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) return;
                          final lvl = int.tryParse(levelCtrl.text.trim()) ?? 0;
                          final mics = int.tryParse(micsCtrl.text.trim()) ?? 0;
                          final friends =
                              int.tryParse(friendsCtrl.text.trim()) ?? 0;
                          await FirebaseFirestore.instance
                              .collection('vip_ranks')
                              .doc(name)
                              .set({
                            'name': name,
                            'level': lvl,
                            'mics': mics,
                            'friends': friends,
                            'goldBadge': gold,
                            'priority': priority
                          });
                          if (mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('تم حفظ الرتبة')));
                          }
                        },
                        child: const Text('حفظ'))
                  ],
                )));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "بحث عن غرفة...",
                    prefixIcon: const Icon(Icons.search, color: Colors.amber),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none),
                  ),
                  onChanged: (v) =>
                      setState(() => _searchText = v.toLowerCase()),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: _createVipRoomDialog,
                icon: const Icon(Icons.stars, color: Colors.amber, size: 28),
                tooltip: "إنشاء غرفة VIP ملكية",
              ),
              IconButton(
                  onPressed: _manageVipRanksDialog,
                  icon: const Icon(Icons.rule_folder, color: Colors.amber),
                  tooltip: 'إدارة رتب VIP'),
              _isSeeding
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.amber))
                  : IconButton(
                      onPressed: _seedTenRooms,
                      icon: const Icon(Icons.auto_awesome, color: Colors.amber),
                      tooltip: "إنشاء 10 غرف تلقائية"),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('rooms').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              var docs = snapshot.data!.docs;
              if (_searchText.isNotEmpty) {
                docs = docs
                    .where((doc) =>
                        (doc['name'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(_searchText) ||
                        doc.id.toLowerCase().contains(_searchText))
                    .toList();
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final id = docs[index].id;
                  final bool isClosed = data['isClosed'] ?? false;
                  final int mics = data['micsCount'] ?? 8;
                  final String? rank = data['vipRank'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: rank != null
                          ? Border.all(
                              color: Colors.amber.withOpacity(0.3), width: 1)
                          : null,
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(rank != null ? Icons.stars : Icons.mic,
                              color: Colors.amber),
                          title: Text(data['name'] ?? "غرفة",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              rank != null
                                  ? "رتبة: $rank | مايكات: $mics"
                                  : "ID: $id | المايكات: $mics",
                              style: const TextStyle(
                                  color: Colors.white54, fontSize: 11)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                  icon: Icon(
                                      isClosed ? Icons.lock : Icons.lock_open,
                                      color:
                                          isClosed ? Colors.red : Colors.green),
                                  onPressed: () => FirebaseFirestore.instance
                                      .collection('rooms')
                                      .doc(id)
                                      .update({'isClosed': !isClosed})),
                              IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.redAccent),
                                  onPressed: () =>
                                      _deleteRoom(id, data['name'])),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              TextButton.icon(
                                  icon: const Icon(Icons.password, size: 16),
                                  label: const Text("رقم سري",
                                      style: TextStyle(fontSize: 12)),
                                  onPressed: () => _setRoomPassword(id)),
                              TextButton.icon(
                                  icon: const Icon(Icons.add_task, size: 16),
                                  label: const Text("المايكات",
                                      style: TextStyle(fontSize: 12)),
                                  onPressed: () => _manageMics(id, mics)),
                            ],
                          ),
                        )
                      ],
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
