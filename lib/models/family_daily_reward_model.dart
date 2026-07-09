import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyDailyRewardModel {
  final String id;
  final String familyId;
  final String userId;
  final String userName;
  final Timestamp date;
  final int gemsReward;
  final int coinsReward;
  final bool isLoginReward;
  final bool isActivityReward;
  final int activityMinutes;
  final Timestamp? claimedAt;

  FamilyDailyRewardModel({
    required this.id,
    required this.familyId,
    required this.userId,
    required this.userName,
    required this.date,
    this.gemsReward = 0,
    this.coinsReward = 0,
    this.isLoginReward = false,
    this.isActivityReward = false,
    this.activityMinutes = 0,
    this.claimedAt,
  });

  factory FamilyDailyRewardModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FamilyDailyRewardModel(
      id: doc.id,
      familyId: data['familyId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      date: data['date'] ?? Timestamp.now(),
      gemsReward: data['gemsReward'] ?? 0,
      coinsReward: data['coinsReward'] ?? 0,
      isLoginReward: data['isLoginReward'] ?? false,
      isActivityReward: data['isActivityReward'] ?? false,
      activityMinutes: data['activityMinutes'] ?? 0,
      claimedAt: data['claimedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'familyId': familyId,
      'userId': userId,
      'userName': userName,
      'date': date,
      'gemsReward': gemsReward,
      'coinsReward': coinsReward,
      'isLoginReward': isLoginReward,
      'isActivityReward': isActivityReward,
      'activityMinutes': activityMinutes,
      'claimedAt': claimedAt ?? FieldValue.serverTimestamp(),
    };
  }
}
