import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app_theme.dart';
import '../../../services/firestore_service.dart';
import '../../voice_room_page.dart';

class AnnouncedRoomInfoSheet extends StatefulWidget {
  final String roomId;

  const AnnouncedRoomInfoSheet({super.key, required this.roomId});

  @override
  State<AnnouncedRoomInfoSheet> createState() => _AnnouncedRoomInfoSheetState();
}

class _AnnouncedRoomInfoSheetState extends State<AnnouncedRoomInfoSheet> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final FirestoreService _firestoreService = FirestoreService();

  DocumentSnapshot? _roomData;
  DocumentSnapshot? _ownerData;
  bool _isLoading = true;
  bool _isFollowing = false;
  bool _isFan = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final roomSnap = await _db.collection('rooms').doc(widget.roomId).get();
      if (!roomSnap.exists) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final roomData = roomSnap.data() as Map<String, dynamic>;
      final ownerId = roomData['ownerId'];
      DocumentSnapshot? ownerSnap;
      if (ownerId != null) {
        ownerSnap = await _db.collection('users').doc(ownerId).get();
      }

      final userSnap = await _db.collection('users').doc(_currentUserId).get();
      final followingRooms =
          (userSnap.data())?['following_rooms']
                  as Map? ??
              {};

      final fanSnap = await _db
          .collection('rooms')
          .doc(widget.roomId)
          .collection('fan_club')
          .doc(_currentUserId)
          .get();

      if (mounted) {
        setState(() {
          _roomData = roomSnap;
          _ownerData = ownerSnap;
          _isFollowing = followingRooms[widget.roomId] == true;
          _isFan = fanSnap.exists;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _followRoom() async {
    await _firestoreService.toggleFollowRoom(_currentUserId, widget.roomId);
    setState(() => _isFollowing = !_isFollowing);
  }

  void _joinOrLeaveFanClub() async {
    final fanRef = _db
        .collection('rooms')
        .doc(widget.roomId)
        .collection('fan_club')
        .doc(_currentUserId);
    if (_isFan) {
      await fanRef.delete();
    } else {
      // ملاحظة: هذا تطبيق مبسط للانضمام. يمكن تطويره لاحقاً ليشمل رسوم الانضمام.
      await fanRef
          .set({'joinedAt': FieldValue.serverTimestamp(), 'uid': _currentUserId});
    }
    setState(() => _isFan = !_isFan);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_roomData == null || !_roomData!.exists) {
      return _buildErrorState('لم يتم العثور على الغرفة');
    }

    final room = _roomData!.data() as Map<String, dynamic>;
    final owner = _ownerData?.data() as Map<String, dynamic>?;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF0F1B25),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        border: Border(top: BorderSide(color: AppTheme.royalGold, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 40,
            backgroundImage: CachedNetworkImageProvider(room['roomImage'] ?? ''),
          ),
          const SizedBox(height: 12),
          Text(room['name'] ?? 'غرفة ملكية',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          if (owner != null)
            Text('بواسطة: ${owner['name'] ?? ''}',
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text('ID: ${room['roomId']}',
              style: const TextStyle(color: AppTheme.royalGold, fontSize: 12)),
          const Divider(color: Colors.white12, height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                  onPressed: _joinOrLeaveFanClub,
                  label: _isFan ? 'أنت عضو' : 'انضم للنادي',
                  icon: _isFan ? Icons.star_rounded : Icons.star_border_rounded,
                  isActive: _isFan,
                  activeColor: Colors.green,
                  inactiveColor: AppTheme.royalGold),
              _buildActionButton(
                  onPressed: _followRoom,
                  label: _isFollowing ? 'إلغاء المتابعة' : 'متابعة',
                  icon: _isFollowing
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_none_rounded,
                  isActive: _isFollowing,
                  activeColor: Colors.grey[600]!,
                  inactiveColor: Colors.blueAccent),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close sheet
              Navigator.pop(context); // Close current room
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => VoiceRoomPage(
                          roomId: widget.roomId, roomName: room['name'])));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 45),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text('الانتقال إلى الغرفة 🚀',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildActionButton(
      {required VoidCallback onPressed,
      required String label,
      required IconData icon,
      required bool isActive,
      required Color activeColor,
      required Color inactiveColor}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? activeColor.withValues(alpha: 0.2) : inactiveColor,
        foregroundColor: isActive ? activeColor : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: isActive ? BorderSide(color: activeColor) : null,
      ),
    );
  }

  Widget _buildLoadingState() => Container(
      height: 300,
      decoration: const BoxDecoration(
        color: Color(0xFF0F1B25),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child:
          const Center(child: CircularProgressIndicator(color: AppTheme.royalGold)));

  Widget _buildErrorState(String message) => Container(
      height: 300,
      decoration: const BoxDecoration(
        color: Color(0xFF0F1B25),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Center(child: Text(message, style: const TextStyle(color: Colors.white))));
}