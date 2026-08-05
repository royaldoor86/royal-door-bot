import 'package:cloud_firestore/cloud_firestore.dart';

class SocialPointsModel {
  final String userId;
  final int totalCoins; // Renamed from totalStars/totalPoints
  final int level;
  final Map<String, int> pointsByType; // e.g., {'follow': 10, 'like': 5}
  final Timestamp lastUpdated;

  SocialPointsModel({
    required this.userId,
    required this.totalCoins,
    required this.level,
    required this.pointsByType,
    required this.lastUpdated,
  });

  factory SocialPointsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SocialPointsModel(
      userId: doc.id,
      totalCoins: (data['totalCoins'] ?? data['totalStars'] ?? data['totalPoints'] ?? 0).toInt(),
      level: (data['level'] ?? 1).toInt(),
      pointsByType: Map<String, int>.from(data['pointsByType'] ?? {}),
      lastUpdated: data['lastUpdated'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalCoins': totalCoins,
      'totalStars': totalCoins, // Legacy sync
      'totalPoints': totalCoins, // Legacy sync
      'level': level,
      'pointsByType': pointsByType,
      'lastUpdated': lastUpdated,
    };
  }

  int get nextLevelPoints => level * 100;
}
