import 'package:cloud_firestore/cloud_firestore.dart';

class AllianceWarModel {
  final String id;
  final String allianceId1;
  final String allianceName1;
  final String allianceId2;
  final String allianceName2;
  final String warType; // 'territory', 'resource', 'dominance'
  final String status; // 'preparing', 'active', 'ended'
  final Timestamp createdAt;
  final Timestamp? startedAt;
  final Timestamp? endedAt;
  final Timestamp endTime;
  final int alliance1Points;
  final int alliance2Points;
  final int targetPoints;
  final double progress;
  final String? winnerAllianceId;
  final List<String> participatingFamilies1;
  final List<String> participatingFamilies2;
  final Map<String, dynamic> rewards;

  AllianceWarModel({
    required this.id,
    required this.allianceId1,
    required this.allianceName1,
    required this.allianceId2,
    required this.allianceName2,
    required this.warType,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
    required this.endTime,
    required this.alliance1Points,
    required this.alliance2Points,
    required this.targetPoints,
    required this.progress,
    this.winnerAllianceId,
    required this.participatingFamilies1,
    required this.participatingFamilies2,
    required this.rewards,
  });

  factory AllianceWarModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AllianceWarModel(
      id: doc.id,
      allianceId1: data['allianceId1'] ?? '',
      allianceName1: data['allianceName1'] ?? '',
      allianceId2: data['allianceId2'] ?? '',
      allianceName2: data['allianceName2'] ?? '',
      warType: data['warType'] ?? 'dominance',
      status: data['status'] ?? 'preparing',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      startedAt: data['startedAt'],
      endedAt: data['endedAt'],
      endTime: data['endTime'] ?? Timestamp.now(),
      alliance1Points: data['alliance1Points'] ?? 0,
      alliance2Points: data['alliance2Points'] ?? 0,
      targetPoints: data['targetPoints'] ?? 1000,
      progress: (data['progress'] ?? 0.0).toDouble(),
      winnerAllianceId: data['winnerAllianceId'],
      participatingFamilies1: List<String>.from(data['participatingFamilies1'] ?? []),
      participatingFamilies2: List<String>.from(data['participatingFamilies2'] ?? []),
      rewards: Map<String, dynamic>.from(data['rewards'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'allianceId1': allianceId1,
      'allianceName1': allianceName1,
      'allianceId2': allianceId2,
      'allianceName2': allianceName2,
      'warType': warType,
      'status': status,
      'createdAt': createdAt,
      'startedAt': startedAt,
      'endedAt': endedAt,
      'endTime': endTime,
      'alliance1Points': alliance1Points,
      'alliance2Points': alliance2Points,
      'targetPoints': targetPoints,
      'progress': progress,
      'winnerAllianceId': winnerAllianceId,
      'participatingFamilies1': participatingFamilies1,
      'participatingFamilies2': participatingFamilies2,
      'rewards': rewards,
    };
  }

  // المكافآت الافتراضية لكل نوع حرب
  static Map<String, dynamic> getDefaultRewards(String warType) {
    switch (warType) {
      case 'territory':
        return {
          'winnerGems': 5000,
          'winnerStars': 10000,
          'loserGems': 1000,
          'loserStars': 2000,
          'territoryBonus': true,
        };
      case 'resource':
        return {
          'winnerGems': 3000,
          'winnerStars': 5000,
          'loserGems': 500,
          'loserStars': 1000,
          'resourceBonus': true,
        };
      case 'dominance':
      default:
        return {
          'winnerGems': 10000,
          'winnerStars': 20000,
          'loserGems': 2000,
          'loserStars': 4000,
          'dominanceBonus': true,
        };
    }
  }

  // حساب التقدم
  static double calculateProgress(int points, int target) {
    if (target <= 0) return 0.0;
    return (points / target).clamp(0.0, 1.0);
  }

  // الحصول على اسم نوع الحرب بالعربية
  String getWarTypeNameAr() {
    switch (warType) {
      case 'territory':
        return 'حرب أراضي';
      case 'resource':
        return 'حرب موارد';
      case 'dominance':
        return 'حرب هيمنة';
      default:
        return 'غير معروف';
    }
  }

  // الحصول على اسم الحالة بالعربية
  String getStatusNameAr() {
    switch (status) {
      case 'preparing':
        return 'جاري التحضير';
      case 'active':
        return 'نشط';
      case 'ended':
        return 'منتهية';
      default:
        return 'غير معروف';
    }
  }

  // إضافة نقاط للتحالف
  AllianceWarModel addPoints(String allianceId, int points) {
    final isAlliance1 = allianceId == allianceId1;
    final newAlliance1Points = isAlliance1 ? alliance1Points + points : alliance1Points;
    final newAlliance2Points = isAlliance1 ? alliance2Points : alliance2Points + points;
    final totalPoints = newAlliance1Points + newAlliance2Points;
    final newProgress = calculateProgress(totalPoints, targetPoints);

    return AllianceWarModel(
      id: id,
      allianceId1: allianceId1,
      allianceName1: allianceName1,
      allianceId2: allianceId2,
      allianceName2: allianceName2,
      warType: warType,
      status: status,
      createdAt: createdAt,
      startedAt: startedAt,
      endedAt: endedAt,
      endTime: endTime,
      alliance1Points: newAlliance1Points,
      alliance2Points: newAlliance2Points,
      targetPoints: targetPoints,
      progress: newProgress,
      winnerAllianceId: winnerAllianceId,
      participatingFamilies1: participatingFamilies1,
      participatingFamilies2: participatingFamilies2,
      rewards: rewards,
    );
  }

  // إنهاء الحرب
  AllianceWarModel endWar() {
    final winner = alliance1Points > alliance2Points ? allianceId1 : allianceId2;
    
    return AllianceWarModel(
      id: id,
      allianceId1: allianceId1,
      allianceName1: allianceName1,
      allianceId2: allianceId2,
      allianceName2: allianceName2,
      warType: warType,
      status: 'ended',
      createdAt: createdAt,
      startedAt: startedAt,
      endedAt: Timestamp.now(),
      endTime: endTime,
      alliance1Points: alliance1Points,
      alliance2Points: alliance2Points,
      targetPoints: targetPoints,
      progress: 1.0,
      winnerAllianceId: winner,
      participatingFamilies1: participatingFamilies1,
      participatingFamilies2: participatingFamilies2,
      rewards: rewards,
    );
  }

  // الوقت المتبقي
  Duration get remainingTime {
    final now = DateTime.now();
    final end = endTime.toDate();
    return end.difference(now);
  }
}
