import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app_theme.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../ui/widgets/royal_animated_frame.dart';
import '../rooms/widgets/moderation/ban_user_sheet.dart';
import '../rooms/widgets/moderation/kick_user_sheet.dart';
import '../rooms/widgets/moderation/mute_user_sheet.dart';
import '../rooms/widgets/moderation/penalty_user_sheet.dart';
import '../rooms/widgets/moderation/silence_user_sheet.dart';
import '../chat/individual_chat_page.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;
  final String? roomId; // لاستخدامه في المستقبل (مثل إرسال هدية من البروفايل)

  const UserProfilePage({super.key, required this.userId, this.roomId});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final FirestoreService _firestoreService = FirestoreService();
  bool _hasPower = false;

  @override
  void initState() {
    super.initState();
    _checkModerationPower();
  }

  void _checkModerationPower() async {
    if (widget.roomId == null || widget.roomId!.isEmpty) return;

    final roomDoc = await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId!)
        .get();
    if (roomDoc.exists && roomDoc.data() != null) {
      final data = roomDoc.data()!;
      final ownerId = data['ownerId'] as String?;
      final moderators = List<String>.from(data['moderators'] ?? []);

      if (mounted) {
        setState(() => _hasPower =
            (_currentUserId == ownerId) || moderators.contains(_currentUserId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFF121212),
            body: Center(
                child: CircularProgressIndicator(color: AppTheme.royalGold)),
          );
        }
        if (!snapshot.data!.exists) {
          return Scaffold(
            backgroundColor: const Color(0xFF121212),
            appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
            body: const Center(
                child: Text('عذراً، لم يتم العثور على المستخدم',
                    style: TextStyle(color: Colors.white))),
          );
        }

        final user = UserModel.fromMap(
            snapshot.data!.data() as Map<String, dynamic>, snapshot.data!.id);

        final bool isFollowing = user.followers.contains(_currentUserId);

        return Scaffold(
          backgroundColor: const Color(0xFF0F1B25),
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 280.0,
                pinned: true,
                stretch: true,
                backgroundColor: const Color(0xFF1A242F),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    user.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      (user.profilePic.isNotEmpty && Uri.tryParse(user.profilePic)?.host.isNotEmpty == true)
                        ? CachedNetworkImage(
                            imageUrl: user.profilePic,
                            fit: BoxFit.cover,
                            errorWidget: (c, u, e) => Container(color: Colors.black26),
                          )
                        : Container(color: Colors.black26, child: const Icon(Icons.person, size: 50, color: Colors.white24)),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.5, 1.0],
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.9)
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(80),
                  child: Transform.translate(
                    offset: const Offset(0, 30),
                    child: (user.currentFrame != null &&
                            user.currentFrame!.isNotEmpty)
                        ? RoyalAnimatedFrame(
                            frameUrl: user.currentFrame!,
                            size: 107,
                            child: CircleAvatar(
                              radius: 40,
                              backgroundImage:
                                  (user.profilePic.isNotEmpty && Uri.tryParse(user.profilePic)?.host.isNotEmpty == true)
                                    ? CachedNetworkImageProvider(user.profilePic)
                                    : const AssetImage('assets/images/default_profile.png') as ImageProvider,
                            ),
                          )
                        : CircleAvatar(
                            radius: 42,
                            backgroundColor: AppTheme.royalGold,
                            child: CircleAvatar(
                              radius: 40,
                              backgroundImage:
                                  (user.profilePic.isNotEmpty && Uri.tryParse(user.profilePic)?.host.isNotEmpty == true)
                                    ? CachedNetworkImageProvider(user.profilePic)
                                    : const AssetImage('assets/images/default_profile.png') as ImageProvider,
                            ),
                          ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const SizedBox(
                          height: 53), // Space for the overlapping avatar
                      Text(
                        'ID: ${user.royalId}',
                        style: const TextStyle(
                            color: AppTheme.royalGold,
                            fontSize: 16,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      if (user.bio.isNotEmpty)
                        Text(
                          user.bio,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontStyle: FontStyle.italic),
                        ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatColumn('مستوى', user.userLevel.toString(),
                              Icons.military_tech_rounded, Colors.amber),
                          _buildStatColumn(
                              'متابِعون',
                              user.followers.length.toString(),
                              Icons.people_alt_rounded,
                              Colors.cyanAccent),
                          _buildStatColumn(
                              'متابَعون',
                              user.following.length.toString(),
                              Icons.person_add_alt_1_rounded,
                              Colors.pinkAccent),
                        ],
                      ),
                      const Divider(
                          color: Colors.white12,
                          height: 40,
                          indent: 20,
                          endIndent: 20),
                      if (_currentUserId != widget.userId)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () async {
                                final firestoreService = FirestoreService();
                                final roomId =
                                    await firestoreService.ensureChatRoomExists(
                                        _currentUserId, user.uid);
                                if (mounted) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => IndividualChatPage(
                                          otherUser: user, roomId: roomId),
                                    ),
                                  );
                                }
                              },
                              icon:
                                  const Icon(Icons.chat_bubble_outline_rounded),
                              label: const Text('مراسلة'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.1),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 12),
                              ),
                            ),
                            const SizedBox(width: 15),
                            ElevatedButton.icon(
                              onPressed: () async {
                                await _firestoreService.toggleFollow(
                                    _currentUserId, user.uid);
                              },
                              icon: Icon(isFollowing
                                  ? Icons.check_circle_outline_rounded
                                  : Icons.person_add_rounded),
                              label: Text(
                                  isFollowing ? 'إلغاء المتابعة' : 'متابعة'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isFollowing
                                    ? Colors.grey[700]
                                    : AppTheme.royalGold,
                                foregroundColor:
                                    isFollowing ? Colors.white : Colors.black,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      if (_hasPower && _currentUserId != widget.userId)
                        _buildModerationControls(user.name),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showModerationSheet(String type, String userId, String name) {
    if (widget.roomId == null) return;
    Widget sheet;
    switch (type) {
      case "silence":
        sheet = SilenceUserSheet(
            roomId: widget.roomId!, userId: userId, userName: name);
        break;
      case "ban":
        sheet = BanUserSheet(
            roomId: widget.roomId!, userId: userId, userName: name);
        break;
      case "kick":
        sheet = KickUserSheet(
            roomId: widget.roomId!, userId: userId, userName: name);
        break;
      case "penalty":
        sheet = PenaltyUserSheet(
            roomId: widget.roomId!, userId: userId, userName: name);
        break;
      case "mute":
        sheet = MuteUserSheet(
            roomId: widget.roomId!, userId: userId, userName: name);
        break;
      default:
        return;
    }
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => sheet);
  }

  Widget _buildModerationControls(String userName) {
    return Padding(
      padding: const EdgeInsets.only(top: 25.0),
      child: Column(
        children: [
          const Text('أدوات الإشراف 🛡️',
              style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 15),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              _modActionButton(
                  'طرد من الغرفة',
                  Icons.exit_to_app,
                  Colors.orange,
                  () => _showModerationSheet("kick", widget.userId, userName)),
              _modActionButton('حظر من الغرفة', Icons.gavel_rounded, Colors.red,
                  () => _showModerationSheet("ban", widget.userId, userName)),
              _modActionButton(
                  'إصمات',
                  Icons.mic_off_rounded,
                  Colors.purpleAccent,
                  () =>
                      _showModerationSheet("silence", widget.userId, userName)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modActionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.8),
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          textStyle:
              const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStatColumn(
      String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }
}
