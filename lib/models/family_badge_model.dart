import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyBadgeModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String type; // 'purchase', 'war_reward', 'contributor'
  final int cost; // for purchase type
  final int minContribution; // for contributor type
  final String? warId; // for war reward type
  final Timestamp? createdAt;
  final bool isActive;

  FamilyBadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.type,
    this.cost = 0,
    this.minContribution = 0,
    this.warId,
    this.createdAt,
    this.isActive = true,
  });

  factory FamilyBadgeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FamilyBadgeModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      type: data['type'] ?? 'purchase',
      cost: data['cost'] ?? 0,
      minContribution: data['minContribution'] ?? 0,
      warId: data['warId'],
      createdAt: data['createdAt'],
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'type': type,
      'cost': cost,
      'minContribution': minContribution,
      'warId': warId,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'isActive': isActive,
    };
  }
}
