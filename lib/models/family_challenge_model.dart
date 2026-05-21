import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyChallengeModel {
  final String id;
  final String familyId;
  final String title;
  final String description;
  final String type; // 'contribution', 'activity', 'custom'
  final int targetValue;
  final String metric; // 'gems', 'stars', 'activity_minutes'
  final Timestamp startDate;
  final Timestamp endDate;
  final String? createdBy;
  final String? winnerId;
  final String? winnerName;
  final int rewardGems;
  final int rewardStars;
  final String status; // 'active', 'completed', 'cancelled'

  FamilyChallengeModel({
    required this.id,
    required this.familyId,
    required this.title,
    required this.description,
    required this.type,
    required this.targetValue,
    required this.metric,
    required this.startDate,
    required this.endDate,
    this.createdBy,
    this.winnerId,
    this.winnerName,
    this.rewardGems = 0,
    this.rewardStars = 0,
    this.status = 'active',
  });

  factory FamilyChallengeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FamilyChallengeModel(
      id: doc.id,
      familyId: data['familyId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? 'custom',
      targetValue: data['targetValue'] ?? 0,
      metric: data['metric'] ?? 'gems',
      startDate: data['startDate'] ?? Timestamp.now(),
      endDate: data['endDate'] ?? Timestamp.now(),
      createdBy: data['createdBy'],
      winnerId: data['winnerId'],
      winnerName: data['winnerName'],
      rewardGems: data['rewardGems'] ?? 0,
      rewardStars: data['rewardStars'] ?? 0,
      status: data['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'familyId': familyId,
      'title': title,
      'description': description,
      'type': type,
      'targetValue': targetValue,
      'metric': metric,
      'startDate': startDate,
      'endDate': endDate,
      'createdBy': createdBy,
      'winnerId': winnerId,
      'winnerName': winnerName,
      'rewardGems': rewardGems,
      'rewardStars': rewardStars,
      'status': status,
    };
  }
}
