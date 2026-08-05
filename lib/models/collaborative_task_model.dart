import 'package:cloud_firestore/cloud_firestore.dart';

class CollaborativeTaskModel {
  final String id;
  final String familyId;
  final String familyName;
  final String title;
  final String description;
  final String type; // 'team', 'alliance', 'war', 'resource'
  final String status; // 'pending', 'in_progress', 'completed', 'failed'
  final Timestamp createdAt;
  final Timestamp? startedAt;
  final Timestamp? completedAt;
  final Timestamp deadline;
  final int requiredParticipants;
  final List<String> participantIds;
  final Map<String, int> participantContributions;
  final int targetValue;
  final int currentValue;
  final Map<String, dynamic> rewards;
  final String? createdBy;
  final String? completedBy;

  CollaborativeTaskModel({
    required this.id,
    required this.familyId,
    required this.familyName,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
    required this.deadline,
    required this.requiredParticipants,
    required this.participantIds,
    required this.participantContributions,
    required this.targetValue,
    required this.currentValue,
    required this.rewards,
    this.createdBy,
    this.completedBy,
  });

  factory CollaborativeTaskModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CollaborativeTaskModel(
      id: doc.id,
      familyId: data['familyId'] ?? '',
      familyName: data['familyName'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? 'team',
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      startedAt: data['startedAt'],
      completedAt: data['completedAt'],
      deadline: data['deadline'] ?? Timestamp.now(),
      requiredParticipants: data['requiredParticipants'] ?? 3,
      participantIds: List<String>.from(data['participantIds'] ?? []),
      participantContributions:
          Map<String, int>.from(data['participantContributions'] ?? {}),
      targetValue: data['targetValue'] ?? 100,
      currentValue: data['currentValue'] ?? 0,
      rewards: Map<String, dynamic>.from(data['rewards'] ?? {}),
      createdBy: data['createdBy'],
      completedBy: data['completedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'familyId': familyId,
      'familyName': familyName,
      'title': title,
      'description': description,
      'type': type,
      'status': status,
      'createdAt': createdAt,
      'startedAt': startedAt,
      'completedAt': completedAt,
      'deadline': deadline,
      'requiredParticipants': requiredParticipants,
      'participantIds': participantIds,
      'participantContributions': participantContributions,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'rewards': rewards,
      'createdBy': createdBy,
      'completedBy': completedBy,
    };
  }

  // حساب نسبة الإنجاز
  double get progress =>
      targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;

  // عدد المشاركين الحالي
  int get currentParticipants => participantIds.length;

  // هل يمكن البدء؟
  bool get canStart =>
      currentParticipants >= requiredParticipants && status == 'pending';

  // هل المهمة مكتملة؟
  bool get isCompleted => currentValue >= targetValue;

  // هل المهمة منتهية؟
  bool get isExpired => deadline.compareTo(Timestamp.now()) < 0;

  // المكافآت الافتراضية لكل نوع مهمة
  static Map<String, dynamic> getDefaultRewards(String type) {
    switch (type) {
      case 'team':
        return {
          'familyGems': 500,
          'familyCoins': 1000,
          'participantGems': 50,
          'participantCoins': 100,
        };
      case 'alliance':
        return {
          'allianceGems': 1000,
          'allianceCoins': 2000,
          'participantGems': 100,
          'participantCoins': 200,
        };
      case 'war':
        return {
          'warPoints': 500,
          'familyGems': 1000,
          'familyCoins': 2000,
          'participantGems': 150,
          'participantCoins': 300,
        };
      case 'resource':
        return {
          'resourceBonus': 1.5,
          'familyGems': 300,
          'familyCoins': 600,
          'participantGems': 30,
          'participantCoins': 60,
        };
      default:
        return {
          'familyGems': 200,
          'familyCoins': 400,
          'participantGems': 20,
          'participantCoins': 40,
        };
    }
  }

  // الانضمام للمهمة
  CollaborativeTaskModel joinTask(String userId) {
    final newParticipantIds = List<String>.from(participantIds);
    if (!newParticipantIds.contains(userId)) {
      newParticipantIds.add(userId);
    }

    final newContributions = Map<String, int>.from(participantContributions);
    newContributions[userId] = 0;

    return CollaborativeTaskModel(
      id: id,
      familyId: familyId,
      familyName: familyName,
      title: title,
      description: description,
      type: type,
      status: status,
      createdAt: createdAt,
      startedAt: startedAt,
      completedAt: completedAt,
      deadline: deadline,
      requiredParticipants: requiredParticipants,
      participantIds: newParticipantIds,
      participantContributions: newContributions,
      targetValue: targetValue,
      currentValue: currentValue,
      rewards: rewards,
      createdBy: createdBy,
      completedBy: completedBy,
    );
  }

  // إضافة مساهمة
  CollaborativeTaskModel addContribution(String userId, int value) {
    final newContributions = Map<String, int>.from(participantContributions);
    newContributions[userId] = (newContributions[userId] ?? 0) + value;

    final totalValue = newContributions.values.reduce((a, b) => a + b);
    final newStatus = totalValue >= targetValue ? 'completed' : status;
    final newCompletedAt =
        newStatus == 'completed' ? Timestamp.now() : completedAt;

    return CollaborativeTaskModel(
      id: id,
      familyId: familyId,
      familyName: familyName,
      title: title,
      description: description,
      type: type,
      status: newStatus,
      createdAt: createdAt,
      startedAt: startedAt,
      completedAt: newCompletedAt,
      deadline: deadline,
      requiredParticipants: requiredParticipants,
      participantIds: participantIds,
      participantContributions: newContributions,
      targetValue: targetValue,
      currentValue: totalValue,
      rewards: rewards,
      createdBy: createdBy,
      completedBy: completedBy,
    );
  }

  // بدء المهمة
  CollaborativeTaskModel startTask() {
    return CollaborativeTaskModel(
      id: id,
      familyId: familyId,
      familyName: familyName,
      title: title,
      description: description,
      type: type,
      status: 'in_progress',
      createdAt: createdAt,
      startedAt: Timestamp.now(),
      completedAt: completedAt,
      deadline: deadline,
      requiredParticipants: requiredParticipants,
      participantIds: participantIds,
      participantContributions: participantContributions,
      targetValue: targetValue,
      currentValue: currentValue,
      rewards: rewards,
      createdBy: createdBy,
      completedBy: completedBy,
    );
  }

  // الحصول على اسم النوع بالعربية
  String getTypeNameAr() {
    switch (type) {
      case 'team':
        return 'فريق';
      case 'alliance':
        return 'تحالف';
      case 'war':
        return 'حرب';
      case 'resource':
        return 'مورد';
      default:
        return 'عام';
    }
  }

  // الحصول على اسم الحالة بالعربية
  String getStatusNameAr() {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'in_progress':
        return 'جاري التنفيذ';
      case 'completed':
        return 'مكتملة';
      case 'failed':
        return 'فشلت';
      default:
        return 'غير معروف';
    }
  }
}
