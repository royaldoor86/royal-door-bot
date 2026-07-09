import 'package:cloud_firestore/cloud_firestore.dart';

class AdvancedStatisticsModel {
  final String id;
  final String familyId;
  final String period; // 'daily', 'weekly', 'monthly'
  final Timestamp startDate;
  final Timestamp endDate;
  final Map<String, dynamic> warStats;
  final Map<String, dynamic> taskStats;
  final Map<String, dynamic> contributionStats;
  final Map<String, dynamic> socialStats;
  final Map<String, dynamic> memberStats;
  final Timestamp createdAt;

  AdvancedStatisticsModel({
    required this.id,
    required this.familyId,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.warStats,
    required this.taskStats,
    required this.contributionStats,
    required this.socialStats,
    required this.memberStats,
    required this.createdAt,
  });

  factory AdvancedStatisticsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdvancedStatisticsModel(
      id: doc.id,
      familyId: data['familyId'] ?? '',
      period: data['period'] ?? 'daily',
      startDate: data['startDate'] ?? Timestamp.now(),
      endDate: data['endDate'] ?? Timestamp.now(),
      warStats: Map<String, dynamic>.from(data['warStats'] ?? {}),
      taskStats: Map<String, dynamic>.from(data['taskStats'] ?? {}),
      contributionStats: Map<String, dynamic>.from(data['contributionStats'] ?? {}),
      socialStats: Map<String, dynamic>.from(data['socialStats'] ?? {}),
      memberStats: Map<String, dynamic>.from(data['memberStats'] ?? {}),
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'familyId': familyId,
      'period': period,
      'startDate': startDate,
      'endDate': endDate,
      'warStats': warStats,
      'taskStats': taskStats,
      'contributionStats': contributionStats,
      'socialStats': socialStats,
      'memberStats': memberStats,
      'createdAt': createdAt,
    };
  }

  // الحصول على اسم الفترة بالعربية
  String getPeriodNameAr() {
    switch (period) {
      case 'daily':
        return 'يومي';
      case 'weekly':
        return 'أسبوعي';
      case 'monthly':
        return 'شهري';
      default:
        return 'عام';
    }
  }
}

class FamilyComparisonModel {
  final String familyId;
  final String familyName;
  final int totalPoints;
  final int warsWon;
  final int warsLost;
  final int tasksCompleted;
  final int activeMembers;
  final int rank;
  final double growthRate;

  FamilyComparisonModel({
    required this.familyId,
    required this.familyName,
    required this.totalPoints,
    required this.warsWon,
    required this.warsLost,
    required this.tasksCompleted,
    required this.activeMembers,
    required this.rank,
    required this.growthRate,
  });

  // نسبة الفوز في الحروب
  double get warWinRate {
    final totalWars = warsWon + warsLost;
    return totalWars > 0 ? warsWon / totalWars : 0;
  }

  // متوسط النقاط لكل عضو
  double get averagePointsPerMember {
    return activeMembers > 0 ? totalPoints / activeMembers : 0;
  }
}
