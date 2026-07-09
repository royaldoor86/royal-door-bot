import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String authorPic;
  final String content;
  final String? imageUrl;
  final List<String>? imageUrls; // دعم الصور المتعددة
  final String? videoUrl;
  final String? audioUrl;
  final int? audioDuration;
  final DateTime createdAt;
  final List<String> likes;
  final int commentCount;
  final bool isVip;
  final bool isPinned; // دعم المنشور المثبت

  PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorPic,
    required this.content,
    this.imageUrl,
    this.imageUrls,
    this.videoUrl,
    this.audioUrl,
    this.audioDuration,
    required this.createdAt,
    this.likes = const [],
    this.commentCount = 0,
    this.isVip = false,
    this.isPinned = false,
  });

  factory PostModel.fromMap(Map<String, dynamic> data, String documentId) {
    return PostModel(
      id: documentId,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'مستخدم ملكي',
      authorPic: data['authorPic'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      imageUrls: data['imageUrls'] != null ? List<String>.from(data['imageUrls']) : null,
      videoUrl: data['videoUrl'],
      audioUrl: data['audioUrl'],
      audioDuration: data['audioDuration'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      likes: List<String>.from(data['likes'] ?? []),
      commentCount: data['commentCount'] ?? 0,
      isVip: data['isVip'] ?? false,
      isPinned: data['isPinned'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'authorId': authorId,
      'authorName': authorName,
      'authorPic': authorPic,
      'content': content,
      'imageUrl': imageUrl,
      'imageUrls': imageUrls,
      'videoUrl': videoUrl,
      'audioUrl': audioUrl,
      'audioDuration': audioDuration,
      'createdAt': FieldValue.serverTimestamp(),
      'likes': likes,
      'commentCount': commentCount,
      'isVip': isVip,
      'isPinned': isPinned,
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
  final String? parentId; // معرف التعليق الأب (في حال كان رداً)
  final String? replyToName; // اسم الشخص الذي تم الرد عليه
  final List<String> likes;

  CommentModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPic,
    required this.text,
    required this.createdAt,
    this.parentId,
    this.replyToName,
    this.likes = const [],
  });

  factory CommentModel.fromMap(Map<String, dynamic> data, String documentId) {
    return CommentModel(
      id: documentId,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'عضو رويال',
      userPic: data['userPic'] ?? '',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      parentId: data['parentId'],
      replyToName: data['replyToName'],
      likes: List<String>.from(data['likes'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userPic': userPic,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'parentId': parentId,
      'replyToName': replyToName,
      'likes': likes,
    };
  }
}
