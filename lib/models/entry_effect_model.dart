import 'package:cloud_firestore/cloud_firestore.dart';

class EntryEffectModel {
  final String id;
  final String name;
  final String lottieUrl; // URL for Lottie animation
  final String soundUrl;  // Optional sound effect
  final int price;
  final bool isActive;

  EntryEffectModel({
    required this.id,
    required this.name,
    required this.lottieUrl,
    this.soundUrl = '',
    required this.price,
    this.isActive = true,
  });

  factory EntryEffectModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return EntryEffectModel(
      id: doc.id,
      name: data['name'] ?? '',
      lottieUrl: data['lottieUrl'] ?? '',
      soundUrl: data['soundUrl'] ?? '',
      price: (data['price'] ?? 0).toInt(),
      isActive: data['isActive'] ?? true,
    );
  }
}
