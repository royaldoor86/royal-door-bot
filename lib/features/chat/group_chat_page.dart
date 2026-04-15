import 'dart:ui';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/firestore_service.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart';
import '../../app_theme.dart';

class GroupChatPage extends StatefulWidget {
  final ChatRoomModel room;

  const GroupChatPage({super.key, required this.room});

  @override
  State<GroupChatPage> createState() => _GroupChatPageState();
}

class _GroupChatPageState extends State<GroupChatPage> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final ScrollController _scrollController = ScrollController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ImagePicker _picker = ImagePicker();
  final AudioRecorder _audioRecorder = AudioRecorder();
  
  StreamSubscription<List<MessageModel>>? _messageSubscription;
  int _messageLimit = 20;
  MessageModel? _replyingTo;
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
  bool _isRecording = false;
  String _searchQuery = "";
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _setupMessageSubscription();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        setState(() => _messageLimit += 20);
        _setupMessageSubscription();
      }
    });
  }

  void _setupMessageSubscription() {
    _messageSubscription?.cancel();
    _messageSubscription = _firestoreService.streamMessages(widget.room.id, limit: _messageLimit).listen((messages) {
      if (messages.isNotEmpty) {
        final currentUid = FirebaseAuth.instance.currentUser?.uid;
        if (currentUid != null) {
          final unreadIds = messages
              .where((m) => !m.isRead && m.senderId != currentUid)
              .map((m) => m.id)
              .toList();
          if (unreadIds.isNotEmpty) {
            _firestoreService.markMessagesAsRead(widget.room.id, unreadIds, readerId: currentUid);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      final directory = await getApplicationDocumentsDirectory();
      String recordingPath = '${directory.path}/rec_group_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioRecorder.start(const RecordConfig(), path: recordingPath);
      setState(() => _isRecording = true);
    }
  }

  Future<void> _stopAndSendRecording() async {
    final path = await _audioRecorder.stop();
    setState(() => _isRecording = false);
    if (path != null) {
      File file = File(path);
      String fileName = 'group_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      Reference storageRef = FirebaseStorage.instance.ref().child('chat_media/${widget.room.id}/$fileName');
      await storageRef.putFile(file);
      String downloadUrl = await storageRef.getDownloadURL();

      final message = MessageModel(
        id: '',
        senderId: _currentUserId,
        text: 'رسالة صوتية 🎤',
        audioUrl: downloadUrl,
        timestamp: DateTime.now(),
        type: MessageType.audio,
      );
      await _firestoreService.sendMessage(widget.room.id, message);
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;
    final message = MessageModel(
      id: '',
      senderId: _currentUserId,
      text: _messageController.text.trim(),
      timestamp: DateTime.now(),
      type: MessageType.text,
      replyToId: _replyingTo?.id,
      replyToText: _replyingTo?.text,
    );
    await _firestoreService.sendMessage(widget.room.id, message);
    _messageController.clear();
    setState(() => _replyingTo = null);
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  void _showGroupInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundBlack,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 20),
          CircleAvatar(
            radius: 40,
            backgroundImage: (widget.room.groupImage != null && widget.room.groupImage!.isNotEmpty) ? NetworkImage(widget.room.groupImage!) : null,
            child: (widget.room.groupImage == null || widget.room.groupImage!.isEmpty) ? const Icon(Icons.groups, size: 40) : null,
          ),
          const SizedBox(height: 10),
          Text(widget.room.groupName ?? 'مجموعة', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(color: Colors.white10),
          ListTile(
            leading: const Icon(Icons.person_add, color: AppTheme.royalGold),
            title: const Text('إضافة أعضاء', style: TextStyle(color: Colors.white)),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.red),
            title: const Text('مغادرة المجموعة', style: TextStyle(color: Colors.red)),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundBlack,
        appBar: AppBar(
          backgroundColor: Colors.white.withOpacity(0.05),
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => Navigator.pop(context)),
          title: InkWell(
            onTap: _showGroupInfo,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: (widget.room.groupImage != null && widget.room.groupImage!.isNotEmpty) ? NetworkImage(widget.room.groupImage!) : null,
                  child: (widget.room.groupImage == null || widget.room.groupImage!.isEmpty) ? const Icon(Icons.groups) : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.room.groupName ?? 'مجموعة', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('${widget.room.participants.length} عضو', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            IconButton(icon: const Icon(Icons.search, color: Colors.white), onPressed: () => setState(() => _isSearching = !_isSearching)),
            IconButton(icon: const Icon(Icons.more_vert, color: Colors.white), onPressed: _showGroupInfo),
          ],
        ),
        body: AppTheme.background(
          child: Column(
            children: [
              if (_isSearching) _buildSearchField(),
              Expanded(child: _buildMessagesList()),
              if (_replyingTo != null) _buildReplyPreview(),
              _buildMessageInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white.withOpacity(0.05),
      child: TextField(
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(hintText: 'بحث عن رسالة...', hintStyle: TextStyle(color: Colors.white24), border: InputBorder.none),
        onChanged: (val) => setState(() => _searchQuery = val),
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.white10,
      child: Row(
        children: [
          const Icon(Icons.reply, size: 16, color: AppTheme.royalGold),
          const SizedBox(width: 8),
          Expanded(child: Text(_replyingTo!.text, maxLines: 1, style: const TextStyle(color: Colors.white70, fontSize: 12))),
          IconButton(icon: const Icon(Icons.close, size: 16, color: Colors.white), onPressed: () => setState(() => _replyingTo = null)),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return StreamBuilder<List<MessageModel>>(
      stream: _firestoreService.streamMessages(widget.room.id, limit: _messageLimit),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppTheme.royalGold));
        var messages = snapshot.data!;
        if (_searchQuery.isNotEmpty) {
          messages = messages.where((m) => m.text.contains(_searchQuery)).toList();
        }

        return ListView.builder(
          controller: _scrollController,
          reverse: true,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isMe = message.senderId == _currentUserId;
            return _buildMessageTile(message, isMe);
          },
        );
      },
    );
  }

  Widget _buildMessageTile(MessageModel message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe) _buildSenderName(message.senderId),
          GestureDetector(
            onLongPress: () => _showMessageOptions(message),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe ? AppTheme.royalGold.withOpacity(0.8) : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(15),
                  topRight: const Radius.circular(15),
                  bottomLeft: Radius.circular(isMe ? 15 : 0),
                  bottomRight: Radius.circular(isMe ? 0 : 15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.replyToText != null) 
                    Container(
                      padding: const EdgeInsets.all(4),
                      margin: const EdgeInsets.only(bottom: 5),
                      decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(5)),
                      child: Text(message.replyToText!, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                    ),
                  if (message.type == MessageType.image) 
                    CachedNetworkImage(imageUrl: message.imageUrl!, width: 200, placeholder: (context, url) => const CircularProgressIndicator())
                  else if (message.type == MessageType.audio)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.play_arrow, color: Colors.white), onPressed: () => _audioPlayer.play(UrlSource(message.audioUrl!))),
                        const Text('رسالة صوتية', style: TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    )
                  else
                    Text(message.text, style: TextStyle(color: isMe ? Colors.black : Colors.white)),
                  const SizedBox(height: 4),
                  Text(intl.DateFormat('hh:mm a').format(message.timestamp), style: TextStyle(color: isMe ? Colors.black38 : Colors.white24, fontSize: 9)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSenderName(String senderId) {
    return StreamBuilder<UserModel>(
      stream: _firestoreService.streamUserData(senderId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 2),
          child: Text(snapshot.data!.name, style: const TextStyle(color: AppTheme.royalGold, fontSize: 10, fontWeight: FontWeight.bold)),
        );
      },
    );
  }

  void _showMessageOptions(MessageModel message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.backgroundBlack,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(leading: const Icon(Icons.reply, color: Colors.white), title: const Text('رد', style: TextStyle(color: Colors.white)), onTap: () { Navigator.pop(context); setState(() => _replyingTo = message); }),
          if (message.senderId == _currentUserId)
            ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: const Text('حذف', style: TextStyle(color: Colors.red)), onTap: () { _firestoreService.deleteMessage(widget.room.id, message.id); Navigator.pop(context); }),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), border: const Border(top: BorderSide(color: Colors.white10))),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(icon: const Icon(Icons.image, color: Colors.white54), onPressed: () {}),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(25)),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'اكتب رسالة...', hintStyle: TextStyle(color: Colors.white24), border: InputBorder.none),
                ),
              ),
            ),
            GestureDetector(
              onLongPress: _startRecording,
              onLongPressUp: _stopAndSendRecording,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(_isRecording ? Icons.mic : Icons.mic_none, color: _isRecording ? Colors.red : AppTheme.royalGold),
              ),
            ),
            IconButton(icon: const Icon(Icons.send, color: AppTheme.royalGold), onPressed: _sendMessage),
          ],
        ),
      ),
    );
  }
}
