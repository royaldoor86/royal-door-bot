import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum VIPLevel {
  none,
  bronze,
  silver,
  gold,
  platinum,
}

class VIPStatus {
  final VIPLevel level;
  final DateTime? activatedAt;
  final DateTime? expiresAt;
  final int totalSpent;
  final int activityPoints;
  final Map<String, dynamic>? metadata;

  VIPStatus({
    required this.level,
    this.activatedAt,
    this.expiresAt,
    this.totalSpent = 0,
    this.activityPoints = 0,
    this.metadata,
  });

  factory VIPStatus.fromMap(Map<String, dynamic> data) {
    return VIPStatus(
      level: _parseLevel(data['level']),
      activatedAt: (data['activatedAt'] as Timestamp?)?.toDate(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
      totalSpent: data['totalSpent'] ?? 0,
      activityPoints: data['activityPoints'] ?? 0,
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'level': level.name,
      'activatedAt':
          activatedAt != null ? Timestamp.fromDate(activatedAt!) : null,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
      'totalSpent': totalSpent,
      'activityPoints': activityPoints,
      'metadata': metadata,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  static VIPLevel _parseLevel(String? level) {
    if (level == null) return VIPLevel.none;
    return VIPLevel.values.firstWhere(
      (e) => e.name == level,
      orElse: () => VIPLevel.none,
    );
  }

  bool get isActive => level != VIPLevel.none;
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  int get daysUntilExpiry {
    if (expiresAt == null) return 0;
    return expiresAt!.difference(DateTime.now()).inDays;
  }

  // VIP Benefits
  double get harvestBonus {
    switch (level) {
      case VIPLevel.none:
        return 0.0;
      case VIPLevel.bronze:
        return 0.05; // 5% bonus
      case VIPLevel.silver:
        return 0.10; // 10% bonus
      case VIPLevel.gold:
        return 0.15; // 15% bonus
      case VIPLevel.platinum:
        return 0.25; // 25% bonus
    }
  }

  double get conversionBonus {
    switch (level) {
      case VIPLevel.none:
        return 0.0;
      case VIPLevel.bronze:
        return 0.03; // 3% bonus
      case VIPLevel.silver:
        return 0.06; // 6% bonus
      case VIPLevel.gold:
        return 0.10; // 10% bonus
      case VIPLevel.platinum:
        return 0.15; // 15% bonus
    }
  }

  int get maxActivePackages {
    switch (level) {
      case VIPLevel.none:
        return 3;
      case VIPLevel.bronze:
        return 5;
      case VIPLevel.silver:
        return 7;
      case VIPLevel.gold:
        return 10;
      case VIPLevel.platinum:
        return 15;
    }
  }

  String get levelName {
    switch (level) {
      case VIPLevel.none:
        return 'غير VIP';
      case VIPLevel.bronze:
        return 'برونزي';
      case VIPLevel.silver:
        return 'فضي';
      case VIPLevel.gold:
        return 'ذهبي';
      case VIPLevel.platinum:
        return 'بلاتيني';
    }
  }

  String get levelIcon {
    switch (level) {
      case VIPLevel.none:
        return '👤';
      case VIPLevel.bronze:
        return '🥉';
      case VIPLevel.silver:
        return '🥈';
      case VIPLevel.gold:
        return '🥇';
      case VIPLevel.platinum:
        return '💎';
    }
  }

  Color get levelColor {
    switch (level) {
      case VIPLevel.none:
        return Colors.grey;
      case VIPLevel.bronze:
        return const Color(0xFFCD7F32);
      case VIPLevel.silver:
        return const Color(0xFFC0C0C0);
      case VIPLevel.gold:
        return const Color(0xFFFFD700);
      case VIPLevel.platinum:
        return const Color(0xFFE5E4E2);
    }
  }

  // Calculate required points for next level
  int get pointsToNextLevel {
    switch (level) {
      case VIPLevel.none:
        return 1000;
      case VIPLevel.bronze:
        return 5000;
      case VIPLevel.silver:
        return 15000;
      case VIPLevel.gold:
        return 50000;
      case VIPLevel.platinum:
        return 0; // Max level
    }
  }

  VIPStatus copyWith({
    VIPLevel? level,
    DateTime? activatedAt,
    DateTime? expiresAt,
    int? totalSpent,
    int? activityPoints,
    Map<String, dynamic>? metadata,
  }) {
    return VIPStatus(
      level: level ?? this.level,
      activatedAt: activatedAt ?? this.activatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      totalSpent: totalSpent ?? this.totalSpent,
      activityPoints: activityPoints ?? this.activityPoints,
      metadata: metadata ?? this.metadata,
    );
  }
}

// VIP Package configurations
class VIPPackage {
  final String id;
  final String name;
  final VIPLevel level;
  final int durationDays;
  final double price;
  final String currency;
  final List<String> benefits;

  VIPPackage({
    required this.id,
    required this.name,
    required this.level,
    required this.durationDays,
    required this.price,
    required this.currency,
    required this.benefits,
  });

  factory VIPPackage.fromMap(Map<String, dynamic> data, String id) {
    return VIPPackage(
      id: id,
      name: data['name'] ?? '',
      level: VIPStatus._parseLevel(data['level']),
      durationDays: data['durationDays'] ?? 30,
      price: (data['price'] ?? 0).toDouble(),
      currency: data['currency'] ?? 'gems',
      benefits: List<String>.from(data['benefits'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'level': level.name,
      'durationDays': durationDays,
      'price': price,
      'currency': currency,
      'benefits': benefits,
    };
  }
}

class VIPPackages {
  static List<VIPPackage> get defaultPackages => [
        VIPPackage(
          id: 'vip_bronze_30',
          name: 'برونزي 30 يوم',
          level: VIPLevel.bronze,
          durationDays: 30,
          price: 5000,
          currency: 'gems',
          benefits: [
            '5% مكافأة إضافية على الحصاد',
            'حتى 5 باقات نشطة',
            '3% مكافأة على التحويل',
          ],
        ),
        VIPPackage(
          id: 'vip_silver_30',
          name: 'فضي 30 يوم',
          level: VIPLevel.silver,
          durationDays: 30,
          price: 15000,
          currency: 'gems',
          benefits: [
            '10% مكافأة إضافية على الحصاد',
            'حتى 7 باقات نشطة',
            '6% مكافأة على التحويل',
          ],
        ),
        VIPPackage(
          id: 'vip_gold_30',
          name: 'ذهبي 30 يوم',
          level: VIPLevel.gold,
          durationDays: 30,
          price: 35000,
          currency: 'gems',
          benefits: [
            '15% مكافأة إضافية على الحصاد',
            'حتى 10 باقات نشطة',
            '10% مكافأة على التحويل',
          ],
        ),
        VIPPackage(
          id: 'vip_platinum_30',
          name: 'بلاتيني 30 يوم',
          level: VIPLevel.platinum,
          durationDays: 30,
          price: 75000,
          currency: 'gems',
          benefits: [
            '25% مكافأة إضافية على الحصاد',
            'حتى 15 باقة نشطة',
            '15% مكافأة على التحويل',
            'أولوية في الدعم',
          ],
        ),
      ];
}
