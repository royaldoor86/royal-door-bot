import 'package:cloud_firestore/cloud_firestore.dart';

class RecurringTaskModel {
  final String id;
  final String familyId;
  final String familyName;
  final String title;
  final String description;
  final String frequency; // 'daily', 'weekly', 'monthly'
  final String status; // 'active', 'paused', 'completed', 'expired'
  final Timestamp createdAt;
  final Timestamp? lastCompletedAt;
  final Timestamp? nextDueAt;
  final int targetValue;
  final int currentValue;
  final Map<String, dynamic> rewards;
  final List<String> completedBy;
  final int streak;
  final int maxStreak;
  final String? createdBy;

  RecurringTaskModel({
    required this.id,
    required this.familyId,
    required this.familyName,
    required this.title,
    required this.description,
    required this.frequency,
    required this.status,
    required this.createdAt,
    this.lastCompletedAt,
    this.nextDueAt,
    required this.targetValue,
    required this.currentValue,
    required this.rewards,
    required this.completedBy,
    required this.streak,
    required this.maxStreak,
    this.createdBy,
  });

  factory RecurringTaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RecurringTaskModel(
      id: doc.id,
      familyId: data['familyId'] ?? '',
      familyName: data['familyName'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      frequency: data['frequency'] ?? 'daily',
      status: data['status'] ?? 'active',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      lastCompletedAt: data['lastCompletedAt'],
      nextDueAt: data['nextDueAt'],
      targetValue: data['targetValue'] ?? 100,
      currentValue: data['currentValue'] ?? 0,
      rewards: Map<String, dynamic>.from(data['rewards'] ?? {}),
      completedBy: List<String>.from(data['completedBy'] ?? []),
      streak: data['streak'] ?? 0,
      maxStreak: data['maxStreak'] ?? 0,
      createdBy: data['createdBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'familyId': familyId,
      'familyName': familyName,
      'title': title,
      'description': description,
      'frequency': frequency,
      'status': status,
      'createdAt': createdAt,
      'lastCompletedAt': lastCompletedAt,
      'nextDueAt': nextDueAt,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'rewards': rewards,
      'completedBy': completedBy,
      'streak': streak,
      'maxStreak': maxStreak,
      'createdBy': createdBy,
    };
  }

  // حساب نسبة الإنجاز
  double get progress =>
      targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;

  // هل المهمة مكتملة؟
  bool get isCompleted => currentValue >= targetValue;

  // هل المهمة منتهية؟
  bool get isExpired =>
      nextDueAt != null && nextDueAt!.compareTo(Timestamp.now()) < 0;

  // المكافآت الافتراضية لكل تكرار
  static Map<String, dynamic> getDefaultRewards(String frequency) {
    switch (frequency) {
      case 'daily':
        return {
          'familyGems': 50,
          'familyCoins': 100,
          'participantGems': 10,
          'participantCoins': 20,
        };
      case 'weekly':
        return {
          'familyGems': 300,
          'familyCoins': 600,
          'participantGems': 50,
          'participantCoins': 100,
        };
      case 'monthly':
        return {
          'familyGems': 1000,
          'familyCoins': 2000,
          'participantGems': 150,
          'participantCoins': 300,
        };
      default:
        return {
          'familyGems': 50,
          'familyCoins': 100,
          'participantGems': 10,
          'participantCoins': 20,
        };
    }
  }

  // حساب الموعد التالي
  static Timestamp calculateNextDueAt(String frequency, Timestamp from) {
    final date = from.toDate();
    switch (frequency) {
      case 'daily':
        return Timestamp.fromDate(date.add(const Duration(days: 1)));
      case 'weekly':
        return Timestamp.fromDate(date.add(const Duration(days: 7)));
      case 'monthly':
        return Timestamp.fromDate(
            DateTime(date.year, date.month + 1, date.day));
      default:
        return Timestamp.fromDate(date.add(const Duration(days: 1)));
    }
  }

  // إكمال المهمة
  RecurringTaskModel completeTask(String userId) {
    final newCompletedBy = List<String>.from(completedBy);
    if (!newCompletedBy.contains(userId)) {
      newCompletedBy.add(userId);
    }

    final newStreak = streak + 1;
    final newMaxStreak = newStreak > maxStreak ? newStreak : maxStreak;
    final newNextDueAt = calculateNextDueAt(frequency, Timestamp.now());

    return RecurringTaskModel(
      id: id,
      familyId: familyId,
      familyName: familyName,
      title: title,
      description: description,
      frequency: frequency,
      status: 'completed',
      createdAt: createdAt,
      lastCompletedAt: Timestamp.now(),
      nextDueAt: newNextDueAt,
      targetValue: targetValue,
      currentValue: targetValue,
      rewards: rewards,
      completedBy: newCompletedBy,
      streak: newStreak,
      maxStreak: newMaxStreak,
      createdBy: createdBy,
    );
  }

  // إعادة تعيين المهمة للدورة التالية
  RecurringTaskModel resetForNextCycle() {
    return RecurringTaskModel(
      id: id,
      familyId: familyId,
      familyName: familyName,
      title: title,
      description: description,
      frequency: frequency,
      status: 'active',
      createdAt: createdAt,
      lastCompletedAt: Timestamp.now(),
      nextDueAt: calculateNextDueAt(frequency, Timestamp.now()),
      targetValue: targetValue,
      currentValue: 0,
      rewards: rewards,
      completedBy: [],
      streak: streak,
      maxStreak: maxStreak,
      createdBy: createdBy,
    );
  }

  // إضافة مساهمة
  RecurringTaskModel addContribution(int value) {
    final newValue = currentValue + value;
    final newStatus = newValue >= targetValue ? 'completed' : status;

    return RecurringTaskModel(
      id: id,
      familyId: familyId,
      familyName: familyName,
      title: title,
      description: description,
      frequency: frequency,
      status: newStatus,
      createdAt: createdAt,
      lastCompletedAt: lastCompletedAt,
      nextDueAt: nextDueAt,
      targetValue: targetValue,
      currentValue: newValue,
      rewards: rewards,
      completedBy: completedBy,
      streak: streak,
      maxStreak: maxStreak,
      createdBy: createdBy,
    );
  }

  // الحصول على اسم التكرار بالعربية
  String getFrequencyNameAr() {
    switch (frequency) {
      case 'daily':
        return 'يومي';
      case 'weekly':
        return 'أسبوعي';
      case 'monthly':
        return 'شهري';
      default:
        return 'غير معروف';
    }
  }

  // الحصول على اسم الحالة بالعربية
  String getStatusNameAr() {
    switch (status) {
      case 'active':
        return 'نشط';
      case 'paused':
        return 'متوقف';
      case 'completed':
        return 'مكتملة';
      case 'expired':
        return 'منتهية';
      default:
        return 'غير معروف';
    }
  }
}
