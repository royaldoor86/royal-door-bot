import 'package:cloud_firestore/cloud_firestore.dart';

class StoryModel {
  final String id;
  final String userId;
  final String userName;
  final String userPic;
  final String? imageUrl;
  final String? videoUrl; // حقل جديد للفيديو
  final DateTime createdAt;
  final List<String> viewers;
  final List<String> likes;
  final int replyCount;

  StoryModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPic,
    this.imageUrl,
    this.videoUrl,
    required this.createdAt,
    this.viewers = const [],
    this.likes = const [],
    this.replyCount = 0,
  });

  factory StoryModel.fromMap(Map<String, dynamic> data, String documentId) {
    return StoryModel(
      id: documentId,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? data['user_name'] ?? 'عضو ملكي',
      userPic: data['userPic'] ?? data['user_pic'] ?? '',
      imageUrl: data['imageUrl'],
      videoUrl: data['videoUrl'], // قراءة رابط الفيديو
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      viewers: List<String>.from(data['viewers'] ?? []),
      likes: List<String>.from(data['likes'] ?? []),
      replyCount: data['replyCount'] ?? data['repliesCount'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPic': userPic,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl, // حفظ رابط الفيديو
      'createdAt': FieldValue.serverTimestamp(),
      'viewers': viewers,
      'likes': likes,
      'replyCount': replyCount,
    };
  }

  StoryModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPic,
    String? imageUrl,
    String? videoUrl,
    DateTime? createdAt,
    List<String>? viewers,
    List<String>? likes,
    int? replyCount,
  }) {
    return StoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPic: userPic ?? this.userPic,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      createdAt: createdAt ?? this.createdAt,
      viewers: viewers ?? List<String>.from(this.viewers),
      likes: likes ?? List<String>.from(this.likes),
      replyCount: replyCount ?? this.replyCount,
    );
  }
}
