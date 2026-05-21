import 'package:cloud_firestore/cloud_firestore.dart';

class FrameModel {
  final String id;
  final String name;
  final String imageUrl; // Animated GIF, PNG, WebP or JSON Lottie URL
  final int price;
  final bool isActive;
  final bool onSale;
  final int salePrice;
  final bool isAnimated;
  final String sourceType; // 'upload' or 'link'
  final String? visibleForVip;
  final int? minVipLevel;
  final bool isProfileFrame;
  final bool isFamilyFrame;
  final String format; // png, gif, webp, json

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

  // دالة ذكية لتحديد الصيغة تلقائياً من الرابط إذا لم تكن محددة
  static String getFormatFromUrl(String url) {
    if (url.contains('.json')) return 'json';
    if (url.contains('.gif')) return 'gif';
    if (url.contains('.webp')) return 'webp';
    return 'png';
  }

  factory FrameModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    String url = data['imageUrl'] ?? '';
    return FrameModel(
      id: doc.id,
      name: data['name'] ?? '',
      imageUrl: url,
      price: (data['price'] ?? 0).toInt(),
      isActive: data['isActive'] ?? true,
      onSale: data['onSale'] ?? false,
      salePrice: (data['salePrice'] ?? 0).toInt(),
      isAnimated: data['isAnimated'] ?? (url.contains('.gif') || url.contains('.json') || url.contains('.webp')),
      sourceType: data['sourceType'] ?? 'upload',
      visibleForVip: data['visibleForVip'],
      minVipLevel: data['minVipLevel'] != null ? (data['minVipLevel'] as num).toInt() : null,
      isProfileFrame: data['isProfileFrame'] ?? false,
      isFamilyFrame: data['isFamilyFrame'] ?? false,
      format: data['format'] ?? getFormatFromUrl(url),
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
