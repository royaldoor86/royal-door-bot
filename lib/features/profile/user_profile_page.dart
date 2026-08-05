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
import '../../services/custom_car_service.dart';
import '../../widgets/animated_vehicle_preview.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;
  final String? roomId; // لاستخدامه في المستقبل (مثل إرسال هدية من البروفايل)
  final bool useScaffold; // لتحديد ما إذا كان سيتم استخدام Scaffold أم لا

  const UserProfilePage({
    super.key,
    required this.userId,
    this.roomId,
    this.useScaffold = true,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final FirestoreService _firestoreService = FirestoreService();
  bool _hasPower = false;
  String? _roomOwnerId;
  List<String> _roomAdmins = [];
  List<String> _roomModerators = [];
  Map<String, dynamic> _moderatorPermissions = {};
  Map<String, dynamic>? _activeVehicle;

  @override
  void initState() {
    super.initState();
    _checkModerationPower();
    _loadActiveVehicle();
  }

  Future<void> _loadActiveVehicle() async {
    final vehicle = await CustomCarService.getActiveCar(widget.userId);
    if (mounted) {
      setState(() {
        _activeVehicle = vehicle;
      });
    }
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
      final admins = List<String>.from(data['admins'] ?? []);
      final moderators = List<String>.from(data['moderators'] ?? []);
      final perms = data['moderatorPermissions'] as Map<String, dynamic>? ?? {};

      if (mounted) {
        setState(() {
          _roomOwnerId = ownerId;
          _roomAdmins = admins;
          _roomModerators = moderators;
          _hasPower = (_currentUserId == ownerId) ||
              admins.contains(_currentUserId) ||
              moderators.contains(_currentUserId);
          _moderatorPermissions = perms;
        });
      }
    }
  }

  bool _can(String key) {
    if (_currentUserId == _roomOwnerId) return true;
    return _moderatorPermissions[key] ?? false;
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
          if (!widget.useScaffold) {
            return const Center(
                child: CircularProgressIndicator(color: AppTheme.royalGold));
          }
          return const Scaffold(
            backgroundColor: Color(0xFF121212),
            body: Center(
                child: CircularProgressIndicator(color: AppTheme.royalGold)),
          );
        }
        if (!snapshot.data!.exists) {
          if (!widget.useScaffold) {
            return const Center(
                child: Text('عذراً، لم يتم العثور على المستخدم',
                    style: TextStyle(color: Colors.white)));
          }
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

        final content = CustomScrollView(
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
                      (user.profilePic.isNotEmpty &&
                              Uri.tryParse(user.profilePic)?.host.isNotEmpty ==
                                  true)
                          ? CachedNetworkImage(
                              imageUrl: user.profilePic,
                              fit: BoxFit.cover,
                              errorWidget: (c, u, e) =>
                                  Container(color: Colors.black26),
                            )
                          : Container(
                              color: Colors.black26,
                              child: const Icon(Icons.person,
                                  size: 50, color: Colors.white24)),
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
                      // عرض الكوينز والجواهر في الأعلى
                      Positioned(
                        top: 50,
                        left: 20,
                        child: _buildCurrencyBadge(
                          Icons.stars_rounded,
                          _parseCurrencyValue(user.rewardStars, user.coins),
                          Colors.amber,
                          'كوينز',
                        ),
                      ),
                      Positioned(
                        top: 50,
                        right: 20,
                        child: _buildCurrencyBadge(
                          Icons.diamond_outlined,
                          _parseCurrencyValue(user.rewardGems, user.gems),
                          Colors.cyan,
                          'جواهر',
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
                              backgroundImage: (user.profilePic.isNotEmpty &&
                                      Uri.tryParse(user.profilePic)
                                              ?.host
                                              .isNotEmpty ==
                                          true)
                                  ? CachedNetworkImageProvider(user.profilePic)
                                  : const AssetImage(
                                          'assets/images/default_avatar.png')
                                      as ImageProvider,
                            ),
                          )
                        : CircleAvatar(
                            radius: 42,
                            backgroundColor: AppTheme.royalGold,
                            child: CircleAvatar(
                              radius: 40,
                              backgroundImage: (user.profilePic.isNotEmpty &&
                                      Uri.tryParse(user.profilePic)
                                              ?.host
                                              .isNotEmpty ==
                                          true)
                                  ? CachedNetworkImageProvider(user.profilePic)
                                  : const AssetImage(
                                          'assets/images/default_avatar.png')
                                      as ImageProvider,
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
                      if (_activeVehicle != null &&
                          _activeVehicle!['enabled'] == true)
                        _buildActiveVehicleSection(),
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
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.1),
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
          );

        if (widget.useScaffold) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F1B25),
            body: content,
          );
        }
        return content;
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
            roomId: widget.roomId!,
            userId: userId,
            userName: name,
            hasPower: _can('canBan'));
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
        builder: (context) => SafeArea(
          child: sheet,
        ));
  }

  Widget _buildModerationControls(String userName) {
    final bool isTargetOwner = widget.userId == _roomOwnerId;
    final bool isTargetAdmin = _roomAdmins.contains(widget.userId);
    final bool isTargetMod = _roomModerators.contains(widget.userId);

    // صاحب الغرفة فقط يمكنه تعيين مسؤولين
    final bool canManageAdmins = _currentUserId == _roomOwnerId;
    // صاحب الغرفة والمسؤولون يمكنهم تعيين مشرفين
    final bool canManageMods =
        (_currentUserId == _roomOwnerId) || _roomAdmins.contains(_currentUserId);

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
              if (canManageAdmins && !isTargetOwner)
                _modActionButton(
                  isTargetAdmin ? 'إزالة كمسؤول' : 'تعيين كمسؤول',
                  isTargetAdmin ? Icons.person_remove : Icons.admin_panel_settings,
                  isTargetAdmin ? Colors.redAccent : Colors.blue,
                  () => _toggleRoomRole('admins', widget.userId, !isTargetAdmin),
                ),
              if (canManageMods && !isTargetOwner && !isTargetAdmin)
                _modActionButton(
                  isTargetMod ? 'إزالة كمشرف' : 'تعيين كمشرف',
                  isTargetMod ? Icons.remove_circle_outline : Icons.shield_outlined,
                  isTargetMod ? Colors.orangeAccent : Colors.teal,
                  () => _toggleRoomRole('moderators', widget.userId, !isTargetMod),
                ),
              if (_can('canKick') && !isTargetOwner && !isTargetAdmin)
                _modActionButton(
                    'طرد من الغرفة',
                    Icons.exit_to_app,
                    Colors.orange,
                    () =>
                        _showModerationSheet("kick", widget.userId, userName)),
              if (_can('canBan') && !isTargetOwner && !isTargetAdmin)
                _modActionButton(
                    'حظر من الغرفة',
                    Icons.gavel_rounded,
                    Colors.red,
                    () => _showModerationSheet("ban", widget.userId, userName)),
              if (_can('canMute') && !isTargetOwner && !isTargetAdmin)
                _modActionButton(
                    'إصمات',
                    Icons.mic_off_rounded,
                    Colors.purpleAccent,
                    () => _showModerationSheet(
                        "silence", widget.userId, userName)),
              if (_can('canPenalty') && !isTargetOwner && !isTargetAdmin)
                _modActionButton(
                    'عقوبة',
                    Icons.warning_rounded,
                    Colors.deepOrange,
                    () => _showModerationSheet(
                        "penalty", widget.userId, userName)),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleRoomRole(String field, String userId, bool add) async {
    if (widget.roomId == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId!)
          .update({
        field: add ? FieldValue.arrayUnion([userId]) : FieldValue.arrayRemove([userId])
      });
      _checkModerationPower(); // تحديث الحالة
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(add ? 'تم التعيين بنجاح' : 'تمت الإزالة بنجاح'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('فشل الإجراء: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
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

  Widget _buildActiveVehicleSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.royalGold.withValues(alpha: 0.15),
            AppTheme.royalGold.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.royalGold.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _activeVehicle?['url'] != null
                ? AnimatedVehiclePreview(
                    url: _activeVehicle!['url'],
                    type: _activeVehicle!['type'] ?? 'gif',
                    fit: BoxFit.cover,
                  )
                : const Icon(Icons.directions_car,
                    color: AppTheme.royalGold, size: 35),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'المركبة النشطة',
                      style: TextStyle(
                        color: AppTheme.royalGold,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.royalGold,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'VIP',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'مركبة ملكية فاخرة',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyBadge(IconData icon, int amount, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 6),
          Text(
            amount.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  int _parseCurrencyValue(int? primary, dynamic secondary) {
    if (primary != null && primary > 0) return primary;
    if (secondary != null) {
      if (secondary is int) return secondary;
      if (secondary is double) return secondary.toInt();
    }
    return 0;
  }
}
