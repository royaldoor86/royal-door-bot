import 'package:flutter/material.dart';
import '../services/family_service.dart';
import '../models/member_rank_model.dart';
import '../app_theme.dart';
import 'dart:ui' as ui;

class MemberRanksPage extends StatefulWidget {
  final String familyId;
  final String familyName;

  const MemberRanksPage({
    super.key,
    required this.familyId,
    required this.familyName,
  });

  @override
  State<MemberRanksPage> createState() => _MemberRanksPageState();
}

class _MemberRanksPageState extends State<MemberRanksPage> {
  final FamilyService _familyService = FamilyService();
  final ranks = MemberRankModel.getDefaultRanks();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A050E),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'رتب أعضاء ${widget.familyName}',
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // وصف النظام
              AppTheme.glassContainer(
                padding: const EdgeInsets.all(16),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.amber, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'نظام الرتب',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'تُحدد الرتب بناءً على مساهمات الأعضاء في العائلة. كلما زادت مساهماتك، ارتفعت رتبتك وحصلت على مزايا أكثر.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // عرض الرتب
              ...ranks.map((rank) => _buildRankCard(rank)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRankCard(MemberRankModel rank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: AppTheme.glassContainer(
        padding: const EdgeInsets.all(16),
        borderGlow: rank.level >= 5,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // عنوان الرتبة
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _parseColor(rank.color).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _parseColor(rank.color).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    rank.icon,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rank.nameAr,
                        style: TextStyle(
                          color: _parseColor(rank.color),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        rank.name,
                        style: TextStyle(
                          color: _parseColor(rank.color).withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // النقاط المطلوبة
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  'النقاط المطلوبة: ${rank.requiredPoints}',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.trending_up, color: Colors.green, size: 16),
                const SizedBox(width: 4),
                Text(
                  'مضاعف المكافآت: x${rank.bonusMultiplier}',
                  style: const TextStyle(color: Colors.green, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // المزايا
            _buildPerksList(rank.perks),
            const SizedBox(height: 12),

            // الميزات الخاصة
            if (rank.specialFeatures.isNotEmpty) ...[
              _buildSpecialFeaturesList(rank.specialFeatures),
              const SizedBox(height: 12),
            ],

            // المكافآت المخصصة
            if (rank.customRewards.isNotEmpty) ...[
              _buildCustomRewardsList(rank.customRewards),
              const SizedBox(height: 12),
            ],

            // الشارة الحصرية
            if (rank.badgeId != null) ...[
              _buildBadgeInfo(rank.badgeId!),
              const SizedBox(height: 12),
            ],

            // الصلاحيات
            _buildPermissionsList(rank.permissions),
            const SizedBox(height: 16),

            // الأعضاء في هذه الرتبة
            _buildMembersInRank(rank),
          ],
        ),
      ),
    );
  }

  Widget _buildPerksList(List<String> perks) {
    final perkNames = {
      'member_chat': '💬 دردشة الأعضاء',
      'view_stats': '📊 عرض الإحصائيات',
      'daily_bonus': '🎁 مكافأة يومية',
      'exclusive_badge': '🏅 شارة حصرية',
      'war_bonus': '⚔️ مكافأة حرب',
      'vip_chat': '💎 دردشة VIP',
      'royal_perks': '👑 مزايا ملكية',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'المزايا:',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: perks.map((perk) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.cyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.cyan.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                perkNames[perk] ?? perk,
                style: const TextStyle(
                  color: Colors.cyan,
                  fontSize: 11,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPermissionsList(Map<String, dynamic> permissions) {
    final permissionNames = {
      'canInvite': 'دعوة أعضاء',
      'canKick': 'طرد أعضاء',
      'canPromote': 'ترقية أعضاء',
      'canManageWars': 'إدارة الحروب',
      'canManagePerks': 'إدارة المزايا',
      'canViewLogs': 'عرض السجلات',
      'canEditSettings': 'تعديل الإعدادات',
    };

    final activePermissions = permissions.entries
        .where((e) => e.value == true)
        .map((e) => permissionNames[e.key] ?? e.key)
        .toList();

    if (activePermissions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الصلاحيات:',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: activePermissions.map((permission) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                permission,
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 11,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSpecialFeaturesList(List<String> features) {
    final featureNames = {
      'basic_access': '🔓 الوصول الأساسي',
      'invite_members': '👥 دعوة أعضاء',
      'kick_members': '🚫 طرد أعضاء',
      'view_logs': '📋 عرض السجلات',
      'manage_wars': '⚔️ إدارة الحروب',
      'promote_members': '⬆️ ترقية أعضاء',
      'manage_perks': '🎁 إدارة المزايا',
      'vip_chat': '💎 دردشة VIP',
      'edit_settings': '⚙️ تعديل الإعدادات',
      'royal_perks': '👑 مزايا ملكية',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الميزات الخاصة:',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: features.map((feature) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.purple.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                featureNames[feature] ?? feature,
                style: const TextStyle(
                  color: Colors.purple,
                  fontSize: 11,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCustomRewardsList(Map<String, dynamic> rewards) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'المكافآت المخصصة:',
          style: TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: rewards.entries.map((entry) {
            String label = '';
            if (entry.key.contains('gems')) {
              label = '💎 ${entry.value} جوهرة';
            } else if (entry.key.contains('stars'))
              label = '⭐ ${entry.value} نجمة';
            else if (entry.key.contains('bonus'))
              label = '🎁 مكافأة ${entry.value}';
            else
              label = '${entry.key}: ${entry.value}';

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 11,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBadgeInfo(String badgeId) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'شارة حصرية',
                  style: TextStyle(
                    color: Colors.amber,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  badgeId,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersInRank(MemberRankModel rank) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _familyService.getMembersByRank(widget.familyId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.amber),
          );
        }

        final members = snapshot.data!;
        final rankMembers = members
            .where((m) => (m['rank'] as MemberRankModel).id == rank.id)
            .toList();

        if (rankMembers.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'لا يوجد أعضاء في هذه الرتبة حالياً',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الأعضاء (${rankMembers.length}/${rank.maxMembers})',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...rankMembers.take(5).map((member) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _parseColor(rank.color),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        member['userId'].substring(0, 8),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ),
                    Text(
                      '${member['contributionPoints']} نقطة',
                      style: TextStyle(
                        color: _parseColor(rank.color),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              );
            }),
            if (rankMembers.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+${rankMembers.length - 5} أعضاء آخرون',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ),
          ],
        );
      },
    );
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    } catch (e) {
      return Colors.amber;
    }
  }
}
