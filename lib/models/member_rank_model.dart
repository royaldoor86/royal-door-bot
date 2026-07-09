import 'package:cloud_firestore/cloud_firestore.dart';

class MemberRankModel {
  final String id;
  final String name;
  final String nameAr;
  final int level;
  final int requiredPoints;
  final String icon;
  final String color;
  final List<String> perks;
  final int maxMembers;
  final double bonusMultiplier;
  final Map<String, dynamic> permissions;
  final String? badgeId; // شارة حصرية للرتبة
  final String? chatColor; // لون الدردشة المخصص
  final List<String> specialFeatures; // ميزات خاصة
  final Map<String, dynamic> customRewards; // مكافآت مخصصة

  MemberRankModel({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.level,
    required this.requiredPoints,
    required this.icon,
    required this.color,
    required this.perks,
    required this.maxMembers,
    this.bonusMultiplier = 1.0,
    required this.permissions,
    this.badgeId,
    this.chatColor,
    this.specialFeatures = const [],
    this.customRewards = const {},
  });

  factory MemberRankModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MemberRankModel(
      id: doc.id,
      name: data['name'] ?? '',
      nameAr: data['nameAr'] ?? '',
      level: data['level'] ?? 1,
      requiredPoints: data['requiredPoints'] ?? 0,
      icon: data['icon'] ?? '⭐',
      color: data['color'] ?? '#FFD700',
      perks: List<String>.from(data['perks'] ?? []),
      maxMembers: data['maxMembers'] ?? 5,
      bonusMultiplier: (data['bonusMultiplier'] ?? 1.0).toDouble(),
      permissions: Map<String, dynamic>.from(data['permissions'] ?? {}),
      badgeId: data['badgeId'],
      chatColor: data['chatColor'],
      specialFeatures: List<String>.from(data['specialFeatures'] ?? []),
      customRewards: Map<String, dynamic>.from(data['customRewards'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'nameAr': nameAr,
      'level': level,
      'requiredPoints': requiredPoints,
      'icon': icon,
      'color': color,
      'perks': perks,
      'maxMembers': maxMembers,
      'bonusMultiplier': bonusMultiplier,
      'permissions': permissions,
      'badgeId': badgeId,
      'chatColor': chatColor,
      'specialFeatures': specialFeatures,
      'customRewards': customRewards,
    };
  }

  // الرتب الافتراضية للعائلة
  static List<MemberRankModel> getDefaultRanks() {
    return [
      MemberRankModel(
        id: 'bronze',
        name: 'Bronze',
        nameAr: 'برونزي',
        level: 1,
        requiredPoints: 0,
        icon: '🥉',
        color: '#CD7F32',
        perks: ['member_chat', 'view_stats'],
        maxMembers: 999,
        bonusMultiplier: 1.0,
        permissions: {
          'canInvite': false,
          'canKick': false,
          'canPromote': false,
          'canManageWars': false,
          'canManagePerks': false,
          'canViewLogs': false,
        },
        badgeId: 'bronze_member',
        chatColor: '#CD7F32',
        specialFeatures: ['basic_access'],
        customRewards: {
          'daily_gems': 10,
          'daily_stars': 20,
        },
      ),
      MemberRankModel(
        id: 'silver',
        name: 'Silver',
        nameAr: 'فضي',
        level: 2,
        requiredPoints: 500,
        icon: '🥈',
        color: '#C0C0C0',
        perks: ['member_chat', 'view_stats', 'daily_bonus'],
        maxMembers: 50,
        bonusMultiplier: 1.1,
        permissions: {
          'canInvite': true,
          'canKick': false,
          'canPromote': false,
          'canManageWars': false,
          'canManagePerks': false,
          'canViewLogs': false,
        },
        badgeId: 'silver_member',
        chatColor: '#C0C0C0',
        specialFeatures: ['basic_access', 'invite_members'],
        customRewards: {
          'daily_gems': 25,
          'daily_stars': 50,
          'weekly_bonus': 100,
        },
      ),
      MemberRankModel(
        id: 'gold',
        name: 'Gold',
        nameAr: 'ذهبي',
        level: 3,
        requiredPoints: 1500,
        icon: '🥇',
        color: '#FFD700',
        perks: ['member_chat', 'view_stats', 'daily_bonus', 'exclusive_badge'],
        maxMembers: 30,
        bonusMultiplier: 1.2,
        permissions: {
          'canInvite': true,
          'canKick': true,
          'canPromote': false,
          'canManageWars': false,
          'canManagePerks': false,
          'canViewLogs': true,
        },
        badgeId: 'gold_member',
        chatColor: '#FFD700',
        specialFeatures: [
          'basic_access',
          'invite_members',
          'kick_members',
          'view_logs'
        ],
        customRewards: {
          'daily_gems': 50,
          'daily_stars': 100,
          'weekly_bonus': 250,
          'monthly_bonus': 500,
        },
      ),
      MemberRankModel(
        id: 'platinum',
        name: 'Platinum',
        nameAr: 'بلاتيني',
        level: 4,
        requiredPoints: 3000,
        icon: '💎',
        color: '#E5E4E2',
        perks: [
          'member_chat',
          'view_stats',
          'daily_bonus',
          'exclusive_badge',
          'war_bonus'
        ],
        maxMembers: 15,
        bonusMultiplier: 1.3,
        permissions: {
          'canInvite': true,
          'canKick': true,
          'canPromote': true,
          'canManageWars': true,
          'canManagePerks': false,
          'canViewLogs': true,
        },
        badgeId: 'platinum_member',
        chatColor: '#E5E4E2',
        specialFeatures: [
          'basic_access',
          'invite_members',
          'kick_members',
          'view_logs',
          'manage_wars',
          'promote_members'
        ],
        customRewards: {
          'daily_gems': 100,
          'daily_stars': 200,
          'weekly_bonus': 500,
          'monthly_bonus': 1000,
          'war_bonus_multiplier': 1.5,
        },
      ),
      MemberRankModel(
        id: 'diamond',
        name: 'Diamond',
        nameAr: 'ماسي',
        level: 5,
        requiredPoints: 5000,
        icon: '💠',
        color: '#B9F2FF',
        perks: [
          'member_chat',
          'view_stats',
          'daily_bonus',
          'exclusive_badge',
          'war_bonus',
          'vip_chat'
        ],
        maxMembers: 10,
        bonusMultiplier: 1.5,
        permissions: {
          'canInvite': true,
          'canKick': true,
          'canPromote': true,
          'canManageWars': true,
          'canManagePerks': true,
          'canViewLogs': true,
        },
        badgeId: 'diamond_member',
        chatColor: '#B9F2FF',
        specialFeatures: [
          'basic_access',
          'invite_members',
          'kick_members',
          'view_logs',
          'manage_wars',
          'promote_members',
          'manage_perks',
          'vip_chat'
        ],
        customRewards: {
          'daily_gems': 200,
          'daily_stars': 400,
          'weekly_bonus': 1000,
          'monthly_bonus': 2000,
          'war_bonus_multiplier': 2.0,
          'exclusive_access': true,
        },
      ),
      MemberRankModel(
        id: 'royal',
        name: 'Royal',
        nameAr: 'ملكي',
        level: 6,
        requiredPoints: 10000,
        icon: '👑',
        color: '#FFD700',
        perks: [
          'member_chat',
          'view_stats',
          'daily_bonus',
          'exclusive_badge',
          'war_bonus',
          'vip_chat',
          'royal_perks'
        ],
        maxMembers: 5,
        bonusMultiplier: 2.0,
        permissions: {
          'canInvite': true,
          'canKick': true,
          'canPromote': true,
          'canManageWars': true,
          'canManagePerks': true,
          'canViewLogs': true,
          'canEditSettings': true,
        },
        badgeId: 'royal_member',
        chatColor: '#FFD700',
        specialFeatures: [
          'basic_access',
          'invite_members',
          'kick_members',
          'view_logs',
          'manage_wars',
          'promote_members',
          'manage_perks',
          'vip_chat',
          'edit_settings',
          'royal_perks'
        ],
        customRewards: {
          'daily_gems': 500,
          'daily_stars': 1000,
          'weekly_bonus': 2500,
          'monthly_bonus': 5000,
          'war_bonus_multiplier': 3.0,
          'exclusive_access': true,
          'custom_title': true,
          'priority_support': true,
        },
      ),
    ];
  }

  // الحصول على الرتب المناسبة بناءً على النقاط
  static MemberRankModel getRankForPoints(int points) {
    final ranks = getDefaultRanks();
    MemberRankModel currentRank = ranks.first;

    for (final rank in ranks) {
      if (points >= rank.requiredPoints) {
        currentRank = rank;
      } else {
        break;
      }
    }

    return currentRank;
  }

  // حساب النقاط المتبقية للرتبة التالية
  int get pointsToNextRank {
    final ranks = getDefaultRanks();
    final currentIndex = ranks.indexWhere((r) => r.id == id);
    if (currentIndex < 0 || currentIndex >= ranks.length - 1) {
      return 0; // أعلى رتبة
    }
    final nextRank = ranks[currentIndex + 1];
    return nextRank.requiredPoints - requiredPoints;
  }

  // نسبة التقدم للرتبة التالية
  double get progressToNextRank {
    final ranks = getDefaultRanks();
    final currentIndex = ranks.indexWhere((r) => r.id == id);
    if (currentIndex < 0 || currentIndex >= ranks.length - 1) {
      return 1.0; // أعلى رتبة
    }
    final previousRank =
        currentIndex > 0 ? ranks[currentIndex - 1] : ranks.first;
    final nextRank = ranks[currentIndex + 1];
    final totalRange = nextRank.requiredPoints - previousRank.requiredPoints;
    final currentProgress = requiredPoints - previousRank.requiredPoints;
    return (currentProgress / totalRange).clamp(0.0, 1.0);
  }
}
