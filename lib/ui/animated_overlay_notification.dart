import 'package:flutter/material.dart';

class AnimatedOverlayNotification extends StatefulWidget {
  final String? title;
  final String? body;
  final VoidCallback? onTap;
  final String? imageUrl;

  const AnimatedOverlayNotification({
    super.key,
    this.title,
    this.body,
    this.onTap,
    this.imageUrl,
  });

  @override
  State<AnimatedOverlayNotification> createState() =>
      _AnimatedOverlayNotificationState();
}

class _AnimatedOverlayNotificationState
    extends State<AnimatedOverlayNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      reverseDuration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeIn,
    ));
    _controller.forward();
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) _controller.reverse();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SlideTransition(
        position: _offsetAnimation,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.imageUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.notifications_active,
                        color: Colors.deepPurple, size: 32),
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.title != null)
                        Text(
                          widget.title!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      if (widget.body != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            widget.body!,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.black54),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
