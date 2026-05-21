import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyModel {
  final String id;
  final String name;
  final String logoUrl;
  final String description;
  final String slogan; // شعار العائلة القصير
  final String creatorId;
  final String? roomId; // المعرف الخاص بغرفة العائلة الرسمية
  final int totalExp;
  final int dailyExp; // الخبرة اليومية للتنافس
  final int weeklyExp; // الخبرة الأسبوعية
  final int monthlyExp; // الخبرة الشهرية
  final int memberCount;
  final int maxMembers; // الحد الأقصى للأعضاء بناءً على المستوى
  final int level;
  final int minLevelToJoin; // الحد الأدنى لليفل المستخدم للانضمام
  final Timestamp createdAt;
  final bool isVerified; // هل العائلة موثقة من الإدارة

  // التحسينات الجديدة
  final int familyGems; // محفظة الجواهر المشتركة
  final int familyStars; // محفظة النجوم المشتركة
  int get familyCoins => familyStars; // مزامنة مع الاسم القديم
  final String? activeBadgeId; // شارة العائلة النشطة
  final Map<String, dynamic> perks; // المزايا المفعلة (مثل تأثيرات الدخول)
  final bool isPrivate; // هل العائلة خاصة (تتطلب طلب انضمام)

  // إحصائيات الحروب (Family Wars)
  final int warWins;
  final int warLosses;
  final int warExp; // خبرة (XP) الترتيب في الحروب

  // نظام الرتب والتصنيف
  final Map<String, String>
      memberRanks; // userId -> rank (e.g., 'warrior', 'contributor')

  FamilyModel({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.description,
    this.slogan = '',
    required this.creatorId,
    this.roomId,
    this.totalExp = 0,
    this.dailyExp = 0,
    this.weeklyExp = 0,
    this.monthlyExp = 0,
    this.memberCount = 1,
    this.maxMembers = 50,
    this.level = 1,
    this.minLevelToJoin = 1,
    required this.createdAt,
    this.isVerified = false,
    this.familyGems = 0,
    this.familyStars = 0,
    this.activeBadgeId,
    this.perks = const {},
    this.isPrivate = false,
    this.warWins = 0,
    this.warLosses = 0,
    this.warExp = 0,
    this.memberRanks = const {},
  });

  factory FamilyModel.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return FamilyModel(
      id: doc.id,
      name: data['name'] ?? '',
      logoUrl: data['logoUrl'] ?? '',
      description: data['description'] ?? '',
      slogan: data['slogan'] ?? '',
      creatorId: data['creatorId'] ?? '',
      roomId: data['roomId'],
      totalExp: (data['totalExp'] ?? data['totalPoints'] ?? 0).toInt(),
      dailyExp: (data['dailyExp'] ?? data['dailyPoints'] ?? 0).toInt(),
      weeklyExp: (data['weeklyExp'] ?? data['weeklyPoints'] ?? 0).toInt(),
      monthlyExp: (data['monthlyExp'] ?? data['monthlyPoints'] ?? 0).toInt(),
      memberCount: (data['memberCount'] ?? 1).toInt(),
      maxMembers: (data['maxMembers'] ?? 50).toInt(),
      level: (data['level'] ?? 1).toInt(),
      minLevelToJoin: (data['minLevelToJoin'] ?? 1).toInt(),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      isVerified: data['isVerified'] ?? false,
      familyGems: (data['familyGems'] ?? 0).toInt(),
      familyStars: (data['familyStars'] ?? data['familyCoins'] ?? 0).toInt(),
      activeBadgeId: data['activeBadgeId'],
      perks: data['perks'] ?? {},
      isPrivate: data['isPrivate'] ?? false,
      warWins: (data['warWins'] ?? 0).toInt(),
      warLosses: (data['warLosses'] ?? 0).toInt(),
      warExp: (data['warExp'] ?? data['warPoints'] ?? 0).toInt(),
      memberRanks: Map<String, String>.from(data['memberRanks'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'logoUrl': logoUrl,
      'description': description,
      'slogan': slogan,
      'creatorId': creatorId,
      'roomId': roomId,
      'totalExp': totalExp,
      'totalPoints': totalExp, // مزامنة مع الحقل القديم
      'dailyExp': dailyExp,
      'dailyPoints': dailyExp, // مزامنة مع الحقل القديم
      'weeklyExp': weeklyExp,
      'weeklyPoints': weeklyExp, // مزامنة مع الحقل القديم
      'monthlyExp': monthlyExp,
      'monthlyPoints': monthlyExp, // مزامنة مع الحقل القديم
      'memberCount': memberCount,
      'maxMembers': maxMembers,
      'level': level,
      'minLevelToJoin': minLevelToJoin,
      'createdAt': createdAt,
      'isVerified': isVerified,
      'familyGems': familyGems,
      'familyStars': familyStars,
      'familyCoins': familyStars, // مزامنة مع الحقل القديم
      'activeBadgeId': activeBadgeId,
      'perks': perks,
      'isPrivate': isPrivate,
      'warWins': warWins,
      'warLosses': warLosses,
      'warExp': warExp,
      'warPoints': warExp, // مزامنة مع الحقل القديم
      'memberRanks': memberRanks,
    };
  }

  // دالة لحساب المستوى القادم
  int get nextLevelPoints => level * level * 10000;

  static int calculateMaxMembers(int level) => 50 + (level * 5);
}
