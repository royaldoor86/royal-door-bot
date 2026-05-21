import 'dart:ui';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../services/ad_manager.dart';
import '../../services/firestore_service.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart';
import '../../app_theme.dart';
import 'chat_message_widgets.dart';
import 'widgets/voice_recording_widget.dart';
import 'services/recording_service.dart';
import 'widgets/media_viewers.dart';
import '../profile/user_profile_page.dart';

class GroupChatPage extends StatefulWidget {
  final ChatRoomModel room;

  const GroupChatPage({super.key, required this.room});

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final ScrollController _scrollController = ScrollController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final ImagePicker _picker = ImagePicker();
  final RecordingService _recordingService = RecordingService();

  StreamSubscription<List<MessageModel>>? _messageSubscription;
  StreamSubscription<DocumentSnapshot>? _roomSubscription;
  int _messageLimit = 30;
  MessageModel? _replyingTo;
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  String _searchQuery = "";
  bool _isSearching = false;
  late ChatRoomModel _currentRoom;
  String? _playingAudioUrl;
  Duration _audioPosition = Duration.zero;
  VideoPlayerController? _pipController;

  BannerAd? _groupBannerAd;
  bool _isAdLoaded = false;
  Timer? _periodicAdTimer;

  @override
  void initState() {
    super.initState();
    _currentRoom = widget.room;
    _setupMessageSubscription();
    _setupRoomSubscription();
    _loadGroupBannerAd();
    _startPeriodicAds();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        setState(() => _messageLimit += 30);
        _setupMessageSubscription();
      }
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _playingAudioUrl = null;
          _audioPosition = Duration.zero;
        });
      }
    });
    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted && _playingAudioUrl != null) {
        setState(() => _audioPosition = p);
      }
    });
  }

  void _loadGroupBannerAd() {
    _groupBannerAd = AdManager().getBannerAd(
      size: AdSize.banner,
      onAdLoaded: () => setState(() => _isAdLoaded = true),
    );
  }

  void _startPeriodicAds() {
    // إظهار إعلان ملء الشاشة كل 5 دقائق من النشاط في الشات (إلا إذا كان VIP)
    _periodicAdTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      if (mounted) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(_currentUserId).get();
        final String vipRank = userDoc.data()?['vipRank'] ?? '';
        
        if (vipRank.isEmpty) {
          AdManager().showInterstitialAd();
        }
      }
    });
  }

  void _setupRoomSubscription() {
    _roomSubscription?.cancel();
    _roomSubscription = FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(widget.room.id)
        .snapshots()
        .listen((snap) {
      if (snap.exists && mounted) {
        setState(() {
          _currentRoom = ChatRoomModel.fromMap(
              snap.data() as Map<String, dynamic>, snap.id);
        });
      }
    });
  }

  void _setupMessageSubscription() {
    _messageSubscription?.cancel();
    _messageSubscription = _firestoreService
        .streamMessages(_currentRoom.id, limit: _messageLimit)
        .listen((messages) {
      if (messages.isNotEmpty) {
        final currentUid = FirebaseAuth.instance.currentUser?.uid;
        if (currentUid != null) {
          final unreadIds = messages
              .where((m) => !m.isRead && m.senderId != currentUid)
              .map((m) => m.id)
              .toList();
          if (unreadIds.isNotEmpty) {
            _firestoreService.markMessagesAsRead(_currentRoom.id, unreadIds,
                readerId: currentUid);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _periodicAdTimer?.cancel();
    _groupBannerAd?.dispose();
    _messageSubscription?.cancel();
    _roomSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _audioPlayer.dispose();
    _sfxPlayer.dispose();
    _pipController?.dispose();
    _recordingService.dispose();
    super.dispose();
  }

  Future<void> _sendVoiceMessage(String audioUrl, int duration) async {
    try {
      debugPrint(
          '[GroupChatPage] Sending voice message: $audioUrl, duration: $duration');

      final message = MessageModel(
        id: '',
        senderId: _currentUserId,
        text: 'رسالة صوتية 🎤',
        audioUrl: audioUrl,
        audioDuration: duration,
        timestamp: DateTime.now(),
        type: MessageType.audio,
      );

      await _firestoreService.sendMessage(_currentRoom.id, message);

      debugPrint('[GroupChatPage] Voice message sent successfully');

      try {
        _sfxPlayer.play(AssetSource('sounds/sent.mp3'));
      } catch (e) {
        debugPrint('Error playing sound: $e');
      }
    } catch (e) {
      debugPrint('[GroupChatPage] Error sending voice message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إرسال الرسالة الصوتية: $e'),
            backgroundColor: Colors.red[700],
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _playVoice(String url) async {
    if (_playingAudioUrl == url) {
      await _audioPlayer.stop();
      setState(() {
        _playingAudioUrl = null;
        _audioPosition = Duration.zero;
      });
    } else {
      await _audioPlayer.stop();
      setState(() {
        _playingAudioUrl = url;
        _audioPosition = Duration.zero;
      });
      await _audioPlayer.play(UrlSource(url));
    }
  }

  Future<void> _uploadAndSendImage() async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image == null) return;
    File file = File(image.path);
    Reference storageRef = FirebaseStorage.instance.ref().child(
        'chat_media/${_currentRoom.id}/${DateTime.now().millisecondsSinceEpoch}.jpg');
    UploadTask uploadTask = storageRef.putFile(file);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();

    final message = MessageModel(
      id: '',
      senderId: _currentUserId,
      text: 'صورة 🖼️',
      imageUrl: downloadUrl,
      timestamp: DateTime.now(),
      type: MessageType.image,
    );
    await _firestoreService.sendMessage(_currentRoom.id, message);
    _sfxPlayer.play(AssetSource('sounds/sent.mp3'));
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final message = MessageModel(
      id: '',
      senderId: _currentUserId,
      text: text,
      timestamp: DateTime.now(),
      type: MessageType.text,
      replyToId: _replyingTo?.id,
      replyToText: _replyingTo?.text,
    );
    await _firestoreService.sendMessage(_currentRoom.id, message);
    _sfxPlayer.play(AssetSource('sounds/sent.mp3'));
    _messageController.clear();
    setState(() => _replyingTo = null);
    _scrollController.animateTo(0,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  void _showGroupInfo() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _GroupInfoSheet(
          room: _currentRoom,
          currentUserId: _currentUserId,
          firestoreService: _firestoreService),
    );
  }

  void _openPiP(String videoUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfessionalVideoPlayer(videoUrl: videoUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F0F),
        appBar: AppBar(
          backgroundColor: Colors.black.withValues(alpha: 0.5),
          elevation: 0,
          flexibleSpace: ClipRect(
              child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.transparent))),
          leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context)),
          title: InkWell(
            onTap: _showGroupInfo,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: (_currentRoom.groupImage != null &&
                          _currentRoom.groupImage!.isNotEmpty &&
                          Uri.tryParse(_currentRoom.groupImage!)?.host.isNotEmpty == true)
                      ? CachedNetworkImageProvider(_currentRoom.groupImage!)
                      : null,
                  child: (_currentRoom.groupImage == null ||
                          _currentRoom.groupImage!.isEmpty)
                      ? const Icon(Icons.groups, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_currentRoom.groupName ?? 'مجموعة',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis),
                      Text('${_currentRoom.participants.length} عضو',
                          style: const TextStyle(
                              color: Colors.white38, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
                icon: const Icon(Icons.search_rounded, color: Colors.white),
                onPressed: () => setState(() => _isSearching = !_isSearching)),
            IconButton(
                icon:
                    const Icon(Icons.more_vert_rounded, color: Colors.white70),
                onPressed: _showGroupInfo),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: _currentRoom.wallpaperUrl != null
                  ? CachedNetworkImage(
                      imageUrl: _currentRoom.wallpaperUrl!, fit: BoxFit.cover)
                  : AppTheme.background(child: const SizedBox()),
            ),
            Positioned.fill(
                child: Container(
                    color: Colors.black.withValues(
                        alpha: _currentRoom.wallpaperUrl != null ? 0.4 : 0))),
            Column(
              children: [
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(_currentUserId).snapshots(),
                  builder: (context, snapshot) {
                    final data = snapshot.data?.data() as Map<String, dynamic>?;
                    final String vipRank = data?['vipRank'] ?? '';
                    if (vipRank.isNotEmpty) return const SizedBox.shrink(); // لا إعلانات للـ VIP

                    return _isAdLoaded
                      ? Opacity(
                          opacity: 0.6,
                          child: Container(
                            alignment: Alignment.center,
                            width: _groupBannerAd!.size.width.toDouble(),
                            height: _groupBannerAd!.size.height.toDouble(),
                            child: AdWidget(ad: _groupBannerAd!),
                          ),
                        )
                      : const SizedBox.shrink();
                  }
                ),
                if (_isSearching) _buildSearchField(),
                Expanded(child: _buildMessagesList()),
                if (_replyingTo != null) _buildReplyPreview(),
                _buildMessageInput(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          border: const Border(bottom: BorderSide(color: Colors.white10))),
      child: TextField(
        autofocus: true,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
            hintText: 'بحث في الرسائل...',
            hintStyle: TextStyle(color: Colors.white24),
            border: InputBorder.none),
        onChanged: (val) => setState(() => _searchQuery = val),
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          border: const Border(
              top: BorderSide(color: AppTheme.royalGold, width: 0.5))),
      child: Row(
        children: [
          const Icon(Icons.reply_rounded, color: AppTheme.royalGold, size: 20),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const Text('الرد على الرسالة',
                    style: TextStyle(
                        color: AppTheme.royalGold,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
                Text(_replyingTo!.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 12)),
              ])),
          IconButton(
              icon: const Icon(Icons.close, size: 18, color: Colors.white38),
              onPressed: () => setState(() => _replyingTo = null)),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return StreamBuilder<List<MessageModel>>(
      stream: _firestoreService.streamMessages(_currentRoom.id,
          limit: _messageLimit),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.royalGold));
        }
        var messages = snapshot.data!;
        if (_searchQuery.isNotEmpty) {
          messages =
              messages.where((m) => m.text.contains(_searchQuery)).toList();
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isMe = message.senderId == _currentUserId;
            
            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(message.senderId).get(),
              builder: (context, userSnap) {
                String? avatar;
                String? name;
                if (userSnap.hasData && userSnap.data!.exists) {
                  final data = userSnap.data!.data() as Map<String, dynamic>?;
                  avatar = data?['profilePic'];
                  name = data?['name'];
                }

                return ChatMessageBubble(
                  message: message,
                  isMe: isMe,
                  senderAvatar: isMe ? null : avatar,
                  senderName: isMe ? null : name,
                  onAvatarTap: isMe ? null : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserProfilePage(userId: message.senderId),
                      ),
                    );
                  },
                  onReply: () => setState(() => _replyingTo = message),
                  onEdit: () {
                    _messageController.text = message.text;
                  },
                  onForward: () {},
                  onLongPress: () {},
                  onTap: () {},
                  onDoubleTap: () {
                    _firestoreService.addReaction(
                        _currentRoom.id, message.id, _currentUserId, '❤️');
                  },
                  onVideoTap: (url) => _openPiP(url),
                  onImageTap: (url) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FullScreenImageViewer(imageUrl: url),
                      ),
                    );
                  },
                  isPlaying: _playingAudioUrl == message.audioUrl,
                  onPlayVoice: message.audioUrl != null
                      ? () => _playVoice(message.audioUrl!)
                      : null,
                  currentPosition:
                      _playingAudioUrl == message.audioUrl ? _audioPosition : null,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return ListenableBuilder(
      listenable: _recordingService,
      builder: (builderContext, child) {
        if (_recordingService.isRecording) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(builderContext).padding.bottom + 10,
              left: 12,
              right: 12,
              top: 10,
            ),
            color: Colors.black87,
            child: VoiceRecordingBar(
              recordingService: _recordingService,
              onCancel: () {
                debugPrint('[GroupChatPage] Cancel button pressed');
                _recordingService.cancelRecording();
                setState(() {});
              },
              onSend: () async {
                try {
                  final duration = _recordingService.recordingDuration;
                  debugPrint(
                      '[GroupChatPage] Sending recording from bar, duration: $duration');
                  final url = await _recordingService
                      .stopAndUploadRecording(_currentRoom.id);
                  debugPrint('[GroupChatPage] Recording uploaded: $url');
                  if (mounted) {
                    await _sendVoiceMessage(url, duration);
                    debugPrint(
                        '[GroupChatPage] Voice message saved to Firestore');
                  }
                } catch (e) {
                  debugPrint(
                      '[GroupChatPage] Error in voice recording bar: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('خطأ: $e'),
                        backgroundColor: Colors.red[700],
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } finally {
                  if (mounted) {
                    _recordingService.resetRecording();
                    setState(() {});
                  }
                }
              },
            ),
          );
        }

        bool hasText = _messageController.text.trim().isNotEmpty;

        return ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 10,
                  left: 12,
                  right: 12,
                  top: 10),
              decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  border: Border(
                      top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.05)))),
              child: Row(
                children: [
                  IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded,
                          color: Colors.white70),
                      onPressed: _uploadAndSendImage),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _messageController,
                        onChanged: (v) => setState(() {}),
                        style:
                            const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: const InputDecoration(
                            hintText: 'اكتب رسالة...',
                            hintStyle:
                                TextStyle(color: Colors.white24, fontSize: 15),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  !hasText
                      ? VoiceRecordingButton(
                          recordingService: _recordingService,
                          roomId: _currentRoom.id,
                          onRecordingStart: () {
                            setState(() {});
                          },
                          onRecordingSent: _sendVoiceMessage,
                          onRecordingCancelled: () {
                            setState(() {});
                          },
                          onError: (errorMessage) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(errorMessage)),
                            );
                          },
                        )
                      : IconButton(
                          icon: const Icon(Icons.send_rounded,
                              color: AppTheme.royalGold),
                          onPressed: _sendMessage),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _GroupInfoSheet extends StatelessWidget {
  final ChatRoomModel room;
  final String currentUserId;
  final FirestoreService firestoreService;

  const _GroupInfoSheet(
      {required this.room,
      required this.currentUserId,
      required this.firestoreService});

  @override
  Widget build(BuildContext context) {
    bool isAdmin = room.admins?.contains(currentUserId) ?? false;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
            color: Color(0xFF121212),
            borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white10,
                      backgroundImage: (room.groupImage != null &&
                              room.groupImage!.isNotEmpty &&
                              Uri.tryParse(room.groupImage!)?.host.isNotEmpty == true)
                          ? CachedNetworkImageProvider(room.groupImage!)
                          : null,
                      child:
                          (room.groupImage == null || room.groupImage!.isEmpty)
                              ? const Icon(Icons.groups,
                                  size: 60, color: Colors.white24)
                              : null),
                  if (isAdmin)
                    Positioned(
                        bottom: 0,
                        right: 0,
                        child: CircleAvatar(
                            backgroundColor: AppTheme.royalGold,
                            radius: 18,
                            child: IconButton(
                                icon: const Icon(Icons.camera_alt,
                                    size: 18, color: Colors.black),
                                onPressed: () => _changeGroupImage(context)))),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(room.groupName ?? 'المجموعة',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                if (isAdmin)
                  IconButton(
                      icon: const Icon(Icons.edit,
                          color: AppTheme.royalGold, size: 20),
                      onPressed: () => _showEditGroupNameDialog(context)),
              ],
            ),
            const SizedBox(height: 30),
            _sectionTitle('الأعضاء (${room.participants.length})'),
            const SizedBox(height: 10),
            ...room.participants.map((uid) => _buildMemberTile(uid, isAdmin)),
            const SizedBox(height: 20),
            if (isAdmin) ...[
              ListTile(
                  leading: const Icon(Icons.person_add_alt_1_rounded,
                      color: Colors.green),
                  title: const Text('إضافة أعضاء جدد',
                      style: TextStyle(color: Colors.green)),
                  onTap: () => _showAddMembersDialog(context)),
              ListTile(
                  leading: const Icon(Icons.wallpaper_rounded,
                      color: AppTheme.royalGold),
                  title: const Text('تغيير خلفية الدردشة من الاستوديو',
                      style: TextStyle(color: Colors.white)),
                  onTap: () => _changeWallpaper(context)),
            ],
            ListTile(
                leading: const Icon(Icons.exit_to_app_rounded,
                    color: Colors.redAccent),
                title: const Text('مغادرة المجموعة',
                    style: TextStyle(color: Colors.redAccent)),
                onTap: () => _confirmExit(context)),
          ],
        ),
      ),
    );
  }

  Future<void> _changeGroupImage(BuildContext context) async {
    final picker = ImagePicker();
    final image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
    if (image == null) return;

    File file = File(image.path);
    Reference ref =
        FirebaseStorage.instance.ref().child('group_pics/${room.id}.jpg');
    await ref.putFile(file);
    String url = await ref.getDownloadURL();

    await FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(room.id)
        .update({'groupImage': url});
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث صورة المجموعة بنجاح ✅')));
    }
  }

  Future<void> _changeWallpaper(BuildContext context) async {
    final picker = ImagePicker();
    final image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) {
      return;
    }

    File file = File(image.path);
    Reference ref =
        FirebaseStorage.instance.ref().child('group_wallpapers/${room.id}.jpg');
    await ref.putFile(file);
    String url = await ref.getDownloadURL();

    await FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(room.id)
        .update({'wallpaperUrl': url});
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث خلفية الدردشة بنجاح ✅')));
    }
  }

  void _showEditGroupNameDialog(BuildContext context) {
    final controller = TextEditingController(text: room.groupName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('تعديل اسم المجموعة',
            style: TextStyle(color: Colors.white)),
        content: TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
                hintText: 'اسم جديد للمجموعة',
                hintStyle: TextStyle(color: Colors.white24))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
              onPressed: () async {
                if (controller.text.trim().isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('chatRooms')
                      .doc(room.id)
                      .update({'groupName': controller.text.trim()});
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                  }
                }
              },
              child: const Text('حفظ',
                  style: TextStyle(color: AppTheme.royalGold))),
        ],
      ),
    );
  }

  void _showAddMembersDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => StreamBuilder<List<UserModel>>(
        stream: firestoreService.streamFriends(currentUserId),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final friends = snap.data!
              .where((f) => !room.participants.contains(f.uid))
              .toList();
          if (friends.isEmpty) {
            return const Center(
                child: Text('لا يوجد أصدقاء جدد لإضافتهم',
                    style: TextStyle(color: Colors.white38)));
          }

          return Column(
            children: [
              const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('إضافة إلى المجموعة',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold))),
              Expanded(
                child: ListView.builder(
                  itemCount: friends.length,
                  itemBuilder: (context, i) => ListTile(
                    leading: CircleAvatar(
                        backgroundImage: (friends[i].profilePic.isNotEmpty &&
                                Uri.tryParse(friends[i].profilePic)?.host.isNotEmpty == true)
                            ? CachedNetworkImageProvider(friends[i].profilePic)
                            : null),
                    title: Text(friends[i].name,
                        style: const TextStyle(color: Colors.white)),
                    trailing: const Icon(Icons.add_circle_outline,
                        color: AppTheme.royalGold),
                    onTap: () async {
                      await firestoreService.manageGroupMember(
                          room.id, friends[i].uid, true);
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('تمت إضافة ${friends[i].name} ✅')));
                      }
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            color: AppTheme.royalGold,
            fontSize: 14,
            fontWeight: FontWeight.bold));
  }

  Widget _buildMemberTile(String uid, bool canManage) {
    bool isMemberAdmin = room.admins?.contains(uid) ?? false;
    return StreamBuilder<UserModel>(
      stream: firestoreService.streamUserData(uid),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final user = snap.data!;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
              backgroundImage: (user.profilePic.isNotEmpty &&
                      Uri.tryParse(user.profilePic)?.host.isNotEmpty == true)
                  ? CachedNetworkImageProvider(user.profilePic)
                  : null),
          title: Text(user.name, style: const TextStyle(color: Colors.white)),
          subtitle: Text(isMemberAdmin ? 'مسؤول' : 'عضو',
              style: TextStyle(
                  color: isMemberAdmin ? AppTheme.royalGold : Colors.white38,
                  fontSize: 11)),
          trailing: (canManage && uid != currentUserId)
              ? IconButton(
                  icon: const Icon(Icons.remove_circle_outline,
                      color: Colors.redAccent, size: 20),
                  onPressed: () =>
                      firestoreService.manageGroupMember(room.id, uid, false))
              : null,
        );
      },
    );
  }

  void _confirmExit(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('مغادرة المجموعة',
            style: TextStyle(color: Colors.white)),
        content: const Text('هل أنت متأكد من رغبتك في مغادرة هذه المجموعة؟',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
              onPressed: () {
                firestoreService.manageGroupMember(
                    room.id, currentUserId, false);
                Navigator.pop(ctx);
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('مغادرة',
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }
}
