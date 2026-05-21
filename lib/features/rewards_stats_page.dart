import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui' as ui;
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/rewards_models.dart';
import '../services/rewards_service.dart';

class RewardsStatsPage extends StatefulWidget {
  const RewardsStatsPage({super.key});

  static Route route() {
    return MaterialPageRoute(builder: (_) => const RewardsStatsPage());
  }

  @override
  State<RewardsStatsPage> createState() => _RewardsStatsPageState();
}

class _RewardsStatsPageState extends State<RewardsStatsPage> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _rotationController;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  double _totalEarnedStars = 0.0;
  int _activePackages = 0;
  double _totalDailyYield = 0.0;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _rotationController = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final user = _auth.currentUser;
    if (user == null) return;
    setState(() => _isLoading = true);
    try {
      final userDoc = await _db.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};
      
      final statsDoc = await _db.collection('users').doc(user.uid).collection('stats').doc('current').get();
      final statsData = statsDoc.data() ?? {};

      final packagesSnapshot = await _db.collection('users').doc(user.uid).collection('active_harvests').where('status', isEqualTo: 'active').get();
      
      double totalDaily = 0.0;
      for (var doc in packagesSnapshot.docs) {
        totalDaily += (doc.data()['dailyReward'] as num?)?.toDouble() ?? 0.0;
      }

      final historySnapshot = await _db.collection('users').doc(user.uid).collection('harvest_daily_logs').orderBy('timestamp', descending: true).limit(15).get();

      setState(() {
        _totalEarnedStars = (statsData['totalEarnedStars'] as num?)?.toDouble() ?? (userData['harvest_stars_wallet'] as num?)?.toDouble() ?? 0.0;
        _activePackages = packagesSnapshot.size;
        _totalDailyYield = totalDaily;
        _history = historySnapshot.docs.map((d) => d.data()).toList();
        _isLoading = false;
      });

      // التحقق من الإنجازات وتحديثها في الخلفية
      await RewardsService().checkAndUnlockAchievements(user.uid);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _format(num n) => NumberFormat.decimalPattern('ar').format(n);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F2027),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('إحصائيات المملكة', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, fontFamily: 'Orbitron')),
          centerTitle: true,
          leading: IconButton(icon: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            indicatorColor: Colors.amber,
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(text: 'الإحصائيات'),
              Tab(text: 'الحصاد'),
              Tab(text: 'الرسوم البيانية'),
              Tab(text: 'الإنجازات'),
            ],
          ),
        ),
        body: Stack(
          children: [
            _buildBackground(),
            _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Colors.amber))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverview(),
                    _buildHistory(),
                    _buildCharts(),
                    _buildAchievements(),
                  ],
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildLevelProgressCard(),
          const SizedBox(height: 25),

          _buildSectionHeader("الإحصائيات الرئيسية", Icons.grid_view_rounded),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _buildMiniStatCard("العائد اليومي", "${_format(_totalDailyYield)} نجمة", Icons.bolt, Colors.amber)),
              const SizedBox(width: 15),
              Expanded(child: _buildMiniStatCard("المكافآت الشهرية", "${_format(_totalDailyYield * 30)} نجمة", Icons.trending_up, Colors.orangeAccent)),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _buildMiniStatCard("الباقات المكتملة", "0", Icons.check_circle_outline, Colors.greenAccent)),
              const SizedBox(width: 15),
              Expanded(child: _buildMiniStatCard("الباقات النشطة", _activePackages.toString(), Icons.play_circle_outline, Colors.lightBlueAccent)),
            ],
          ),
          
          const SizedBox(height: 25),
          _buildSectionHeader("الباقات النشطة", Icons.inventory_2_outlined),
          const SizedBox(height: 15),
          _buildActivePackagesSection(),
          
          const SizedBox(height: 30),
          _buildSectionHeader("تاريخ الحصاد الأخير", Icons.history),
          const SizedBox(height: 15),
          _buildRecentHarvestList(),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildActivePackagesSection() {
    final user = _auth.currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<List<ActiveReward>>(
      stream: RewardsService().getActiveRewards(user.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));
        final rewards = snapshot.data!;
        
        if (rewards.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: const Column(
              children: [
                Icon(Icons.inventory_2_outlined, color: Colors.white24, size: 40),
                SizedBox(height: 15),
                Text("لا توجد باقات نشطة حالياً", style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          );
        }

        return Column(
          children: rewards.map((reward) {
            final progress = 1.0 - (reward.remainingDays / 30.0);
            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF004D40).withValues(alpha: 0.1), const Color(0xFF00251A).withValues(alpha: 0.3)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.tealAccent.withValues(alpha: 0.2)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.tealAccent.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.diamond, color: Colors.tealAccent, size: 20),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(reward.packageName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            Text("ينتهي في: ${DateFormat('yyyy/MM/dd').format(reward.endTime)}", style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'Orbitron')),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text("+${_format(reward.dailyReward)}", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontFamily: 'Orbitron')),
                          const Text("يومياً", style: TextStyle(color: Colors.white24, fontSize: 9)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      color: Colors.tealAccent,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("المتبقي: ${reward.remainingDays} يوم", style: const TextStyle(color: Colors.white54, fontSize: 10)),
                      Text("${(progress * 100).toInt()}%", style: const TextStyle(color: Colors.tealAccent, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'Orbitron')),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCharts() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSectionHeader("تحليل العوائد", Icons.insights),
          const SizedBox(height: 20),
          _buildLineChart("نمو النجوم الملكية"),
          const SizedBox(height: 30),
          _buildSectionHeader("أداء الباقات", Icons.pie_chart_outline),
          const SizedBox(height: 15),
          _buildPackagesPieChart(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildLineChart(String title) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      const FlSpot(0, 3),
                      const FlSpot(2, 2),
                      const FlSpot(4, 5),
                      const FlSpot(6, 3.5),
                      const FlSpot(8, 4),
                      const FlSpot(10, 7),
                    ],
                    isCurved: true,
                    color: Colors.amber,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.amber.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelProgressCard() {
    double progress = (_totalEarnedStars % 10000) / 10000;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFFFB300), Color(0xFFE65100)]),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.3), blurRadius: 20, spreadRadius: 2)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("المستوى 1", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'Orbitron')),
              Container(
                width: 45, height: 45,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                child: const Center(child: Text("1", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Orbitron'))),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          Text("${(progress * 100).toInt()}% مكتمل", style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'Orbitron')),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Orbitron')),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildPackagesPieChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.white10)),
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 0,
                centerSpaceRadius: 40,
                sections: [
                  PieChartSectionData(color: Colors.redAccent, value: 40, radius: 25, showTitle: false),
                  PieChartSectionData(color: Colors.amber, value: 30, radius: 25, showTitle: false),
                  PieChartSectionData(color: Colors.orange, value: 30, radius: 25, showTitle: false),
                ],
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _chartLegend("المرجان", Colors.redAccent, "287,500"),
              const SizedBox(height: 8),
              _chartLegend("الزمرد", Colors.amber, "565,000"),
              const SizedBox(height: 8),
              _chartLegend("الدر", Colors.orange, "176,500"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chartLegend(String label, Color color, String value) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentHarvestList() {
    if (_history.isEmpty) return const Center(child: Text("لا يوجد سجل حصاد", style: TextStyle(color: Colors.white24)));
    return Column(
      children: _history.take(3).map((item) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(15)),
        child: Row(
          children: [
            const Icon(Icons.history_toggle_off, color: Colors.amber, size: 18),
            const SizedBox(width: 15),
            Text(DateFormat('yyyy/MM/dd').format((item['timestamp'] as Timestamp).toDate()), style: const TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'Orbitron')),
            const Spacer(),
            Text("${_format(item['amount'] ?? 0)} نجمة", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Orbitron')),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.amber, size: 20),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }


  Widget _buildHistory() {
    if (_history.isEmpty) return const Center(child: Text("لا يوجد سجل حصاد حالياً", style: TextStyle(color: Colors.white54)));
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _history.length,
      itemBuilder: (context, i) {
        final item = _history[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("عملية حصاد يومي", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(item['timestamp'] != null ? DateFormat('yyyy/MM/dd').format((item['timestamp'] as Timestamp).toDate()) : "", 
                    style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'Orbitron')
                  )
                ],
              ),
              Text("+${_format(item['amount'] ?? 0)} ⭐", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontFamily: 'Orbitron')),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAchievements() {
    final user = _auth.currentUser;
    if (user == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSectionHeader("خريطة المستويات", Icons.map_outlined),
          const SizedBox(height: 20),
          _buildLevelMap(),
          const SizedBox(height: 30),
          _buildSectionHeader("الأوسمة الملكية", Icons.military_tech),
          const SizedBox(height: 15),
          StreamBuilder<List<RewardAchievement>>(
            stream: RewardsService().getUserAchievements(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.amber));
              }

              final achievements = snapshot.data ?? [];
              if (achievements.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(20),
                  child: const Text("لا توجد أوسمة محققة حالياً. استمر بالحصاد!", 
                    style: TextStyle(color: Colors.white24, fontSize: 12)),
                );
              }

              return Column(
                children: achievements.map((ach) => _achievementItem(
                  ach.id,
                  ach.title, 
                  ach.description, 
                  true, 
                  isClaimed: ach.isClaimed,
                  reward: ach.rewardGems,
                )).toList(),
              );
            },
          ),
          const SizedBox(height: 20),
          const Text("سيتم إضافة المزيد من الأوسمة قريباً...", 
            style: TextStyle(color: Colors.white24, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildLevelMap() {
    final levels = [
      {'name': 'مبتدئ', 'stars': '0', 'reached': true},
      {'name': 'برونزي', 'stars': '50k', 'reached': _totalEarnedStars >= 50000},
      {'name': 'فضي', 'stars': '150k', 'reached': _totalEarnedStars >= 150000},
      {'name': 'ذهبي', 'stars': '500k', 'reached': _totalEarnedStars >= 500000},
      {'name': 'بلاتيني', 'stars': '1M', 'reached': _totalEarnedStars >= 1000000},
      {'name': 'خبير ملكي', 'stars': '5M', 'reached': _totalEarnedStars >= 5000000},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white10),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: levels.length,
        itemBuilder: (context, index) {
          final level = levels[index];
          final bool isReached = level['reached'] as bool;
          final bool isLast = index == levels.length - 1;

          return Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isReached ? Colors.amber : Colors.white10,
                      boxShadow: isReached ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.3), blurRadius: 8)] : null,
                    ),
                    child: Icon(isReached ? Icons.check : Icons.lock, size: 15, color: isReached ? Colors.black : Colors.white30),
                  ),
                  if (!isLast)
                    Container(width: 2, height: 40, color: isReached ? Colors.amber.withValues(alpha: 0.5) : Colors.white10),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(level['name'] as String, style: TextStyle(color: isReached ? Colors.white : Colors.white30, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("المتطلب: ${level['stars']} نجمة", style: TextStyle(color: isReached ? Colors.white54 : Colors.white24, fontSize: 12, fontFamily: 'Orbitron')),
                    const SizedBox(height: 25),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }


  Widget _achievementItem(String id, String t, String d, bool done, {bool isClaimed = false, int reward = 0}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: done ? Colors.amber.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: done ? Colors.amber.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(done ? Icons.emoji_events : Icons.lock_outline, color: done ? Colors.amber : Colors.white24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t, style: TextStyle(color: done ? Colors.white : Colors.white38, fontWeight: FontWeight.bold, fontFamily: 'Orbitron')),
                Text(d, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                if (done && !isClaimed && reward > 0)
                  Text("المكافأة: $reward جوهرة", style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (done && !isClaimed)
            ElevatedButton(
              onPressed: () => _claimAchievement(id),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                minimumSize: const Size(60, 25),
              ),
              child: const Text("مطالبة", style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
            )
          else if (isClaimed)
            const Icon(Icons.check_circle, color: Colors.greenAccent, size: 20)
          else
            const Icon(Icons.lock, color: Colors.white10, size: 16),
        ],
      ),
    );
  }

  Future<void> _claimAchievement(String id) async {
    try {
      await RewardsService().claimAchievementReward(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("تم استلام مكافأة الإنجاز بنجاح! 🎉"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("فشل في استلام المكافأة: $e"), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
        ),
      ),
      child: AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) => Stack(children: List.generate(20, (i) {
          final r = math.Random(i);
          return Positioned(
            left: r.nextDouble() * MediaQuery.of(context).size.width,
            top: (r.nextDouble() * MediaQuery.of(context).size.height + (_rotationController.value * 50)) % MediaQuery.of(context).size.height,
            child: Container(width: 1.5, height: 1.5, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle)),
          );
        })),
      ),
    );
  }
}
