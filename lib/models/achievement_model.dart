import 'package:cloud_firestore/cloud_firestore.dart';

enum AchievementType {
  firstHarvest,
  harvestStreak,
  totalGems,
  totalStars,
  packagesOwned,
  socialPoints,
  referrals,
  vipLevel,
}

enum AchievementStatus {
  locked,
  unlocked,
  claimed,
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final AchievementType type;
  final int targetValue;
  final int rewardGems;
  final int rewardStars;
  final AchievementStatus status;
  final DateTime? unlockedAt;
  final DateTime? claimedAt;
  final Map<String, dynamic>? metadata;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.type,
    required this.targetValue,
    this.rewardGems = 0,
    this.rewardStars = 0,
    this.status = AchievementStatus.locked,
    this.unlockedAt,
    this.claimedAt,
    this.metadata,
  });

  factory Achievement.fromMap(Map<String, dynamic> data, String id) {
    return Achievement(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? '🏆',
      type: _parseType(data['type']),
      targetValue: data['targetValue'] ?? 0,
      rewardGems: data['rewardGems'] ?? 0,
      rewardStars: data['rewardStars'] ?? 0,
      status: _parseStatus(data['status']),
      unlockedAt: (data['unlockedAt'] as Timestamp?)?.toDate(),
      claimedAt: (data['claimedAt'] as Timestamp?)?.toDate(),
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'icon': icon,
      'type': type.name,
      'targetValue': targetValue,
      'rewardGems': rewardGems,
      'rewardStars': rewardStars,
      'status': status.name,
      'unlockedAt': unlockedAt != null ? Timestamp.fromDate(unlockedAt!) : null,
      'claimedAt': claimedAt != null ? Timestamp.fromDate(claimedAt!) : null,
      'metadata': metadata,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  static AchievementType _parseType(String? type) {
    if (type == null) return AchievementType.firstHarvest;
    return AchievementType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => AchievementType.firstHarvest,
    );
  }

  static AchievementStatus _parseStatus(String? status) {
    if (status == null) return AchievementStatus.locked;
    return AchievementStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => AchievementStatus.locked,
    );
  }

  double get progress {
    // This should be calculated based on user's current value vs target
    // This is a placeholder - actual progress calculation should be done in the service
    return 0.0;
  }

  bool get isUnlocked => status == AchievementStatus.unlocked || status == AchievementStatus.claimed;
  bool get isClaimed => status == AchievementStatus.claimed;
  bool get canClaim => isUnlocked && !isClaimed;

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? icon,
    AchievementType? type,
    int? targetValue,
    int? rewardGems,
    int? rewardStars,
    AchievementStatus? status,
    DateTime? unlockedAt,
    DateTime? claimedAt,
    Map<String, dynamic>? metadata,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      rewardGems: rewardGems ?? this.rewardGems,
      rewardStars: rewardStars ?? this.rewardStars,
      status: status ?? this.status,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      claimedAt: claimedAt ?? this.claimedAt,
      metadata: metadata ?? this.metadata,
    );
  }
}

// Predefined achievements
class AchievementsList {
  static List<Achievement> get defaultAchievements => [
    Achievement(
      id: 'first_harvest',
      title: 'أول حصاد',
      description: 'قم بحصاد مكافأتك الأولى',
      icon: '🌱',
      type: AchievementType.firstHarvest,
      targetValue: 1,
      rewardGems: 100,
      rewardStars: 10,
    ),
    Achievement(
      id: 'harvest_streak_3',
      title: 'ثلاثة أيام متتالية',
      description: 'احصد لمدة 3 أيام متتالية',
      icon: '🔥',
      type: AchievementType.harvestStreak,
      targetValue: 3,
      rewardGems: 200,
      rewardStars: 20,
    ),
    Achievement(
      id: 'harvest_streak_7',
      title: 'أسبوع كامل',
      description: 'احصد لمدة 7 أيام متتالية',
      icon: '⭐',
      type: AchievementType.harvestStreak,
      targetValue: 7,
      rewardGems: 500,
      rewardStars: 50,
    ),
    Achievement(
      id: 'gems_1000',
      title: 'ألف جوهرة',
      description: 'اجمع 1000 جوهرة',
      icon: '💎',
      type: AchievementType.totalGems,
      targetValue: 1000,
      rewardGems: 150,
      rewardStars: 15,
    ),
    Achievement(
      id: 'gems_10000',
      title: 'عشرة آلاف جوهرة',
      description: 'اجمع 10000 جوهرة',
      icon: '💎💎',
      type: AchievementType.totalGems,
      targetValue: 10000,
      rewardGems: 1000,
      rewardStars: 100,
    ),
    Achievement(
      id: 'stars_100',
      title: 'مائة نجمة',
      description: 'اجمع 100 نجمة',
      icon: '🌟',
      type: AchievementType.totalStars,
      targetValue: 100,
      rewardGems: 200,
      rewardStars: 20,
    ),
    Achievement(
      id: 'packages_5',
      title: 'جامع الباقات',
      description: 'امتلك 5 باقات نشطة',
      icon: '📦',
      type: AchievementType.packagesOwned,
      targetValue: 5,
      rewardGems: 300,
      rewardStars: 30,
    ),
    Achievement(
      id: 'social_points_500',
      title: 'شعبي',
      description: 'احصل على 500 نقطة اجتماعية',
      icon: '👥',
      type: AchievementType.socialPoints,
      targetValue: 500,
      rewardGems: 250,
      rewardStars: 25,
    ),
  ];
}
