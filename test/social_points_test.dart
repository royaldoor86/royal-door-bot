import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:royaldoor/models/social_points_model.dart';

void main() {
  group('Social Points Model Tests', () {
    test('SocialPointsModel basic functionality', () {
      final model = SocialPointsModel(
        userId: 'test_user',
        totalStars: 150,
        level: 2,
        pointsByType: {'follow_given': 10, 'like_received': 20},
        lastUpdated: Timestamp.now(),
      );

      expect(model.totalPoints, 150);
      expect(model.level, 2);
      expect(model.nextLevelPoints, 200);
      expect(model.pointsByType['follow_given'], 10);
      expect(model.pointsByType['like_received'], 20);
    });

    test('SocialPointsModel toMap works', () {
      final original = SocialPointsModel(
        userId: 'test_user',
        totalStars: 150,
        level: 2,
        pointsByType: {'follow_given': 10},
        lastUpdated: Timestamp.now(),
      );

      final map = original.toMap();
      expect(map['totalPoints'], 150);
      expect(map['level'], 2);
      expect(map['pointsByType']['follow_given'], 10);
    });

    test('Level progression calculation', () {
      // Level 1 requires 100 points
      expect(
          SocialPointsModel(
            userId: 'test',
            totalStars: 50,
            level: 1,
            pointsByType: {},
            lastUpdated: Timestamp.now(),
          ).nextLevelPoints,
          100);

      // Level 2 requires 200 points
      expect(
          SocialPointsModel(
            userId: 'test',
            totalStars: 150,
            level: 2,
            pointsByType: {},
            lastUpdated: Timestamp.now(),
          ).nextLevelPoints,
          200);
    });
  });
}
