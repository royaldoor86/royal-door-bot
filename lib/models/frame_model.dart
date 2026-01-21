import 'package:cloud_firestore/cloud_firestore.dart';

class FrameModel {
  final String id;
  final String name;
  final String imageUrl; // Animated GIF or PNG URL
  final int price;
  final bool isActive;
  final bool onSale;
  final int salePrice;
  final bool isAnimated;
  final String sourceType; // 'upload' or 'link'
  final String? visibleForVip; // مرئي لاسم مستوى VIP محدد (String)
  final int? minVipLevel; // مرئي لمستوى VIP محدد وما فوق (int)
  final bool isProfileFrame;
  final bool isFamilyFrame; // إطار خاص بالعائلات
  final String format; // png, gif, webp

  FrameModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.price,
    this.isActive = true,
    this.onSale = false,
    this.salePrice = 0,
    this.isAnimated = false,
    this.sourceType = 'upload',
    this.visibleForVip,
    this.minVipLevel,
    this.isProfileFrame = false,
    this.isFamilyFrame = false,
    this.format = 'png',
  });

  int get effectivePrice => onSale && salePrice > 0 ? salePrice : price;

  factory FrameModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return FrameModel(
      id: doc.id,
      name: data['name'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      price: (data['price'] ?? 0).toInt(),
      isActive: data['isActive'] ?? true,
      onSale: data['onSale'] ?? false,
      salePrice: (data['salePrice'] ?? 0).toInt(),
      isAnimated: data['isAnimated'] ?? false,
      sourceType: data['sourceType'] ?? 'upload',
      visibleForVip: data['visibleForVip'],
      minVipLevel: data['minVipLevel'] != null ? (data['minVipLevel'] as num).toInt() : null,
      isProfileFrame: data['isProfileFrame'] ?? false,
      isFamilyFrame: data['isFamilyFrame'] ?? false,
      format: data['format'] ?? 'png',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'price': price,
      'isActive': isActive,
      'onSale': onSale,
      'salePrice': salePrice,
      'isAnimated': isAnimated,
      'sourceType': sourceType,
      'visibleForVip': visibleForVip,
      'minVipLevel': minVipLevel,
      'isProfileFrame': isProfileFrame,
      'isFamilyFrame': isFamilyFrame,
      'format': format,
    };
  }
}
