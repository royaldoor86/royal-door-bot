import 'package:flutter/material.dart';
import '../services/family_service.dart';
import '../models/family_war_model.dart';
import '../app_theme.dart';
import 'dart:ui' as ui;

class GlobalActiveWarsPage extends StatefulWidget {
  const GlobalActiveWarsPage({super.key});

  @override
  State<GlobalActiveWarsPage> createState() => _GlobalActiveWarsPageState();
}

class _GlobalActiveWarsPageState extends State<GlobalActiveWarsPage> {
  final FamilyService _familyService = FamilyService();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A050E),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'الحروب النشطة عالمياً',
            style: TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.amber),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: StreamBuilder<List<FamilyWarModel>>(
          stream: _familyService.getActiveWars(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.amber),
              );
            }

            final wars = snapshot.data ?? [];
            if (wars.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 80, color: Colors.white.withValues(alpha: 0.2)),
                    const SizedBox(height: 16),
                    const Text(
                      'لا توجد حروب نشطة حالياً',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: wars.length,
              itemBuilder: (context, index) {
                return _buildWarCard(wars[index]);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildWarCard(FamilyWarModel war) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: AppTheme.glassContainer(
        padding: const EdgeInsets.all(16),
        borderGlow: war.warType == 'championship',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // نوع الحرب
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getWarTypeColor(war.warType ?? 'normal')
                        .withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getWarTypeColor(war.warType ?? 'normal')
                          .withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    _getWarTypeText(war.warType ?? 'normal'),
                    style: TextStyle(
                      color: _getWarTypeColor(war.warType ?? 'normal'),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  _formatDuration(war.remainingTime),
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // شريط التقدم
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: war.progress,
                backgroundColor: Colors.white10,
                color: Colors.amber,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),

            // الفريقان
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTeamInfo(
                  war.challengerName,
                  war.challengerPoints,
                  war.challengerLogo,
                  Colors.amber,
                ),
                const Text(
                  'VS',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildTeamInfo(
                  war.targetName,
                  war.targetPoints,
                  war.targetLogo,
                  Colors.redAccent,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // الفائز الحالي
            _buildCurrentLeader(war),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamInfo(String name, int points, String? logoUrl, Color color) {
    return Column(
      children: [
        if (logoUrl != null && logoUrl.isNotEmpty)
          CircleAvatar(
            radius: 35,
            backgroundImage: NetworkImage(logoUrl),
            backgroundColor: Colors.white10,
          )
        else
          CircleAvatar(
            radius: 35,
            backgroundColor: color.withValues(alpha: 0.2),
            child: Icon(Icons.groups, color: color, size: 35),
          ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.5)),
          ),
          child: Text(
            points.toString(),
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentLeader(FamilyWarModel war) {
    final currentLeader = war.getCurrentLeader();
    if (currentLeader == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.balance, color: Colors.grey, size: 20),
            SizedBox(width: 8),
            Text(
              'تعادل',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    final isChallengerLeading = currentLeader == war.challengerId;
    final leaderName =
        isChallengerLeading ? war.challengerName : war.targetName;
    final leaderPoints =
        isChallengerLeading ? war.challengerPoints : war.targetPoints;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events, color: Colors.amber, size: 20),
          const SizedBox(width: 8),
          Text(
            'المتصدر: $leaderName ($leaderPoints نقطة)',
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  Color _getWarTypeColor(String warType) {
    switch (warType) {
      case 'championship':
        return Colors.orange;
      case 'alliance':
        return Colors.red;
      default:
        return Colors.amber;
    }
  }

  String _getWarTypeText(String warType) {
    switch (warType) {
      case 'championship':
        return 'حرب بطولة 🏆';
      case 'alliance':
        return 'حرب تحالف 🤝';
      default:
        return 'حرب عادية ⚔️';
    }
  }
}
