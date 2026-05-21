import 'dart:ui';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:video_compress/video_compress.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../services/ad_manager.dart';
import '../../services/firestore_service.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart';
import '../../app_theme.dart';
import '../../theme/design_tokens.dart';
import '../../theme/reusable_widgets.dart';
import 'chat_message_widgets.dart';
import 'widgets/voice_recording_widget.dart';
import 'services/recording_service.dart';
import 'widgets/media_viewers.dart';
import '../profile/user_profile_page.dart';

export 'chat_message_widgets.dart';

class IndividualChatPage extends StatefulWidget {
  final UserModel otherUser;
  final String roomId;

  const IndividualChatPage(
      {super.key, required this.otherUser, required this.roomId});

  @override
  State<IndividualChatPage> createState() => _IndividualChatPageState();
}

class _IndividualChatPageState extends State<IndividualChatPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final ScrollController _scrollController = ScrollController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final ImagePicker _picker = ImagePicker();
  final RecordingService _recordingService = RecordingService();

  StreamSubscription<List<MessageModel>>? _messageSubscription;
  StreamSubscription<DocumentSnapshot>? _typingSubscription;
  StreamSubscription<DocumentSnapshot>? _roomSubscription;

  String? _lastMessageId;
  int _messageLimit = 50;
  bool _isOtherUserTyping = false;
  MessageModel? _replyingTo;
  MessageModel? _editingMessage;
  String? _currentWallpaper;
  String? _playingAudioUrl;

  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  Timer? _typingTimer;
  final Set<String> _markedReadMessageIds = <String>{};
  String _searchQuery = "";
  bool _isSearching = false;

  bool _isSelectionMode = false;
  final Set<String> _selectedMessageIds = {};

  VideoPlayerController? _pipController;
  bool _showPiP = false;

  bool _isDisappearingMessages = false;
  int _disappearingDurationHours = 24;
  List<String> _pinnedMessageIds = [];
  MessageModel? _topPinnedMessage;

  String? _highlightedMessageId;
  String? _pendingScrollMessageId;
  final Map<String, GlobalKey> _messageKeys = {};

  Duration _audioPosition = Duration.zero;

  BannerAd? _chatBannerAd;
  bool _isAdLoaded = false;
  Timer? _periodicAdTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _loadChatBannerAd();
    _startPeriodicAds();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        setState(() => _messageLimit += 30);
        _setupMessageSubscription();
      }
    });

    _setupMessageSubscription();
    _setupRoomSubscription();
    _updateUserStatus(true);

    _typingSubscription = FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(widget.roomId)
        .snapshots()
        .listen((snap) {
      if (snap.exists) {
        final typingStatus = (snap.data())?['typingStatus'] as Map?;
        if (mounted) {
          setState(() => _isOtherUserTyping =
              typingStatus?[widget.otherUser.uid] ?? false);
        }
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

  void _loadChatBannerAd() {
    _chatBannerAd = AdManager().getBannerAd(
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

  void _scrollToMessage(String messageId) {
    if (_messageKeys.containsKey(messageId)) {
      final targetContext = _messageKeys[messageId]!.currentContext;
      if (targetContext != null) {
        Scrollable.ensureVisible(targetContext,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut);
        setState(() => _highlightedMessageId = messageId);
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) setState(() => _highlightedMessageId = null);
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('الرسالة بعيدة، جاري جلب البيانات... ⏳'),
          duration: Duration(seconds: 1)));
      setState(() {
        _pendingScrollMessageId = messageId;
        _messageLimit += 50;
      });
      _setupMessageSubscription();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateUserStatus(true);
    } else {
      _updateUserStatus(false);
      _audioPlayer.stop();
    }
  }

  void _updateUserStatus(bool isActive) {
    if (_currentUserId.isNotEmpty) {
      _firestoreService.updateSingleField(_currentUserId, 'isActive', isActive);
      _firestoreService.updateSingleField(
          _currentUserId, 'lastSeen', FieldValue.serverTimestamp());
    }
  }

  void _setupRoomSubscription() {
    _roomSubscription?.cancel();
    _roomSubscription = FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(widget.roomId)
        .snapshots()
        .listen((snap) {
      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>;
        final pinned = List<String>.from(data['pinnedMessages'] ?? []);
        if (mounted) {
          setState(() {
            _currentWallpaper = data['wallpaperUrl'];
            _isDisappearingMessages = data['isDisappearing'] ?? false;
            _disappearingDurationHours = data['disappearingDuration'] ?? 24;
            _pinnedMessageIds = pinned;
          });
          if (pinned.isNotEmpty) {
            _fetchTopPinnedMessage(pinned.last);
          } else {
            setState(() => _topPinnedMessage = null);
          }
        }
      }
    });
  }

  Future<void> _fetchTopPinnedMessage(String messageId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(widget.roomId)
          .collection('messages')
          .doc(messageId)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _topPinnedMessage = MessageModel.fromMap(doc.data()!, doc.id);
        });
      }
    } catch (e) {
      debugPrint("Error fetching pinned message: $e");
    }
  }

  void _setupMessageSubscription() {
    _messageSubscription?.cancel();
    _messageSubscription = _firestoreService
        .streamMessages(widget.roomId, limit: _messageLimit)
        .listen((messages) {
      if (messages.isNotEmpty) {
        final latestMsg = messages.first;
        if (_lastMessageId != null && latestMsg.id != _lastMessageId) {
          if (latestMsg.senderId != _currentUserId) {
            _sfxPlayer.play(AssetSource('sounds/received.mp3'));
          }
        }
        _lastMessageId = latestMsg.id;
        final currentUid = FirebaseAuth.instance.currentUser?.uid;
        if (currentUid != null) {
          final unreadIds = messages
              .where((m) =>
                  !m.isRead &&
                  m.senderId != currentUid &&
                  !_markedReadMessageIds.contains(m.id))
              .map((m) => m.id)
              .where((id) => id.isNotEmpty)
              .toList();
          if (unreadIds.isNotEmpty) {
            _firestoreService.markMessagesAsRead(widget.roomId, unreadIds,
                readerId: currentUid);
            _markedReadMessageIds.addAll(unreadIds);
          }
        }

        if (_pendingScrollMessageId != null &&
            messages.any((m) => m.id == _pendingScrollMessageId)) {
          final pendingId = _pendingScrollMessageId!;
          setState(() => _pendingScrollMessageId = null);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToMessage(pendingId);
          });
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _periodicAdTimer?.cancel();
    _chatBannerAd?.dispose();
    _updateUserStatus(false);
    _messageSubscription?.cancel();
    _typingSubscription?.cancel();
    _roomSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _audioPlayer.dispose();
    _sfxPlayer.dispose();
    _pipController?.dispose();
    _typingTimer?.cancel();
    _recordingService.dispose();
    super.dispose();
  }

  void _openPiP(String videoUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfessionalVideoPlayer(videoUrl: videoUrl),
      ),
    );
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

  void _showMessageInfo(MessageModel message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.backgroundDarkDeep,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.borderRadiusXl3))),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DesignTokens.spacingLg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const HeadingText('معلومات الرسالة', fontSize: DesignTokens.fontSizeLg),
              const SizedBox(height: DesignTokens.spacingXl),
              _infoRow(Icons.done_all_rounded, 'استُلمت في:',
                  message.deliveredAt ?? message.timestamp),
              const RoyalDivider(indent: 0, endIndent: 0),
              _infoRow(
                  Icons.visibility_rounded,
                  'قُرئت في:',
                  message.readAt ??
                      (message.isRead ? message.timestamp : null)),
              if (message.expiresAt != null) ...[
                const RoyalDivider(indent: 0, endIndent: 0),
                _infoRow(
                    Icons.timer_off_rounded, 'تختفي في:', message.expiresAt),
              ],
              const SizedBox(height: DesignTokens.spacingMd),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, DateTime? time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DesignTokens.spacingSm),
      child: Row(
        children: [
          Icon(icon, color: DesignTokens.primaryGold, size: DesignTokens.iconSizeSm),
          const SizedBox(width: DesignTokens.spacingMd),
          BodyText(label, color: DesignTokens.neutralGray400),
          const Spacer(),
          BodyText(
              time != null
                  ? intl.DateFormat('hh:mm a').format(time)
                  : 'قيد الانتظار...',
              fontWeight: DesignTokens.fontWeightBold,
              color: time != null ? DesignTokens.neutralWhite : DesignTokens.neutralGray600),
        ],
      ),
    );
  }

  Future<void> _changeWallpaper() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      return;
    }

    if (!mounted) return;

    File file = File(image.path);
    Reference storageRef =
        FirebaseStorage.instance.ref().child('wallpapers/${widget.roomId}.jpg');
    UploadTask uploadTask = storageRef.putFile(file);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();

    await _firestoreService.updateChatWallpaper(widget.roomId, downloadUrl);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تغيير الخلفية بنجاح 🎨')));
    }
  }

  Future<void> _sendVoiceMessage(String audioUrl, int duration) async {
    try {
      debugPrint(
          '[IndividualChatPage] Sending voice message: $audioUrl, duration: $duration');

      DateTime? expiresAt;
      if (_isDisappearingMessages) {
        expiresAt =
            DateTime.now().add(Duration(hours: _disappearingDurationHours));
      }

      final message = MessageModel(
        id: '',
        senderId: _currentUserId,
        text: 'رسالة صوتية 🎤',
        audioUrl: audioUrl,
        audioDuration: duration,
        timestamp: DateTime.now(),
        type: MessageType.audio,
        replyToId: _replyingTo?.id,
        replyToText: _replyingTo?.text,
        expiresAt: expiresAt,
      );

      await _firestoreService.sendMessage(widget.roomId, message);

      debugPrint('[IndividualChatPage] Voice message sent successfully');

      try {
        _sfxPlayer.play(AssetSource('sounds/sent.mp3'));
      } catch (e) {
        debugPrint('Error playing sound: $e');
      }

      if (mounted) {
        setState(() => _replyingTo = null);
      }
    } catch (e) {
      debugPrint('[IndividualChatPage] Error sending voice message: $e');
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

  Future<void> _uploadAndSendImage() async {
    final XFile? image =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) return;

    if (!mounted) return;

    DateTime? expiresAt;
    if (_isDisappearingMessages) {
      expiresAt =
          DateTime.now().add(Duration(hours: _disappearingDurationHours));
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProImageEditor.file(
          File(image.path),
          callbacks: ProImageEditorCallbacks(
            onImageEditingComplete: (Uint8List bytes) async {
              Navigator.pop(context);

              ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(
                  content: Text('جاري الرفع... 🚀'),
                  duration: Duration(seconds: 2)));

              String fileName =
                  'img_${DateTime.now().millisecondsSinceEpoch}.jpg';
              Reference storageRef = FirebaseStorage.instance
                  .ref()
                  .child('chat_media/${widget.roomId}/$fileName');

              UploadTask uploadTask = storageRef.putData(bytes);
              TaskSnapshot snapshot = await uploadTask;
              String downloadUrl = await snapshot.ref.getDownloadURL();

              final message = MessageModel(
                id: '',
                senderId: _currentUserId,
                text: 'صورة 🖼️',
                imageUrl: downloadUrl,
                timestamp: DateTime.now(),
                type: MessageType.image,
                replyToId: _replyingTo?.id,
                replyToText: _replyingTo?.text,
                expiresAt: expiresAt,
              );
              await _firestoreService.sendMessage(widget.roomId, message);
              _sfxPlayer.play(AssetSource('sounds/sent.mp3'));
              setState(() => _replyingTo = null);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndSendVideo() async {
    final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery, maxDuration: const Duration(minutes: 5));
    if (video == null) return;

    if (!mounted) return;

    DateTime? expiresAt;
    if (_isDisappearingMessages) {
      expiresAt =
          DateTime.now().add(Duration(hours: _disappearingDurationHours));
    }

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('جاري معالجة الفيديو... ⏳'),
        duration: Duration(seconds: 2)));

    MediaInfo? mediaInfo;
    File fileToUpload;

    try {
      mediaInfo = await VideoCompress.compressVideo(
        video.path,
        quality: VideoQuality.MediumQuality,
        deleteOrigin: false,
      );
      fileToUpload = mediaInfo?.file ?? File(video.path);
    } catch (e) {
      debugPrint("Error compressing video: $e");
      fileToUpload = File(video.path);
    }

    String? thumbUrl;
    try {
      final thumbnailFile =
          await VideoCompress.getFileThumbnail(video.path, quality: 50);
      Reference thumbRef = FirebaseStorage.instance.ref().child(
          'chat_media/${widget.roomId}/thumb_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await thumbRef.putFile(thumbnailFile);
      thumbUrl = await thumbRef.getDownloadURL();
    } catch (e) {
      debugPrint("Error generating thumbnail: $e");
    }

    String fileName = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
    Reference storageRef = FirebaseStorage.instance
        .ref()
        .child('chat_media/${widget.roomId}/$fileName');

    UploadTask uploadTask = storageRef.putFile(fileToUpload);
    TaskSnapshot snapshot = await uploadTask;
    String downloadUrl = await snapshot.ref.getDownloadURL();

    final message = MessageModel(
      id: '',
      senderId: _currentUserId,
      text: 'فيديو 🎥',
      videoUrl: downloadUrl,
      imageUrl: thumbUrl ?? '',
      timestamp: DateTime.now(),
      type: MessageType.video,
      replyToId: _replyingTo?.id,
      replyToText: _replyingTo?.text,
      expiresAt: expiresAt,
    );
    await _firestoreService.sendMessage(widget.roomId, message);
    _sfxPlayer.play(AssetSource('sounds/sent.mp3'));
    setState(() => _replyingTo = null);
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) {
      return;
    }

    if (_editingMessage != null) {
      await _firestoreService.updateMessageText(
          widget.roomId, _editingMessage!.id, text);
      setState(() => _editingMessage = null);
      _messageController.clear();
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return;
    }
    DateTime? expiresAt;
    if (_isDisappearingMessages) {
      expiresAt =
          DateTime.now().add(Duration(hours: _disappearingDurationHours));
    }

    final message = MessageModel(
      id: '',
      senderId: currentUser.uid,
      text: text,
      timestamp: DateTime.now(),
      type: MessageType.text,
      replyToId: _replyingTo?.id,
      replyToText: _replyingTo?.text,
      expiresAt: expiresAt,
    );

    if (!mounted) return;
    await _firestoreService.sendMessage(widget.roomId, message);
    if (mounted) {
      _sfxPlayer.play(AssetSource('sounds/sent.mp3'));
      _messageController.clear();
      setState(() => _replyingTo = null);
      _typingTimer?.cancel();
      _firestoreService.setTypingStatus(widget.roomId, currentUser.uid, false);
      _scrollController.animateTo(0,
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _onTextChanged(String val) {
    _firestoreService.setTypingStatus(
        widget.roomId, _currentUserId, val.isNotEmpty);
    _typingTimer?.cancel();
    if (val.isNotEmpty) {
      _typingTimer = Timer(
          const Duration(milliseconds: 1200),
          () => _firestoreService.setTypingStatus(
              widget.roomId, _currentUserId, false));
    }
    setState(() {});
  }

  void _toggleSelection(String messageId) {
    setState(() {
      if (_selectedMessageIds.contains(messageId)) {
        _selectedMessageIds.remove(messageId);
        if (_selectedMessageIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedMessageIds.add(messageId);
        _isSelectionMode = true;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedMessageIds.clear();
      _isSelectionMode = false;
    });
  }

  void _handlePinMessage() async {
    if (_selectedMessageIds.isEmpty) return;
    final messageId = _selectedMessageIds.first;
    final isPinned = _pinnedMessageIds.contains(messageId);

    await _firestoreService.togglePinChatMessage(
        widget.roomId, messageId, !isPinned);

    _clearSelection();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:
            Text(isPinned ? 'تم إلغاء تثبيت الرسالة' : 'تم تثبيت الرسالة 📌'),
        backgroundColor: DesignTokens.primaryGold,
      ));
    }
  }

  void _handleBulkDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => RoyalConfirmDialog(
        title: 'حذف الرسائل',
        message: 'هل أنت متأكد من حذف ${_selectedMessageIds.length} رسائل؟',
        confirmLabel: 'حذف',
        onConfirm: () => Navigator.pop(ctx, true),
        icon: Icons.delete_forever,
        iconColor: DesignTokens.semanticError,
      ),
    );

    if (confirm == true) {
      final idsToDelete = List<String>.from(_selectedMessageIds);
      for (String id in idsToDelete) {
        await _firestoreService.deleteMessage(widget.roomId, id);
      }
      _clearSelection();
    }
  }

  void _handleBulkForward() {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.backgroundDarkDeep,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.borderRadiusXl3))),
      builder: (ctx) => SafeArea(
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) => StreamBuilder<List<UserModel>>(
            stream: _firestoreService.streamFriends(_currentUserId),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const RoyalLoadingIndicator();
              }
              final friends = snap.data!;
              return Column(
                children: [
                  const Padding(
                      padding: EdgeInsets.all(DesignTokens.spacingLg),
                      child: HeadingText('تحويل الرسائل المحددة إلى...',
                          fontSize: DesignTokens.fontSizeBase)),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: friends.length,
                      itemBuilder: (_, i) => ListTile(
                        leading: CircleAvatar(
                            backgroundImage: (friends[i].profilePic.isNotEmpty &&
                                    Uri.tryParse(friends[i].profilePic)?.host.isNotEmpty == true)
                                ? CachedNetworkImageProvider(
                                    friends[i].profilePic)
                                : null),
                        title: BodyText(friends[i].name, color: DesignTokens.neutralWhite),
                        onTap: () async {
                          Navigator.pop(ctx);
                          final targetRoomId =
                              await _firestoreService.ensureChatRoomExists(
                                  _currentUserId, friends[i].uid);

                          final roomSnap = await FirebaseFirestore.instance
                              .collection('chatRooms')
                              .doc(widget.roomId)
                              .collection('messages')
                              .get();
                          final selectedMessages = roomSnap.docs
                              .map((doc) =>
                                  MessageModel.fromMap(doc.data(), doc.id))
                              .where((m) => _selectedMessageIds.contains(m.id))
                              .toList();

                          for (var msg in selectedMessages) {
                            final fMsg = MessageModel(
                                id: '',
                                senderId: _currentUserId,
                                text: msg.text,
                                timestamp: DateTime.now(),
                                type: msg.type,
                                imageUrl: msg.imageUrl,
                                audioUrl: msg.audioUrl,
                                location: msg.location,
                                contactData: msg.contactData,
                                forwardedFrom: widget.otherUser.name);
                            await _firestoreService.sendMessage(
                                targetRoomId, fMsg);
                          }
                          _clearSelection();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(
                                  'تم التحويل بنجاح لـ ${friends[i].name}')));
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showSharedMedia() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DesignTokens.backgroundDarkDeep,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.borderRadiusXl3))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            const SizedBox(height: DesignTokens.spacingMd),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: DesignTokens.neutralGray700,
                    borderRadius: BorderRadius.circular(2))),
            const Padding(
                padding: EdgeInsets.all(DesignTokens.spacingLg),
                child: HeadingText('الوسائط المشتركة',
                    fontSize: DesignTokens.fontSizeLg)),
            Expanded(
              child: StreamBuilder<List<MessageModel>>(
                stream:
                    _firestoreService.streamMessages(widget.roomId, limit: 100),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const RoyalLoadingIndicator();
                  }
                  final mediaMessages = snap.data!
                      .where((m) =>
                          m.type == MessageType.image ||
                          m.type == MessageType.video)
                      .toList();
                  if (mediaMessages.isEmpty) {
                    return const Center(
                        child: BodyText('لا توجد وسائط بعد',
                            color: DesignTokens.neutralGray500));
                  }

                  return GridView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(DesignTokens.spacingSm),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 5,
                            mainAxisSpacing: 5),
                    itemCount: mediaMessages.length,
                    itemBuilder: (context, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMd),
                      child: CachedNetworkImage(
                          imageUrl: mediaMessages[i].imageUrl!,
                          fit: BoxFit.cover),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showForwardPicker(MessageModel message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.backgroundDarkDeep,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.borderRadiusXl3))),
      builder: (ctx) => SafeArea(
        child: DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) => StreamBuilder<List<UserModel>>(
            stream: _firestoreService.streamFriends(_currentUserId),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const RoyalLoadingIndicator();
              }
              final friends = snap.data!;
              return Column(
                children: [
                  const Padding(
                      padding: EdgeInsets.all(DesignTokens.spacingLg),
                      child: HeadingText('تحويل الرسالة إلى...',
                          fontSize: DesignTokens.fontSizeBase)),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: friends.length,
                      itemBuilder: (context, i) => ListTile(
                        leading: CircleAvatar(
                            backgroundImage: (friends[i].profilePic.isNotEmpty &&
                                    Uri.tryParse(friends[i].profilePic)?.host.isNotEmpty == true)
                                ? CachedNetworkImageProvider(
                                    friends[i].profilePic)
                                : null),
                        title: BodyText(friends[i].name, color: DesignTokens.neutralWhite),
                        onTap: () async {
                          Navigator.pop(ctx);
                          final rId =
                              await _firestoreService.ensureChatRoomExists(
                                  _currentUserId, friends[i].uid);
                          final fMsg = MessageModel(
                              id: '',
                              senderId: _currentUserId,
                              text: message.text,
                              timestamp: DateTime.now(),
                              type: message.type,
                              imageUrl: message.imageUrl,
                              audioUrl: message.audioUrl,
                              location: message.location,
                              contactData: message.contactData,
                              forwardedFrom: widget.otherUser.name);
                          await _firestoreService.sendMessage(rId, fMsg);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content:
                                    Text('تم التحويل إلى ${friends[i].name}')));
                          }
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: DesignTokens.neutralBlack,
        appBar: _isSelectionMode
            ? _buildSelectionAppBar()
            : (_isSearching ? _buildSearchAppBar() : _buildNormalAppBar()),
        body: Stack(
          children: [
            Positioned.fill(
              child: _currentWallpaper != null
                  ? CachedNetworkImage(
                      imageUrl: _currentWallpaper!, fit: BoxFit.cover)
                  : AppTheme.background(child: const SizedBox()),
            ),
            Positioned.fill(
                child: Container(
                    color: DesignTokens.neutralBlack.withValues(
                        alpha: _currentWallpaper != null ? 0.4 : 0.0))),
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
                            width: _chatBannerAd!.size.width.toDouble(),
                            height: _chatBannerAd!.size.height.toDouble(),
                            child: AdWidget(ad: _chatBannerAd!),
                          ),
                        )
                      : const SizedBox.shrink();
                  }
                ),
                _buildPinnedMessageBar(),
                Expanded(child: _buildMessagesList()),
                if (_replyingTo != null) _buildReplyPreview(),
                if (_editingMessage != null) _buildEditPreview(),
                _buildMessageInput(),
              ],
            ),
            if (_showPiP) _buildPiPOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildPiPOverlay() {
    return Positioned(
      bottom: 100,
      right: 20,
      child: Material(
        elevation: 10,
        borderRadius: BorderRadius.circular(15),
        color: Colors.black,
        child: Container(
          width: 180,
          height: 120,
          padding: const EdgeInsets.all(2),
          child: Stack(
            children: [
              ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: VideoPlayer(_pipController!)),
              Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                      icon: const Icon(Icons.close,
                          color: Colors.white, size: 18),
                      onPressed: () => setState(() => _showPiP = false))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinnedMessageBar() {
    if (_topPinnedMessage == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingLg, vertical: DesignTokens.spacingSm),
      decoration: const BoxDecoration(
        color: DesignTokens.backgroundDarkMedium,
        border: Border(bottom: BorderSide(color: DesignTokens.primaryGold, width: 1)),
      ),
      child: InkWell(
        onTap: () => _scrollToMessage(_topPinnedMessage!.id),
        child: Row(
          children: [
            const Icon(Icons.push_pin, color: DesignTokens.primaryGold, size: DesignTokens.iconSizeSm),
            const SizedBox(width: DesignTokens.spacingSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CaptionText('رسالة مثبتة',
                      color: DesignTokens.primaryGold,
                      fontSize: DesignTokens.fontSizeXs,
                      fontWeight: DesignTokens.fontWeightBold),
                  BodyText(
                    _topPinnedMessage!.type == MessageType.text
                        ? _topPinnedMessage!.text
                        : (_topPinnedMessage!.type == MessageType.image
                            ? 'صورة 🖼️'
                            : 'رسالة وسائط'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    fontSize: DesignTokens.fontSizeSm,
                    color: DesignTokens.neutralWhite,
                  ),
                ],
              ),
            ),
            if (_pinnedMessageIds.length > 1)
              Container(
                padding: const EdgeInsets.all(DesignTokens.spacingXs),
                decoration: const BoxDecoration(
                    color: Colors.white10, shape: BoxShape.circle),
                child: CaptionText('+${_pinnedMessageIds.length - 1}',
                    color: DesignTokens.neutralWhite, fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildSelectionAppBar() {
    bool canPin = _selectedMessageIds.length == 1;
    return AppBar(
      backgroundColor: DesignTokens.primaryGold,
      leading: IconButton(
          icon: const Icon(Icons.close, color: DesignTokens.neutralBlack),
          onPressed: _clearSelection),
      title: HeadingText('${_selectedMessageIds.length} رسائل محددة',
          color: DesignTokens.neutralBlack, fontSize: DesignTokens.fontSizeBase),
      actions: [
        if (canPin)
          IconButton(
              icon: Icon(
                  _pinnedMessageIds.contains(_selectedMessageIds.first)
                      ? Icons.push_pin_outlined
                      : Icons.push_pin,
                  color: DesignTokens.neutralBlack),
              onPressed: _handlePinMessage),
        IconButton(
            icon: const Icon(Icons.delete_rounded, color: DesignTokens.neutralBlack),
            onPressed: _handleBulkDelete),
        IconButton(
            icon: const Icon(Icons.forward_rounded, color: DesignTokens.neutralBlack),
            onPressed: _handleBulkForward),
      ],
    );
  }

  PreferredSizeWidget _buildNormalAppBar() {
    return AppBar(
      backgroundColor: DesignTokens.neutralBlack.withValues(alpha: 0.5),
      elevation: 0,
      flexibleSpace: ClipRect(
          child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(color: Colors.transparent))),
      leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: DesignTokens.neutralWhite, size: DesignTokens.iconSizeSm),
          onPressed: () => Navigator.pop(context)),
      title: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfilePage(userId: widget.otherUser.uid),
            ),
          );
        },
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                    radius: 18,
                    backgroundColor: DesignTokens.backgroundDarkLight,
                    backgroundImage: (widget.otherUser.profilePic.isNotEmpty &&
                            Uri.tryParse(widget.otherUser.profilePic)?.host.isNotEmpty == true)
                        ? CachedNetworkImageProvider(widget.otherUser.profilePic)
                        : null),
                if (widget.otherUser.isActive)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                          color: DesignTokens.semanticSuccess,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: DesignTokens.semanticSuccess.withValues(alpha: 0.5),
                                blurRadius: 5,
                                spreadRadius: 1)
                          ]),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: DesignTokens.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HeadingText(widget.otherUser.name,
                      color: DesignTokens.neutralWhite,
                      fontSize: DesignTokens.fontSizeBase,
                      overflow: TextOverflow.ellipsis),
                  CaptionText(
                      _isOtherUserTyping
                          ? 'يكتب الآن...'
                          : (widget.otherUser.isActive
                              ? 'متصل الآن'
                              : 'آخر ظهور: ${widget.otherUser.lastSeen != null ? intl.DateFormat('hh:mm a').format(widget.otherUser.lastSeen!) : 'قديماً'}'),
                      color: _isOtherUserTyping
                              ? DesignTokens.primaryGold
                              : (widget.otherUser.isActive
                                  ? DesignTokens.semanticSuccess
                                  : DesignTokens.neutralGray500),
                      fontSize: 10),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: DesignTokens.neutralGray400),
            onPressed: _showMoreOptions),
      ],
    );
  }

  PreferredSizeWidget _buildSearchAppBar() {
    return AppBar(
      backgroundColor: DesignTokens.backgroundDarkDeep,
      leading: IconButton(
          icon: const Icon(Icons.close, color: DesignTokens.neutralWhite),
          onPressed: () => setState(() {
                _isSearching = false;
                _searchQuery = "";
              })),
      title: TextField(
        autofocus: true,
        style: const TextStyle(
          color: DesignTokens.neutralWhite,
          fontFamily: DesignTokens.primaryFont,
        ),
        decoration: const InputDecoration(
            hintText: 'بحث في الرسائل...',
            hintStyle: TextStyle(color: DesignTokens.neutralGray600),
            border: InputBorder.none),
        onChanged: (val) => setState(() => _searchQuery = val),
      ),
    );
  }

  void _showMessageOptions(MessageModel message) {
    bool isMe = message.senderId == _currentUserId;
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.backgroundDarkDeep,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.borderRadiusXl3))),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: DesignTokens.spacingMd),
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: DesignTokens.neutralGray700,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: DesignTokens.spacingLg),
              ListTile(
                leading:
                    const Icon(Icons.reply_rounded, color: DesignTokens.primaryGold),
                title: const BodyText('رد سريع',
                    color: DesignTokens.neutralWhite),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _replyingTo = message);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_rounded, color: DesignTokens.neutralGray400),
                title: const BodyText('نسخ', color: DesignTokens.neutralWhite),
                onTap: () {
                  Navigator.pop(ctx);
                  Clipboard.setData(ClipboardData(text: message.text));
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم نسخ النص ✅')));
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.forward_rounded, color: DesignTokens.neutralGray400),
                title:
                    const BodyText('تحويل', color: DesignTokens.neutralWhite),
                onTap: () {
                  Navigator.pop(ctx);
                  _showForwardPicker(message);
                },
              ),
              ListTile(
                leading: Icon(
                    _pinnedMessageIds.contains(message.id)
                        ? Icons.push_pin_outlined
                        : Icons.push_pin,
                    color: DesignTokens.neutralGray400),
                title: BodyText(
                    _pinnedMessageIds.contains(message.id)
                        ? 'إلغاء التثبيت'
                        : 'تثبيت',
                    color: DesignTokens.neutralWhite),
                onTap: () {
                  Navigator.pop(ctx);
                  _firestoreService.togglePinChatMessage(widget.roomId,
                      message.id, !_pinnedMessageIds.contains(message.id));
                },
              ),
              if (isMe)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded,
                      color: DesignTokens.semanticError),
                  title: const BodyText('حذف',
                      color: DesignTokens.semanticError),
                  onTap: () {
                    Navigator.pop(ctx);
                    _firestoreService.deleteMessage(widget.roomId, message.id);
                  },
                ),
              const RoyalDivider(indent: DesignTokens.spacingLg, endIndent: DesignTokens.spacingLg),
              ListTile(
                leading: const Icon(Icons.check_circle_outline_rounded,
                    color: DesignTokens.neutralGray400),
                title: const BodyText('تحديد متعدد',
                    color: DesignTokens.neutralWhite),
                onTap: () {
                  Navigator.pop(ctx);
                  _toggleSelection(message.id);
                },
              ),
              const SizedBox(height: DesignTokens.spacingMd),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return StreamBuilder<List<MessageModel>>(
      stream:
          _firestoreService.streamMessages(widget.roomId, limit: _messageLimit),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: RoyalLoadingIndicator());
        }
        var messages = snapshot.data!;

        messages = messages.where((m) {
          if (m.expiresAt == null) return true;
          return m.expiresAt!.isAfter(DateTime.now());
        }).toList();

        if (_searchQuery.isNotEmpty) {
          messages =
              messages.where((m) => m.text.contains(_searchQuery)).toList();
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding:
              const EdgeInsets.only(top: 100, left: DesignTokens.spacingMd, right: DesignTokens.spacingMd, bottom: DesignTokens.spacingLg),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isMe = message.senderId == _currentUserId;
            final isSelected = _selectedMessageIds.contains(message.id);

            bool showDate = false;
            if (index == messages.length - 1) {
              showDate = true;
            } else {
              final nextMsg = messages[index + 1];
              if (!_isSameDay(message.timestamp, nextMsg.timestamp)) {
                showDate = true;
              }
            }

            final key = _messageKeys.putIfAbsent(message.id, () => GlobalKey());

            return Container(
              key: key,
              color: _highlightedMessageId == message.id
                  ? DesignTokens.primaryGold.withValues(alpha: 0.2)
                  : Colors.transparent,
              child: Column(
                children: [
                  if (showDate) _buildDateHeader(message.timestamp),
                  ChatMessageBubble(
                    message: message,
                    isMe: isMe,
                    isSelected: isSelected,
                    senderAvatar: isMe ? null : widget.otherUser.profilePic,
                    onAvatarTap: isMe
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    UserProfilePage(userId: widget.otherUser.uid),
                              ),
                            );
                          },
                    onReply: () => setState(() => _replyingTo = message),
                    onEdit: () {
                      setState(() => _editingMessage = message);
                      _messageController.text = message.text;
                    },
                    onForward: () => _showForwardPicker(message),
                    onLongPress: () {
                      if (_isSelectionMode) {
                        _toggleSelection(message.id);
                      } else {
                        HapticFeedback.mediumImpact();
                        _showMessageOptions(message);
                      }
                    },
                    onTap: () {
                      if (_isSelectionMode) {
                        _toggleSelection(message.id);
                      } else if (isMe) {
                        _showMessageInfo(message);
                      }
                    },
                    onDoubleTap: () {
                      HapticFeedback.mediumImpact();
                      _firestoreService.addReaction(
                          widget.roomId, message.id, _currentUserId, '❤️');
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
                    currentPosition: _playingAudioUrl == message.audioUrl
                        ? _audioPosition
                        : null,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Widget _buildDateHeader(DateTime date) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: DesignTokens.spacingMd),
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingMd, vertical: DesignTokens.spacingXs),
        decoration: BoxDecoration(
          color: DesignTokens.neutralWhite.withValues(alpha: 0.1),
          borderRadius: const BorderRadius.all(Radius.circular(DesignTokens.borderRadiusLg)),
        ),
        child: CaptionText(
          intl.DateFormat('dd MMM yyyy').format(date),
          color: DesignTokens.neutralGray400,
          fontSize: 11,
        ),
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.backgroundDarkDeep,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.borderRadiusXl3))),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + DesignTokens.spacingMd),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: DesignTokens.spacingMd),
              ListTile(
                  leading: const Icon(Icons.perm_media_rounded,
                      color: DesignTokens.neutralGray400),
                  title: const BodyText('الوسائط المشتركة',
                      color: DesignTokens.neutralWhite),
                  onTap: () {
                    Navigator.pop(context);
                    _showSharedMedia();
                  }),
              ListTile(
                  leading:
                      const Icon(Icons.timer_rounded, color: DesignTokens.neutralGray400),
                  title: const BodyText('الرسائل المختفية',
                      color: DesignTokens.neutralWhite),
                  subtitle: CaptionText(
                      _isDisappearingMessages ? 'مفعلة (24 ساعة)' : 'غير مفعلة',
                      color: DesignTokens.neutralGray600),
                  onTap: _toggleDisappearingMessages),
              ListTile(
                  leading: const Icon(Icons.wallpaper_rounded,
                      color: DesignTokens.neutralGray400),
                  title: const BodyText('تغيير الخلفية',
                      color: DesignTokens.neutralWhite),
                  onTap: () {
                    Navigator.pop(context);
                    _changeWallpaper();
                  }),
              ListTile(
                  leading:
                      const Icon(Icons.search_rounded, color: DesignTokens.neutralGray400),
                  title: const BodyText('بحث في المحادثة',
                      color: DesignTokens.neutralWhite),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _isSearching = true);
                  }),
              const RoyalDivider(indent: DesignTokens.spacingLg, endIndent: DesignTokens.spacingLg),
              ListTile(
                leading: const Icon(Icons.delete_sweep_rounded,
                    color: DesignTokens.primaryGold),
                title: const BodyText('مسح الدردشة',
                    color: DesignTokens.neutralWhite),
                onTap: () async {
                  Navigator.pop(context);
                  bool? confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => RoyalConfirmDialog(
                      title: 'مسح الدردشة',
                      message: 'هل أنت متأكد من مسح كافة الرسائل؟ ستبقى المحادثة موجودة.',
                      onConfirm: () => Navigator.pop(ctx, true),
                      icon: Icons.delete_sweep_rounded,
                      iconColor: DesignTokens.primaryGold,
                    ),
                  );
                  if (confirm == true) {
                    if (mounted) {
                      await _firestoreService.clearChatMessages(widget.roomId);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('تم مسح الدردشة بنجاح')));
                      }
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever_rounded,
                    color: DesignTokens.semanticError),
                title: const BodyText('حذف المحادثة',
                    color: DesignTokens.semanticError),
                onTap: () async {
                  Navigator.pop(context);
                  bool? confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => RoyalConfirmDialog(
                      title: 'حذف المحادثة',
                      message: 'سيتم حذف المحادثة من قائمتك نهائياً. يمكنك مراسلته مرة أخرى لاحقاً.',
                      onConfirm: () => Navigator.pop(ctx, true),
                      icon: Icons.delete_forever_rounded,
                      iconColor: DesignTokens.semanticError,
                    ),
                  );
                  if (confirm == true) {
                    if (mounted) {
                      await _firestoreService.deleteConversation(
                          widget.roomId, _currentUserId);
                      if (context.mounted) Navigator.pop(context);
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.block_rounded, color: DesignTokens.semanticError),
                title: const BodyText('حظر المستخدم', color: DesignTokens.semanticError),
                onTap: () async {
                  Navigator.pop(context);
                  bool? confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => RoyalConfirmDialog(
                      title: 'حظر المستخدم',
                      message: 'هل أنت متأكد من حظر ${widget.otherUser.name}؟ لن يتمكن من مراسلتك مرة أخرى.',
                      confirmLabel: 'حظر',
                      onConfirm: () => Navigator.pop(ctx, true),
                      icon: Icons.block_rounded,
                      iconColor: DesignTokens.semanticError,
                    ),
                  );
                  if (confirm == true) {
                    await _firestoreService.blockUser(_currentUserId, widget.otherUser.uid);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم حظر المستخدم بنجاح 🚫')));
                    Navigator.pop(context); // الخروج من المحادثة بعد الحظر
                  }
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.report_problem_outlined, color: Colors.orangeAccent),
                title: const BodyText('إبلاغ عن المستخدم',
                    color: DesignTokens.neutralWhite),
                onTap: () async {
                  Navigator.pop(context);
                  await _firestoreService.reportEntity(
                    reporterId: _currentUserId,
                    targetId: widget.otherUser.uid,
                    type: 'user',
                    reason: 'Report from private chat',
                    content: 'User: ${widget.otherUser.name}',
                  );
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم إرسال بلاغ عن هذا المستخدم للإدارة 🛡️')));
                  }
                }),
              const SizedBox(height: DesignTokens.spacingMd),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleDisappearingMessages() async {
    Navigator.pop(context);
    bool newValue = !_isDisappearingMessages;
    await FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(widget.roomId)
        .update({'isDisappearing': newValue, 'disappearingDuration': 24});
    if (mounted) {
      setState(() => _isDisappearingMessages = newValue);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(newValue
              ? 'تم تفعيل الرسائل المختفية ✅'
              : 'تم إيقاف الرسائل المختفية ❌')));
    }
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingLg, vertical: DesignTokens.spacingSm),
      decoration: BoxDecoration(
          color: DesignTokens.neutralBlack.withValues(alpha: 0.8),
          border:
              const Border(top: BorderSide(color: DesignTokens.primaryGold, width: 0.5))),
      child: Row(
        children: [
          const Icon(Icons.reply_rounded, color: DesignTokens.primaryGold, size: DesignTokens.iconSizeSm),
          const SizedBox(width: DesignTokens.spacingMd),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const CaptionText('الرد على الرسالة',
                    color: DesignTokens.primaryGold,
                    fontSize: 11,
                    fontWeight: DesignTokens.fontWeightBold),
                BodyText(_replyingTo!.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    color: DesignTokens.neutralGray400,
                    fontSize: 12),
              ])),
          IconButton(
              icon: const Icon(Icons.close, size: 18, color: DesignTokens.neutralGray600),
              onPressed: () => setState(() => _replyingTo = null)),
        ],
      ),
    );
  }

  Widget _buildEditPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingLg, vertical: DesignTokens.spacingSm),
      decoration: BoxDecoration(
          color: DesignTokens.primaryGold.withValues(alpha: 0.1),
          border: const Border(top: BorderSide(color: DesignTokens.primaryGold, width: 0.5))),
      child: Row(
        children: [
          const Icon(Icons.edit_rounded, color: DesignTokens.primaryGold, size: DesignTokens.iconSizeSm),
          const SizedBox(width: DesignTokens.spacingMd),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                const CaptionText('تعديل الرسالة',
                    color: DesignTokens.primaryGold,
                    fontSize: 11,
                    fontWeight: DesignTokens.fontWeightBold),
                BodyText(_editingMessage!.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    color: DesignTokens.neutralGray400,
                    fontSize: 12),
              ])),
          IconButton(
              icon: const Icon(Icons.close, size: 18, color: DesignTokens.neutralGray600),
              onPressed: () {
                setState(() => _editingMessage = null);
                _messageController.clear();
              }),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return ListenableBuilder(
      listenable: _recordingService,
      builder: (context, child) {
        if (_recordingService.isRecording) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + DesignTokens.spacingMd,
              left: DesignTokens.spacingMd,
              right: DesignTokens.spacingMd,
              top: DesignTokens.spacingMd,
            ),
            color: DesignTokens.neutralBlack.withValues(alpha: 0.87),
            child: VoiceRecordingBar(
              recordingService: _recordingService,
              onCancel: () {
                debugPrint('[IndividualChatPage] Cancel button pressed');
                _recordingService.cancelRecording();
                setState(() {});
              },
              onSend: () async {
                try {
                  final duration = _recordingService.recordingDuration;
                  debugPrint(
                      '[IndividualChatPage] Sending recording from bar, duration: $duration');
                  final url = await _recordingService
                      .stopAndUploadRecording(widget.roomId);
                  debugPrint('[IndividualChatPage] Recording uploaded: $url');
                  if (mounted) {
                    await _sendVoiceMessage(url, duration);
                    debugPrint(
                        '[IndividualChatPage] Voice message saved to Firestore');
                  }
                } catch (e) {
                  debugPrint(
                      '[IndividualChatPage] Error in voice recording bar: $e');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('خطأ: $e'),
                        backgroundColor: DesignTokens.semanticError,
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

        return Column(
          children: [
            Container(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + DesignTokens.spacingMd,
                  left: DesignTokens.spacingSm,
                  right: DesignTokens.spacingSm,
                  top: DesignTokens.spacingMd),
              decoration: BoxDecoration(
                  color: DesignTokens.neutralBlack.withValues(alpha: 0.8),
                  border: const Border(top: BorderSide(color: DesignTokens.backgroundDarkMedium))),
              child: Row(
                children: [
                  IconButton(
                      icon: const Icon(Icons.add_circle_outline_rounded,
                          color: DesignTokens.neutralGray400),
                      onPressed: _showMediaOptions),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingLg),
                      decoration: const BoxDecoration(
                          color: DesignTokens.backgroundDarkMedium,
                          borderRadius: BorderRadius.all(Radius.circular(DesignTokens.borderRadiusXl))),
                      child: TextField(
                        controller: _messageController,
                        onChanged: _onTextChanged,
                        style:
                            const TextStyle(color: DesignTokens.neutralWhite, fontSize: 14, fontFamily: DesignTokens.primaryFont),
                        decoration: const InputDecoration(
                            hintText: 'اكتب رسالتك...',
                            hintStyle: TextStyle(color: DesignTokens.neutralGray600),
                            border: InputBorder.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacingSm),
                  !hasText
                      ? VoiceRecordingButton(
                          recordingService: _recordingService,
                          roomId: widget.roomId,
                          onRecordingStart: () {
                            setState(() {});
                          },
                          onRecordingSent: (audioUrl, duration) async {
                            await _sendVoiceMessage(audioUrl, duration);
                          },
                          onRecordingCancelled: () {
                            setState(() {});
                          },
                        )
                      : GestureDetector(
                          onTap: _sendMessage,
                          child: CircleAvatar(
                              backgroundColor: _editingMessage != null
                                  ? DesignTokens.semanticInfo
                                  : DesignTokens.primaryGold,
                              radius: 22,
                              child: Icon(
                                  _editingMessage != null
                                      ? Icons.check_rounded
                                      : Icons.send_rounded,
                                  color: DesignTokens.neutralBlack,
                                  size: 20)),
                        ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: DesignTokens.backgroundDarkDeep,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(DesignTokens.borderRadiusXl3))),
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + DesignTokens.spacingLg, top: DesignTokens.spacingLg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _mediaOption(Icons.image_rounded, 'صور', DesignTokens.semanticSuccess,
                  _uploadAndSendImage),
              _mediaOption(Icons.videocam_rounded, 'فيديو', DesignTokens.primaryGold,
                  _pickAndSendVideo),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mediaOption(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
              radius: 28,
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color, size: 28)),
          const SizedBox(height: DesignTokens.spacingSm),
          CaptionText(label,
              color: DesignTokens.neutralGray400, fontSize: 12),
        ],
      ),
    );
  }
}
