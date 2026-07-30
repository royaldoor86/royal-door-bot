import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';

@JS('window')
external JSObject get _window;

/// A service to handle WebRTC functionality using Agora Web SDK.
class WebRTCService {
  static final WebRTCService _instance = WebRTCService._internal();
  factory WebRTCService() => _instance;
  WebRTCService._internal();

  JSObject? _client;
  JSObject? _localAudioTrack;
  final List<JSObject> _remoteAudioTracks = <JSObject>[];
  
  final _volumeController = StreamController<double>.broadcast();
  Stream<double> get volumeStream => _volumeController.stream;

  final _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  bool _isInitialized = false;
  bool _isJoined = false;
  bool _isMuted = false;
  bool _isSpeakerMuted = false;

  /// Retrieves the AGORA APP ID.
  String getAppId() {
    try {
      if (_window.hasProperty('AGORA_APP_ID'.toJS).toDart) {
        final appId = _window.getProperty('AGORA_APP_ID'.toJS);
        if (appId != null && appId.isString) {
          return (appId as JSString).toDart;
        }
      }
      return '2042a5996de7444e9a72babc8527b25e';
    } catch (e) {
      return '2042a5996de7444e9a72babc8527b25e';
    }
  }

  bool _audioAutoplayBlocked = false;
  bool get audioAutoplayBlocked => _audioAutoplayBlocked;

  final _autoplayBlockedController = StreamController<bool>.broadcast();
  Stream<bool> get autoplayBlockedStream => _autoplayBlockedController.stream;

  /// Initializes the Agora RTC Engine.
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      debugPrint("🔄 Initializing Agora Web SDK");
      
      if (!_window.hasProperty('AgoraRTC'.toJS).toDart) {
        throw Exception("Agora Web SDK not loaded");
      }

      final agoraRtc = _window.getProperty('AgoraRTC'.toJS) as JSObject;

      // Create client for Agora SDK v4.
      final clientOptions = JSObject();
      clientOptions.setProperty('mode'.toJS, 'live'.toJS);
      clientOptions.setProperty('codec'.toJS, 'vp8'.toJS);

      _client = agoraRtc.callMethod('createClient'.toJS, clientOptions) as JSObject;

      // Handle Autoplay policy.
      agoraRtc.setProperty('onAudioAutoplayPaused'.toJS, (() {
        debugPrint("🔇 Audio Autoplay blocked by browser. User interaction required.");
        _audioAutoplayBlocked = true;
        _autoplayBlockedController.add(true);
      }).toJS);
      
      _isInitialized = true;
      debugPrint("✅ Agora Web SDK initialized successfully");
    } catch (e) {
      debugPrint("❌ Agora Web SDK initialization error: $e");
      rethrow;
    }
  }

  /// Manually resumes audio context on user interaction.
  Future<void> resumeAudio() async {
    try {
      for (final track in _remoteAudioTracks) {
        final playPromise = track.callMethod('play'.toJS) as JSPromise;
        await playPromise.toDart;
      }
      _audioAutoplayBlocked = false;
      _autoplayBlockedController.add(false);
      debugPrint("🔊 Audio context resumed successfully");
    } catch (e) {
      debugPrint("❌ Error resuming audio: $e");
    }
  }

  /// Joins a channel with the specified ID.
  Future<void> joinChannel({required String channelId, bool asSpeaker = false}) async {
    if (!_isInitialized) {
      await init();
    }

    try {
      debugPrint("🎤 Joining channel: $channelId as ${asSpeaker ? 'speaker' : 'audience'}");

      final appId = getAppId();
      final uid = DateTime.now().millisecondsSinceEpoch % 4294967295;
      
      if (_client == null) throw Exception("Client not initialized");

      // Join channel.
      final joinPromise = _client!.callMethod('join'.toJS, appId.toJS, channelId.toJS, null, uid.toJS) as JSPromise;
      await joinPromise.toDart;

      if (asSpeaker) {
        final agoraRtc = _window.getProperty('AgoraRTC'.toJS) as JSObject;
        
        // Create local audio track.
        final trackPromise = agoraRtc.callMethod('createMicrophoneAudioTrack'.toJS) as JSPromise;
        _localAudioTrack = (await trackPromise.toDart) as JSObject;
        
        final playPromise = _localAudioTrack!.callMethod('play'.toJS) as JSPromise;
        await playPromise.toDart;
        
        final publishPromise = _client!.callMethod('publish'.toJS, _localAudioTrack!) as JSPromise;
        await publishPromise.toDart;
        
        if (_isMuted) {
          _localAudioTrack!.callMethod('setEnabled'.toJS, false.toJS);
        }
      }

      // Subscribe to remote users.
      _client!.callMethod('on'.toJS, 'user-published'.toJS, ((JSObject user, JSString mediaType) async {
        final type = mediaType.toDart;
        debugPrint("📥 Remote user published, mediaType: $type");
        
        final subscribePromise = _client!.callMethod('subscribe'.toJS, user, mediaType) as JSPromise;
        await subscribePromise.toDart;
        
        if (type == 'audio') {
          final remoteAudioTrack = user.getProperty('audioTrack'.toJS);
          if (remoteAudioTrack != null) {
            final track = remoteAudioTrack as JSObject;
            final playPromise = track.callMethod('play'.toJS) as JSPromise;
            await playPromise.toDart;
            _remoteAudioTracks.add(track);
          }
        }
      }).toJS);

      _client!.callMethod('on'.toJS, 'user-unpublished'.toJS, ((JSObject user, JSString mediaType) {
        final type = mediaType.toDart;
        debugPrint("📤 Remote user unpublished, mediaType: $type");
        if (type == 'audio') {
          final remoteAudioTrack = user.getProperty('audioTrack'.toJS);
          if (remoteAudioTrack != null) {
            final track = remoteAudioTrack as JSObject;
            track.callMethod('stop'.toJS);
            _remoteAudioTracks.remove(track);
          }
        }
      }).toJS);

      _isJoined = true;
      _connectionController.add(true);
      debugPrint("✅ Joined channel successfully");
    } catch (e) {
      debugPrint("❌ Error joining channel: $e");
      rethrow;
    }
  }

  /// Leaves the current channel.
  Future<void> leave() async {
    try {
      debugPrint("🚪 Leaving channel");

      if (_localAudioTrack != null) {
        _localAudioTrack!.callMethod('stop'.toJS);
        _localAudioTrack!.callMethod('close'.toJS);
        _localAudioTrack = null;
      }

      for (final track in _remoteAudioTracks) {
        track.callMethod('stop'.toJS);
        track.callMethod('close'.toJS);
      }
      _remoteAudioTracks.clear();

      if (_client != null) {
        final leavePromise = _client!.callMethod('leave'.toJS) as JSPromise;
        await leavePromise.toDart;
        _client = null;
      }

      _isJoined = false;
      _isInitialized = false;
      _connectionController.add(false);

      debugPrint("✅ Left channel successfully");
    } catch (e) {
      debugPrint("❌ Error leaving channel: $e");
    }
  }

  /// Mutes or unmutes the local audio track.
  Future<void> muteLocalAudio(bool muted) async {
    if (_localAudioTrack == null) return;

    try {
      _localAudioTrack!.callMethod('setEnabled'.toJS, (!muted).toJS);
      _isMuted = muted;
      debugPrint("🔇 Audio muted: $muted");
    } catch (e) {
      debugPrint("❌ Error muting audio: $e");
    }
  }

  /// Sets the speakerphone status.
  Future<void> setSpeakerphone(bool enabled) async {
    _isSpeakerMuted = !enabled;
    debugPrint("🔊 Speakerphone: $enabled");
  }

  /// Adjusts the recording signal volume. Not supported on web.
  Future<void> adjustRecordingSignalVolume(int volume) async {
    debugPrint("🎚️ Recording volume: $volume (not supported on web)");
  }

  /// Adjusts the playback signal volume. Not supported on web.
  Future<void> adjustPlaybackSignalVolume(int volume) async {
    debugPrint("🎚️ Playback volume: $volume (not supported on web)");
  }

  bool get isJoined => _isJoined;
  bool get isMuted => _isMuted;
  bool get isSpeakerMuted => _isSpeakerMuted;

  /// Disposes of the service and releases resources.
  void dispose() {
    leave();
    _volumeController.close();
    _connectionController.close();
    _autoplayBlockedController.close();
  }
}
