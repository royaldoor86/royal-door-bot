import 'package:cloud_firestore/cloud_firestore.dart';

class ProgressiveRewardModel {
  final String id;
  final String userId;
  final String familyId;
  final int consecutiveDays; // أيام متتالية
  final int currentStreak; // السلسلة الحالية
  final int maxStreak; // أقصى سلسلة
  final int baseGems; // الجواهر الأساسية (تبدأ بـ 1)
  final int currentGems; // الجواهر الحالية
  final int bonusMultiplier; // مضاعف المكافأة
  final Timestamp lastClaimDate;
  final Timestamp nextClaimDate;
  final Map<String, dynamic> rewards; // المكافآت الحالية

  ProgressiveRewardModel({
    required this.id,
    required this.userId,
    required this.familyId,
    required this.consecutiveDays,
    required this.currentStreak,
    required this.maxStreak,
    required this.baseGems,
    required this.currentGems,
    required this.bonusMultiplier,
    required this.lastClaimDate,
    required this.nextClaimDate,
    required this.rewards,
  });

  factory ProgressiveRewardModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProgressiveRewardModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      familyId: data['familyId'] ?? '',
      consecutiveDays: data['consecutiveDays'] ?? 0,
      currentStreak: data['currentStreak'] ?? 0,
      maxStreak: data['maxStreak'] ?? 0,
      baseGems: data['baseGems'] ?? 1,
      currentGems: data['currentGems'] ?? 1,
      bonusMultiplier: data['bonusMultiplier'] ?? 1,
      lastClaimDate: data['lastClaimDate'] ?? Timestamp.now(),
      nextClaimDate: data['nextClaimDate'] ?? Timestamp.now(),
      rewards: Map<String, dynamic>.from(data['rewards'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'familyId': familyId,
      'consecutiveDays': consecutiveDays,
      'currentStreak': currentStreak,
      'maxStreak': maxStreak,
      'baseGems': baseGems,
      'currentGems': currentGems,
      'bonusMultiplier': bonusMultiplier,
      'lastClaimDate': lastClaimDate,
      'nextClaimDate': nextClaimDate,
      'rewards': rewards,
    };
  }

  // حساب الجواهر بناءً على السلسلة
  static int calculateGemsForStreak(int streak) {
    // تبدأ بجوهر واحد وتزداد
    // اليوم 1: 1 جوهرة
    // اليوم 2: 2 جوهرة
    // اليوم 3: 3 جواهر
    // اليوم 7: 7 جواهر
    // اليوم 30: 30 جوهرة
    // الحد الأقصى: 100 جوهرة
    return (streak + 1).clamp(1, 100);
  }

  // حساب مضاعف المكافأة بناءً على السلسلة
  static int calculateBonusMultiplier(int streak) {
    if (streak >= 30) return 3; // 30 يوم أو أكثر: x3
    if (streak >= 14) return 2; // 14 يوم أو أكثر: x2
    if (streak >= 7) return 1; // 7 أيام أو أكثر: x1 (لا يوجد مضاعف إضافي)
    return 1; // أقل من 7 أيام: x1
  }

  // حساب المكافآت الكاملة
  Map<String, dynamic> calculateFullRewards() {
    final gems = calculateGemsForStreak(currentStreak);
    final multiplier = calculateBonusMultiplier(currentStreak);
    final totalGems = gems * multiplier;
    final stars = totalGems * 2; // النجوم ضعف الجواهر

    return {
      'gems': totalGems,
      'stars': stars,
      'streak': currentStreak,
      'multiplier': multiplier,
    };
  }

  // هل يمكن المطالبة بالمكافأة؟
  bool get canClaim => DateTime.now().isAfter(nextClaimDate.toDate());

  // هل السلسلة مكسورة؟
  bool get isStreakBroken {
    final now = DateTime.now();
    final lastClaim = lastClaimDate.toDate();
    final daysSinceLastClaim = now.difference(lastClaim).inDays;
    return daysSinceLastClaim > 1; // أكثر من يوم يعني كسر السلسلة
  }

  // نسخة معدلة من النموذج
  ProgressiveRewardModel copyWith({
    String? id,
    String? userId,
    String? familyId,
    int? consecutiveDays,
    int? currentStreak,
    int? maxStreak,
    int? baseGems,
    int? currentGems,
    int? bonusMultiplier,
    Timestamp? lastClaimDate,
    Timestamp? nextClaimDate,
    Map<String, dynamic>? rewards,
  }) {
    return ProgressiveRewardModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      familyId: familyId ?? this.familyId,
      consecutiveDays: consecutiveDays ?? this.consecutiveDays,
      currentStreak: currentStreak ?? this.currentStreak,
      maxStreak: maxStreak ?? this.maxStreak,
      baseGems: baseGems ?? this.baseGems,
      currentGems: currentGems ?? this.currentGems,
      bonusMultiplier: bonusMultiplier ?? this.bonusMultiplier,
      lastClaimDate: lastClaimDate ?? this.lastClaimDate,
      nextClaimDate: nextClaimDate ?? this.nextClaimDate,
      rewards: rewards ?? this.rewards,
    );
  }
}
