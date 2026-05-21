import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyHistoryModel {
  final String id;
  final String familyId;
  final String type; // 'member_join', 'member_leave', 'level_up', 'war_start', 'war_end', 'alliance_formed', 'alliance_dissolved', 'badge_earned', 'event_created'
  final String title;
  final String description;
  final Map<String, dynamic>? data;
  final String? userId;
  final String? userName;
  final Timestamp? createdAt;

  FamilyHistoryModel({
    required this.id,
    required this.familyId,
    required this.type,
    required this.title,
    required this.description,
    this.data,
    this.userId,
    this.userName,
    this.createdAt,
  });

  factory FamilyHistoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FamilyHistoryModel(
      id: doc.id,
      familyId: data['familyId'] ?? '',
      type: data['type'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      data: data['data'],
      userId: data['userId'],
      userName: data['userName'],
      createdAt: data['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'familyId': familyId,
      'type': type,
      'title': title,
      'description': description,
      'data': data,
      'userId': userId,
      'userName': userName,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}
