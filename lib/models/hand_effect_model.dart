import 'package:cloud_firestore/cloud_firestore.dart';

class HandEffectModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String animationUrl;
  final int cost;
  final String currency; // 'gems', 'stars'
  final String type; // 'family', 'global'
  final String? familyId; // if type is 'family'
  final bool isActive;
  final int purchaseCount;
  final Timestamp? createdAt;

  HandEffectModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.animationUrl,
    required this.cost,
    required this.currency,
    required this.type,
    this.familyId,
    this.isActive = true,
    this.purchaseCount = 0,
    this.createdAt,
  });

  factory HandEffectModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HandEffectModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      animationUrl: data['animationUrl'] ?? '',
      cost: data['cost'] ?? 0,
      currency: data['currency'] ?? 'gems',
      type: data['type'] ?? 'global',
      familyId: data['familyId'],
      isActive: data['isActive'] ?? true,
      purchaseCount: data['purchaseCount'] ?? 0,
      createdAt: data['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'animationUrl': animationUrl,
      'cost': cost,
      'currency': currency,
      'type': type,
      'familyId': familyId,
      'isActive': isActive,
      'purchaseCount': purchaseCount,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}
