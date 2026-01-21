import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'rooms/widgets/room_info_sheet.dart';
import 'rooms/widgets/gift_shop_sheet.dart';
import 'rooms/widgets/mic_modes_sheet.dart';

class VoiceRoomDetailsPage extends StatefulWidget {
  final String roomId;
  final String roomName;
  final String? roomImage; 

  const VoiceRoomDetailsPage({
    super.key,
    required this.roomId,
    required this.roomName,
    this.roomImage, 
  });

  @override
  State<VoiceRoomDetailsPage> createState() => _VoiceRoomDetailsPageState();
}

class _VoiceRoomDetailsPageState extends State<VoiceRoomDetailsPage> with TickerProviderStateMixin {
  bool _isMuted = false;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // إظهار لوحة صدارة الساحة الملكية
  void _showArenaLeaderboard() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ArenaLeaderboardSheet(roomId: widget.roomId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                _buildMicGrid(),
                const Spacer(),
                _buildFloatingSideButtons(),
                _buildRoomNotice(),
                _buildBottomActions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: (widget.roomImage != null && widget.roomImage!.isNotEmpty)
              ? NetworkImage(widget.roomImage!)
              : const NetworkImage('https://img.freepik.com/free-vector/night-mosque-ramadan-kareem-background_1017-31016.jpg'),
          fit: BoxFit.cover,
          opacity: 0.5,
        ),
        color: const Color(0xFF1A0A05),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(icon: const Icon(Icons.power_settings_new, color: Colors.white), onPressed: _showExitSheet),
              IconButton(icon: const Icon(Icons.more_horiz, color: Colors.white), onPressed: _showSettingsSheet),
            ],
          ),
          GestureDetector(
            onTap: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => RoomInfoSheet(roomId: widget.roomId),
            ),
            child: _buildRoomProfileWidget(),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomProfileWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          const Text("0 :الإعجاب", style: TextStyle(color: Colors.white70, fontSize: 10)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(widget.roomName, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              Text("ID:${widget.roomId}", style: const TextStyle(color: Colors.white60, fontSize: 8)),
            ],
          ),
          const SizedBox(width: 8),
          CircleAvatar(radius: 15, backgroundColor: Colors.grey[800], backgroundImage: (widget.roomImage != null) ? NetworkImage(widget.roomImage!) : null),
        ],
      ),
    );
  }

  Widget _buildMicGrid() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        children: [
          _buildMicRow([5, 4, 3, 2, 1]),
          const SizedBox(height: 20),
          _buildMicRow([10, 9, 8, 7, 6]),
        ],
      ),
    );
  }

  Widget _buildMicRow(List<int> indices) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: indices.map((idx) => _buildMicSeat(idx)).toList(),
    );
  }

  Widget _buildMicSeat(int index) {
    return Column(
      children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.1), border: Border.all(color: Colors.white24)),
          child: const Icon(Icons.mic, color: Colors.white38, size: 24),
        ),
        const SizedBox(height: 4),
        Text("$index", style: const TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }

  Widget _buildFloatingSideButtons() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: Column(
          children: [
            // أيقونة الساحة الملكية للمسابقات
            _buildSideIcon(Icons.emoji_events, "الساحة", color: Colors.amber, onTap: _showArenaLeaderboard),
            _buildSideIcon(Icons.auto_awesome, "لاف"),
            _buildSideIcon(Icons.card_giftcard, "عروض"),
            _buildSideIcon(Icons.chat_bubble, "الرسائل", badge: "5"),
          ],
        ),
      ),
    );
  }

  Widget _buildSideIcon(IconData icon, String label, {String? badge, Color color = Colors.white70, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: color, size: 28),
                if (badge != null)
                  Positioned(top: -5, left: -5, child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 8)))),
              ],
            ),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 8)),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomNotice() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: const [
          Text("نظام: مرحباً بك في رويال دور، يرجى الالتزام بالقوانين الملكية.", textAlign: TextAlign.right, style: TextStyle(color: Color(0xFF5ED5A8), fontSize: 11)),
          Divider(color: Colors.white10),
          Text("إشعار الغرفة: استمتع بوقتك في الديوان 🥰", style: TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.8), Colors.transparent])),
      child: Row(
        children: [
          _buildBottomIconButton(Icons.card_giftcard, Colors.pinkAccent, () => _showSheet(const GiftShopSheet())),
          const SizedBox(width: 12),
          _buildBottomIconButton(Icons.videogame_asset, Colors.amber, () {}),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 40, decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)), child: const TextField(textAlign: TextAlign.right, style: TextStyle(color: Colors.white, fontSize: 13), decoration: InputDecoration(hintText: "قل شيئاً...", hintStyle: TextStyle(color: Colors.white38, fontSize: 12), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 10), suffixIcon: Icon(Icons.edit, color: Colors.white38, size: 14))))),
          const SizedBox(width: 10),
          _buildBottomIconButton(_isMuted ? Icons.mic_off : Icons.mic, _isMuted ? Colors.red : Colors.white70, () => setState(() => _isMuted = !_isMuted)),
          const SizedBox(width: 10),
          _buildBottomIconButton(Icons.volume_up, Colors.white70, () {}),
        ],
      ),
    );
  }

  Widget _buildBottomIconButton(IconData icon, Color color, VoidCallback onTap) => GestureDetector(onTap: onTap, child: Icon(icon, color: color, size: 28));

  void _showSheet(Widget sheet) => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => sheet);

  void _showSettingsSheet() { /* كود الإعدادات */ }
  void _showExitSheet() { /* كود الخروج */ }
}

// --- واجهة لوحة صدارة الساحة الملكية ---
class _ArenaLeaderboardSheet extends StatelessWidget {
  final String roomId;
  const _ArenaLeaderboardSheet({required this.roomId});

  @override
  Widget build(BuildContext context) {
    final db = FirebaseFirestore.instance;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF042F2C), Color(0xFF021412)]),
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 15),
          Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.amber.withOpacity(0.3), borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 20),
          const Text("ساحة المنافسة الملكية 🏆", style: TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.bold)),
          const Text("أقوى داعمي الوكالة حالياً", style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 20),
          
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // البحث عن المسابقات النشطة في هذه الغرفة (بناءً على صاحب الغرفة)
              stream: db.collection('royal_arena_contests').where('status', isEqualTo: 'active').limit(1).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("لا توجد مسابقات نشطة حالياً", style: TextStyle(color: Colors.white24)));
                
                final contestDoc = snapshot.data!.docs.first;
                final contestData = contestDoc.data() as Map<String, dynamic>;

                return Column(
                  children: [
                    _buildContestInfo(contestData),
                    Expanded(child: _buildLeaderboardList(contestDoc.reference)),
                  ],
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContestInfo(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.all(15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.amber.withOpacity(0.2))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text("الجائزة: ${data['prize']} ${data['currency'] == 'gems' ? '💎' : '🪙'}", style: const TextStyle(color: Colors.amber, fontSize: 12)),
            ],
          ),
          const Icon(Icons.timer_outlined, color: Colors.white38),
        ],
      ),
    );
  }

  Widget _buildLeaderboardList(DocumentReference contestRef) {
    return StreamBuilder<QuerySnapshot>(
      stream: contestRef.collection('leaderboard').orderBy('points', descending: true).limit(10).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final users = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final userData = users[index].data() as Map<String, dynamic>;
            return _buildLeaderboardItem(index + 1, userData);
          },
        );
      }
    );
  }

  Widget _buildLeaderboardItem(int rank, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Text("#$rank", style: TextStyle(color: rank <= 3 ? Colors.amber : Colors.white24, fontWeight: FontWeight.bold)),
          const SizedBox(width: 15),
          const CircleAvatar(radius: 18, backgroundColor: Colors.white10, child: Icon(Icons.person, color: Colors.white24)),
          const SizedBox(width: 15),
          const Expanded(child: Text("مشارك ملكي", style: TextStyle(color: Colors.white, fontSize: 13))),
          Text("${data['points']} نقطة", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}
