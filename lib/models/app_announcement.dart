// lib/models/app_announcement.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class AppAnnouncement {
  final String text;        // نص الإعلان
  final bool isActive;      // تفعيل/تعطيل
  final String? imageUrl;   // صورة صغيرة (اختياري)
  final double speed;       // سرعة حركة الشريط

  AppAnnouncement({
    required this.text,
    required this.isActive,
    this.imageUrl,
    required this.speed,
  });

  factory AppAnnouncement.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return AppAnnouncement(
      text: data['text'] ?? '',
      isActive: data['isActive'] ?? false,
      imageUrl: data['imageUrl'],
      speed: _parseDouble(data['speed'] ?? 40),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll('%', '')) ?? 0.0;
    }
    return 0.0;
  }

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isActive': isActive,
      'imageUrl': imageUrl,
      'speed': speed,
    };
  }
}
