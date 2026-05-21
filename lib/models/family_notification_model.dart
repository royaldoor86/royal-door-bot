import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyNotificationModel {
  final String id;
  final String familyId;
  final String title;
  final String message;
  final String type; // 'join', 'war', 'task', 'level_up', 'event'
  final Map<String, dynamic>? data;
  final Timestamp createdAt;
  final bool isRead;

  FamilyNotificationModel({
    required this.id,
    required this.familyId,
    required this.title,
    required this.message,
    required this.type,
    this.data,
    required this.createdAt,
    this.isRead = false,
  });

  factory FamilyNotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FamilyNotificationModel(
      id: doc.id,
      familyId: data['familyId'] ?? '',
      title: data['title'] ?? '',
      message: data['message'] ?? '',
      type: data['type'] ?? '',
      data: data['data'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      isRead: data['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'familyId': familyId,
      'title': title,
      'message': message,
      'type': type,
      'data': data,
      'createdAt': createdAt,
      'isRead': isRead,
    };
  }
}