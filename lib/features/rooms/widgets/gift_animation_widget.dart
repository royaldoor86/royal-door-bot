import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audioplayers/audioplayers.dart';

class RoyalGiftAnimation extends StatefulWidget {
  final String giftName;
  final String giftImageUrl;
  final String? giftVideoUrl;
  final String senderName;
  final String receiverName;
  final int count;
  final String? giftType;
  final String? soundUrl;
  final VoidCallback onComplete;

  const RoyalGiftAnimation({
    super.key,
    required this.giftName,
    required this.giftImageUrl,
    this.giftVideoUrl,
    required this.senderName,
    required this.receiverName,
    required this.count,
    this.giftType,
    this.soundUrl,
    required this.onComplete,
  });

  @override
  State<RoyalGiftAnimation> createState() => _RoyalGiftAnimationState();
}

class _RoyalGiftAnimationState extends State<RoyalGiftAnimation>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late Animation<double> _opacityAnimation;
  VideoPlayerController? _videoController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _displayTimer;
  bool _isClosing = false;

  String get _effectiveMediaUrl {
    if (widget.giftVideoUrl != null && widget.giftVideoUrl!.isNotEmpty) {
      return widget.giftVideoUrl!;
    }
    return widget.giftImageUrl;
  }

  bool _isVideo(String url) {
    final u = url.toLowerCase();
    return u.endsWith('.mp4') || u.endsWith('.mov') || u.endsWith('.webm');
  }

  bool _isGif(String url) {
    final u = url.toLowerCase();
    return u.endsWith('.gif');
  }

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _mainController, curve: Curves.easeIn));

    final mediaUrl = _effectiveMediaUrl;
    final isGif = widget.giftType == 'gif' || _isGif(mediaUrl);
    final isVideo = widget.giftType == 'video' || _isVideo(mediaUrl);

    if (isVideo && mediaUrl.isNotEmpty) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(mediaUrl))
        ..initialize().then((_) {
          if (!mounted) return;

          setState(() {});
          _videoController?.setVolume(1.0);
          _videoController?.setLooping(false);
          _videoController?.play();

          final rawDuration =
              _videoController?.value.duration ?? const Duration(seconds: 8);
          final videoDuration = rawDuration > Duration.zero
              ? rawDuration
              : const Duration(seconds: 8);

          final displayDuration = videoDuration + const Duration(seconds: 1);
          _startDisplayTimer(displayDuration);

          _videoController?.addListener(_handleVideoStatus);
        });
    } else {
      _playGiftSound();
      // Keep gift display longer by default to allow users مشاهدة الهدية كاملة
      _startDisplayTimer(
          isGif ? const Duration(seconds: 20) : const Duration(seconds: 15));
    }

    _mainController.forward();
  }

  void _finishAnimation() {
    if (_isClosing) return;
    _isClosing = true;
    _displayTimer?.cancel();
    if (mounted) {
      _mainController.reverse().then((_) => widget.onComplete());
    }
  }

  void _handleVideoStatus() {
    if (_videoController == null ||
        !_videoController!.value.isInitialized ||
        _isClosing) {
      return;
    }

    final value = _videoController!.value;
    if (!value.isPlaying &&
        value.duration > Duration.zero &&
        value.position >= value.duration - const Duration(milliseconds: 200)) {
      _finishAnimation();
    }
  }

  void _startDisplayTimer(Duration duration) {
    _displayTimer?.cancel();
    _displayTimer = Timer(duration, () {
      if (mounted) {
        _finishAnimation();
      }
    });
  }

  Future<void> _playGiftSound() async {
    try {
      if (widget.soundUrl != null && widget.soundUrl!.isNotEmpty) {
        await _audioPlayer.play(UrlSource(widget.soundUrl!));
      }
    } catch (e) {
      debugPrint("Sound Error: $e");
    }
  }

  @override
  void dispose() {
    _displayTimer?.cancel();
    _mainController.dispose();
    _videoController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: Container(color: Colors.black.withValues(alpha: 0.2)),
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _mainController,
              builder: (context, child) {
                final mediaUrl = _effectiveMediaUrl;
                final isVideo =
                    widget.giftType == 'video' || _isVideo(mediaUrl);
                return Opacity(
                  opacity: _opacityAnimation.value,
                  child: isVideo
                      ? (_videoController != null &&
                              _videoController!.value.isInitialized
                          ? SizedBox.expand(
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: SizedBox(
                                  width: _videoController!.value.size.width,
                                  height: _videoController!.value.size.height,
                                  child: VideoPlayer(_videoController!),
                                ),
                              ),
                            )
                          : const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.amber)))
                      : Center(
                        child: CachedNetworkImage(
                            imageUrl: mediaUrl,
                            width: MediaQuery.of(context).size.width * 0.9,
                            height: MediaQuery.of(context).size.height * 0.7,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const CircularProgressIndicator(color: Colors.pinkAccent),
                            errorWidget: (context, url, error) =>
                                const SizedBox(),
                          ),
                      ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: Column(
                children: [
                  Text(
                    "${widget.senderName} أهدى ${widget.receiverName}",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(blurRadius: 10, color: Colors.black)]),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "${widget.giftName} x${widget.count}",
                    style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        shadows: [Shadow(blurRadius: 10, color: Colors.black)]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
