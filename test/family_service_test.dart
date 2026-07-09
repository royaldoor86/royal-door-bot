import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:royaldoor/models/family_model.dart';

void main() {
  group('Family Model Tests', () {
    test('calculateMaxMembers returns correct values', () {
      expect(FamilyModel.calculateMaxMembers(1), 55);
      expect(FamilyModel.calculateMaxMembers(2), 60);
      expect(FamilyModel.calculateMaxMembers(5), 75);
      expect(FamilyModel.calculateMaxMembers(10), 100);
    });

    test('FamilyModel basic functionality', () {
      final family = FamilyModel(
        id: 'test_family',
        name: 'Test Family',
        logoUrl: '',
        description: 'A test family',
        creatorId: 'leader123',
        level: 3,
        maxMembers: 75,
        createdAt: Timestamp.now(),
      );

      expect(family.id, 'test_family');
      expect(family.name, 'Test Family');
      expect(family.level, 3);
      expect(family.maxMembers, 75);
      expect(family.creatorId, 'leader123');
    });

    test('FamilyModel toMap works', () {
      final original = FamilyModel(
        id: 'test_family',
        name: 'Test Family',
        logoUrl: '',
        description: 'A test family',
        creatorId: 'leader123',
        level: 2,
        maxMembers: 60,
        createdAt: Timestamp.now(),
      );

      final map = original.toMap();
      expect(map['name'], 'Test Family');
      expect(map['level'], 2);
      expect(map['maxMembers'], 60);
      expect(map['creatorId'], 'leader123');
    });

    test('Family level progression', () {
      final family = FamilyModel(
        id: 'test',
        name: 'Test',
        logoUrl: '',
        description: '',
        creatorId: 'creator',
        createdAt: Timestamp.now(),
        level: 2,
      );

      // Test next level points calculation
      expect(family.nextLevelPoints, 2 * 2 * 10000); // level^2 * 10000
    });
  });
}
