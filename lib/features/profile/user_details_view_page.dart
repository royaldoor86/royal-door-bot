import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart' as intl;
import 'package:audioplayers/audioplayers.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../models/family_model.dart';
import '../../services/firestore_service.dart';
import '../edit_profile_page.dart';
import '../voice_room_page.dart';
import 'visitors_page.dart';
import 'friends_lists_page.dart';
import '../../features/chat/individual_chat_page.dart';
import 'widgets/rank_badge.dart';
import 'widgets/partner_item.dart';
import 'widgets/gift_item.dart';
import '../../widgets/animated_vehicle_preview.dart';
import '../../app_theme.dart';

class UserDetailsViewPage extends StatefulWidget {
  final UserModel user;
  const UserDetailsViewPage({super.key, required this.user});

  @override
  State<UserDetailsViewPage> createState() => _UserDetailsViewPageState();
}

class _UserDetailsViewPageState extends State<UserDetailsViewPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _frameController;
  late AnimationController _pulseController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  bool _isFollowing = false;
  bool _isFriend = false;
  bool _hasPendingRequest = false;
  bool _isPlayingVoice = false;
  bool _incomingFriendRequest = false;
  double _sheetPosition = 0.4;

  FamilyModel? _userFamily;
  List<UserModel> _partners = [];
  List<Map<String, dynamic>> _userBadges = [];
  List<Map<String, dynamic>> _userGifts = [];
  List<Map<String, dynamic>> _userVehicles = [];
  int _visitorsCount = 0;
  bool _hasActiveRoom = false;

  final FirestoreService _firestoreService = FirestoreService();
  StreamSubscription<QuerySnapshot>? _incomingRequestSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _frameController =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat();
    _pulseController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);

    _loadRealData();

    if (_currentUserId.isNotEmpty) {
      try {
        _firestoreService.recordProfileVisit(_currentUserId, widget.user.uid);
      } catch (e) {
        debugPrint('Error recording profile visit: $e');
      }
    }

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlayingVoice = state == PlayerState.playing);
      }
    });

    _subscribeToIncomingRequests();
    _checkUserRoomStatus();
  }

  Future<void> _loadRealData() async {
    _checkFollowingStatus();
    _checkFriendshipStatus();
    await Future.wait([
      _fetchFamily(),
      _fetchPartners(),
      _fetchBadgesGiftsAndVehicles(),
      _fetchVisitorsCount(),
    ]);
  }

  Future<void> _checkUserRoomStatus() async {
    try {
      final roomSnap = await FirebaseFirestore.instance
          .collection('rooms')
          .where('ownerId', isEqualTo: widget.user.uid)
          .get();
      if (mounted) setState(() => _hasActiveRoom = roomSnap.docs.isNotEmpty);
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  void _checkFollowingStatus() {
    if (_currentUserId.isNotEmpty) {
      setState(() {
        _isFollowing = widget.user.followers.contains(_currentUserId);
      });
    }
  }

  Future<void> _checkFriendshipStatus() async {
    if (_currentUserId.isEmpty || widget.user.uid == _currentUserId) return;
    setState(() {
      _isFriend = widget.user.friends.contains(_currentUserId);
    });
    if (!_isFriend) {
      final requestDoc = await FirebaseFirestore.instance
          .collection('friendRequests')
          .doc('${_currentUserId}_${widget.user.uid}')
          .get();
      if (mounted) setState(() => _hasPendingRequest = requestDoc.exists);
    }
  }

  Future<void> _fetchFamily() async {
    if (widget.user.familyId != null && widget.user.familyId!.isNotEmpty) {
      try {
        final familyDoc = await FirebaseFirestore.instance
            .collection('families')
            .doc(widget.user.familyId)
            .get();
        if (familyDoc.exists && mounted) {
          setState(() => _userFamily = FamilyModel.fromFirestore(familyDoc));
        }
      } catch (e) {
        debugPrint("Error fetching family: $e");
      }
    }
  }

  Future<void> _fetchPartners() async {
    if (widget.user.friends.isNotEmpty) {
      try {
        final partnerIds = widget.user.friends.take(4).toList();
        final partnersSnap = await FirebaseFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: partnerIds)
            .get();
        if (mounted) {
          setState(() {
            _partners = partnersSnap.docs
                .map((doc) => UserModel.fromMap(doc.data(), doc.id))
                .toList();
          });
        }
      } catch (e) {
        debugPrint("Error fetching partners: $e");
      }
    }
  }

  Future<void> _fetchBadgesGiftsAndVehicles() async {
    try {
      final badgesSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .collection('badges')
          .get();
      final giftsSnap = await FirebaseFirestore.instance
          .collection('sent_gifts')
          .where('receiverId', isEqualTo: widget.user.uid)
          .get();
      final inventorySnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .collection('inventory')
          .where('type', isEqualTo: 'vehicle')
          .get();

      if (mounted) {
        setState(() {
          _userBadges = badgesSnap.docs.map((d) => d.data()).toList();
          _userVehicles = inventorySnap.docs.map((d) => d.data()).toList();
          Map<String, Map<String, dynamic>> groupedGifts = {};
          for (var doc in giftsSnap.docs) {
            final data = doc.data();
            final giftId = data['giftId'];
            if (groupedGifts.containsKey(giftId)) {
              groupedGifts[giftId]!['count'] =
                  (groupedGifts[giftId]!['count'] ?? 0) + (data['count'] ?? 1);
            } else {
              groupedGifts[giftId] = {
                'name': data['giftName'],
                'imageUrl': data['giftImage'],
                'count': data['count'] ?? 1
              };
            }
          }
          _userGifts = groupedGifts.values.toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching radiance data: $e");
    }
  }

  Future<void> _fetchVisitorsCount() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .collection('visitors')
          .get();
      if (mounted) setState(() => _visitorsCount = snap.docs.length);
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> _toggleFollow() async {
    if (_currentUserId.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() => _isFollowing = !_isFollowing);
    try {
      await _firestoreService.toggleFollow(_currentUserId, widget.user.uid);
    } catch (e) {
      if (mounted) setState(() => _isFollowing = !_isFollowing);
    }
  }

  Future<void> _handleFriendAction() async {
    if (_currentUserId.isEmpty || widget.user.uid == _currentUserId) return;
    HapticFeedback.lightImpact();
    try {
      if (_isFriend) {
        final batch = FirebaseFirestore.instance.batch();
        batch.update(
            FirebaseFirestore.instance.collection('users').doc(_currentUserId),
            {
              'friends': FieldValue.arrayRemove([widget.user.uid])
            });
        batch.update(
            FirebaseFirestore.instance.collection('users').doc(widget.user.uid),
            {
              'friends': FieldValue.arrayRemove([_currentUserId])
            });
        await batch.commit();
        if (mounted) setState(() => _isFriend = false);
        return;
      }
      if (_hasPendingRequest) {
        final docRef = FirebaseFirestore.instance
            .collection('friendRequests')
            .doc('${_currentUserId}_${widget.user.uid}');
        final doc = await docRef.get();
        if (doc.exists) await docRef.delete();
        if (mounted) setState(() => _hasPendingRequest = false);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إلغاء طلب الصداقة')));
        return;
      }
      if (_incomingFriendRequest) {
        final incomingSnap = await FirebaseFirestore.instance
            .collection('friendRequests')
            .where('senderId', isEqualTo: widget.user.uid)
            .where('receiverId', isEqualTo: _currentUserId)
            .where('status', isEqualTo: 'pending')
            .limit(1)
            .get();
        if (incomingSnap.docs.isNotEmpty) {
          final reqDoc = incomingSnap.docs.first;
          await _firestoreService.acceptFriendRequest(
              reqDoc.id, widget.user.uid, _currentUserId);
          if (mounted) {
            setState(() {
              _isFriend = true;
              _incomingFriendRequest = false;
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم قبول طلب الصداقة')));
        } else {
          await _sendFriendRequest();
        }
        return;
      }
      await _sendFriendRequest();
    } catch (e) {
      debugPrint("Error handling friend action: $e");
    }
  }

  Future<void> _sendFriendRequest() async {
    setState(() => _hasPendingRequest = true);
    try {
      await _firestoreService.sendFriendRequest(
          _currentUserId, widget.user.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إرسال طلب الصداقة 🚀')));
      }
    } catch (e) {
      if (mounted) setState(() => _hasPendingRequest = false);
    }
  }

  void _subscribeToIncomingRequests() {
    if (_currentUserId.isEmpty || widget.user.uid == _currentUserId) return;
    try {
      _incomingRequestSub = FirebaseFirestore.instance
          .collection('friendRequests')
          .where('receiverId', isEqualTo: _currentUserId)
          .where('senderId', isEqualTo: widget.user.uid)
          .where('status', isEqualTo: 'pending')
          .snapshots()
          .listen((snap) {
        if (mounted) {
          setState(() {
            _incomingFriendRequest = snap.docs.isNotEmpty;
          });
        }
      });
    } catch (e) {
      debugPrint("Error subscribing to incoming requests: $e");
    }
  }

  Future<void> _playVoiceBio() async {
    if (widget.user.voiceBioUrl == null || widget.user.voiceBioUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يوجد تسجيل صوتی لهذا المستخدم')));
      return;
    }
    HapticFeedback.selectionClick();
    if (_isPlayingVoice) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(UrlSource(widget.user.voiceBioUrl!));
    }
  }

  Future<void> _navigateToUserRoom() async {
    HapticFeedback.heavyImpact();
    try {
      final roomSnap = await FirebaseFirestore.instance
          .collection('rooms')
          .where('ownerId', isEqualTo: widget.user.uid)
          .limit(1)
          .get();
      if (roomSnap.docs.isNotEmpty) {
        final roomData = roomSnap.docs.first.data();
        if (mounted) {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => VoiceRoomPage(
                      roomId: roomSnap.docs.first.id,
                      roomName: roomData['name'] ?? 'غرفة ملكية',
                      roomImage: roomData['imageUrl'])));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('المستخدم لا يملك غرفة نشطة حالياً 🏠')));
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> _togglePostLike(PostModel post) async {
    if (_currentUserId.isEmpty) return;
    HapticFeedback.lightImpact();
    final postRef = FirebaseFirestore.instance.collection('posts').doc(post.id);
    final isLiked = post.likes.contains(_currentUserId);
    try {
      if (isLiked) {
        await postRef.update({
          'likes': FieldValue.arrayRemove([_currentUserId])
        });
      } else {
        await postRef.update({
          'likes': FieldValue.arrayUnion([_currentUserId])
        });
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  void _showProfileOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 25),
        decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 8),
            ListTile(
                leading: const Icon(Icons.block, color: Colors.redAccent),
                title: const Text('حظر المستخدم',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _firestoreService.blockUser(_currentUserId, widget.user.uid);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم حظر المستخدم')));
                }),
            ListTile(
                leading: const Icon(Icons.report_problem,
                    color: Colors.orangeAccent),
                title: const Text('إبلاغ عن الحساب',
                    style: TextStyle(color: Colors.white)),
                onTap: () async {
                  Navigator.pop(context);
                  await _firestoreService.reportEntity(
                    reporterId: _currentUserId,
                    targetId: widget.user.uid,
                    type: 'user',
                    reason: 'Account reporting from profile',
                    content: 'User: ${widget.user.name}',
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('تم إرسال البلاغ للإدارة للمراجعة 🛡️')));
                  }
                }),
            ListTile(
                leading: const Icon(Icons.share, color: AppTheme.royalGold),
                title: const Text('مشاركة البروفايل',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _shareProfile();
                }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _shareProfile() {
    HapticFeedback.mediumImpact();
    Share.share(
        'شاهد هذا البروفايل الملكي على رويال دور: ${widget.user.name}\nID: ${widget.user.royalId}');
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    if (difference.inMinutes < 5) return 'نشط الآن';
    if (difference.inHours < 1) return 'منذ ${difference.inMinutes} دقيقة';
    if (difference.inHours < 24) return 'منذ ${difference.inHours} ساعة';
    return intl.DateFormat('yyyy-MM-dd').format(lastSeen);
  }

  int _calculateAge(DateTime? birthDate) {
    if (birthDate == null) return 0;
    DateTime today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _frameController.dispose();
    _pulseController.dispose();
    _audioPlayer.dispose();
    _incomingRequestSub?.cancel();
    super.dispose();
  }

  void _copyRoyalId(String id) {
    HapticFeedback.vibrate();
    Clipboard.setData(ClipboardData(text: id));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('تم نسخ الآيدي الملكي: $id ✅'),
        backgroundColor: const Color(0xFF042F2C),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))));
  }

  Future<void> _handleProfileLike() async {
    if (_currentUserId.isEmpty || _currentUserId == widget.user.uid) return;
    HapticFeedback.mediumImpact();
    await _firestoreService.toggleProfileLike(_currentUserId, widget.user.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF020617),
        body: Stack(
          children: [
            _buildHeaderImage(),
            _buildDraggableContent(),
            _buildFloatingInfoBar(),
            _buildTopButtons(),
            _buildBottomActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderImage() {
    double scale = 1.0 + (0.4 - _sheetPosition).clamp(0.0, 0.1) * 1.5;
    double verticalOffset = (_sheetPosition - 0.4).clamp(0.0, 0.55) * -220;
    double blurValue = ((_sheetPosition - 0.4) / 0.55).clamp(0.0, 1.0) * 12.0;
    double darkness = ((_sheetPosition - 0.4) / 0.55).clamp(0.0, 1.0) * 0.3;

    return Stack(
      children: [
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..translate(0.0, verticalOffset)
            ..scale(scale),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.55,
            width: double.infinity,
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: widget.user.profilePic.isNotEmpty
                        ? NetworkImage(widget.user.profilePic)
                        : const AssetImage(
                                'assets/images/avatar_placeholder.png')
                            as ImageProvider,
                    fit: BoxFit.cover)),
            child: ClipRRect(
                child: BackdropFilter(
                    filter:
                        ImageFilter.blur(sigmaX: blurValue, sigmaY: blurValue),
                    child: Container(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                          Colors.black.withValues(
                              alpha: (0.3 + darkness).clamp(0.0, 1.0)),
                          Colors.transparent,
                          Colors.black.withValues(
                              alpha: (0.7 + (darkness * 0.5)).clamp(0.0, 1.0))
                        ]))))),
          ),
        ),
        if (widget.user.activeVehicleUrl != null)
          Positioned.fill(
              child: Opacity(
                  opacity: 0.5,
                  child: AnimatedVehiclePreview(
                      url: widget.user.activeVehicleUrl!,
                      type: widget.user.activeVehicleType ?? 'gif',
                      fit: BoxFit.cover))),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.18,
          right: 20,
          child: Stack(
            alignment: Alignment.center,
            children: [
              RotationTransition(
                  turns: _frameController,
                  child: Container(
                      width: 105,
                      height: 105,
                      decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(colors: [
                            Colors.amber,
                            Colors.orange,
                            Colors.red,
                            Colors.purple,
                            Colors.blue,
                            Colors.green,
                            Colors.amber
                          ])))),
              Container(
                  width: 95,
                  height: 95,
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                  child: CircleAvatar(
                      radius: 45,
                      backgroundImage: widget.user.profilePic.isNotEmpty
                          ? NetworkImage(widget.user.profilePic)
                          : const AssetImage(
                                  'assets/images/avatar_placeholder.png')
                              as ImageProvider)),
              if (widget.user.accountLevel > 20)
                const Positioned(
                    top: -5,
                    child: Icon(Icons.workspace_premium,
                        color: Colors.amber, size: 30)),
            ],
          ),
        ),
        if (_hasActiveRoom)
          Positioned(
            top: MediaQuery.of(context).size.height * 0.21,
            left: 20,
            child: GestureDetector(
              onTap: _navigateToUserRoom,
              child: ScaleTransition(
                scale: Tween(begin: 1.0, end: 1.08).animate(CurvedAnimation(
                    parent: _pulseController, curve: Curves.easeInOut)),
                child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [Color(0xFFFF0080), Color(0xFFFF4DAB)]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFFFF0080)
                                  .withValues(alpha: 0.4),
                              blurRadius: 15,
                              spreadRadius: 2)
                        ]),
                    child: const Row(children: [
                      Icon(Icons.live_tv, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('في الغرفة الآن',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13))
                    ])),
              ),
            ),
          ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.27,
          left: 20,
          child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                int charm = widget.user.charm;
                bool isLiked = false;
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  charm = data['charm'] ?? 0;
                  isLiked =
                      (data['profileLikes'] ?? []).contains(_currentUserId);
                }
                return GestureDetector(
                  onTap: _handleProfileLike,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: isLiked
                                ? [Colors.red, Colors.pinkAccent]
                                : [
                                    const Color(0xFFFFD540),
                                    const Color(0xFFFFA500)
                                  ]),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 1),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 8)
                        ]),
                    child: Row(children: [
                      Icon(isLiked ? Icons.favorite : Icons.thumb_up,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                          (widget.user.privilegeSettings['hide_charm'] ?? false)
                              ? '***'
                              : '$charm',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12))
                    ]),
                  ),
                );
              }),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.44,
          left: 0,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildModernMiniBadge(widget.user.nobleLevel, Colors.blueGrey,
                    Icons.workspace_premium),
                _buildModernMiniBadge('LV.${widget.user.accountLevel}',
                    Colors.amber, Icons.emoji_events),
                _buildModernMiniBadge(
                    '${widget.user.charm}', Colors.pink, Icons.favorite),
                _buildModernMiniBadge(
                    '${widget.user.contribution}', Colors.orange, Icons.shield),
                _buildModernMiniBadge('Presenter', Colors.teal, Icons.mic),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernMiniBadge(String label, Color color, IconData icon) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(height: 4),
      Text(label,
          style: const TextStyle(
              color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))
    ]);
  }

  Widget _buildFloatingInfoBar() {
    double bottomOffset = MediaQuery.of(context).size.height * _sheetPosition;
    return Positioned(
      bottom: bottomOffset + 5,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 45,
            height: 5,
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 5)
                ]),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1))),
                  child: Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              const Icon(Icons.copy_all_outlined,
                                  color: Colors.white70, size: 16),
                              const SizedBox(width: 6),
                              GestureDetector(
                                  onTap: () =>
                                      _copyRoyalId(widget.user.royalId),
                                  child: Text('ID:${widget.user.royalId}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14))),
                              if (!(widget
                                      .user.privilegeSettings['hide_country'] ??
                                  false)) ...[
                                const SizedBox(width: 12),
                                const Text('|',
                                    style: TextStyle(color: Colors.white24)),
                                const SizedBox(width: 12),
                                Text(
                                    widget.user.country.isNotEmpty
                                        ? widget.user.country
                                        : 'المملكة',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 13)),
                              ],
                              const SizedBox(width: 12),
                              const Text('|',
                                  style: TextStyle(color: Colors.white24)),
                              const SizedBox(width: 12),
                              Text('المشجعون: ${widget.user.followers.length}',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.greenAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10)),
                        child: StreamBuilder<DocumentSnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(widget.user.uid)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Text('نشط الآن',
                                    style: TextStyle(
                                        color: Colors.greenAccent,
                                        fontSize: 11));
                              }
                              final lastActive = (snapshot.data!.data()
                                  as Map?)?['lastActive'] as Timestamp?;
                              return Text(
                                  lastActive != null
                                      ? _formatLastSeen(lastActive.toDate())
                                      : 'نشط الآن',
                                  style: const TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold));
                            }),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopButtons() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context)),
            Row(children: [
              const Icon(Icons.mic, color: Colors.white70, size: 18),
              const SizedBox(width: 6),
              Text(widget.user.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              if (widget.user.activeBadge != null) ...[
                const SizedBox(width: 5),
                _buildActiveBadgeDisplay(widget.user.activeBadge!)
              ],
              if (widget.user.isVerified)
                const Padding(
                    padding: EdgeInsets.only(right: 5),
                    child: Icon(Icons.verified, color: Colors.blue, size: 20)),
              const SizedBox(width: 10),
              if (widget.user.uid == _currentUserId)
                IconButton(
                    icon: const Icon(Icons.edit_note,
                        color: Colors.white, size: 30),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const EditProfilePage()));
                    }),
              IconButton(
                  icon: const Icon(Icons.more_vert,
                      color: Colors.white, size: 25),
                  onPressed: _showProfileOptions),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveBadgeDisplay(String activeBadge) {
    if (activeBadge.startsWith('http')) {
      return CachedNetworkImage(
          imageUrl: activeBadge, width: 22, height: 22, fit: BoxFit.contain);
    }
    return Text(activeBadge, style: const TextStyle(fontSize: 18));
  }

  Widget _buildDraggableContent() {
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        setState(() => _sheetPosition = notification.extent);
        return true;
      },
      child: DraggableScrollableSheet(
        initialChildSize: 0.4,
        minChildSize: 0.38,
        maxChildSize: 0.95,
        snap: true,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
            child: CustomScrollView(
              controller: scrollController,
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 25),
                      _buildStatsBar(),
                      _buildBioHeader(),
                      _buildTabBar(),
                    ],
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 150),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (_tabController.index == 0)
                        _buildProfileTab()
                      else if (_tabController.index == 1)
                        _buildRadianceTab()
                      else
                        _buildMomentsTab(),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(
              child: _statItem(
                  'الزوار',
                  '$_visitorsCount',
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const VisitorsPage())))),
          Expanded(
              child: _statItem(
                  'الأصدقاء',
                  '${widget.user.friends.length}',
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const FriendsListsPage())))),
          Expanded(
              child: _statItem(
                  'المتابعة',
                  '${widget.user.following.length}',
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const FriendsListsPage())))),
          Expanded(
              child: _statItem(
                  'المعجبون',
                  '${widget.user.followers.length}',
                  () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const FriendsListsPage())))),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, VoidCallback onTap) {
    return GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Column(children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.white38),
              overflow: TextOverflow.ellipsis)
        ]));
  }

  Widget _buildBioHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(
              child: Text(
                  widget.user.bio.isNotEmpty
                      ? widget.user.bio
                      : "لا يوجد توقيع حالياً لمواطن رويال دور",
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 14, height: 1.5))),
          const SizedBox(width: 12),
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                  color: widget.user.gender == 'ذكر'
                      ? Colors.blue.withValues(alpha: 0.3)
                      : Colors.pink.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(15)),
              child: Row(children: [
                Icon(widget.user.gender == 'ذكر' ? Icons.male : Icons.female,
                    color: Colors.white, size: 14),
                const SizedBox(width: 6),
                Text('${_calculateAge(widget.user.birthDate)}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold))
              ])),
        ]),
        if (widget.user.zodiac.isNotEmpty)
          Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text('البرج الفلكي: ${widget.user.zodiac}',
                  style: const TextStyle(
                      color: AppTheme.royalGold,
                      fontSize: 12,
                      fontWeight: FontWeight.bold))),
        const SizedBox(height: 15),
        Row(children: [
          const Text('LV.',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                  fontSize: 12)),
          Text('${widget.user.userLevel}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 12)),
          const SizedBox(width: 12),
          Expanded(
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                      value: (widget.user.userLevel % 100) / 100,
                      backgroundColor: Colors.white10,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.amber),
                      minHeight: 8))),
          const SizedBox(width: 12),
          Text('${((widget.user.userLevel % 100) / 100 * 100).toInt()}%',
              style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }

  TabBar _buildTabBar() {
    return TabBar(
        controller: _tabController,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white38,
        indicatorColor: AppTheme.royalGold,
        indicatorSize: TabBarIndicatorSize.label,
        indicatorWeight: 4,
        tabs: const [
          Tab(text: 'ملف التعريف'),
          Tab(text: 'تألق'),
          Tab(text: 'لحظات')
        ]);
  }

  Widget _buildProfileTab() {
    return Column(
      children: [
        Padding(
            padding: const EdgeInsets.all(20),
            child: _buildSectionHeader('العائلة الملكية', '')),
        _buildFamilyBanner(),
        Padding(
            padding: const EdgeInsets.all(20),
            child: _buildSectionHeader('آخر الزوار', '')),
        _buildRecentVisitors(),
        Padding(
            padding: const EdgeInsets.all(20),
            child: _buildSectionHeader('معلومات واهتمامات', '')),
        Center(
            child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: widget.user.tags.isNotEmpty
                    ? widget.user.tags.map((tag) => _buildTagChip(tag)).toList()
                    : [_buildTagChip('لم يتم اختيار اهتمامات ⚖️')])),
        Padding(
            padding: const EdgeInsets.all(20),
            child: _buildSectionHeader('البصمة الصوتية', '')),
        _buildVoiceBioWidget(),
        const SizedBox(height: 25),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildSectionHeader('شركائي المقربون', '')),
        _buildPartnersWidget(),
      ],
    );
  }

  Widget _buildVoiceBioWidget() {
    return GestureDetector(
      onTap: _playVoiceBio,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
        child: Row(children: [
          Icon(
              _isPlayingVoice
                  ? Icons.pause_circle_filled
                  : Icons.play_circle_fill,
              color: AppTheme.royalGold,
              size: 35),
          const SizedBox(width: 12),
          Expanded(
              child: Row(
                  children: List.generate(
                      25,
                      (index) => Expanded(
                          child: Container(
                              height: (index % 5 + 1) * 4.0,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                  color: AppTheme.royalGold.withValues(
                                      alpha: _isPlayingVoice ? 0.8 : 0.2),
                                  borderRadius: BorderRadius.circular(2))))))),
          const SizedBox(width: 10),
          const Text('استمع',
              style: TextStyle(
                  color: AppTheme.royalGold,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  Widget _buildPartnersWidget() {
    if (_partners.isEmpty) {
      return const Center(
          child: Padding(
              padding: EdgeInsets.all(20),
              child: Text('لا يوجد شركاء منضمين حالياً',
                  style: TextStyle(color: Colors.white38, fontSize: 13))));
    }
    return SizedBox(
        height: 120,
        child: Stack(children: [
          CustomPaint(
              size: const Size(double.infinity, 120),
              painter: RelationshipLinesPainter()),
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _partners.map((p) => PartnerItem(partner: p)).toList())
        ]));
  }

  Widget _buildRadianceTab() {
    return Column(
      children: [
        Padding(
            padding: const EdgeInsets.all(20),
            child: _buildSectionHeader('اللقب الملكي الشرفي', 'تغيير')),
        Center(
            child: RankBadge(
                label: widget.user.honoraryTitle ??
                    widget.user.familyRole ??
                    'عضو ملكي',
                color: Colors.white12,
                icon: Icons.military_tech_rounded)),
        Padding(
            padding: const EdgeInsets.all(20),
            child: _buildSectionHeader(
                'أوسمة الاستحقاق (${_userBadges.length})', 'رؤية الكل')),
        if (_userBadges.isEmpty)
          const Center(
              child: Text('لا توجد أوسمة مكتسبة حتى الآن',
                  style: TextStyle(color: Colors.white38, fontSize: 13)))
        else
          GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, mainAxisSpacing: 12, crossAxisSpacing: 12),
              itemCount: _userBadges.length,
              itemBuilder: (context, index) => GiftItem(
                  index: index,
                  icon: Icons.workspace_premium,
                  color: Colors.amber,
                  name: _userBadges[index]['name'] ?? 'وسام رويال',
                  onTap: () => _showGiftDetails(
                      _userBadges[index]['name'] ?? 'وسام رويال',
                      Colors.amber))),
        Padding(
            padding: const EdgeInsets.all(20),
            child: _buildSectionHeader(
                'المركبات الخاصة (${_userVehicles.length})', 'إدارة المتجر')),
        if (_userVehicles.isEmpty)
          const Center(
              child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('لا توجد مركبات ملكية مملوكة حالياً',
                      style: TextStyle(color: Colors.white38, fontSize: 13))))
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                childAspectRatio: 0.8),
            itemCount: _userVehicles.length,
            itemBuilder: (context, index) {
              final v = _userVehicles[index];
              return GestureDetector(
                onTap: () =>
                    _showGiftDetails(v['name'] ?? 'مركبة ملكية', Colors.amber),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.amber.withValues(alpha: 0.1)),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: AnimatedVehiclePreview(
                            url: v['imageUrl'] ?? '',
                            type: v['vehicleType'] ?? 'gif',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(v['name'] ?? 'مركبة',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        Padding(
            padding: const EdgeInsets.all(20),
            child: _buildSectionHeader(
                'هدايا الغرف (${_userGifts.length})', 'رؤية الكل')),
        if (_userGifts.isEmpty)
          const Center(
              child: Text('لم يتم استلام هدايا ملكية بعد',
                  style: TextStyle(color: Colors.white38, fontSize: 13)))
        else
          GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85),
              itemCount: _userGifts.length,
              itemBuilder: (context, index) => GiftItem(
                  index: index,
                  imageUrl: _userGifts[index]['imageUrl'],
                  icon: Icons.card_giftcard,
                  color: Colors.pinkAccent,
                  name: _userGifts[index]['name'] ?? 'هدية',
                  count: _userGifts[index]['count'] ?? 1,
                  onTap: () => _showGiftDetails(
                      _userGifts[index]['name'] ?? 'هدية', Colors.pinkAccent))),
      ],
    );
  }

  Widget _buildMomentsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .where('authorId', isEqualTo: widget.user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.royalGold));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text('لا توجد لحظات ملكية مسجلة',
                  style: TextStyle(color: Colors.white38, fontSize: 13)));
        }
        final posts = snapshot.data!.docs
            .map((doc) =>
                PostModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();
        return Column(
            children: posts
                .map((post) => Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    child: _buildMomentCard(post)))
                .toList());
      },
    );
  }

  Widget _buildRecentVisitors() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .collection('visitors')
          .orderBy('timestamp', descending: true)
          .limit(6)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text('لا يوجد زوار مؤخراً',
                  style: TextStyle(color: Colors.white38, fontSize: 12)));
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
              children: docs
                  .map((doc) => FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(doc.id)
                          .get(),
                      builder: (context, userSnap) {
                        if (!userSnap.hasData) return const SizedBox.shrink();
                        final pic =
                            (userSnap.data!.data() as Map?)?['profilePic'] ??
                                '';
                        return Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: CircleAvatar(
                                radius: 22,
                                backgroundColor: Colors.white10,
                                backgroundImage:
                                    pic.isNotEmpty ? NetworkImage(pic) : null,
                                child: pic.isEmpty
                                    ? const Icon(Icons.person,
                                        size: 20, color: Colors.white38)
                                    : null));
                      }))
                  .toList()),
        );
      },
    );
  }

  Widget _buildFamilyBanner() {
    if (_userFamily == null) {
      return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
          child: const Center(
              child: Text('لم ينضم لعائلة ملكية بعد',
                  style: TextStyle(color: Colors.white38, fontSize: 13))));
    }
    return Container(
        height: 110,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 10)],
            gradient: const LinearGradient(
                colors: [Color(0xFF4C1D95), Color(0xFF1E293B)])),
        child: Stack(children: [
          Positioned(
              right: 20,
              top: 0,
              bottom: 0,
              child: Row(children: [
                Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_userFamily!.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18)),
                      const Text('عائلة رويال المعتمدة',
                          style: TextStyle(color: Colors.white70, fontSize: 10))
                    ]),
                const SizedBox(width: 20),
                Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: Colors.white10, shape: BoxShape.circle),
                    child: CircleAvatar(
                        radius: 38,
                        backgroundImage: _userFamily!.logoUrl.isNotEmpty
                            ? NetworkImage(_userFamily!.logoUrl)
                            : const AssetImage(
                                    'assets/images/avatar_placeholder.png')
                                as ImageProvider))
              ])),
          Positioned(
              left: 20,
              top: 0,
              bottom: 0,
              child: Center(
                  child: Row(children: [
                const Icon(Icons.group, color: Colors.white, size: 18),
                const SizedBox(width: 5),
                Text('${_userFamily!.memberCount}/${_userFamily!.maxMembers}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold))
              ])))
        ]));
  }

  void _showGiftDetails(String name, Color color) {
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
            padding: const EdgeInsets.all(25),
            decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  height: 5,
                  width: 40,
                  decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(5))),
              const SizedBox(height: 25),
              Icon(Icons.card_giftcard, color: color, size: 90),
              const SizedBox(height: 20),
              Text(name,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 12),
              const Text(
                  'هذا العنصر الملكي يمنح صاحبه هيبة ومكانة عالية داخل المملكة ويزيد من مستوى التألق.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, height: 1.5)),
              const SizedBox(height: 30),
              ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      minimumSize: const Size(double.infinity, 55),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30))),
                  child: const Text('إغلاق التفاصيل',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)))
            ])));
  }

  Widget _buildSectionHeader(String title, String trailing) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(title,
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
      if (trailing.isNotEmpty)
        GestureDetector(
            onTap: () => HapticFeedback.lightImpact(),
            child: Row(children: [
              Text(trailing,
                  style: const TextStyle(
                      color: AppTheme.royalGold,
                      fontSize: 13,
                      fontWeight: FontWeight.bold)),
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios,
                  size: 10, color: AppTheme.royalGold)
            ]))
    ]);
  }

  Widget _buildMomentCard(PostModel post) {
    final bool isLiked = post.likes.contains(_currentUserId);
    return Card(
      margin: const EdgeInsets.only(bottom: 18),
      elevation: 0,
      color: Colors.white.withValues(alpha: 0.03),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ListTile(
            leading: CircleAvatar(
                backgroundImage: post.authorPic.isNotEmpty
                    ? NetworkImage(post.authorPic)
                    : null),
            title: Row(children: [
              Text(post.authorName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white)),
              const SizedBox(width: 10),
              RankBadge(
                  label: '${widget.user.charm}',
                  color: Colors.pink,
                  icon: Icons.favorite)
            ]),
            subtitle: Text(
                intl.DateFormat('yyyy-MM-dd HH:mm').format(post.createdAt),
                style: const TextStyle(fontSize: 11, color: Colors.white38))),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
            child: Text(post.content,
                style: const TextStyle(color: Colors.white70, height: 1.4))),
        if (post.imageUrl != null)
          Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(post.imageUrl!,
                      width: double.infinity, fit: BoxFit.cover))),
        Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              GestureDetector(
                  onTap: () => _togglePostLike(post),
                  child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                          color: isLiked
                              ? Colors.red.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(15)),
                      child: Row(children: [
                        Icon(isLiked ? Icons.favorite : Icons.favorite_border,
                            size: 20,
                            color: isLiked ? Colors.red : Colors.white38),
                        const SizedBox(width: 6),
                        Text('${post.likes.length}',
                            style: TextStyle(
                                color: isLiked ? Colors.red : Colors.white38,
                                fontWeight: FontWeight.bold))
                      ]))),
              const SizedBox(width: 15),
              GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('ميزة التعليقات قيد التطوير الملكي ✍️')));
                  },
                  child: Row(children: [
                    const Icon(Icons.chat_bubble_outline,
                        size: 20, color: Colors.white38),
                    const SizedBox(width: 6),
                    Text('${post.commentCount}',
                        style: const TextStyle(
                            color: Colors.white38, fontWeight: FontWeight.bold))
                  ])),
              const Spacer(),
              IconButton(
                  icon: const Icon(Icons.report_gmailerrorred_rounded,
                      size: 20, color: Colors.white38),
                  onPressed: () async {
                    await _firestoreService.reportEntity(
                      reporterId: _currentUserId,
                      targetId: post.id,
                      type: 'post',
                      reason: 'Inappropriate content in Moments',
                      content: post.content,
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('تم إرسال بلاغ عن هذا المنشور 🛡️')));
                    }
                  }),
              IconButton(
                  icon: const Icon(Icons.share_outlined,
                      size: 20, color: Colors.white38),
                  onPressed: _shareProfile)
            ]))
      ]),
    );
  }

  Widget _buildTagChip(String label) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
        child: Text(label,
            style: const TextStyle(
                fontSize: 13,
                color: Colors.white70,
                fontWeight: FontWeight.w500)));
  }

  Widget _buildBottomActionButtons() {
    if (widget.user.uid == _currentUserId) return const SizedBox.shrink();
    return Positioned(
      bottom: 40,
      left: 20,
      right: 20,
      child: Row(children: [
        if (_isFriend) ...[
          Expanded(
              child: ElevatedButton.icon(
                  onPressed: () async {
                    if (_currentUserId.isEmpty) return;
                    try {
                      final roomId =
                          await _firestoreService.ensureChatRoomExists(
                              _currentUserId, widget.user.uid);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => IndividualChatPage(
                                  otherUser: widget.user, roomId: roomId)));
                    } catch (e) {
                      debugPrint('Error opening chat from profile: $e');
                    }
                  },
                  icon: const Icon(Icons.chat, color: Colors.white),
                  label: const Text('مراسلة',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4C1D95),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30))))),
          const SizedBox(width: 12),
        ],
        Expanded(
            child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: ElevatedButton.icon(
                    key: ValueKey(_isFriend),
                    onPressed: _handleFriendAction,
                    icon: Icon(
                        _isFriend
                            ? Icons.people
                            : (_hasPendingRequest
                                ? Icons.hourglass_top
                                : Icons.person_add_alt_1),
                        color: Colors.white),
                    label: Text(
                        _isFriend
                            ? 'صديق ملكي'
                            : (_hasPendingRequest ? 'قيد الطلب' : 'إضافة صديق'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _isFriend
                            ? Colors.blueGrey.withValues(alpha: 0.5)
                            : (_hasPendingRequest
                                ? Colors.orange
                                : const Color(0xFF00C853)),
                        elevation: 5,
                        shadowColor: Colors.black26,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape:
                            RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)))))),
        const SizedBox(width: 15),
        Expanded(
            child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: ElevatedButton.icon(
                    key: ValueKey(_isFollowing),
                    onPressed: _toggleFollow,
                    icon: Icon(_isFollowing ? Icons.check : Icons.add,
                        color: Colors.white),
                    label: Text(_isFollowing ? 'متابع' : 'متابعة',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _isFollowing
                            ? Colors.grey.withValues(alpha: 0.5)
                            : const Color(0xFF03A9F4),
                        elevation: 5,
                        shadowColor: Colors.black26,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)))))),
      ]),
    );
  }
}

class RelationshipLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.pinkAccent.withValues(alpha: 0.2)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final path = Path();
    double centerY = 45;
    path.moveTo(size.width * 0.15, centerY);
    path.quadraticBezierTo(
        size.width * 0.5, centerY - 40, size.width * 0.85, centerY);
    canvas.drawPath(path, paint);
    final heartPaint = Paint()
      ..color = Colors.pinkAccent.withValues(alpha: 0.5);
    canvas.drawCircle(Offset(size.width * 0.35, centerY - 15), 3, heartPaint);
    canvas.drawCircle(Offset(size.width * 0.65, centerY - 15), 3, heartPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
