import 'package:cloud_firestore/cloud_firestore.dart';

class MiniGameModel {
  final String id;
  final String familyId;
  final String name;
  final String nameAr;
  final String type; // 'quiz', 'trivia', 'reaction', 'memory'
  final String description;
  final Map<String, dynamic> gameData; // بيانات اللعبة
  final int maxPlayers;
  final int currentPlayers;
  final String createdBy;
  final Timestamp createdAt;
  final Timestamp? startedAt;
  final Timestamp? endedAt;
  final bool isActive;
  final Map<String, dynamic> results; // النتائج

  MiniGameModel({
    required this.id,
    required this.familyId,
    required this.name,
    required this.nameAr,
    required this.type,
    required this.description,
    required this.gameData,
    required this.maxPlayers,
    required this.currentPlayers,
    required this.createdBy,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
    required this.isActive,
    required this.results,
  });

  factory MiniGameModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MiniGameModel(
      id: doc.id,
      familyId: data['familyId'] ?? '',
      name: data['name'] ?? '',
      nameAr: data['nameAr'] ?? '',
      type: data['type'] ?? 'quiz',
      description: data['description'] ?? '',
      gameData: Map<String, dynamic>.from(data['gameData'] ?? {}),
      maxPlayers: data['maxPlayers'] ?? 2,
      currentPlayers: data['currentPlayers'] ?? 0,
      createdBy: data['createdBy'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      startedAt: data['startedAt'],
      endedAt: data['endedAt'],
      isActive: data['isActive'] ?? true,
      results: Map<String, dynamic>.from(data['results'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'familyId': familyId,
      'name': name,
      'nameAr': nameAr,
      'type': type,
      'description': description,
      'gameData': gameData,
      'maxPlayers': maxPlayers,
      'currentPlayers': currentPlayers,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'startedAt': startedAt,
      'endedAt': endedAt,
      'isActive': isActive,
      'results': results,
    };
  }

  // هل اللعبة ممتلئة؟
  bool get isFull => currentPlayers >= maxPlayers;

  // هل يمكن الانضمام؟
  bool get canJoin => isActive && !isFull;

  // الحصول على اسم النوع بالعربية
  String getTypeNameAr() {
    switch (type) {
      case 'quiz':
        return 'اختبار';
      case 'trivia':
        return 'معلومات عامة';
      case 'reaction':
        return 'رد فعل';
      case 'memory':
        return 'ذاكرة';
      default:
        return 'لعبة';
    }
  }
}

class DailyChallengeModel {
  final String id;
  final String familyId;
  final String title;
  final String titleAr;
  final String description;
  final String type; // 'points', 'wars', 'tasks', 'social'
  final int targetValue;
  final int currentValue;
  final Timestamp startDate;
  final Timestamp endDate;
  final Map<String, dynamic> rewards;
  final List<String> completedBy;
  final bool isActive;

  DailyChallengeModel({
    required this.id,
    required this.familyId,
    required this.title,
    required this.titleAr,
    required this.description,
    required this.type,
    required this.targetValue,
    required this.currentValue,
    required this.startDate,
    required this.endDate,
    required this.rewards,
    required this.completedBy,
    required this.isActive,
  });

  factory DailyChallengeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailyChallengeModel(
      id: doc.id,
      familyId: data['familyId'] ?? '',
      title: data['title'] ?? '',
      titleAr: data['titleAr'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? 'points',
      targetValue: data['targetValue'] ?? 100,
      currentValue: data['currentValue'] ?? 0,
      startDate: data['startDate'] ?? Timestamp.now(),
      endDate: data['endDate'] ?? Timestamp.now(),
      rewards: Map<String, dynamic>.from(data['rewards'] ?? {}),
      completedBy: List<String>.from(data['completedBy'] ?? []),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'familyId': familyId,
      'title': title,
      'titleAr': titleAr,
      'description': description,
      'type': type,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'startDate': startDate,
      'endDate': endDate,
      'rewards': rewards,
      'completedBy': completedBy,
      'isActive': isActive,
    };
  }

  // نسبة التقدم
  double get progress => targetValue > 0 ? currentValue / targetValue : 0;

  // هل التحدي مكتمل؟
  bool get isCompleted => currentValue >= targetValue;

  // الحصول على اسم النوع بالعربية
  String getTypeNameAr() {
    switch (type) {
      case 'points':
        return 'نقاط';
      case 'wars':
        return 'حروب';
      case 'tasks':
        return 'مهام';
      case 'social':
        return 'اجتماعي';
      default:
        return 'عام';
    }
  }
}
