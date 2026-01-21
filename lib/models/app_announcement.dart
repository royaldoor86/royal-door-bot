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
      speed: (data['speed'] ?? 40).toDouble(),
    );
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
