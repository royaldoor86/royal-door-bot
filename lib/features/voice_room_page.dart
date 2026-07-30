import '../widgets/online_users_sheet.dart'; // تأكد من صحة المسار
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'profile/user_profile_page.dart';
import 'rooms/widgets/announced_room_info_sheet.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:marquee/marquee.dart';
import 'package:file_picker/file_picker.dart';
import '../services/agora_service.dart';
import '../services/room_presence_service.dart';
import '../services/custom_car_service.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'rooms/widgets/gift_shop_sheet.dart';
import 'rooms/widgets/room_info_sheet.dart';
import 'rooms/widgets/battle_result_dialog.dart';
import 'rooms/widgets/room_more_menu_sheet.dart';
import 'rooms/widgets/lucky_box_dialog.dart';
import 'rooms/widgets/leaderboard_sheet.dart';
import 'rooms/widgets/game_selector_sheet.dart';
import 'rooms/widgets/games/tic_tac_toe_game.dart';
import 'rooms/widgets/games/fruit_war_game.dart';
import 'rooms/widgets/games/voting_game.dart';
import 'rooms/widgets/games/lucky_draw_game.dart';
import 'rooms/widgets/games/bomb_game.dart';
import 'rooms/widgets/games/crocodile_game.dart';
import 'rooms/widgets/mic_queue_sheet.dart';

import 'rooms/widgets/moderation/silence_user_sheet.dart';
import 'rooms/widgets/moderation/ban_user_sheet.dart';
import 'rooms/widgets/moderation/kick_user_sheet.dart';
import 'rooms/widgets/moderation/penalty_user_sheet.dart';
import 'rooms/widgets/moderation/mute_user_sheet.dart';
import 'rooms/room_notification_preferences.dart';
import 'rooms/room_event_feedback.dart';

import 'dart:async';
import 'dart:math' as math;
import '../app_theme.dart';
import '../services/firestore_service.dart';
import 'voice_room_ui_widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lottie/lottie.dart';

// New imports for refactored modules
import 'voice_room_constants.dart';
import 'voice_room_mic_logic.dart';
import 'voice_room_battle_logic.dart';
import 'voice_room_gift_logic.dart';

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
    with TickerProviderStateMixin, WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late String _roomName;
  bool _showEntryBanner = false;
  bool _showRoomEntranceEffect = false;
  String _entryBannerText = '';
  Map<String, dynamic>? _activeVehicle;
  bool _showVehicleEntry = false;
  final TextEditingController _messageController = TextEditingController();
  final AgoraService _agoraService = AgoraService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AudioPlayer _eventAudioPlayer = AudioPlayer();

  bool _isMuted = false;
  bool _isMicMuted = false;
  bool _noiseReduction = false;
  bool _eyeComfort = false;
  bool _dataSaverMode = false;

  String _roomNoticeText = VoiceRoomConstants.defaultRoomNotice;
  String? _dynamicBgImage;
  String? _dynamicRoomImage;
  String _micMode = VoiceRoomConstants.defaultMicMode;
  int _maxSeats = VoiceRoomConstants.maxMicSeats;

  bool _muteChatGlobal = false;
  bool _mutePublic = false;
  bool _requireMicApproval = false;
  int _minLevelRequired = 1;
  Map<String, dynamic> _moderatorPermissions = {};
  bool _adminOnlyMic = false;
  bool _roomNoiseReductionEnabled = false;
  bool _roomEyeComfortEnabled = false;
  RoomNotificationPreferences _roomNotificationPrefs =
      const RoomNotificationPreferences(
    enabled: true,
    welcomeMessage: '',
    toggles: {
      'welcome': true,
      'battle': true,
      'gift': true,
    },
  );

  Map<int, Map<String, dynamic>> _micSeats = {};
  Set<int> _lockedSeats = {};
  List<String> _moderators = [];
  List<String> _admins = []; // إضافة قائمة المسؤولين
  int? _mySeat;

  Map<String, dynamic>? _battleData;
  Map<String, dynamic>? _activeGame;
  Timer? _battleTimer;
  bool _resultShown = false;

  String get _currentUserId => _auth.currentUser?.uid ?? '';

  late AnimationController _giftAnimController;
  late AnimationController _speakingAnimController;
  late AnimationController _boxAnimController;
  late AnimationController _comboAnimController;
  late AnimationController _entryAnimController;
  late AnimationController _eventPulseController;
  late AnimationController _roomEntranceController;

  StreamSubscription? _announcementSub;
  StreamSubscription? _micRequestSub;
  bool _showCapsule = false;
  Map<String, dynamic>? _capsuleData;
  Timer? _capsuleTimer;

  String? _lastGiftEventId;

  // Refactored logic instances
  late VoiceRoomMicLogic _micLogic;
  late VoiceRoomBattleLogic _battleLogic;
  late VoiceRoomGiftLogic _giftLogic;

  Widget _buildAutoScaleText(String text, TextStyle style,
      {double maxFontSize = 16, double minFontSize = 10}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            style: style.copyWith(fontSize: maxFontSize),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
    );
  }

  bool _initialGiftLoaded = false;
  String? _currentEntryEffect;
  String? _entryUserName;

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
  bool _audioBlockedByBrowser = false;
  StreamSubscription? _moderationSub;
  String _currentMusicName = 'لم يتم اختيار ملف';

  StreamSubscription? _volumeSub;
  StreamSubscription? _connectionSub;
  Timer? _inactivityMuteTimer;
  Timer? _inactivityKickTimer;
  Timer? _reconnectionTimer;
  int _reconnectionAttempts = 0;
  static const int _maxReconnectionAttempts = 3;

  @override
  bool get wantKeepAlive => true;

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
    _eventPulseController = AnimationController(
        duration: const Duration(milliseconds: 900), vsync: this)
      ..repeat(reverse: true);
    _roomEntranceController = AnimationController(
        duration: const Duration(milliseconds: 1500), vsync: this);

    // Initialize refactored logic instances
    _micLogic = VoiceRoomMicLogic(
      db: _db,
      auth: _auth,
      agoraService: _agoraService,
      roomId: widget.roomId,
      ownerId: widget.ownerId ?? '',
      admins: _admins,
      moderators: _moderators,
      moderatorPermissions: _moderatorPermissions,
      maxSeats: _maxSeats,
      adminOnlyMic: _adminOnlyMic,
      requireMicApproval: _requireMicApproval,
      lockedSeats: _lockedSeats.toList(),
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(error)));
        }
      },
      onSeatTaken: (seat) {
        setState(() => _mySeat = seat);
      },
      onSeatLeft: () {
        setState(() => _mySeat = null);
      },
      onRequestMic: () => _requestMic(),
    );

    _battleLogic = VoiceRoomBattleLogic(
      db: _db,
      roomId: widget.roomId,
      onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(error)));
        }
      },
      moderators: _moderators,
      ownerId: widget.ownerId ?? '',
      micSeats: _micSeats,
      onBattleEnded: (redScore, blueScore) {
        _showBattleResult(redScore, blueScore);
      },
      onBattleTick: () {
        if (mounted) setState(() {});
      },
    );

    _giftLogic = VoiceRoomGiftLogic(roomId: widget.roomId, context: context);

    // التحقق من المصادقة قبل تهيئة Agora
    _checkAuthenticationAndInit();
    _loadUserVoiceSettings(); // إضافة تحميل إعدادات المستخدم
    _loadActiveVehicle().then((_) async {
      await _updatePresence(true);
      if (mounted) {
        _listenToModerationStatus();
      }
    });
    _listenToRoomChanges();
    _listenToMicSeats();
    _checkMyVipStatus();
    _listenToMyMicRequest();
    _cleanupOldSeats();
    _listenToNewEntries();
    _listenToGlobalAnnouncements();
    _listenToMusicStream();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _showRoomEntranceEffect = true);
      _roomEntranceController.forward(from: 0).then((_) {
        if (mounted) {
          setState(() => _showRoomEntranceEffect = false);
        }
      });
    });
    _listenToVolumeIndication();
    _listenToConnectionState();
  }

  Future<void> _loadActiveVehicle() async {
    try {
      final userId = _currentUserId;
      final activeVehicle = await CustomCarService.getActiveCar(userId);
      if (mounted) {
        setState(() {
          _activeVehicle = activeVehicle;
        });
      }
    } catch (e) {
      debugPrint('Error loading active vehicle: $e');
    }
  }

  Widget _buildVehicleAnimation(String url, String type) {
    if (type == 'lottie' && url.startsWith('http')) {
      return Lottie.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.directions_car,
              color: AppTheme.royalGold, size: 80);
        },
      );
    } else if (type == 'gif' && url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.directions_car,
              color: AppTheme.royalGold, size: 80);
        },
      );
    } else if (url.startsWith('assets')) {
      return Image.asset(
        url,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.directions_car,
              color: AppTheme.royalGold, size: 80);
        },
      );
    }
    return const Icon(Icons.directions_car,
        color: AppTheme.royalGold, size: 80);
  }

  /// التحقق من المصادقة قبل تهيئة Agora
  Future<void> _checkAuthenticationAndInit() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      debugPrint('⚠️ User not authenticated, skipping Agora init');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('يجب تسجيل الدخول للدخول إلى الغرفة الصوتية'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    // Force token refresh to ensure fresh authentication
    try {
      await auth.currentUser!.getIdToken(true);
      debugPrint('✅ User authenticated successfully');
      _initAgora();

    if (kIsWeb) {
      _agoraService.audioBlockedStream.listen((blocked) {
        if (mounted) setState(() => _audioBlockedByBrowser = blocked);
      });
    }
    } catch (e) {
      debugPrint('❌ Authentication refresh failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل التحقق من المصادقة، يرجى تسجيل الدخول مرة أخرى'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// الاستماع إلى حالة الاتصال مع محاولة إعادة الاتصال التلقائية
  /// - لا يتم طرد المستخدم فوراً عند انقطاع الاتصال
  /// - يتم محاولة إعادة الاتصال 3 مرات قبل الطرد
  void _listenToConnectionState() {
    _connectionSub = _agoraService.connectionStream.listen((state) {
      if (state == ConnectionStateType.connectionStateDisconnected ||
          state == ConnectionStateType.connectionStateFailed) {
        if (mounted && _reconnectionAttempts < _maxReconnectionAttempts) {
          _attemptReconnection();
        } else if (mounted &&
            _reconnectionAttempts >= _maxReconnectionAttempts) {
          _performForcedExit(reason: 'فشل الاتصال بعد عدة محاولات 📡');
        }
      } else if (state == ConnectionStateType.connectionStateConnected) {
        // إعادة تعيين عدادات إعادة الاتصال عند نجاح الاتصال
        _reconnectionAttempts = 0;
        _reconnectionTimer?.cancel();
      }
    });
  }

  /// مراقبة حالة الإشراف (الحظر والطرد) بشكل فوري
  void _listenToModerationStatus() {
    if (_currentUserId.isEmpty) return;

    // 1. مراقبة الحظر من الغرفة
    _moderationSub = _db
        .collection('rooms')
        .doc(widget.roomId)
        .collection('bans')
        .doc(_currentUserId)
        .snapshots()
        .listen((snap) {
      if (snap.exists && mounted) {
        _performForcedExit(reason: 'عذراً، لقد تم حظرك من هذه الغرفة 🚫');
      }
    });

    // 2. مراقبة الطرد (عن طريق الحذف من online_users)
    _db
        .collection('rooms')
        .doc(widget.roomId)
        .collection('online_users')
        .doc(_currentUserId)
        .snapshots()
        .listen((snap) {
      if (!snap.exists && mounted) {
        // ننتظر ثانية للتأكد أن الحذف لم يكن بسبب انقطاع اتصال مؤقت
        Future.delayed(const Duration(seconds: 1), () async {
          if (!mounted) return;
          final currentSnap = await _db
              .collection('rooms')
              .doc(widget.roomId)
              .collection('online_users')
              .doc(_currentUserId)
              .get();
          if (!currentSnap.exists && mounted) {
            _performForcedExit(reason: 'لقد تم طردك من الغرفة من قبل الإدارة 🛡️');
          }
        });
      }
    });
  }

  /// محاولة إعادة الاتصال التلقائية
  /// - ينتظر 3 ثواني قبل المحاولة
  /// - يحدد عدد المحاولات بـ 3 فقط
  void _attemptReconnection() async {
    if (_reconnectionTimer != null) return;

    _reconnectionAttempts++;
    debugPrint(
        '🔄 محاولة إعادة الاتصال $_reconnectionAttempts/$_maxReconnectionAttempts');

    _reconnectionTimer = Timer(const Duration(seconds: 3), () async {
      try {
        await _agoraService.leave();
        await _agoraService.joinChannel(
          channelId: widget.roomId,
          asSpeaker: _mySeat != null, // الحفاظ على الدور الحالي
        );
        _reconnectionTimer = null;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إعادة الاتصال بنجاح ✅'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        debugPrint('❌ فشل إعادة الاتصال: $e');
        _reconnectionTimer = null;
        // إذا فشلت المحاولة، سيتم محاولة أخرى في الاستماع التالي للحالة
      }
    });
  }

  void _performForcedExit({String? reason}) async {
    if (!mounted) return;
    if (reason != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(reason)));
    }

    // تنظيف المايك والوجود قبل الخروج
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
  /// - Auto-Mute بعد 5 ثواني من الصمت (فقط للمتحدثين)
  /// - الخروج التلقائي بعد 30 دقيقة من الصمت (للمستمعين)
  void _startInactivityTimers() {
    // 1. مؤقت الكتم (10 ثواني) - فقط إذا كان على المايك وغير مكتوم
    // يتم إيقاف المؤقت إذا كانت الموسيقى تعمل لمنع التوقف المفاجئ
    if (_mySeat != null &&
        !_isMicMuted &&
        _inactivityMuteTimer == null &&
        !_isMusicPlaying) {
      _inactivityMuteTimer = Timer(const Duration(seconds: 10), () {
        if (mounted && _mySeat != null && !_isMicMuted && !_isMusicPlaying) {
          _toggleMicMute();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم كتم المايك تلقائياً بسبب عدم التحدث 🔇'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      });
    }

    // 2. مؤقت الخروج التلقائي (30 دقيقة صمت) - فقط للمستمعين
    // المتحدثون لا يتم طردهم تلقائياً
    if (_mySeat == null && _inactivityKickTimer == null) {
      _inactivityKickTimer = Timer(const Duration(minutes: 30), () {
        if (mounted && _mySeat == null) {
          _performForcedExit(
              reason: 'تم الخروج تلقائياً بسبب الصمت لمدة 30 دقيقة 💤');
        }
      });
    }
  }

  void _listenToMyMicRequest() {
    if (_currentUserId.isEmpty) return;
    _micRequestSub?.cancel();
    _micRequestSub = _db
        .collection('rooms')
        .doc(widget.roomId)
        .collection('mic_requests')
        .doc(_currentUserId)
        .snapshots()
        .listen((snap) {
      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>;
        if (data['status'] == 'rejected') {
          _showRejectionDialog();
          // حذف الطلب المرفوض حتى لا يتكرر التنبيه
          snap.reference.delete();
        }
      }
    });
  }

  void _showRejectionDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F1B25),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.redAccent, width: 1.5)),
        title: const Text('طلب المايك مرفوض 🚫',
            style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        content: const Text(
          'عذراً، لقد تم رفض طلبك للصعود على المايك من قبل الإدارة. هل تود البقاء كمستمع أم مغادرة الغرفة؟',
          style: TextStyle(color: Colors.white70, fontSize: 14),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performForcedExit();
            },
            child: const Text('مغادرة الغرفة', style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.royalGold,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('البقاء كمستمع', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _checkMyVipStatus() async {
    await _db.collection('users').doc(_currentUserId).get();
    // لا نحتاج setState لأن البيانات غير مستخدمة حالياً
  }

  void _listenToMusicStream() {
    _musicPositionSub = _agoraService.musicPositionStream.listen((pos) {
      if (mounted && _isMusicPlaying) {
        _musicPosition = pos;
      }
    });

    _agoraService.mixingStateStream.listen((state) {
      if (!mounted) return;
      if (state == AudioMixingStateType.audioMixingStateStopped ||
          state == AudioMixingStateType.audioMixingStateFailed) {
        _isMusicPlaying = false;
        _musicPosition = 0;
      } else if (state == AudioMixingStateType.audioMixingStatePlaying) {
        _isMusicPlaying = true;
        _resetInactivityTimers();
      }
    });
  }

  void _stopMusicLocally() {
    if (!mounted) return;
    _isMusicPlaying = false;
    _musicPosition = 0;
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

  void _toggleDataSaver(bool enabled) async {
    _dataSaverMode = enabled;
    if (enabled) {
      // 1. تقليل جودة الصوت لتوفير البيانات
      await _agoraService.engine?.setAudioProfile(
        profile: AudioProfileType.audioProfileSpeechStandard,
        scenario: AudioScenarioType.audioScenarioChatroom,
      );
      // 2. إيقاف التحميل المسبق للصور عالية الجودة إن وجد
    } else {
      // استعادة الجودة العالية
      await _agoraService.engine?.setAudioProfile(
        profile: AudioProfileType.audioProfileMusicStandard,
        scenario: AudioScenarioType.audioScenarioGameStreaming,
      );
    }
  }

  void _triggerCapsule(Map<String, dynamic> data) {
    if (!mounted || _dataSaverMode) {
      return; // عدم عرض الكبسولة في وضع توفير البيانات
    }
    _capsuleTimer?.cancel();
    _capsuleData = data;
    _showCapsule = true;
    _capsuleTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) _showCapsule = false;
    });
  }

  Future<void> _playRoomEventFeedback(String eventType) async {
    if (!mounted) return;
    HapticFeedback.heavyImpact();
    _eventPulseController.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) {
        HapticFeedback.mediumImpact();
      }
    });
    try {
      await _eventAudioPlayer
          .play(AssetSource(RoomEventFeedback.assetFor(eventType)));
    } catch (e) {
      debugPrint('Unable to play room event sound: $e');
    }
  }

  void _showRoomEventToast(String title, String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(message, style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
        if (uid == _currentUserId || _dataSaverMode) return;
        final userDoc = await _db.collection('users').doc(uid).get();
        final String? effect = userDoc.data()?['entryEffect'];
        if (effect != null && mounted) {
          _playRoomEventFeedback('welcome');
          _currentEntryEffect = effect;
          _entryUserName = userDoc.data()?['name'] ?? 'ملك رويال';
          _entryAnimController.forward(from: 0).then((_) {
            if (mounted) _currentEntryEffect = null;
          });
        }
      }
    });
  }

  Future<void> _updatePresence(bool isJoining) async {
    if (_currentUserId.isEmpty) return;
    final roomRef = _db.collection('rooms').doc(widget.roomId);
    if (isJoining) {
      // تنظيف أي مقعد قديم للمستخدم (حل مشكلة الصعود التلقائي للمايك عند الدخول)
      try {
        final oldSeats = await roomRef
            .collection('mic_seats')
            .where('userId', isEqualTo: _currentUserId)
            .get();
        for (var doc in oldSeats.docs) {
          await doc.reference.delete();
        }
      } catch (e) {
        debugPrint("Error cleaning old seats on join: $e");
      }

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
        final roomSnapshot = await roomRef.get();
        final roomData = roomSnapshot.data();
        _roomNotificationPrefs = RoomNotificationPreferences.fromMap(roomData);
        final welcomeMessage = _roomNotificationPrefs
            .resolvedWelcomeMessage('أهلاً بك $name في Royal Door 👑✨');

        // عرض المركبة إذا كانت مفعلة، وإلا عرض الترحيب العادي
        if (_activeVehicle != null && _activeVehicle!['enabled'] == true) {
          _showVehicleEntry = true;
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) _showVehicleEntry = false;
          });
        } else if (_roomNotificationPrefs.shouldShow('welcome')) {
          _entryBannerText = welcomeMessage;
          _showEntryBanner = true;
          Future.delayed(const Duration(seconds: 5), () {
            if (mounted) _showEntryBanner = false;
          });
        }
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

  Future<void> _loadUserVoiceSettings() async {
    try {
      final doc = await _db.collection('users').doc(_currentUserId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;

        // تطبيق الإعدادات المحفوظة
        final double micVol = (data['micVolume'] ?? 0.8).toDouble();
        final double speakerVol = (data['speakerVolume'] ?? 1.0).toDouble();
        final bool noiseCancel = data['noiseCancellation'] ?? true;
        final bool echoCancel = data['echoCancellation'] ?? true;
        final bool micAutoEnabled = data['micAutoEnabled'] ?? true;
        final bool speakerAutoEnabled = data['speakerAutoEnabled'] ?? true;

        _noiseReduction = noiseCancel;

        // تطبيق على Agora
        await _agoraService.engine
            ?.adjustRecordingSignalVolume((micVol * 100).toInt());
        await _agoraService.engine
            ?.adjustPlaybackSignalVolume((speakerVol * 100).toInt());

        if (noiseCancel) {
          await _agoraService.engine
              ?.setParameters('{"che.audio.opensles":true}');
          await _agoraService.engine?.setParameters('{"che.audio.agc":true}');
          await _agoraService.engine?.setParameters('{"che.audio.ans":true}');
        }

        if (echoCancel) {
          await _agoraService.engine?.setParameters('{"che.audio.aec":true}');
        }

        // تطبيق الإعدادات التلقائية
        if (micAutoEnabled && _mySeat == null) {
          // تفعيل المايك تلقائياً إذا كان الإعداد مفعل
          // يمكن إضافة منطق هنا لاتخاذ المايك تلقائياً
        }

        if (speakerAutoEnabled) {
          // Speakerphone auto-enable - method not available in AgoraService
          // Implement setSpeakerphone in AgoraService if needed
        }
      }
    } catch (e) {
      debugPrint('Error loading user voice settings: $e');
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
            _admins = List<String>.from(data['admins'] ?? []); // تحميل المسؤولين
            _micMode = data['micMode'] ?? 'normal';
            _muteChatGlobal = data['muteChat'] ?? false;
            _mutePublic = data['mutePublic'] ?? false;
            _requireMicApproval = data['requireMicApproval'] ?? false;
            _minLevelRequired = data['minLevelRequired'] ?? 1;
            _moderatorPermissions =
                data['moderatorPermissions'] as Map<String, dynamic>? ?? {};
            _adminOnlyMic = data['adminOnlyMic'] ?? false;
            _roomNoiseReductionEnabled = data['noiseReductionEnabled'] ?? false;
            _roomEyeComfortEnabled = data['eyeComfortEnabled'] ?? false;
            _roomNotificationPrefs = RoomNotificationPreferences.fromMap(data);
            _maxSeats = data['maxSeats'] ?? 8;

            // تحديث بيانات منطق المايك عند حدوث تغييرات في الغرفة
            _micLogic = VoiceRoomMicLogic(
              db: _db,
              auth: _auth,
              agoraService: _agoraService,
              roomId: widget.roomId,
              ownerId: widget.ownerId ?? '',
              admins: _admins, // تمرير المسؤولين
              moderators: _moderators,
              moderatorPermissions: _moderatorPermissions,
              maxSeats: _maxSeats,
              adminOnlyMic: _adminOnlyMic,
              requireMicApproval: _requireMicApproval,
              lockedSeats: _lockedSeats.toList(),
              onError: (error) {
                if (mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(error)));
                }
              },
              onSeatTaken: (seat) => _mySeat = seat,
              onSeatLeft: () => _mySeat = null,
              onRequestMic: () => _requestMic(),
            );

            var newBattleData = data['battle'];
            if (newBattleData != null && newBattleData['active'] == true) {
              final wasBattleActive =
                  _battleData != null && _battleData!['active'] == true;
              _battleData = newBattleData;
              _resultShown = false;
              if (!wasBattleActive &&
                  _roomNotificationPrefs.shouldShow('battle')) {
                _playRoomEventFeedback('battle');
                _showRoomEventToast(
                    'معركة جديدة', 'بدأت معركة داخل الغرفة 👑', Colors.orange);
              }
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
            _activeGame = data['activeGame'];
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
      Set<String> onlineUserIds = {};

      for (var doc in snap.docs) {
        int index = int.parse(doc.id);
        newSeats[index] = doc.data();
        final uid = doc.data()['userId'];
        onlineUserIds.add(uid);
        if (uid == _currentUserId) foundMySeat = index;
      }

      if (mounted) {
        final bool wasOnMic = _mySeat != null;
        final bool isNowOnMic = foundMySeat != null;

        _micSeats = newSeats;
        _mySeat = foundMySeat;

        // مزامنة حالة أكورا تلقائياً عند تغيير المقعد (يدوياً أو بواسطة مشرف)
        if (!wasOnMic && isNowOnMic) {
          debugPrint('🎙️ Auto-activating mic: User assigned to seat $foundMySeat');
          _agoraService.updateClientRole(true);
          _isMicMuted = false;
          _playRoomEventFeedback('mic');
        } else if (wasOnMic && !isNowOnMic) {
          debugPrint('🔇 Auto-deactivating mic: User left seat');
          _agoraService.updateClientRole(false);
        }

        // تحقق من خروج أحد المتسابقين إذا كانت المعركة نشطة
        if (_battleData != null && _battleData!['active'] == true) {
          final mode = _battleData!['mode'] ?? 'team';
          if (mode == 'individual') {
            final redId = _battleData!['redId'];
            final blueId = _battleData!['blueId'];

            // إذا خرج أي من الطرفين من المايك، تنتهي المعركة بسبب الهروب
            if (!onlineUserIds.contains(redId)) {
              _endBattle(reason: 'red_escaped');
            } else if (!onlineUserIds.contains(blueId)) {
              _endBattle(reason: 'blue_escaped');
            }
          }
        }
      }
    });
  }

  /// تهيئة Agora عند دخول الغرفة
  /// - تهيئة المحرك بجودة صوت منخفضة
  /// - الانضمام كمستمع (Audience) - لا تكلفة
  /// - تفعيل Listener Mode افتراضياً
  Future<void> _initAgora() async {
    await _agoraService.init();
    try {
      // الانضمام كمستخدم عادي (Audience) - لا تكلفة
      await _agoraService.joinChannel(
          channelId: widget.roomId, asSpeaker: false);
    } catch (e) {
      debugPrint("Agora error: $e");
    }
  }

  /// تنظيف الموارد عند الخروج من الصفحة
  /// - مهم جداً لمنع تسرب الذاكرة
  /// - مغادرة قناة Agora لتوفير التكلفة
  /// - إلغاء جميع الاشتراكات والمؤقتات
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // عند الاحتفاظ بالغرفة أو التبديل إلى تطبيق آخر
        unawaited(_agoraService.setBackgroundMode(true));
        break;
      case AppLifecycleState.resumed:
        // عند العودة إلى التطبيق
        unawaited(_agoraService.setBackgroundMode(false));
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // إذا كان الغرفة في وضع الاحتفاظ (مغلقة للشاشة فقط)، لا نغادر قناة أكورا
    bool isMinimized = RoomPresenceService().isMinimized;

    if (!isMinimized) {
      _updatePresence(false);
      _agoraService.stopMusic();
      // مغادرة قناة Agora فقط عند الخروج النهائي
      _agoraService.leave();
    } else {
      // إذا كان احتفاظ، نضمن استمرار الصوت في الخلفية
      unawaited(_agoraService.setBackgroundMode(true));
    }

    _micRequestSub?.cancel();
    _announcementSub?.cancel();
    _capsuleTimer?.cancel();
    _battleTimer?.cancel();
    _musicPositionSub?.cancel();
    _moderationSub?.cancel();
    _volumeSub?.cancel();
    _connectionSub?.cancel();
    _inactivityMuteTimer?.cancel();
    _inactivityKickTimer?.cancel();
    _reconnectionTimer?.cancel();

    _messageController.dispose();
    _eventAudioPlayer.dispose();
    _giftAnimController.dispose();
    _speakingAnimController.dispose();
    _boxAnimController.dispose();
    _comboAnimController.dispose();
    _entryAnimController.dispose();
    _eventPulseController.dispose();
    _roomEntranceController.dispose();
    super.dispose();
  }

  bool get _hasPower =>
      _currentUserId == widget.ownerId ||
      _admins.contains(_currentUserId) ||
      _moderators.contains(_currentUserId);

  bool _hasPermission(String key) {
    if (_currentUserId == widget.ownerId || _admins.contains(_currentUserId)) {
      return true;
    }
    if (!_moderators.contains(_currentUserId)) return false;
    return _moderatorPermissions[key] ?? false;
  }

  /// أخذ المايك مع التحقق من الشروط
  /// - التحقق من أن رقم المايك ضمن الحد المسموح (5 مايكات فقط)
  /// - التحقق من صلاحيات الإدارة
  /// - التحقق من أن المايك غير مغلق
  /// - تحويل المستخدم إلى متحدث (Broadcaster) - يبدأ احتساب التكلفة
  void _takeMic(int seatNumber) async {
    HapticFeedback.lightImpact(); // اهتزاز خفيف عند لمس المايك
    
    // المنطق الآن محمي بالكامل داخل _micLogic
    await _micLogic.takeMic(seatNumber, _mySeat);
    
    // تحديث الحالة المحلية إذا تم أخذ المايك (المشرفين فقط أو إذا كانت الموافقة معطلة)
    if (_mySeat == seatNumber) {
      setState(() {
        _isMicMuted = false;
      });
    }
  }

  /// مغادرة المايك والعودة للمستمع
  /// - حذف المستخدم من قائمة المايكات
  /// - تحويل الدور إلى مستمع (Audience) - يتوقف احتساب التكلفة
  /// - هذا مهم جداً لتوفير التكلفة عند عدم التحدث
  void _leaveMic() async {
    HapticFeedback.mediumImpact(); // اهتزاز عند النزول
    await _micLogic.leaveMic(_mySeat);
  }

  /// كتم/فتح المايك مع تغيير الدور تلقائياً
  /// - عند الكتم: يتحول إلى مستمع (Audience) - لا تكلفة
  /// - عند الفتح: يتحول إلى متحدث (Broadcaster) - يبدأ احتساب التكلفة
  /// - هذا يضمن أن فقط المتحدثين يدفعون
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
    // وعند تفعيل المايك يعود متحدثاً (Broadcaster)
    await _agoraService.toggleMute(newMute);

    HapticFeedback.selectionClick();
  }

  Widget _buildActiveGameOverlay() {
    if (_activeGame?['id'] == 'tic_tac_toe') {
      return TicTacToeGame(
        roomId: widget.roomId,
        gameData: _activeGame!,
        hasPower: _hasPower,
      );
    } else if (_activeGame?['id'] == 'fruit_war') {
      return FruitWarGame(
        roomId: widget.roomId,
        gameData: _activeGame!,
        hasPower: _hasPower,
      );
    } else if (_activeGame?['id'] == 'voting') {
      return VotingGame(
        roomId: widget.roomId,
        gameData: _activeGame!,
        hasPower: _hasPower,
      );
    } else if (_activeGame?['id'] == 'lucky_draw') {
      return LuckyDrawGame(
        roomId: widget.roomId,
        gameData: _activeGame!,
        hasPower: _hasPower,
      );
    } else if (_activeGame?['id'] == 'bomb') {
      return BombGame(
        roomId: widget.roomId,
        gameData: _activeGame!,
        hasPower: _hasPower,
      );
    } else if (_activeGame?['id'] == 'crocodile') {
      return CrocodileGame(
        roomId: widget.roomId,
        gameData: _activeGame!,
        hasPower: _hasPower,
      );
    }

    final gameName = _activeGame?['name'] ?? 'لعبة جارية';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.indigo.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.indigoAccent, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
          )
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.videogame_asset, color: Colors.white, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(gameName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const Text('انقر للمشاركة في اللعبة الملكية',
                    style: TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white54, size: 20),
            onPressed: () {
              if (_hasPower) {
                _db.collection('rooms').doc(widget.roomId).update({
                  'activeGame': FieldValue.delete(),
                });
              } else {
                _activeGame = null; // إخفاء محلي للمستخدم
              }
            },
          ),
        ],
      ),
    );
  }

  void _showGamesSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => GameSelectorSheet(
        roomId: widget.roomId,
        hasPower: _hasPower,
      ),
    );
  }

  void _showUserProfileBottomSheet(String userId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _UserProfileBottomSheet(
        userId: userId,
        roomId: widget.roomId,
        currentUserId: _auth.currentUser?.uid ?? '',
      ),
    );
  }

  Future<void> _requestMic() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userDoc = await _db.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      await _db
          .collection('rooms')
          .doc(widget.roomId)
          .collection('mic_requests')
          .doc(user.uid)
          .set({
        'userId': user.uid,
        'name': userData['name'] ?? user.displayName ?? 'مستخدم ملكي',
        'photoUrl': userData['profilePic'] ?? user.photoURL ?? '',
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'pending', // إضافة الحالة
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('تم إرسال طلب الصعود للمايك بنجاح ⏳'),
            backgroundColor: Colors.blueAccent));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل إرسال الطلب ❌'),
            backgroundColor: Colors.redAccent));
      }
    }
  }

  void _showMicQueue() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.7,
        child: MicQueueSheet(
          roomId: widget.roomId,
          hasPower: _hasPower,
          onApprove: (uid, name, photo) async {
            // الموافقة تعني إعطاءه أول مايك فارغ متاح
            int? freeSeat;
            for (int i = 1; i <= _maxSeats; i++) {
              if (!_micSeats.containsKey(i) && !_lockedSeats.contains(i)) {
                freeSeat = i;
                break;
              }
            }

            if (freeSeat != null) {
              await _db
                  .collection('rooms')
                  .doc(widget.roomId)
                  .collection('mic_seats')
                  .doc(freeSeat.toString())
                  .set({
                'userId': uid,
                'name': name,
                'photoUrl': photo,
                'joinedAt': FieldValue.serverTimestamp(),
                'isMuted': false,
                'agoraUid': 0, // سيتم تحديثه عند دخوله الفعلي
              });
              // إزالة من القائمة
              await _db
                  .collection('rooms')
                  .doc(widget.roomId)
                  .collection('mic_requests')
                  .doc(uid)
                  .delete();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('تم السماح لـ $name بالصعود للمايك 🎙️')));
              }
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('عذراً، لا توجد مايكات فارغة حالياً 🚫')));
              }
            }
          },
        ),
      ),
    );
  }

  void _onSendPressed({String? customText, bool isSystem = false}) async {
    HapticFeedback.lightImpact(); // اهتزاز عند الإرسال
    _resetInactivityTimers(); // تصفير عدادات الخمول عند إرسال رسالة
    final text = customText ?? _messageController.text.trim();
    if (text.isEmpty) return;

    if (!isSystem) {
      final userSnap = await _db.collection('users').doc(_currentUserId).get();
      final userData = userSnap.data() ?? {};
      final int userLevel = (userData['accountLevel'] ?? 1).toInt();
      final bool isOwnerOrModerator = _hasPower;

      // 1. التحقق من كتم الدردشة العام
      if (_muteChatGlobal && !isOwnerOrModerator) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('الدردشة مغلقة حالياً من قبل الإدارة 🔇')));
        }
        return;
      }

      // 2. التحقق من الحد الأدنى للمستوى
      if (userLevel < _minLevelRequired && !isOwnerOrModerator) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('يجب أن يكون مستواك $_minLevelRequired على الأقل للدردشة 🏆')));
        }
        return;
      }

      // 3. التحقق من كتم غير الأعضاء
      if (_mutePublic && !isOwnerOrModerator) {
        final memberSnap = await _db
            .collection('rooms')
            .doc(widget.roomId)
            .collection('members')
            .doc(_currentUserId)
            .get();
        if (!memberSnap.exists) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('يجب أن تكون عضواً في الغرفة للدردشة 👑')));
          }
          return;
        }
      }
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

    final blueColor = Color(_battleData!['blueColor'] ?? Colors.blue.value);
    final redColor = Color(_battleData!['redColor'] ?? Colors.red.value);

    _addFloatingHeart(position, isBlueTeam ? blueColor : redColor);
    final field = isBlueTeam ? 'battle.bluePoints' : 'battle.redPoints';
    await _db
        .collection('rooms')
        .doc(widget.roomId)
        .update({field: FieldValue.increment(1)});
  }

  void _addFloatingHeart(Offset pos, Color color) {
    _floatingHearts.add(_FloatingHeart(
        key: UniqueKey(),
        position: pos,
        color: color,
        onComplete: (key) {
          _floatingHearts.removeWhere((h) => h.key == key);
        }));
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
    if (mounted) _isMusicPlaying = !_isMusicPlaying;
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
        backgroundColor: Colors.black, // إضافة لون خلفية افتراضي
        body: Stack(
          children: [
            Positioned.fill(child: _buildBackground()),
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(),
                  _buildMarqueeBar(),
                  if (isBattleActive) _buildBattleNotificationOverlay(),
                  _buildGiftEventListener(),
                  Expanded(
                    child: Stack(
                      children: [
                        CustomScrollView(
                          physics: const BouncingScrollPhysics(),
                          slivers: [
                            if (isBattleActive)
                              SliverToBoxAdapter(child: _buildBattleBar()),
                            // 1. المايكات وتوزيعها الديناميكي حسب النمط
                            SliverPadding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 15),
                                sliver: _buildDynamicMicLayout(isBattleActive)),
                            SliverToBoxAdapter(
                                child: Column(children: [
                              const SizedBox(height: 10),
                              _buildRoomNotice()
                            ])),
                          ],
                        ),
                        if (_activeGame != null) 
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: _buildActiveGameOverlay(),
                          ),
                        if (isBattleActive)
                          Positioned.fill(
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTapDown: (d) =>
                                        _handleTap(true, d.globalPosition),
                                    behavior: HitTestBehavior.translucent,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                          colors: [
                                            Color(_battleData!['blueColor'] ??
                                                    Colors.blue.value)
                                                .withValues(alpha: 0.08),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTapDown: (d) =>
                                        _handleTap(false, d.globalPosition),
                                    behavior: HitTestBehavior.translucent,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.centerRight,
                                          end: Alignment.centerLeft,
                                          colors: [
                                            Color(_battleData!['redColor'] ??
                                                    Colors.red.value)
                                                .withValues(alpha: 0.08),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ...(_dataSaverMode ? [] : _floatingHearts),
                        if (_audioBlockedByBrowser)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black87,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.volume_off,
                                        size: 64, color: Colors.amber),
                                    const SizedBox(height: 16),
                                    const Text(
                                      "المتصفح يمنع تشغيل الصوت تلقائياً",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      "اضغط على الزر لتفعيل الصوت",
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 14),
                                    ),
                                    const SizedBox(height: 24),
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        await _agoraService.resumeAudio();
                                        if (mounted) {
                                          setState(() =>
                                              _audioBlockedByBrowser = false);
                                        }
                                      },
                                      icon: const Icon(Icons.volume_up),
                                      label: const Text("تفعيل الصوت"),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.amber,
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 32, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(25)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        if (_showVehicleEntry && _activeVehicle != null)
                          Positioned(
                              top: 20,
                              left: 0,
                              right: 0,
                              child: Center(
                                  child: Container(
                                      width: 300,
                                      height: 200,
                                      decoration: BoxDecoration(
                                          color: Colors.black
                                              .withValues(alpha: 0.8),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          boxShadow: const [
                                            BoxShadow(
                                                color: Colors.black26,
                                                blurRadius: 10,
                                                offset: Offset(0, 4))
                                          ]),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            '🚗 دخول ملكي',
                                            style: TextStyle(
                                                color: AppTheme.royalGold,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16),
                                          ),
                                          const SizedBox(height: 10),
                                          Expanded(
                                            child: _buildVehicleAnimation(
                                                _activeVehicle!['url'],
                                                _activeVehicle!['type']),
                                          ),
                                        ],
                                      )))),
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
                  _buildChatArea(),
                  _buildBottomBar(),
                ],
              ),
            ),
            if (_showRoomEntranceEffect) _buildRoomEntranceOverlay(),
            _buildComboOverlay(),
            _buildVipEntryOverlay(),
            if (_eyeComfort)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.orange.withValues(alpha: 0.15),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicMicLayout(bool isBattle) {
    // توزيع المايكات بناءً على النمط micMode
    if (_micMode == 'chat-5' || (_micMode == '4-4' && _maxSeats == 5)) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [1, 2, 3, 4, 5].map((n) => _buildMicSeat(n)).toList(),
          ),
        ),
      );
    } else if (_micMode == '4-4' || (_maxSeats == 8 && _micMode != 'broadcast-5')) {
      return SliverToBoxAdapter(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [1, 2, 3, 4].map((n) => _buildMicSeat(n)).toList(),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [5, 6, 7, 8].map((n) => _buildMicSeat(n)).toList(),
            ),
          ],
        ),
      );
    } else if (_micMode == 'normal' && _maxSeats == 10) {
      // نمط 10 مايكات (صفين من 5)
      return SliverToBoxAdapter(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [1, 2, 3, 4, 5].map((n) => _buildMicSeat(n)).toList(),
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [6, 7, 8, 9, 10].map((n) => _buildMicSeat(n)).toList(),
            ),
          ],
        ),
      );
    } else if (_micMode == 'broadcast-5') {
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
    } else if (_micMode == 'chat-15' || _maxSeats == 15) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
              mainAxisSpacing: 15,
              crossAxisSpacing: 5,
              childAspectRatio: 0.7),
          delegate: SliverChildBuilderDelegate((context, index) {
            int seatNumber = index + 1;
            if (seatNumber > 15) return null;
            return _buildMicSeat(seatNumber);
          }, childCount: 15),
        ),
      );
    } else {
      // النمط الشبكي الافتراضي للغرف الأخرى
      int crossCount = 4;
      return SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossCount,
            mainAxisSpacing: 20,
            crossAxisSpacing: 10,
            childAspectRatio: 0.75),
        delegate: SliverChildBuilderDelegate((context, index) {
          int seatNumber = index + 1;
          if (seatNumber > _maxSeats) return null;
          Color? team;
          if (isBattle) {
            team = (seatNumber % 2 == 0) ? Colors.blue : Colors.red;
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

    final blueColor = Color(_battleData!['blueColor'] ?? Colors.blue.value);
    final redColor = Color(_battleData!['redColor'] ?? Colors.red.value);

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
                Icon(Icons.shield, color: blueColor, size: 16),
                const SizedBox(width: 4),
                Text('$bluePoints',
                    style: TextStyle(
                        color: blueColor, fontWeight: FontWeight.bold))
              ]),
              const Text('GLOBAL BATTLE 🔥',
                  style: TextStyle(
                      color: Colors.amber,
                      fontSize: 10,
                      fontWeight: FontWeight.bold)),
              Row(children: [
                Text('$redPoints',
                    style: TextStyle(
                        color: redColor, fontWeight: FontWeight.bold)),
                const SizedBox(width: 4),
                Icon(Icons.shield, color: redColor, size: 16)
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
                          blueColor.withValues(alpha: 0.8),
                          blueColor
                        ]),
                      ),
                      child: const Center(
                          child: Text('TEAM 1',
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
                        gradient: LinearGradient(colors: [
                          redColor,
                          redColor.withValues(alpha: 0.8)
                        ]),
                      ),
                      child: const Center(
                          child: Text('TEAM 2',
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
        child: AnimatedBuilder(
            animation: _entryAnimController,
            builder: (context, child) {
              final progress = (_entryAnimController.value).clamp(0.0, 1.0);
              final opacity = (1.0 - progress).clamp(0.0, 1.0);
              return Transform.scale(
                scale: 0.9 + (progress * 0.25),
                child: Opacity(
                  opacity: opacity,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.85),
                            const Color(0xFF1A1228).withValues(alpha: 0.95),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color: AppTheme.royalGold.withValues(alpha: 0.9),
                            width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.royalGold.withValues(alpha: 0.35),
                            blurRadius: 24,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.auto_awesome,
                            color: AppTheme.royalGold, size: 64),
                        const SizedBox(height: 10),
                        const Text("👑 وصول فخم 👑",
                            style: TextStyle(
                                color: Colors.amber,
                                fontSize: 24,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(_entryUserName ?? '',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold))
                      ]),
                    ),
                  ),
                ),
              );
            }));
  }

  Widget _buildRoomEntranceOverlay() {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _roomEntranceController,
        builder: (context, child) {
          final progress =
              Curves.easeOutCubic.transform(_roomEntranceController.value);
          final opacity = (1.0 - progress).clamp(0.0, 1.0);
          return Opacity(
            opacity: opacity,
            child: Container(
              color: Colors.black.withValues(alpha: 0.35),
              child: Center(
                child: Transform.scale(
                  scale: 0.8 + (progress * 0.35),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF1A0F2B).withValues(alpha: 0.95),
                          const Color(0xFF26153C).withValues(alpha: 0.95),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                          color: AppTheme.royalGold.withValues(alpha: 0.9),
                          width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.royalGold.withValues(alpha: 0.35),
                          blurRadius: 30,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome,
                            color: AppTheme.royalGold, size: 56),
                        SizedBox(height: 10),
                        Text(
                          'Royal Door',
                          style: TextStyle(
                            color: AppTheme.royalGold,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'أهلاً بك في الغرفة الصوتية 👑',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
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
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                Colors.black.withValues(alpha: 0.8),
                                const Color(0xFF2A1450).withValues(alpha: 0.95),
                              ]),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(color: Colors.amber, width: 3),
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.amberAccent,
                                    blurRadius: 20,
                                    spreadRadius: 2)
                              ]),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          // القسم الأيسر: معلومات الغرفة (يأخذ المساحة المتبقية بالكامل)
          Expanded(
            child: Container(
              height: 38,
              padding: const EdgeInsets.only(left: 12, right: 2),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(77),
                borderRadius: BorderRadius.circular(20),
              ),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (context) => RoomInfoSheet(
                      roomId: widget.roomId,
                      roomName: _roomName,
                      ownerId: widget.ownerId,
                      onRoomNameChanged: (newName) {
                        _roomName = newName;
                      },
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
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
                    Flexible(
                      child: _buildAutoScaleText(
                        _roomName,
                        const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                        maxFontSize: 14,
                        minFontSize: 8,
                      ),
                    ),
                    const SizedBox(width: 5),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // القسم الأيمن: الأيقونات (تأخذ مساحتها الطبيعية دون ضغط)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_roomNoiseReductionEnabled || _roomEyeComfortEnabled)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors.teal.withValues(alpha: 0.25),
                      Colors.purple.withValues(alpha: 0.2),
                    ]),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                      if (_roomNoiseReductionEnabled)
                        const Icon(Icons.graphic_eq,
                            color: Colors.white, size: 12),
                      if (_roomNoiseReductionEnabled && _roomEyeComfortEnabled)
                        const SizedBox(width: 4),
                      if (_roomEyeComfortEnabled)
                        const Icon(Icons.nightlight_round,
                            color: Colors.white, size: 12),
                    ],
                  ),
                ),
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
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.25),
                            Colors.white.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.group,
                              color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '$count',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _showMoreMenu(context),
                child:
                    const Icon(Icons.more_horiz, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 8),
              IconButton(
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.power_settings_new,
                    color: Colors.white, size: 24),
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

  Widget _buildMicRequestButton() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _db
          .collection('rooms')
          .doc(widget.roomId)
          .collection('mic_requests')
          .doc(_currentUserId)
          .snapshots(),
      builder: (context, snap) {
        bool alreadyRequested = snap.hasData && snap.data!.exists;
        return IconButton(
          icon: Icon(alreadyRequested ? Icons.hourglass_top : Icons.mic_none,
              color: alreadyRequested ? Colors.amber : Colors.white,
              size: 26),
          onPressed: alreadyRequested
              ? () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('طلبك قيد الانتظار حالياً ⏳')));
                }
              : _requestMic,
        );
      },
    );
  }

  Widget _buildAdminQueueButton() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('rooms')
          .doc(widget.roomId)
          .collection('mic_requests')
          .snapshots(),
      builder: (context, snap) {
        final count = snap.hasData ? snap.data!.docs.length : 0;
        if (count == 0) {
          return IconButton(
              icon: const Icon(Icons.mic_external_on, color: Colors.white70, size: 26),
              onPressed: _showMicQueue);
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            // هالة نبض للفت الانتباه
            ScaleTransition(
              scale: _eventPulseController,
              child: Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amber.withValues(alpha: 0.2),
                ),
              ),
            ),
            IconButton(
                icon: const Icon(Icons.mic_external_on, color: Colors.amber, size: 26),
                onPressed: _showMicQueue),
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1)),
                child: Text(
                  '$count',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
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
          if (_mySeat != null)
            IconButton(
                icon: Icon(_isMicMuted ? Icons.mic_off : Icons.mic,
                    color: _isMicMuted ? Colors.redAccent : Colors.greenAccent,
                    size: 26),
                onPressed: _toggleMicMute)
          else if (_requireMicApproval)
            _buildMicRequestButton(),
          if (_hasPower) _buildAdminQueueButton(),
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
              onPressed: () async {
                _isMuted = !_isMuted;
                await _agoraService.toggleMuteFromChat(_isMuted);
              }),
        ],
      ),
    );
  }

  Future<void> _updateNoiseReduction(bool enabled) async {
    if (_agoraService.engine == null) return;
    try {
      if (enabled) {
        await _agoraService.engine
            ?.setParameters('{"che.audio.opensles":true}');
        await _agoraService.engine?.setParameters('{"che.audio.agc":true}');
        await _agoraService.engine?.setParameters('{"che.audio.ans":true}');
      } else {
        await _agoraService.engine?.setParameters('{"che.audio.ans":false}');
      }
    } catch (e) {
      debugPrint('Error updating noise reduction: $e');
    }
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
              ownerId: widget.ownerId,
              hasPower: _hasPower,
              moderatorPermissions: _moderatorPermissions,
              isBattleActive:
                  _battleData != null && _battleData!['active'] == true,
              micMode: _micMode,
              noiseReduction: _noiseReduction,
              eyeComfort: _eyeComfort,
              onNoiseReductionChanged: (v) {
                _noiseReduction = v;
                _updateNoiseReduction(v);
              },
              onEyeComfortChanged: (v) => setState(() => _eyeComfort = v),
              onEndBattle: _endBattle,
              onShowGames: _showGamesSelector,
              onFixAudio: () async {
                // إعادة تهيئة الصوت لحل المشكلات
                await _agoraService.leave();
                await Future.delayed(const Duration(milliseconds: 500));
                await _agoraService.joinChannel(
                  channelId: widget.roomId,
                  asSpeaker: _mySeat != null,
                );
              },
              onShowLeaderboard: _showLeaderboard,
              extraWidgets: [
                if (_hasPower)
                  Material(
                    color: Colors.transparent,
                    child: ListTile(
                        leading:
                            const Icon(Icons.music_note, color: Colors.amber),
                        title: const Text('مشغل MP3',
                            style: TextStyle(color: Colors.white)),
                        onTap: () {
                          Navigator.pop(context);
                          _showMusicPlayer();
                        }),
                  ),
                Material(
                  color: Colors.transparent,
                  child: ListTile(
                      leading:
                          const Icon(Icons.group_add, color: Colors.cyanAccent),
                      title: const Text('نادي المعجبين',
                          style: TextStyle(color: Colors.white)),
                      subtitle: const Text('كن جزءاً من عائلة الغرفة',
                          style:
                              TextStyle(color: Colors.white38, fontSize: 10)),
                      onTap: () {
                        Navigator.pop(context);
                        _showFanClubList();
                      }),
                ),
                SwitchListTile(
                    title: const Text('توفير البيانات',
                        style: TextStyle(color: Colors.white)),
                    subtitle: const Text(
                        'تقليل جودة الصوت وإيقاف التأثيرات لتوفير الإنترنت',
                        style: TextStyle(color: Colors.white38, fontSize: 10)),
                    value: _dataSaverMode,
                    activeThumbColor: Colors.greenAccent,
                    onChanged: (v) {
                      Navigator.pop(context);
                      _toggleDataSaver(v);
                    }),
              ],
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

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Material(
                                  color: Colors.white.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(12),
                                  clipBehavior: Clip.antiAlias,
                                  child: ListTile(
                                    onTap: () {
                                      Navigator.pop(context);
                                      _showUserCard(memberUid);
                                    },
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          Colors.amber.withValues(alpha: 0.1),
                                      backgroundImage: (userData[
                                                      'profilePic'] !=
                                                  null &&
                                              userData['profilePic'] != '' &&
                                              Uri.tryParse(userData[
                                                          'profilePic'])
                                                      ?.host
                                                      .isNotEmpty ==
                                                  true)
                                          ? NetworkImage(userData['profilePic'])
                                          : null,
                                      child: (userData['profilePic'] == null ||
                                              userData['profilePic'] == '' ||
                                              Uri.tryParse(userData[
                                                              'profilePic'] ??
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
                                    title: _buildAutoScaleText(
                                        userData['name'] ?? 'مستخدم',
                                        const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold),
                                        maxFontSize: 16,
                                        minFontSize: 10),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                            'ID: ${userData['shortId'] ?? userData['royalId'] ?? (memberUid.length > 8 ? memberUid.substring(0, 8) : memberUid)}',
                                            style: const TextStyle(
                                                color: Colors.amber,
                                                fontSize: 11)),
                                        Text(
                                            'انضم في: ${memberData['joinedAt'] != null ? (memberData['joinedAt'] as Timestamp).toDate().toString().split(' ')[0] : ''}',
                                            style: const TextStyle(
                                                color: Colors.white38,
                                                fontSize: 10)),
                                      ],
                                    ),
                                    trailing: const Icon(Icons.favorite,
                                        color: Colors.redAccent, size: 18),
                                  ),
                                ),
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
      builder: (ctx) => RoyalMusicPlayerSheet(
        roomId: widget.roomId,
        agoraService: _agoraService,
        currentMusicName: _currentMusicName,
        isMusicPlaying: _isMusicPlaying,
        musicDuration: _musicDuration,
        musicPosition: _musicPosition,
        musicVolume: _musicVolume,
        onMusicUpdate: (name, playing, duration, pos) {
          setState(() {
            _currentMusicName = name;
            _isMusicPlaying = playing;
            _musicDuration = duration;
            _musicPosition = pos;
          });
        },
        onVolumeChanged: (v) => setState(() => _musicVolume = v),
        onPickMusic: _pickAndPlayMusic,
        onToggleMusic: _toggleMusic,
      ),
    );
  }

  Widget _buildPickerBtn(Function setS) {
    return Center(
      child: GestureDetector(
        onTap: () async {
          await _pickAndPlayMusic();
          if (mounted) setS(() {});
        },
        child: Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
              color: AppTheme.royalGold.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(
                  color: AppTheme.royalGold.withValues(alpha: 0.2), width: 2)),
          child: const Column(
            children: [
              Icon(Icons.library_music_rounded,
                  color: AppTheme.royalGold, size: 60),
              SizedBox(height: 10),
              Text('اختر ملف MP3',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
            ],
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
        final dynamic gemsValue = userSnap.data()?['gems'] ?? 0;
        final int currentGems = gemsValue is int ? gemsValue : gemsValue.toInt();

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
          final dynamic expValue = roomSnap.data()?['exp'] ?? 0;
          final int currentExp = expValue is int ? expValue : expValue.toInt();
          final dynamic levelValue = roomSnap.data()?['level'] ?? 1;
          final int currentLevel = levelValue is int ? levelValue : levelValue.toInt();
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

    // لون المايك الافتراضي (ذهبي ملكي) أو لون الفريق
    Color seatThemeColor = teamColor ?? AppTheme.royalGold;

    return StreamBuilder<List<AudioVolumeInfo>>(
        stream: _agoraService.volumeStream,
        builder: (context, volSnap) {
          bool isSpeaking = false;
          if (isOccupied && !isMuted && volSnap.hasData) {
            for (var speaker in volSnap.data!) {
              if ((isMe && speaker.uid == 0) ||
                  (!isMe &&
                      speaker.uid != 0 &&
                      speaker.uid == seatData['agoraUid'])) {
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
                  width: 75,
                  child: Column(children: [
                    SizedBox(
                      height: 80,
                      child: Stack(alignment: Alignment.center, children: [
                        // 1. هالة خارجية "نيون" تجعل المايك بارزاً جداً ضد أي خلفية
                        Container(
                          width: 66,
                          height: 66,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: seatThemeColor.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: seatThemeColor.withValues(alpha: 0.2),
                                blurRadius: 12,
                                spreadRadius: 2,
                              )
                            ],
                          ),
                        ),

                        // 2. هالة التحدث (تظهر فقط عند الكلام)
                        if (isSpeaking) _MicSpeakingGlow(color: seatThemeColor),

                        // 3. جسم المايك الرئيسي
                        Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: isLocked
                                  ? Colors.red.withValues(alpha: 0.2)
                                  : (isOccupied
                                      ? Colors.black.withValues(alpha: 0.4)
                                      : Colors.white.withValues(alpha: 0.08)),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isLocked
                                    ? Colors.redAccent.withValues(alpha: 0.5)
                                    : seatThemeColor.withValues(alpha: 0.3),
                                width: 1.5,
                              ),
                            ),
                            child: isLocked
                                ? const Icon(Icons.lock,
                                    color: Colors.amber, size: 22)
                                : (isOccupied
                                    ? CircleAvatar(
                                        radius: 29,
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
                                                Uri.tryParse(seatData['photoUrl']?.toString() ?? '')?.host.isEmpty ==
                                                    true)
                                            ? const Icon(Icons.person,
                                                color: Colors.white, size: 30)
                                            : null)
                                    : Icon(Icons.mic,
                                        color: seatThemeColor.withValues(alpha: 0.6),
                                        size: 24))),

                        // 4. إطار المايك (إذا وجد)
                        if (isOccupied &&
                            micFrame != null &&
                            micFrame.isNotEmpty &&
                            Uri.tryParse(micFrame)?.host.isNotEmpty == true)
                          SizedBox(
                            width: 82,
                            height: 82,
                            child: IgnorePointer(
                              child: CachedNetworkImage(
                                imageUrl: micFrame,
                                fit: BoxFit.contain,
                                errorWidget: (context, url, error) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                          ),

                        // 5. علامة الكتم
                        if (isOccupied && isMuted)
                          Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.6),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.mic_off,
                                  color: Colors.redAccent, size: 26))
                      ]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                        isOccupied
                            ? (isMe ? 'أنا' : seatData['name'])
                            : (isLocked ? 'مغلق' : '$number'),
                        style: TextStyle(
                            color: isMe
                                ? Colors.greenAccent
                                : (isLocked ? Colors.redAccent : Colors.white),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            shadows: const [
                              Shadow(color: Colors.black, blurRadius: 4)
                            ]),
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
          width: 300,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1B25),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
                color: AppTheme.royalGold.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isOccupied) ...[
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 95,
                      height: 95,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.royalGold, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.royalGold.withValues(alpha: 0.2),
                            blurRadius: 15,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                    ),
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: Colors.black12,
                      backgroundImage: (seatData['photoUrl'] != null &&
                              seatData['photoUrl'].toString().isNotEmpty)
                          ? CachedNetworkImageProvider(seatData['photoUrl'])
                          : null,
                      child: (seatData['photoUrl'] == null ||
                              seatData['photoUrl'].toString().isEmpty)
                          ? const Icon(Icons.person,
                              size: 45, color: Colors.white24)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  seatData['name'] ?? 'مستخدم رويال',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    decoration: TextDecoration.none,
                    fontFamily: 'Tajawal', // Assuming professional font
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 30),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.royalGold.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic_none_rounded,
                      color: AppTheme.royalGold, size: 40),
                ),
                const SizedBox(height: 12),
                const Text(
                  "تحكم المايك 🎤",
                  style: TextStyle(
                    color: AppTheme.royalGold,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none,
                    fontFamily: 'Tajawal',
                  ),
                ),
                const SizedBox(height: 30),
              ],
              if (isMe) ...[
                _buildModernMenuItem(
                  'اترك المايك',
                  Icons.logout_rounded,
                  Colors.redAccent,
                  () {
                    Navigator.pop(context);
                    _leaveMic();
                  },
                ),
                _buildModernMenuItem(
                  _isMicMuted ? 'تفعيل المايك' : 'كتم المايك',
                  _isMicMuted ? Icons.mic_rounded : Icons.mic_off_rounded,
                  Colors.orangeAccent,
                  () {
                    Navigator.pop(context);
                    _toggleMicMute();
                  },
                ),
                _buildModernMenuItem(
                  'الملف الشخصي',
                  Icons.person_pin_rounded,
                  Colors.blueAccent,
                  () {
                    Navigator.pop(context);
                    _showUserCard(_currentUserId);
                  },
                ),
              ] else if (isOccupied) ...[
                _buildModernMenuItem(
                  'الملف الشخصي',
                  Icons.person_search_rounded,
                  Colors.blueAccent,
                  () {
                    Navigator.pop(context);
                    _showUserProfileBottomSheet(targetUserId!);
                  },
                ),
                if (_hasPermission('canManageMic')) ...[
                  _buildModernMenuItem(
                    'إنزال من المايك',
                    Icons.arrow_downward_rounded,
                    Colors.orange,
                    () {
                      Navigator.pop(context);
                      _adminKickFromMic(seatNumber);
                    },
                  ),
                ],
              ] else ...[
                if (!isLocked || _hasPower)
                  _buildModernMenuItem(
                    (_requireMicApproval && !_hasPower) ? 'طلب صعود للمايك' : 'الصعود للمايك',
                    (_requireMicApproval && !_hasPower) ? Icons.hourglass_top : Icons.mic_external_on_rounded,
                    (_requireMicApproval && !_hasPower) ? Colors.amberAccent : Colors.greenAccent,
                    () {
                      Navigator.pop(context);
                      if (_requireMicApproval && !_hasPower) {
                        _requestMic();
                      } else {
                        _takeMic(seatNumber);
                      }
                    },
                  ),
                if (_hasPermission('canManageMic')) ...[
                  _buildModernMenuItem(
                    isLocked ? 'فتح المايك' : 'قفل المايك',
                    isLocked ? Icons.lock_open_rounded : Icons.lock_rounded,
                    AppTheme.royalGold,
                    () {
                      Navigator.pop(context);
                      _toggleLockSeat(seatNumber);
                    },
                  ),
                  _buildModernMenuItem(
                    'دعوة صديق',
                    Icons.person_add_alt_1_rounded,
                    Colors.cyanAccent,
                    () {
                      Navigator.pop(context);
                      _showInviteList(seatNumber);
                    },
                  ),
                ]
              ],
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white38,
                  textStyle: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
                child: const Text('إغلاق'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernMenuItem(
      String title, IconData icon, Color color, VoidCallback onTap) {
    return VoiceRoomUIWidgets.buildModernMenuItem(title, icon, color, onTap);
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
        sheet = BanUserSheet(
            roomId: widget.roomId,
            userId: userId,
            userName: name,
            hasPower: _hasPower);
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
    final redColor = Color(_battleData?['redColor'] ?? Colors.red.value);
    final blueColor = Color(_battleData?['blueColor'] ?? Colors.blue.value);
    final redName = _battleData?['redName'] ?? 'الفريق الأول';
    final blueName = _battleData?['blueName'] ?? 'الفريق الثاني';

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => BattleResultDialog(
              redPoints: red,
              bluePoints: blue,
              redColor: redColor,
              blueColor: blueColor,
              redName: redName,
              blueName: blueName,
            ));
  }

  void _startBattleCountdown() {
    _battleLogic.setBattleData(_battleData);
  }

  void _endBattle({String? reason}) async {
    // توزيع المكافآت قبل إغلاق المعركة رسمياً
    if (_battleData != null && _battleData!['active'] == true) {
      final redPoints = _battleData!['redPoints'] ?? 0;
      final bluePoints = _battleData!['bluePoints'] ?? 0;
      final mode = _battleData!['mode'] ?? 'team';

      if (reason == 'red_escaped') {
        _onSendPressed(
            customText: '🚩 انتهت المعركة بانسحاب الطرف الأول!', isSystem: true);
        if (mode == 'individual') {
          FirestoreService.earnBattleWinXP(widget.roomId); // الفائز هو الأزرق
        }
      } else if (reason == 'blue_escaped') {
        _onSendPressed(
            customText: '🚩 انتهت المعركة بانسحاب الطرف الثاني!', isSystem: true);
        if (mode == 'individual') {
          FirestoreService.earnBattleWinXP(widget.roomId); // الفائز هو الأحمر
        }
      } else {
        // فوز طبيعي بالنقاط
        if (redPoints > bluePoints) {
          _onSendPressed(
              customText: '🏆 مبروك للفريق الأحمر الفوز بالمعركة!',
              isSystem: true);
          if (mode == 'individual') {
            final redId = _battleData!['redId'];
            if (redId == _currentUserId) {
              FirestoreService.earnBattleWinXP(widget.roomId);
            }
          }
        } else if (bluePoints > redPoints) {
          _onSendPressed(
              customText: '🏆 مبروك للفريق الأزرق الفوز بالمعركة!',
              isSystem: true);
          if (mode == 'individual') {
            final blueId = _battleData!['blueId'];
            if (blueId == _currentUserId) {
              FirestoreService.earnBattleWinXP(widget.roomId);
            }
          }
        } else {
          _onSendPressed(
              customText: '🤝 انتهت المعركة بالتعادل!', isSystem: true);
        }
      }
    }

    await _battleLogic.endBattle(reason: reason);

    // حذف رسائل المعركة وإشعار الفوز بعد فترة قصيرة بناءً على الطلب رقم 2
    Future.delayed(const Duration(seconds: 7), () async {
      try {
        final chatSnap = await _db
            .collection('rooms')
            .doc(widget.roomId)
            .collection('chat')
            .get();
        final batch = _db.batch();
        for (var doc in chatSnap.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      } catch (e) {
        debugPrint("Error clearing chat after battle: $e");
      }
    });
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
    // تأخير بسيط لضمان انغلاق أي نوافذ منبثقة (مثل متجر الهدايا)
    // ولتجنب تداخل الحركات
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        if (_roomNotificationPrefs.shouldShow('gift')) {
          _playRoomEventFeedback('gift');
          final receiverName =
              (data['receiverName'] as String?)?.trim().isNotEmpty == true
                  ? data['receiverName']
                  : 'الجميع';
          _showRoomEventToast(
            'هدية جديدة',
            '${data['senderName'] ?? 'مستخدم'} أرسل ${data['giftName'] ?? 'هدية'} إلى $receiverName',
            AppTheme.royalGold,
          );
        }
        _giftLogic.queueGift(data);
      }
    });
  }

  Widget _buildBackground() {
    return VoiceRoomUIWidgets.buildBackground(_dynamicBgImage);
  }

  Widget _buildRoomNotice() {
    return VoiceRoomUIWidgets.buildRoomNotice(_roomNoticeText);
  }

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

  Future<void> _performMinimizeExit() async {
    // حفظ البيانات الضرورية قبل إغلاق الواجهة
    final String rId = widget.roomId;
    final String rName = widget.roomName;
    final String? rImg = _dynamicRoomImage ?? widget.roomImage;
    final String? oId = widget.ownerId;

    // تفعيل وضع الخلفية لضمان استمرار الصوت
    await _agoraService.setBackgroundMode(true);

    // إذا كان المستخدم على المايك، يفضل النزول عند الاحتفاظ لتوفير التكلفة (اختياري حسب سياسة التطبيق)
    // في رويال دور، سنبقي المستخدم على المايك إذا أراد ذلك، لكن نضمن استقرار الصوت

    if (!mounted) return;

    RoomPresenceService().minimizeRoom(
      context, // استخدام سياق الصفحة الرئيسي
      rId,
      rName,
      rImg,
      onRoomTap: () {
        // عند العودة للغرفة، نفتح الصفحة مجدداً
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VoiceRoomPage(
              roomId: rId,
              roomName: rName,
              roomImage: rImg,
              ownerId: oId,
            ),
          ),
        );
      },
    );

    // الخروج من الصفحة الحالية (تصغير)
    Navigator.pop(context);
  }

  Future<void> _performFinalExit() async {
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

    // مغادرة المايك
    HapticFeedback.mediumImpact();
    await _micLogic.leaveMic(_mySeat);

    // تحديث الوجود
    if (_currentUserId.isNotEmpty) {
      final roomRef = _db.collection('rooms').doc(widget.roomId);
      await roomRef.update({
        'onlineUsers': FieldValue.arrayRemove([_currentUserId])
      });
    }

    // إيقاف الصوت والمغادرة
    await _agoraService.stopMusic();
    await _agoraService.leave();
    RoomPresenceService().closeMinimized();

    if (mounted) {
      Navigator.pop(context); // الخروج من الغرفة
    }
  }

  void _showExitOptions() {
    showDialog(
        context: context,
        barrierColor: Colors.black.withAlpha(204),
        builder: (dialogCtx) => Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
              GestureDetector(
                  onTap: () async {
                    Navigator.pop(dialogCtx);
                    await _performMinimizeExit();
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
                    Navigator.pop(dialogCtx);
                    await _performFinalExit();
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

/// وجبة مخصصة لعرض هالة التحدث بشكل مستقل
class _MicSpeakingGlow extends StatefulWidget {
  final Color? color;
  const _MicSpeakingGlow({this.color});

  @override
  State<_MicSpeakingGlow> createState() => _MicSpeakingGlowState();
}

class _MicSpeakingGlowState extends State<_MicSpeakingGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color glowColor = widget.color ?? Colors.greenAccent;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 68 + (12 * _controller.value),
          height: 68 + (12 * _controller.value),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color:
                  glowColor.withValues(alpha: 0.8 - (0.6 * _controller.value)),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(
                    alpha: 0.3 * (1.0 - _controller.value)),
                blurRadius: 15,
                spreadRadius: 5 * _controller.value,
              )
            ],
          ),
        );
      },
    );
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

class RoyalMusicPlayerSheet extends StatefulWidget {
  final String roomId;
  final AgoraService agoraService;
  final String currentMusicName;
  final bool isMusicPlaying;
  final int musicDuration;
  final int musicPosition;
  final double musicVolume;
  final Function(String, bool, int, int) onMusicUpdate;
  final Function(double) onVolumeChanged;
  final Future<void> Function() onPickMusic;
  final VoidCallback onToggleMusic;

  const RoyalMusicPlayerSheet({
    super.key,
    required this.roomId,
    required this.agoraService,
    required this.currentMusicName,
    required this.isMusicPlaying,
    required this.musicDuration,
    required this.musicPosition,
    required this.musicVolume,
    required this.onMusicUpdate,
    required this.onVolumeChanged,
    required this.onPickMusic,
    required this.onToggleMusic,
  });

  @override
  State<RoyalMusicPlayerSheet> createState() => _RoyalMusicPlayerSheetState();
}

class _RoyalMusicPlayerSheetState extends State<RoyalMusicPlayerSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  late double _localVolume;
  int _localPos = 0;
  bool _localPlaying = false;
  StreamSubscription? _posSub;

  @override
  void initState() {
    super.initState();
    _localVolume = widget.musicVolume;
    _localPos = widget.musicPosition;
    _localPlaying = widget.isMusicPlaying;
    _rotationController =
        AnimationController(vsync: this, duration: const Duration(seconds: 15));

    if (_localPlaying) _rotationController.repeat();

    _posSub = widget.agoraService.musicPositionStream.listen((pos) {
      if (mounted) {
        setState(() => _localPos = pos);
      }
    });
  }

  @override
  void dispose() {
    _posSub?.cancel();
    _rotationController.dispose();
    super.dispose();
  }

  String _formatDuration(int msec) {
    final d = Duration(milliseconds: msec);
    return "${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 25,
        bottom: MediaQuery.of(context).padding.bottom + 15,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0A121A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
        border: Border(top: BorderSide(color: AppTheme.royalGold, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 45,
              height: 5,
              decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.only(bottom: 25)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.equalizer, color: AppTheme.royalGold),
              const Text('مشغل الوسائط الملكي',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5)),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 30),
          // ديسك الموسيقى المتحرك
          RotationTransition(
            turns: _rotationController,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(colors: [
                    AppTheme.royalGold.withValues(alpha: 0.1),
                    AppTheme.royalGold,
                    AppTheme.royalGold.withValues(alpha: 0.1),
                  ])),
              child: Container(
                padding: const EdgeInsets.all(35),
                decoration: const BoxDecoration(
                    color: Color(0xFF0F1B25), shape: BoxShape.circle),
                child: Icon(
                    _localPlaying
                        ? Icons.music_note_rounded
                        : Icons.music_off_rounded,
                    color: _localPlaying ? AppTheme.royalGold : Colors.white10,
                    size: 50),
              ),
            ),
          ),
          const SizedBox(height: 35),
          Text(widget.currentMusicName,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          const Text('بث مباشر عالي الجودة 🎙️',
              style: TextStyle(color: AppTheme.royalGold, fontSize: 11)),
          const SizedBox(height: 30),
          if (widget.musicDuration <= 0 && !_localPlaying)
            Center(
              child: GestureDetector(
                onTap: () async {
                  await widget.onPickMusic();
                  if (mounted) setState(() => _localPlaying = true);
                  _rotationController.repeat();
                },
                child: Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                      color: AppTheme.royalGold.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppTheme.royalGold.withValues(alpha: 0.2),
                          width: 2)),
                  child: const Column(
                    children: [
                      Icon(Icons.library_music_rounded,
                          color: AppTheme.royalGold, size: 60),
                      SizedBox(height: 10),
                      Text('اختر ملف MP3',
                          style:
                              TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            )
          else ...[
            Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape:
                        const RoundSliderThumbShape(enabledThumbRadius: 7),
                    overlayShape:
                        const RoundSliderOverlayShape(overlayRadius: 15),
                  ),
                  child: Slider(
                    value: _localPos.toDouble().clamp(
                        0,
                        widget.musicDuration > 0
                            ? widget.musicDuration.toDouble()
                            : 1),
                    max: widget.musicDuration > 0
                        ? widget.musicDuration.toDouble()
                        : 1,
                    onChanged: (v) {
                      widget.agoraService.seekMusic(v.toInt());
                      setState(() => _localPos = v.toInt());
                    },
                    activeColor: AppTheme.royalGold,
                    inactiveColor: Colors.white10,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(_localPos),
                          style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                      Text(_formatDuration(widget.musicDuration),
                          style: const TextStyle(
                              color: Colors.white38,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                    icon: const Icon(Icons.replay_10,
                        size: 32, color: Colors.white70),
                    onPressed: () {
                      int newPos = _localPos - 10000;
                      if (newPos < 0) newPos = 0;
                      widget.agoraService.seekMusic(newPos);
                      setState(() => _localPos = newPos);
                    }),
                const SizedBox(width: 25),
                GestureDetector(
                  onTap: () {
                    widget.onToggleMusic();
                    setState(() {
                      _localPlaying = !_localPlaying;
                      if (_localPlaying) {
                        _rotationController.repeat();
                      } else {
                        _rotationController.stop();
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: const BoxDecoration(
                        color: AppTheme.royalGold, shape: BoxShape.circle),
                    child: Icon(
                        _localPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 45,
                        color: Colors.black),
                  ),
                ),
                const SizedBox(width: 25),
                IconButton(
                    icon: const Icon(Icons.forward_10,
                        size: 32, color: Colors.white70),
                    onPressed: () {
                      int newPos = _localPos + 10000;
                      if (newPos > widget.musicDuration) {
                        newPos = widget.musicDuration;
                      }
                      widget.agoraService.seekMusic(newPos);
                      setState(() => _localPos = newPos);
                    }),
              ],
            ),
            const SizedBox(height: 35),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.volume_down_rounded,
                      color: AppTheme.royalGold, size: 20),
                  Expanded(
                    child: Slider(
                      value: _localVolume,
                      max: 100,
                      onChanged: (v) {
                        setState(() => _localVolume = v);
                        widget.agoraService.adjustMusicVolume(v.toInt());
                        widget.onVolumeChanged(v);
                      },
                      activeColor: AppTheme.royalGold,
                      inactiveColor: Colors.white10,
                    ),
                  ),
                  const Icon(Icons.volume_up_rounded,
                      color: AppTheme.royalGold, size: 20),
                ],
              ),
            ),
          ],
          const SizedBox(height: 35),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                    onPressed: () async {
                      await widget.onPickMusic();
                      setState(() {
                        _localPlaying = true;
                        _rotationController.repeat();
                      });
                    },
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15))),
                    icon: const Icon(Icons.folder_open_rounded,
                        color: AppTheme.royalGold, size: 20),
                    label: const Text("تغيير الملف",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: TextButton.icon(
                    onPressed: () {
                      widget.agoraService.stopMusic();
                      setState(() {
                        _localPlaying = false;
                        _localPos = 0;
                        _rotationController.stop();
                      });
                      Navigator.pop(context);
                    },
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor:
                            Colors.redAccent.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15))),
                    icon: const Icon(Icons.stop_circle_rounded,
                        color: Colors.redAccent, size: 20),
                    label: const Text("إيقاف نهائي",
                        style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold))),
              ),
            ],
          ),
          const SizedBox(height: 15),
        ],
      ),
    );
  }
}

class _UserProfileBottomSheet extends StatelessWidget {
  final String userId;
  final String? roomId;
  final String currentUserId;

  const _UserProfileBottomSheet({
    required this.userId,
    this.roomId,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF0F1B25),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding + 20),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: UserProfilePage(
              userId: userId,
              roomId: roomId,
              useScaffold: false,
            ),
          ),
        ],
      ),
    );
  }
}
