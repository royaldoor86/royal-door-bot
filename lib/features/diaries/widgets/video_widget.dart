import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../../app_theme.dart';

class VideoWidget extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;

  const VideoWidget({
    super.key,
    required this.videoUrl,
    this.autoPlay = false,
  });

  @override
  State<VideoWidget> createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isMuted = true;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..setLooping(true)
      ..setVolume(_isMuted ? 0 : 1)
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _isInitialized = true);
          // سنقوم بتشغيل الفيديو فقط إذا كان مسموحاً له بالتشغيل التلقائي
          if (widget.autoPlay) _controller.play();
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // تم إزالة VisibilityDetector مؤقتاً لحل مشكلة المكتبة المفقودة
    // سيعمل الفيديو الآن عند الضغط عليه أو إذا كان autoPlay مفعل
    return GestureDetector(
      onTap: () {
        if (!_isInitialized) return;
        setState(() {
          if (_controller.value.isPlaying) {
            _controller.pause();
          } else {
            _controller.play();
            // عند التشغيل، نجعل الصوت مفعلاً أو مكتوماً حسب الرغبة
            _controller.setVolume(_isMuted ? 0 : 1);
          }
        });
      },
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 500, minHeight: 250),
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_isInitialized)
              AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            else
              const Center(child: CircularProgressIndicator(color: AppTheme.royalGold, strokeWidth: 2)),
            
            // زر كتم الصوت
            Positioned(
              bottom: 15,
              right: 15,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isMuted = !_isMuted;
                    _controller.setVolume(_isMuted ? 0 : 1);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                  child: Icon(
                    _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),

            // أيقونة التشغيل في حالة التوقف
            if (_isInitialized && !_controller.value.isPlaying)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 50),
              ),
          ],
        ),
      ),
    );
  }
}
