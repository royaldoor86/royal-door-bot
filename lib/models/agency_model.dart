import 'package:cloud_firestore/cloud_firestore.dart';

enum AgencyType { reseller, hosting }

class AgencyModel {
  final String id;
  final String ownerId;
  final String ownerName;
  final String name;
  final String logoUrl;
  final AgencyType type;
  final int balance; // For reseller agents
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
    this.memberCount = 0,
    this.commissionRate = 0.1, // Default 10%
    this.isActive = true,
    required this.createdAt,
  });

  factory AgencyModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AgencyModel(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      ownerName: data['ownerName'] ?? '',
      name: data['name'] ?? '',
      logoUrl: data['logoUrl'] ?? '',
      type: (data['type'] == 'reseller') ? AgencyType.reseller : AgencyType.hosting,
      balance: (data['balance'] ?? 0).toInt(),
      memberCount: (data['memberCount'] ?? 0).toInt(),
      commissionRate: (data['commissionRate'] ?? 0.1).toDouble(),
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
      'memberCount': memberCount,
      'commissionRate': commissionRate,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }
}
