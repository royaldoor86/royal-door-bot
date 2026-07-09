import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyInvitationModel {
  final String id;
  final String familyId;
  final String familyName;
  final String familyLogo;
  final String familyDescription;
  final String inviterId;
  final String inviterName;
  final String inviteCode;
  final Timestamp createdAt;
  final int totalInvites;
  final int acceptedInvites;
  final int rewardPerInvite; // 2 gems
  final bool isActive;

  FamilyInvitationModel({
    required this.id,
    required this.familyId,
    required this.familyName,
    required this.familyLogo,
    required this.familyDescription,
    required this.inviterId,
    required this.inviterName,
    required this.inviteCode,
    required this.createdAt,
    this.totalInvites = 0,
    this.acceptedInvites = 0,
    this.rewardPerInvite = 2,
    this.isActive = true,
  });

  factory FamilyInvitationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FamilyInvitationModel(
      id: doc.id,
      familyId: data['familyId'] ?? '',
      familyName: data['familyName'] ?? '',
      familyLogo: data['familyLogo'] ?? '',
      familyDescription: data['familyDescription'] ?? '',
      inviterId: data['inviterId'] ?? '',
      inviterName: data['inviterName'] ?? '',
      inviteCode: data['inviteCode'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      totalInvites: data['totalInvites'] ?? 0,
      acceptedInvites: data['acceptedInvites'] ?? 0,
      rewardPerInvite: data['rewardPerInvite'] ?? 2,
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'familyId': familyId,
      'familyName': familyName,
      'familyLogo': familyLogo,
      'familyDescription': familyDescription,
      'inviterId': inviterId,
      'inviterName': inviterName,
      'inviteCode': inviteCode,
      'createdAt': createdAt,
      'totalInvites': totalInvites,
      'acceptedInvites': acceptedInvites,
      'rewardPerInvite': rewardPerInvite,
      'isActive': isActive,
    };
  }
}
