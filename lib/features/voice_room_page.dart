import '../widgets/online_users_sheet.dart'; // تأكد من صحة المسار
import 'package:flutter/services.dart';
import 'profile/user_profile_page.dart';
import 'rooms/widgets/announced_room_info_sheet.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:marquee/marquee.dart';
import 'package:file_picker/file_picker.dart';
import '../services/agora_service.dart';
import '../services/room_presence_service.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'rooms/widgets/gift_shop_sheet.dart';
import 'rooms/widgets/room_info_sheet.dart';
import 'rooms/widgets/battle_result_dialog.dart';
import 'rooms/widgets/room_more_menu_sheet.dart';
import 'rooms/widgets/gift_animation_widget.dart';
import 'rooms/widgets/lucky_box_dialog.dart';
import 'rooms/widgets/leaderboard_sheet.dart';

import 'rooms/widgets/moderation/silence_user_sheet.dart';
import 'rooms/widgets/moderation/ban_user_sheet.dart';
import 'rooms/widgets/moderation/kick_user_sheet.dart';
import 'rooms/widgets/moderation/penalty_user_sheet.dart';
import 'rooms/widgets/moderation/mute_user_sheet.dart';

import 'dart:async';
import 'dart:math' as math;
import '../app_theme.dart';
import '../services/firestore_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class VoiceRoomPage extends StatefulWidget {
  final String roomId;
  final String roomName;
  final String? roomImage;
  final String? ownerId;

  const VoiceRoomPage({
    super.key,
    required this.roomId,
    required this.roomName,
    this.roomImage,
    this.ownerId,
  });

  @override
  State<VoiceRoomPage> createState() => _VoiceRoomPageState();
}

class _VoiceRoomPageState extends State<VoiceRoomPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final FirestoreService _firestoreService = FirestoreService();
  late String _roomName;
  bool _showEntryBanner = false;
  String _entryBannerText = '';
  final TextEditingController _messageController = TextEditingController();
  final AgoraService _agoraService = AgoraService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isMuted = false;
  bool _isMicMuted = false;
  bool _noiseReduction = false;
  bool _eyeComfort = false;
  bool _dataSaverMode = false;

  String _roomNoticeText =
      'اهلا بكم في رويال دور , يرجى الدردشه بطريقه لائقة تليق بالمجتمع';
  String? _dynamicBgImage;
  String? _dynamicRoomImage;
  String _micMode = 'normal';
  int _maxSeats = 5; // تقليل عدد المايكات من 10 إلى 5 لتوفير التكلفة

  bool _muteChatGlobal = false;
  bool _adminOnlyMic = false;

  Map<int, Map<String, dynamic>> _micSeats = {};
  Set<int> _lockedSeats = {};
  List<String> _moderators = [];
  int? _mySeat;

  Map<String, dynamic>? _battleData;
  Timer? _battleTimer;
  bool _resultShown = false;

  String get _currentUserId => _auth.currentUser?.uid ?? '';

  late AnimationController _giftAnimController;
  late AnimationController _speakingAnimController;
  late AnimationController _boxAnimController;
  late AnimationController _comboAnimController;
  late AnimationController _entryAnimController;

  StreamSubscription? _announcementSub;
  bool _showCapsule = false;
  Map<String, dynamic>? _capsuleData;
  Timer? _capsuleTimer;

  String? _lastGiftEventId;
  bool _initialGiftLoaded = false;
  String? _currentEntryEffect;
  String? _entryUserName;

  final List<Map<String, dynamic>> _giftQueue = [];
  bool _isGiftPlaying = false;

  final List<Widget> _floatingHearts = [];

  Future<int> _getCapsuleRoomStats(String? roomId) async {
    if (roomId == null || roomId.isEmpty) return 0;
    int followers = 0;
    try {
      final followersSnap = await _db
          .collection('users')
          .where('following_rooms.$roomId', isEqualTo: true)
          .get();
      followers = followersSnap.docs.length;
    } catch (e) {
      // ignore error, show 0
    }
    return followers;
  }

  // --- Music Player State ---
  bool _isMusicPlaying = false;

  double _musicVolume = 60.0;
  int _musicDuration = 0;
  int _musicPosition = 0;
  StreamSubscription? _musicPositionSub;
  String _currentMusicName = 'لم يتم اختيار ملف';

  StreamSubscription? _volumeSub;
  StreamSubscription? _connectionSub;
  Timer? _inactivityMuteTimer;
  Timer? _inactivityKickTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    RoomPresenceService().closeMinimized();

    _roomName = widget.roomName;

    _giftAnimController =
        AnimationController(duration: const Duration(seconds: 1), vsync: this)
          ..repeat(reverse: true);
    _speakingAnimController = AnimationController(
        duration: const Duration(milliseconds: 800), vsync: this)
      ..repeat(reverse: true);
    _boxAnimController = AnimationController(
        duration: const Duration(milliseconds: 500), vsync: this)
      ..repeat(reverse: true);
    _comboAnimController =
        AnimationController(duration: const Duration(seconds: 2), vsync: this);
    _entryAnimController =
        AnimationController(duration: const Duration(seconds: 4), vsync: this);

    _initAgora();
    _listenToRoomChanges();
    _listenToMicSeats();
    _updatePresence(true);
    _checkMyVipStatus();
    _cleanupOldSeats();
    _listenToNewEntries();
    _listenToGlobalAnnouncements();
    _listenToMusicStream();
    _listenToVolumeIndication();
    _listenToConnectionState();
  }

  /// الاستماع إلى حالة اتصال Agora
  /// - يكتشف انقطاع الاتصال وفشل الاتصال
  /// - يخرج المستخدم تلقائياً عند انقطاع الاتصال لتوفير التكلفة
  /// - يمنع الاستمرار في حساب المستخدم عند انقطاع الاتصال
  void _listenToConnectionState() {
    _connectionSub = _agoraService.connectionStream.listen((state) {
      if (state == ConnectionStateType.connectionStateDisconnected ||
          state == ConnectionStateType.connectionStateFailed) {
        if (mounted) {
          _performForcedExit(reason: 'انقطع الاتصال بالخادم 📡');
        }
      }
    });
  }

  /// الخروج القسري من الغرفة
  /// - يستخدم عند انقطاع الاتصال أو الأخطاء
  /// - ينظف جميع الموارد لتوفير التكلفة ومنع تسرب الذاكرة
  /// - يغادر قناة Agora لتوقف الحساب
  void _performForcedExit({String? reason}) async {
    if (!mounted) return;
    if (reason != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(reason)));
    }

    // تنظيف المايك والوجود قبل الخروج
    // هذا يوقف حساب التكلفة على هذا المستخدم
    _leaveMic();
    _updatePresence(false);
    _agoraService.stopMusic();
    _agoraService.leave();
    RoomPresenceService().closeMinimized();

    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _listenToVolumeIndication() {
    _volumeSub = _agoraService.volumeStream.listen((speakers) {
      if (!mounted) return;

      bool isSpeaking = false;
      for (var speaker in speakers) {
        // uid == 0 هو المستخدم المحلي
        if (speaker.uid == 0 && (speaker.volume ?? 0) > 20) {
          isSpeaking = true;
          break;
        }
      }

      if (isSpeaking) {
        _resetInactivityTimers();
      } else {
        _startInactivityTimers();
      }
    });
  }

  void _resetInactivityTimers() {
    _inactivityMuteTimer?.cancel();
    _inactivityMuteTimer = null;
    _inactivityKickTimer?.cancel();
    _inactivityKickTimer = null;
  }

  /// بدء مؤقتات الخمول لتوفير التكلفة
  /// - Auto-Mute بعد 5 ثواني من الصمت (لتوفير التكلفة - فقط المتحدثين يحسب عليهم السعر)
  /// - الخروج التلقائي بعد 60 دقيقة من الصمت (تم زيادة الوقت من 30 إلى 60 دقيقة)
  void _startInactivityTimers() {
    // 1. مؤقت الكتم (5 ثواني) - فقط إذا كان على المايك وغير مكتوم
    // هذا يوفر التكلفة لأن المستخدم يتحول إلى مستمع (Audience) عند الكتم
    if (_mySeat != null && !_isMicMuted && _inactivityMuteTimer == null) {
      _inactivityMuteTimer = Timer(const Duration(seconds: 5), () {
        if (mounted && _mySeat != null && !_isMicMuted) {
          _toggleMicMute();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('تم كتم المايك تلقائياً بسبب عدم التحدث لـ 5 ثواني 🔇'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      });
    }

    // 2. مؤقت الخروج التلقائي (60 دقيقة صمت) - تم زيادة الوقت لتجنب الطرد المفاجئ
    _inactivityKickTimer ??= Timer(const Duration(minutes: 60), () {
      if (mounted) {
        _performForcedExit(
            reason: 'تم الخروج تلقائياً بسبب الصمت لمدة 60 دقيقة 💤');
      }
    });
  }

  void _checkMyVipStatus() async {
    await _db.collection('users').doc(_currentUserId).get();
    if (mounted) {
      setState(() {
        // VIP rank data loaded but not currently displayed
      });
    }
  }

  void _listenToMusicStream() {
    _musicPositionSub = _agoraService.musicPositionStream.listen((pos) {
      if (mounted && _isMusicPlaying) {
        setState(() {
          _musicPosition = pos;
        });
        if (_musicDuration > 0 && pos >= _musicDuration - 500) {
          _stopMusicLocally();
        }
      }
    });
  }

  void _stopMusicLocally() {
    if (!mounted) return;
    setState(() {
      _isMusicPlaying = false;
      _musicPosition = 0;
    });
  }

  String _formatDuration(int msec) {
    if (msec <= 0) return "00:00";
    Duration duration = Duration(milliseconds: msec);
    String minutes = duration.inMinutes.toString().padLeft(2, '0');
    String seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  void _listenToGlobalAnnouncements() {
    _announcementSub = _db
        .collection('global_announcements')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snap) {
      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data();
        final Timestamp? ts = data['timestamp'];
        if (ts != null &&
            ts.toDate().isAfter(
                DateTime.now().subtract(const Duration(seconds: 10)))) {
          if (data['roomId'] != widget.roomId) {
            _triggerCapsule(data);
          }
        }
      }
    });
  }

  void _triggerCapsule(Map<String, dynamic> data) {
    if (!mounted) return;
    _capsuleTimer?.cancel();
    setState(() {
      _capsuleData = data;
      _showCapsule = true;
    });
    _capsuleTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) setState(() => _showCapsule = false);
    });
  }

  void _cleanupOldSeats() async {
    final seats = await _db
        .collection('rooms')
        .doc(widget.roomId)
        .collection('mic_seats')
        .where('userId', isEqualTo: _currentUserId)
        .get();
    for (var doc in seats.docs) {
      await doc.reference.delete();
    }
  }

  void _listenToNewEntries() {
    _db
        .collection('rooms')
        .doc(widget.roomId)
        .collection('online_users')
        .orderBy('joinedAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snap) async {
      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data();
        final String uid = data['uid'];
        if (uid == _currentUserId) return;
        final userDoc = await _db.collection('users').doc(uid).get();
        final String? effect = userDoc.data()?['entryEffect'];
        if (effect != null && mounted) {
          setState(() {
            _currentEntryEffect = effect;
            _entryUserName = userDoc.data()?['name'] ?? 'ملك رويال';
          });
          _entryAnimController.forward(from: 0).then((_) {
            if (mounted) setState(() => _currentEntryEffect = null);
          });
        }
      }
    });
  }

  void _updatePresence(bool isJoining) async {
    if (_currentUserId.isEmpty) return;
    final roomRef = _db.collection('rooms').doc(widget.roomId);
    if (isJoining) {
      final userDoc = await _db.collection('users').doc(_currentUserId).get();
      final String noble = userDoc.data()?['nobleLevel'] ?? 'N1';
      final String name = _auth.currentUser?.displayName ?? 'مستخدم';

      await _firestoreService.increaseRoomExp(widget.roomId, 40);

      await roomRef.collection('online_users').doc(_currentUserId).set({
        'uid': _currentUserId,
        'name': name,
        'joinedAt': FieldValue.serverTimestamp(),
        'nobleLevel': noble
      });
      if (mounted) {
        setState(() {
          _entryBannerText = 'أهلاً بك $name في رويال دور 👑✨';
          _showEntryBanner = true;
        });
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) setState(() => _showEntryBanner = false);
        });
      }
    } else {
      if (_mySeat != null) {
        await roomRef.collection('mic_seats').doc(_mySeat.toString()).delete();
      }
      try {
        final chatSnap = await roomRef
            .collection('chat')
            .where('senderId', isEqualTo: _currentUserId)
            .get();
        final batch = _db.batch();
        for (var doc in chatSnap.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      } catch (e) {
        debugPrint("Error deleting chat: $e");
      }
      await roomRef.collection('online_users').doc(_currentUserId).delete();
    }
  }

  void _listenToRoomChanges() {
    _db.collection('rooms').doc(widget.roomId).snapshots().listen((doc) {
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (mounted) {
          setState(() {
            _dynamicBgImage = data['backgroundImage'];
            _dynamicRoomImage = data['roomImage'];
            _roomNoticeText = data['notice'] ?? _roomNoticeText;
            _lockedSeats = Set<int>.from(data['lockedSeats'] ?? []);
            _moderators = List<String>.from(data['moderators'] ?? []);
            _micMode = data['micMode'] ?? 'normal';
            _muteChatGlobal = data['muteChat'] ?? false;
            _adminOnlyMic = data['adminOnlyMic'] ?? false;
            _maxSeats = data['maxSeats'] ?? 10;
            var newBattleData = data['battle'];
            if (newBattleData != null && newBattleData['active'] == true) {
              _battleData = newBattleData;
              _resultShown = false;
              _startBattleCountdown();
            } else {
              if (_battleData != null &&
                  _battleData!['active'] == true &&
                  !_resultShown) {
                _showBattleResult(_battleData!['redPoints'] ?? 0,
                    _battleData!['bluePoints'] ?? 0);
                _resultShown = true;
              }
              _battleData = newBattleData;
              _battleTimer?.cancel();
            }
          });
        }
      }
    });
  }

  void _listenToMicSeats() {
    _db
        .collection('rooms')
        .doc(widget.roomId)
        .collection('mic_seats')
        .snapshots()
        .listen((snap) {
      Map<int, Map<String, dynamic>> newSeats = {};
      int? foundMySeat;
      for (var doc in snap.docs) {
        int index = int.parse(doc.id);
        newSeats[index] = doc.data();
        if (doc.data()['userId'] == _currentUserId) foundMySeat = index;
      }
      if (mounted) {
        setState(() {
          _micSeats = newSeats;
          _mySeat = foundMySeat;
        });
      }
    });
  }

  /// تهيئة Agora والانضمام إلى القناة الصوتية
  /// - جميع المستخدمين يدخلون كمستمعين (Audience) لتوفير التكلفة
  /// - المايك مكتوم تلقائياً عند الدخول
  /// - استخدام Token للإنتاج (أمان عالي)
  /// - جودة صوت منخفضة (audioProfileSpeechStandard) لتوفير التكلفة
  Future<void> _initAgora() async {
    await _agoraService.init();
    try {
      // الانضمام كمستمع (asSpeaker: false) لتوفير التكلفة
      // فقط عند أخذ المايك يتحول المستخدم إلى متحدث (Broadcaster)
      await _agoraService.joinChannel(
          channelId: widget.roomId, asSpeaker: false);
    } catch (e) {
      debugPrint("Agora error: $e");
    }
  }

  /// تنظيف الموارد عند الخروج من الصفحة
  /// - مهم جداً لمنع تسرب الذاكرة (Memory Leak Prevention)
  /// - مغادرة قناة Agora لتوفير التكلفة ومنع الاستمرار في الفاتورة
  /// - إلغاء جميع الاشتراكات (Stream Subscriptions)
  /// - إلغاء جميع المؤقتات (Timers)
  /// - إطلاق جميع Animation Controllers
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!RoomPresenceService().isMinimized) {
      _updatePresence(false);
    }
    _announcementSub?.cancel();
    _capsuleTimer?.cancel();
    _battleTimer?.cancel();
    _musicPositionSub?.cancel();
    _volumeSub?.cancel();
    _connectionSub?.cancel();
    _inactivityMuteTimer?.cancel();
    _inactivityKickTimer?.cancel();
    _agoraService.stopMusic();
    // مغادرة قناة Agora لتوفير التكلفة ومنع تسرب الذاكرة
    // هذا يمنع Agora من الاستمرار في حساب المستخدم بعد الخروج
    _agoraService.leave();
    _messageController.dispose();
    _giftAnimController.dispose();
    _speakingAnimController.dispose();
    _boxAnimController.dispose();
    _comboAnimController.dispose();
    _entryAnimController.dispose();
    super.dispose();
  }

  bool get _hasPower =>
      _currentUserId == widget.ownerId || _moderators.contains(_currentUserId);

  /// أخذ المايك (Seat)
  /// - يتحول المستخدم من مستمع (Audience) إلى متحدث (Broadcaster)
  /// - يحسب عليه السعر فقط عند التحدث
  /// - يتحقق من صلاحيات الإدارة والمايكات المغلقة
  /// - يحد من عدد المايكات إلى 5 فقط لتوفير التكلفة
  void _takeMic(int seatNumber) async {
    HapticFeedback.lightImpact(); // اهتزاز خفيف عند لمس المايك
    if (_adminOnlyMic && !_hasPower) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('عذراً، المايك مخصص للمسؤولين حالياً 👑')));
      }
      return;
    }
    if (_lockedSeats.contains(seatNumber) && !_hasPower) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('هذا المايك مغلق من قبل الإدارة 🔒')));
      }
      return;
    }
    if (_mySeat != null) {
      await _db
          .collection('rooms')
          .doc(widget.roomId)
          .collection('mic_seats')
          .doc(_mySeat.toString())
          .delete();
    }
    final userDoc = await _db.collection('users').doc(_currentUserId).get();
    final String? micFrame = userDoc.data()?['currentFrame'];
    await _db
        .collection('rooms')
        .doc(widget.roomId)
        .collection('mic_seats')
        .doc(seatNumber.toString())
        .set({
      'userId': _currentUserId,
      'name': _auth.currentUser?.displayName ?? 'مستخدم',
      'photoUrl': _auth.currentUser?.photoURL ?? '',
      'isMuted': false,
      'timestamp': FieldValue.serverTimestamp(),
      'agoraUid': _agoraService.localUid,
      'micFrame': micFrame,
    });
    // تحويل الدور لمتحدث (Broadcaster) عند أخذ المايك
    // هذا يبدأ حساب التكلفة على هذا المستخدم فقط
    await _agoraService.updateClientRole(true);
    setState(() {
      _mySeat = seatNumber;
      _isMicMuted = false;
    });
  }

  /// مغادرة المايك (Seat)
  /// - يتحول المستخدم من متحدث (Broadcaster) إلى مستمع (Audience)
  /// - يتوقف حساب التكلفة على هذا المستخدم
  /// - مهم جداً لتوفير التكلفة
  void _leaveMic() async {
    HapticFeedback.mediumImpact(); // اهتزاز عند النزول
    if (_mySeat != null) {
      await _db
          .collection('rooms')
          .doc(widget.roomId)
          .collection('mic_seats')
          .doc(_mySeat.toString())
          .delete();
      // العودة لدور مستمع (Audience) لتوفير التكاليف
      // هذا يوقف حساب التكلفة على هذا المستخدم
      await _agoraService.updateClientRole(false);
      if (mounted) setState(() => _mySeat = null);
    }
  }

  /// كتم/فتح المايك مع تحديث الدور تلقائياً
  /// - عند الكتم: يتحول إلى مستمع (Audience) - لا يحسب عليه السعر
  /// - عند الفتح: يتحول إلى متحدث (Broadcaster) - يحسب عليه السعر
  /// - هذا يضمن التوفير التلقائي للتكلفة عند الصمت
  void _toggleMicMute() async {
    if (_mySeat == null) return;
    bool newMute = !_isMicMuted;
    setState(() => _isMicMuted = newMute);

    await _db
        .collection('rooms')
        .doc(widget.roomId)
        .collection('mic_seats')
        .doc(_mySeat.toString())
        .update({'isMuted': newMute});

    // عند الكتم، يتحول المستخدم إلى مستمع (Audience) تلقائياً لتقليل استهلاك أكورا
    // هذا يوقف حساب التكلفة على هذا المستخدم
    // وعند تفعيل المايك يعود متحدثاً (Broadcaster) ويبدأ الحساب
    await _agoraService.toggleMute(newMute);

    HapticFeedback.selectionClick();
  }

  void _onSendPressed({String? customText, bool isSystem = false}) async {
    HapticFeedback.lightImpact(); // اهتزاز عند الإرسال
    _resetInactivityTimers(); // تصفير عدادات الخمول عند إرسال رسالة
    final text = customText ?? _messageController.text.trim();
    if (text.isEmpty) return;
    if (_muteChatGlobal && !_hasPower && !isSystem) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('الدردشة مغلقة حالياً من قبل الإدارة 🔇')));
      }
      return;
    }
    if (customText == null) _messageController.clear();
    final userSnap = await _db.collection('users').doc(_currentUserId).get();
    final String noble = userSnap.data()?['nobleLevel'] ?? 'N1';

    await _firestoreService.increaseRoomExp(widget.roomId, 1);

    await _db.collection('rooms').doc(widget.roomId).collection('chat').add({
      'senderId': isSystem ? 'system' : _currentUserId,
      'senderName':
          isSystem ? 'نظام' : (_auth.currentUser?.displayName ?? 'مستخدم ملكي'),
      'senderPic': isSystem ? '' : (_auth.currentUser?.photoURL ?? ''),
      'text': text,
      'isSystem': isSystem,
      'nobleLevel': noble,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void _handleTap(bool isBlueTeam, Offset position) async {
    if (_battleData == null || _battleData!['active'] != true) return;
    _addFloatingHeart(position, isBlueTeam ? Colors.blue : Colors.red);
    final field = isBlueTeam ? 'battle.bluePoints' : 'battle.redPoints';
    await _db
        .collection('rooms')
        .doc(widget.roomId)
        .update({field: FieldValue.increment(1)});
  }

  void _addFloatingHeart(Offset pos, Color color) {
    setState(() {
      _floatingHearts.add(_FloatingHeart(
          key: UniqueKey(),
          position: pos,
          color: color,
          onComplete: (key) {
            setState(() => _floatingHearts.removeWhere((h) => h.key == key));
          }));
    });
  }

  Future<void> _pickAndPlayMusic() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final name = result.files.single.name;
      await _agoraService.startMusic(path);

      await Future.delayed(const Duration(milliseconds: 1000));
      final duration = await _agoraService.getMusicDuration();

      if (mounted) {
        setState(() {
          _isMusicPlaying = true;
          _musicDuration = duration;
          _currentMusicName = name;
          _musicPosition = 0;
        });
      }
    }
  }

  void _toggleMusic() async {
    if (_isMusicPlaying) {
      await _agoraService.pauseMusic();
    } else {
      await _agoraService.resumeMusic();
    }
    if (mounted) setState(() => _isMusicPlaying = !_isMusicPlaying);
  }

  @override
  Widget build(BuildContext context) {
    bool isBattleActive = _battleData != null && _battleData!['active'] == true;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            _buildBackground(),
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  _buildMarqueeBar(),
                  _buildGiftEventListener(),
                  Expanded(
                    child: Stack(
                      children: [
                        CustomScrollView(
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            // 1. المايكات وتوزيعها الديناميكي حسب النمط
                            SliverPadding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 15),
                                sliver: _buildDynamicMicLayout(isBattleActive)),
                            // 2. شريط المعركة (النجوم والوقت) تحت المايكات مباشرة
                            if (isBattleActive)
                              SliverToBoxAdapter(child: _buildBattleBar()),
                            SliverToBoxAdapter(
                                child: Column(children: [
                              const SizedBox(height: 10),
                              _buildRoomNotice()
                            ])),
                          ],
                        ),
                        if (isBattleActive) ...[
                          Positioned(
                              left: 0,
                              top: 100,
                              bottom: 200,
                              width: MediaQuery.of(context).size.width / 2,
                              child: GestureDetector(
                                  onTapDown: (d) =>
                                      _handleTap(true, d.globalPosition),
                                  behavior: HitTestBehavior.translucent,
                                  child: Container())),
                          Positioned(
                              right: 0,
                              top: 100,
                              bottom: 200,
                              width: MediaQuery.of(context).size.width / 2,
                              child: GestureDetector(
                                  onTapDown: (d) =>
                                      _handleTap(false, d.globalPosition),
                                  behavior: HitTestBehavior.translucent,
                                  child: Container())),
                        ],
                        ..._floatingHearts,
                        if (_showEntryBanner)
                          Positioned(
                              top: 20,
                              left: 0,
                              right: 0,
                              child: Center(
                                  child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8, horizontal: 20),
                                      decoration: BoxDecoration(
                                          color: Colors.amber
                                              .withValues(alpha: 0.9),
                                          borderRadius:
                                              BorderRadius.circular(25),
                                          boxShadow: const [
                                            BoxShadow(
                                                color: Colors.black26,
                                                blurRadius: 10,
                                                offset: Offset(0, 4))
                                          ]),
                                      child: Text(_entryBannerText,
                                          style: const TextStyle(
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14))))),
                        if (_showCapsule && _capsuleData != null)
                          _buildRoyalCapsule(),
                      ],
                    ),
                  ),
                  if (isBattleActive) _buildBattleNotificationOverlay(),
                  _buildChatArea(),
                  _buildBottomBar(),
                ],
              ),
            ),
            _buildComboOverlay(),
            _buildVipEntryOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicMicLayout(bool isBattle) {
    // توزيع المايكات بناءً على النمط micMode
    if (_micMode == 'broadcast-5') {
      return SliverToBoxAdapter(
        child: Column(
          children: [
            Center(child: _buildMicSeat(1)), // المايك الرئيسي في الأعلى
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [2, 3, 4, 5].map((n) => _buildMicSeat(n)).toList(),
            ),
          ],
        ),
      );
    } else if (_micMode == 'broadcast-11') {
      return SliverToBoxAdapter(
        child: Column(
          children: [
            Center(child: _buildMicSeat(1)),
            const SizedBox(height: 15),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 15,
              children: List.generate(10, (i) => _buildMicSeat(i + 2)),
            ),
          ],
        ),
      );
    } else if (_micMode == '2-4-4') {
      return SliverToBoxAdapter(
        child: Column(
          children: [
            Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [1, 2]
                    .map((n) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: _buildMicSeat(n)))
                    .toList()),
            const SizedBox(height: 15),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [3, 4, 5, 6].map((n) => _buildMicSeat(n)).toList()),
            const SizedBox(height: 15),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [7, 8, 9, 10].map((n) => _buildMicSeat(n)).toList()),
          ],
        ),
      );
    } else {
      // النمط العادي أو أنماط الدردشة (Grid)
      int crossCount = _micMode == 'chat-15' ? 5 : 5;
      return SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            mainAxisSpacing: 15,
            crossAxisSpacing: 5,
            childAspectRatio: 0.8),
        delegate: SliverChildBuilderDelegate((context, index) {
          int seatNumber = index + 1;
          if (seatNumber > _maxSeats) return null;
          Color? team;
          if (isBattle) {
            if (_maxSeats >= 30) {
              team = (seatNumber % 2 == 0) ? Colors.blue : Colors.red;
            } else {
              if ([5, 4, 3, 10, 9].contains(seatNumber)) team = Colors.blue;
              if ([2, 1, 8, 7, 6].contains(seatNumber)) team = Colors.red;
            }
          }
          return _buildMicSeat(seatNumber, teamColor: team);
        }, childCount: _maxSeats),
      );
    }
  }

  Widget _buildBattleNotificationOverlay() {
    if (_battleData == null || _battleData!['active'] != true) {
      return const SizedBox.shrink();
    }
    String mode = _battleData!['mode'] ?? 'team';
    String text = mode == 'individual'
        ? '⚔️ تحدي 1 ضد 1: ${_battleData!['redName']} VS ${_battleData!['blueName']}'
        : '⚔️ بدأت الآن معركة الفريق الملكية!';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          Colors.amber.shade800.withValues(alpha: 0.9),
          Colors.orange.shade900.withValues(alpha: 0.9)
        ]),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bolt, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.bolt, color: Colors.white, size: 20),
        ],
      ),
    );
  }

  Widget _buildRoyalCapsule() {
    return Positioned(
      right: 15,
      top: 100,
      child: GestureDetector(
        onTap: () {
          if (_capsuleData?['roomId'] != null) {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              isScrollControlled: true,
              builder: (ctx) =>
                  AnnouncedRoomInfoSheet(roomId: _capsuleData!['roomId']),
            );
          }
        },
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          tween: Tween(begin: 0.0, end: 1.0),
          curve: Curves.elasticOut,
          builder: (context, value, child) => Transform.scale(
              scale: value,
              child: Opacity(opacity: value.clamp(0.0, 1.0), child: child)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  AppTheme.royalGold.withValues(alpha: 0.9),
                  Colors.purple.withValues(alpha: 0.7)
                ]),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white24, width: 1),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 15,
                      spreadRadius: 2)
                ]),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.stars, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_capsuleData?['roomName'] ?? 'غرفة ملكية',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  RichText(
                      text: TextSpan(children: [
                    TextSpan(
                        text: _capsuleData?['senderName'] ?? 'مستخدم',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                    const TextSpan(
                        text: ' أهدى ',
                        style: TextStyle(color: Colors.white70, fontSize: 11)),
                    TextSpan(
                        text: _capsuleData?['giftName'] ?? 'هدية',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                    const TextSpan(
                        text: ' إلى ',
                        style: TextStyle(color: Colors.white70, fontSize: 11)),
                    TextSpan(
                        text: _capsuleData?['receiverName'] ?? 'الجميع',
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ])),
                  const Text('انقر للانتقال للغرفة ➜',
                      style: TextStyle(
                          color: Colors.white54,
                          fontSize: 9,
                          fontStyle: FontStyle.italic)),
                  // إضافة عداد الشعبية (الإعجابات + المعجبين + المتابعين)
                  const SizedBox(height: 4),
                  FutureBuilder<int>(
                    future: _getCapsuleRoomStats(_capsuleData?['roomId']),
                    builder: (context, snapshot) {
                      int total = snapshot.data ?? 0;
                      return Row(
                        children: [
                          const Icon(Icons.favorite,
                              color: Colors.pinkAccent, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            total.toString(),
                            style: const TextStyle(
                              color: Colors.pinkAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(width: 12),
              const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white, size: 14),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildBattleBar() {
    if (_battleData == null) return const SizedBox.shrink();
    int redPoints = _battleData!['redPoints'] ?? 0;
    int bluePoints = _battleData!['bluePoints'] ?? 0;
    double total = _parseDouble(redPoints + bluePoints);
    double blueRatio = total == 0 ? 0.5 : _parseDouble(bluePoints) / total;
    if (blueRatio < 0.05) blueRatio = 0.05;
    if (blueRatio > 0.95) blueRatio = 0.95;
    final remaining = (_battleData!['endTime'] as Timestamp)
        .toDate()
        .difference(DateTime.now());
    String timeStr = remaining.isNegative
        ? "00:00"
        : '${remaining.inMinutes.toString().padLeft(2, '0')}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                const Icon(Icons.shield, color: Colors.blue, size: 16),
                const SizedBox(width: 4),
                Text('$bluePoints',
                    style: const TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.bold))
              ]),
              Row(children: [
                Text('$redPoints',
                    style: const TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                const Icon(Icons.shield, color: Colors.red, size: 16)
              ]),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: SizedBox(
              height: 18,
              child: Row(
                children: [
                  Expanded(
                    flex: (blueRatio * 100).toInt() + 1,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Colors.blue.shade900,
                          Colors.blue.shade400
                        ]),
                      ),
                      child: const Center(
                          child: Text('BLUE',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold))),
                    ),
                  ),
                  Expanded(
                    flex: ((1 - blueRatio) * 100).toInt() + 1,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [Colors.red.shade400, Colors.red.shade900]),
                      ),
                      child: const Center(
                          child: Text('RED',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold))),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white10, width: 0.5)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer, color: Colors.amber, size: 12),
                const SizedBox(width: 4),
                Text('$timeStr PK',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVipEntryOverlay() {
    if (_currentEntryEffect == null) return const SizedBox.shrink();
    return IgnorePointer(
        child: Center(
            child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.amber, width: 2)),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.stars, color: Colors.amber, size: 60),
                  const SizedBox(height: 10),
                  const Text("👑 وصول فخم 👑",
                      style: TextStyle(
                          color: Colors.amber,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  Text(_entryUserName ?? '',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold))
                ]))));
  }

  Widget _buildComboOverlay() {
    return IgnorePointer(
        child: Center(
            child: AnimatedBuilder(
                animation: _comboAnimController,
                builder: (context, child) {
                  if (!_comboAnimController.isAnimating) {
                    return const SizedBox.shrink();
                  }
                  return ScaleTransition(
                      scale: CurvedAnimation(
                          parent: _comboAnimController,
                          curve: Curves.elasticOut),
                      child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(30),
                              border:
                                  Border.all(color: Colors.amber, width: 3)),
                          child: RichText(
                              text: const TextSpan(children: [
                            WidgetSpan(
                                child: Icon(Icons.flash_on,
                                    color: Colors.amber, size: 80)),
                            TextSpan(
                                text: "\nGIFT COMBO!",
                                style: TextStyle(
                                    color: Colors.amber,
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    fontStyle: FontStyle.italic)),
                            TextSpan(
                                text: "\nأحدهم يشعل الأجواء 🔥",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold))
                          ]))));
                })));
  }

  Widget _buildChatArea() {
    return Container(
        height: 180,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('rooms')
                .doc(widget.roomId)
                .collection('chat')
                .orderBy('timestamp', descending: true)
                .limit(50)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              final docs = snapshot.data!.docs.where((doc) {
                final d = doc.data() as Map<String, dynamic>;
                final text = d['text'] ?? '';
                final isSystem = d['isSystem'] == true;
                if (isSystem &&
                    (text.contains('دخل') || text.contains('انضم'))) {
                  return false;
                }
                if (isSystem && text.contains('بدأت الآن معركة')) return false;
                return true;
              }).toList();
              return ListView.builder(
                  reverse: true,
                  itemCount: docs.length,
                  cacheExtent: 500,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    bool isSystem = data['isSystem'] == true;
                    bool isOwner = data['senderId'] == widget.ownerId;
                    String noble = data['nobleLevel'] ?? 'N1';
                    return Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                                color: isSystem
                                    ? Colors.amber.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(15)),
                            child: Directionality(
                                textDirection: TextDirection.rtl,
                                child: RichText(
                                    text: TextSpan(children: [
                                  if (noble != 'N1')
                                    const WidgetSpan(
                                        child: Padding(
                                            padding: EdgeInsets.only(left: 4),
                                            child: Icon(Icons.workspace_premium,
                                                color: Colors.amber,
                                                size: 14))),
                                  if (isOwner)
                                    const WidgetSpan(
                                        child: Padding(
                                            padding: EdgeInsets.only(left: 4),
                                            child: Icon(Icons.stars,
                                                color: Colors.amber,
                                                size: 14))),
                                  TextSpan(
                                      text: isSystem
                                          ? ' '
                                          : '${data['senderName']}: ',
                                      style: TextStyle(
                                          color: noble != 'N1'
                                              ? Colors.amber
                                              : (isOwner
                                                  ? Colors.amber
                                                  : Colors.white70),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12)),
                                  TextSpan(
                                      text: data['text'],
                                      style: TextStyle(
                                          color: isSystem
                                              ? Colors.amber
                                              : Colors.white,
                                          fontSize: 13))
                                ])))));
                  });
            }));
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            height: 38,
            padding: const EdgeInsets.only(left: 15, right: 2),
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(77),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => RoomInfoSheet(
                      roomId: widget.roomId,
                      roomName: _roomName,
                      ownerId: widget.ownerId,
                      onRoomNameChanged: (newName) {
                        setState(() {
                          _roomName = newName;
                        });
                      },
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: (_dynamicRoomImage != null &&
                                _dynamicRoomImage != '' &&
                                Uri.tryParse(_dynamicRoomImage!)
                                        ?.host
                                        .isNotEmpty ==
                                    true)
                            ? NetworkImage(_dynamicRoomImage!)
                            : const AssetImage('assets/images/room_party.jpg')
                                as ImageProvider,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _roomName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              StreamBuilder<QuerySnapshot>(
                stream: _db
                    .collection('rooms')
                    .doc(widget.roomId)
                    .collection('online_users')
                    .snapshots(),
                builder: (context, snapshot) {
                  int count = 0;
                  if (snapshot.hasData) {
                    count = snapshot.data!.docs.length;
                  }
                  return GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        barrierColor: Colors.black.withValues(alpha: 0.7),
                        builder: (context) => FractionallySizedBox(
                          heightFactor: 0.75,
                          child: OnlineUsersSheet(roomId: widget.roomId),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.25),
                            Colors.white.withValues(alpha: 0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.group,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 5),
                          Text(
                            '$count',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              GestureDetector(
                onTap: () => _showMoreMenu(context), // Keep this
                child:
                    const Icon(Icons.more_horiz, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 15),
              IconButton(
                icon: const Icon(Icons.power_settings_new,
                    color: Colors.white, size: 26),
                onPressed: () => _showExitOptions(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showLeaderboard() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => LeaderboardSheet(roomId: widget.roomId));
  }

  Widget _buildBottomBar() {
    bool canChat = !_muteChatGlobal || _hasPower;
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 5, 15, 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          GestureDetector(
              onTap: () {
                showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (context) => GiftShopSheet(roomId: widget.roomId));
              },
              child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                          colors: [Colors.purple, Colors.pink, Colors.orange])),
                  child: const Icon(Icons.card_giftcard,
                      color: Colors.white, size: 22))),
          const SizedBox(width: 8),
          GestureDetector(
              onTap: _showLuckyBox,
              child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Colors.amber),
                  child: const Icon(Icons.card_membership,
                      color: Colors.black, size: 20))),
          const SizedBox(width: 10),
          Expanded(
              child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
                color: Colors.black54, borderRadius: BorderRadius.circular(25)),
            child: Row(
              children: [
                Expanded(
                    child: TextField(
                  controller: _messageController,
                  enabled: canChat,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                      hintText: canChat ? 'قل شيئاً...' : 'الدردشة مغلقة 🔇',
                      hintStyle: const TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                      isDense: true),
                )),
                IconButton(
                    icon: const Icon(Icons.send, color: Colors.amber),
                    onPressed: () => _onSendPressed())
              ],
            ),
          )),
          IconButton(
              icon: Icon(_isMuted ? Icons.volume_off : Icons.volume_up,
                  color: _isMuted ? Colors.redAccent : Colors.white, size: 26),
              onPressed: () {
                setState(() => _isMuted = !_isMuted);
                _agoraService.toggleAllRemoteAudio(_isMuted);
              }),
        ],
      ),
    );
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => RoomMoreMenuSheet(
              roomId: widget.roomId,
              roomName: widget.roomName,
              roomImage: _dynamicRoomImage ?? widget.roomImage,
              hasPower: _hasPower,
              isBattleActive:
                  _battleData != null && _battleData!['active'] == true,
              micMode: _micMode,
              noiseReduction: _noiseReduction,
              eyeComfort: _eyeComfort,
              onNoiseReductionChanged: (v) =>
                  setState(() => _noiseReduction = v),
              onEyeComfortChanged: (v) => setState(() => _eyeComfort = v),
              onEndBattle: _endBattle,
              onFixAudio: () {},
              onShowLeaderboard: _showLeaderboard,
              extraWidgets: [
                if (_hasPower)
                  ListTile(
                      leading:
                          const Icon(Icons.music_note, color: Colors.amber),
                      title: const Text('مشغل MP3',
                          style: TextStyle(color: Colors.white)),
                      onTap: () {
                        Navigator.pop(context);
                        _showMusicPlayer();
                      }),
                ListTile(
                    leading:
                        const Icon(Icons.group_add, color: Colors.cyanAccent),
                    title: const Text('نادي المعجبين',
                        style: TextStyle(color: Colors.white)),
                    subtitle: const Text('كن جزءاً من عائلة الغرفة',
                        style: TextStyle(color: Colors.white38, fontSize: 10)),
                    onTap: () {
                      Navigator.pop(context);
                      _showFanClubList();
                    }),
                SwitchListTile(
                    title: const Text('توفير البيانات',
                        style: TextStyle(color: Colors.white)),
                    value: _dataSaverMode,
                    onChanged: (v) => setState(() => _dataSaverMode = v)),
              ],
              ownerId: widget.ownerId,
            ));
  }

  void _showFanClubList() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1B25),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      isScrollControlled: true,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(2)),
                margin: const EdgeInsets.only(bottom: 20)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('نادي المعجبين 🏆',
                    style: TextStyle(
                        color: Colors.amber,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                StreamBuilder<DocumentSnapshot>(
                    stream: _db
                        .collection('rooms')
                        .doc(widget.roomId)
                        .collection('fan_club')
                        .doc(_currentUserId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      bool isMember = snapshot.hasData && snapshot.data!.exists;
                      if (isMember) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.green)),
                          child: const Text('أنت عضو',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold)),
                        );
                      }
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20))),
                        onPressed: () async {
                          await _joinFanClub();
                        },
                        child: const Text('انضمام'),
                      );
                    }),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                  stream: _db
                      .collection('rooms')
                      .doc(widget.roomId)
                      .collection('fan_club')
                      .orderBy('joinedAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final membersDocs = snapshot.data!.docs;
                    if (membersDocs.isEmpty) {
                      return const Center(
                          child: Text('لا يوجد معجبون بعد 💔',
                              style: TextStyle(color: Colors.white38)));
                    }
                    return ListView.builder(
                      itemCount: membersDocs.length,
                      itemBuilder: (context, index) {
                        final String memberUid = membersDocs[index].id;
                        final memberData =
                            membersDocs[index].data() as Map<String, dynamic>;

                        return StreamBuilder<DocumentSnapshot>(
                            stream: _db
                                .collection('users')
                                .doc(memberUid)
                                .snapshots(),
                            builder: (context, userSnap) {
                              if (!userSnap.hasData) {
                                return const SizedBox.shrink();
                              }
                              final userData = userSnap.data!.data()
                                  as Map<String, dynamic>?;
                              if (userData == null) {
                                return const SizedBox.shrink();
                              }

                              return ListTile(
                                onTap: () {
                                  Navigator.pop(context);
                                  _showUserCard(memberUid);
                                },
                                leading: CircleAvatar(
                                  backgroundColor:
                                      Colors.amber.withValues(alpha: 0.1),
                                  backgroundImage: (userData['profilePic'] !=
                                              null &&
                                          userData['profilePic'] != '' &&
                                          Uri.tryParse(userData['profilePic'])
                                                  ?.host
                                                  .isNotEmpty ==
                                              true)
                                      ? NetworkImage(userData['profilePic'])
                                      : null,
                                  child: (userData['profilePic'] == null ||
                                          userData['profilePic'] == '' ||
                                          Uri.tryParse(userData['profilePic'] ??
                                                      '')
                                                  ?.host
                                                  .isEmpty ==
                                              true)
                                      ? Text(
                                          userData['name']
                                                  ?.substring(0, 1)
                                                  .toUpperCase() ??
                                              'U',
                                          style: const TextStyle(
                                              color: Colors.amber))
                                      : null,
                                ),
                                title: Text(userData['name'] ?? 'مستخدم',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                                subtitle: Text(
                                    'انضم في: ${memberData['joinedAt'] != null ? (memberData['joinedAt'] as Timestamp).toDate().toString().split(' ')[0] : ''}',
                                    style: const TextStyle(
                                        color: Colors.white38, fontSize: 10)),
                                trailing: const Icon(Icons.favorite,
                                    color: Colors.redAccent, size: 18),
                              );
                            });
                      },
                    );
                  }),
            ),
          ],
        ),
      ),
    );
  }

  void _showMusicPlayer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (c, setS) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 25,
            bottom: MediaQuery.of(c).padding.bottom + 15,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFF0F1B25),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            border: Border(top: BorderSide(color: Colors.amber, width: 0.5)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(2)),
                    margin: const EdgeInsets.only(bottom: 20)),
                const Text('مشغل الموسيقى الملكي 🎵',
                    style: TextStyle(
                        color: Colors.amber,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(_currentMusicName,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 30),
                if (_musicDuration <= 0 && !_isMusicPlaying)
                  Center(
                    child: GestureDetector(
                      onTap: () async {
                        await _pickAndPlayMusic();
                        if (mounted) setS(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.amber.withValues(alpha: 0.3))),
                        child: const Icon(Icons.library_music_rounded,
                            color: Colors.amber, size: 50),
                      ),
                    ),
                  )
                else ...[
                  Column(
                    children: [
                      Slider(
                        value: _parseDouble(_musicPosition).clamp(
                            0,
                            _parseDouble(_musicDuration) > 0
                                ? _parseDouble(_musicDuration)
                                : 1),
                        max: _parseDouble(_musicDuration) > 0
                            ? _parseDouble(_musicDuration)
                            : 1,
                        onChanged: (v) {
                          _agoraService.seekMusic(v.toInt());
                          if (mounted) setS(() => _musicPosition = v.toInt());
                        },
                        activeColor: Colors.amber,
                        inactiveColor: Colors.white10,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatDuration(_musicPosition),
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 10)),
                            Text(_formatDuration(_musicDuration),
                                style: const TextStyle(
                                    color: Colors.white38, fontSize: 10)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                          icon: const Icon(Icons.replay_10,
                              size: 30, color: Colors.white),
                          onPressed: () {
                            int newPos = _musicPosition - 10000;
                            if (newPos < 0) newPos = 0;
                            _agoraService.seekMusic(newPos);
                            if (mounted) setS(() => _musicPosition = newPos);
                          }),
                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: () {
                          _toggleMusic();
                          if (mounted) setS(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: const BoxDecoration(
                              color: Colors.amber, shape: BoxShape.circle),
                          child: Icon(
                              _isMusicPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 40,
                              color: Colors.black),
                        ),
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                          icon: const Icon(Icons.forward_10,
                              size: 30, color: Colors.white),
                          onPressed: () {
                            int newPos = _musicPosition + 10000;
                            if (newPos > _musicDuration) {
                              newPos = _musicDuration;
                            }
                            _agoraService.seekMusic(newPos);
                            if (mounted) setS(() => _musicPosition = newPos);
                          }),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      const Icon(Icons.volume_down,
                          color: Colors.white54, size: 18),
                      Expanded(
                        child: Slider(
                          value: _musicVolume,
                          max: 100,
                          onChanged: (v) {
                            if (mounted) setState(() => _musicVolume = v);
                            _agoraService.adjustMusicVolume(v.toInt());
                            if (mounted) setS(() {});
                          },
                          activeColor: Colors.cyanAccent,
                        ),
                      ),
                      const Icon(Icons.volume_up,
                          color: Colors.white54, size: 18),
                    ],
                  ),
                ],
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(
                        onPressed: () async {
                          await _pickAndPlayMusic();
                          if (mounted) setS(() {});
                        },
                        icon:
                            const Icon(Icons.folder_open, color: Colors.amber),
                        label: const Text("تغيير الملف",
                            style: TextStyle(color: Colors.white70))),
                    TextButton.icon(
                        onPressed: () {
                          _agoraService.stopMusic();
                          _stopMusicLocally();
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.stop_circle_outlined,
                            color: Colors.redAccent),
                        label: const Text("إيقاف نهائي",
                            style: TextStyle(color: Colors.redAccent))),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll('%', '')) ?? 0.0;
    }
    return 0.0;
  }

  Future<void> _joinFanClub() async {
    try {
      final roomDoc = await _db.collection('rooms').doc(widget.roomId).get();
      final roomData = roomDoc.data() ?? {};
      final int membershipFee = roomData['membershipFee'] ?? 0;

      if (membershipFee > 0) {
        if (!mounted) return;
        bool? confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFF1A242F),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.amber, width: 1)),
            title: const Text('الانضمام لنادي المعجبين 🏆',
                style:
                    TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.workspace_premium,
                    color: Colors.amber, size: 60),
                const SizedBox(height: 15),
                const Text('يتطلب الانضمام دفع رسوم عضوية لمرة واحدة.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center),
                const SizedBox(height: 10),
                const Text('تكلفة الانضمام:',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                Text('$membershipFee جوهرة 💎',
                    style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('إلغاء',
                      style: TextStyle(color: Colors.white54))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('دفع وانضمام',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );

        if (confirm != true) return;
      }

      final userRef = _db.collection('users').doc(_currentUserId);
      final roomRef = _db.collection('rooms').doc(widget.roomId);

      await _db.runTransaction((transaction) async {
        final userSnap = await transaction.get(userRef);
        final roomSnap = await transaction.get(roomRef);
        final int currentGems = userSnap.data()?['gems'] ?? 0;

        if (currentGems < membershipFee) {
          throw "عذراً، رصيدك من الجواهر غير كافٍ 💰";
        }

        transaction.update(userRef, {'gems': currentGems - membershipFee});

        if (membershipFee > 0) {
          transaction.update(roomRef,
              {'pendingEarnings': FieldValue.increment(membershipFee)});
        }

        transaction.set(roomRef.collection('fan_club').doc(_currentUserId), {
          'joinedAt': FieldValue.serverTimestamp(),
          'uid': _currentUserId,
        });

        transaction.set(roomRef.collection('members').doc(_currentUserId), {
          'joinedAt': FieldValue.serverTimestamp(),
          'lastVisited': FieldValue.serverTimestamp(),
          'uid': _currentUserId,
        });

        if (roomSnap.exists) {
          int currentExp = roomSnap.data()?['exp'] ?? 0;
          int currentLevel = roomSnap.data()?['level'] ?? 1;
          int pointsToAdd = 100; // زيادة الخبرة عند الانضمام
          int newExp = currentExp + pointsToAdd;
          int nextLevelThreshold = currentLevel * 10000;

          if (newExp >= nextLevelThreshold) {
            transaction.update(roomRef, {
              'exp': newExp - nextLevelThreshold,
              'level': currentLevel + 1,
            });
          } else {
            transaction.update(roomRef, {'exp': newExp});
          }
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('مبروك! انضممت لنادي المعجبين 🏆✨'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()), backgroundColor: Colors.redAccent));
      }
    }
  }

  Widget _buildMicSeat(int number, {Color? teamColor}) {
    var seatData = _micSeats[number];
    bool isOccupied = seatData != null;
    bool isMe = seatData != null && seatData['userId'] == _currentUserId;
    bool isLocked = _lockedSeats.contains(number);
    bool isMuted = seatData?['isMuted'] ?? false;
    String? micFrame = seatData?['micFrame'];

    return StreamBuilder<List<AudioVolumeInfo>>(
        stream: _agoraService.volumeStream,
        builder: (context, volSnap) {
          bool isSpeaking = false;
          if (isOccupied && volSnap.hasData) {
            for (var speaker in volSnap.data!) {
              if ((isMe && speaker.uid == 0) ||
                  (speaker.uid == seatData['agoraUid'])) {
                if (speaker.volume! > 20) {
                  isSpeaking = true;
                  break;
                }
              }
            }
          }

          return GestureDetector(
              onTap: () => _showMicMenu(number),
              child: SizedBox(
                  width: 65,
                  child: Column(children: [
                    Stack(alignment: Alignment.center, children: [
                      if (teamColor != null)
                        Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      teamColor.withValues(alpha: 0.8),
                                      teamColor.withValues(alpha: 0.2)
                                    ]),
                                border:
                                    Border.all(color: teamColor, width: 2))),
                      if (isSpeaking)
                        ScaleTransition(
                            scale: _speakingAnimController,
                            child: Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.greenAccent, width: 2)))),
                      Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isLocked
                                ? Colors.red.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                            border: isLocked
                                ? Border.all(
                                    color:
                                        Colors.redAccent.withValues(alpha: 0.5),
                                    width: 1)
                                : null,
                          ),
                          child: isLocked
                              ? const Icon(Icons.lock,
                                  color: Colors.amber, size: 18)
                              : (isOccupied
                                  ? CircleAvatar(
                                      backgroundColor: Colors.transparent,
                                      backgroundImage: (seatData['photoUrl'] != null &&
                                              seatData['photoUrl']
                                                  .toString()
                                                  .isNotEmpty &&
                                              Uri.tryParse(seatData['photoUrl'].toString())
                                                      ?.host
                                                      .isNotEmpty ==
                                                  true)
                                          ? CachedNetworkImageProvider(
                                              seatData['photoUrl'].toString())
                                          : null,
                                      child: (seatData['photoUrl'] == null ||
                                              seatData['photoUrl']
                                                  .toString()
                                                  .isEmpty ||
                                              Uri.tryParse(seatData['photoUrl']?.toString() ?? '')
                                                      ?.host
                                                      .isEmpty ==
                                                  true)
                                          ? const Icon(Icons.person,
                                              color: Colors.white)
                                          : null)
                                  : const Icon(Icons.mic,
                                      color: Colors.white54, size: 20))),
                      if (isOccupied &&
                          micFrame != null &&
                          micFrame.isNotEmpty &&
                          Uri.tryParse(micFrame)?.host.isNotEmpty == true)
                        Positioned.fill(
                            child: IgnorePointer(
                                child: CachedNetworkImage(
                          imageUrl: micFrame,
                          fit: BoxFit.contain,
                          errorWidget: (context, url, error) =>
                              const SizedBox.shrink(),
                        ))),
                      if (isOccupied && isMuted)
                        Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                                color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.mic_off,
                                color: Colors.redAccent, size: 24))
                    ]),
                    const SizedBox(height: 6),
                    Text(
                        isOccupied
                            ? (isMe ? 'أنا' : seatData['name'])
                            : (isLocked ? 'مغلق' : '$number'),
                        style: TextStyle(
                            color: isMe
                                ? Colors.greenAccent
                                : (isLocked ? Colors.amber : Colors.white),
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis)
                  ])));
        });
  }

  void _showMicMenu(int seatNumber) {
    var seatData = _micSeats[seatNumber];
    bool isOccupied = seatData != null;
    bool isMe = _mySeat == seatNumber;
    bool isLocked = _lockedSeats.contains(seatNumber);
    String? targetUserId = seatData?['userId'];
    showDialog(
      context: context,
      builder: (context) => Center(
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
              color: const Color(0xFF1A242F).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                  color: AppTheme.royalGold.withValues(alpha: 0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5), blurRadius: 20)
              ]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 50,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 15),
                  decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(10))),
              const Text("لوحة تحكم المايك 🎤",
                  style: TextStyle(
                      color: AppTheme.royalGold,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none)),
              const SizedBox(height: 25),
              if (isMe) ...[
                _buildModernMenuItem(
                    'اترك المايك', Icons.logout_rounded, Colors.redAccent, () {
                  Navigator.pop(context);
                  _leaveMic();
                }),
                _buildModernMenuItem(
                    _isMicMuted ? 'تفعيل المايك' : 'كتم المايك',
                    _isMicMuted ? Icons.mic_rounded : Icons.mic_off_rounded,
                    Colors.orangeAccent, () {
                  Navigator.pop(context);
                  _toggleMicMute();
                }),
                _buildModernMenuItem(
                    'ملفي الشخصي', Icons.person_pin_rounded, Colors.blueAccent,
                    () {
                  Navigator.pop(context);
                  _showUserCard(_currentUserId);
                }),
              ] else if (isOccupied) ...[
                _buildModernMenuItem('الملف الشخصي',
                    Icons.person_search_rounded, Colors.blueAccent, () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => UserProfilePage(
                          userId: targetUserId!, roomId: widget.roomId),
                    ),
                  );
                }),
                if (_hasPower) ...[
                  const Divider(color: Colors.white10, height: 20),
                  _buildModernMenuItem('إنزال العضو',
                      Icons.arrow_downward_rounded, Colors.orange, () {
                    Navigator.pop(context);
                    _adminKickFromMic(seatNumber);
                  }),
                  _buildModernMenuItem(
                      'طرد نهائي', Icons.gavel_rounded, Colors.red, () {
                    Navigator.pop(context);
                    _adminKickFromRoom(targetUserId!);
                  })
                ]
              ] else ...[
                if (!isLocked || _hasPower)
                  _buildModernMenuItem('الصعود للمايك',
                      Icons.mic_external_on_rounded, Colors.greenAccent, () {
                    Navigator.pop(context);
                    _takeMic(seatNumber);
                  }),
                if (_hasPower) ...[
                  _buildModernMenuItem(
                      isLocked ? 'فتح القفل' : 'قفل المايك',
                      isLocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                      AppTheme.royalGold, () {
                    Navigator.pop(context);
                    _toggleLockSeat(seatNumber);
                  }),
                  _buildModernMenuItem('دعوة صديق',
                      Icons.person_add_alt_1_rounded, Colors.cyanAccent, () {
                    Navigator.pop(context);
                    _showInviteList(seatNumber);
                  })
                ]
              ],
              const SizedBox(height: 10),
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إغلاق',
                      style: TextStyle(color: Colors.white38)))
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernMenuItem(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(15),
        child: ListTile(
          onTap: onTap,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 22),
          ),
          title: Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.arrow_forward_ios_rounded,
              color: Colors.white10, size: 14),
        ),
      ),
    );
  }

  void _showUserCard(String userId) async {
    final userSnap = await _db.collection('users').doc(userId).get();
    if (!userSnap.exists) return;
    final data = userSnap.data()!;
    final String? userFrame = data['currentFrame'];
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => Center(
        child: Container(
          width: 320,
          decoration: BoxDecoration(
              gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E)]),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 5)
              ]),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(alignment: Alignment.center, children: [
                Container(
                    height: 120,
                    decoration: const BoxDecoration(
                        color: Colors.amber,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(28)))),
                Positioned(
                    top: 20,
                    child: SizedBox(
                      width: 140,
                      height: 140,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                              radius: 45,
                              backgroundColor: Colors.white,
                              child: CircleAvatar(
                                  radius: 43,
                                  backgroundImage:
                                      (data['profilePic'] != null &&
                                              data['profilePic']
                                                  .toString()
                                                  .isNotEmpty &&
                                              Uri.tryParse(data['profilePic']
                                                          .toString())
                                                      ?.host
                                                      .isNotEmpty ==
                                                  true)
                                          ? CachedNetworkImageProvider(
                                              data['profilePic'].toString())
                                          : null)),
                          if (userFrame != null &&
                              userFrame.isNotEmpty &&
                              Uri.tryParse(userFrame)?.host.isNotEmpty == true)
                            Positioned.fill(
                                child: IgnorePointer(
                                    child: CachedNetworkImage(
                              imageUrl: userFrame,
                              fit: BoxFit.contain,
                              errorWidget: (context, url, error) =>
                                  const SizedBox.shrink(),
                            ))),
                        ],
                      ),
                    )),
              ]),
              const SizedBox(height: 50),
              Text(data['name'] ?? 'مستخدم ملكي',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.none)),
              Text("ID: ${data['royalId']}",
                  style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 14,
                      decoration: TextDecoration.none)),
              const Divider(
                  color: Colors.white10, indent: 30, endIndent: 30, height: 30),
              if (_hasPower && userId != _currentUserId)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      _cardActionBtn('طرد', Colors.red, () {
                        Navigator.pop(context);
                        _showModerationSheet("kick", userId, data['name']);
                      }),
                      _cardActionBtn('حظر', Colors.black, () {
                        Navigator.pop(context);
                        _showModerationSheet("ban", userId, data['name']);
                      }),
                      _cardActionBtn('إصمات', Colors.orange, () {
                        Navigator.pop(context);
                        _showModerationSheet("silence", userId, data['name']);
                      }),
                      _cardActionBtn('عقوبة', Colors.purple, () {
                        Navigator.pop(context);
                        _showModerationSheet("penalty", userId, data['name']);
                      }),
                      _cardActionBtn('كتم', Colors.blueGrey, () {
                        Navigator.pop(context);
                        _showModerationSheet("mute", userId, data['name']);
                      }),
                      _cardActionBtn('كتم', Colors.blueGrey, () {
                        Navigator.pop(context);
                        _showModerationSheet("mute", userId, data['name']);
                      }),
                      _cardActionBtn('ازالة', Colors.redAccent, () {
                        Navigator.pop(context);
                        _removeUserModeration(userId);
                      }),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardActionBtn(String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            textStyle:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        onPressed: onTap,
        child: Text(label));
  }

  void _showModerationSheet(String type, String userId, String name) {
    Widget sheet;
    switch (type) {
      case "silence":
        sheet = SilenceUserSheet(
            roomId: widget.roomId, userId: userId, userName: name);
        break;
      case "ban":
        sheet =
            BanUserSheet(roomId: widget.roomId, userId: userId, userName: name);
        break;
      case "kick":
        sheet = KickUserSheet(
            roomId: widget.roomId, userId: userId, userName: name);
        break;
      case "penalty":
        sheet = PenaltyUserSheet(
            roomId: widget.roomId, userId: userId, userName: name);
        break;
      case "mute":
        sheet = MuteUserSheet(
            roomId: widget.roomId, userId: userId, userName: name);
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

  Future<void> _removeUserModeration(String uid) async {
    await _db
        .collection('rooms')
        .doc(widget.roomId)
        .collection('silenced')
        .doc(uid)
        .delete();
    await _db
        .collection('rooms')
        .doc(widget.roomId)
        .collection('bans')
        .doc(uid)
        .delete();
    _micSeats.forEach((key, value) {
      if (value['userId'] == uid) {
        _db
            .collection('rooms')
            .doc(widget.roomId)
            .collection('mic_seats')
            .doc(key.toString())
            .delete();
      }
    });
  }

  Future<void> _adminKickFromMic(int seat) async {
    await _db
        .collection('rooms')
        .doc(widget.roomId)
        .collection('mic_seats')
        .doc(seat.toString())
        .delete();
  }

  Future<void> _adminKickFromRoom(String userId) async {
    await _db
        .collection('rooms')
        .doc(widget.roomId)
        .collection('online_users')
        .doc(userId)
        .delete();
  }

  Future<void> _toggleLockSeat(int seat) async {
    List<int> locked = List.from(_lockedSeats);
    if (locked.contains(seat)) {
      locked.remove(seat);
    } else {
      locked.add(seat);
    }
    await _db
        .collection('rooms')
        .doc(widget.roomId)
        .update({'lockedSeats': locked});
  }

  void _showBattleResult(int red, int blue) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            BattleResultDialog(redPoints: red, bluePoints: blue));
  }

  void _startBattleCountdown() {
    _battleTimer?.cancel();
    _battleTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_battleData == null || _battleData!['active'] == false) {
        timer.cancel();
        return;
      }
      final endDateTime = (_battleData!['endTime'] as Timestamp).toDate();
      if (DateTime.now().isAfter(endDateTime)) {
        timer.cancel();
        _endBattle();
      } else {
        if (mounted) setState(() {});
      }
    });
  }

  void _endBattle() async {
    if (_currentUserId == widget.ownerId) {
      await _db
          .collection('rooms')
          .doc(widget.roomId)
          .update({'battle.active': false});
    }
  }

  void _showLuckyBox() async {
    final userSnap = await _db.collection('users').doc(_currentUserId).get();
    final int gems = (userSnap.data()?['gems'] ?? 0).toInt();
    final int stars =
        (userSnap.data()?['stars'] ?? userSnap.data()?['coins'] ?? 0).toInt();
    if (!mounted) return;
    showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.8),
        builder: (context) => LuckyBoxDialog(
            roomId: widget.roomId,
            userGems: gems,
            userStars: stars,
            onPurchase: _openBox));
  }

  Future<void> _openBox(String type, String currency, int cost,
      Map<String, dynamic> wonGift) async {
    final userRef = _db.collection('users').doc(_currentUserId);
    final roomRef = _db.collection('rooms').doc(widget.roomId);
    try {
      await _db.runTransaction((transaction) async {
        final snap = await transaction.get(userRef);
        final roomSnap = await transaction.get(roomRef);

        if (currency == 'gems') {
          final currentGems = snap.data()?['gems'] ?? 0;
          if (currentGems < cost) throw 'عذراً، رصيدك غير كافٍ 💰';
          transaction.update(userRef, {'gems': currentGems - cost});
        } else {
          final currentStars =
              (snap.data()?['stars'] ?? snap.data()?['coins'] ?? 0).toInt();
          if (currentStars < cost) throw 'عذراً، رصيدك من النجوم غير كافٍ ⭐';
          transaction.update(userRef, {
            'stars': currentStars - cost,
            'coins': currentStars - cost,
          });
        }

        if (roomSnap.exists) {
          int currentExp = roomSnap.data()?['exp'] ?? 0;
          int currentLevel = roomSnap.data()?['level'] ?? 1;
          int pointsToAdd = 10;
          int newExp = currentExp + pointsToAdd;
          int nextLevelThreshold = currentLevel * 10000;

          if (newExp >= nextLevelThreshold) {
            transaction.update(roomRef, {
              'exp': newExp - nextLevelThreshold,
              'level': currentLevel + 1,
            });
          } else {
            transaction.update(roomRef, {'exp': newExp});
          }
        }

        final wonGiftImageUrl = (wonGift['imageUrl'] as String?) ?? '';
        final wonGiftVideoUrl = (wonGift['videoUrl'] as String?) ??
            (wonGift['giftVideoUrl'] as String?) ??
            '';
        final wonGiftType = (wonGift['giftType'] as String?) ??
            (wonGiftVideoUrl.isNotEmpty
                ? 'video'
                : (wonGiftImageUrl.toLowerCase().endsWith('.gif')
                    ? 'gif'
                    : 'image'));

        transaction.set(roomRef.collection('gift_events').doc(), {
          'giftName': 'جائزة صندوق الحظ: ${wonGift['name']}',
          'giftImageUrl': wonGiftImageUrl,
          'giftVideoUrl': wonGiftVideoUrl,
          'senderName': 'صندوق الحظ 🎁',
          'receiverName': _auth.currentUser?.displayName,
          'count': 1,
          'timestamp': FieldValue.serverTimestamp(),
          'giftType': wonGiftType,
          'soundUrl': wonGift['soundUrl']
        });
        transaction.set(_db.collection('global_announcements').doc(), {
          'senderName': _auth.currentUser?.displayName ?? 'لاعب محظوظ',
          'giftName': wonGift['name'],
          'roomName': widget.roomName,
          'roomId': widget.roomId,
          'receiverName': _auth.currentUser?.displayName ?? 'الجميع',
          'timestamp': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString()), backgroundColor: Colors.redAccent));
      }
    }
  }

  Widget _buildMarqueeBar() {
    return StreamBuilder<DocumentSnapshot>(
        stream: _db.collection('settings').doc('marquee').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const SizedBox(height: 5);
          }
          final data = snapshot.data!.data() as Map<String, dynamic>;
          final String text = data['text'] ?? 'أهلاً بكم في رويال دور 👑✨';
          final double velocity = _parseDouble(data['velocity'] ?? 40.0);
          if (text.isEmpty) return const SizedBox(height: 5);
          return Container(
              height: 32,
              margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
              decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.black.withValues(alpha: 0.3),
                  ]),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                      width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                      blurRadius: 8,
                      spreadRadius: 1,
                    )
                  ]),
              child: Row(children: [
                const SizedBox(width: 12),
                Expanded(
                    child: Marquee(
                        text: text,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                  color: Colors.black54,
                                  blurRadius: 2,
                                  offset: Offset(1, 1))
                            ]),
                        scrollAxis: Axis.horizontal,
                        blankSpace: 60.0,
                        velocity: velocity,
                        pauseAfterRound: const Duration(seconds: 2)))
              ]));
        });
  }

  Widget _buildGiftEventListener() {
    return StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('rooms')
            .doc(widget.roomId)
            .collection('gift_events')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            final doc = snapshot.data!.docs.first;
            final data = doc.data() as Map<String, dynamic>;
            if (!_initialGiftLoaded) {
              _lastGiftEventId = doc.id;
              _initialGiftLoaded = true;
              return const SizedBox.shrink();
            }
            if (_lastGiftEventId != doc.id) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() => _lastGiftEventId = doc.id);
                  if (data['isCombo'] == true) {
                    _comboAnimController.forward(from: 0);
                    Future.delayed(const Duration(seconds: 3),
                        () => _comboAnimController.reverse());
                  }
                  _triggerGlobalAnimation(data);
                }
              });
            }
          }
          return const SizedBox.shrink();
        });
  }

  void _triggerGlobalAnimation(Map<String, dynamic> data) {
    if (_dataSaverMode) return;

    _giftQueue.add(data);
    _playNextGift();
  }

  void _playNextGift() {
    if (_isGiftPlaying || _giftQueue.isEmpty) return;

    _isGiftPlaying = true;
    final data = _giftQueue.removeAt(0);

    showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.transparent,
        builder: (ctx) => RoyalGiftAnimation(
            giftName: data['giftName'] ?? '',
            giftImageUrl: data['giftImageUrl'] ?? '',
            giftVideoUrl: data['giftVideoUrl'],
            senderName: data['senderName'] ?? '',
            receiverName: data['receiverName'] ?? '',
            count: data['count'] ?? 1,
            giftType: data['giftType'],
            soundUrl: data['soundUrl'],
            onComplete: () {
              if (ctx.mounted) Navigator.pop(ctx);
              _isGiftPlaying = false;
              _triggerCapsule(data);
              _playNextGift();
            }));
  }

  Widget _buildBackground() {
    final bool hasValidBg = _dynamicBgImage != null &&
        _dynamicBgImage!.isNotEmpty &&
        Uri.tryParse(_dynamicBgImage!)?.host.isNotEmpty == true;
    return SizedBox.expand(
        child: hasValidBg
            ? Image.network(_dynamicBgImage!,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Image.asset(
                    'assets/images/room_global.jpg',
                    fit: BoxFit.cover))
            : Image.asset('assets/images/room_global.jpg', fit: BoxFit.cover));
  }

  Widget _buildRoomNotice() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
              color: Colors.black12, borderRadius: BorderRadius.circular(8)),
          child: Row(children: [
            const Icon(Icons.campaign, color: Colors.amber, size: 16),
            const SizedBox(width: 6),
            Expanded(
                child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Text(' $_roomNoticeText',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                        textAlign: TextAlign.right)))
          ])));
  void _showInviteList(int seatNumber) async {
    final usersSnap = await _db
        .collection('rooms')
        .doc(widget.roomId)
        .collection('online_users')
        .get();
    final List<Map<String, dynamic>> users = usersSnap.docs
        .map((doc) => doc.data())
        .where((user) =>
            user['uid'] != _currentUserId &&
            !_micSeats.values.any((seat) => seat['userId'] == user['uid']))
        .toList();
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F1B25),
      builder: (ctx) => Container(
        height: 400,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('دعوة مستخدم للمايك',
                style: TextStyle(
                    color: Colors.amber,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const Divider(color: Colors.white10),
            Expanded(
              child: users.isEmpty
                  ? const Center(
                      child: Text('لا يوجد مستخدمون متاحون',
                          style: TextStyle(color: Colors.white54)))
                  : ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (_, index) {
                        final user = users[index];
                        return ListTile(
                          leading: CircleAvatar(
                              backgroundImage: (user['profilePic'] != null &&
                                      user['profilePic']
                                          .toString()
                                          .isNotEmpty &&
                                      Uri.tryParse(user['profilePic'])
                                              ?.host
                                              .isNotEmpty ==
                                          true)
                                  ? NetworkImage(user['profilePic'])
                                  : null),
                          title: Text(user['name'] ?? 'مستخدم',
                              style: const TextStyle(color: Colors.white)),
                          trailing: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber),
                            child: const Text('دعوة',
                                style: TextStyle(color: Colors.black)),
                            onPressed: () async {
                              if (mounted) {
                                Navigator.pop(ctx);
                              }
                              await _db
                                  .collection('rooms')
                                  .doc(widget.roomId)
                                  .collection('mic_invites')
                                  .add({
                                'toUserId': user['uid'],
                                'seat': seatNumber,
                                'fromUserId': _currentUserId,
                                'timestamp': FieldValue.serverTimestamp(),
                              });
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'تم إرسال دعوة إلى ${user['name']}')));
                              }
                            },
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

  void _showExitOptions() {
    showDialog(
        context: context,
        barrierColor: Colors.black.withAlpha(204),
        builder: (context) => Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              GestureDetector(
                  onTap: () async {
                    if (Navigator.canPop(context)) Navigator.pop(context);
                    // عند الاحتفاظ، نضمن أن المستخدم مستمع فقط لتوفير التكلفة
                    if (_mySeat != null) {
                      _leaveMic();
                    } else {
                      await _agoraService.updateClientRole(false);
                    }
                    if (mounted) {
                      RoomPresenceService().minimizeRoom(
                          context,
                          widget.roomId,
                          widget.roomName,
                          _dynamicRoomImage ?? widget.roomImage);
                      if (Navigator.canPop(context)) Navigator.pop(context);
                    }
                  },
                  child: Column(children: [
                    Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(colors: [
                              Color(0xFF00BFA5),
                              Color(0xFF004D40)
                            ])),
                        child: const Icon(Icons.file_upload_outlined,
                            color: Colors.white, size: 40)),
                    const Text('احتفاظ',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none))
                  ])),
              const SizedBox(height: 60),
              GestureDetector(
                  onTap: () async {
                    final chatSnap = await _db
                        .collection('rooms')
                        .doc(widget.roomId)
                        .collection('chat')
                        .where('senderId', isEqualTo: _currentUserId)
                        .get();
                    final batch = _db.batch();
                    for (var doc in chatSnap.docs) {
                      batch.delete(doc.reference);
                    }
                    await batch.commit();
                    _leaveMic();
                    _updatePresence(false);
                    _agoraService.stopMusic();
                    _agoraService.leave();
                    RoomPresenceService().closeMinimized();
                    if (mounted) {
                      if (Navigator.canPop(context)) Navigator.pop(context);
                      if (Navigator.canPop(context)) Navigator.pop(context);
                    }
                  },
                  child: Column(children: [
                    Container(
                        width: 80,
                        height: 80,
                        decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                                colors: [Colors.redAccent, Colors.red])),
                        child: const Icon(Icons.power_settings_new,
                            color: Colors.white, size: 40)),
                    const Text('خروج نهائي',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none))
                  ])),
            ])));
  }
}

class _FloatingHeart extends StatefulWidget {
  final Offset position;
  final Color color;
  final Function(Key?) onComplete;
  const _FloatingHeart(
      {super.key,
      required this.position,
      required this.color,
      required this.onComplete});
  @override
  State<_FloatingHeart> createState() => _FloatingHeartState();
}

class _FloatingHeartState extends State<_FloatingHeart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _yAnim;
  late Animation<double> _opacityAnim;
  late double _randomX;
  @override
  void initState() {
    super.initState();
    _randomX = (math.Random().nextDouble() - 0.5) * 100;
    _controller = AnimationController(
        duration: const Duration(milliseconds: 1500), vsync: this);
    _yAnim = Tween<double>(
            begin: widget.position.dy, end: widget.position.dy - 300)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _opacityAnim = Tween<double>(begin: 1.0, end: 0.0).animate(
        CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0)));
    _controller.forward().then((_) => widget.onComplete(widget.key));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Positioned(
              left: widget.position.dx + (_randomX * _controller.value),
              top: _yAnim.value,
              child: Opacity(
                  opacity: _opacityAnim.value,
                  child: Icon(Icons.favorite, color: widget.color, size: 30)));
        });
  }
}
