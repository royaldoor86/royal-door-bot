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

  StoryModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPic,
    this.imageUrl,
    this.videoUrl,
    required this.createdAt,
    this.viewers = const [],
  });

  factory StoryModel.fromMap(Map<String, dynamic> data, String documentId) {
    return StoryModel(
      id: documentId,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'عضو ملكي',
      userPic: data['userPic'] ?? '',
      imageUrl: data['imageUrl'],
      videoUrl: data['videoUrl'], // قراءة رابط الفيديو
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      viewers: List<String>.from(data['viewers'] ?? []),
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
    };
  }
}
