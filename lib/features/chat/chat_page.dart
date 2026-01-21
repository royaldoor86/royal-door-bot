import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart';
import '../../app_theme.dart';
import 'individual_chat_page.dart';
import '../profile/user_details_view_page.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundBlack,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('المحادثات الملكية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.royalGold,
            labelColor: AppTheme.royalGold,
            unselectedLabelColor: Colors.white38,
            tabs: const [Tab(text: 'المحادثات'), Tab(text: 'طلبات الصداقة')],
          ),
        ),
        body: AppTheme.background(
          child: Column(
            children: [
              _buildSearchBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildChatList(),
                    const _FriendRequestsList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: AppTheme.glassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
        opacity: 0.03,
        child: Row(
          children: [
            const Icon(Icons.search, color: AppTheme.royalGold, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'بحث بواسطة الآيدي الملكي...',
                  hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(icon: const Icon(Icons.person_add_alt_1, color: AppTheme.royalGold, size: 20), onPressed: () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Center(child: Text('يرجى تسجيل الدخول', style: TextStyle(color: Colors.white24)));

    return StreamBuilder<List<ChatRoomModel>>(
      stream: _firestoreService.streamChatRooms(currentUser.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppTheme.royalGold));
        final rooms = snapshot.data ?? [];
        if (rooms.isEmpty) return const Center(child: Text('لا توجد محادثات جارية حالياً', style: TextStyle(color: Colors.white24)));

        return ListView.builder(
          itemCount: rooms.length,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemBuilder: (context, index) {
            final room = rooms[index];
            final otherUserId = room.participants.firstWhere((id) => id != currentUser.uid, orElse: () => '');
            
            return StreamBuilder<UserModel>(
              stream: _firestoreService.streamUserData(otherUserId),
              builder: (context, userSnap) {
                if (!userSnap.hasData) return const SizedBox.shrink();
                final otherUser = userSnap.data!;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: AppTheme.glassContainer(
                    padding: const EdgeInsets.all(10),
                    opacity: 0.02,
                    child: ListTile(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => IndividualChatPage(otherUser: otherUser, roomId: room.id))),
                      leading: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Colors.white10,
                            backgroundImage: otherUser.profilePic.isNotEmpty ? NetworkImage(otherUser.profilePic) : null,
                            child: otherUser.profilePic.isEmpty ? const Icon(Icons.person, color: Colors.white24) : null,
                          ),
                          if (otherUser.isActive) Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: AppTheme.backgroundBlack, width: 2))),
                        ],
                      ),
                      title: Text(otherUser.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      subtitle: Text(room.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(intl.DateFormat('hh:mm a').format(room.lastMessageTime), style: const TextStyle(color: Colors.white24, fontSize: 10)),
                          if (room.unreadCounts[currentUser.uid] != null && room.unreadCounts[currentUser.uid]! > 0)
                            Container(margin: const EdgeInsets.only(top: 5), padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: AppTheme.royalGold, shape: BoxShape.circle), child: Text('${room.unreadCounts[currentUser.uid]}', style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _FriendRequestsList extends StatelessWidget {
  const _FriendRequestsList();
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('طلبات الصداقة الملكية ستظهر هنا 🤝', style: TextStyle(color: Colors.white24)));
  }
}
