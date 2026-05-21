import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminFamilyRequestsPage extends StatefulWidget {
  const AdminFamilyRequestsPage({super.key});

  @override
  State<AdminFamilyRequestsPage> createState() =>
      _AdminFamilyRequestsPageState();
}

class _AdminFamilyRequestsPageState extends State<AdminFamilyRequestsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Color primaryDark = const Color(0xFF0A1F1C);
  final Color accentGold = const Color(0xFFC5A059);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: primaryDark,
        appBar: AppBar(
          backgroundColor: const Color(0xFF051211),
          title: Text('إدارة شؤون العائلات',
              style: TextStyle(color: accentGold, fontWeight: FontWeight.bold)),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: accentGold,
            labelColor: accentGold,
            unselectedLabelColor: Colors.white38,
            tabs: const [
              Tab(text: 'طلبات التأسيس'),
              Tab(text: 'مهام العائلة الملكية'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildRequestsTab(),
            _buildFamilyTasksTab(),
          ],
        ),
      ),
    );
  }

  // --- التبويب الأول: طلبات التأسيس ---
  Widget _buildRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('family_requests')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Center(
              child: Text('لا توجد طلبات جديدة حالياً',
                  style: TextStyle(color: Colors.white24)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildRequestCard(docs[index].id, data);
          },
        );
      },
    );
  }

  Widget _buildRequestCard(String docId, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: accentGold.withValues(alpha: 0.1))),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              radius: 30,
              backgroundImage: (data['logoUrl'] != null &&
                      data['logoUrl'].toString().isNotEmpty)
                  ? NetworkImage(data['logoUrl'])
                  : null,
              child: (data['logoUrl'] ?? '').isEmpty
                  ? const Icon(Icons.shield, color: Colors.white24)
                  : null,
            ),
            title: Text(data['name'] ?? '',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text(data['slogan'] ?? '',
                style: TextStyle(color: accentGold.withValues(alpha: 0.5))),
          ),
          const Divider(color: Colors.white10),
          Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(data['description'] ?? '',
                  style: const TextStyle(color: Colors.white70, fontSize: 13))),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: ElevatedButton(
                      onPressed: () => _approveRequest(docId, data),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      child: const Text('موافقة وتأسيس'))),
              const SizedBox(width: 12),
              Expanded(
                  child: ElevatedButton(
                      onPressed: () => _rejectRequest(docId),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent),
                      child: const Text('رفض الطلب'))),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _approveRequest(String docId, Map<String, dynamic> data) async {
    try {
      await _db.runTransaction((tx) async {
        final familyRef = _db.collection('families').doc();
        final requestRef = _db.collection('family_requests').doc(docId);
        final userRef = _db.collection('users').doc(data['creatorId']);
        tx.set(familyRef, {
          'name': data['name'],
          'logoUrl': data['logoUrl'],
          'slogan': data['slogan'],
          'description': data['description'],
          'creatorId': data['creatorId'],
          'roomId': data['roomId'], // حفظ معرف الغرفة المختارة
          'level': 1,
          'memberCount': 1,
          'totalPoints': 0,
          'isVerified': true,
          'createdAt': FieldValue.serverTimestamp()
        });
        tx.update(
            userRef, {'familyId': familyRef.id, 'familyRole': 'رئيس العائلة'});
        tx.update(requestRef, {'status': 'approved'});
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('تمت الموافقة وتأسيس العائلة بنجاح! 🏰')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  Future<void> _rejectRequest(String docId) async {
    await _db
        .collection('family_requests')
        .doc(docId)
        .update({'status': 'rejected'});
  }

  // --- التبويب الثاني: إدارة مهام العائلة الملكية ---
  Widget _buildFamilyTasksTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () => _showAddTaskDialog(),
            icon: const Icon(Icons.add_task, color: Colors.black),
            label: const Text('إضافة مهمة عائلية ملكية',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
                backgroundColor: accentGold,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15))),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('family_tasks_config')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(
                    child: Text('لا توجد مهام عائلية حالياً',
                        style: TextStyle(color: Colors.white24)));
              }
              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return _buildTaskCard(docs[index].id, data);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(String docId, Map<String, dynamic> data) {
    bool isLimited = data['isLimited'] ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accentGold.withValues(alpha: 0.1))),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: accentGold.withValues(alpha: 0.1),
                shape: BoxShape.circle),
            child: Icon(isLimited ? Icons.timer : Icons.replay,
                color: accentGold, size: 20)),
        title: Text(data['title'] ?? '',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(data['description'] ?? '',
                style: const TextStyle(color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if ((data['gems'] ?? 0) > 0)
                  _rewardChip('${data['gems']} 💎', Colors.cyanAccent),
                if ((data['stars'] ?? data['coins'] ?? 0) > 0)
                  _rewardChip(
                      '${data['stars'] ?? data['coins']} ⭐', Colors.amber),
                if ((data['xp'] ?? 0) > 0)
                  _rewardChip('${data['xp']} XP', Colors.purpleAccent),
                if (isLimited)
                  _rewardChip(
                      'مؤقتة: ${data['durationHours']} ساعة', Colors.redAccent),
                if (!isLimited) _rewardChip('يومية متجددة', Colors.greenAccent),
              ],
            ),
          ],
        ),
        trailing: IconButton(
            icon: const Icon(Icons.delete_outline,
                color: Colors.redAccent, size: 20),
            onPressed: () =>
                _db.collection('family_tasks_config').doc(docId).delete()),
      ),
    );
  }

  Widget _rewardChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 9, fontWeight: FontWeight.bold)),
    );
  }

  void _showAddTaskDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final gemsCtrl = TextEditingController(text: '0');
    final coinsCtrl = TextEditingController(text: '0');
    final xpCtrl = TextEditingController(text: '0');
    final hoursCtrl = TextEditingController(text: '24');
    bool isLimited = false;
    String selectedIcon = 'task';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
                color: primaryDark,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(40)),
                border: Border.all(color: accentGold.withValues(alpha: 0.2))),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                      child: Container(
                          width: 50,
                          height: 5,
                          decoration: BoxDecoration(
                              color: accentGold.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(10)))),
                  const SizedBox(height: 20),
                  Text('تخصيص مهمة ملكية جديدة',
                      style: TextStyle(
                          color: accentGold,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 25),
                  _buildLabel('عنوان المهمة'),
                  _buildRoyalInput(
                      titleCtrl, 'مثال: جمع 1000 نقطة', Icons.edit),
                  const SizedBox(height: 15),
                  _buildLabel('وصف المهمة'),
                  _buildRoyalInput(
                      descCtrl, 'اشرح متطلبات الإنجاز...', Icons.description,
                      maxLines: 2),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text('مهمة مؤقتة (تنتهي بعد مدة)',
                          style: TextStyle(color: Colors.white, fontSize: 13)),
                      const Spacer(),
                      Switch(
                        value: isLimited,
                        onChanged: (v) => setModalState(() => isLimited = v),
                        activeThumbColor: accentGold,
                      ),
                    ],
                  ),
                  if (isLimited) ...[
                    _buildLabel('مدة المهمة بالساعات'),
                    _buildRoyalInput(hoursCtrl, '24', Icons.hourglass_bottom,
                        isNum: true),
                    const SizedBox(height: 15),
                  ],
                  const SizedBox(height: 15),
                  _buildLabel('أيقونة المهمة'),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['mic', 'gift', 'chat', 'room', 'task']
                          .map((icon) => GestureDetector(
                                onTap: () =>
                                    setModalState(() => selectedIcon = icon),
                                child: Container(
                                  margin: const EdgeInsets.only(left: 10),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: selectedIcon == icon
                                        ? accentGold.withValues(alpha: 0.2)
                                        : Colors.white.withValues(alpha: 0.05),
                                    border: Border.all(
                                        color: selectedIcon == icon
                                            ? accentGold
                                            : Colors.transparent),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(_getIconData(icon),
                                      color: selectedIcon == icon
                                          ? accentGold
                                          : Colors.white38),
                                ),
                              ))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 25),
                  Text('تحديد المكافآت:',
                      style: TextStyle(
                          color: accentGold.withValues(alpha: 0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            _buildLabel('الجواهر 💎'),
                            _buildRoyalInput(gemsCtrl, '0', Icons.diamond,
                                isNum: true)
                          ])),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            _buildLabel('النجوم ⭐'),
                            _buildRoyalInput(
                                coinsCtrl, '0', Icons.stars_rounded,
                                isNum: true)
                          ])),
                    ],
                  ),
                  const SizedBox(height: 15),
                  _buildLabel('الخبرة XP'),
                  _buildRoyalInput(xpCtrl, '0', Icons.bolt, isNum: true),
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: () async {
                      if (titleCtrl.text.isNotEmpty) {
                        int hours = int.tryParse(hoursCtrl.text) ?? 24;
                        int starsAmount = int.tryParse(coinsCtrl.text) ?? 0;
                        await _db.collection('family_tasks_config').add({
                          'title': titleCtrl.text.trim(),
                          'description': descCtrl.text.trim(),
                          'gems': int.tryParse(gemsCtrl.text) ?? 0,
                          'stars': starsAmount,
                          'coins': starsAmount, // Sync for legacy
                          'xp': int.tryParse(xpCtrl.text) ?? 0,
                          'isLimited': isLimited,
                          'durationHours': isLimited ? hours : 0,
                          'icon': selectedIcon,
                          'type': selectedIcon, // Use icon as type for now
                          'createdAt': FieldValue.serverTimestamp(),
                          'expiryDate': isLimited
                              ? Timestamp.fromDate(
                                  DateTime.now().add(Duration(hours: hours)))
                              : null,
                        });
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: accentGold,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15))),
                    child: const Text('اعتماد ونشر المهمة فوراً',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'mic':
        return Icons.mic;
      case 'gift':
        return Icons.card_giftcard;
      case 'chat':
        return Icons.chat_bubble_outline;
      case 'room':
        return Icons.meeting_room;
      default:
        return Icons.task_alt;
    }
  }

  Widget _buildLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 5),
      child: Text(text,
          style: const TextStyle(color: Colors.white70, fontSize: 12)));

  Widget _buildRoyalInput(
      TextEditingController ctrl, String hint, IconData icon,
      {bool isNum = false, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
        prefixIcon: Icon(icon, color: accentGold, size: 18),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none),
      ),
    );
  }
}
