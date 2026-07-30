import 'dart:async';

class WebRTCService {
  static final WebRTCService _instance = WebRTCService._internal();
  factory WebRTCService() => _instance;
  WebRTCService._internal();

  Stream<double> get volumeStream => const Stream.empty();
  Stream<bool> get connectionStream => const Stream.empty();
  Stream<bool> get autoplayBlockedStream => const Stream.empty();

  bool get audioAutoplayBlocked => false;
  bool get isJoined => false;
  bool get isMuted => false;
  bool get isSpeakerMuted => false;

  Future<void> init() async {}
  Future<void> resumeAudio() async {}
  Future<void> joinChannel({required String channelId, bool asSpeaker = false}) async {}
  Future<void> leave() async {}
  Future<void> muteLocalAudio(bool muted) async {}
  Future<void> setSpeakerphone(bool enabled) async {}
  Future<void> adjustRecordingSignalVolume(int volume) async {}
  Future<void> adjustPlaybackSignalVolume(int volume) async {}
  void dispose() {}
}
