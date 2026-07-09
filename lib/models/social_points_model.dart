import 'package:cloud_firestore/cloud_firestore.dart';

class SocialPointsModel {
  final String userId;
  final int totalStars; // Renamed from totalPoints
  final int level;
  final Map<String, int> pointsByType; // e.g., {'follow': 10, 'like': 5}
  final Timestamp lastUpdated;

  SocialPointsModel({
    required this.userId,
    required this.totalStars,
    required this.level,
    required this.pointsByType,
    required this.lastUpdated,
  });

  factory SocialPointsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SocialPointsModel(
      userId: doc.id,
      totalStars: (data['totalStars'] ?? data['totalPoints'] ?? 0).toInt(),
      level: (data['level'] ?? 1).toInt(),
      pointsByType: Map<String, int>.from(data['pointsByType'] ?? {}),
      lastUpdated: data['lastUpdated'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalStars': totalStars,
      'totalPoints': totalStars, // Legacy sync
      'level': level,
      'pointsByType': pointsByType,
      'lastUpdated': lastUpdated,
    };
  }

  int get nextLevelPoints => level * 100;

  // Legacy getter for backward compatibility if needed in UI
  int get totalPoints => totalStars;
}
