import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/firestore_service.dart';
import '../../services/localization_service.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart';
import '../../app_theme.dart';
import '../../theme/reusable_widgets.dart';
import 'individual_chat_page.dart';
import 'group_chat_page.dart';
import '../profile/user_details_view_page.dart';
import '../../services/facebook_friend_sync_service.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key});

  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage>
  with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _searchPulseController;
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _searchPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchPulseController.dispose();
    _searchController.dispose();
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
              const Tab(text: 'الأصدقاء'),
              const Tab(text: 'Facebook'),
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
                    const _FriendsList(),
                    const _FacebookFriendsTab(),
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
          color: isSelected
              ? AppTheme.royalGold
              : Colors.white.withValues(alpha: 0.05),
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
      child: AnimatedBuilder(
        animation: _searchPulseController,
        builder: (context, child) {
          final pulse = _searchPulseController.value;
          final firstColor = Color.lerp(
              const Color(0xFFD4AF37), const Color(0xFF00D9FF), pulse)!;
          final secondColor = Color.lerp(
              const Color(0xFF7C3AED), const Color(0xFFFF4F9A), pulse)!;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  firstColor.withValues(alpha: 0.28),
                  secondColor.withValues(alpha: 0.20),
                  const Color(0xFF0D1728),
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: firstColor.withValues(alpha: 0.72),
                width: 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color: firstColor.withValues(alpha: 0.24 + pulse * 0.16),
                  blurRadius: 22 + pulse * 8,
                  spreadRadius: 1 + pulse,
                ),
                BoxShadow(
                  color: secondColor.withValues(alpha: 0.13),
                  blurRadius: 30,
                  offset: const Offset(-4, 6),
                ),
              ],
            ),
            child: AppTheme.glassContainer(
              opacity: 0.06,
              borderRadius: BorderRadius.circular(21),
              child: Row(
                children: [
                  const SizedBox(width: 15),
                  Transform.translate(
                    offset: Offset(0, -pulse * 1.5),
                    child: Icon(Icons.search_rounded,
                        color: firstColor, size: 25),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        hintText: 'Search by Royal ID...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 14),
                      ),
                      onSubmitted: (_) => _searchAndShowProfile(),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsetsDirectional.only(end: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: firstColor.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: firstColor.withValues(alpha: 0.4)),
                    ),
                    child: Icon(Icons.auto_awesome,
                        size: 15, color: firstColor),
                  ),
                ],
              ),
            ),
          );
        },
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
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF102A43), Color(0xFF211A3A)],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.royalGold.withValues(alpha: 0.18)),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.royalGold.withValues(alpha: 0.10),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: AppTheme.glassContainer(
              opacity: 0.04,
              borderGlow: true,
              child: Material(
                color: Colors.transparent,
                child: ListTile(
                contentPadding:
                  const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
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
                      radius: 26,
                        backgroundImage: (user.profilePic.isNotEmpty &&
                                Uri.tryParse(user.profilePic)
                                        ?.host
                                        .isNotEmpty ==
                                    true)
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
                        fontSize: 14)),
                subtitle: Text(room.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: unread > 0 ? Colors.white70 : Colors.white38,
                        fontSize: 12)),
                trailing: _buildTrailing(room),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupTile(BuildContext context, FirestoreService fs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF33251A), Color(0xFF102A43)],
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.royalGold.withValues(alpha: 0.22)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.royalGold.withValues(alpha: 0.12),
              blurRadius: 18,
              spreadRadius: 1,
            ),
          ],
        ),
        child: AppTheme.glassContainer(
          opacity: 0.04,
          borderGlow: true,
          child: Material(
            color: Colors.transparent,
            child: ListTile(
            contentPadding:
              const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => GroupChatPage(room: room))),
            onLongPress: () => _showDeleteConfirmation(context, fs),
            leading: CircleAvatar(
              radius: 26,
              backgroundColor: Colors.white10,
              backgroundImage: (room.groupImage != null &&
                      room.groupImage!.isNotEmpty &&
                      Uri.tryParse(room.groupImage!)?.host.isNotEmpty == true)
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
                    fontSize: 14)),
            subtitle: Text(room.lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white38, fontSize: 12)),
            trailing: _buildTrailing(room),
            ),
          ),
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
                          backgroundImage: (sender.profilePic.isNotEmpty &&
                                  Uri.tryParse(sender.profilePic)
                                          ?.host
                                          .isNotEmpty ==
                                      true)
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
                              onPressed: () async {
                                try {
                                  await fs.acceptFriendRequest(
                                      r['id'], sender.uid, uid);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                          content: Text('تم قبول طلب الصداقة ✅'),
                                          backgroundColor: Colors.green),
                                    );
                                  }
                                } catch (e) {
                                  debugPrint('Error accepting friend request: $e');
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                          content: Text('حدث خطأ أثناء قبول طلب الصداقة'),
                                          backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              }),
                          IconButton(
                              icon: const Icon(Icons.cancel,
                                  color: Colors.redAccent),
                              constraints: const BoxConstraints(
                                  minWidth: 36, minHeight: 36),
                              padding: const EdgeInsets.all(6),
                              iconSize: 18,
                              visualDensity: VisualDensity.compact,
                              splashRadius: 18,
                              onPressed: () async {
                                try {
                                  await fs.rejectFriendRequest(r['id']);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                          content: Text('تم رفض طلب الصداقة'),
                                          backgroundColor: Colors.orange),
                                    );
                                  }
                                } catch (e) {
                                  debugPrint('Error rejecting friend request: $e');
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      const SnackBar(
                                          content: Text('حدث خطأ أثناء رفض طلب الصداقة'),
                                          backgroundColor: Colors.red),
                                    );
                                  }
                                }
                              }),
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

class _FriendsList extends StatelessWidget {
  const _FriendsList();

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
          child:
              Text('يرجى تسجيل الدخول', style: TextStyle(color: Colors.white)));
    }

    return StreamBuilder<UserModel>(
      stream: firestoreService.streamUserData(user.uid),
      builder: (context, snapshot) {
        final userData = snapshot.data;

        return DefaultTabController(
          length: 3,
          child: Column(
            children: [
              const TabBar(
                labelColor: AppTheme.royalGold,
                unselectedLabelColor: Colors.white38,
                indicatorColor: AppTheme.royalGold,
                tabs: [
                  Tab(text: 'أصدقاء'),
                  Tab(text: 'متابعة'),
                  Tab(text: 'معجبون'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _UserListStream(
                      stream: firestoreService.streamFriends(user.uid),
                      emptyMessage: 'لا يوجد أصدقاء حالياً',
                    ),
                    _UserListStream(
                      stream: firestoreService
                          .streamUsersFromList(userData?.following ?? []),
                      emptyMessage: 'لم تقم بمتابعة أحد بعد',
                    ),
                    _UserListStream(
                      stream: firestoreService
                          .streamUsersFromList(userData?.followers ?? []),
                      emptyMessage: 'لا يوجد معجبون حالياً',
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FacebookFriendsTab extends StatefulWidget {
  const _FacebookFriendsTab();

  @override
  State<_FacebookFriendsTab> createState() => _FacebookFriendsTabState();
}

class _FacebookFriendsTabState extends State<_FacebookFriendsTab> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(
          child:
              Text('يرجى تسجيل الدخول', style: TextStyle(color: Colors.white)));
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data();
        final facebookLinked = (data?['facebookLinked'] as bool?) ?? false;
        final friendIds = (data?['facebookFriendIds'] as List?)
                ?.whereType<String>()
                .toList() ??
            <String>[];
        final facebookFriends = (data?['facebookFriendsData'] as List?)
                ?.whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList() ??
            <Map<String, dynamic>>[];

        return Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              if (!facebookLinked)
                SingleChildScrollView(
                  child: Card(
                    color: Colors.white.withValues(alpha: 0.08),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                        const Icon(Icons.facebook,
                            color: AppTheme.royalGold, size: 36),
                        const SizedBox(height: 12),
                        const Text(
                          'ربط حساب فيسبوك يسمح لك بعرض أصدقاءك داخل المحادثات وإرسال طلبات صداقة مباشرة.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await _connectFacebookAndSync(context);
                          },
                          icon: const Icon(Icons.link),
                          label: const Text('ربط ومزامنة فيسبوك'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.royalGold),
                        ),
                        ],
                      ),
                    ),
                  ),
                )
              else ...[
                Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.greenAccent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'تم ربط فيسبوك ومزامنة ${friendIds.length} صديقًا.',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        await FacebookFriendSyncService.clearFacebookSync();
                        await FacebookAuth.instance.logOut();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم حذف ربط فيسبوك')),
                          );
                        }
                      },
                      icon: const Icon(Icons.link_off, color: Colors.redAccent),
                      label: const Text('إلغاء الربط',
                          style: TextStyle(color: Colors.redAccent)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('الكل'),
                      selected: _filter == 'all',
                      selectedColor: AppTheme.royalGold.withValues(alpha: 0.2),
                      checkmarkColor: AppTheme.royalGold,
                      labelStyle: TextStyle(
                        color: _filter == 'all' ? Colors.white : Colors.white70,
                      ),
                      onSelected: (_) => setState(() => _filter = 'all'),
                    ),
                    FilterChip(
                      label: const Text('مسجلون'),
                      selected: _filter == 'registered',
                      selectedColor: AppTheme.royalGold.withValues(alpha: 0.2),
                      checkmarkColor: AppTheme.royalGold,
                      labelStyle: TextStyle(
                        color: _filter == 'registered'
                            ? Colors.white
                            : Colors.white70,
                      ),
                      onSelected: (_) => setState(() => _filter = 'registered'),
                    ),
                    FilterChip(
                      label: const Text('غير مسجلين'),
                      selected: _filter == 'unregistered',
                      selectedColor: AppTheme.royalGold.withValues(alpha: 0.2),
                      checkmarkColor: AppTheme.royalGold,
                      labelStyle: TextStyle(
                        color: _filter == 'unregistered'
                            ? Colors.white
                            : Colors.white70,
                      ),
                      onSelected: (_) =>
                          setState(() => _filter = 'unregistered'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 360,
                  child: friendIds.isEmpty && facebookFriends.isEmpty
                      ? const Center(
                          child: Text('لا يوجد أصدقاء متاحون حاليًا من فيسبوك',
                              style: TextStyle(color: Colors.white24)))
                      : FutureBuilder<List<Map<String, dynamic>>>(
                          future: FacebookFriendSyncService
                              .getRegisteredFacebookFriendsInApp(friendIds),
                          builder: (context, userSnapshot) {
                            if (!userSnapshot.hasData) {
                              return const Center(
                                  child: CircularProgressIndicator(
                                      color: AppTheme.royalGold));
                            }

                            final registeredUsers =
                                <String, Map<String, dynamic>>{};
                            for (final appUser in userSnapshot.data ?? []) {
                              final facebookId =
                                  appUser['facebookId']?.toString();
                              if (facebookId != null && facebookId.isNotEmpty) {
                                registeredUsers[facebookId] = appUser;
                              }
                            }

                            final displayItems = facebookFriends.isEmpty
                                ? (userSnapshot.data ?? [])
                                    .whereType<Map<String, dynamic>>()
                                    .map((appUser) => {
                                          'facebookId': appUser['facebookId']
                                                  ?.toString() ??
                                              '',
                                          'name': appUser['name']?.toString() ??
                                              'Facebook Friend',
                                          'pictureUrl': '',
                                          'appUser': appUser,
                                        })
                                    .toList()
                                : facebookFriends.map((friend) {
                                    final facebookId =
                                        friend['facebookId']?.toString() ?? '';
                                    final appUser = registeredUsers[facebookId];
                                    return {
                                      'facebookId': facebookId,
                                      'name': friend['name']?.toString() ??
                                          'Facebook Friend',
                                      'pictureUrl':
                                          friend['pictureUrl']?.toString() ??
                                              '',
                                      'appUser': appUser,
                                    };
                                  }).toList();

                            final filteredItems = displayItems.where((item) {
                              final hasAppAccount =
                                  (item['appUser'] as Map<String, dynamic>?) !=
                                      null;
                              switch (_filter) {
                                case 'registered':
                                  return hasAppAccount;
                                case 'unregistered':
                                  return !hasAppAccount;
                                default:
                                  return true;
                              }
                            }).toList();

                            if (filteredItems.isEmpty) {
                              return const Center(
                                  child: Text(
                                      'لا توجد عناصر تطابق هذا الفلتر حالياً',
                                      style: TextStyle(color: Colors.white24)));
                            }

                            return ListView.separated(
                              itemCount: filteredItems.length,
                              separatorBuilder: (_, __) => const Divider(
                                  color: Colors.white10, height: 20),
                              itemBuilder: (context, index) {
                                final item = filteredItems[index];
                                final appUser =
                                    item['appUser'] as Map<String, dynamic>?;
                                final friendName = item['name']?.toString() ??
                                    'Facebook Friend';
                                final friendPicture =
                                    item['pictureUrl']?.toString() ?? '';
                                final friendId =
                                    item['facebookId']?.toString() ?? '';

                                if (appUser == null) {
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.white10,
                                      backgroundImage: friendPicture.isNotEmpty
                                          ? CachedNetworkImageProvider(
                                              friendPicture)
                                          : null,
                                      child: friendPicture.isEmpty
                                          ? Text(friendName.isNotEmpty
                                              ? friendName[0].toUpperCase()
                                              : 'F')
                                          : null,
                                    ),
                                    title: Text(friendName,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                    subtitle: const Text(
                                        'ليس لديه حساب في التطبيق بعد',
                                        style:
                                            TextStyle(color: Colors.white38)),
                                    trailing: TextButton.icon(
                                      onPressed: () async {
                                        await _shareAppInvite(
                                            context, friendName);
                                      },
                                      icon: const Icon(Icons.share,
                                          color: AppTheme.royalGold),
                                      label: const Text('دعوة',
                                          style: TextStyle(
                                              color: AppTheme.royalGold)),
                                    ),
                                  );
                                }

                                final friend = UserModel.fromMap(
                                  Map<String, dynamic>.from(appUser),
                                  appUser['uid']?.toString() ?? '',
                                );
                                return FutureBuilder<Map<String, dynamic>>(
                                  future: FirestoreService()
                                      .getFriendshipState(user.uid, friend.uid),
                                  builder: (context, stateSnapshot) {
                                    final state =
                                        stateSnapshot.data?['status'] ?? 'none';
                                    final requestId = stateSnapshot
                                        .data?['requestId']
                                        ?.toString();
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.white10,
                                        backgroundImage:
                                            friend.profilePic.isNotEmpty
                                                ? CachedNetworkImageProvider(
                                                    friend.profilePic)
                                                : null,
                                        child: friend.profilePic.isEmpty
                                            ? const Icon(Icons.person)
                                            : null,
                                      ),
                                      title: Text(friend.name,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold)),
                                      subtitle: Text(friend.royalId,
                                          style: const TextStyle(
                                              color: Colors.white38)),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (state == 'friends')
                                            TextButton.icon(
                                              onPressed: () async {
                                                final roomId =
                                                    await FirestoreService()
                                                        .ensureChatRoomExists(
                                                            user.uid,
                                                            friend.uid);
                                                if (!context.mounted) return;
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        IndividualChatPage(
                                                      otherUser: friend,
                                                      roomId: roomId,
                                                    ),
                                                  ),
                                                );
                                              },
                                              icon: const Icon(Icons.chat,
                                                  color: AppTheme.royalGold),
                                              label: const Text('دردشة',
                                                  style: TextStyle(
                                                      color:
                                                          AppTheme.royalGold)),
                                            )
                                          else if (state == 'pending')
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Chip(
                                                  label: Text('طلب مرسل',
                                                      style: TextStyle(
                                                          fontSize: 12)),
                                                  backgroundColor:
                                                      Colors.orangeAccent,
                                                ),
                                                const SizedBox(width: 6),
                                                TextButton.icon(
                                                  onPressed: () async {
                                                    try {
                                                      if (requestId == null ||
                                                          requestId.isEmpty) {
                                                        if (context.mounted) {
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            const SnackBar(
                                                                content: Text('معرف الطلب غير صالح'),
                                                                backgroundColor: Colors.red),
                                                          );
                                                        }
                                                        return;
                                                      }

                                                      await FirestoreService()
                                                          .cancelFriendRequest(
                                                              requestId);
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          SnackBar(
                                                              content: Text(
                                                                  'تم إلغاء طلب الصداقة إلى ${friend.name}'),
                                                              backgroundColor: Colors.orange),
                                                        );
                                                      }
                                                    } catch (e) {
                                                      debugPrint('Error canceling friend request: $e');
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          const SnackBar(
                                                              content: Text('حدث خطأ أثناء إلغاء طلب الصداقة'),
                                                              backgroundColor: Colors.red),
                                                        );
                                                      }
                                                    }
                                                  },
                                                  icon: const Icon(Icons.undo,
                                                      color: Colors.redAccent),
                                                  label: const Text('إلغاء',
                                                      style: TextStyle(
                                                          color: Colors
                                                              .redAccent)),
                                                ),
                                              ],
                                            )
                                          else if (state == 'incoming')
                                            TextButton.icon(
                                              onPressed: () async {
                                                try {
                                                  if (requestId == null || requestId.isEmpty) {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(context)
                                                          .showSnackBar(
                                                        const SnackBar(
                                                            content: Text('معرف الطلب غير صالح'),
                                                            backgroundColor: Colors.red),
                                                      );
                                                    }
                                                    return;
                                                  }

                                                  await FirestoreService()
                                                      .acceptFriendRequest(
                                                    requestId,
                                                    friend.uid,
                                                    user.uid,
                                                  );
                                                  
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                          content: Text(
                                                              'تمت إضافة ${friend.name} إلى قائمة الأصدقاء ✅'),
                                                          backgroundColor: Colors.green),
                                                    );
                                                  }
                                                } catch (e) {
                                                  debugPrint('Error accepting friend request: $e');
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                          content: Text('حدث خطأ أثناء قبول طلب الصداقة'),
                                                          backgroundColor: Colors.red),
                                                    );
                                                  }
                                                }
                                              },
                                              icon: const Icon(
                                                  Icons.check_circle,
                                                  color: Colors.greenAccent),
                                              label: const Text('قبول',
                                                  style: TextStyle(
                                                      color:
                                                          Colors.greenAccent)),
                                            )
                                          else
                                            TextButton.icon(
                                              onPressed: () async {
                                                try {
                                                  if (user.uid == friend.uid) {
                                                    return;
                                                  }
                                                  await FirestoreService()
                                                      .sendFriendRequest(
                                                          user.uid, friend.uid);
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                          content: Text(
                                                              'تم إرسال طلب صداقة إلى ${friend.name} ✅'),
                                                          backgroundColor: Colors.green),
                                                    );
                                                  }
                                                } catch (e) {
                                                  debugPrint('Error sending friend request: $e');
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                          content: Text('حدث خطأ أثناء إرسال طلب الصداقة'),
                                                          backgroundColor: Colors.red),
                                                    );
                                                  }
                                                }
                                              },
                                              icon: const Icon(
                                                  Icons.person_add_alt_1,
                                                  color: AppTheme.royalGold),
                                              label: const Text('إضافة',
                                                  style: TextStyle(
                                                      color:
                                                          AppTheme.royalGold)),
                                            ),
                                        ],
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
              ],
            ),
          ),
        );
      },
    );
  }
}

Future<void> _shareAppInvite(BuildContext context, String friendName) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  final inviterName = currentUser?.displayName ?? currentUser?.email ?? 'صديق';
  final message =
      'أدعوك للانضمام إلى تطبيق رويال دور $inviterName\nhttps://royaldoor.app';

  await Share.share(message, subject: 'دعوة إلى رويال دور');

  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تم إرسال دعوة إلى $friendName')),
    );
  }
}

Future<void> _connectFacebookAndSync(BuildContext context) async {
  try {
    final result = await FacebookAuth.instance.login(
      permissions: const ['public_profile', 'email'],
    );

    if (result.status != LoginStatus.success || result.accessToken == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إلغاء ربط فيسبوك أو فشل الإذن')),
        );
      }
      return;
    }

    await FacebookFriendSyncService.syncFacebookFriendsToApp(
        result.accessToken!.token);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم ربط ومزامنة أصدقاء فيسبوك بنجاح')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل ربط فيسبوك: $e')),
      );
    }
  }
}

class _UserListStream extends StatelessWidget {
  final Stream<List<UserModel>> stream;
  final String emptyMessage;

  const _UserListStream({
    required this.stream,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.royalGold));
        }

        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return Center(
              child: Text(emptyMessage,
                  style: const TextStyle(color: Colors.white24)));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          separatorBuilder: (context, index) =>
              const Divider(color: Colors.white10, height: 20),
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              leading: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppTheme.royalGold.withValues(alpha: 0.3),
                      width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white10,
                  backgroundImage: user.profilePic.isNotEmpty
                      ? NetworkImage(user.profilePic)
                      : null,
                  child: user.profilePic.isEmpty
                      ? const Icon(Icons.person, color: Colors.white38)
                      : null,
                ),
              ),
              title: Text(user.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              trailing: const Icon(Icons.arrow_forward_ios,
                  size: 14, color: Colors.white24),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => UserDetailsViewPage(user: user)));
              },
            );
          },
        );
      },
    );
  }
}
