import 'package:cloud_firestore/cloud_firestore.dart';

class ChatRoomModel {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final Map<String, int> unreadCounts;

  ChatRoomModel({
    required this.id,
    required this.participants,
    this.lastMessage = '',
    required this.lastMessageTime,
    this.unreadCounts = const {},
  });

  factory ChatRoomModel.fromMap(Map<String, dynamic> data, String documentId) {
    return ChatRoomModel(
      id: documentId,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime: (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCounts: Map<String, int>.from(data['unreadCounts'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCounts': unreadCounts,
    };
  }
}

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final String? imageUrl;
  final String? audioUrl;
  final String? giftId;      // جديد: معرف الهدية
  final String? giftName;    // جديد: اسم الهدية
  final String? giftImage;   // جديد: صورة الهدية
  final int? giftPrice;      // جديد: سعر الهدية
  final DateTime timestamp;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    this.imageUrl,
    this.audioUrl,
    this.giftId,
    this.giftName,
    this.giftImage,
    this.giftPrice,
    required this.timestamp,
    this.isRead = false,
  });

  factory MessageModel.fromMap(Map<String, dynamic> data, String documentId) {
    return MessageModel(
      id: documentId,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      imageUrl: data['imageUrl'],
      audioUrl: data['audioUrl'],
      giftId: data['giftId'],
      giftName: data['giftName'],
      giftImage: data['giftImage'],
      giftPrice: data['giftPrice'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'giftId': giftId,
      'giftName': giftName,
      'giftImage': giftImage,
      'giftPrice': giftPrice,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': isRead,
    };
  }
}
