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
  bool _timerStarted = false;

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
    final isVideo = widget.giftType == 'video' || _isVideo(mediaUrl);

    // تايمر أمان عام لضمان اختفاء الهدية مهما حدث في التحميل
    _startDisplayTimer(const Duration(seconds: 20));

    if (isVideo && mediaUrl.isNotEmpty) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(mediaUrl))
        ..initialize().then((_) {
          if (!mounted) return;

          setState(() {});
          _videoController?.setVolume(1.0);
          _videoController?.setLooping(false);
          _videoController?.play();

          // نبدأ التايمر فقط بعد تشغيل الفيديو بنجاح
          if (!_isClosing) {
            _timerStarted = true;
            final rawDuration =
                _videoController?.value.duration ?? const Duration(seconds: 8);
            final videoDuration = rawDuration > Duration.zero
                ? rawDuration
                : const Duration(seconds: 8);

            // وقت عرض الفيديو + 3 ثواني
            _startDisplayTimer(videoDuration + const Duration(seconds: 3));
          }
        }).catchError((error) {
          debugPrint("Video initialization error: $error");
          if (mounted && !_timerStarted) {
            _startDisplayTimer(const Duration(seconds: 8));
          }
        });
    } else {
      _playGiftSound();
      // للصور والـ GIF، سيتم تحديث التايمر في imageBuilder
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
          // خلفية داكنة مع تأثير ضبابي
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                color: Colors.black.withValues(alpha: 0.85),
              ),
            ),
          ),
          // تأثيرات إضاءة خلفية
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.0,
                    colors: [
                      Colors.amber.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          // المحتوى الرئيسي
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
                            width: MediaQuery.of(context).size.width * 0.95,
                            height: MediaQuery.of(context).size.height * 0.75,
                            fit: BoxFit.contain,
                            placeholder: (context, url) => const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.pinkAccent),
                            ),
                            errorWidget: (context, url, error) =>
                                const SizedBox(),
                            fadeInDuration: const Duration(milliseconds: 500),
                            fadeOutDuration: const Duration(milliseconds: 500),
                            memCacheWidth: 1200,
                            memCacheHeight: 1200,
                            imageBuilder: (context, imageProvider) {
                              // نبدأ التايمر الحقيقي بعد تحميل الصورة
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (!_isClosing && !_timerStarted) {
                                  _timerStarted = true;
                                  final isGif = widget.giftType == 'gif' ||
                                      _isGif(mediaUrl);
                                  _startDisplayTimer(isGif
                                      ? const Duration(seconds: 15)
                                      : const Duration(seconds: 8));
                                }
                              });
                              return Image(
                                image: imageProvider,
                                width: MediaQuery.of(context).size.width * 0.95,
                                height:
                                    MediaQuery.of(context).size.height * 0.75,
                                fit: BoxFit.contain,
                              );
                            },
                          ),
                        ),
                );
              },
            ),
          ),
          // معلومات الهدية بتصميم ناعم وعصري
          Positioned(
            bottom: 50,
            left: 20,
            right: 20,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // تفاصيل الهدية (جهة اليسار)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${widget.senderName} أهدى ${widget.receiverName}",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 4,
                              )
                            ],
                          ),
                        ),
                        const SizedBox(height: 5),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Colors.amber, Colors.orangeAccent],
                          ).createShader(bounds),
                          child: Text(
                            "${widget.giftName} x${widget.count}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // زر التخطي (جهة اليمين)
                  GestureDetector(
                    onTap: _finishAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'تخطي',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.white.withValues(alpha: 0.8),
                            size: 14,
                          ),
                        ],
                      ),
                    ),
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
