import 'package:cloud_firestore/cloud_firestore.dart';

class FamilyModel {
  final String id;
  final String name;
  final String logoUrl;
  final String description;
  final String slogan; // شعار العائلة القصير
  final String creatorId;
  final String? roomId; // المعرف الخاص بغرفة العائلة الرسمية
  final int totalPoints;
  final int dailyPoints; // النقاط اليومية للتنافس
  final int weeklyPoints; // النقاط الأسبوعية
  final int monthlyPoints; // النقاط الشهرية
  final int memberCount;
  final int maxMembers; // الحد الأقصى للأعضاء بناءً على المستوى
  final int level;
  final int minLevelToJoin; // الحد الأدنى لليفل المستخدم للانضمام
  final Timestamp createdAt;
  final bool isVerified; // هل العائلة موثقة من الإدارة

  FamilyModel({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.description,
    this.slogan = '',
    required this.creatorId,
    this.roomId,
    this.totalPoints = 0,
    this.dailyPoints = 0,
    this.weeklyPoints = 0,
    this.monthlyPoints = 0,
    this.memberCount = 1,
    this.maxMembers = 50,
    this.level = 1,
    this.minLevelToJoin = 1,
    required this.createdAt,
    this.isVerified = false,
  });

  factory FamilyModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return FamilyModel(
      id: doc.id,
      name: data['name'] ?? '',
      logoUrl: data['logoUrl'] ?? '',
      description: data['description'] ?? '',
      slogan: data['slogan'] ?? '',
      creatorId: data['creatorId'] ?? '',
      roomId: data['roomId'],
      totalPoints: (data['totalPoints'] ?? 0).toInt(),
      dailyPoints: (data['dailyPoints'] ?? 0).toInt(),
      weeklyPoints: (data['weeklyPoints'] ?? 0).toInt(),
      monthlyPoints: (data['monthlyPoints'] ?? 0).toInt(),
      memberCount: (data['memberCount'] ?? 1).toInt(),
      maxMembers: (data['maxMembers'] ?? 50).toInt(),
      level: (data['level'] ?? 1).toInt(),
      minLevelToJoin: (data['minLevelToJoin'] ?? 1).toInt(),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      isVerified: data['isVerified'] ?? false,
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
      'totalPoints': totalPoints,
      'dailyPoints': dailyPoints,
      'weeklyPoints': weeklyPoints,
      'monthlyPoints': monthlyPoints,
      'memberCount': memberCount,
      'maxMembers': maxMembers,
      'level': level,
      'minLevelToJoin': minLevelToJoin,
      'createdAt': createdAt,
      'isVerified': isVerified,
    };
  }

  // دالة لحساب المستوى القادم
  int get nextLevelPoints => level * level * 10000;
}
