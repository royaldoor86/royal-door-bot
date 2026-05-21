import 'package:flutter/material.dart';
import '../features/voice_room_page.dart';

class RoomPresenceService {
  static final RoomPresenceService _instance = RoomPresenceService._internal();
  factory RoomPresenceService() => _instance;
  RoomPresenceService._internal();

  OverlayEntry? _overlayEntry;

  bool get isMinimized => _overlayEntry != null;

  void minimizeRoom(
      BuildContext context, String roomId, String roomName, String? roomImage) {
    if (_overlayEntry != null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => _MinimizedRoomFloatingIcon(
        roomId: roomId,
        roomName: roomName,
        roomImage: roomImage,
        onTap: () {
          closeMinimized();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VoiceRoomPage(
                roomId: roomId,
                roomName: roomName,
                roomImage: roomImage,
              ),
            ),
          );
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void closeMinimized() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

class _MinimizedRoomFloatingIcon extends StatefulWidget {
  final String roomId;
  final String roomName;
  final String? roomImage;
  final VoidCallback onTap;

  const _MinimizedRoomFloatingIcon({
    required this.roomId,
    required this.roomName,
    this.roomImage,
    required this.onTap,
  });

  @override
  State<_MinimizedRoomFloatingIcon> createState() =>
      _MinimizedRoomFloatingIconState();
}

class _MinimizedRoomFloatingIconState extends State<_MinimizedRoomFloatingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset _offset = const Offset(20, 100);

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 5))
          ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _offset.dx,
      top: _offset.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _offset += details.delta;
          });
        },
        onTap: widget.onTap,
        child: RotationTransition(
          turns: _controller,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.cyanAccent, width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black54, blurRadius: 10)
              ],
              image: DecorationImage(
                image:
                    (widget.roomImage != null && widget.roomImage!.isNotEmpty)
                        ? NetworkImage(widget.roomImage!)
                        : const AssetImage('assets/images/room_global.jpg')
                            as ImageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
