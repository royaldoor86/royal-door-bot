import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import '../../models/story_model.dart';
import '../../services/firestore_service.dart';
import '../../models/chat_model.dart';
import '../../app_theme.dart';

class StoryViewer extends StatefulWidget {
  final List<StoryModel> stories;
  final int initialIndex;
  final bool returnToDiaries;

  const StoryViewer({
    required this.stories,
    this.initialIndex = 0,
    this.returnToDiaries = false,
    super.key,
  });

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class StoryGroup {
  final String userId;
  final String userName;
  final String userPic;
  final List<StoryModel> stories;
  StoryGroup(
      {required this.userId,
      required this.userName,
      required this.userPic,
      required this.stories});
}

class _StoryViewerState extends State<StoryViewer> {
  final FirestoreService _fs = FirestoreService();
  late final List<StoryGroup> _groups;
  late PageController _pageController;
  int _groupIndex = 0;
  int _innerIndex = 0;

  VideoPlayerController? _videoController;
  Timer? _progressTimer;
  double _progress = 0.0;
  bool _isPaused = false;
  static const Duration _defaultImageDuration = Duration(seconds: 5);
  bool _showHeart = false;
  Timer? _heartTimer;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    _groups = _groupStories(widget.stories);
    final pair = _flatIndexToGroupInner(widget.initialIndex);
    _groupIndex = pair['group']!;
    _innerIndex = pair['inner']!;

    _pageController = PageController(initialPage: _groupIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _initCurrent();
        _markViewed(_currentStory);
      }
    });
  }

  StoryModel get _currentStory => _groups[_groupIndex].stories[_innerIndex];

  List<StoryGroup> _groupStories(List<StoryModel> flat) {
    final List<StoryGroup> groups = [];
    for (final s in flat) {
      if (groups.isEmpty || groups.last.userId != s.userId) {
        groups.add(StoryGroup(
            userId: s.userId,
            userName: s.userName,
            userPic: s.userPic,
            stories: [s]));
      } else {
        groups.last.stories.add(s);
      }
    }
    return groups;
  }

  Map<String, int> _flatIndexToGroupInner(int flatIndex) {
    int idx = flatIndex.clamp(0, widget.stories.length - 1);
    int acc = 0;
    for (int g = 0; g < _groups.length; g++) {
      final len = _groups[g].stories.length;
      if (idx < acc + len) return {'group': g, 'inner': idx - acc};
      acc += len;
    }
    return {'group': 0, 'inner': 0};
  }

  Future<void> _markViewed(StoryModel s) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && uid.isNotEmpty) await _fs.markStoryViewed(s.id, uid);
  }

  void _initCurrent() {
    if (_isClosing) return;
    _disposeVideo();
    _progress = 0.0;
    _isPaused = false;
    final story = _currentStory;

    if (story.videoUrl != null && story.videoUrl!.isNotEmpty) {
      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(story.videoUrl!));
      _videoController!.initialize().then((_) {
        if (!mounted || _isClosing) return;
        _videoController!.play();
        _startProgressForVideo(_videoController!.value.duration);
        setState(() {});
      }).catchError((e) {
        _startProgressForImage(_defaultImageDuration);
        return null;
      });
    } else {
      _startProgressForImage(_defaultImageDuration);
    }
    if (mounted) setState(() {});
  }

  void _startProgressForImage(Duration dur) {
    _progressTimer?.cancel();
    int tick = 0;
    const int ticks = 100;
    _progressTimer = Timer.periodic(
        Duration(milliseconds: dur.inMilliseconds ~/ ticks), (t) {
      if (_isPaused || _isClosing) return;
      tick++;
      if (mounted) setState(() => _progress = tick / ticks);
      if (_progress >= 1.0) {
        t.cancel();
        _nextStory();
      }
    });
  }

  void _startProgressForVideo(Duration dur) {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_isPaused || _isClosing) return;
      if (_videoController == null || !_videoController!.value.isInitialized) {
        return;
      }
      final pos = _videoController!.value.position.inMilliseconds;
      final d = dur.inMilliseconds;
      if (d <= 0) return;
      if (mounted) setState(() => _progress = (pos / d).clamp(0.0, 1.0));
      if (_progress >= 0.99) _nextStory();
    });
  }

  void _pause() {
    setState(() => _isPaused = true);
    _videoController?.pause();
  }

  void _resume() {
    setState(() => _isPaused = false);
    _videoController?.play();
  }

  void _disposeVideo() {
    _progressTimer?.cancel();
    _videoController?.dispose();
    _videoController = null;
  }

  void _nextStory() {
    if (_isClosing) return;
    _progressTimer?.cancel();
    _videoController?.pause();

    final group = _groups[_groupIndex];
    if (_innerIndex < group.stories.length - 1) {
      if (mounted) {
        setState(() => _innerIndex++);
        _initCurrent();
        _markViewed(_currentStory);
      }
    } else if (_groupIndex < _groups.length - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      _closeViewer();
    }
  }

  void _prevStory() {
    if (_isClosing) return;
    _progressTimer?.cancel();
    _videoController?.pause();

    if (_innerIndex > 0) {
      if (mounted) {
        setState(() => _innerIndex--);
        _initCurrent();
        _markViewed(_currentStory);
      }
    } else if (_groupIndex > 0) {
      _pageController.previousPage(
          duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      _closeViewer();
    }
  }

  void _closeViewer() {
    if (_isClosing || !mounted) return;
    _isClosing = true;
    _disposeVideo();
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _isClosing = true;
    _disposeVideo();
    _heartTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_groups.isEmpty) {
      return const Scaffold(body: Center(child: Text('لا توجد قصص')));
    }
    final currentGroup = _groups[_groupIndex];
    final story = _currentStory;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final bool isOwner = uid == story.userId;
    final bool isLiked = story.likes.contains(uid);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Content (Image/Video)
            PageView.builder(
              controller: _pageController,
              itemCount: _groups.length,
              onPageChanged: (pg) {
                if (mounted && !_isClosing) {
                  setState(() {
                    _groupIndex = pg;
                    _innerIndex = 0;
                  });
                  _initCurrent();
                  _markViewed(_currentStory);
                }
              },
              itemBuilder: (context, idx) {
                final st =
                    (idx == _groupIndex) ? story : _groups[idx].stories[0];
                return _buildContent(st);
              },
            ),

            // Navigation & Long Press Handler
            GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapUp: (details) {
                final width = MediaQuery.of(context).size.width;
                final height = MediaQuery.of(context).size.height;
                final y = details.globalPosition.dy;

                // منع التنقل عند النقر في الجزء العلوي أو السفلي لتجنب التداخل مع الأيقونات
                if (y < 150 || y > height - 120) return;

                if (details.globalPosition.dx < width * 0.3) {
                  _prevStory();
                } else if (details.globalPosition.dx > width * 0.7)
                  _nextStory();
              },
              onLongPress: _pause,
              onLongPressUp: _resume,
              child: Container(color: Colors.transparent),
            ),

            // Gradient for controls readability
            _buildOverlayGradient(),

            // Progress bars
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 8,
              right: 8,
              child: Row(
                children: currentGroup.stories.map((s) {
                  int sIdx = currentGroup.stories.indexOf(s);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: LinearProgressIndicator(
                        value: sIdx < _innerIndex
                            ? 1.0
                            : (sIdx == _innerIndex ? _progress : 0.0),
                        backgroundColor: Colors.white24,
                        color: Colors.white,
                        minHeight: 2.5,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Top Bar
            Positioned(
              top: MediaQuery.of(context).padding.top + 25,
              left: 15,
              right: 15,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white12,
                    backgroundImage:
                        (currentGroup.userPic.isNotEmpty && Uri.tryParse(currentGroup.userPic)?.host.isNotEmpty == true)
                          ? CachedNetworkImageProvider(currentGroup.userPic)
                          : null,
                    child: (currentGroup.userPic.isEmpty || Uri.tryParse(currentGroup.userPic)?.host.isNotEmpty != true)
                      ? const Icon(Icons.person, color: Colors.white24, size: 20)
                      : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(currentGroup.userName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        Text(_timeAgo(story.createdAt),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 10)),
                      ],
                    ),
                  ),
                  if (isOwner)
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      color: const Color(0xFF1A1A1A),
                      offset: const Offset(0, 40),
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem<String>(
                          value: 'viewers',
                          child: Row(
                            children: [
                              Icon(Icons.remove_red_eye_outlined,
                                  color: Colors.white70, size: 20),
                              SizedBox(width: 12),
                              Text('عرض المشاهدات',
                                  style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline,
                                  color: Colors.redAccent, size: 20),
                              SizedBox(width: 12),
                              Text('حذف القصة',
                                  style: TextStyle(color: Colors.redAccent)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (String value) {
                        if (value == 'viewers') {
                          _showViewers();
                        } else if (value == 'delete') {
                          _showDeleteConfirmation();
                        }
                      },
                    )
                  else
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      color: const Color(0xFF1A1A1A),
                      offset: const Offset(0, 40),
                      itemBuilder: (BuildContext context) => [
                        const PopupMenuItem<String>(
                          value: 'report',
                          child: Row(
                            children: [
                              Icon(Icons.report_problem_outlined,
                                  color: Colors.orangeAccent, size: 20),
                              SizedBox(width: 12),
                              Text('إبلاغ عن محتوى',
                                  style: TextStyle(color: Colors.orangeAccent)),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'close',
                          child: Row(
                            children: [
                              Icon(Icons.close,
                                  color: Colors.white70, size: 20),
                              SizedBox(width: 12),
                              Text('إغلاق',
                                  style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (String value) {
                        if (value == 'report') {
                          _showReportStory();
                        } else if (value == 'close') {
                          _closeViewer();
                        }
                      },
                    ),
                ],
              ),
            ),

            // Bottom Bar (Replies & Interaction)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 15,
              left: 15,
              right: 15,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: TextField(
                        onTap: _pause,
                        onSubmitted: (val) {
                          _sendReply(val);
                          FocusScope.of(context).unfocus();
                        },
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'إرسال رسالة...',
                          hintStyle:
                              TextStyle(color: Colors.white70, fontSize: 14),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  GestureDetector(
                    onTap: _toggleLike,
                    child: Icon(
                      isLiked
                          ? Icons.favorite_rounded
                          : Icons.favorite_outline_rounded,
                      color: isLiked ? Colors.redAccent : Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 15),
                  const Icon(Icons.send_outlined,
                      color: Colors.white, size: 26),
                ],
              ),
            ),

            // Heart animation
            if (_showHeart)
              Center(
                child: TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 500),
                  tween: Tween<double>(begin: 0, end: 1.2),
                  builder: (context, double value, child) => Transform.scale(
                    scale: value > 1.0 ? 2.0 - value : value,
                    child: const Icon(Icons.favorite_rounded,
                        color: Colors.redAccent, size: 120),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlayGradient() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Column(
          children: [
            Container(
              height: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.transparent
                  ],
                ),
              ),
            ),
            const Spacer(),
            Container(
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(StoryModel story) {
    if (story.videoUrl != null && story.videoUrl!.isNotEmpty) {
      if (_videoController == null || !_videoController!.value.isInitialized) {
        return const Center(
            child: CircularProgressIndicator(color: AppTheme.royalGold));
      }
      return Center(
        child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: _videoController!.value.size.width,
            height: _videoController!.value.size.height,
            child: VideoPlayer(_videoController!),
          ),
        ),
      );
    }

    final bool isValidUrl = story.imageUrl != null && story.imageUrl!.isNotEmpty && Uri.tryParse(story.imageUrl!)?.host.isNotEmpty == true;

    return isValidUrl 
      ? CachedNetworkImage(
          imageUrl: story.imageUrl!,
          fit: BoxFit.cover,
          fadeOutDuration: Duration.zero,
          fadeInDuration: Duration.zero,
          placeholder: (c, u) => const Center(
              child: CircularProgressIndicator(
                  color: AppTheme.royalGold, strokeWidth: 2)),
          errorWidget: (context, url, error) =>
              const Center(child: Icon(Icons.error, color: Colors.white30)),
        )
      : const Center(child: Icon(Icons.broken_image, color: Colors.white30, size: 50));
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return '${diff.inMinutes} د';
    if (diff.inHours < 24) return '${diff.inHours} س';
    return '${diff.inDays} يوم';
  }

  Future<void> _toggleLike() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    HapticFeedback.mediumImpact();

    final bool wasLiked = _currentStory.likes.contains(uid);
    await _fs.toggleStoryLike(_currentStory.id, uid);

    if (!wasLiked) {
      try {
        final roomId =
            await _fs.ensureChatRoomExists(uid, _currentStory.userId);
        final message = MessageModel(
          id: '',
          senderId: uid,
          text: '❤️ أعجب بقصتك',
          timestamp: DateTime.now(),
          type: MessageType.text,
        );
        await _fs.sendMessage(roomId, message);
      } catch (e) {
        debugPrint('Error sending like message: $e');
      }

      if (mounted && !_isClosing) {
        setState(() {
          _showHeart = true;
          _heartTimer?.cancel();
          _heartTimer = Timer(const Duration(milliseconds: 800),
              () => setState(() => _showHeart = false));
        });
      }
    }

    if (mounted && !_isClosing) {
      setState(() {
        if (wasLiked) {
          _currentStory.likes.remove(uid);
        } else {
          _currentStory.likes.add(uid);
        }
      });
    }
  }

  Future<void> _sendReply(String text) async {
    if (text.trim().isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final userSnap = await _fs.streamUserData(uid).first;

    // تسجيل الرد في نظام الستوري (اختياري)
    await _fs.addStoryReply(
        _currentStory.id, uid, userSnap.name, userSnap.profilePic, text);

    // إرسال الرسالة للمحادثة الحقيقية (بناءً على طلب المستخدم)
    try {
      final roomId = await _fs.ensureChatRoomExists(uid, _currentStory.userId);
      final message = MessageModel(
        id: '',
        senderId: uid,
        text: 'رد على قصتك: $text',
        timestamp: DateTime.now(),
        type: MessageType.text,
      );
      await _fs.sendMessage(roomId, message);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('تم إرسال الرد للمحادثة الخاصة ✅'),
            duration: Duration(seconds: 1)));
      }
    } catch (e) {
      debugPrint('Error sending private reply: $e');
    }

    _resume();
  }

  void _showViewers() {
    _pause();
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => Column(
        children: [
          const SizedBox(height: 12),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2))),
          const Padding(
              padding: EdgeInsets.all(20),
              child: Text('المشاهدات',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold))),
          Expanded(
            child: ListView.builder(
              itemCount: _currentStory.viewers.length,
              itemBuilder: (context, i) => StreamBuilder(
                stream: _fs.streamUserData(_currentStory.viewers[i]),
                builder: (context, snap) {
                  if (!snap.hasData) return const SizedBox();
                  final viewer = snap.data!;
                  return ListTile(
                    leading: CircleAvatar(
                        backgroundImage:
                            (viewer.profilePic.isNotEmpty && Uri.tryParse(viewer.profilePic)?.host.isNotEmpty == true)
                              ? CachedNetworkImageProvider(viewer.profilePic)
                              : null,
                        child: (viewer.profilePic.isEmpty || Uri.tryParse(viewer.profilePic)?.host.isNotEmpty != true)
                          ? const Icon(Icons.person, color: Colors.white24)
                          : null,
                    ),
                    title: Text(viewer.name,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14)),
                    trailing: _currentStory.likes.contains(viewer.uid)
                        ? const Icon(Icons.favorite_rounded,
                            color: Colors.redAccent, size: 20)
                        : null,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    ).whenComplete(() => _resume());
  }

  void _showDeleteConfirmation() {
    _pause();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('تأكيد الحذف', style: TextStyle(color: Colors.white)),
        content: const Text('هل أنت متأكد من حذف هذه القصة؟',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء',
                style: TextStyle(color: AppTheme.royalGold)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _deleteStory();
            },
            child: const Text('حذف', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    ).then((_) => _resume());
  }

  Future<void> _deleteStory() async {
    try {
      await _fs.deleteStory(_currentStory.id);
      if (mounted && !_isClosing) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف القصة بنجاح ✅'),
            duration: Duration(seconds: 1),
          ),
        );
        // العودة إلى الصفحة السابقة بعد الحذف
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _closeViewer();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في حذف القصة: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      _resume();
    }
  }

  void _showReportStory() {
    _pause();
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('إبلاغ عن قصة غير لائقة', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'سبب الإبلاغ...',
            hintStyle: TextStyle(color: Colors.white24),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.white38))),
          TextButton(onPressed: () async {
            if (reasonController.text.trim().isEmpty) return;
            final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
            await FirebaseFirestore.instance.collection('reports').add({
              'type': 'story',
              'targetId': _currentStory.id,
              'targetName': _currentStory.userName,
              'reason': reasonController.text.trim(),
              'reporterId': uid,
              'reporterName': 'User',
              'createdAt': FieldValue.serverTimestamp(),
              'status': 'new',
            });
            if (context.mounted) Navigator.pop(ctx);
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال البلاغ للإدارة')));
          }, child: const Text('إرسال', style: TextStyle(color: AppTheme.royalGold))),
        ],
      ),
    ).then((_) => _resume());
  }
}
