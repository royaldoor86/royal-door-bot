import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  video,
  audio,
  gift,
  voiceWhisper,
  location,
  file,
  contact
}

class ChatRoomModel {
  final String id;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastMessageTime;
  final Map<String, int> unreadCounts;
  final Map<String, bool> typingStatus;
  final String? wallpaperUrl;
  final Map<String, dynamic>? lastRead; // {userId: Timestamp}
  final bool isGroup;
  final String? groupName;
  final String? groupImage;
  final List<String>? admins;
  final List<String> pinnedMessages;
  final List<String> pinnedBy;
  final List<String> archivedBy;

  ChatRoomModel({
    required this.id,
    required this.participants,
    this.lastMessage = '',
    required this.lastMessageTime,
    this.unreadCounts = const {},
    this.typingStatus = const {},
    this.wallpaperUrl,
    this.lastRead,
    this.isGroup = false,
    this.groupName,
    this.groupImage,
    this.admins,
    this.pinnedMessages = const [],
    this.pinnedBy = const [],
    this.archivedBy = const [],
  });

  factory ChatRoomModel.fromMap(Map<String, dynamic> data, String documentId) {
    return ChatRoomModel(
      id: documentId,
      participants: List<String>.from(data['participants'] ?? []),
      lastMessage: data['lastMessage'] ?? '',
      lastMessageTime:
          (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCounts: Map<String, int>.from(data['unreadCounts'] ?? {}),
      typingStatus: Map<String, bool>.from(data['typingStatus'] ?? {}),
      wallpaperUrl: data['wallpaperUrl'],
      lastRead: data['lastRead'],
      isGroup: data['isGroup'] ?? false,
      groupName: data['groupName'],
      groupImage: data['groupImage'],
      admins: data['admins'] != null ? List<String>.from(data['admins']) : null,
      pinnedMessages: List<String>.from(data['pinnedMessages'] ?? []),
      pinnedBy: List<String>.from(data['pinnedBy'] ?? []),
      archivedBy: List<String>.from(data['archivedBy'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'participants': participants,
      'lastMessage': lastMessage,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCounts': unreadCounts,
      'typingStatus': typingStatus,
      'wallpaperUrl': wallpaperUrl,
      'lastRead': lastRead,
      'isGroup': isGroup,
      'groupName': groupName,
      'groupImage': groupImage,
      'admins': admins,
      'pinnedMessages': pinnedMessages,
      'pinnedBy': pinnedBy,
      'archivedBy': archivedBy,
    };
  }
}

class MessageModel {
  final String id;
  final String senderId;
  final String text;
  final String? imageUrl;
  final String? videoUrl;
  final String? audioUrl;
  final int? audioDuration;
  final String? fileUrl; // رابط الملف (PDF, Zip, etc)
  final String? giftId;
  final String? giftName;
  final String? giftImage;
  final int? giftPrice;
  final String? giftType;
  final DateTime timestamp;
  final bool isRead;
  final bool isDeleted;
  final bool isPinned;
  final MessageType type;
  final String? replyToId;
  final String? replyToText;
  final String? forwardedFrom;
  final Map<String, String>? reactions;
  final DateTime? expiresAt;
  final DateTime? editedAt;
  final DateTime? readAt;
  final DateTime? deliveredAt;
  final Map<String, double>? location;
  final Map<String, dynamic>? contactData;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.text,
    this.imageUrl,
    this.videoUrl,
    this.audioUrl,
    this.audioDuration,
    this.fileUrl,
    this.giftId,
    this.giftName,
    this.giftImage,
    this.giftPrice,
    this.giftType,
    required this.timestamp,
    this.isRead = false,
    this.isDeleted = false,
    this.isPinned = false,
    this.type = MessageType.text,
    this.replyToId,
    this.replyToText,
    this.forwardedFrom,
    this.reactions,
    this.expiresAt,
    this.editedAt,
    this.readAt,
    this.deliveredAt,
    this.location,
    this.contactData,
  });

  factory MessageModel.fromMap(Map<String, dynamic> data, String documentId) {
    return MessageModel(
      id: documentId,
      senderId: data['senderId'] ?? '',
      text: data['text'] ?? '',
      imageUrl: data['imageUrl'],
      videoUrl: data['videoUrl'],
      audioUrl: data['audioUrl'],
      audioDuration: data['audioDuration'],
      fileUrl: data['fileUrl'],
      giftId: data['giftId'],
      giftName: data['giftName'],
      giftImage: data['giftImage'],
      giftPrice: data['giftPrice'],
      giftType: data['giftType'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      isDeleted: data['isDeleted'] ?? false,
      isPinned: data['isPinned'] ?? false,
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${data['type']}',
        orElse: () => MessageType.text,
      ),
      replyToId: data['replyToId'],
      replyToText: data['replyToText'],
      forwardedFrom: data['forwardedFrom'],
      reactions: data['reactions'] != null
          ? Map<String, String>.from(data['reactions'])
          : null,
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      editedAt: (data['editedAt'] as Timestamp?)?.toDate(),
      readAt: (data['readAt'] as Timestamp?)?.toDate(),
      deliveredAt: (data['deliveredAt'] as Timestamp?)?.toDate(),
      location: data['location'] != null
          ? Map<String, double>.from(data['location'])
          : null,
      contactData: data['contactData'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'text': text,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'audioUrl': audioUrl,
      'audioDuration': audioDuration,
      'fileUrl': fileUrl,
      'giftId': giftId,
      'giftName': giftName,
      'giftImage': giftImage,
      'giftPrice': giftPrice,
      'giftType': giftType,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': isRead,
      'isDeleted': isDeleted,
      'isPinned': isPinned,
      'type': type.toString().split('.').last,
      'replyToId': replyToId,
      'replyToText': replyToText,
      'forwardedFrom': forwardedFrom,
      'reactions': reactions,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'editedAt': editedAt != null ? Timestamp.fromDate(editedAt!) : null,
      'readAt': readAt != null ? Timestamp.fromDate(readAt!) : null,
      'deliveredAt':
          deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'location': location,
      'contactData': contactData,
    };
  }
}
