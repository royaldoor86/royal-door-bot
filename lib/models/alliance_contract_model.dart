import 'package:cloud_firestore/cloud_firestore.dart';

class AllianceContractModel {
  final String id;
  final String allianceId;
  final String allianceName;
  final String familyId;
  final String familyName;
  final String contractType; // 'mutual_defense', 'resource_sharing', 'trade', 'full_alliance'
  final String status; // 'pending', 'active', 'rejected', 'expired', 'terminated'
  final Timestamp createdAt;
  final Timestamp? signedAt;
  final Timestamp? expiresAt;
  final Map<String, dynamic> terms;
  final List<String> signatories;
  final String? createdBy;
  final String? terminatedBy;
  final Timestamp? terminatedAt;
  final String? terminationReason;

  AllianceContractModel({
    required this.id,
    required this.allianceId,
    required this.allianceName,
    required this.familyId,
    required this.familyName,
    required this.contractType,
    required this.status,
    required this.createdAt,
    this.signedAt,
    this.expiresAt,
    required this.terms,
    required this.signatories,
    this.createdBy,
    this.terminatedBy,
    this.terminatedAt,
    this.terminationReason,
  });

  factory AllianceContractModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AllianceContractModel(
      id: doc.id,
      allianceId: data['allianceId'] ?? '',
      allianceName: data['allianceName'] ?? '',
      familyId: data['familyId'] ?? '',
      familyName: data['familyName'] ?? '',
      contractType: data['contractType'] ?? 'full_alliance',
      status: data['status'] ?? 'pending',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      signedAt: data['signedAt'],
      expiresAt: data['expiresAt'],
      terms: Map<String, dynamic>.from(data['terms'] ?? {}),
      signatories: List<String>.from(data['signatories'] ?? []),
      createdBy: data['createdBy'],
      terminatedBy: data['terminatedBy'],
      terminatedAt: data['terminatedAt'],
      terminationReason: data['terminationReason'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'allianceId': allianceId,
      'allianceName': allianceName,
      'familyId': familyId,
      'familyName': familyName,
      'contractType': contractType,
      'status': status,
      'createdAt': createdAt,
      'signedAt': signedAt,
      'expiresAt': expiresAt,
      'terms': terms,
      'signatories': signatories,
      'createdBy': createdBy,
      'terminatedBy': terminatedBy,
      'terminatedAt': terminatedAt,
      'terminationReason': terminationReason,
    };
  }

  // الشروط الافتراضية لكل نوع عقد
  static Map<String, dynamic> getDefaultTerms(String contractType) {
    switch (contractType) {
      case 'mutual_defense':
        return {
          'defenseSupport': true,
          'warAssistance': true,
          'resourceSharing': false,
          'tradeBenefits': false,
          'durationDays': 30,
          'autoRenew': false,
        };
      case 'resource_sharing':
        return {
          'defenseSupport': false,
          'warAssistance': false,
          'resourceSharing': true,
          'tradeBenefits': true,
          'durationDays': 60,
          'autoRenew': true,
          'resourceLimit': 10000,
        };
      case 'trade':
        return {
          'defenseSupport': false,
          'warAssistance': false,
          'resourceSharing': false,
          'tradeBenefits': true,
          'durationDays': 90,
          'autoRenew': true,
          'tradeDiscount': 0.15,
        };
      case 'full_alliance':
      default:
        return {
          'defenseSupport': true,
          'warAssistance': true,
          'resourceSharing': true,
          'tradeBenefits': true,
          'durationDays': 180,
          'autoRenew': true,
          'resourceLimit': 50000,
          'tradeDiscount': 0.25,
          'sharedWars': true,
        };
    }
  }

  // التحقق من صلاحية العقد
  bool get isValid {
    if (status != 'active') return false;
    if (expiresAt != null && expiresAt!.compareTo(Timestamp.now()) < 0) return false;
    return true;
  }

  // التحقق من انتهاء العقد
  bool get isExpired {
    if (expiresAt == null) return false;
    return expiresAt!.compareTo(Timestamp.now()) < 0;
  }

  // الحصول على اسم نوع العقد بالعربية
  String getContractTypeNameAr() {
    switch (contractType) {
      case 'mutual_defense':
        return 'دفاع مشترك';
      case 'resource_sharing':
        return 'مشاركة موارد';
      case 'trade':
        return 'تجارة';
      case 'full_alliance':
        return 'تحالف كامل';
      default:
        return 'غير معروف';
    }
  }

  // الحصول على اسم الحالة بالعربية
  String getStatusNameAr() {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'active':
        return 'نشط';
      case 'rejected':
        return 'مرفوض';
      case 'expired':
        return 'منتهي';
      case 'terminated':
        return 'ملغي';
      default:
        return 'غير معروف';
    }
  }

  // التوقيع على العقد
  AllianceContractModel signContract(String userId) {
    final newSignatories = List<String>.from(signatories);
    if (!newSignatories.contains(userId)) {
      newSignatories.add(userId);
    }

    return AllianceContractModel(
      id: id,
      allianceId: allianceId,
      allianceName: allianceName,
      familyId: familyId,
      familyName: familyName,
      contractType: contractType,
      status: status,
      createdAt: createdAt,
      signedAt: Timestamp.now(),
      expiresAt: expiresAt,
      terms: terms,
      signatories: newSignatories,
      createdBy: createdBy,
      terminatedBy: terminatedBy,
      terminatedAt: terminatedAt,
      terminationReason: terminationReason,
    );
  }

  // إلغاء العقد
  AllianceContractModel terminateContract(String userId, String reason) {
    return AllianceContractModel(
      id: id,
      allianceId: allianceId,
      allianceName: allianceName,
      familyId: familyId,
      familyName: familyName,
      contractType: contractType,
      status: 'terminated',
      createdAt: createdAt,
      signedAt: signedAt,
      expiresAt: expiresAt,
      terms: terms,
      signatories: signatories,
      createdBy: createdBy,
      terminatedBy: userId,
      terminatedAt: Timestamp.now(),
      terminationReason: reason,
    );
  }
}
