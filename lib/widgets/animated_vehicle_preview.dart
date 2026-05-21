import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AnimatedVehiclePreview extends StatefulWidget {
  final String type;
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;

  const AnimatedVehiclePreview({
    required this.type,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    super.key,
  });

  @override
  State<AnimatedVehiclePreview> createState() => _AnimatedVehiclePreviewState();
}

class _AnimatedVehiclePreviewState extends State<AnimatedVehiclePreview> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  void _initPlayer() {
    if (widget.type == "video") {
      if (widget.url.isEmpty) {
        setState(() => _hasError = true);
        return;
      }
      try {
        _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
          ..initialize().then((_) {
            if (mounted) {
              setState(() {
                _isInitialized = true;
                _controller!.setLooping(true);
                _controller!.setVolume(0);
                _controller!.play();
              });
            }
          }).catchError((e) {
            if (mounted) setState(() => _hasError = true);
          });
      } catch (e) {
        if (mounted) setState(() => _hasError = true);
      }
    }
  }

  @override
  void didUpdateWidget(AnimatedVehiclePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.type != widget.type) {
      _controller?.dispose();
      _controller = null;
      _isInitialized = false;
      _hasError = false;
      _initPlayer();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_hasError) return const Center(child: Icon(Icons.broken_image, color: Colors.white10, size: 40));

    switch (widget.type) {
      case "lottie":
        return Lottie.network(
          widget.url,
          fit: widget.fit,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.white10),
        );
      case "gif":
        return CachedNetworkImage(
          imageUrl: widget.url,
          fit: widget.fit,
          placeholder: (context, url) => const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.white10),
        );
      case "video":
        if (_isInitialized && _controller != null) {
          return SizedBox.expand(
            child: FittedBox(
              fit: widget.fit,
              child: SizedBox(
                width: _controller!.value.size.width,
                height: _controller!.value.size.height,
                child: VideoPlayer(_controller!),
              ),
            ),
          );
        }
        return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)));
      default:
        return const Center(child: Icon(Icons.directions_car, color: Colors.white24, size: 50));
    }
  }
}
