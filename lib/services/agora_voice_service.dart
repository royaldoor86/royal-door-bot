// lib/services/agora_voice_service.dart
import 'dart:async';
import 'dart:math';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraVoiceService extends ChangeNotifier {
  static const String defaultAppId = "2042a5996de7444e9a72babc8527b25e";
  static const String primaryCertificate = "80f53822aff047ab833948acbd7c76e1";
  static const String secondaryCertificate = "4b1952e689234f4fb5eb83a290b37581";

  AgoraVoiceService({
    String? appId,
    this.defaultSpeakerOn = true,
    this.onLog,
    this.onJoined,
    this.onLeft,
    this.onRemoteJoined,
    this.onRemoteLeft,
  }) : appId = appId ?? defaultAppId, _speakerOn = defaultSpeakerOn;

  final String appId;
  final bool defaultSpeakerOn;

  final void Function(String msg)? onLog;
  final void Function(int localUid)? onJoined;
  final VoidCallback? onLeft;
  final void Function(int remoteUid)? onRemoteJoined;
  final void Function(int remoteUid)? onRemoteLeft;

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

  bool get readyToJoin => _permissionGranted && _initialized && !_joining && !_joined;

  void _log(String m) {
    onLog?.call(m);
    print(m);
  }

  Future<bool> requestMicPermission() async {
    final status = await Permission.microphone.request();
    _permissionGranted = status.isGranted;
    _log(_permissionGranted ? '✅ microphone permission granted' : '❌ microphone permission NOT granted');
    notifyListeners();
    return _permissionGranted;
  }

  Future<void> init() async {
    if (_initialized) return;

    if (appId.isEmpty) {
      _log('❌ APP_ID فارغ');
      return;
    }

    try {
      final engine = createAgoraRtcEngine();
      await engine.initialize(
        RtcEngineContext(
          appId: appId,
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ),
      );

      engine.registerEventHandler(
        RtcEngineEventHandler(
          onError: (err, msg) => _log('❌ Agora Error: $err | $msg'),
          onJoinChannelSuccess: (conn, elapsed) async {
            _localUid = conn.localUid;
            _joined = true;
            _joining = false;
            _log('✅ Joined channel "${conn.channelId}" as uid=${conn.localUid}');
            notifyListeners();
            onJoined?.call(conn.localUid ?? 0);

            await Future.delayed(const Duration(milliseconds: 250));
            try {
              await _engine?.setEnableSpeakerphone(_speakerOn);
            } catch (e) {
              _log('⚠️ setEnableSpeakerphone failed: $e');
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
          onAudioVolumeIndication: (conn, speakers, speakerNumber, totalVolume) {
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
            _remoteVolumes..clear()..addAll(rem);
            notifyListeners();
          },
        ),
      );

      await engine.enableAudio();
      await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      await engine.enableAudioVolumeIndication(interval: 200, smooth: 3, reportVad: true);

      _engine = engine;
      _initialized = true;
      _log('✅ Agora initialized (ready to join)');
      notifyListeners();
    } catch (e) {
      _log('❌ Failed to init Agora: $e');
      _initialized = false;
      _engine = null;
      notifyListeners();
    }
  }

  Future<void> join({required String channelName, String token = '', int? uid}) async {
    if (_joining || _joined) return;
    if (!_permissionGranted) {
      final ok = await requestMicPermission();
      if (!ok) return;
    }
    await init();
    if (!_initialized || _engine == null) return;

    _joining = true;
    notifyListeners();

    try {
      _localUid = (uid ?? _localUid ?? (100000 + Random().nextInt(800000)));
      await _engine!.joinChannel(
        token: token,
        channelId: channelName,
        uid: _localUid!,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
        ),
      );
    } catch (e) {
      _log('❌ joinChannel failed: $e');
      _joining = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> leave() async {
    final engine = _engine;
    if (engine == null) return;
    try {
      await engine.leaveChannel();
    } catch (e) {
      _log('⚠️ leaveChannel error: $e');
    }
  }

  Future<void> setMuted(bool muted) async {
    final engine = _engine;
    if (engine == null) return;
    _muted = muted;
    notifyListeners();
    try {
      await engine.muteLocalAudioStream(muted);
    } catch (e) {
      _log('⚠️ muteLocalAudioStream failed: $e');
    }
  }

  Future<void> setSpeakerOn(bool on) async {
    final engine = _engine;
    if (engine == null) return;
    _speakerOn = on;
    notifyListeners();
    try {
      await engine.setEnableSpeakerphone(on);
    } catch (e) {
      _log('⚠️ setEnableSpeakerphone failed: $e');
    }
  }

  @override
  void dispose() {
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }
}
