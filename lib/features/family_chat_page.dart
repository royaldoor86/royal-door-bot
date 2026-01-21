import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../models/chat_model.dart';

class FamilyChatPage extends StatefulWidget {
  final String familyId;
  const FamilyChatPage({super.key, required this.familyId});

  @override
  State<FamilyChatPage> createState() => _FamilyChatPageState();
}

class _FamilyChatPageState extends State<FamilyChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();
  bool _showEmojiPicker = false;
  
  MessageModel? _replyTo;

  final List<String> _emojis = [
    '❤️','🧡','💛','💚','💙','💜','🖤','🤍','🤎','💔','❤️‍🔥','✨','⭐','🌟','🔥','💥',
    '🌹','🌸','💐','🌻','🌺','🌷','🥀','🍃','🍀','🌿',
    '😊','🥰','😍','😘','🤴','👸','👑','💎','👑','✨',
    '😂','🤣','😎','😇','🦁','🦅','🏛️','🛡️','⚔️','📜','💰','💸','🔥','👑'
  ];

  @override
  void dispose() {
    _deleteMyMessagesOnExit();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _deleteMyMessagesOnExit() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    try {
      final myMsgs = await _db.collection('families').doc(widget.familyId).collection('messages').where('senderId', isEqualTo: currentUser.uid).get();
      if (myMsgs.docs.isNotEmpty) {
        final batch = _db.batch();
        for (var doc in myMsgs.docs) { batch.delete(doc.reference); }
        await batch.commit();
      }
    } catch (e) {}
  }

  void _sendMessage(UserModel user) async {
    if (_messageController.text.trim().isEmpty) return;
    final text = _messageController.text.trim();
    _messageController.clear();
    await _db.collection('families').doc(widget.familyId).collection('messages').add({
      'senderId': user.uid,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'senderName': user.name,
      'senderPic': user.profilePic,
      'replyTo': _replyTo != null ? {'text': _replyTo!.text, 'sender': 'عضو'} : null,
    });
    setState(() { _replyTo = null; _showEmojiPicker = false; });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAuth = FirebaseAuth.instance.currentUser;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: StreamBuilder<UserModel>(
        stream: userAuth != null ? _firestoreService.streamUserData(userAuth.uid) : null,
        builder: (context, userSnap) {
          if (!userSnap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
          final user = userSnap.data!;
          return Scaffold(
            backgroundColor: const Color(0xFF1A050E),
            appBar: _buildAppBar(),
            body: Column(
              children: [
                Expanded(child: _buildMessagesList(user.uid)),
                if (_replyTo != null) _buildReplyPreview(),
                _buildMessageInput(user),
                if (_showEmojiPicker) _buildEmojiPicker(),
              ],
            ),
          );
        }
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF3D0B16),
      elevation: 0,
      title: StreamBuilder<DocumentSnapshot>(
        stream: _db.collection('families').doc(widget.familyId).snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) return const Text('دردشة العائلة');
          final data = snap.data!.data() as Map<String, dynamic>?;
          return Column(
            children: [
              Text(data?['name'] ?? 'دردشة العائلة', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const Text('الرسائل تُحذف تلقائياً عند الخروج 🛡️', style: TextStyle(color: Colors.amber, fontSize: 9)),
            ],
          );
        },
      ),
      centerTitle: true,
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  Widget _buildMessagesList(String myUid) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('families').doc(widget.familyId).collection('messages').orderBy('timestamp', descending: false).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(15),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final msg = MessageModel.fromMap(data, docs[index].id);
            bool isMe = msg.senderId == myUid;

            // --- تفعيل ميزة اسحب للرد ---
            return Dismissible(
              key: Key(msg.id),
              direction: DismissDirection.startToEnd,
              confirmDismiss: (dir) async {
                setState(() => _replyTo = msg);
                return false; // يمنع حذف الرسالة من الواجهة، فقط يفعّل الرد
              },
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.reply, color: Colors.amber),
              ),
              child: _buildMessageBubble(msg, data, isMe),
            );
          },
        );
      },
    );
  }

  Widget _buildMessageBubble(MessageModel msg, Map<String, dynamic> data, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.start : MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe) CircleAvatar(radius: 15, backgroundImage: (data['senderPic'] != null && data['senderPic'] != '') ? NetworkImage(data['senderPic']) : null, child: (data['senderPic'] == null || data['senderPic'] == '') ? const Icon(Icons.person, size: 15) : null),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe) Text(data['senderName'] ?? '', style: const TextStyle(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.amber.withOpacity(0.1) : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isMe ? Colors.amber.withOpacity(0.3) : Colors.white.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // عرض الرد إذا وجد
                        if (data['replyTo'] != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
                            child: Text(data['replyTo']['text'], style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.white54)),
                          ),
                        Text(msg.text, style: TextStyle(color: isMe ? Colors.amber : Colors.white, fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.black26,
      child: Row(
        children: [
          const Icon(Icons.reply, color: Colors.amber, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(_replyTo!.text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.white54))),
          IconButton(icon: const Icon(Icons.close, size: 18, color: Colors.white), onPressed: () => setState(() => _replyTo = null)),
        ],
      ),
    );
  }

  Widget _buildMessageInput(UserModel user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(color: Color(0xFF3D0B16), borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.emoji_emotions_outlined, color: _showEmojiPicker ? Colors.amber : Colors.white54),
              onPressed: () => setState(() => _showEmojiPicker = !_showEmojiPicker),
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                maxLines: null,
                style: const TextStyle(color: Colors.white),
                onTap: () => setState(() => _showEmojiPicker = false),
                decoration: const InputDecoration(hintText: 'اكتب رسالة للعائلة...', hintStyle: TextStyle(color: Colors.white24), border: InputBorder.none),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.amber),
              onPressed: () => _sendMessage(user),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return SafeArea(
      top: false,
      child: Container(
        height: 200,
        color: const Color(0xFF1A050E),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8, mainAxisSpacing: 10, crossAxisSpacing: 10),
          itemCount: _emojis.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                _messageController.text += _emojis[index];
                _messageController.selection = TextSelection.fromPosition(TextPosition(offset: _messageController.text.length));
              },
              child: Center(child: Text(_emojis[index], style: const TextStyle(fontSize: 24))),
            );
          },
        ),
      ),
    );
  }
}
