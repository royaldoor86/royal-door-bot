import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import '../../../app_theme.dart';
import '../diaries_page.dart'; // for downloadMedia if it's there, but better move it to a utility

class VideoWidget extends StatefulWidget {
  final String videoUrl;
  const VideoWidget({super.key, required this.videoUrl});

  @override
  State<VideoWidget> createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _showControls = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..setLooping(false)
      ..initialize().then((_) {
        if (mounted) setState(() => _isInitialized = true);
      });
    _controller.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.removeListener(() {});
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openFullScreen() async {
    if (!_isInitialized) return;
    _controller.pause();
    await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => FullScreenVideo(
                controller: _controller, videoUrl: widget.videoUrl)));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final height = width * 9 / 16;

      return Container(
        height: height,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: Colors.black, borderRadius: BorderRadius.circular(15)),
        child: _isInitialized
            ? ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Stack(
                  children: [
                    SizedBox(
                      width: width,
                      height: height,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: _controller.value.size.width == 0
                              ? width
                              : _controller.value.size.width,
                          height: _controller.value.size.height == 0
                              ? height
                              : _controller.value.size.height,
                          child: VideoPlayer(_controller),
                        ),
                      ),
                    ),
                    if (_showControls)
                      Positioned.fill(child: Container(color: Colors.black26)),
                    Center(
                      child: AnimatedOpacity(
                        opacity: _controller.value.isPlaying ? 0.0 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: IconButton(
                          iconSize: 56,
                          icon: Icon(
                              _controller.value.isPlaying
                                  ? Icons.pause_circle_filled
                                  : Icons.play_circle_fill,
                              color: Colors.white70),
                          onPressed: () => setState(() =>
                              _controller.value.isPlaying
                                  ? _controller.pause()
                                  : _controller.play()),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 8,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          VideoProgressIndicator(
                            _controller,
                            allowScrubbing: true,
                            colors: const VideoProgressColors(
                                playedColor: AppTheme.royalGold,
                                bufferedColor: Colors.white24,
                                backgroundColor: Colors.white12),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                _formatDuration(_controller.value.position),
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                              const Spacer(),
                              Text(
                                _formatDuration(_controller.value.duration),
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _openFullScreen,
                        onLongPress: () =>
                            setState(() => _showControls = !_showControls),
                      ),
                    ),
                  ],
                ),
              )
            : const Center(
                child: CircularProgressIndicator(color: AppTheme.royalGold)),
      );
    });
  }

  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) return '${d.inHours}:$mm:$ss';
    return '$mm:$ss';
  }
}

class FullScreenVideo extends StatefulWidget {
  final VideoPlayerController controller;
  final String? videoUrl;
  const FullScreenVideo({super.key, required this.controller, this.videoUrl});

  @override
  State<FullScreenVideo> createState() => _FullScreenVideoState();
}

class _FullScreenVideoState extends State<FullScreenVideo> {
  bool _didAutoPop = false;

  void _checkCompletion() {
    final c = widget.controller;
    final pos = c.value.position;
    final dur = c.value.duration;
    if (dur.inMilliseconds > 0 &&
        pos.inMilliseconds >= (dur.inMilliseconds - 200) &&
        !_didAutoPop) {
      _didAutoPop = true;
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    widget.controller.play();
    widget.controller.addListener(_checkCompletion);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_checkCompletion);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: widget.controller.value.size.width == 0
                        ? MediaQuery.of(context).size.width
                        : widget.controller.value.size.width,
                    height: widget.controller.value.size.height == 0
                        ? MediaQuery.of(context).size.height
                        : widget.controller.value.size.height,
                    child: VideoPlayer(widget.controller),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty)
                    Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(8)),
                        child: IconButton(
                            icon: const Icon(Icons.download_outlined,
                                color: Colors.white),
                            onPressed: () async {
                              await downloadMedia(context, widget.videoUrl!,
                                  isImage: false);
                            })),
                  const SizedBox(height: 8),
                  _iconButton(
                      icon: Icons.close,
                      onTap: () => Navigator.of(context).pop()),
                ],
              ),
            ),
            Center(
              child: IconButton(
                iconSize: 64,
                icon: Icon(
                    widget.controller.value.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                    color: Colors.white70),
                onPressed: () => setState(() =>
                    widget.controller.value.isPlaying
                        ? widget.controller.pause()
                        : widget.controller.play()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconButton({required IconData icon, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.black45, borderRadius: BorderRadius.circular(8)),
      child:
          IconButton(icon: Icon(icon, color: Colors.white), onPressed: onTap),
    );
  }
}
