import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../services/social_service.dart';
import '../../../services/wallet_service.dart';
import '../../profile/friends_lists_page.dart';
import '../royal_quest/theme/app_theme.dart';
import 'royal_xo_provider.dart';
import 'royal_xo_game.dart';

class RoyalXoPrivateRoomPage extends StatefulWidget {
  final String currency;
  final int entryCost;
  final int rewardAmount;

  const RoyalXoPrivateRoomPage({
    super.key,
    required this.currency,
    required this.entryCost,
    required this.rewardAmount,
  });

  @override
  State<RoyalXoPrivateRoomPage> createState() => _RoyalXoPrivateRoomPageState();
}

class _RoyalXoPrivateRoomPageState extends State<RoyalXoPrivateRoomPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String? _roomId;
  bool _isCreating = true;

  @override
  void initState() {
    super.initState();
    _createRoom();
  }

  Future<void> _createRoom() async {
    final provider = Provider.of<RoyalXoProvider>(context, listen: false);
    final success = await provider.createOnlineRoom(
      cost: widget.entryCost,
      currency: widget.currency,
    );
    
    if (success) {
      setState(() {
        _roomId = provider.roomId;
        _isCreating = false;
      });
      provider.listenToOnlineRoom();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('فشل إنشاء الغرفة الملكية')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final provider = Provider.of<RoyalXoProvider>(context);

    if (provider.status == GameStatus.playing) {
      // If guest joined, provider state will change to playing via listenToOnlineRoom
      // We should navigate to the game screen, but since this is already inside the provider scope,
      // the parent RoyalXoScreen will handle the switch.
      // However, this page is usually pushed, so we might need to pop or just wait.
      // Actually, RoyalXoModeSelection pushes RoyalXoGame which includes RoyalXoScreen.
      // If we push this PrivateRoomPage on top, we need to pop it when game starts.
    }

    return Scaffold(
      backgroundColor: AppTheme.primaryNavy,
      appBar: AppBar(
        title: const Text('غرفة ملكية خاصة', style: TextStyle(color: AppTheme.goldLight)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.goldLight),
          onPressed: () {
            provider.leaveOnlineRoom();
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryNavy, AppTheme.primaryDark],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 30),
            
            // Profile Section
            Center(
              child: Column(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.goldAccent, width: 3),
                      boxShadow: [
                        BoxShadow(color: AppTheme.goldAccent.withValues(alpha: 0.3), blurRadius: 20),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundImage: user?.photoURL != null 
                          ? NetworkImage(user!.photoURL!) 
                          : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                    ),
                  ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
                  
                  const SizedBox(height: 15),
                  
                  Text(
                    user?.displayName ?? 'الملك',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Waiting Status
            if (_isCreating)
              const CircularProgressIndicator(color: AppTheme.goldAccent)
            else ...[
              Text(
                'بانتظار انضمام منافس...',
                style: TextStyle(color: AppTheme.silverAccent, fontSize: 16),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).fadeIn(duration: 1.seconds),
              
              const SizedBox(height: 10),
              
              if (_roomId != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: AppTheme.goldAccent.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'رمز الدخول: $_roomId',
                        style: const TextStyle(color: AppTheme.goldLight, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: const Icon(Icons.copy, color: AppTheme.goldAccent, size: 20),
                        onPressed: () {
                          // Copy logic
                        },
                      ),
                    ],
                  ),
                ),
            ],

            const Spacer(),

            // Add Friend Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
              child: ElevatedButton.icon(
                onPressed: () => _showFriendsList(context),
                icon: const Icon(Icons.person_add, size: 28),
                label: const Text('دعوة صديق ملكي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.goldAccent,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 10,
                ),
              ),
            ).animate().slideY(begin: 0.5, duration: 500.ms),
          ],
        ),
      ),
    );
  }

  void _showFriendsList(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: AppTheme.primaryNavy,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 15),
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            const Text('دعوة الأصدقاء للمبارزة', style: TextStyle(color: AppTheme.goldLight, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                // Assuming friends are stored in users/uid/following or a separate friends collection
                // For now, let's list some users or use a standard friends query
                stream: _db.collection('users').limit(20).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  
                  final users = snapshot.data!.docs.where((d) => d.id != _auth.currentUser?.uid).toList();
                  
                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final userData = users[index].data() as Map<String, dynamic>;
                      final userId = users[index].id;
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: userData['photoURL'] != null 
                              ? NetworkImage(userData['photoURL']) 
                              : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                        ),
                        title: Text(userData['displayName'] ?? 'لاعب', style: const TextStyle(color: Colors.white)),
                        subtitle: Text('@${userData['username'] ?? 'user'}', style: TextStyle(color: AppTheme.silverAccent)),
                        trailing: ElevatedButton(
                          onPressed: () => _inviteFriend(userId, userData['displayName'] ?? 'لاعب'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondaryNavy,
                            foregroundColor: AppTheme.goldLight,
                            side: const BorderSide(color: AppTheme.goldAccent),
                          ),
                          child: const Text('دعوة'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _inviteFriend(String targetUid, String name) async {
    if (_roomId == null) return;
    
    // Create notification with room link and code
    await SocialService.sendNotification(
      targetUid: targetUid,
      title: 'دعوة لمبارزة XO ملكية ⚔️',
      body: 'قام ${FirebaseAuth.instance.currentUser?.displayName} بدعوتك للعب XO. رمز الغرفة: $_roomId',
      type: 'royal_xo_invite',
    );

    // Save extra data for the router to handle
    final inviteRef = FirebaseFirestore.instance
        .collection('notifications')
        .doc(targetUid)
        .collection('items')
        .where('type', isEqualTo: 'royal_xo_invite')
        .orderBy('timestamp', descending: true)
        .limit(1);
    
    final docs = await inviteRef.get();
    if (docs.docs.isNotEmpty) {
      await docs.docs.first.reference.update({
        'data': {
          'type': 'royal_xo_invite',
          'roomId': _roomId,
          'currency': widget.currency,
          'entryCost': widget.entryCost,
          'rewardAmount': widget.rewardAmount,
        }
      });
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم إرسال الدعوة لـ $name')),
      );
    }
  }
}
