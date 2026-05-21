import 'dart:async';
import 'dart:convert';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

import 'agora_token.dart';

class AgoraTokenResult {
  final String token;
  final int uid;

  AgoraTokenResult({required this.token, required this.uid});
}

class AgoraService {
  static final AgoraService _instance = AgoraService._internal();
  factory AgoraService() => _instance;
  AgoraService._internal();

  RtcEngine? _engine;
  int? _localUid;
  int? get localUid => _localUid;

  final _volumeController = StreamController<List<AudioVolumeInfo>>.broadcast();
  Stream<List<AudioVolumeInfo>> get volumeStream => _volumeController.stream;

  final _musicPositionController = StreamController<int>.broadcast();
  Stream<int> get musicPositionStream => _musicPositionController.stream;

  final _connectionController =
      StreamController<ConnectionStateType>.broadcast();
  Stream<ConnectionStateType> get connectionStream =>
      _connectionController.stream;

  static const String appId = "2042a5996de7444e9a72babc8527b25e";

  bool _joined = false;
  bool get isJoined => _joined;
  bool _isInitializing = false;
  bool _isMusicActive = false; // تتبع ما إذا كانت الموسيقى تعمل

  /// تهيئة محرك Agora RTC
  /// - طلب إذن المايك
  /// - إعداد المحرك بجودة صوت منخفضة جداً لتوفير التكلفة (audioProfileSpeechLowQuality)
  /// - تسجيل معالجات الأحداث
  /// - تفعيل Listener Mode افتراضياً لتقليل استهلاك Agora
  Future<void> init() async {
    if (_isInitializing || _engine != null) return;
    _isInitializing = true;
    try {
      // طلب أذونات المايك والبلوتوث
      final statuses = await [
        Permission.microphone,
        Permission.bluetoothConnect,
      ].request();

      if (statuses[Permission.microphone]?.isGranted != true) {
        debugPrint("⚠️ Microphone permission denied");
      }

      _engine = createAgoraRtcEngine();

      // تهيئة المحرك بجودة صوت منخفضة جداً لتوفير التكلفة
      // audioScenarioChatroom: مناسب للغرف الصوتية مع استهلاك منخفض
      await _engine!.initialize(const RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        audioScenario: AudioScenarioType.audioScenarioChatroom,
      ));

      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            _joined = true;
            _localUid = connection.localUid;
            debugPrint(
                "✅ Agora Joined: ${connection.channelId} with UID: $_localUid");
            _engine?.setEnableSpeakerphone(true);
            // كتم المايك تلقائياً عند الدخول - Listener Mode لتوفير التكلفة
            _engine?.muteLocalAudioStream(true);
          },
          onConnectionStateChanged: (RtcConnection connection,
              ConnectionStateType state, ConnectionChangedReasonType reason) {
            _connectionController.add(state);
            if (state == ConnectionStateType.connectionStateDisconnected ||
                state == ConnectionStateType.connectionStateFailed) {
              debugPrint("📡 Agora Disconnected: $reason");
            }
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            debugPrint("👤 Agora Remote User Joined: $remoteUid");
          },
          onUserOffline: (RtcConnection connection, int remoteUid,
              UserOfflineReasonType reason) {
            debugPrint("🚶 Agora Remote User Offline: $remoteUid");
          },
          onAudioVolumeIndication: (RtcConnection connection,
              List<AudioVolumeInfo> speakers,
              int speakerNumber,
              int totalVolume) {
            _volumeController.add(speakers);
          },
          onAudioMixingStateChanged:
              (AudioMixingStateType state, AudioMixingReasonType reason) {
            if (state == AudioMixingStateType.audioMixingStatePlaying) {
              _isMusicActive = true;
            } else if (state == AudioMixingStateType.audioMixingStateStopped ||
                state == AudioMixingStateType.audioMixingStateFailed) {
              _isMusicActive = false;
            }
          },
          onError: (ErrorCodeType err, String msg) {
            debugPrint("❌ Agora Error: $err - $msg");
          },
        ),
      );

      await _engine!.enableAudio();

      // استخدام جودة صوت منخفضة لتوفير التكلفة
      // audioProfileSpeechStandard: استهلاك منخفض للبيانات والمعالجة
      // مناسب للغرف الصوتية فقط - لا يستخدم للموسيقى أو HD
      await _engine!.setAudioProfile(
        profile: AudioProfileType.audioProfileSpeechStandard,
        scenario: AudioScenarioType.audioScenarioChatroom,
      );

      // تفعيل مؤشرات الصوت للكشف عن الصمت (Auto-Mute)
      // interval: 200ms - تحديث سريع للكشف عن الصمت
      // reportVad: true - تفعيل Voice Activity Detection للكشف التلقائي عن الصوت
      await _engine!.enableAudioVolumeIndication(
          interval: 200, smooth: 3, reportVad: true);

      // إصلاح مشكلة الصوت في بعض أجهزة أندرويد
      // استخدام OpenSL ES لتحسين الأداء
      await _engine!.setParameters('{"che.audio.opensl":true}');

      Timer.periodic(const Duration(milliseconds: 500), (timer) async {
        if (_joined && _engine != null && _isMusicActive) {
          try {
            int pos = await _engine!.getAudioMixingCurrentPosition();
            if (pos >= 0) _musicPositionController.add(pos);
          } catch (_) {}
        }
      });
    } catch (e) {
      debugPrint("❌ Agora Init Error: $e");
    } finally {
      _isInitializing = false;
    }
  }

  Future<AgoraTokenResult?> _fetchToken(String channelName) async {
    int retries = 3;
    while (retries > 0) {
      try {
        // التأكد من تسجيل الدخول قبل أي شيء
        var currentUser = FirebaseAuth.instance.currentUser;

        if (currentUser == null) {
          debugPrint("⏳ Waiting for Firebase Auth...");
          await Future.delayed(const Duration(seconds: 2));
          currentUser = FirebaseAuth.instance.currentUser;
        }

        if (currentUser == null) return null;

        debugPrint("🔑 Requesting token for: ${currentUser.uid}");

        // جلب توكن الهوية وتنشيط الجلسة
        await currentUser.getIdToken(true);

        final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
            'generateAgoraToken',
            options:
                HttpsCallableOptions(timeout: const Duration(seconds: 15)));

        final result = await callable.call({'channelName': channelName});

        if (result.data != null && result.data['token'] != null) {
          final token = result.data['token'] as String;
          final dynamic uidValue = result.data['uid'];
          final int uid = uidValue is int
              ? uidValue
              : int.tryParse(uidValue?.toString() ?? '') ??
                  _deriveAgoraUid(FirebaseAuth.instance.currentUser?.uid ?? '');
          return AgoraTokenResult(token: token, uid: uid);
        }
        return null;
      } catch (e) {
        debugPrint("⚠️ Token attempt ($retries) failed: $e");
        // إذا كان الخطأ بسبب App Check أو المصادقة، ننتظر وقت أطول قليلاً
        await Future.delayed(const Duration(seconds: 3));
        retries--;
      }
    }

    debugPrint(
        "ℹ️ Falling back to local Agora token generation for channel: $channelName");
    return _generateLocalToken(channelName);
  }

  AgoraTokenResult? _generateLocalToken(String channelName) {
    const appCertificate = "4b1952e689234f4fb5eb83a290b37581";
    const int tokenExpireSeconds = 3600;
    const int privilegeExpireSeconds = 3600;

    final firebaseUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (firebaseUid.isEmpty) {
      debugPrint("❌ Cannot generate local Agora token without Firebase user");
      return null;
    }

    try {
      final int localUid = _deriveAgoraUid(firebaseUid);
      final token = AgoraTokenBuilder.buildTokenWithUid(
        appId,
        appCertificate,
        channelName,
        localUid,
        AgoraTokenRole.publisher,
        tokenExpireSeconds,
        privilegeExpireSeconds,
      );
      debugPrint("✅ Local Agora token generated successfully (uid=$localUid)");
      return AgoraTokenResult(token: token, uid: localUid);
    } catch (error) {
      debugPrint("❌ Local Agora token generation failed: $error");
      return null;
    }
  }

  int _deriveAgoraUid(String firebaseUid) {
    final bytes = sha256.convert(utf8.encode(firebaseUid)).bytes;
    final int value = bytes.sublist(0, 4).fold<int>(
        0, (previousValue, element) => (previousValue << 8) | element);
    return (value & 0x7FFFFFFF) + 1;
  }

  /// الانضمام إلى قناة Agora
  /// - جميع المستخدمين يدخلون كمستمعين (Audience) لتوفير التكلفة
  /// - المايك مكتوم تلقائياً (publishMicrophoneTrack: false)
  /// - استخدام Token للإنتاج (أمان عالي)
  /// - جودة صوت منخفضة جداً (audioProfileSpeechLowQuality)
  /// - فقط المتحدثين الذين يأخذون المايك يحسب عليهم السعر
  Future<void> joinChannel(
      {required String channelId, bool asSpeaker = false}) async {
    if (_engine == null) await init();
    if (_joined) await leave();

    debugPrint("🌐 Fetching Agora token for channel: $channelId");
    final tokenResult = await _fetchToken(channelId);

    if (tokenResult == null || tokenResult.token.isEmpty) {
      debugPrint("❌ Aborting Join: Valid token is required for this project.");
      return;
    }

    try {
      // جميع المستخدمين يدخلون كمستمعين لتوفير التكلفة
      // Audience: لا يحسب عليهم السعر لأنهم لا يرسلون صوت
      const role = ClientRoleType.clientRoleAudience;
      final int uid = tokenResult.uid;

      // جودة صوت منخفضة لتوفير التكلفة
      // يتم تفعيلها مرة أخرى للتأكد من الإعدادات الصحيحة
      await _engine!.setAudioProfile(
        profile: AudioProfileType.audioProfileSpeechStandard,
        scenario: AudioScenarioType.audioScenarioChatroom,
      );

      await _engine!.setClientRole(role: role);

      await _engine!.joinChannel(
        token: tokenResult.token,
        channelId: channelId,
        uid: uid,
        options: const ChannelMediaOptions(
          autoSubscribeAudio: true, // استقبال الصوت من الآخرين
          publishMicrophoneTrack:
              false, // عدم إرسال الصوت (Listener Mode) - يوفر التكلفة
          clientRoleType: role,
          audienceLatencyLevel:
              AudienceLatencyLevelType.audienceLatencyLevelLowLatency,
        ),
      );
      _joined = true;

      try {
        await _engine?.setEnableSpeakerphone(true);
      } catch (e) {
        debugPrint("⚠️ Speakerphone Error: $e");
      }
    } catch (e) {
      debugPrint("❌ Agora Join Exception: $e");
    }
  }

  Future<void> startMusic(String filePath) async {
    _isMusicActive = true;
    await _engine?.startAudioMixing(
        filePath: filePath, loopback: false, cycle: 1);
  }

  Future<void> pauseMusic() async {
    await _engine?.pauseAudioMixing();
  }

  Future<void> resumeMusic() async {
    await _engine?.resumeAudioMixing();
  }

  Future<void> stopMusic() async {
    _isMusicActive = false;
    await _engine?.stopAudioMixing();
  }

  Future<void> adjustMusicVolume(int volume) async {
    await _engine?.adjustAudioMixingVolume(volume);
  }

  Future<void> seekMusic(int milliseconds) async {
    await _engine?.setAudioMixingPosition(milliseconds);
  }

  Future<int> getMusicDuration() async {
    if (!_isMusicActive) return 0;
    return await _engine?.getAudioMixingDuration() ?? 0;
  }

  Future<int> getMusicPosition() async {
    if (!_isMusicActive) return 0;
    return await _engine?.getAudioMixingCurrentPosition() ?? 0;
  }

  /// تحديث دور المستخدم بين متحدث ومستمع
  /// - asSpeaker=true: يفتح المايك (Broadcaster) - يحسب عليه السعر
  /// - asSpeaker=false: يكتم المايك (Audience) - لا يحسب عليه السعر (توفير التكلفة)
  /// - هذا هو المفتاح الرئيسي لتوفير التكلفة في Agora
  Future<void> updateClientRole(bool asSpeaker) async {
    if (_engine == null || !_joined) return;
    final role = asSpeaker
        ? ClientRoleType.clientRoleBroadcaster
        : ClientRoleType.clientRoleAudience;

    try {
      await _engine!.setClientRole(role: role);
      await _engine!.updateChannelMediaOptions(ChannelMediaOptions(
          publishMicrophoneTrack:
              asSpeaker, // إرسال الصوت فقط إذا كان متحدثاً - يوفر التكلفة
          autoSubscribeAudio: true,
          clientRoleType: role,
          audienceLatencyLevel:
              AudienceLatencyLevelType.audienceLatencyLevelLowLatency));

      // فتح المايك فقط إذا كان متحدثاً
      if (asSpeaker) {
        await _engine!.muteLocalAudioStream(false);
      } else {
        // كتم المايك عند العودة للمستمع لتوفير التكلفة
        // هذا يمنع Agora من حساب هذا المستخدم في الفاتورة
        await _engine!.muteLocalAudioStream(true);
      }
    } catch (e) {
      debugPrint("❌ Agora Update Role Error: $e");
    }
  }

  /// كتم/فتح المايك مع تحديث الدور تلقائياً
  /// - عند الكتم: يتحول إلى مستمع (Audience) - لا يحسب عليه السعر
  /// - عند الفتح: يتحول إلى متحدث (Broadcaster) - يحسب عليه السعر
  /// - هذه الدالة تضمن التوفير التلقائي للتكلفة
  Future<void> toggleMute(bool muted) async {
    if (_engine == null || !_joined) return;

    // عند كتم المايك، يتحول المستخدم إلى مستمع فقط لتوفير التكاليف
    // هذا يمنع Agora من حساب هذا المستخدم في الفاتورة
    if (muted) {
      await updateClientRole(false);
    } else {
      await updateClientRole(true);
    }
    await _engine?.muteLocalAudioStream(muted);
  }

  Future<void> toggleAllRemoteAudio(bool muted) async {
    await _engine?.muteAllRemoteAudioStreams(muted);
  }

  /// مغادرة القناة وتنظيف الموارد
  /// - مهم جداً لمنع تسرب الذاكرة وتوفير التكلفة
  /// - يجب استدعاؤه عند الخروج من الصفحة أو إغلاق التطبيق
  /// - يمنع Agora من الاستمرار في حساب المستخدم بعد الخروج
  Future<void> leave() async {
    if (!_joined) return;
    try {
      await _engine?.leaveChannel();
    } catch (e) {
      debugPrint("⚠️ Agora Leave Exception: $e");
    } finally {
      _joined = false;
      _isMusicActive = false;
    }
  }

  RtcEngine? get engine => _engine;

  /// تنظيف كامل للموارد عند إغلاق التطبيق
  /// - منع تسرب الذاكرة (Memory Leak Prevention)
  /// - إلغاء جميع الاشتراكات (Stream Controllers)
  /// - إطلاق محرك Agora (Release Engine)
  /// - مهم جداً للأداء وتوفير التكلفة
  Future<void> dispose() async {
    await leave();
    await _volumeController.close();
    await _musicPositionController.close();
    await _connectionController.close();
    await _engine?.release();
    _engine = null;
    _isInitializing = false;
  }
}
