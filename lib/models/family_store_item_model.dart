import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyStoreItemModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final int cost;
  final int? saleCost; // سعر العرض/الخصم
  final String currency; // 'family_gems', 'family_stars'
  final String
      type; // 'hand_effect', 'hand_id', 'entertainment', 'perk', 'badge'
  final String? effectId; // for hand_effect type
  final int? durationDays; // for perks
  final String? handNumber; // for hand_effect type - رقم الإيد
  final String? handLetters; // for hand_effect type - حروف الإيد
  final bool isActive;
  final int purchaseCount;
  final Timestamp? createdAt;

  FamilyStoreItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.cost,
    this.saleCost,
    required this.currency,
    required this.type,
    this.effectId,
    this.durationDays,
    this.handNumber,
    this.handLetters,
    this.isActive = true,
    this.purchaseCount = 0,
    this.createdAt,
  });

  factory FamilyStoreItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FamilyStoreItemModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      cost: data['cost'] ?? 0,
      saleCost: data['saleCost'],
      currency: data['currency'] ?? 'family_gems',
      type: data['type'] ?? 'perk',
      effectId: data['effectId'],
      durationDays: data['durationDays'],
      handNumber: data['handNumber'],
      handLetters: data['handLetters'],
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
      'cost': cost,
      'saleCost': saleCost,
      'currency': currency,
      'type': type,
      'effectId': effectId,
      'durationDays': durationDays,
      'handNumber': handNumber,
      'handLetters': handLetters,
      'isActive': isActive,
      'purchaseCount': purchaseCount,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }
}
