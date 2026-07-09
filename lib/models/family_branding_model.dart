import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyBrandingModel {
  final String familyId;
  final String? primaryColor;
  final String? secondaryColor;
  final String? backgroundUrl;
  final String? musicUrl;
  final int backgroundCost; // 1000 gems
  final int musicCost; // 5000 gems
  final bool hasCustomBackground;
  final bool hasCustomMusic;
  final Timestamp? backgroundPurchasedAt;
  final Timestamp? musicPurchasedAt;

  FamilyBrandingModel({
    required this.familyId,
    this.primaryColor,
    this.secondaryColor,
    this.backgroundUrl,
    this.musicUrl,
    this.backgroundCost = 1000,
    this.musicCost = 5000,
    this.hasCustomBackground = false,
    this.hasCustomMusic = false,
    this.backgroundPurchasedAt,
    this.musicPurchasedAt,
  });

  factory FamilyBrandingModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FamilyBrandingModel(
      familyId: doc.id,
      primaryColor: data['primaryColor'],
      secondaryColor: data['secondaryColor'],
      backgroundUrl: data['backgroundUrl'],
      musicUrl: data['musicUrl'],
      backgroundCost: data['backgroundCost'] ?? 1000,
      musicCost: data['musicCost'] ?? 5000,
      hasCustomBackground: data['hasCustomBackground'] ?? false,
      hasCustomMusic: data['hasCustomMusic'] ?? false,
      backgroundPurchasedAt: data['backgroundPurchasedAt'],
      musicPurchasedAt: data['musicPurchasedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'backgroundUrl': backgroundUrl,
      'musicUrl': musicUrl,
      'backgroundCost': backgroundCost,
      'musicCost': musicCost,
      'hasCustomBackground': hasCustomBackground,
      'hasCustomMusic': hasCustomMusic,
      'backgroundPurchasedAt': backgroundPurchasedAt,
      'musicPurchasedAt': musicPurchasedAt,
    };
  }
}
