import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';
import 'web_rtc_service.dart';

class AgoraService {
  static final AgoraService _instance = AgoraService._internal();
  factory AgoraService() => _instance;
  AgoraService._internal();

  RtcEngine? _engine;
  int? _localUid;
  int? get localUid => _localUid;

  // WebRTC service for web platform
  final _webRTCService = WebRTCService();

  final _volumeController = StreamController<List<AudioVolumeInfo>>.broadcast();
  Stream<List<AudioVolumeInfo>> get volumeStream => _volumeController.stream;

  final _connectionController =
      StreamController<ConnectionStateType>.broadcast();
  Stream<ConnectionStateType> get connectionStream =>
      _connectionController.stream;

  final _musicPositionController = StreamController<int>.broadcast();
  Stream<int> get musicPositionStream => _musicPositionController.stream;

  final _mixingStateController = StreamController<AudioMixingStateType>.broadcast();
  Stream<AudioMixingStateType> get mixingStateStream => _mixingStateController.stream;

  String getAppId() {
    // استخدام App ID من ملف .env أو استخدام App ID افتراضي للاختبار
    try {
      final appId = dotenv.env['AGORA_APP_ID'];
      debugPrint(
          '🔍 Checking AGORA_APP_ID: ${appId == null ? "NULL" : appId.isEmpty ? "EMPTY" : "FOUND (${appId.length} chars)"}');
      if (appId == null || appId.isEmpty) {
        debugPrint('⚠️ Using default Agora App ID for testing');
        return '2042a5996de7444e9a72babc8527b25e'; // App ID من ملف .env
      }
      return appId;
    } catch (e) {
      debugPrint('⚠️ Error loading AGORA_APP_ID: $e');
      debugPrint('⚠️ Using default Agora App ID for testing');
      return '2042a5996de7444e9a72babc8527b25e';
    }
  }

  bool _joined = false;
  bool get isJoined => _joined;
  bool _isInitializing = false;
  bool _isJoining = false;

  // Music player state
  final AudioPlayer _audioPlayer = AudioPlayer();
  final int _musicDuration = 0;
  Timer? _musicTimer;
  bool _isMusicPlaying = false;
  bool _isMusicPaused = false;
  String? _currentMusicPath;

  // Room audio state
  bool _isRoomMuted = false;
  bool _isSpeakerMuted = false;
  bool _isInBackground = false;

  Completer<void>? _joinCompleter;

  Future<void> init() async {
    if (kIsWeb) {
      // Use WebRTC for web platform
      await _webRTCService.init();
      return;
    }

    if (_isInitializing) {
      debugPrint("⚠️ Agora already initializing, waiting...");
      return;
    }
    if (_engine != null) {
      debugPrint("✅ Agora already initialized");
      return;
    }

    _isInitializing = true;

    try {
      debugPrint("🔄 Initializing Agora RTC Engine");

      // التحقق من App ID
      final currentAppId = getAppId();
      debugPrint("🔑 Using Agora App ID: ${currentAppId.substring(0, 8)}...");

      // طلب الصلاحيات المطلوبة
      debugPrint("🔐 Requesting permissions...");
      final micStatus = await Permission.microphone.request();
      final btStatus = await Permission.bluetoothConnect.request();

      debugPrint(
          "🔐 Microphone permission: ${micStatus.isGranted ? 'GRANTED' : 'DENIED'}");
      debugPrint(
          "🔐 Bluetooth permission: ${btStatus.isGranted ? 'GRANTED' : 'DENIED'}");

      if (!micStatus.isGranted) {
        throw Exception("Microphone permission denied");
      }

      // إنشاء المحرك
      debugPrint("🔧 Creating Agora RTC Engine...");
      _engine = createAgoraRtcEngine();

      // تهيئة المحرك
      debugPrint("🔧 Initializing Agora Engine...");
      await _engine!.initialize(RtcEngineContext(
        appId: currentAppId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        audioScenario: AudioScenarioType.audioScenarioGameStreaming,
      ));

      debugPrint("✅ Agora Engine initialized successfully");

      // تسجيل معالجات الأحداث
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            debugPrint("✅ Agora Joined: ${connection.localUid}");
            _joined = true;
            _localUid = connection.localUid;
            if (_joinCompleter != null && !_joinCompleter!.isCompleted) {
              _joinCompleter!.complete();
            }
            _connectionController
                .add(ConnectionStateType.connectionStateConnected);
            
            // تحسين: تفعيل السبيكر فقط إذا لم يتم كتمه مسبقاً
            if (!_isSpeakerMuted) {
              _engine?.setEnableSpeakerphone(true);
            }
            _engine?.muteAllRemoteAudioStreams(_isRoomMuted);
          },
          onAudioVolumeIndication: (RtcConnection connection,
              List<AudioVolumeInfo> speakers,
              int speakerNumber,
              int totalVolume) {
            _volumeController.add(speakers);
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint("⚠️ Agora Error: $err - $msg");
            _connectionController
                .add(ConnectionStateType.connectionStateFailed);
          },
          onConnectionLost: (RtcConnection connection) {
            debugPrint("⚠️ Agora Connection Lost");
            _connectionController
                .add(ConnectionStateType.connectionStateDisconnected);
          },
          onLeaveChannel: (RtcConnection connection, RtcStats stats) {
            debugPrint("✅ Agora Left Channel");
            _connectionController
                .add(ConnectionStateType.connectionStateDisconnected);
          },
          onAudioMixingStateChanged: (AudioMixingStateType state, AudioMixingReasonType reason) {
            debugPrint("🎵 Agora Mixing State: $state, Reason: $reason");
            _mixingStateController.add(state);
            if (state == AudioMixingStateType.audioMixingStateStopped || 
                state == AudioMixingStateType.audioMixingStateFailed) {
              _isMusicPlaying = false;
              _isMusicPaused = false;
              _musicTimer?.cancel();
            } else if (state == AudioMixingStateType.audioMixingStatePlaying) {
              _isMusicPlaying = true;
              _isMusicPaused = false;
            }
          },
        ),
      );

      // ضبط إعدادات الصوت
      debugPrint("🔧 Configuring audio settings...");
      await _engine!.setParameters('{"che.audio.opensles":true}');
      await _engine!.enableAudio();
      await _engine!.setAudioProfile(
        profile: AudioProfileType.audioProfileMusicStandard,
        scenario: AudioScenarioType.audioScenarioGameStreaming,
      );
      await _engine!.setDefaultAudioRouteToSpeakerphone(true);
      await _engine!.enableAudioVolumeIndication(
        interval: 250,
        smooth: 3,
        reportVad: true,
      );

      // إعدادات للصوت في الخلفية
      await _engine!.setParameters('{"che.audio.keep.audiosession":true}');
      await _engine!.setParameters('{"che.audio.focus.request":true}');
      await _engine!.setParameters('{"che.audio.focus.mode":"constant"}');
      await _engine!.setParameters('{"che.audio.allow.background":true}');
      await _engine!.setParameters('{"che.audio.keep.awake":true}');
      await _engine!.setParameters('{"che.audio.scene":"chatroom"}');

      debugPrint("✅ Agora initialization completed successfully");
    } catch (e) {
      debugPrint("❌ Agora Init Error: $e");
      // تنظيف المحرك الفاشل
      try {
        await _engine?.release();
        _engine = null;
      } catch (_) {}
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> joinChannel(
      {required String channelId, bool asSpeaker = false}) async {
    if (kIsWeb) {
      // Use WebRTC for web platform
      await _webRTCService.joinChannel(channelId: channelId, asSpeaker: asSpeaker);
      return;
    }

    if (_isJoining || _joined) {
      debugPrint("⚠️ Agora already joining or joined, skipping...");
      return;
    }

    if (_engine == null) await init();

    _isJoining = true;
    final token = await _fetchToken(channelId);

    // If token is mandatory and we failed to get it, handle appropriately
    if (token == null) {
      debugPrint("⚠️ Failed to fetch token, attempt to join without it (might fail if app is in production mode)");
    }

    _joinCompleter = Completer<void>();

    try {
      await _engine!.setClientRole(
        role: asSpeaker
            ? ClientRoleType.clientRoleBroadcaster
            : ClientRoleType.clientRoleAudience,
      );

      final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final int numericUid = userId.isEmpty ? 0 : (userId.hashCode & 0x7FFFFFFF);

      debugPrint(
          "🔊 Joining Agora channel: $channelId, uid: $numericUid, token: ${token != null ? 'provided' : 'null'}");

      await _engine!.joinChannel(
          token: token ?? "", 
          channelId: channelId,
          uid: numericUid,
          options: ChannelMediaOptions(
            autoSubscribeAudio: true,
            publishMicrophoneTrack: asSpeaker,
            clientRoleType: asSpeaker
                ? ClientRoleType.clientRoleBroadcaster
                : ClientRoleType.clientRoleAudience,
            audienceLatencyLevel:
                AudienceLatencyLevelType.audienceLatencyLevelLowLatency,
          ));

      try {
        await _joinCompleter!.future.timeout(const Duration(seconds: 15));
        debugPrint("✅ Agora join completed successfully");
        _joined = true;
      } on TimeoutException {
        debugPrint("⚠️ Agora join timeout reached");
        // We don't set _joined = true here, but we don't throw to allow background join
      }

      if (!_isSpeakerMuted) {
        await _engine!.setEnableSpeakerphone(true);
      }
      
      // التأكد من كتم المايك محلياً إذا كان داخلاً كمستمع فقط
      if (!asSpeaker) {
        await _engine!.muteLocalAudioStream(true);
      }
    } catch (e) {
      debugPrint("❌ Agora Join Error: $e");
      _joined = false;
      try {
        await _engine!.setEnableSpeakerphone(true);
      } catch (_) {}
    } finally {
      _isJoining = false;
    }
  }

  Future<void> updateClientRole(bool asSpeaker) async {
    if (kIsWeb) {
      // WebRTC handles this automatically based on asSpeaker parameter in joinChannel
      debugPrint("🔄 WebRTC role update not needed (handled in joinChannel)");
      return;
    }

    if (_engine == null || !_joined) {
      debugPrint("⚠️ Cannot update role: Engine null or not joined");
      return;
    }

    final role = asSpeaker
        ? ClientRoleType.clientRoleBroadcaster
        : ClientRoleType.clientRoleAudience;

    try {
      await _engine!.setClientRole(role: role);

      await _engine!.updateChannelMediaOptions(ChannelMediaOptions(
        publishMicrophoneTrack: asSpeaker,
        autoSubscribeAudio: true,
        clientRoleType: role,
      ));

      if (asSpeaker) {
        await _engine!.enableLocalAudio(true);
        await _engine!.muteLocalAudioStream(false);
      } else {
        await _engine!.muteLocalAudioStream(true);
      }

      if (!_isSpeakerMuted) {
        await _engine!.setEnableSpeakerphone(true);
      }
    } catch (e) {
      debugPrint("❌ Agora update role error: $e");
    }
  }

  Future<void> toggleMute(bool muted) async {
    if (kIsWeb) {
      // Use WebRTC for web platform
      await _webRTCService.muteLocalAudio(muted);
      return;
    }
    await _engine?.muteLocalAudioStream(muted);
  }

  Future<void> toggleAllRemoteAudio(bool muted) async {
    await _engine?.muteAllRemoteAudioStreams(muted);
  }

  Future<String?> _fetchToken(String channelName) async {
    try {
      final auth = FirebaseAuth.instance;
      if (auth.currentUser == null) {
        debugPrint("⚠️ User not authenticated, skipping token fetch");
        return null;
      }

      // زيادة مهلة الانتظار لـ Cloud Functions لتجنب DEADLINE_EXCEEDED
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
        'generateAgoraToken',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 20),
        ),
      );

      final result = await callable.call({'channelName': channelName});
      final token = result.data['token'] as String?;

      if (token != null && token.isNotEmpty) {
        debugPrint("✅ Token fetched successfully");
        return token;
      } else {
        debugPrint("⚠️ Token is null or empty from server");
        return null;
      }
    } catch (e) {
      debugPrint("! Token fetch error: $e");
      
      // التعامل مع أخطاء App Check و Timeout
      if (e is FirebaseFunctionsException) {
        if (e.code == 'deadline-exceeded') {
          debugPrint("⏰ Cloud Function timeout (DEADLINE_EXCEEDED)");
        }
      }
      
      return null;
    }
  }

  Future<void> leave() async {
    if (kIsWeb) {
      // Use WebRTC for web platform
      await _webRTCService.leave();
      return;
    }

    if (_engine == null) return;
    try {
      await _engine!.leaveChannel();
    } catch (e) {
      debugPrint("⚠️ Error leaving channel: $e");
    }
    _joined = false;
    _isJoining = false;
    _localUid = null;
  }

  RtcEngine? get engine => _engine;

  /// Enable or disable automatic gain control (AGC) via engine parameters.
  Future<void> setAGCEnabled(bool enabled) async {
    try {
      await _engine
          ?.setParameters('{"che.audio.agc": ${enabled ? 'true' : 'false'}}');
      debugPrint('AGC set to: $enabled');
    } catch (e) {
      debugPrint('Failed to set AGC: $e');
    }
  }

  /// Apply a simple EQ preset by sending parameters to the engine.
  /// Preset examples: 'flat', 'bass_boost', 'voice'
  Future<void> applyEQPreset(String preset) async {
    try {
      await _engine?.setParameters('{"che.audio.eq": "$preset"}');
      debugPrint('EQ preset applied: $preset');
    } catch (e) {
      debugPrint('Failed to apply EQ preset: $e');
    }
  }

  // Music player methods using Agora Audio Mixing for "Global" sound
  Future<void> startMusic(String path) async {
    if (_engine == null) return;
    try {
      if (_isMusicPlaying) {
        await stopMusic();
      }

      // استخدام startAudioMixing لبث الصوت للجميع في الغرفة
      // path: المسار للملف (محلي أو URL)
      // loopback: false لكي يسمعه الجميع
      // replace: false لكي لا يستبدل صوت المايك
      // cycle: -1 للتكرار اللانهائي (أو 1 لمرة واحدة)
      await _engine!.startAudioMixing(
        filePath: path,
        loopback: false,
        cycle: 1,
      );

      _isMusicPlaying = true;
      _isMusicPaused = false;
      _currentMusicPath = path;

      // تحسين مؤقت الموضع باستخدام بيانات Agora
      _musicTimer?.cancel();
      _musicTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
        if (!_isMusicPlaying || _isMusicPaused) return;
        
        final position = await _engine!.getAudioMixingCurrentPosition();
        if (position >= 0) {
          _musicPositionController.add(position); // Agora returns milliseconds
        }
      });

      debugPrint('✅ Global Music started via Agora: $path');
    } catch (e) {
      debugPrint('❌ Error starting Agora music: $e');
    }
  }

  Future<void> stopMusic() async {
    if (_engine == null) return;
    try {
      await _engine!.stopAudioMixing();
      _musicTimer?.cancel();
      _isMusicPlaying = false;
      _isMusicPaused = false;
      _currentMusicPath = null;
      _musicPositionController.add(0);
      debugPrint('✅ Agora Music stopped');
    } catch (e) {
      debugPrint('❌ Error stopping Agora music: $e');
    }
  }

  Future<void> pauseMusic() async {
    if (_engine == null) return;
    try {
      await _engine!.pauseAudioMixing();
      _isMusicPaused = true;
      debugPrint('✅ Agora Music paused');
    } catch (e) {
      debugPrint('❌ Error pausing Agora music: $e');
    }
  }

  Future<void> resumeMusic() async {
    if (_engine == null) return;
    try {
      await _engine!.resumeAudioMixing();
      _isMusicPaused = false;
      debugPrint('✅ Agora Music resumed');
    } catch (e) {
      debugPrint('❌ Error resuming Agora music: $e');
    }
  }

  Future<int> getMusicDuration() async {
    if (_engine == null) return 0;
    try {
      return await _engine!.getAudioMixingDuration();
    } catch (e) {
      debugPrint('❌ Error getting Agora music duration: $e');
      return 0;
    }
  }

  Future<void> adjustMusicVolume(int volume) async {
    if (_engine == null) return;
    try {
      // تعديل مستوى صوت البث (للآخرين)
      await _engine!.adjustAudioMixingPublishVolume(volume);
      // تعديل مستوى صوت الاستماع (للمستخدم المحلي)
      await _engine!.adjustAudioMixingPlayoutVolume(volume);
      debugPrint('✅ Agora Music volume adjusted to: $volume');
    } catch (e) {
      debugPrint('❌ Error adjusting Agora music volume: $e');
    }
  }

  Future<void> seekMusic(int positionMs) async {
    if (_engine == null) return;
    try {
      await _engine!.setAudioMixingPosition(positionMs);
      debugPrint('✅ Agora Music seeked to: $positionMs ms');
    } catch (e) {
      debugPrint('❌ Error seeking Agora music: $e');
    }
  }

  void dispose() {
    _volumeController.close();
    _connectionController.close();
    _musicPositionController.close();
    _mixingStateController.close();
    _musicTimer?.cancel();
    _audioPlayer.dispose();
  }

  // --- Room Audio Management ---

  /// كتم صوت الغرفة بالكامل (remote audio)
  Future<void> muteRoomAudio(bool muted) async {
    if (_engine == null) return;
    try {
      _isRoomMuted = muted;
      await _engine?.muteAllRemoteAudioStreams(muted);
      debugPrint('✅ Room audio ${muted ? "muted" : "unmuted"}');
    } catch (e) {
      debugPrint('❌ Error muting room audio: $e');
    }
  }

  /// كتم السبيكر (speakerphone)
  Future<void> muteSpeaker(bool muted) async {
    if (_engine == null) return;
    try {
      _isSpeakerMuted = muted;
      await _engine?.setEnableSpeakerphone(!muted);
      debugPrint('✅ Speaker ${muted ? "muted" : "unmuted"}');
    } catch (e) {
      debugPrint('❌ Error muting speaker: $e');
    }
  }

  /// الحصول على حالة كتم صوت الغرفة
  bool get isRoomMuted => _isRoomMuted;

  /// الحصول على حالة كتم السبيكر
  bool get isSpeakerMuted => _isSpeakerMuted;

  /// Web only: Check if audio is blocked by browser
  bool get isAudioBlockedByBrowser => kIsWeb && _webRTCService.audioAutoplayBlocked;

  /// Web only: Stream for autoplay blocked state
  Stream<bool> get audioBlockedStream => _webRTCService.autoplayBlockedStream;

  /// Web only: Resume audio context
  Future<void> resumeAudio() async {
    if (kIsWeb) {
      await _webRTCService.resumeAudio();
    }
  }

  /// الحصول على حالة الوضع الخلفي
  bool get isInBackground => _isInBackground;

  /// تعيين حالة الوضع الخلفي (يستخدم عند الاحتفاظ بالغرفة)
  Future<void> setBackgroundMode(bool inBackground) async {
    _isInBackground = inBackground;

    // عند الاحتفاظ بالغرفة: أبقِ الصوت شغال دائماً
    if (inBackground) {
      // إلغاء كتم صوت الغرفة وتفعيل السبيكر
      await muteRoomAudio(false);
      await muteSpeaker(false);

      // إعدادات إضافية للصوت في الخلفية
      await _engine?.setParameters('{"che.audio.keep.audiosession":true}');
      await _engine?.setParameters('{"che.audio.focus.request":true}');
      await _engine?.setParameters('{"che.audio.focus.mode":"constant"}');
      await _engine?.setParameters('{"che.audio.allow.background":true}');

      // إبقاء الموسيقى شغالة إذا كانت تعمل
      if (_isMusicPlaying) {
        await resumeMusic();
      }

      debugPrint('✅ Background: Room audio continues');
    } else {
      // عند العودة من الاحتفاظ، استعد حالة الصوت الأصلية
      if (_isSpeakerMuted) {
        await muteRoomAudio(true);
        await muteSpeaker(true);
      } else {
        await muteRoomAudio(false);
        await muteSpeaker(false);
      }
      debugPrint('✅ Foreground: Room audio restored');
    }
  }

  /// كتم/إلغاء كتم الصوت من شريط المحادثة
  Future<void> toggleMuteFromChat(bool muted) async {
    _isSpeakerMuted = muted;
    await muteSpeaker(muted);

    // إذا كان في الوضع الخلفي، كتم صوت الغرفة أيضاً
    if (_isInBackground) {
      await muteRoomAudio(muted);
      debugPrint(
          '✅ Chat toggle: Room audio ${muted ? "muted" : "unmuted"} (background mode)');
    }
  }

  // --- Music State Getters ---

  bool get isMusicPlaying => _isMusicPlaying;
  bool get isMusicPaused => _isMusicPaused;
  String? get currentMusicPath => _currentMusicPath;
}
