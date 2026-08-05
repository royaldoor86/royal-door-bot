import 'package:cloud_firestore/cloud_firestore.dart';
import 'privacy_model.dart';

class StoryModel {
  final String id;
  final String userId;
  final String userName;
  final String userPic;
  final String? imageUrl;
  final String? videoUrl; // حقل جديد للفيديو
  final DateTime createdAt;
  final DateTime? expiresAt; // تاريخ انتهاء القصة
  final List<String> viewers;
  final List<String> likes;
  final int replyCount;
  final String? storyText; // نص القصة النصية
  final String? storyBackgroundColor; // لون خلفية القصة النصية
  final String? storyFilter; // فلتر الصورة
  final List<String> archivedBy; // المستخدمون الذين حفظوا القصة
  final String? postReference; // مرجع المنشور المشترك
  final String? postContent; // محتوى المنشور المشترك
  final String? postAuthorName; // اسم كاتب المنشور المشترك
  final PrivacyLevel privacy; // إعدادات الخصوصية

  StoryModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPic,
    this.imageUrl,
    this.videoUrl,
    required this.createdAt,
    this.expiresAt,
    this.viewers = const [],
    this.likes = const [],
    this.replyCount = 0,
    this.storyText,
    this.storyBackgroundColor,
    this.storyFilter,
    this.archivedBy = const [],
    this.postReference,
    this.postContent,
    this.postAuthorName,
    this.privacy = PrivacyLevel.public,
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
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      viewers: List<String>.from(data['viewers'] ?? []),
      likes: List<String>.from(data['likes'] ?? []),
      replyCount: data['replyCount'] ?? data['repliesCount'] ?? 0,
      storyText: data['storyText'],
      storyBackgroundColor: data['storyBackgroundColor'],
      storyFilter: data['storyFilter'],
      archivedBy: List<String>.from(data['archivedBy'] ?? []),
      postReference: data['postReference'],
      postContent: data['postContent'],
      postAuthorName: data['postAuthorName'],
      privacy: data['privacy'] != null
          ? PrivacyLevelExtension.fromString(data['privacy'] as String)
          : PrivacyLevel.public,
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
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'viewers': viewers,
      'likes': likes,
      'replyCount': replyCount,
      'storyText': storyText,
      'storyBackgroundColor': storyBackgroundColor,
      'storyFilter': storyFilter,
      'archivedBy': archivedBy,
      'postReference': postReference,
      'postContent': postContent,
      'postAuthorName': postAuthorName,
      'privacy': privacy.value,
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
    DateTime? expiresAt,
    List<String>? viewers,
    List<String>? likes,
    int? replyCount,
    String? storyText,
    String? storyBackgroundColor,
    String? storyFilter,
    List<String>? archivedBy,
    String? postReference,
    String? postContent,
    String? postAuthorName,
    PrivacyLevel? privacy,
  }) {
    return StoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPic: userPic ?? this.userPic,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      viewers: viewers ?? List<String>.from(this.viewers),
      likes: likes ?? List<String>.from(this.likes),
      replyCount: replyCount ?? this.replyCount,
      storyText: storyText ?? this.storyText,
      storyBackgroundColor: storyBackgroundColor ?? this.storyBackgroundColor,
      storyFilter: storyFilter ?? this.storyFilter,
      archivedBy: archivedBy ?? List<String>.from(this.archivedBy),
      postReference: postReference ?? this.postReference,
      postContent: postContent ?? this.postContent,
      postAuthorName: postAuthorName ?? this.postAuthorName,
      privacy: privacy ?? this.privacy,
    );
  }
}
