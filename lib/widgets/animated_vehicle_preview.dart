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
    Key? key,
  }) : super(key: key);

  @override
  State<AnimatedVehiclePreview> createState() => _AnimatedVehiclePreviewState();
}

class _AnimatedVehiclePreviewState extends State<AnimatedVehiclePreview> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.type == "video") {
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
        });
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
          placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.white10),
        );
      case "video":
        if (_isInitialized && _controller != null) {
          return FittedBox(
            fit: widget.fit,
            child: SizedBox(
              width: _controller!.value.size.width,
              height: _controller!.value.size.height,
              child: VideoPlayer(_controller!),
            ),
          );
        }
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      default:
        return const Icon(Icons.directions_car, color: Colors.white24, size: 50);
    }
  }
}
