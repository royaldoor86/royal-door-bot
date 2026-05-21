import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../services/ad_manager.dart';
import '../../services/firestore_service.dart';
import '../../services/localization_service.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart';
import '../../app_theme.dart';
import '../../theme/reusable_widgets.dart';
import 'individual_chat_page.dart';
import 'group_chat_page.dart';
import '../profile/user_details_view_page.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _filter = 'all';
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = AdManager().getBannerAd(
      size: AdSize.banner,
      onAdLoaded: () {
        setState(() {
          _isAdLoaded = true;
        });
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  void _searchAndShowProfile() async {
    final royalId = _searchController.text.trim();
    if (royalId.isEmpty) return;
    final targetUser = await _firestoreService.getUserByRoyalId(royalId);
    if (targetUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لم يتم العثور على المستخدم')));
      }
      return;
    }
    if (mounted) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => UserDetailsViewPage(user: targetUser)));
    }
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final trans = Translations.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        bottomNavigationBar: _isAdLoaded && _bannerAd != null
            ? Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                height: _bannerAd!.size.height.toDouble(),
                width: _bannerAd!.size.width.toDouble(),
                child: AdWidget(
                  key: ObjectKey(_bannerAd),
                  ad: _bannerAd!,
                ),
              )
            : null,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(trans.get('chats'),
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.group_add_rounded,
                  color: AppTheme.royalGold, size: 28),
              onPressed: _showCreateGroupDialog,
            ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.royalGold,
            labelColor: AppTheme.royalGold,
            unselectedLabelColor: Colors.white38,
            tabs: [
              Tab(text: trans.get('chats')),
              const Tab(text: 'Requests'),
            ],
          ),
        ),
        body: AppTheme.background(
          child: Column(
            children: [
              _buildSearchBar(trans),
              _buildFilterChips(trans),
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

  void _showCreateGroupDialog() {
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Create Royal Group 👑',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Group Name',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: AppTheme.royalGold),
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                final roomRef =
                    FirebaseFirestore.instance.collection('chatRooms').doc();
                await roomRef.set({
                  'groupName': name,
                  'isGroup': true,
                  'participants': [uid],
                  'admins': [uid],
                  'createdAt': FieldValue.serverTimestamp(),
                  'lastMessage': 'Group Created',
                  'lastMessageTime': FieldValue.serverTimestamp(),
                  'unreadCounts': {uid: 0},
                });
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
              }
            },
            child: const Text('Create',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(Translations trans) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _filterChip('All', 'all'),
          _filterChip('Unread', 'unread'),
          _filterChip('Groups', 'groups'),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    bool isSelected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        margin: const EdgeInsets.only(left: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? AppTheme.royalGold : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSearchBar(Translations trans) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: AppTheme.glassContainer(
        opacity: 0.05,
        child: Row(
          children: [
            const SizedBox(width: 15),
            const Icon(Icons.search, color: Colors.white24),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                    hintText: 'Search by Royal ID...',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.white24, fontSize: 14)),
                onSubmitted: (_) => _searchAndShowProfile(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return StreamBuilder<List<ChatRoomModel>>(
      stream: _firestoreService.streamChatRooms(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const RoyalShimmerList(itemCount: 8, itemHeight: 70);
        }
        var rooms = snapshot.data!;

        if (_filter == 'unread') {
          rooms = rooms.where((r) => (r.unreadCounts[uid] ?? 0) > 0).toList();
        }
        if (_filter == 'groups') rooms = rooms.where((r) => r.isGroup).toList();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: rooms.length,
          itemBuilder: (context, index) {
            final room = rooms[index];
            return _ChatTile(room: room, myUid: uid);
          },
        );
      },
    );
  }
}

class _ChatTile extends StatelessWidget {
  final ChatRoomModel room;
  final String myUid;
  const _ChatTile({required this.room, required this.myUid});

  void _showDeleteConfirmation(
      BuildContext context, FirestoreService fs) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('حذف المحادثة',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
            'سيتم حذف المحادثة من قائمتك فقط، يمكنك بدء المحادثة مرة أخرى لاحقاً.',
            style: TextStyle(color: Colors.white70, fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await fs.deleteConversation(room.id, myUid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم حذف المحادثة.'), backgroundColor: Colors.green),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final FirestoreService fs = FirestoreService();

    if (room.isGroup) {
      return _buildGroupTile(context, fs);
    }

    final otherUid =
        room.participants.firstWhere((id) => id != myUid, orElse: () => '');
    return StreamBuilder<UserModel>(
      stream: fs.streamUserData(otherUid),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final user = snap.data!;
        int unread = room.unreadCounts[myUid] ?? 0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          child: AppTheme.glassContainer(
            opacity: 0.03,
            child: ListTile(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => IndividualChatPage(
                          otherUser: user, roomId: room.id))),
              onLongPress: () => _showDeleteConfirmation(context, fs),
              leading: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                      radius: 28,
                      backgroundImage: (user.profilePic.isNotEmpty && Uri.tryParse(user.profilePic)?.host.isNotEmpty == true)
                          ? CachedNetworkImageProvider(user.profilePic)
                          : null),
                  if (user.isActive)
                    Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.black, width: 2.5))),
                ],
              ),
              title: Text(user.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15)),
              subtitle: Text(room.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: unread > 0 ? Colors.white70 : Colors.white38,
                      fontSize: 13)),
              trailing: _buildTrailing(room),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupTile(BuildContext context, FirestoreService fs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: AppTheme.glassContainer(
        opacity: 0.03,
        child: ListTile(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => GroupChatPage(room: room))),
          onLongPress: () => _showDeleteConfirmation(context, fs),
          leading: CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white10,
            backgroundImage:
                (room.groupImage != null && room.groupImage!.isNotEmpty && Uri.tryParse(room.groupImage!)?.host.isNotEmpty == true)
                    ? CachedNetworkImageProvider(room.groupImage!)
                    : null,
            child: (room.groupImage == null || room.groupImage!.isEmpty)
                ? const Icon(Icons.groups, color: AppTheme.royalGold)
                : null,
          ),
          title: Text(room.groupName ?? 'Group',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
          subtitle: Text(room.lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white38, fontSize: 13)),
          trailing: _buildTrailing(room),
        ),
      ),
    );
  }

  Widget _buildTrailing(ChatRoomModel room) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(intl.DateFormat('hh:mm a').format(room.lastMessageTime),
            style: const TextStyle(color: Colors.white24, fontSize: 10)),
      ],
    );
  }
}

class _FriendRequestsList extends StatelessWidget {
  const _FriendRequestsList();
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final fs = FirestoreService();
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: fs.streamFriendRequests(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const RoyalShimmerList(itemCount: 8, itemHeight: 70);
        }
        final reqs = snapshot.data!;
        if (reqs.isEmpty) {
          return const Center(
              child: Text('No friend requests',
                  style: TextStyle(color: Colors.white24)));
        }

        return ListView.builder(
          itemCount: reqs.length,
          itemBuilder: (context, i) {
            final r = reqs[i];
            return StreamBuilder<UserModel>(
              stream: fs.streamUserData(r['senderId']),
              builder: (context, uSnap) {
                if (!uSnap.hasData) return const SizedBox();
                final sender = uSnap.data!;
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                  child: AppTheme.glassContainer(
                    opacity: 0.05,
                    child: ListTile(
                      leading: CircleAvatar(
                          backgroundImage: (sender.profilePic.isNotEmpty && Uri.tryParse(sender.profilePic)?.host.isNotEmpty == true)
                              ? CachedNetworkImageProvider(sender.profilePic)
                              : null),
                      title: Text(sender.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle,
                                color: Colors.green),
                              constraints: const BoxConstraints(
                                minWidth: 36, minHeight: 36),
                              padding: const EdgeInsets.all(6),
                              iconSize: 18,
                              visualDensity: VisualDensity.compact,
                              splashRadius: 18,
                              onPressed: () => fs.acceptFriendRequest(
                                r['id'], sender.uid, uid)),
                            IconButton(
                              icon: const Icon(Icons.cancel,
                                color: Colors.redAccent),
                              constraints: const BoxConstraints(
                                minWidth: 36, minHeight: 36),
                              padding: const EdgeInsets.all(6),
                              iconSize: 18,
                              visualDensity: VisualDensity.compact,
                              splashRadius: 18,
                              onPressed: () => fs.rejectFriendRequest(r['id'])),
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
