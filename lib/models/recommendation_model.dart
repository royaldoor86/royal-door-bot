import 'package:cloud_firestore/cloud_firestore.dart';

class RecommendationModel {
  final String id;
  final String type; // 'war', 'alliance', 'task'
  final String targetId; // warId, allianceId, taskId
  final String targetName;
  final String familyId;
  final double score; // درجة التوصية (0-100)
  final Map<String, dynamic> reasons; // أسباب التوصية
  final Timestamp createdAt;
  final bool isViewed;
  final bool isAccepted;

  RecommendationModel({
    required this.id,
    required this.type,
    required this.targetId,
    required this.targetName,
    required this.familyId,
    required this.score,
    required this.reasons,
    required this.createdAt,
    this.isViewed = false,
    this.isAccepted = false,
  });

  factory RecommendationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RecommendationModel(
      id: doc.id,
      type: data['type'] ?? '',
      targetId: data['targetId'] ?? '',
      targetName: data['targetName'] ?? '',
      familyId: data['familyId'] ?? '',
      score: (data['score'] ?? 0).toDouble(),
      reasons: Map<String, dynamic>.from(data['reasons'] ?? {}),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      isViewed: data['isViewed'] ?? false,
      isAccepted: data['isAccepted'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'targetId': targetId,
      'targetName': targetName,
      'familyId': familyId,
      'score': score,
      'reasons': reasons,
      'createdAt': createdAt,
      'isViewed': isViewed,
      'isAccepted': isAccepted,
    };
  }

  // الحصول على اسم النوع بالعربية
  String getTypeNameAr() {
    switch (type) {
      case 'war':
        return 'حرب';
      case 'alliance':
        return 'تحالف';
      case 'task':
        return 'مهمة';
      default:
        return 'توصية';
    }
  }

  // هل التوصية عالية الجودة؟
  bool get isHighQuality => score >= 80;

  // هل التوصية متوسطة الجودة؟
  bool get isMediumQuality => score >= 50 && score < 80;
}
