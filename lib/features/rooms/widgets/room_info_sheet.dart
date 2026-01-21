import 'package:flutter/material.dart';

class RoomInfoSheet extends StatelessWidget {
  final String roomId;
  const RoomInfoSheet({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: 1,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFF0F1B25),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: TabBarView(
                children: [
                  const Center(child: Text("اللحظات ستظهر هنا", style: TextStyle(color: Colors.white))),
                  _buildMembersTab(),
                  _buildInfoTab(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0A121A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white38),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
              ],
            ),
          ),
          const TabBar(
            indicatorColor: Colors.blue,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white38,
            tabs: [Tab(text: "اللحظات"), Tab(text: "الأعضاء"), Tab(text: "المعلومات")],
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTab() {
    final List<Map<String, dynamic>> members = [
      {'name': 'iraqi', 'level': 34, 'gender': 'male', 'role': 'star'},
      {'name': 'العنزي', 'level': 24, 'gender': 'male', 'role': 'none'},
      {'name': 'zoz ☾', 'level': 22, 'gender': 'female', 'role': 'shield'},
      {'name': 'العنزي', 'level': 34, 'gender': 'male', 'role': 'none'},
      {'name': 'شموخ ☾', 'level': 19, 'gender': 'female', 'role': 'shield'},
      {'name': 'أبو ماريا', 'level': 26, 'gender': 'male', 'role': 'none'},
      {'name': 'ZEZO', 'level': 27, 'gender': 'female', 'role': 'none'},
      {'name': 'روكاوي', 'level': 30, 'gender': 'male', 'role': 'none'},
      {'name': 'براءة أنثى', 'level': 34, 'gender': 'female', 'role': 'none'},
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.person_add_alt_1, color: Colors.blueAccent, size: 24),
              Row(
                children: const [
                  Icon(Icons.help_outline, color: Colors.white38, size: 16),
                  SizedBox(width: 5),
                  Text("الأعضاء: 9/1000", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        _buildSearchBar(),
        const SizedBox(height: 15),
        Expanded(
          child: ListView.separated(
            itemCount: members.length,
            separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 1),
            itemBuilder: (context, index) {
              final m = members[index];
              return ListTile(
                leading: const Icon(Icons.arrow_left, color: Colors.blue, size: 18),
                trailing: const CircleAvatar(radius: 20, backgroundColor: Colors.grey),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (m['role'] == 'star') const Icon(Icons.stars, color: Colors.purpleAccent, size: 16),
                    if (m['role'] == 'shield') const Icon(Icons.verified_user, color: Colors.tealAccent, size: 16),
                    const SizedBox(width: 5),
                    _buildLevelBadge(m['gender'], m['level']),
                    const SizedBox(width: 8),
                    Text(m['name'], style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildRoomInfoCard(),
          const SizedBox(height: 12),
          _buildInfoRow("مستوى الغرفة", _buildLevelProgress()),
          const SizedBox(height: 12),
          _buildInfoRow("إشعار الغرفة", const Text("🥰🥰🥰", style: TextStyle(color: Colors.white))),
          const SizedBox(height: 12),
          _buildClubSection(),
        ],
      ),
    );
  }

  // --- Widgets مساعدة ---
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 40,
        decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(20)),
        child: const TextField(
          textAlign: TextAlign.right,
          decoration: InputDecoration(
            hintText: "ابحث عن معرف",
            hintStyle: TextStyle(color: Colors.white38, fontSize: 12),
            prefixIcon: Icon(Icons.search, color: Colors.white38, size: 20),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildLevelBadge(String gender, int level) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(color: Colors.blueGrey.withOpacity(0.3), borderRadius: BorderRadius.circular(4)),
      child: Row(
        children: [
          Icon(gender == 'male' ? Icons.male : Icons.female, color: Colors.blue, size: 10),
          const SizedBox(width: 2),
          Text("$level", style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRoomInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1B2B38), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.public, color: Colors.greenAccent, size: 20),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("معرف: $roomId", style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(12))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelProgress() {
    return Expanded(
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const LinearProgressIndicator(value: 0.1, minHeight: 18, backgroundColor: Colors.black38, color: Color(0xFF1B2B38)),
          ),
          const Text("25417/240900", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, Widget content) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFF1B2B38).withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)), const SizedBox(height: 8), content]),
    );
  }

  Widget _buildClubSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Text("نادي الأعضاء", style: TextStyle(color: Colors.white38, fontSize: 12)),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildClubBox("الأعضاء", "9"),
            const SizedBox(width: 12),
            _buildClubBox("اسم النادي", "iraqi"),
          ],
        ),
      ],
    );
  }

  Widget _buildClubBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: const Color(0xFF1B2B38), borderRadius: BorderRadius.circular(12)),
        child: Column(children: [Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)), const SizedBox(height: 8), Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))]),
      ),
    );
  }
}
