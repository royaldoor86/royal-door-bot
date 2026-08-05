import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/family_service.dart';
import '../models/family_war_model.dart';
import '../models/war_challenge_model.dart';
import '../app_theme.dart';
import 'dart:ui' as ui;

class FamilyWarsManagementPage extends StatefulWidget {
  final String familyId;
  final String familyName;

  const FamilyWarsManagementPage({
    super.key,
    required this.familyId,
    required this.familyName,
  });

  @override
  State<FamilyWarsManagementPage> createState() =>
      _FamilyWarsManagementPageState();
}

class _FamilyWarsManagementPageState extends State<FamilyWarsManagementPage>
    with SingleTickerProviderStateMixin {
  final FamilyService _familyService = FamilyService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
            'إدارة حروب ${widget.familyName}',
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.amber),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: 'حربي الحالية'),
              Tab(text: 'إعلان حرب'),
              Tab(text: 'التحديات'),
              Tab(text: 'سجل الحروب'),
              Tab(text: 'التحكيم'),
              Tab(text: 'المصالحة'),
              Tab(text: 'تفاصيل المعارك'),
            ],
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white54,
            indicatorColor: Colors.amber,
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildCurrentWarTab(),
            _buildDeclareWarTab(),
            _buildChallengesTab(),
            _buildWarHistoryTab(),
            _buildArbitrationTab(),
            _buildReconciliationTab(),
            _buildBattleDetailsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentWarTab() {
    return SafeArea(
      child: FutureBuilder<FamilyWarModel?>(
        future: _familyService.getCurrentWar(widget.familyId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.amber),
            );
          }

          final currentWar = snapshot.data;
          if (currentWar == null) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shield_outlined,
                        size: 80, color: Colors.white.withValues(alpha: 0.2)),
                    const SizedBox(height: 16),
                    const Text(
                      'لا توجد حرب نشطة حالياً',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'انتقل إلى تبويب "إعلان حرب" للبدء',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          }

          return _buildActiveWarCard(currentWar);
        },
      ),
    );
  }

  Widget _buildActiveWarCard(FamilyWarModel war) {
    final isChallenger = war.challengerId == widget.familyId;
    final myPoints = isChallenger ? war.challengerPoints : war.targetPoints;
    final enemyPoints = isChallenger ? war.targetPoints : war.challengerPoints;
    final enemyName = isChallenger ? war.targetName : war.challengerName;
    final enemyLogo = isChallenger ? war.targetLogo : war.challengerLogo;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 600;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // نوع الحرب
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
              const SizedBox(height: 20),

              // بطاقة الحرب
              AppTheme.glassContainer(
                padding: const EdgeInsets.all(20),
                borderGlow: true,
                child: Column(
                  children: [
                    // العنوان
                    const Text(
                      '⚔️ الحرب جارية ⚔️',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // شريط التقدم
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: war.progress,
                        backgroundColor: Colors.white10,
                        color: Colors.amber,
                        minHeight: 12,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${(war.progress * 100).toInt()}% مكتمل',
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 20),

                    // الوقت المتبقي
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.access_time,
                            color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _formatDuration(war.remainingTime),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // نقاط الطرفين
                    isWideScreen
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Expanded(
                                child: _buildTeamScore(
                                  widget.familyName,
                                  myPoints,
                                  Colors.amber,
                                  isChallenger,
                                  null,
                                ),
                              ),
                              const Text(
                                'VS',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: _buildTeamScore(
                                  enemyName,
                                  enemyPoints,
                                  Colors.redAccent,
                                  !isChallenger,
                                  enemyLogo,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              _buildTeamScore(
                                widget.familyName,
                                myPoints,
                                Colors.amber,
                                isChallenger,
                                null,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'VS',
                                style: TextStyle(
                                  color: Colors.white38,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildTeamScore(
                                enemyName,
                                enemyPoints,
                                Colors.redAccent,
                                !isChallenger,
                                enemyLogo,
                              ),
                            ],
                          ),
                    const SizedBox(height: 24),

                    // زر إضافة نقاط
                    SizedBox(
                      width: double.infinity,
                      child: AppTheme.gradientButton(
                        text: 'إضافة نقاط للحرب',
                        onPressed: () => _showAddPointsDialog(war),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // زر إنهاء الحرب (للمدير فقط)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _showEndWarDialog(war),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: const BorderSide(color: Colors.redAccent),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: const Text(
                          'إنهاء الحرب يدوياً',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // إحصائيات الحرب
              _buildWarStatisticsCard(war),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTeamScore(String name, int points, Color color, bool isMyTeam,
      [String? logoUrl]) {
    return Column(
      children: [
        if (logoUrl != null && logoUrl.isNotEmpty)
          CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage(logoUrl),
            backgroundColor: Colors.white10,
          )
        else
          CircleAvatar(
            radius: 30,
            backgroundColor: color.withValues(alpha: 0.2),
            child: Icon(Icons.groups, color: color, size: 30),
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
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWarStatisticsCard(FamilyWarModel war) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _familyService.getWarStatistics(war.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.amber));
        }

        final stats = snapshot.data!;
        final topContributors = stats['topContributors'] as List;
        final myPoints = war.challengerId == widget.familyId
            ? war.challengerPoints
            : war.targetPoints;
        final enemyPoints = war.challengerId == widget.familyId
            ? war.targetPoints
            : war.challengerPoints;

        return AppTheme.glassContainer(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '📊 إحصائيات الحرب المفصلة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // إحصائيات النقاط
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                      'نقاطي', myPoints.toString(), Icons.star, Colors.amber),
                  _buildStatItem('نقاطهم', enemyPoints.toString(),
                      Icons.star_border, Colors.redAccent),
                  _buildStatItem(
                      'الفرق',
                      (myPoints - enemyPoints).abs().toString(),
                      Icons.compare_arrows,
                      Colors.cyan),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(color: Colors.white10),
              const SizedBox(height: 16),

              // إحصائيات المشاركة
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(
                      'المساهمين',
                      stats['totalContributors'].toString(),
                      Icons.people,
                      Colors.cyan),
                  _buildStatItem(
                      'إجمالي النقاط',
                      stats['totalPoints'].toString(),
                      Icons.trending_up,
                      Colors.green),
                  _buildStatItem(
                      'متوسط المساهمة',
                      stats['avgContribution'].toString(),
                      Icons.bar_chart,
                      Colors.orange),
                ],
              ),

              // إحصائيات الوقت
              const SizedBox(height: 16),
              const Divider(color: Colors.white10),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('المدة', '${war.durationMinutes} دقيقة',
                      Icons.access_time, Colors.purple),
                  _buildStatItem(
                      'المنقضي',
                      '${(war.progress * war.durationMinutes).toInt()} دقيقة',
                      Icons.timer,
                      Colors.teal),
                  _buildStatItem(
                      'المتبقي',
                      '${((1 - war.progress) * war.durationMinutes).toInt()} دقيقة',
                      Icons.hourglass_empty,
                      Colors.pink),
                ],
              ),

              if (topContributors.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(color: Colors.white10),
                const SizedBox(height: 16),
                const Text(
                  '🏆 أفضل المساهمين',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...topContributors.take(5).map((contributor) {
                  final entry = contributor as MapEntry;
                  final rank = topContributors.indexOf(contributor) + 1;
                  final rankColor = rank == 1
                      ? Colors.amber
                      : rank == 2
                          ? Colors.grey
                          : rank == 3
                              ? Colors.brown
                              : Colors.white54;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: rankColor.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              '#$rank',
                              style: TextStyle(
                                color: rankColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            entry.key.substring(0, 8),
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ),
                        Text(
                          entry.value.toString(),
                          style: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildDeclareWarTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 600;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              AppTheme.glassContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚔️ إعلان حرب جديدة',
                      style: TextStyle(
                        color: Colors.amber,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'اختر عائلة للتحدي وحدد نوع الحرب',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: AppTheme.gradientButton(
                        text: 'اختر عائلة للتحدي',
                        onPressed: () => _showFamilySelectionDialog(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildWarTypesInfo(isWideScreen),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWarTypesInfo(bool isWideScreen) {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📋 أنواع الحروب',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          isWideScreen
              ? Row(
                  children: [
                    Expanded(
                      child: _buildWarTypeInfo(
                          'عادية', 'حرب عادية مع مكافآت أساسية', Colors.amber),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildWarTypeInfo(
                          'بطولة',
                          'حرب بطولة مع مكافآت كبيرة وشارة حصرية',
                          Colors.orange),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildWarTypeInfo(
                          'تحالف', 'حرب تحالفية مع أعلى المكافآت', Colors.red),
                    ),
                  ],
                )
              : Column(
                  children: [
                    _buildWarTypeInfo(
                        'عادية', 'حرب عادية مع مكافآت أساسية', Colors.amber),
                    const SizedBox(height: 12),
                    _buildWarTypeInfo('بطولة',
                        'حرب بطولة مع مكافآت كبيرة وشارة حصرية', Colors.orange),
                    const SizedBox(height: 12),
                    _buildWarTypeInfo(
                        'تحالف', 'حرب تحالفية مع أعلى المكافآت', Colors.red),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildWarTypeInfo(String type, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.military_tech, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengesTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 600;

        return FutureBuilder<FamilyWarModel?>(
          future: _familyService.getCurrentWar(widget.familyId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.amber),
              );
            }

            final currentWar = snapshot.data;
            if (currentWar == null) {
              return Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events_outlined,
                          size: 80, color: Colors.white.withValues(alpha: 0.2)),
                      const SizedBox(height: 16),
                      const Text(
                        'لا توجد حرب نشطة للتحديات',
                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'ابدأ حرباً لتفعيل التحديات',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            }

            final challenges = WarChallengeModel.getDefaultChallenges(
              currentWar.id,
              widget.familyId,
              widget.familyName,
            );

            return isWideScreen
                ? GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.5,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: challenges.length,
                    itemBuilder: (context, index) {
                      return _buildChallengeCard(challenges[index], currentWar);
                    },
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: challenges.length,
                    itemBuilder: (context, index) {
                      return _buildChallengeCard(challenges[index], currentWar);
                    },
                  );
          },
        );
      },
    );
  }

  Widget _buildChallengeCard(WarChallengeModel challenge, FamilyWarModel war) {
    final progress = challenge.progress;
    final isCompleted = challenge.isCompleted;
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final userContribution = war.contributionPoints[userId] ?? 0;

    // حساب التقدم بناءً على مساهمة المستخدم
    final actualProgress = challenge.type == 'points'
        ? (userContribution / challenge.targetValue).clamp(0.0, 1.0)
        : progress;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: AppTheme.glassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isCompleted ? Icons.check_circle : Icons.military_tech,
                    color: isCompleted ? Colors.green : Colors.amber,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        challenge.description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: actualProgress,
                backgroundColor: Colors.white10,
                color: isCompleted ? Colors.green : Colors.amber,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(actualProgress * 100).toInt()}% مكتمل',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.stars, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '+${challenge.rewardPoints}',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarHistoryTab() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 600;

        return StreamBuilder<List<FamilyWarModel>>(
          stream: _familyService.getFamilyWars(widget.familyId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.amber));
            }

            final wars = snapshot.data ?? [];
            if (wars.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history,
                        size: 80, color: Colors.white.withValues(alpha: 0.2)),
                    const SizedBox(height: 16),
                    const Text(
                      'لا يوجد سجل حروب',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            return isWideScreen
                ? GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.0,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: wars.length,
                    itemBuilder: (context, index) {
                      return _buildWarHistoryCard(wars[index]);
                    },
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: wars.length,
                    itemBuilder: (context, index) {
                      return _buildWarHistoryCard(wars[index]);
                    },
                  );
          },
        );
      },
    );
  }

  Widget _buildWarHistoryCard(FamilyWarModel war) {
    final isChallenger = war.challengerId == widget.familyId;
    final opponentName = isChallenger ? war.targetName : war.challengerName;
    final myPoints = isChallenger ? war.challengerPoints : war.targetPoints;
    final enemyPoints = isChallenger ? war.targetPoints : war.challengerPoints;
    final isWinner = war.winnerId == widget.familyId;
    final isDraw = war.winnerId == null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: AppTheme.glassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ضد $opponentName',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(war.createdAt),
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDraw
                        ? Colors.grey.withValues(alpha: 0.2)
                        : isWinner
                            ? Colors.green.withValues(alpha: 0.2)
                            : Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDraw
                          ? Colors.grey
                          : isWinner
                              ? Colors.green
                              : Colors.red,
                    ),
                  ),
                  child: Text(
                    isDraw ? 'تعادل' : (isWinner ? 'فوز 🏆' : 'خسارة'),
                    style: TextStyle(
                      color: isDraw
                          ? Colors.grey
                          : (isWinner ? Colors.green : Colors.red),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHistoryStat('نقاطي', myPoints.toString(), Colors.amber),
                _buildHistoryStat(
                    'نقاطهم', enemyPoints.toString(), Colors.redAccent),
                _buildHistoryStat('النوع',
                    _getWarTypeText(war.warType ?? 'normal'), Colors.cyan),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
      ],
    );
  }

  void _showAddPointsDialog(FamilyWarModel war) {
    final pointsController = TextEditingController();
    String selectedCurrency = 'coins'; // 'coins' or 'gems'

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A050E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.amber, width: 1.5),
          ),
          title: const Text(
            'إضافة نقاط للحرب',
            style: TextStyle(color: Colors.amber),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // عرض رصيد المستخدم
                FutureBuilder<DocumentSnapshot>(
                  future: _db
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.uid)
                      .get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox();
                    }
                    final userData =
                        snapshot.data!.data() as Map<String, dynamic>?;
                    final coins = (userData?['coins'] ?? 0).toInt();
                    final gems = (userData?['gems'] ?? 0).toInt();

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Flexible(
                            child: Column(
                              children: [
                                const Text('كوينز 💰',
                                    style: TextStyle(
                                        color: Colors.amber, fontSize: 12)),
                                Text('$coins',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                          Flexible(
                            child: Column(
                              children: [
                                const Text('جواهر 💎',
                                    style: TextStyle(
                                        color: Colors.cyan, fontSize: 12)),
                                Text('$gems',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                // اختيار العملة
                const Text(
                  'اختر العملة:',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Column(
                  children: [
                    RadioListTile<String>(
                      title: const Text('كوينز 💰',
                          style: TextStyle(color: Colors.white)),
                      subtitle: const Text('ضعيفة (5 كوينز = 1 نقطة)',
                          style:
                              TextStyle(color: Colors.white38, fontSize: 11)),
                      value: 'coins',
                      groupValue: selectedCurrency,
                      onChanged: (value) =>
                          setDialogState(() => selectedCurrency = value!),
                      activeColor: Colors.amber,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                    RadioListTile<String>(
                      title: const Text('جواهر 💎',
                          style: TextStyle(color: Colors.white)),
                      subtitle: const Text('قوية (1 جوهرة = 1 نقطة)',
                          style:
                              TextStyle(color: Colors.white38, fontSize: 11)),
                      value: 'gems',
                      groupValue: selectedCurrency,
                      onChanged: (value) =>
                          setDialogState(() => selectedCurrency = value!),
                      activeColor: Colors.cyan,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pointsController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: selectedCurrency == 'coins'
                        ? 'عدد الكوينز'
                        : 'عدد الجواهر',
                    labelStyle: const TextStyle(color: Colors.amber),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.amber),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selectedCurrency == 'gems'
                        ? Colors.cyan.withValues(alpha: 0.1)
                        : Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selectedCurrency == 'gems'
                          ? Colors.cyan
                          : Colors.amber,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    selectedCurrency == 'gems'
                        ? 'قوة النقاط: 1 جوهرة = 1 نقطة حرب'
                        : 'قوة النقاط: 5 كوينز = 1 نقطة حرب',
                    style: TextStyle(
                      color: selectedCurrency == 'gems'
                          ? Colors.cyan
                          : Colors.amber,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('إلغاء', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = int.tryParse(pointsController.text) ?? 0;
                if (amount <= 0) return;
                try {
                  await _familyService.addWarPoints(
                    war.id,
                    widget.familyId,
                    amount,
                    currency: selectedCurrency,
                    userId: FirebaseAuth.instance.currentUser?.uid,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(selectedCurrency == 'gems'
                            ? 'تم إضافة $amount جوهرة ($amount نقطة حرب)'
                            : 'تم إضافة $amount كوينز (${(amount / 5).floor()} نقطة حرب)'),
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
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    selectedCurrency == 'gems' ? Colors.cyan : Colors.amber,
              ),
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEndWarDialog(FamilyWarModel war) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A050E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        title: const Text(
          'إنهاء الحرب',
          style: TextStyle(color: Colors.redAccent),
        ),
        content: const Text(
          'هل أنت متأكد من إنهاء الحرب الآن؟ سيتم تحديد الفائز بناءً على النقاط الحالية.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _familyService.endFamilyWar(war.id);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم إنهاء الحرب بنجاح'),
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
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  void _showFamilySelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A050E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.amber, width: 1.5),
        ),
        title: const Text(
          'اختر عائلة للتحدي',
          style: TextStyle(color: Colors.amber),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('families')
                .where(FieldPath.documentId, isNotEqualTo: widget.familyId)
                .limit(20)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.amber));
              }

              final families = snapshot.data!.docs;
              if (families.isEmpty) {
                return const Center(
                  child: Text('لا توجد عائلات أخرى',
                      style: TextStyle(color: Colors.white70)),
                );
              }

              return ListView.builder(
                itemCount: families.length,
                itemBuilder: (context, index) {
                  final family = families[index];
                  final data = family.data() as Map<String, dynamic>;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: data['logoUrl'] != null
                          ? NetworkImage(data['logoUrl'])
                          : null,
                      backgroundColor: Colors.white10,
                    ),
                    title: Text(
                      data['name'] ?? '',
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      'المستوى: ${data['level'] ?? 1} | الأعضاء: ${data['memberCount'] ?? 0}',
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showWarTypeDialog(
                          family.id, data['name'] ?? 'غير معروف');
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showWarTypeDialog(String targetFamilyId, String targetFamilyName) {
    String selectedWarType = 'normal';
    int durationMinutes = 60;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A050E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.amber, width: 1.5),
          ),
          title: Text(
            'حرب ضد $targetFamilyName',
            style: const TextStyle(color: Colors.amber),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('نوع الحرب:', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedWarType,
                items: const [
                  DropdownMenuItem(value: 'normal', child: Text('عادية')),
                  DropdownMenuItem(value: 'championship', child: Text('بطولة')),
                  DropdownMenuItem(value: 'alliance', child: Text('تحالف')),
                ],
                onChanged: (value) =>
                    setDialogState(() => selectedWarType = value!),
                dropdownColor: const Color(0xFF1A050E),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text('المدة (دقائق):',
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Slider(
                value: durationMinutes.toDouble(),
                min: 30,
                max: 180,
                divisions: 5,
                label: '$durationMinutes دقيقة',
                onChanged: (value) =>
                    setDialogState(() => durationMinutes = value.toInt()),
                activeColor: Colors.amber,
              ),
              Text(
                '$durationMinutes دقيقة',
                style: const TextStyle(
                    color: Colors.amber, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('إلغاء', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await _familyService.startFamilyWar(
                    challengerId: widget.familyId,
                    targetId: targetFamilyId,
                    durationMinutes: durationMinutes,
                    warType: selectedWarType,
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم إعلان الحرب بنجاح!'),
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
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              child: const Text('إعلان الحرب'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '$hours ساعة $minutes دقيقة';
    }
    return '$minutes دقيقة';
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
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

  // --- تبويب التحكيم ---
  Widget _buildArbitrationTab() {
    return SafeArea(
      child: FutureBuilder<FamilyWarModel?>(
        future: _familyService.getCurrentWar(widget.familyId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.amber));
          }

          final currentWar = snapshot.data;
          if (currentWar == null) {
            return const Center(
              child: Text('لا توجد حرب نشطة حالياً',
                  style: TextStyle(color: Colors.white38)),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: AppTheme.gradientButton(
                  text: 'طلب تحكيم في النزاع ⚖️',
                  onPressed: () => _showArbitrationDialog(currentWar.id),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _familyService.getArbitrationRequests(currentWar.id),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final requests = snapshot.data!.docs;
                    if (requests.isEmpty) {
                      return const Center(
                        child: Text('لا توجد طلبات تحكيم',
                            style: TextStyle(color: Colors.white38)),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final req =
                            requests[index].data() as Map<String, dynamic>;
                        final reqId = requests[index].id;
                        return _buildArbitrationRequestCard(
                            req, reqId, currentWar.id);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildArbitrationRequestCard(
      Map<String, dynamic> req, String reqId, String warId) {
    final status = req['status'] ?? 'pending';
    return AppTheme.glassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                req['reason'] ?? 'بدون سبب',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'pending'
                      ? Colors.orange.withValues(alpha: 0.3)
                      : Colors.green.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status == 'pending' ? 'قيد الانتظار' : 'تم الحل',
                  style: TextStyle(
                    color: status == 'pending' ? Colors.orange : Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            req['description'] ?? '',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          if (status == 'pending') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTheme.gradientButton(
                    text: 'قبول وحل',
                    onPressed: () =>
                        _showArbitrationDecisionDialog(warId, reqId),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showArbitrationDialog(String warId) {
    final reasonController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A050E),
        title:
            const Text('طلب تحكيم ⚖️', style: TextStyle(color: Colors.amber)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: reasonController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'سبب النزاع',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'التفاصيل',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _familyService.requestWarArbitration(
                  warId: warId,
                  familyId: widget.familyId,
                  reason: reasonController.text,
                  description: descriptionController.text,
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم إرسال طلب التحكيم'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('فشل: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
  }

  void _showArbitrationDecisionDialog(String warId, String requestId) {
    final decisionController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A050E),
        title:
            const Text('حكم التحكيم ⚖️', style: TextStyle(color: Colors.amber)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: decisionController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'الحكم',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'ملاحظات',
                labelStyle: TextStyle(color: Colors.white70),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _familyService.acceptArbitrationRequest(
                  warId: warId,
                  requestId: requestId,
                  decision: decisionController.text,
                  notes: notesController.text,
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم حل النزاع'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('فشل: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text('تطبيق الحكم'),
          ),
        ],
      ),
    );
  }

  // --- تبويب المصالحة ---
  Widget _buildReconciliationTab() {
    return SafeArea(
      child: FutureBuilder<FamilyWarModel?>(
        future: _familyService.getCurrentWar(widget.familyId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.amber));
          }

          final currentWar = snapshot.data;
          if (currentWar == null) {
            return const Center(
              child: Text('لا توجد حرب نشطة حالياً',
                  style: TextStyle(color: Colors.white38)),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: AppTheme.gradientButton(
                  text: 'طلب مصالحة تلقائية 🤝',
                  onPressed: () => _showReconciliationDialog(currentWar.id),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      _familyService.getReconciliationRequests(currentWar.id),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final requests = snapshot.data!.docs;
                    if (requests.isEmpty) {
                      return const Center(
                        child: Text('لا توجد طلبات مصالحة',
                            style: TextStyle(color: Colors.white38)),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final req =
                            requests[index].data() as Map<String, dynamic>;
                        final reqId = requests[index].id;
                        return _buildReconciliationRequestCard(
                            req, reqId, currentWar.id);
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReconciliationRequestCard(
      Map<String, dynamic> req, String reqId, String warId) {
    final status = req['status'] ?? 'pending';
    return AppTheme.glassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'طلب مصالحة',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status == 'pending'
                      ? Colors.orange.withValues(alpha: 0.3)
                      : Colors.green.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status == 'pending' ? 'قيد الانتظار' : 'تم القبول',
                  style: TextStyle(
                    color: status == 'pending' ? Colors.orange : Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            req['reason'] ?? '',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          if (status == 'pending') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppTheme.gradientButton(
                    text: 'قبول المصالحة',
                    onPressed: () =>
                        _showReconciliationTermsDialog(warId, reqId),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showReconciliationDialog(String warId) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A050E),
        title:
            const Text('طلب مصالحة 🤝', style: TextStyle(color: Colors.amber)),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'سبب المصالحة',
            labelStyle: TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _familyService.requestAutoReconciliation(
                  warId: warId,
                  familyId: widget.familyId,
                  reason: reasonController.text,
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم إرسال طلب المصالحة'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('فشل: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text('إرسال'),
          ),
        ],
      ),
    );
  }

  void _showReconciliationTermsDialog(String warId, String requestId) {
    final termsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A050E),
        title: const Text('شروط المصالحة 🤝',
            style: TextStyle(color: Colors.amber)),
        content: TextField(
          controller: termsController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'شروط المصالحة',
            labelStyle: TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _familyService.acceptReconciliation(
                  warId: warId,
                  requestId: requestId,
                  terms: termsController.text,
                );
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم قبول المصالحة وإنهاء الحرب'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('فشل: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text('قبول وإنهاء الحرب'),
          ),
        ],
      ),
    );
  }

  // --- تبويب تفاصيل المعارك ---
  Widget _buildBattleDetailsTab() {
    return SafeArea(
      child: FutureBuilder<FamilyWarModel?>(
        future: _familyService.getCurrentWar(widget.familyId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.amber));
          }

          final currentWar = snapshot.data;
          if (currentWar == null) {
            return const Center(
              child: Text('لا توجد حرب نشطة حالياً',
                  style: TextStyle(color: Colors.white38)),
            );
          }

          return StreamBuilder<QuerySnapshot>(
            stream: _familyService.getBattleDetails(currentWar.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final battles = snapshot.data!.docs;
              if (battles.isEmpty) {
                return const Center(
                  child: Text('لا توجد تفاصيل معارك مسجلة',
                      style: TextStyle(color: Colors.white38)),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: battles.length,
                itemBuilder: (context, index) {
                  final battle = battles[index].data() as Map<String, dynamic>;
                  return _buildBattleDetailCard(battle);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildBattleDetailCard(Map<String, dynamic> battle) {
    final battleData = battle['battleData'] as Map<String, dynamic>?;
    final loggedAt = battle['loggedAt'] as Timestamp?;

    return AppTheme.glassContainer(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'تفاصيل المعركة',
                style: TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (loggedAt != null)
                Text(
                  _formatTimestamp(loggedAt),
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (battleData != null) ...[
            _buildBattleDetailRow(
                'الفائز', battleData['winner']?.toString() ?? '-'),
            _buildBattleDetailRow(
                'النقاط', battleData['points']?.toString() ?? '-'),
            _buildBattleDetailRow(
                'المشاركون', battleData['participants']?.toString() ?? '-'),
            _buildBattleDetailRow(
                'المدة', battleData['duration']?.toString() ?? '-'),
          ],
        ],
      ),
    );
  }

  Widget _buildBattleDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
