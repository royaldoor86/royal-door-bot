import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String royalId;
  final String name;
  final String email;
  final String profilePic;
  final int gems;
  final int coins;
  final int botPoints; // نقاط البوت الجديدة
  final String? telegramId; // أيدي التلغرام للربط
  final int agencyGems; 
  final int agencyCoins; 
  final int userLevel;
  final int accountLevel;
  final String bio;
  final String country;
  final String gender;
  final String zodiac;
  final String phoneNumber;
  final List<String> friends;
  final List<String> following;
  final List<String> followers;
  final List<String> tags; 
  final DateTime? birthDate; 
  final int charm; 
  final int wealth; 
  final int contribution; 
  final String nobleLevel; 
  final String? voiceBioUrl; 
  final String? honoraryTitle; 
  final bool isOwner;
  final bool isAgent;
  final bool isBanned;
  final bool isActive;
  final String? currentFrame;
  final String? entryEffect;
  final String? familyId;
  final String? familyRole;
  final String? verificationColor;
  final String? activeBadge; 
  final Map<String, dynamic>? agentData;

  UserModel({
    required this.uid,
    required this.royalId,
    required this.name,
    required this.email,
    this.profilePic = '',
    this.gems = 0,
    this.coins = 0,
    this.botPoints = 0,
    this.telegramId,
    this.agencyGems = 0,
    this.agencyCoins = 0,
    this.userLevel = 1,
    this.accountLevel = 1,
    this.bio = '',
    this.country = '',
    this.gender = 'غير محدد',
    this.zodiac = '',
    this.phoneNumber = '',
    this.friends = const [],
    this.following = const [],
    this.followers = const [],
    this.tags = const [],
    this.birthDate,
    this.charm = 0,
    this.wealth = 0,
    this.contribution = 0,
    this.nobleLevel = 'N1',
    this.voiceBioUrl,
    this.honoraryTitle,
    this.isOwner = false,
    this.isAgent = false,
    this.isBanned = false,
    this.isActive = true,
    this.currentFrame,
    this.entryEffect,
    this.familyId,
    this.familyRole,
    this.verificationColor,
    this.activeBadge,
    this.agentData,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      royalId: data['royalId']?.toString() ?? documentId.substring(0, 8),
      name: data['name'] ?? 'مستخدم جديد',
      email: data['email'] ?? '',
      profilePic: data['profilePic'] ?? '',
      gems: (data['gems'] ?? 0).toInt(),
      coins: (data['coins'] ?? 0).toInt(),
      botPoints: (data['botPoints'] ?? 0).toInt(),
      telegramId: data['telegramId']?.toString(),
      agencyGems: (data['agencyGems'] ?? 0).toInt(),
      agencyCoins: (data['agencyCoins'] ?? 0).toInt(),
      userLevel: (data['userLevel'] ?? 1).toInt(),
      accountLevel: (data['accountLevel'] ?? 1).toInt(),
      bio: data['bio'] ?? '',
      country: data['country'] ?? '',
      gender: data['gender'] ?? 'غير محدد',
      zodiac: data['zodiac'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      friends: List<String>.from(data['friends'] ?? []),
      following: List<String>.from(data['following'] ?? []),
      followers: List<String>.from(data['followers'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      birthDate: data['birthDate'] != null ? (data['birthDate'] as Timestamp).toDate() : null,
      charm: (data['charm'] ?? 0).toInt(),
      wealth: (data['wealth'] ?? 0).toInt(),
      contribution: (data['contribution'] ?? 0).toInt(),
      nobleLevel: data['nobleLevel'] ?? 'N1',
      voiceBioUrl: data['voiceBioUrl'],
      honoraryTitle: data['honoraryTitle'],
      isOwner: data['isOwner'] ?? false,
      isAgent: data['isAgent'] ?? false,
      isBanned: data['isBanned'] ?? false,
      isActive: data['isActive'] ?? true,
      currentFrame: data['currentFrame'],
      entryEffect: data['entryEffect'],
      familyId: data['familyId'],
      familyRole: data['familyRole'],
      verificationColor: data['verificationColor'],
      activeBadge: data['activeBadge'],
      agentData: data['agentData'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'royalId': royalId,
      'name': name,
      'email': email,
      'profilePic': profilePic,
      'gems': gems,
      'coins': coins,
      'botPoints': botPoints,
      'telegramId': telegramId,
      'agencyGems': agencyGems,
      'agencyCoins': agencyCoins,
      'userLevel': userLevel,
      'accountLevel': accountLevel,
      'bio': bio,
      'country': country,
      'gender': gender,
      'zodiac': zodiac,
      'phoneNumber': phoneNumber,
      'friends': friends,
      'following': following,
      'followers': followers,
      'tags': tags,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'charm': charm,
      'wealth': wealth,
      'contribution': contribution,
      'nobleLevel': nobleLevel,
      'voiceBioUrl': voiceBioUrl,
      'honoraryTitle': honoraryTitle,
      'isOwner': isOwner,
      'isAgent': isAgent,
      'isBanned': isBanned,
      'isActive': isActive,
      'currentFrame': currentFrame,
      'entryEffect': entryEffect,
      'familyId': familyId,
      'familyRole': familyRole,
      'verificationColor': verificationColor,
      'activeBadge': activeBadge,
      'agentData': agentData,
      'lastActive': FieldValue.serverTimestamp(),
    };
  }
}
