import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String royalId;
  final String name;
  final String email;
  final String profilePic;
  final int gems;
  final int stars;
  final int agencyGems;
  final int agencyStars;
  final int userLevel;
  final int accountLevel;
  final int royalXP;
  final String bio;
  final String country;
  final String gender;
  final String zodiac;
  final String phoneNumber;
  final List<String> friends;
  final List<String> following;
  final List<String> followers;
  final List<String> blockedUsers;
  final List<String> tags;
  final DateTime? birthDate;
  final int charm;
  final int contribution;
  final String nobleLevel;
  final String? voiceBioUrl;
  final String? honoraryTitle;
  final bool isOwner;
  final bool isAgent;
  final bool isBanned;
  final bool isVerified;
  final bool isPrivate;
  final bool notificationEnabled;
  final bool soundEnabled;
  final bool isActive;
  final DateTime? lastSeen;
  final String? currentFrame;
  final String? entryEffect;
  final String? profileCover;
  final String? chatBubble;
  final String? familyId;
  final String? familyRole;
  final String? verificationColor;
  final String? activeBadge;
  final String? activeVehicleUrl;
  final String? activeVehicleType;
  final Map<String, dynamic>? agentData;
  final Map<String, bool> privilegeSettings;

  final int harvestCoinsWallet;
  final int harvestGemsWallet;
  final double harvestFinancialWallet;
  final double harvestWallet; // محفظة المكافآت المنفصلة
  final double harvestPointsWallet; // محفظة النجوم من المكافآت (Legacy)
  final double harvestStarsWallet; // محفظة النجوم من المكافآت (Modern)
  double get starsHarvestWallet =>
      harvestStarsWallet; // alias for compatibility

  // حقول VIP المطورة
  final String? vipRank;
  final DateTime? vipExpiryDate;

  int get calculatedRoyalLevel {
    final thresholds = [
      0,
      1000,
      3000,
      7000,
      15000,
      40000,
      10000,
      30000,
      50000,
      100000,
      200000,
      400000,
      800000,
      1500000,
      3000000,
      5000000,
      8000000,
      10000000,
      11000000,
      120000000
    ];
    for (int i = thresholds.length - 1; i >= 0; i--) {
      if (royalXP >= thresholds[i]) return i + 1;
    }
    return 1;
  }

  bool get isVipActive {
    if (vipExpiryDate == null) return false;
    return vipExpiryDate!.isAfter(DateTime.now());
  }

  UserModel({
    required this.uid,
    required this.royalId,
    required this.name,
    required this.email,
    this.profilePic = '',
    this.gems = 0,
    this.stars = 0,
    this.agencyGems = 0,
    this.agencyStars = 0,
    this.userLevel = 1,
    this.accountLevel = 1,
    this.royalXP = 0,
    this.bio = '',
    this.country = '',
    this.gender = 'غير محدد',
    this.zodiac = '',
    this.phoneNumber = '',
    this.friends = const [],
    this.following = const [],
    this.followers = const [],
    this.blockedUsers = const [],
    this.tags = const [],
    this.birthDate,
    this.charm = 0,
    this.contribution = 0,
    this.nobleLevel = 'N1',
    this.voiceBioUrl,
    this.honoraryTitle,
    this.isOwner = false,
    this.isAgent = false,
    this.isBanned = false,
    this.isVerified = false,
    this.isPrivate = false,
    this.notificationEnabled = true,
    this.soundEnabled = true,
    this.isActive = true,
    this.lastSeen,
    this.currentFrame,
    this.entryEffect,
    this.profileCover,
    this.chatBubble,
    this.familyId,
    this.familyRole,
    this.verificationColor,
    this.activeBadge,
    this.activeVehicleUrl,
    this.activeVehicleType,
    this.agentData,
    this.privilegeSettings = const {},
    this.harvestCoinsWallet = 0,
    this.harvestGemsWallet = 0,
    this.harvestFinancialWallet = 0.0,
    this.harvestWallet = 0.0,
    this.harvestPointsWallet = 0.0,
    this.harvestStarsWallet = 0.0,
    this.vipRank,
    this.vipExpiryDate,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    // Helper to safely parse numbers from potential strings
    double safeParseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) {
        return double.tryParse(value.replaceAll('%', '')) ?? 0.0;
      }
      return 0.0;
    }

    int safeParseInt(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return UserModel(
      uid: documentId,
      royalId: data['royalId']?.toString() ??
          data['shortId']?.toString() ??
          documentId.substring(0, 8),
      name: data['name'] ?? 'مستخدم جديد',
      email: data['email'] ?? '',
      profilePic: data['profilePic'] ?? '',
      gems: safeParseInt(data['gems']),
      stars: safeParseInt(data['stars'] ?? data['coins']),
      agencyGems: safeParseInt(data['agencyGems']),
      agencyStars: safeParseInt(data['agencyStars'] ?? data['agencyCoins']),
      userLevel: safeParseInt(data['userLevel'] ?? 1),
      accountLevel: safeParseInt(data['accountLevel'] ?? 1),
      royalXP: safeParseInt(data['royalXP']),
      bio: data['bio'] ?? '',
      country: data['country'] ?? '',
      gender: data['gender'] ?? 'غير محدد',
      zodiac: data['zodiac'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      friends: List<String>.from(data['friends'] ?? []),
      following: List<String>.from(data['following'] ?? []),
      followers: List<String>.from(data['followers'] ?? []),
      blockedUsers: List<String>.from(data['blockedUsers'] ?? []),
      tags: List<String>.from(data['tags'] ?? []),
      birthDate: data['birthDate'] != null
          ? (data['birthDate'] as Timestamp).toDate()
          : null,
      charm: safeParseInt(data['charm']),
      contribution: safeParseInt(data['contribution']),
      nobleLevel: data['nobleLevel'] ?? 'N1',
      voiceBioUrl: data['voiceBioUrl'],
      honoraryTitle: data['honoraryTitle'],
      isOwner: data['isOwner'] ?? false,
      isAgent: data['isAgent'] ?? false,
      isBanned: data['isBanned'] ?? false,
      isVerified: data['isVerified'] ?? false,
      isPrivate: data['isPrivate'] ?? false,
      notificationEnabled: data['notificationEnabled'] ?? true,
      soundEnabled: data['soundEnabled'] ?? true,
      isActive: data['isActive'] ?? true,
      lastSeen: data['lastSeen'] != null
          ? (data['lastSeen'] as Timestamp).toDate()
          : (data['lastActive'] != null
              ? (data['lastActive'] as Timestamp).toDate()
              : null),
      currentFrame: data['currentFrame'],
      entryEffect: data['entryEffect'],
      profileCover: data['profileCover'],
      chatBubble: data['chatBubble'],
      familyId: data['familyId'],
      familyRole: data['familyRole'],
      verificationColor: data['verificationColor'],
      activeBadge: data['activeBadge'],
      activeVehicleUrl: data['activeVehicleUrl'],
      activeVehicleType: data['activeVehicleType'],
      agentData: data['agentData'],
      privilegeSettings:
          Map<String, bool>.from(data['privilegeSettings'] ?? {}),
      harvestCoinsWallet: safeParseInt(data['harvest_coins_wallet']),
      harvestGemsWallet: safeParseInt(data['harvest_gems_wallet']),
      harvestFinancialWallet: safeParseDouble(data['harvest_financial_wallet']),
      harvestWallet: safeParseDouble(data['harvest_wallet']),
      harvestPointsWallet: safeParseDouble(data['harvest_points_wallet']),
      harvestStarsWallet: safeParseDouble(
          data['harvest_stars_wallet'] ?? data['harvest_points_wallet']),
      vipRank: data['vipRank'],
      vipExpiryDate: data['vipExpiryDate'] != null
          ? (data['vipExpiryDate'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'royalId': royalId,
      'name': name,
      'email': email,
      'profilePic': profilePic,
      'gems': gems,
      'stars': stars,
      'coins': stars,
      'agencyGems': agencyGems,
      'agencyStars': agencyStars,
      'agencyCoins': agencyStars,
      'userLevel': userLevel,
      'accountLevel': accountLevel,
      'royalXP': royalXP,
      'bio': bio,
      'country': country,
      'gender': gender,
      'zodiac': zodiac,
      'phoneNumber': phoneNumber,
      'friends': friends,
      'following': following,
      'followers': followers,
      'blockedUsers': blockedUsers,
      'tags': tags,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'charm': charm,
      'contribution': contribution,
      'nobleLevel': nobleLevel,
      'voiceBioUrl': voiceBioUrl,
      'honoraryTitle': honoraryTitle,
      'isOwner': isOwner,
      'isAgent': isAgent,
      'isBanned': isBanned,
      'isVerified': isVerified,
      'isPrivate': isPrivate,
      'notificationEnabled': notificationEnabled,
      'soundEnabled': soundEnabled,
      'isActive': isActive,
      'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      'currentFrame': currentFrame,
      'entryEffect': entryEffect,
      'profileCover': profileCover,
      'chatBubble': chatBubble,
      'familyId': familyId,
      'familyRole': familyRole,
      'verificationColor': verificationColor,
      'activeBadge': activeBadge,
      'activeVehicleUrl': activeVehicleUrl,
      'activeVehicleType': activeVehicleType,
      'agentData': agentData,
      'privilegeSettings': privilegeSettings,
      'lastActive': FieldValue.serverTimestamp(),
      'harvest_coins_wallet': harvestCoinsWallet,
      'harvest_gems_wallet': harvestGemsWallet,
      'harvest_financial_wallet': harvestFinancialWallet,
      'harvest_wallet': harvestWallet,
      'harvest_points_wallet': harvestPointsWallet,
      'harvest_stars_wallet': harvestStarsWallet,
      'vipRank': vipRank,
      'vipExpiryDate':
          vipExpiryDate != null ? Timestamp.fromDate(vipExpiryDate!) : null,
    };
  }
}
