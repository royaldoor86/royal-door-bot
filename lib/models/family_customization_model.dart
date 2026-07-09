import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyCustomizationModel {
  final String id;
  final String familyId;
  final String theme; // 'dark', 'light', 'royal', 'nature', 'ocean'
  final String primaryColor; // لون أساسي
  final String secondaryColor; // لون ثانوي
  final String? logoUrl; // رابط الشعار
  final String? bannerUrl; // رابط البانر
  final Map<String, dynamic> customSettings; // إعدادات مخصصة
  final Timestamp createdAt;
  final Timestamp updatedAt;

  FamilyCustomizationModel({
    required this.id,
    required this.familyId,
    required this.theme,
    required this.primaryColor,
    required this.secondaryColor,
    this.logoUrl,
    this.bannerUrl,
    required this.customSettings,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FamilyCustomizationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FamilyCustomizationModel(
      id: doc.id,
      familyId: data['familyId'] ?? '',
      theme: data['theme'] ?? 'dark',
      primaryColor: data['primaryColor'] ?? '#FFD700',
      secondaryColor: data['secondaryColor'] ?? '#1A050E',
      logoUrl: data['logoUrl'],
      bannerUrl: data['bannerUrl'],
      customSettings: Map<String, dynamic>.from(data['customSettings'] ?? {}),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'familyId': familyId,
      'theme': theme,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'logoUrl': logoUrl,
      'bannerUrl': bannerUrl,
      'customSettings': customSettings,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // السمات الافتراضية لكل موضوع
  static Map<String, dynamic> getDefaultThemeSettings(String theme) {
    switch (theme) {
      case 'dark':
        return {
          'primaryColor': '#FFD700',
          'secondaryColor': '#1A050E',
          'backgroundColor': '#1A050E',
          'cardColor': '#3D0B16',
          'textColor': '#FFFFFF',
        };
      case 'light':
        return {
          'primaryColor': '#FFD700',
          'secondaryColor': '#FFFFFF',
          'backgroundColor': '#FFFFFF',
          'cardColor': '#F5F5F5',
          'textColor': '#000000',
        };
      case 'royal':
        return {
          'primaryColor': '#FFD700',
          'secondaryColor': '#4A0E1C',
          'backgroundColor': '#4A0E1C',
          'cardColor': '#6B1830',
          'textColor': '#FFFFFF',
        };
      case 'nature':
        return {
          'primaryColor': '#4CAF50',
          'secondaryColor': '#2E7D32',
          'backgroundColor': '#1B5E20',
          'cardColor': '#388E3C',
          'textColor': '#FFFFFF',
        };
      case 'ocean':
        return {
          'primaryColor': '#2196F3',
          'secondaryColor': '#0D47A1',
          'backgroundColor': '#01579B',
          'cardColor': '#1976D2',
          'textColor': '#FFFFFF',
        };
      default:
        return {
          'primaryColor': '#FFD700',
          'secondaryColor': '#1A050E',
          'backgroundColor': '#1A050E',
          'cardColor': '#3D0B16',
          'textColor': '#FFFFFF',
        };
    }
  }

  // الحصول على اسم الموضوع بالعربية
  String getThemeNameAr() {
    switch (theme) {
      case 'dark':
        return 'داكن';
      case 'light':
        return 'فاتح';
      case 'royal':
        return 'ملكي';
      case 'nature':
        return 'طبيعي';
      case 'ocean':
        return 'بحري';
      default:
        return 'افتراضي';
    }
  }
}
