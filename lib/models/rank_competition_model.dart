import 'package:cloud_firestore/cloud_firestore.dart';

class RankCompetitionModel {
  final String id;
  final String familyId;
  final String rankId;
  final String rankName;
  final int totalMembers;
  final int activeMembers;
  final int totalContributionPoints;
  final int weeklyContributionPoints;
  final int monthlyContributionPoints;
  final int competitionScore;
  final int rank;
  final Timestamp lastUpdated;
  final List<String> topMembers;
  final Map<String, dynamic> achievements;

  RankCompetitionModel({
    required this.id,
    required this.familyId,
    required this.rankId,
    required this.rankName,
    required this.totalMembers,
    required this.activeMembers,
    required this.totalContributionPoints,
    required this.weeklyContributionPoints,
    required this.monthlyContributionPoints,
    required this.competitionScore,
    required this.rank,
    required this.lastUpdated,
    required this.topMembers,
    required this.achievements,
  });

  factory RankCompetitionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RankCompetitionModel(
      id: doc.id,
      familyId: data['familyId'] ?? '',
      rankId: data['rankId'] ?? '',
      rankName: data['rankName'] ?? '',
      totalMembers: data['totalMembers'] ?? 0,
      activeMembers: data['activeMembers'] ?? 0,
      totalContributionPoints: data['totalContributionPoints'] ?? 0,
      weeklyContributionPoints: data['weeklyContributionPoints'] ?? 0,
      monthlyContributionPoints: data['monthlyContributionPoints'] ?? 0,
      competitionScore: data['competitionScore'] ?? 0,
      rank: data['rank'] ?? 0,
      lastUpdated: data['lastUpdated'] ?? Timestamp.now(),
      topMembers: List<String>.from(data['topMembers'] ?? []),
      achievements: Map<String, dynamic>.from(data['achievements'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'familyId': familyId,
      'rankId': rankId,
      'rankName': rankName,
      'totalMembers': totalMembers,
      'activeMembers': activeMembers,
      'totalContributionPoints': totalContributionPoints,
      'weeklyContributionPoints': weeklyContributionPoints,
      'monthlyContributionPoints': monthlyContributionPoints,
      'competitionScore': competitionScore,
      'rank': rank,
      'lastUpdated': lastUpdated,
      'topMembers': topMembers,
      'achievements': achievements,
    };
  }

  // حساب نقاط التنافس
  static int calculateCompetitionScore(
    int totalMembers,
    int activeMembers,
    int totalContributionPoints,
    int weeklyContributionPoints,
  ) {
    final activityRatio = totalMembers > 0 ? (activeMembers / totalMembers) * 100 : 0;
    return (totalContributionPoints ~/ 10) +
           (weeklyContributionPoints ~/ 5) +
           (activityRatio.toInt() * 10);
  }

  // تحديث الإحصائيات بعد مساهمة
  RankCompetitionModel updateContribution(int points) {
    final newTotalContribution = totalContributionPoints + points;
    final newWeeklyContribution = weeklyContributionPoints + points;
    final newMonthlyContribution = monthlyContributionPoints + points;
    final newScore = calculateCompetitionScore(
      totalMembers,
      activeMembers,
      newTotalContribution,
      newWeeklyContribution,
    );

    return RankCompetitionModel(
      id: id,
      familyId: familyId,
      rankId: rankId,
      rankName: rankName,
      totalMembers: totalMembers,
      activeMembers: activeMembers,
      totalContributionPoints: newTotalContribution,
      weeklyContributionPoints: newWeeklyContribution,
      monthlyContributionPoints: newMonthlyContribution,
      competitionScore: newScore,
      rank: rank,
      lastUpdated: Timestamp.now(),
      topMembers: topMembers,
      achievements: achievements,
    );
  }

  // إضافة إنجاز
  RankCompetitionModel addAchievement(String achievementId, String achievementName) {
    final newAchievements = Map<String, dynamic>.from(achievements);
    newAchievements[achievementId] = {
      'name': achievementName,
      'achievedAt': Timestamp.now(),
    };

    return RankCompetitionModel(
      id: id,
      familyId: familyId,
      rankId: rankId,
      rankName: rankName,
      totalMembers: totalMembers,
      activeMembers: activeMembers,
      totalContributionPoints: totalContributionPoints,
      weeklyContributionPoints: weeklyContributionPoints,
      monthlyContributionPoints: monthlyContributionPoints,
      competitionScore: competitionScore,
      rank: rank,
      lastUpdated: lastUpdated,
      topMembers: topMembers,
      achievements: newAchievements,
    );
  }

  // الحصول على المستوى التنافسي
  String getCompetitionLevel() {
    if (competitionScore >= 10000) return 'أسطوري';
    if (competitionScore >= 5000) return 'ممتاز';
    if (competitionScore >= 2500) return 'متقدم';
    if (competitionScore >= 1000) return 'متوسط';
    if (competitionScore >= 500) return 'مبتدئ';
    return 'جديد';
  }

  // الحصول على لون المستوى
  String getCompetitionLevelColor() {
    if (competitionScore >= 10000) return '#FFD700'; // ذهبي
    if (competitionScore >= 5000) return '#C0C0C0'; // فضي
    if (competitionScore >= 2500) return '#CD7F32'; // برونزي
    if (competitionScore >= 1000) return '#4CAF50'; // أخضر
    if (competitionScore >= 500) return '#2196F3'; // أزرق
    return '#9E9E9E'; // رمادي
  }
}
