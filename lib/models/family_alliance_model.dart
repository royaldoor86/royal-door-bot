import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyAllianceModel {
  final String id;
  final String name;
  final String description;
  final String familyId1;
  final String familyId2;
  final String familyName1;
  final String familyName2;
  final String familyLogo1;
  final String familyLogo2;
  final String status; // 'pending', 'active', 'rejected', 'dissolved'
  final Timestamp? createdAt;
  final Timestamp? dissolvedAt;
  final String? dissolvedBy;

  FamilyAllianceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.familyId1,
    required this.familyId2,
    required this.familyName1,
    required this.familyName2,
    required this.familyLogo1,
    required this.familyLogo2,
    required this.status,
    this.createdAt,
    this.dissolvedAt,
    this.dissolvedBy,
  });

  factory FamilyAllianceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FamilyAllianceModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      familyId1: data['familyId1'] ?? '',
      familyId2: data['familyId2'] ?? '',
      familyName1: data['familyName1'] ?? '',
      familyName2: data['familyName2'] ?? '',
      familyLogo1: data['familyLogo1'] ?? '',
      familyLogo2: data['familyLogo2'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'],
      dissolvedAt: data['dissolvedAt'],
      dissolvedBy: data['dissolvedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'familyId1': familyId1,
      'familyId2': familyId2,
      'familyName1': familyName1,
      'familyName2': familyName2,
      'familyLogo1': familyLogo1,
      'familyLogo2': familyLogo2,
      'status': status,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'dissolvedAt': dissolvedAt,
      'dissolvedBy': dissolvedBy,
    };
  }
}
