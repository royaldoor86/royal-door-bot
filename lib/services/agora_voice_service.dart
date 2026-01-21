// lib/services/agora_voice_service.dart
//
// ✅ Agora Voice Service (مصحح نهائي)
// - يحل AgoraRtcException(-3) عبر تطبيق speaker بعد join فقط
// - يدعم Token فارغ (Testing Mode) أو Token موجود
// - يطلب صلاحية المايك
// - join/leave/release صحيح
// - Audio volume indication جاهز للأنيميشن/المؤشرات
//
// ملاحظة: ضع AppId الصحيح (32 حرف) عند إنشاء الخدمة.

import 'dart:async';
import 'dart:math';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraVoiceService extends ChangeNotifier {
  AgoraVoiceService({
    required this.appId,
    this.defaultSpeakerOn = true,
    this.onLog,
    this.onJoined,
    this.onLeft,
    this.onRemoteJoined,
    this.onRemoteLeft,
  }) : _speakerOn = defaultSpeakerOn;

  final String appId;

  /// افتراضيًا نخلي السبيكر شغّال بعد الـ join
  final bool defaultSpeakerOn;

  /// Logs للواجهة
  final void Function(String msg)? onLog;

  /// Callbacks للواجهة (اختياري)
  final void Function(int localUid)? onJoined;
  final VoidCallback? onLeft;
  final void Function(int remoteUid)? onRemoteJoined;
  final void Function(int remoteUid)? onRemoteLeft;

  // ========= Engine / State =========
  RtcEngine? _engine;

  bool _permissionGranted = false;
  bool _initialized = false;
  bool _joining = false;
  bool _joined = false;

  int? _localUid;
  final Set<int> _remoteUids = <int>{};

  bool _muted = false;
  bool _speakerOn;

  int _localVolume = 0;
  final Map<int, int> _remoteVolumes = <int, int>{};

  // ========= Public Getters =========
  bool get permissionGranted => _permissionGranted;
  bool get initialized => _initialized;
  bool get joining => _joining;
  bool get joined => _joined;

  int? get localUid => _localUid;
  List<int> get remoteUids => _remoteUids.toList()..sort();

  bool get muted => _muted;
  bool get speakerOn => _speakerOn;

  int get localVolume => _localVolume;
  Map<int, int> get remoteVolumes => Map.unmodifiable(_remoteVolumes);

  bool get readyToJoin =>
      _permissionGranted && _initialized && !_joining && !_joined;

  // ========= Logging =========
  void _log(String m) {
    onLog?.call(m);
    // ignore: avoid_print
    print(m);
  }

  // ========= Permissions =========
  Future<bool> requestMicPermission() async {
    final status = await Permission.microphone.request();
    _permissionGranted = status.isGranted;

    _log(_permissionGranted
        ? '✅ microphone permission granted'
        : '❌ microphone permission NOT granted');

    notifyListeners();
    return _permissionGranted;
  }

  // ========= Init =========
  Future<void> init() async {
    if (_initialized) return;

    final id = appId.trim();
    if (id.isEmpty) {
      _log('❌ APP_ID فارغ');
      return;
    }
    if (id.length != 32) {
      _log('❌ APP_ID غير صحيح (لازم 32 حرف) length=${id.length}');
      return;
    }

    try {
      final engine = createAgoraRtcEngine();

      await engine.initialize(
        RtcEngineContext(
          appId: id,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );

      engine.registerEventHandler(
        RtcEngineEventHandler(
          onError: (err, msg) => _log('❌ Agora Error: $err | $msg'),
          onJoinChannelSuccess: (conn, elapsed) async {
            _localUid = conn.localUid;
            _joined = true;
            _joining = false;

            _log(
                '✅ Joined channel "${conn.channelId}" as uid=${conn.localUid}');
            notifyListeners();
            onJoined?.call(conn.localUid ?? 0);

            // ✅ مهم: تطبيق speaker بعد join لتفادي -3
            await Future.delayed(const Duration(milliseconds: 250));
            try {
              await _engine?.setEnableSpeakerphone(_speakerOn);
              _log('🔊 Speaker applied AFTER join (speakerOn=$_speakerOn)');
            } catch (e) {
              _log('⚠️ setEnableSpeakerphone failed AFTER join (ignored): $e');
            }
          },
          onLeaveChannel: (conn, stats) {
            _log('🚪 Left channel');
            _joined = false;
            _joining = false;
            _remoteUids.clear();
            _remoteVolumes.clear();
            _localVolume = 0;
            notifyListeners();
            onLeft?.call();
          },
          onUserJoined: (conn, remoteUid, elapsed) {
            _remoteUids.add(remoteUid);
            _log('👤 Remote user joined: $remoteUid');
            notifyListeners();
            onRemoteJoined?.call(remoteUid);
          },
          onUserOffline: (conn, remoteUid, reason) {
            _remoteUids.remove(remoteUid);
            _remoteVolumes.remove(remoteUid);
            _log('👤 Remote user offline: $remoteUid (reason: $reason)');
            notifyListeners();
            onRemoteLeft?.call(remoteUid);
          },
          onTokenPrivilegeWillExpire: (conn, token) {
            _log('⚠️ Token will expire soon. Renew token.');
          },
          onRequestToken: (conn) {
            _log('⚠️ Agora requested a new token (expired/invalid).');
          },
          onAudioVolumeIndication:
              (conn, speakers, speakerNumber, totalVolume) {
            int local = 0;
            final Map<int, int> rem = {};
            for (final s in speakers) {
              final uid = (s.uid ?? 0);
              final vol = (s.volume ?? 0).clamp(0, 100);
              if (uid == 0) {
                local = vol;
              } else {
                rem[uid] = vol;
              }
            }
            _localVolume = local;
            _remoteVolumes
              ..clear()
              ..addAll(rem);
            notifyListeners();
          },
        ),
      );

      await engine.enableAudio();
      await engine.disableVideo();

      // ✅ لا تستدعي setEnableSpeakerphone هنا

      await engine.enableAudioVolumeIndication(
        interval: 200,
        smooth: 3,
        reportVad: true,
      );

      // افتراضيًا افتح المايك
      await engine.muteLocalAudioStream(false);
      _muted = false;

      _engine = engine;
      _initialized = true;

      _log('✅ Agora initialized (ready to join)');
      notifyListeners();
    } catch (e) {
      _log('❌ Failed to init Agora: $e');
      _initialized = false;
      try {
        await _engine?.release();
      } catch (_) {}
      _engine = null;
      notifyListeners();
    }
  }

  int _generateUid() => 100000 + Random().nextInt(800000);

  // ========= Join =========
  Future<void> join({
    required String channelName,
    String token = '',
    int? uid,
  }) async {
    if (_joining || _joined) return;

    final ch = channelName.trim();
    final tk = token.trim();

    if (ch.isEmpty) {
      _log('❌ Channel فارغ');
      return;
    }

    if (!_permissionGranted) {
      final ok = await requestMicPermission();
      if (!ok) return;
    }

    await init();
    if (!_initialized || _engine == null) return;

    _joining = true;
    notifyListeners();

    try {
      _localUid = (uid ?? _localUid ?? _generateUid());

      _log(
          '➡️ Trying join: channel="$ch" token=${tk.isEmpty ? "(empty)" : "(provided)"} uid=$_localUid');

      await _engine!.joinChannel(
        token: tk, // ارسله نص (حتى لو فارغ) لتجنب null
        channelId: ch,
        uid: _localUid!,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileCommunication,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
          autoSubscribeVideo: false,
        ),
      );

      _log('✅ join request sent');
      // _joined يتفعل من onJoinChannelSuccess
    } catch (e) {
      _log('❌ joinChannel failed: $e');
      _joining = false;
      notifyListeners();
      rethrow;
    }
  }

  // ========= Leave =========
  Future<void> leave() async {
    final engine = _engine;
    if (engine == null) return;

    try {
      await engine.leaveChannel();
    } catch (e) {
      _log('⚠️ leaveChannel error (ignored): $e');
    }
  }

  // ========= Controls =========
  Future<void> setMuted(bool muted) async {
    final engine = _engine;
    if (engine == null) return;

    _muted = muted;
    notifyListeners();

    try {
      await engine.muteLocalAudioStream(muted);
      _log(muted ? '🎙️ Mic muted' : '🎙️ Mic unmuted');
    } catch (e) {
      _log('⚠️ muteLocalAudioStream failed (ignored): $e');
    }
  }

  Future<void> setSpeakerOn(bool on) async {
    final engine = _engine;
    if (engine == null) return;

    _speakerOn = on;
    notifyListeners();

    // ✅ آمن: لو رجع -3 بأي جهاز ما نكسر التطبيق
    try {
      await engine.setEnableSpeakerphone(on);
      _log(on ? '🔊 Speaker ON' : '👂 Speaker OFF (earpiece)');
    } catch (e) {
      _log('⚠️ setEnableSpeakerphone failed (ignored): $e');
    }
  }

  // ========= Release =========
  Future<void> _releaseInternal() async {
    final engine = _engine;
    _engine = null;

    _initialized = false;
    _joining = false;
    _joined = false;

    _localUid = null;
    _remoteUids.clear();
    _remoteVolumes.clear();
    _localVolume = 0;

    notifyListeners();

    try {
      await engine?.leaveChannel();
    } catch (_) {}
    try {
      await engine?.release();
    } catch (_) {}

    _log('🧹 Agora released');
  }

  @override
  void dispose() {
    // لا يمكن await داخل dispose
    unawaited(_releaseInternal());
    super.dispose();
  }
}
