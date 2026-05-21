import 'package:cloud_firestore/cloud_firestore.dart';

enum AgencyType { reseller, hosting }

class AgencyModel {
  final String id;
  final String ownerId;
  final String ownerName;
  final String name;
  final String logoUrl;
  final AgencyType type;
  final int balance; // For reseller agents (Gems)
  final int agencyStars; // New field
  final int agencyCoins; // Legacy field
  final int memberCount;
  final double commissionRate;
  final bool isActive;
  final Timestamp createdAt;

  AgencyModel({
    required this.id,
    required this.ownerId,
    required this.ownerName,
    required this.name,
    required this.logoUrl,
    required this.type,
    this.balance = 0,
    this.agencyStars = 0,
    this.agencyCoins = 0,
    this.memberCount = 0,
    this.commissionRate = 0.1, // Default 10%
    this.isActive = true,
    required this.createdAt,
  });

  factory AgencyModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return AgencyModel(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? '',
      name: data['name'] ?? '',
      logoUrl: data['logoUrl'] ?? '',
      type: (data['type'] == 'reseller') ? AgencyType.reseller : AgencyType.hosting,
      balance: parseInt(data['balance']),
      agencyStars: parseInt(data['agencyStars'] ?? data['agencyCoins'] ?? 0),
      agencyCoins: parseInt(data['agencyCoins'] ?? data['agencyStars'] ?? 0),
      memberCount: parseInt(data['memberCount']),
      commissionRate: parseDouble(data['commissionRate'] ?? 0.1),
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'ownerName': ownerName,
      'name': name,
      'logoUrl': logoUrl,
      'type': type == AgencyType.reseller ? 'reseller' : 'hosting',
      'balance': balance,
      'agencyStars': agencyStars,
      'agencyCoins': agencyCoins,
      'memberCount': memberCount,
      'commissionRate': commissionRate,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }
}
