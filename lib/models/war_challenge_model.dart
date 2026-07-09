import 'package:cloud_firestore/cloud_firestore.dart';

class WarChallengeModel {
  final String id;
  final String warId;
  final String familyId;
  final String familyName;
  final String title;
  final String description;
  final String type; // 'points', 'participation', 'time', 'special'
  final int targetValue;
  final int currentValue;
  final int rewardPoints;
  final String rewardType; // 'gems', 'stars', 'badge'
  final String? rewardBadgeId;
  final String status; // 'active', 'completed', 'failed'
  final Timestamp createdAt;
  final Timestamp? completedAt;
  final int maxParticipants;
  final List<String> participantIds;
  final Map<String, int> participantProgress;

  WarChallengeModel({
    required this.id,
    required this.warId,
    required this.familyId,
    required this.familyName,
    required this.title,
    required this.description,
    required this.type,
    required this.targetValue,
    required this.currentValue,
    required this.rewardPoints,
    required this.rewardType,
    this.rewardBadgeId,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.maxParticipants = 999,
    required this.participantIds,
    required this.participantProgress,
  });

  factory WarChallengeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return WarChallengeModel(
      id: doc.id,
      warId: data['warId'] ?? '',
      familyId: data['familyId'] ?? '',
      familyName: data['familyName'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? 'points',
      targetValue: data['targetValue'] ?? 100,
      currentValue: data['currentValue'] ?? 0,
      rewardPoints: data['rewardPoints'] ?? 50,
      rewardType: data['rewardType'] ?? 'stars',
      rewardBadgeId: data['rewardBadgeId'],
      status: data['status'] ?? 'active',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      completedAt: data['completedAt'],
      maxParticipants: data['maxParticipants'] ?? 999,
      participantIds: List<String>.from(data['participantIds'] ?? []),
      participantProgress: Map<String, int>.from(data['participantProgress'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'warId': warId,
      'familyId': familyId,
      'familyName': familyName,
      'title': title,
      'description': description,
      'type': type,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'rewardPoints': rewardPoints,
      'rewardType': rewardType,
      'rewardBadgeId': rewardBadgeId,
      'status': status,
      'createdAt': createdAt,
      'completedAt': completedAt,
      'maxParticipants': maxParticipants,
      'participantIds': participantIds,
      'participantProgress': participantProgress,
    };
  }

  // حساب نسبة الإنجاز
  double get progress => targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0.0;

  // هل التحدي مكتمل؟
  bool get isCompleted => currentValue >= targetValue;

  // هل يمكن الانضمام؟
  bool canJoin(String userId) {
    return status == 'active' && 
           !participantIds.contains(userId) && 
           participantIds.length < maxParticipants;
  }

  // التحديات الافتراضية للحرب
  static List<WarChallengeModel> getDefaultChallenges(String warId, String familyId, String familyName) {
    return [
      WarChallengeModel(
        id: '',
        warId: warId,
        familyId: familyId,
        familyName: familyName,
        title: 'سيد النقاط',
        description: 'اجمع 500 نقطة في الحرب',
        type: 'points',
        targetValue: 500,
        currentValue: 0,
        rewardPoints: 100,
        rewardType: 'stars',
        status: 'active',
        createdAt: Timestamp.now(),
        participantIds: [],
        participantProgress: {},
      ),
      WarChallengeModel(
        id: '',
        warId: warId,
        familyId: familyId,
        familyName: familyName,
        title: 'المشاركة النشطة',
        description: 'شارك 10 أعضاء في الحرب',
        type: 'participation',
        targetValue: 10,
        currentValue: 0,
        rewardPoints: 50,
        rewardType: 'gems',
        status: 'active',
        createdAt: Timestamp.now(),
        participantIds: [],
        participantProgress: {},
      ),
      WarChallengeModel(
        id: '',
        warId: warId,
        familyId: familyId,
        familyName: familyName,
        title: 'السرعة القصوى',
        description: 'اكسب 200 نقطة في أول ساعة',
        type: 'time',
        targetValue: 200,
        currentValue: 0,
        rewardPoints: 150,
        rewardType: 'stars',
        status: 'active',
        createdAt: Timestamp.now(),
        participantIds: [],
        participantProgress: {},
      ),
      WarChallengeModel(
        id: '',
        warId: warId,
        familyId: familyId,
        familyName: familyName,
        title: 'بطل الحرب',
        description: 'كن أكثر عضو مساهماً في الحرب',
        type: 'special',
        targetValue: 1000,
        currentValue: 0,
        rewardPoints: 200,
        rewardType: 'badge',
        rewardBadgeId: 'war_hero',
        status: 'active',
        createdAt: Timestamp.now(),
        participantIds: [],
        participantProgress: {},
      ),
    ];
  }

  // تحديث تقدم المشارك
  WarChallengeModel updateParticipantProgress(String userId, int progress) {
    final newProgress = Map<String, int>.from(participantProgress);
    newProgress[userId] = (newProgress[userId] ?? 0) + progress;
    
    final totalProgress = newProgress.values.reduce((a, b) => a + b);
    final newCurrentValue = totalProgress;
    final newStatus = newCurrentValue >= targetValue ? 'completed' : status;
    final newCompletedAt = newStatus == 'completed' ? Timestamp.now() : completedAt;

    return WarChallengeModel(
      id: id,
      warId: warId,
      familyId: familyId,
      familyName: familyName,
      title: title,
      description: description,
      type: type,
      targetValue: targetValue,
      currentValue: newCurrentValue,
      rewardPoints: rewardPoints,
      rewardType: rewardType,
      rewardBadgeId: rewardBadgeId,
      status: newStatus,
      createdAt: createdAt,
      completedAt: newCompletedAt,
      maxParticipants: maxParticipants,
      participantIds: participantIds,
      participantProgress: newProgress,
    );
  }
}
