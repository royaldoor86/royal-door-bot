import 'package:cloud_firestore/cloud_firestore.dart';

class EnhancedChatMessageModel {
  final String id;
  final String familyId;
  final String senderId;
  final String senderName;
  final String message;
  final Timestamp timestamp;
  final List<String> reactions; // ردود الفعل (emojis)
  final bool isDisappearing; // هل الرسالة مؤقتة؟
  final Timestamp? disappearAt; // متى تختفي الرسالة
  final bool isDeleted;
  final Map<String, dynamic> metadata; // بيانات إضافية

  EnhancedChatMessageModel({
    required this.id,
    required this.familyId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    this.reactions = const [],
    this.isDisappearing = false,
    this.disappearAt,
    this.isDeleted = false,
    required this.metadata,
  });

  factory EnhancedChatMessageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EnhancedChatMessageModel(
      id: doc.id,
      familyId: data['familyId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      message: data['message'] ?? '',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      reactions: List<String>.from(data['reactions'] ?? []),
      isDisappearing: data['isDisappearing'] ?? false,
      disappearAt: data['disappearAt'],
      isDeleted: data['isDeleted'] ?? false,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'familyId': familyId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': timestamp,
      'reactions': reactions,
      'isDisappearing': isDisappearing,
      'disappearAt': disappearAt,
      'isDeleted': isDeleted,
      'metadata': metadata,
    };
  }

  // هل الرسالة منتهية الصلاحية؟
  bool get isExpired {
    if (!isDisappearing || disappearAt == null) return false;
    return DateTime.now().isAfter(disappearAt!.toDate());
  }

  // إضافة رد فعل
  EnhancedChatMessageModel addReaction(String emoji) {
    final newReactions = List<String>.from(reactions);
    if (!newReactions.contains(emoji)) {
      newReactions.add(emoji);
    }
    return EnhancedChatMessageModel(
      id: id,
      familyId: familyId,
      senderId: senderId,
      senderName: senderName,
      message: message,
      timestamp: timestamp,
      reactions: newReactions,
      isDisappearing: isDisappearing,
      disappearAt: disappearAt,
      isDeleted: isDeleted,
      metadata: metadata,
    );
  }

  // إزالة رد فعل
  EnhancedChatMessageModel removeReaction(String emoji) {
    final newReactions = List<String>.from(reactions);
    newReactions.remove(emoji);
    return EnhancedChatMessageModel(
      id: id,
      familyId: familyId,
      senderId: senderId,
      senderName: senderName,
      message: message,
      timestamp: timestamp,
      reactions: newReactions,
      isDisappearing: isDisappearing,
      disappearAt: disappearAt,
      isDeleted: isDeleted,
      metadata: metadata,
    );
  }
}

class VoiceRoomModel {
  final String id;
  final String familyId;
  final String name;
  final String description;
  final String createdBy;
  final List<String> participants;
  final String? activeSpeaker;
  final Timestamp createdAt;
  final Timestamp? endedAt;
  final bool isActive;
  final int maxParticipants;
  final Map<String, dynamic> settings;

  VoiceRoomModel({
    required this.id,
    required this.familyId,
    required this.name,
    required this.description,
    required this.createdBy,
    required this.participants,
    this.activeSpeaker,
    required this.createdAt,
    this.endedAt,
    required this.isActive,
    required this.maxParticipants,
    required this.settings,
  });

  factory VoiceRoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VoiceRoomModel(
      id: doc.id,
      familyId: data['familyId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      createdBy: data['createdBy'] ?? '',
      participants: List<String>.from(data['participants'] ?? []),
      activeSpeaker: data['activeSpeaker'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      endedAt: data['endedAt'],
      isActive: data['isActive'] ?? true,
      maxParticipants: data['maxParticipants'] ?? 10,
      settings: Map<String, dynamic>.from(data['settings'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'familyId': familyId,
      'name': name,
      'description': description,
      'createdBy': createdBy,
      'participants': participants,
      'activeSpeaker': activeSpeaker,
      'createdAt': createdAt,
      'endedAt': endedAt,
      'isActive': isActive,
      'maxParticipants': maxParticipants,
      'settings': settings,
    };
  }

  // عدد المشاركين الحالي
  int get currentParticipants => participants.length;

  // هل الغرفة ممتلئة؟
  bool get isFull => currentParticipants >= maxParticipants;

  // هل يمكن الانضمام؟
  bool get canJoin => isActive && !isFull;
}
