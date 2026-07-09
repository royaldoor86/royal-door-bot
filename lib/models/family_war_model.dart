import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyWarModel {
  final String id;
  final String challengerId;
  final String challengerName;
  final String? challengerLogo;
  final int challengerPoints;
  final String targetId;
  final String targetName;
  final String? targetLogo;
  final int targetPoints;
  final String status; // 'active', 'completed', 'cancelled'
  final Timestamp startTime;
  final Timestamp endTime;
  final Timestamp createdAt;
  final String? winnerId;
  final String? warType; // 'normal', 'championship', 'alliance'
  final int durationMinutes;
  final Map<String, dynamic> rewards;
  final List<String> participants; // قائمة بمعرفات المشاركين من كل عائلة
  final Map<String, int> contributionPoints; // userId -> points
  final String? createdBy;
  final Timestamp? completedAt;

  FamilyWarModel({
    required this.id,
    required this.challengerId,
    required this.challengerName,
    this.challengerLogo,
    this.challengerPoints = 0,
    required this.targetId,
    required this.targetName,
    this.targetLogo,
    this.targetPoints = 0,
    required this.status,
    required this.startTime,
    required this.endTime,
    required this.createdAt,
    this.winnerId,
    this.warType = 'normal',
    required this.durationMinutes,
    this.rewards = const {},
    this.participants = const [],
    this.contributionPoints = const {},
    this.createdBy,
    this.completedAt,
  });

  factory FamilyWarModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FamilyWarModel(
      id: doc.id,
      challengerId: data['challengerId'] ?? '',
      challengerName: data['challengerName'] ?? '',
      challengerLogo: data['challengerLogo'],
      challengerPoints: (data['challengerPoints'] ?? 0).toInt(),
      targetId: data['targetId'] ?? '',
      targetName: data['targetName'] ?? '',
      targetLogo: data['targetLogo'],
      targetPoints: (data['targetPoints'] ?? 0).toInt(),
      status: data['status'] ?? 'active',
      startTime: data['startTime'] ?? Timestamp.now(),
      endTime: data['endTime'] ?? Timestamp.now(),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      winnerId: data['winnerId'],
      warType: data['warType'] ?? 'normal',
      durationMinutes: (data['durationMinutes'] ?? 60).toInt(),
      rewards: data['rewards'] ?? {},
      participants: List<String>.from(data['participants'] ?? []),
      contributionPoints:
          Map<String, int>.from(data['contributionPoints'] ?? {}),
      createdBy: data['createdBy'],
      completedAt: data['completedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'challengerId': challengerId,
      'challengerName': challengerName,
      'challengerLogo': challengerLogo,
      'challengerPoints': challengerPoints,
      'targetId': targetId,
      'targetName': targetName,
      'targetLogo': targetLogo,
      'targetPoints': targetPoints,
      'status': status,
      'startTime': startTime,
      'endTime': endTime,
      'createdAt': createdAt,
      'winnerId': winnerId,
      'warType': warType,
      'durationMinutes': durationMinutes,
      'rewards': rewards,
      'participants': participants,
      'contributionPoints': contributionPoints,
      'createdBy': createdBy,
      'completedAt': completedAt,
    };
  }

  // الحصول على المكافآت الافتراضية حسب نوع الحرب
  static Map<String, dynamic> getDefaultRewards(String warType) {
    switch (warType) {
      case 'championship':
        return {
          'winnerGems': 1000,
          'winnerStars': 5000,
          'winnerBadges': ['champion_war_badge', 'golden_warrior'],
          'loserGems': 200,
          'loserStars': 1000,
          'loserBadges': [],
          'participationReward': 50, // stars for all participants
        };
      case 'alliance':
        return {
          'winnerGems': 1500,
          'winnerStars': 7500,
          'winnerBadges': ['alliance_war_badge', 'alliance_commander'],
          'loserGems': 300,
          'loserStars': 1500,
          'loserBadges': [],
          'participationReward': 75,
        };
      case 'tournament':
        return {
          'winnerGems': 2000,
          'winnerStars': 10000,
          'winnerBadges': ['tournament_champion', 'legendary_warrior'],
          'loserGems': 400,
          'loserStars': 2000,
          'loserBadges': [],
          'participationReward': 100,
        };
      default: // normal
        return {
          'winnerGems': 500,
          'winnerStars': 2500,
          'winnerBadges': ['war_veteran'],
          'loserGems': 100,
          'loserStars': 500,
          'loserBadges': [],
          'participationReward': 25,
        };
    }
  }

  // حساب المكافآت الفردية بناءً على المساهمة
  Map<String, dynamic> calculateIndividualRewards(
      String userId, int contributionPoints) {
    final isWinner =
        winnerId == (challengerPoints > targetPoints ? challengerId : targetId);
    final baseReward = isWinner
        ? rewards['winnerStars'] ?? 2500
        : rewards['loserStars'] ?? 500;
    final contributionBonus = (contributionPoints / 100).floor() * 10;
    final totalStars = baseReward + contributionBonus;
    final gemsReward = isWinner
        ? (rewards['winnerGems'] ?? 500) ~/ 10
        : (rewards['loserGems'] ?? 100) ~/ 10;

    // إضافة شارات خاصة للمساهمين المتميزين
    List<String> badges = [];
    if (contributionPoints >= 500) {
      badges.add('elite_contributor');
    }
    if (contributionPoints >= 1000) {
      badges.add('war_legend');
    }

    return {
      'stars': totalStars,
      'gems': gemsReward,
      'badges': badges,
    };
  }

  // حساب الوقت المتبقي
  Duration get remainingTime {
    final now = DateTime.now();
    final end = endTime.toDate();
    if (now.isAfter(end)) return Duration.zero;
    return end.difference(now);
  }

  // هل الحرب نشطة؟
  bool get isActive => status == 'active' && remainingTime > Duration.zero;

  // هل انتهت الحرب؟
  bool get isCompleted => status == 'completed';

  // نسبة تقدم الحرب
  double get progress {
    final totalDuration =
        endTime.toDate().difference(startTime.toDate()).inMinutes;
    final elapsed = DateTime.now().difference(startTime.toDate()).inMinutes;
    if (totalDuration <= 0) return 1.0;
    return (elapsed / totalDuration).clamp(0.0, 1.0);
  }

  // الفائز الحالي (بناءً على النقاط)
  String? getCurrentLeader() {
    if (challengerPoints > targetPoints) return challengerId;
    if (targetPoints > challengerPoints) return targetId;
    return null; // تعادل
  }

  // الفرق في النقاط
  int get pointDifference => (challengerPoints - targetPoints).abs();
}
