import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';

class AgoraService {
  static final AgoraService _instance = AgoraService._internal();
  factory AgoraService() => _instance;
  AgoraService._internal();

  RtcEngine? _engine;
  int? _localUid;
  int? get localUid => _localUid;

  final _volumeController = StreamController<List<AudioVolumeInfo>>.broadcast();
  Stream<List<AudioVolumeInfo>> get volumeStream => _volumeController.stream;

  final _connectionController =
      StreamController<ConnectionStateType>.broadcast();
  Stream<ConnectionStateType> get connectionStream =>
      _connectionController.stream;

  final _musicPositionController = StreamController<int>.broadcast();
  Stream<int> get musicPositionStream => _musicPositionController.stream;

  static String get appId =>
      dotenv.env['AGORA_APP_ID'] ?? "daed7a59dcbd4de2969b7504ae0843dc";

  bool _joined = false;
  bool get isJoined => _joined;
  bool _isInitializing = false;

  // Music player state
  final int _musicDuration = 0;
  Timer? _musicTimer;

  Completer<void>? _joinCompleter;

  Future<void> init() async {
    if (_isInitializing || _engine != null) return;
    _isInitializing = true;
    try {
      await [
        Permission.microphone,
        Permission.bluetoothConnect,
      ].request();

      _engine = createAgoraRtcEngine();

      await _engine!.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        audioScenario: AudioScenarioType.audioScenarioGameStreaming,
      ));

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

          _engine?.setEnableSpeakerphone(true);
          _engine?.muteAllRemoteAudioStreams(false);
        }, onAudioVolumeIndication: (RtcConnection connection,
                List<AudioVolumeInfo> speakers,
                int speakerNumber,
                int totalVolume) {
          _volumeController.add(speakers);
        }, onError: (ErrorCodeType err, String msg) {
          debugPrint("⚠️ Agora Error: $err - $msg");
          _connectionController.add(ConnectionStateType.connectionStateFailed);
        }, onConnectionLost: (RtcConnection connection) {
          debugPrint("⚠️ Agora Connection Lost");
          _connectionController
              .add(ConnectionStateType.connectionStateDisconnected);
        }, onLeaveChannel: (RtcConnection connection, RtcStats stats) {
          debugPrint("✅ Agora Left Channel");
          _connectionController
              .add(ConnectionStateType.connectionStateDisconnected);
        }),
      );

      await _engine!.setParameters('{"che.audio.opensles":true}');
      await _engine!.enableAudio();
      await _engine!.setAudioProfile(
        profile: AudioProfileType.audioProfileMusicStandard,
        scenario: AudioScenarioType.audioScenarioGameStreaming,
      );

      await _engine!.setEnableSpeakerphone(true);
      await _engine!.setDefaultAudioRouteToSpeakerphone(true);
      await _engine!.enableAudioVolumeIndication(
          interval: 250, smooth: 3, reportVad: true);
    } catch (e) {
      debugPrint("❌ Agora Init Error: $e");
    } finally {
      _isInitializing = false;
    }
  }

  Future<void> joinChannel(
      {required String channelId, bool asSpeaker = false}) async {
    if (_engine == null) await init();

    // For testing, allow joining without token
    final token = await _fetchToken(channelId);
    _joinCompleter = Completer<void>();

    try {
      await _engine!.setClientRole(
        role: asSpeaker
            ? ClientRoleType.clientRoleBroadcaster
            : ClientRoleType.clientRoleAudience,
      );

      await _engine!.joinChannel(
          token: token ?? "", // Use empty string if token is null
          channelId: channelId,
          uid: 0,
          options: ChannelMediaOptions(
            autoSubscribeAudio: true,
            publishMicrophoneTrack: asSpeaker,
            clientRoleType: asSpeaker
                ? ClientRoleType.clientRoleBroadcaster
                : ClientRoleType.clientRoleAudience,
            audienceLatencyLevel:
                AudienceLatencyLevelType.audienceLatencyLevelLowLatency,
          ));

      await _joinCompleter!.future.timeout(const Duration(seconds: 15));
      await _engine!.setEnableSpeakerphone(true);
    } catch (e) {
      debugPrint("❌ Agora Join Error: $e");
      _joined = false;
    }
  }

  Future<void> updateClientRole(bool asSpeaker) async {
    if (_engine == null) return;

    await _engine!.setClientRole(
      role: asSpeaker
          ? ClientRoleType.clientRoleBroadcaster
          : ClientRoleType.clientRoleAudience,
    );

    await _engine!.updateChannelMediaOptions(ChannelMediaOptions(
      publishMicrophoneTrack: asSpeaker,
      autoSubscribeAudio: true,
    ));

    if (asSpeaker) {
      await _engine!.enableLocalAudio(true);
      await _engine!.muteLocalAudioStream(false);
    } else {
      await _engine!.muteLocalAudioStream(true);
    }

    await _engine!.setEnableSpeakerphone(true);
  }

  Future<void> toggleMute(bool muted) async {
    await _engine?.muteLocalAudioStream(muted);
  }

  Future<void> toggleAllRemoteAudio(bool muted) async {
    await _engine?.muteAllRemoteAudioStreams(muted);
  }

  Future<String?> _fetchToken(String channelName) async {
    try {
      final HttpsCallable callable =
          FirebaseFunctions.instance.httpsCallable('generateAgoraToken');
      final result = await callable.call({'channelName': channelName});
      return result.data['token'] as String?;
    } catch (e) {
      debugPrint("⚠️ Token Warning: $e");
      return null;
    }
  }

  Future<void> leave() async {
    if (_engine == null) return;
    await _engine!.leaveChannel();
    _joined = false;
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
      // Example parameter payload - the exact implementation can be refined
      final params = {
        'preset': preset,
      };
      await _engine?.setParameters('{"che.audio.eq": "$preset"}');
      debugPrint('EQ preset applied: $preset');
    } catch (e) {
      debugPrint('Failed to apply EQ preset: $e');
    }
  }

  // Music player methods (placeholder implementations)
  Future<void> startMusic(String path) async {
    // Placeholder for music playback
    debugPrint('Music started: $path');
  }

  Future<void> stopMusic() async {
    // Placeholder for stopping music
    debugPrint('Music stopped');
    _musicTimer?.cancel();
  }

  Future<void> pauseMusic() async {
    // Placeholder for pausing music
    debugPrint('Music paused');
  }

  Future<void> resumeMusic() async {
    // Placeholder for resuming music
    debugPrint('Music resumed');
  }

  Future<int> getMusicDuration() async {
    // Placeholder for getting music duration
    return _musicDuration;
  }

  Future<void> adjustMusicVolume(int volume) async {
    // Placeholder for adjusting music volume
    debugPrint('Music volume adjusted to: $volume');
  }

  Future<void> seekMusic(int position) async {
    // Placeholder for seeking music
    debugPrint('Music seeked to: $position');
  }

  void dispose() {
    _volumeController.close();
    _connectionController.close();
    _musicPositionController.close();
    _musicTimer?.cancel();
  }
}
