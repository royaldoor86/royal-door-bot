import 'package:cloud_firestore/cloud_firestore.dart';

class AllianceModel {
  final String id;
  final String name;
  final String description;
  final String? logoUrl;
  final String creatorFamilyId;
  final String creatorFamilyName;
  final String status; // 'pending', 'active', 'dissolved'
  final Timestamp createdAt;
  final Timestamp? dissolvedAt;
  final String? dissolvedBy;
  final List<String> memberFamilyIds;
  final Map<String, dynamic> sharedResources;
  final int maxMembers;
  final int maxAlliancesPerFamily;
  final Map<String, dynamic> benefits;
  final String? allianceType; // 'military', 'economic', 'social'
  final Timestamp? lastActivityAt;

  AllianceModel({
    required this.id,
    required this.name,
    required this.description,
    this.logoUrl,
    required this.creatorFamilyId,
    required this.creatorFamilyName,
    required this.status,
    required this.createdAt,
    this.dissolvedAt,
    this.dissolvedBy,
    required this.memberFamilyIds,
    required this.sharedResources,
    this.maxMembers = 5,
    this.maxAlliancesPerFamily = 2,
    required this.benefits,
    this.allianceType,
    this.lastActivityAt,
  });

  factory AllianceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AllianceModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      logoUrl: data['logoUrl'],
      creatorFamilyId: data['creatorFamilyId'] ?? '',
      creatorFamilyName: data['creatorFamilyName'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      dissolvedAt: data['dissolvedAt'],
      dissolvedBy: data['dissolvedBy'],
      memberFamilyIds: List<String>.from(data['memberFamilyIds'] ?? []),
      sharedResources: Map<String, dynamic>.from(data['sharedResources'] ?? {}),
      maxMembers: data['maxMembers'] ?? 5,
      maxAlliancesPerFamily: data['maxAlliancesPerFamily'] ?? 2,
      benefits: Map<String, dynamic>.from(data['benefits'] ?? {}),
      allianceType: data['allianceType'],
      lastActivityAt: data['lastActivityAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'logoUrl': logoUrl,
      'creatorFamilyId': creatorFamilyId,
      'creatorFamilyName': creatorFamilyName,
      'status': status,
      'createdAt': createdAt,
      'dissolvedAt': dissolvedAt,
      'dissolvedBy': dissolvedBy,
      'memberFamilyIds': memberFamilyIds,
      'sharedResources': sharedResources,
      'maxMembers': maxMembers,
      'maxAlliancesPerFamily': maxAlliancesPerFamily,
      'benefits': benefits,
      'allianceType': allianceType,
      'lastActivityAt': lastActivityAt,
    };
  }

  // حساب الموارد المشتركة
  int get totalSharedGems => sharedResources['gems'] ?? 0;
  int get totalSharedStars => sharedResources['stars'] ?? 0;
  int get totalSharedCoins => sharedResources['coins'] ?? 0;

  // الفوائد الافتراضية حسب نوع التحالف
  static Map<String, dynamic> getDefaultBenefits(String allianceType) {
    switch (allianceType) {
      case 'military':
        return {
          'warBonusMultiplier': 1.5,
          'sharedWarPoints': true,
          'allianceWars': true,
          'jointDefense': true,
        };
      case 'economic':
        return {
          'tradeBonusMultiplier': 1.3,
          'sharedTreasury': true,
          'resourceSharing': true,
          'taxReduction': 0.1,
        };
      case 'social':
        return {
          'chatAccess': true,
          'sharedEvents': true,
          'memberVisibility': true,
          'reputationBonus': 1.2,
        };
      default:
        return {
          'basicSharing': true,
          'visibility': true,
        };
    }
  }

  // التحقق من أن العائلة يمكنها الانضمام
  bool canJoin(String familyId, int currentAlliancesCount) {
    if (status != 'active') return false;
    if (memberFamilyIds.contains(familyId)) return false;
    if (memberFamilyIds.length >= maxMembers) return false;
    if (currentAlliancesCount >= maxAlliancesPerFamily) return false;
    return true;
  }

  // هل التحالف نشط؟
  bool get isActive => status == 'active';

  // عدد الأعضاء الحالي
  int get currentMemberCount => memberFamilyIds.length;

  // هل هناك مكان لأعضاء جدد؟
  bool get hasSpace => currentMemberCount < maxMembers;
}
