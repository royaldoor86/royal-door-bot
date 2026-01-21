import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String authorPic;
  final String content;
  final String? imageUrl;
  final String? videoUrl; // إضافة حقل الفيديو هنا
  final String? audioUrl;
  final int? audioDuration;
  final DateTime createdAt;
  final List<String> likes;
  final int commentCount;
  final bool isVip;

  PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorPic,
    required this.content,
    this.imageUrl,
    this.videoUrl, // تحديث المشيد
    this.audioUrl,
    this.audioDuration,
    required this.createdAt,
    this.likes = const [],
    this.commentCount = 0,
    this.isVip = false,
  });

  factory PostModel.fromMap(Map<String, dynamic> data, String documentId) {
    return PostModel(
      id: documentId,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'مستخدم ملكي',
      authorPic: data['authorPic'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      videoUrl: data['videoUrl'], // قراءة رابط الفيديو
      audioUrl: data['audioUrl'],
      audioDuration: data['audioDuration'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes: List<String>.from(data['likes'] ?? []),
      commentCount: data['commentCount'] ?? 0,
      isVip: data['isVip'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorPic': authorPic,
      'content': content,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl, // حفظ رابط الفيديو
      'audioUrl': audioUrl,
      'audioDuration': audioDuration,
      'createdAt': FieldValue.serverTimestamp(),
      'likes': likes,
      'commentCount': commentCount,
      'isVip': isVip,
    };
  }
}

class CommentModel {
  final String id;
  final String userId;
  final String userName;
  final String userPic;
  final String text;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPic,
    required this.text,
    required this.createdAt,
  });

  factory CommentModel.fromMap(Map<String, dynamic> data, String documentId) {
    return CommentModel(
      id: documentId,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'عضو رويال',
      userPic: data['userPic'] ?? '',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPic': userPic,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}
