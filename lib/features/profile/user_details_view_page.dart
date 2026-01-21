import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart' as intl;
import 'package:audioplayers/audioplayers.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/user_model.dart';
import '../../models/post_model.dart';
import '../../models/family_model.dart';
import '../edit_profile_page.dart';
import '../voice_room_details_page.dart';
import 'visitors_page.dart';
import 'friends_lists_page.dart';

class UserDetailsViewPage extends StatefulWidget {
  final UserModel user;
  const UserDetailsViewPage({super.key, required this.user});

  @override
  State<UserDetailsViewPage> createState() => _UserDetailsViewPageState();
}

class _UserDetailsViewPageState extends State<UserDetailsViewPage> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _frameController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  
  bool _isFollowing = false;
  bool _isFriend = false;
  bool _hasPendingRequest = false;
  bool _isPlayingVoice = false;
  
  FamilyModel? _userFamily;
  List<UserModel> _partners = [];
  List<Map<String, dynamic>> _userBadges = [];
  List<Map<String, dynamic>> _userGifts = [];
  int _visitorsCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _frameController = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    _loadRealData();
    
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() => _isPlayingVoice = state == PlayerState.playing);
      }
    });
  }

  Future<void> _loadRealData() async {
    _checkFollowingStatus();
    _checkFriendshipStatus();
    await Future.wait([
      _fetchFamily(),
      _fetchPartners(),
      _fetchBadgesAndGifts(),
      _fetchVisitorsCount(),
    ]);
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
          .collection('friend_requests')
          .doc('${_currentUserId}_${widget.user.uid}')
          .get();
      if (mounted) {
        setState(() => _hasPendingRequest = requestDoc.exists);
      }
    }
  }

  Future<void> _fetchFamily() async {
    if (widget.user.familyId != null && widget.user.familyId!.isNotEmpty) {
      try {
        final familyDoc = await FirebaseFirestore.instance.collection('families').doc(widget.user.familyId).get();
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
            _partners = partnersSnap.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList();
          });
        }
      } catch (e) {
        debugPrint("Error fetching partners: $e");
      }
    }
  }

  Future<void> _fetchBadgesAndGifts() async {
    try {
      final badgesSnap = await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).collection('badges').get();
      final giftsSnap = await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).collection('received_gifts').get();
      
      if (mounted) {
        setState(() {
          _userBadges = badgesSnap.docs.map((d) => d.data()).toList();
          _userGifts = giftsSnap.docs.map((d) => d.data()).toList();
        });
      }
    } catch (e) {
      debugPrint("Error fetching badges/gifts: $e");
    }
  }

  Future<void> _fetchVisitorsCount() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).collection('visitors').get();
      if (mounted) {
        setState(() => _visitorsCount = snap.docs.length);
      }
    } catch (e) { debugPrint("Error: $e"); }
  }

  Future<void> _toggleFollow() async {
    if (_currentUserId.isEmpty) return;
    final userRef = FirebaseFirestore.instance.collection('users').doc(widget.user.uid);
    final currentUserRef = FirebaseFirestore.instance.collection('users').doc(_currentUserId);

    setState(() => _isFollowing = !_isFollowing);

    try {
      if (_isFollowing) {
        await userRef.update({'followers': FieldValue.arrayUnion([_currentUserId])});
        await currentUserRef.update({'following': FieldValue.arrayUnion([widget.user.uid])});
      } else {
        await userRef.update({'followers': FieldValue.arrayRemove([_currentUserId])});
        await currentUserRef.update({'following': FieldValue.arrayRemove([widget.user.uid])});
      }
    } catch (e) {
      debugPrint("Error toggling follow: $e");
    }
  }

  Future<void> _handleFriendAction() async {
    if (_currentUserId.isEmpty || widget.user.uid == _currentUserId) return;

    if (_isFriend) {
      _showConfirmDialog('إلغاء الصداقة', 'هل أنت متأكد من حذف ${widget.user.name} من قائمة الأصدقاء؟', () async {
        await FirebaseFirestore.instance.collection('users').doc(_currentUserId).update({'friends': FieldValue.arrayRemove([widget.user.uid])});
        await FirebaseFirestore.instance.collection('users').doc(widget.user.uid).update({'friends': FieldValue.arrayRemove([_currentUserId])});
        setState(() => _isFriend = false);
      });
    } else if (_hasPendingRequest) {
      await FirebaseFirestore.instance.collection('friend_requests').doc('${_currentUserId}_${widget.user.uid}').delete();
      setState(() => _hasPendingRequest = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إلغاء طلب الصداقة')));
    } else {
      setState(() => _hasPendingRequest = true);
      await FirebaseFirestore.instance.collection('friend_requests').doc('${_currentUserId}_${widget.user.uid}').set({'from': _currentUserId, 'to': widget.user.uid, 'status': 'pending', 'timestamp': FieldValue.serverTimestamp()});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال طلب الصداقة 🚀')));
    }
  }

  void _showConfirmDialog(String title, String content, VoidCallback onConfirm) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: Text(title), content: Text(content), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')), TextButton(onPressed: () { Navigator.pop(ctx); onConfirm(); }, child: const Text('تأكيد', style: TextStyle(color: Colors.red)))]));
  }

  Future<void> _playVoiceBio() async {
    if (widget.user.voiceBioUrl == null || widget.user.voiceBioUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يوجد تسجيل صوتی لهذا المستخدم')));
      return;
    }
    if (_isPlayingVoice) { await _audioPlayer.pause(); } else { await _audioPlayer.play(UrlSource(widget.user.voiceBioUrl!)); }
  }

  Future<void> _navigateToUserRoom() async {
    try {
      final roomSnap = await FirebaseFirestore.instance.collection('rooms').where('ownerId', isEqualTo: widget.user.uid).limit(1).get();
      if (roomSnap.docs.isNotEmpty) {
        final roomData = roomSnap.docs.first.data();
        if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => VoiceRoomDetailsPage(roomId: roomSnap.docs.first.id, roomName: roomData['name'] ?? 'غرفة ملكية', roomImage: roomData['imageUrl'])));
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('المستخدم لا يملك غرفة نشطة حالياً 🏠')));
      }
    } catch (e) { debugPrint("Error: $e"); }
  }

  Future<void> _togglePostLike(PostModel post) async {
    if (_currentUserId.isEmpty) return;
    final postRef = FirebaseFirestore.instance.collection('posts').doc(post.id);
    final isLiked = post.likes.contains(_currentUserId);
    try {
      if (isLiked) { await postRef.update({'likes': FieldValue.arrayRemove([_currentUserId])}); } else { await postRef.update({'likes': FieldValue.arrayUnion([_currentUserId])}); }
    } catch (e) { debugPrint("Error: $e"); }
  }

  void _shareProfile() {
    Share.share('شاهد هذا البروفايل الملكي على رويال دور: ${widget.user.name}\nID: ${widget.user.royalId}');
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
    if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) age--;
    return age;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _frameController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _copyRoyalId(String id) {
    Clipboard.setData(ClipboardData(text: id));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم نسخ الآيدي الملكي: $id ✅'), backgroundColor: const Color(0xFF042F2C), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            _buildHeaderImage(),
            _buildDraggableContent(),
            _buildTopButtons(),
            _buildBottomActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderImage() {
    return Stack(
      children: [
        Container(
          height: MediaQuery.of(context).size.height * 0.55,
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: widget.user.profilePic.isNotEmpty ? NetworkImage(widget.user.profilePic) : const AssetImage('assets/images/avatar_placeholder.png') as ImageProvider,
              fit: BoxFit.cover,
            ),
          ),
          child: Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.3), Colors.transparent, Colors.black.withOpacity(0.7)]))),
        ),
        // شارة الشعبية العائمة (كما في الصورة)
        Positioned(
          top: 80,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white, width: 1),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 5)],
            ),
            child: Row(
              children: [
                const Icon(Icons.thumb_up, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text('${widget.user.charm}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.15,
          left: 20,
          child: Stack(
            alignment: Alignment.center,
            children: [
              RotationTransition(
                turns: _frameController,
                child: Container(
                  width: 105, height: 105,
                  decoration: const BoxDecoration(shape: BoxShape.circle, gradient: SweepGradient(colors: [Colors.amber, Colors.orange, Colors.red, Colors.purple, Colors.blue, Colors.green, Colors.amber])),
                ),
              ),
              Container(
                width: 95, height: 95,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: CircleAvatar(radius: 45, backgroundImage: widget.user.profilePic.isNotEmpty ? NetworkImage(widget.user.profilePic) : const AssetImage('assets/images/avatar_placeholder.png') as ImageProvider),
              ),
              if (widget.user.accountLevel > 20) const Positioned(top: -5, child: Icon(Icons.workspace_premium, color: Colors.amber, size: 30)),
            ],
          ),
        ),
        Positioned(
          bottom: MediaQuery.of(context).size.height * 0.42,
          right: 20,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _navigateToUserRoom,
                child: TweenAnimationBuilder(
                  tween: Tween<double>(begin: 1.0, end: 1.1),
                  duration: const Duration(seconds: 1),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFF0080), Color(0xFFFF4DAB)]), borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: const Color(0xFFFF0080).withOpacity(0.4), blurRadius: 15)]),
                        child: const Row(children: [Icon(Icons.home_filled, color: Colors.white, size: 18), SizedBox(width: 5), Text('دخول الغرفة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))]),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildRankBadge('Presenter', Colors.grey.shade400, icon: Icons.mic_external_on),
                    _buildRankBadge('${widget.user.accountLevel}', Colors.amber, icon: Icons.emoji_events),
                    _buildRankBadge('${widget.user.charm}', Colors.pink, icon: Icons.favorite),
                    _buildRankBadge('${widget.user.wealth}', Colors.purple, icon: Icons.diamond),
                    _buildRankBadge('${widget.user.contribution}', Colors.orange, icon: Icons.shield),
                    _buildRankBadge(widget.user.nobleLevel, Colors.blueGrey, isTextOnly: true),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: MediaQuery.of(context).size.height * 0.38,
          right: 20, left: 20,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                color: Colors.white.withOpacity(0.1),
                child: Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            const Icon(Icons.copy_all_outlined, color: Colors.white70, size: 16),
                            const SizedBox(width: 4),
                            GestureDetector(onTap: () => _copyRoyalId(widget.user.royalId), child: Text('ID:${widget.user.royalId}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
                            const SizedBox(width: 10),
                            const Text('|', style: TextStyle(color: Colors.white38)),
                            const SizedBox(width: 10),
                            Text(widget.user.country.isNotEmpty ? widget.user.country : 'المملكة', style: const TextStyle(color: Colors.white, fontSize: 13)),
                            const SizedBox(width: 10),
                            const Text('|', style: TextStyle(color: Colors.white38)),
                            const SizedBox(width: 10),
                            Text('المشجعون: ${widget.user.followers.length}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                      child: StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance.collection('users').doc(widget.user.uid).snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const Text('نشط الآن', style: TextStyle(color: Colors.greenAccent, fontSize: 11));
                          final lastActive = (snapshot.data!.data() as Map?)?['lastActive'] as Timestamp?;
                          return Text(lastActive != null ? _formatLastSeen(lastActive.toDate()) : 'نشط الآن', style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold));
                        }
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRankBadge(String label, Color color, {IconData? icon, bool isTextOnly = false}) {
    return Container(margin: const EdgeInsets.only(left: 4), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: color.withOpacity(0.8), borderRadius: BorderRadius.circular(10)), child: Row(mainAxisSize: MainAxisSize.min, children: [if (icon != null) Icon(icon, color: Colors.white, size: 10), if (icon != null) const SizedBox(width: 2), Text(label, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))]));
  }

  Widget _buildTopButtons() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
            Row(children: [
              const Icon(Icons.mic, color: Colors.white70, size: 18),
              const SizedBox(width: 5),
              Text(widget.user.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              if (widget.user.uid == _currentUserId) IconButton(icon: const Icon(Icons.edit_note, color: Colors.white, size: 28), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilePage()))),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildDraggableContent() {
    return DraggableScrollableSheet(
      initialChildSize: 0.4, minChildSize: 0.38, maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          child: Column(children: [
            _buildStatsBar(), 
            _buildBioHeader(),
            _buildTabBar(),
            Expanded(child: TabBarView(controller: _tabController, children: [_buildProfileTab(scrollController), _buildRadianceTab(scrollController), _buildMomentsTab(scrollController)]))
          ]),
        );
      },
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Expanded(child: _statItem('الزوار', '$_visitorsCount', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisitorsPage())))),
          Expanded(child: _statItem('الأصدقاء', '${widget.user.friends.length}', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendsListsPage())))),
          Expanded(child: _statItem('المتابعة', '${widget.user.following.length}', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendsListsPage())))),
          Expanded(child: _statItem('المعجبون', '${widget.user.followers.length}', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendsListsPage())))),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildBioHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Text(widget.user.bio.isNotEmpty ? widget.user.bio : "لا يوجد توقيع حالياً", textAlign: TextAlign.right, style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.5))),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: widget.user.gender == 'ذكر' ? Colors.blue.shade400 : Colors.pink.shade300, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [Icon(widget.user.gender == 'ذكر' ? Icons.male : Icons.female, color: Colors.white, size: 14), const SizedBox(width: 4), Text('${_calculateAge(widget.user.birthDate)}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))]),
          ),
        ]),
        if (widget.user.zodiac.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('البرج: ${widget.user.zodiac}', style: const TextStyle(color: Colors.blueGrey, fontSize: 12, fontWeight: FontWeight.bold))),
        const SizedBox(height: 10),
        Row(children: [
          Text('LV.${widget.user.userLevel}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber, fontSize: 12)),
          const SizedBox(width: 10),
          Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(5), child: LinearProgressIndicator(value: (widget.user.userLevel % 100) / 100, backgroundColor: Colors.grey.shade200, valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber), minHeight: 6))),
          const SizedBox(width: 10),
          Text('${((widget.user.userLevel % 100) / 100 * 100).toInt()}%', style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ]),
      ]),
    );
  }

  Widget _buildTabBar() {
    return TabBar(controller: _tabController, labelColor: Colors.black, unselectedLabelColor: Colors.grey, indicatorColor: Colors.green, indicatorSize: TabBarIndicatorSize.label, indicatorWeight: 4, tabs: const [Tab(text: 'ملف التعريف'), Tab(text: 'تألق'), Tab(text: 'لحظات')]);
  }

  Widget _buildProfileTab(ScrollController controller) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      children: [
        _buildSectionHeader('العائلة', ''),
        const SizedBox(height: 10),
        _buildFamilyBanner(),
        const SizedBox(height: 20),
        _buildSectionHeader('معلومات عني', ''),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: widget.user.tags.isNotEmpty ? widget.user.tags.map((tag) => _buildTagChip(tag)).toList() : [_buildTagChip('مسلم 🕌'), _buildTagChip('Ludo 🎮'), _buildTagChip('غناء 🎤')]),
        const SizedBox(height: 20),
        _buildSectionHeader('الصوت', ''),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _playVoiceBio,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(15)),
            child: Row(children: [
              Icon(_isPlayingVoice ? Icons.pause_circle_filled : Icons.play_circle_fill, color: Colors.blue, size: 30),
              const SizedBox(width: 10),
              Expanded(child: Row(children: List.generate(20, (index) => Container(width: 3, height: (index % 5 + 1) * 4.0, margin: const EdgeInsets.symmetric(horizontal: 1), color: Colors.blue.withOpacity(_isPlayingVoice ? 0.8 : 0.3))))),
              const Text('مشغل الصوت', style: TextStyle(color: Colors.blue, fontSize: 12)),
            ]),
          ),
        ),
        const SizedBox(height: 20),
        _buildSectionHeader('شركائي المقربون', ''),
        const SizedBox(height: 15),
        if (_partners.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('لا يوجد شركاء حالياً', style: TextStyle(color: Colors.grey))))
        else SizedBox(height: 110, child: Stack(children: [CustomPaint(size: const Size(double.infinity, 110), painter: RelationshipLinesPainter()), Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: _partners.map((p) => _buildPartnerItem(p.name, 'LV.${p.userLevel}', p.profilePic)).toList())])),
      ],
    );
  }

  Widget _buildFamilyBanner() {
    if (_userFamily == null) return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(15)), child: const Center(child: Text('لم ينضم لعائلة بعد', style: TextStyle(color: Colors.grey))));
    return Container(
      height: 100, decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), gradient: const LinearGradient(colors: [Colors.orange, Colors.purple, Colors.blue])),
      child: Stack(children: [
        Positioned(right: 20, top: 0, bottom: 0, child: Row(children: [Text(_userFamily!.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)), const SizedBox(width: 20), Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle), child: CircleAvatar(radius: 35, backgroundImage: _userFamily!.logoUrl.isNotEmpty ? NetworkImage(_userFamily!.logoUrl) : const AssetImage('assets/images/avatar_placeholder.png') as ImageProvider))])),
        Positioned(left: 20, top: 0, bottom: 0, child: Center(child: Row(children: [const Icon(Icons.person, color: Colors.white70, size: 16), Text(' ${_userFamily!.memberCount}/${_userFamily!.maxMembers}', style: const TextStyle(color: Colors.white, fontSize: 14))]))),
      ]),
    );
  }

  Widget _buildPartnerItem(String name, String level, String pic) {
    return Column(children: [Stack(alignment: Alignment.bottomCenter, children: [Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.pinkAccent, shape: BoxShape.circle), child: CircleAvatar(radius: 35, backgroundImage: pic.isNotEmpty ? NetworkImage(pic) : const AssetImage('assets/images/avatar_placeholder.png') as ImageProvider)), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.pink, borderRadius: BorderRadius.circular(10)), child: Text(level, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)))]), const SizedBox(height: 5), Text(name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))]);
  }

  Widget _buildRadianceTab(ScrollController controller) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      children: [
        _buildSectionHeader('اللقب الشرفي', 'المزيد'),
        const SizedBox(height: 10),
        _buildRankBadge(widget.user.honoraryTitle ?? widget.user.familyRole ?? 'عضو ملكي', Colors.grey.shade400, icon: Icons.mic_external_on),
        const SizedBox(height: 20),
        _buildSectionHeader('الشارات ${_userBadges.length}', 'رؤية الكل'),
        const SizedBox(height: 15),
        if (_userBadges.isEmpty) const Center(child: Text('لا توجد شارات حالياً', style: TextStyle(color: Colors.grey)))
        else GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10), itemCount: _userBadges.length, itemBuilder: (context, index) => _buildGiftItem(index, Icons.workspace_premium, Colors.amber, _userBadges[index]['name'] ?? 'شارة')),
        const SizedBox(height: 20),
        _buildSectionHeader('سيارة', 'إدارة'),
        const SizedBox(height: 10),
        Align(alignment: Alignment.centerRight, child: _buildGiftItem(0, Icons.pets, Colors.amber, 'الأسد الطائر')),
        const SizedBox(height: 20),
        _buildSectionHeader('هدية ${_userGifts.length}', 'رؤية الكل'),
        const SizedBox(height: 15),
        if (_userGifts.isEmpty) const Center(child: Text('لا توجد هدايا مستلمة', style: TextStyle(color: Colors.grey)))
        else GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.8), itemCount: _userGifts.length, itemBuilder: (context, index) => Column(children: [_buildGiftItem(index, Icons.card_giftcard, Colors.pinkAccent, _userGifts[index]['name'] ?? 'هدية'), Text('x${_userGifts[index]['count'] ?? 1}', style: const TextStyle(fontSize: 12, color: Colors.grey))])),
      ],
    );
  }

  Widget _buildGiftItem(int index, IconData icon, Color color, String name) {
    return GestureDetector(onTap: () => _showGiftDetails(name, color), child: Container(height: 60, width: 60, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade200)), child: Icon(icon, color: color, size: 35)));
  }

  void _showGiftDetails(String name, Color color) {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (context) => Container(padding: const EdgeInsets.all(25), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))), child: Column(mainAxisSize: MainAxisSize.min, children: [Container(height: 5, width: 40, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(5))), const SizedBox(height: 20), Icon(Icons.card_giftcard, color: color, size: 80), const SizedBox(height: 15), Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), const SizedBox(height: 10), const Text('هذه الهدية تمنح المستخدم نقاط خبرة وتألق وتزيد من شعبيته في المنصة.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)), const SizedBox(height: 25), ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: color, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))), child: const Text('إغلاق', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))])));
  }

  Widget _buildSectionHeader(String title, String trailing) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), if (trailing.isNotEmpty) Row(children: [Text(trailing, style: const TextStyle(color: Colors.grey, fontSize: 13)), const Icon(Icons.arrow_forward_ios, size: 10, color: Colors.grey)])]);
  }

  Widget _buildMomentsTab(ScrollController controller) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('posts').where('authorId', isEqualTo: widget.user.uid).orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('لا توجد لحظات حالياً', style: TextStyle(color: Colors.grey)));
        final posts = snapshot.data!.docs.map((doc) => PostModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
        return ListView.builder(controller: controller, padding: const EdgeInsets.all(15), itemCount: posts.length, itemBuilder: (context, index) => _buildMomentCard(posts[index]));
      },
    );
  }

  Widget _buildMomentCard(PostModel post) {
    final bool isLiked = post.likes.contains(_currentUserId);
    return Card(
      margin: const EdgeInsets.only(bottom: 15), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: Color(0xFFF5F5F5))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ListTile(
          leading: CircleAvatar(backgroundImage: post.authorPic.isNotEmpty ? NetworkImage(post.authorPic) : null),
          title: Row(
            children: [
              Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(width: 8),
              _buildRankBadge('${widget.user.charm}', Colors.pink, icon: Icons.favorite),
              _buildRankBadge(widget.user.nobleLevel, Colors.blueGrey, isTextOnly: true),
            ],
          ),
          subtitle: Text(intl.DateFormat('yyyy-MM-dd').format(post.createdAt), style: const TextStyle(fontSize: 12)),
        ),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 15), child: Text(post.content)),
        if (post.imageUrl != null) Padding(padding: const EdgeInsets.all(15), child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(post.imageUrl!, width: double.infinity, fit: BoxFit.cover))),
        Padding(padding: const EdgeInsets.all(10), child: Row(children: [
          GestureDetector(onTap: () => _togglePostLike(post), child: Row(children: [Icon(isLiked ? Icons.favorite : Icons.favorite_border, size: 20, color: isLiked ? Colors.red : Colors.grey), const SizedBox(width: 5), Text('${post.likes.length}', style: TextStyle(color: isLiked ? Colors.red : Colors.grey))])),
          const SizedBox(width: 20),
          GestureDetector(onTap: () {}, child: Row(children: [const Icon(Icons.chat_bubble_outline, size: 20, color: Colors.grey), const SizedBox(width: 5), Text('${post.commentCount}', style: const TextStyle(color: Colors.grey))])),
          const Spacer(),
          IconButton(icon: const Icon(Icons.share_outlined, size: 20, color: Colors.grey), onPressed: _shareProfile),
        ])),
      ]),
    );
  }

  Widget _buildTagChip(String label) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)), child: Text(label, style: const TextStyle(fontSize: 13)));
  }

  Widget _buildBottomActionButtons() {
    if (widget.user.uid == _currentUserId) return const SizedBox.shrink();
    return Positioned(
      bottom: 20, left: 20, right: 20,
      child: Row(children: [
        Expanded(child: ElevatedButton.icon(
          onPressed: _handleFriendAction,
          icon: Icon(_isFriend ? Icons.people : (_hasPendingRequest ? Icons.hourglass_top : Icons.person_add_alt_1), color: Colors.white),
          label: Text(_isFriend ? 'صديق' : (_hasPendingRequest ? 'تم الطلب' : 'إضافة الأصدقاء'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(backgroundColor: _isFriend ? Colors.blueGrey : (_hasPendingRequest ? Colors.orange : const Color(0xFF00C853)), padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
        )),
        const SizedBox(width: 15),
        Expanded(child: ElevatedButton.icon(
          onPressed: _toggleFollow,
          icon: Icon(_isFollowing ? Icons.check : Icons.add, color: Colors.white),
          label: Text(_isFollowing ? 'تمت المتابعة' : 'متابعة', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(backgroundColor: _isFollowing ? Colors.grey : const Color(0xFF03A9F4), padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
        )),
      ]),
    );
  }
}

class RelationshipLinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.pinkAccent.withOpacity(0.2)..strokeWidth = 2..style = PaintingStyle.stroke;
    final path = Path();
    double centerY = 45;
    path.moveTo(size.width * 0.15, centerY);
    path.quadraticBezierTo(size.width * 0.5, centerY - 40, size.width * 0.85, centerY);
    canvas.drawPath(path, paint);
    final heartPaint = Paint()..color = Colors.pinkAccent.withOpacity(0.5);
    canvas.drawCircle(Offset(size.width * 0.35, centerY - 15), 3, heartPaint);
    canvas.drawCircle(Offset(size.width * 0.65, centerY - 15), 3, heartPaint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
