import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/family_service.dart';
import '../models/member_rank_model.dart';
import '../app_theme.dart';
import 'dart:ui' as ui;

class RankPerksPage extends StatefulWidget {
  final String familyId;
  final String familyName;

  const RankPerksPage({
    super.key,
    required this.familyId,
    required this.familyName,
  });

  @override
  State<RankPerksPage> createState() => _RankPerksPageState();
}

class _RankPerksPageState extends State<RankPerksPage> {
  final FamilyService _familyService = FamilyService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A050E),
        body: Center(
          child: Text('يجب تسجيل الدخول', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A050E),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'مزايا رتبتك في ${widget.familyName}',
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.amber),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: StreamBuilder<MemberRankModel>(
          stream: _familyService.getMemberRank(widget.familyId, user.uid),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.amber),
              );
            }

            final currentRank = snapshot.data!;
            final ranks = MemberRankModel.getDefaultRanks();
            final currentIndex = ranks.indexWhere((r) => r.id == currentRank.id);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // بطاقة الرتبة الحالية
                  _buildCurrentRankCard(currentRank),
                  const SizedBox(height: 20),

                  // شريط التقدم للرتبة التالية
                  if (currentIndex < ranks.length - 1)
                    _buildProgressToNextRank(currentRank, ranks[currentIndex + 1]),
                  const SizedBox(height: 20),

                  // المزايا المتاحة
                  _buildAvailablePerks(currentRank),
                  const SizedBox(height: 20),

                  // الصلاحيات
                  _buildPermissions(currentRank),
                  const SizedBox(height: 20),

                  // مضاعف المكافآت
                  _buildBonusMultiplier(currentRank),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCurrentRankCard(MemberRankModel rank) {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(20),
      borderGlow: rank.level >= 5,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _parseColor(rank.color).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _parseColor(rank.color).withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Text(
              rank.icon,
              style: const TextStyle(fontSize: 48),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            rank.nameAr,
            style: TextStyle(
              color: _parseColor(rank.color),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            rank.name,
            style: TextStyle(
              color: _parseColor(rank.color).withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.amber.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              'المستوى ${rank.level}',
              style: const TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressToNextRank(MemberRankModel currentRank, MemberRankModel nextRank) {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'التقدم للرتبة التالية',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nextRank.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                    Text(
                      nextRank.nameAr,
                      style: TextStyle(
                        color: _parseColor(nextRank.color),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'النقاط المطلوبة',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      '${nextRank.requiredPoints}',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: currentRank.progressToNextRank,
              backgroundColor: Colors.white10,
              color: Colors.amber,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(currentRank.progressToNextRank * 100).toInt()}% مكتمل',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailablePerks(MemberRankModel rank) {
    final perkDetails = {
      'member_chat': {
        'name': 'دردشة الأعضاء',
        'icon': '💬',
        'description': 'المشاركة في دردشة العائلة',
        'action': null,
      },
      'view_stats': {
        'name': 'عرض الإحصائيات',
        'icon': '📊',
        'description': 'عرض إحصائيات العائلة',
        'action': null,
      },
      'daily_bonus': {
        'name': 'مكافأة يومية',
        'icon': '🎁',
        'description': 'استلام مكافأة يومية',
        'action': 'claim_daily',
      },
      'exclusive_badge': {
        'name': 'شارة حصرية',
        'icon': '🏅',
        'description': 'شارة خاصة برتبتك',
        'action': null,
      },
      'war_bonus': {
        'name': 'مكافأة حرب',
        'icon': '⚔️',
        'description': 'مكافأة إضافية في الحروب',
        'action': null,
      },
      'vip_chat': {
        'name': 'دردشة VIP',
        'icon': '💎',
        'description': 'دردشة خاصة للأعضاء المميزين',
        'action': null,
      },
      'royal_perks': {
        'name': 'مزايا ملكية',
        'icon': '👑',
        'description': 'مزايا خاصة للرتب الملكية',
        'action': null,
      },
    };

    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'المزايا المتاحة',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...rank.perks.map((perk) {
            final details = perkDetails[perk];
            if (details == null) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.cyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.cyan.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    details['icon'] as String,
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          details['name'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          details['description'] as String,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (details['action'] == 'claim_daily')
                    AppTheme.gradientButton(
                      text: 'استلام',
                      onPressed: () => _claimDailyBonus(),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPermissions(MemberRankModel rank) {
    final permissionDetails = {
      'canInvite': {'name': 'دعوة أعضاء', 'icon': '👥'},
      'canKick': {'name': 'طرد أعضاء', 'icon': '🚫'},
      'canPromote': {'name': 'ترقية أعضاء', 'icon': '⬆️'},
      'canManageWars': {'name': 'إدارة الحروب', 'icon': '⚔️'},
      'canManagePerks': {'name': 'إدارة المزايا', 'icon': '🎁'},
      'canViewLogs': {'name': 'عرض السجلات', 'icon': '📋'},
      'canEditSettings': {'name': 'تعديل الإعدادات', 'icon': '⚙️'},
    };

    final activePermissions = rank.permissions.entries
        .where((e) => e.value == true)
        .map((e) => e.key)
        .toList();

    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'الصلاحيات',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (activePermissions.isEmpty)
            const Text(
              'لا توجد صلاحيات إضافية',
              style: TextStyle(color: Colors.white38, fontSize: 13),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: activePermissions.map((permission) {
                final details = permissionDetails[permission];
                if (details == null) return const SizedBox.shrink();

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        details['icon'] as String,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        details['name'] as String,
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildBonusMultiplier(MemberRankModel rank) {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.amber.withValues(alpha: 0.5),
              ),
            ),
            child: const Icon(Icons.trending_up, color: Colors.amber, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مضاعف المكافآت',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'تحصل على x${rank.bonusMultiplier} من المكافآت',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.amber.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              'x${rank.bonusMultiplier}',
              style: const TextStyle(
                color: Colors.amber,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _claimDailyBonus() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _familyService.claimDailyRankBonus(widget.familyId, user.uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم استلام المكافأة اليومية بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.amber;
    }
  }
}
