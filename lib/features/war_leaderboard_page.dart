import 'package:flutter/material.dart';
import '../services/family_service.dart';
import '../models/war_leaderboard_model.dart';
import '../app_theme.dart';
import 'dart:ui' as ui;

class WarLeaderboardPage extends StatefulWidget {
  const WarLeaderboardPage({super.key});

  @override
  State<WarLeaderboardPage> createState() => _WarLeaderboardPageState();
}

class _WarLeaderboardPageState extends State<WarLeaderboardPage> {
  final FamilyService _familyService = FamilyService();
  String _selectedPeriod = 'all'; // all, week, month
  String _sortBy = 'points'; // points, wins, streak

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
            'تصنيف الحروب العالمي',
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
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3D0B16), Color(0xFF1A050E)],
            ),
          ),
          child: Column(
            children: [
              // فترة التصفية
              _buildPeriodFilter(),
              const SizedBox(height: 20),

              // قائمة التصنيف
              Expanded(
                child: StreamBuilder<List<WarLeaderboardModel>>(
                  stream: _familyService.getWarLeaderboard(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.amber),
                      );
                    }

                    var leaderboard = snapshot.data!;

                    if (leaderboard.isEmpty) {
                      return const Center(
                        child: Text(
                          'لا توجد بيانات للتصنيف حالياً',
                          style: TextStyle(color: Colors.white38),
                        ),
                      );
                    }

                    // ترتيب القائمة حسب الخيار المحدد
                    leaderboard = List.from(leaderboard);
                    switch (_sortBy) {
                      case 'wins':
                        leaderboard
                            .sort((a, b) => b.warsWon.compareTo(a.warsWon));
                        break;
                      case 'streak':
                        leaderboard.sort((a, b) =>
                            b.currentStreak.compareTo(a.currentStreak));
                        break;
                      case 'points':
                      default:
                        leaderboard.sort(
                            (a, b) => b.totalPoints.compareTo(a.totalPoints));
                        break;
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: leaderboard.length,
                      itemBuilder: (context, index) {
                        final entry = leaderboard[index];
                        return _buildLeaderboardCard(entry, index);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodFilter() {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildFilterChip('الكل', 'all'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip('أسبوعي', 'week'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip('شهري', 'month'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFilterChip('حسب النقاط', 'points'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip('حسب الفوز', 'wins'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterChip('حسب السلسلة', 'streak'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedPeriod == value || _sortBy == value;
    return GestureDetector(
      onTap: () {
        if (['all', 'week', 'month'].contains(value)) {
          setState(() => _selectedPeriod = value);
        } else {
          setState(() => _sortBy = value);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.amber.withValues(alpha: 0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.amber : Colors.white24,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.amber : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderboardCard(WarLeaderboardModel entry, int index) {
    final isTop3 = index < 3;
    final rankIcon = index == 0
        ? '🥇'
        : index == 1
            ? '🥈'
            : index == 2
                ? '🥉'
                : '${index + 1}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: AppTheme.glassContainer(
        padding: const EdgeInsets.all(16),
        borderGlow: isTop3,
        child: Row(
          children: [
            // الرتبة
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isTop3
                    ? Colors.amber.withValues(alpha: 0.3)
                    : Colors.white10,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isTop3 ? Colors.amber : Colors.white24,
                ),
              ),
              child: Center(
                child: Text(
                  rankIcon,
                  style: TextStyle(
                    fontSize: isTop3 ? 28 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // شعار العائلة
            CircleAvatar(
              radius: 28,
              backgroundImage:
                  entry.familyLogo != null && entry.familyLogo!.isNotEmpty
                      ? NetworkImage(entry.familyLogo!)
                      : null,
              child: (entry.familyLogo == null || entry.familyLogo!.isEmpty)
                  ? const Icon(Icons.family_restroom, color: Colors.amber)
                  : null,
            ),
            const SizedBox(width: 16),

            // معلومات العائلة
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.familyName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _parseColor(entry.getRankColor())
                              .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          entry.getRankTitle(),
                          style: TextStyle(
                            color: _parseColor(entry.getRankColor()),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${entry.winRate.toStringAsFixed(1)}% فوز',
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // النقاط
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${entry.totalPoints}',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'نقطة',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
