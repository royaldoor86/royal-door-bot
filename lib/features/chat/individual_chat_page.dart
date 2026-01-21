import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../../services/firestore_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart';

class IndividualChatPage extends StatefulWidget {
  final UserModel otherUser;
  final String roomId;

  const IndividualChatPage({super.key, required this.otherUser, required this.roomId});

  @override
  State<IndividualChatPage> createState() => _IndividualChatPageState();
}

class _IndividualChatPageState extends State<IndividualChatPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final ScrollController _scrollController = ScrollController();
  
  StreamSubscription<List<MessageModel>>? _messageSubscription;
  String? _lastMessageId;
  
  // Animation state
  String? _animatingGiftImage;
  String? _animatingGiftName;
  bool _showGiftAnimation = false;
  late AnimationController _giftScaleController;
  late Animation<double> _giftScaleAnimation;

  final List<Map<String, dynamic>> _royalGifts = [
    {'id': 'rose', 'name': 'وردة ملكية', 'image': 'https://cdn-icons-png.flaticon.com/512/3504/3504104.png', 'price': 10},
    {'id': 'heart', 'name': 'قلب ذهبي', 'image': 'https://cdn-icons-png.flaticon.com/512/3011/3011114.png', 'price': 50},
    {'id': 'crown', 'name': 'تاج الملك', 'image': 'https://cdn-icons-png.flaticon.com/512/2991/2991613.png', 'price': 500},
    {'id': 'car', 'name': 'سيارة فاخرة', 'image': 'https://cdn-icons-png.flaticon.com/512/3202/3202926.png', 'price': 2000},
    {'id': 'palace', 'name': 'قصر رويال', 'image': 'https://cdn-icons-png.flaticon.com/512/2853/2853361.png', 'price': 10000},
  ];

  @override
  void initState() {
    super.initState();
    _giftScaleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _giftScaleAnimation = CurvedAnimation(parent: _giftScaleController, curve: Curves.elasticOut);
    
    // مراقبة الرسائل الجديدة لتشغيل الأنيميشن
    _messageSubscription = _firestoreService.streamMessages(widget.roomId).listen((messages) {
      if (messages.isNotEmpty) {
        final latestMsg = messages.first;
        if (_lastMessageId != null && latestMsg.id != _lastMessageId) {
          // إذا كانت رسالة جديدة وهدية "كبيرة"
          if (latestMsg.giftId != null && (latestMsg.giftPrice ?? 0) >= 500) {
            _triggerGiftAnimation(latestMsg.giftImage ?? '', latestMsg.giftName ?? '');
          }
        }
        _lastMessageId = latestMsg.id;
      }
    });
  }

  void _triggerGiftAnimation(String imageUrl, String name) {
    setState(() {
      _animatingGiftImage = imageUrl;
      _animatingGiftName = name;
      _showGiftAnimation = true;
    });
    _giftScaleController.forward(from: 0).then((_) {
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _showGiftAnimation = false);
        }
      });
    });
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _messageController.dispose();
    _giftScaleController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final message = MessageModel(
      id: '',
      senderId: currentUser.uid,
      text: _messageController.text.trim(),
      timestamp: DateTime.now(),
    );

    await _firestoreService.sendMessage(widget.roomId, message);
    _messageController.clear();
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  void _showGiftPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              const Text('إرسال هدية ملكية 🎁', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
              const SizedBox(height: 20),
              SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _royalGifts.length,
                  itemBuilder: (context, index) {
                    final gift = _royalGifts[index];
                    return GestureDetector(
                      onTap: () => _sendGift(gift),
                      child: Container(
                        width: 100,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.amber.withOpacity(0.2)),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.network(gift['image'], width: 40, height: 40),
                            const SizedBox(height: 8),
                            Text(gift['name'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.monetization_on, color: Colors.amber, size: 12),
                                const SizedBox(width: 2),
                                Text('${gift['price']}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _sendGift(Map<String, dynamic> gift) async {
    Navigator.pop(context);
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final userSnap = await _firestoreService.streamUserData(currentUser.uid).first;
    if (userSnap.coins < gift['price']) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رصيدك من الكوينز غير كافٍ 👑'), backgroundColor: Colors.red));
      return;
    }

    await _firestoreService.sendGiftInChat(
      roomId: widget.roomId,
      senderId: currentUser.uid,
      receiverId: widget.otherUser.uid,
      gift: gift,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.white.withOpacity(0.7),
          elevation: 0,
          flexibleSpace: ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container(color: Colors.transparent))),
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context)),
          title: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: widget.otherUser.profilePic.isNotEmpty ? NetworkImage(widget.otherUser.profilePic) : null,
                child: widget.otherUser.profilePic.isEmpty ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.otherUser.name, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                  const Text('متصل الآن', style: TextStyle(color: Colors.green, fontSize: 10)),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(icon: const Icon(Icons.more_vert, color: Colors.black), onPressed: () {}),
          ],
        ),
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF5F7F9), Color(0xFFE8EEF5)],
                ),
              ),
              child: Column(
                children: [
                  Expanded(child: _buildMessagesList()),
                  _buildMessageInput(),
                ],
              ),
            ),
            if (_showGiftAnimation) _buildGiftAnimationOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildGiftAnimationOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Center(
            child: ScaleTransition(
              scale: _giftScaleAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                      boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.5), blurRadius: 40, spreadRadius: 10)],
                    ),
                    child: Image.network(_animatingGiftImage ?? '', width: 200, height: 200),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    'هدية ملكية فاخرة: $_animatingGiftName',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.amber, blurRadius: 10)]),
                  ),
                  const SizedBox(height: 10),
                  const Text('من صديق ملكي مخلص 👑', style: TextStyle(color: Colors.amber, fontSize: 16)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessagesList() {
    return StreamBuilder<List<MessageModel>>(
      stream: _firestoreService.streamMessages(widget.roomId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final messages = snapshot.data!;

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 20),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isMe = message.senderId == FirebaseAuth.instance.currentUser?.uid;

            if (message.giftId != null) {
              return _buildGiftBubble(message, isMe);
            }
            
            return _buildMessageBubble(message, isMe);
          },
        );
      },
    );
  }

  Widget _buildGiftBubble(MessageModel message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isMe 
              ? [Colors.amber.shade700, Colors.amber.shade400] 
              : [Colors.white, Colors.amber.shade50],
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.2), blurRadius: 10, spreadRadius: 2)],
          border: Border.all(color: Colors.amber.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            if (message.giftImage != null)
              Image.network(message.giftImage!, width: 60, height: 60),
            const SizedBox(height: 10),
            Text(
              isMe ? 'أرسلت هدية: ${message.giftName}' : 'أرسل لك هدية: ${message.giftName}',
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              intl.DateFormat('hh:mm a').format(message.timestamp),
              style: TextStyle(color: isMe ? Colors.white70 : Colors.grey, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? Colors.deepPurple : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isMe ? const Radius.circular(20) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(20),
          ),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              intl.DateFormat('hh:mm a').format(message.timestamp),
              style: TextStyle(color: isMe ? Colors.white60 : Colors.grey, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.only(left: 16, right: 16, bottom: MediaQuery.of(context).padding.bottom + 10, top: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: _showGiftPicker,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle),
                  child: const Icon(Icons.card_giftcard, color: Colors.black, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'اكتب رسالتك الملكية...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(color: Colors.deepPurple, shape: BoxShape.circle),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
