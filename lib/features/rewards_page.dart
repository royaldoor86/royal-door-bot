import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/rewards_models.dart';
import '../models/vip_model.dart';
import '../services/rewards_service.dart';
import '../services/vip_service.dart';
import '../features/rewards_stats_page.dart';
import 'package:lottie/lottie.dart';
import '../constants/rewards_constants.dart';
import 'royal_rewards_marketplace_page.dart';
import 'rewards_leaderboard_page.dart';
import 'rewards_inbox_page.dart';
import '../services/ad_manager.dart';
import '../services/notifications_service.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:confetti/confetti.dart';
import '../widgets/feature_lock_wrapper.dart';

class RewardsPage extends StatefulWidget {
  const RewardsPage({super.key});

  @override
  State<RewardsPage> createState() => _RewardsPageState();
}

class _RewardsPageState extends State<RewardsPage>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late AnimationController _waveController;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final RewardsService _rewardsService = RewardsService();
  bool _isProcessing = false;
  bool _isDarkMode = true;
  late AudioPlayer _audioPlayer;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _rotationController =
        AnimationController(duration: const Duration(seconds: 20), vsync: this);
    _pulseController =
        AnimationController(duration: const Duration(seconds: 2), vsync: this);
    _waveController =
        AnimationController(duration: const Duration(seconds: 3), vsync: this);
    _rotationController.repeat();
    _pulseController.repeat(reverse: true);
    _waveController.repeat();
    _audioPlayer = AudioPlayer();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _runRewardsLifecycle();
  }

  Future<void> _runRewardsLifecycle() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await RewardsService().cleanupExpiredRewards();
      await _rewardsService.processDueDailyRewardsForUser(user.uid,
          isManualActivation: false, adWatched: false);
    } catch (_) {}
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    _audioPlayer.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _playSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/coin_sound.mp3'));
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  String _formatNumber(num number) {
    return NumberFormat.decimalPattern('ar').format(number);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: FeatureLockWrapper(
        lockField: 'isHarvestLocked',
        child: StreamBuilder<DocumentSnapshot>(
          stream: user != null
              ? _db.collection('users').doc(user.uid).snapshots()
              : null,
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return const Scaffold(
                  backgroundColor: Color(0xFF0F2027),
                  body: Center(
                      child: CircularProgressIndicator(
                          color: Colors.amberAccent)));
            }

            final userData = UserModel.fromMap(
                userSnapshot.data!.data() as Map<String, dynamic>,
                userSnapshot.data!.id);

            return FutureBuilder<Map<String, dynamic>>(
                future: _rewardsService.getRewardsSettings(),
                builder: (context, settingsSnapshot) {
                  final isMaintenance = settingsSnapshot
                          .data?[RewardsConstants.configIsMaintenance] ??
                      false;

                  return Scaffold(
                    body: Stack(
                      children: [
                        // Premium Background
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _isDarkMode
                                  ? const [
                                      Color(0xFF0F2027),
                                      Color(0xFF203A43),
                                      Color(0xFF2C5364)
                                    ]
                                  : const [
                                      Color(0xFF4DD0E1),
                                      Color(0xFF26C6DA),
                                      Color(0xFF00BCD4)
                                    ],
                            ),
                          ),
                        ),

                        _buildStarField(),

                        Align(
                          alignment: Alignment.topCenter,
                          child: ConfettiWidget(
                            confettiController: _confettiController,
                            blastDirectionality: BlastDirectionality.explosive,
                            shouldLoop: false,
                            colors: const [
                              Colors.amber,
                              Colors.orange,
                              Colors.yellow,
                              Colors.white
                            ],
                            numberOfParticles: 50,
                            gravity: 0.1,
                          ),
                        ),

                        SafeArea(
                          child: StreamBuilder<List<ActiveReward>>(
                            stream:
                                _rewardsService.getActiveRewards(userData.uid),
                            builder: (context, rewardsSnapshot) {
                              final activeRewards = rewardsSnapshot.data ?? [];
                              double dailyGems = activeRewards.fold(
                                  0, (prev, item) => prev + item.dailyReward);

                              return StreamBuilder<DocumentSnapshot>(
                                stream: _db
                                    .collection('users')
                                    .doc(userData.uid)
                                    .collection('harvest_status')
                                    .doc('harvest')
                                    .snapshots(),
                                builder: (context, statusSnapshot) {
                                  final statusData = statusSnapshot.data?.data()
                                      as Map<String, dynamic>?;
                                  // Calculate activation availability for Active Center Card (Visual only)
                                  bool isActiveStatus = false;
                                  if (statusData != null) {
                                    final lastActivation =
                                        statusData['lastActivation']
                                            as Timestamp?;
                                    if (lastActivation != null) {
                                      final diff = DateTime.now()
                                          .difference(lastActivation.toDate());
                                      if (diff.inSeconds < 24 * 3600) {
                                        isActiveStatus = true;
                                      }
                                    }
                                  }

                                  return Column(
                                    children: [
                                      // 1. TOP NAVIGATION (Advantages, Market, Stats)
                                      _buildTopNav(context, userData),

                                      // Theme Toggle
                                      _buildThemeToggle(),

                                      if (isMaintenance)
                                        Container(
                                          width: double.infinity,
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 20, vertical: 10),
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                              color: Colors.red
                                                  .withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              border: Border.all(
                                                  color: Colors.red
                                                      .withValues(alpha: 0.5))),
                                          child: const Row(children: [
                                            Icon(Icons.warning,
                                                color: Colors.redAccent,
                                                size: 20),
                                            SizedBox(width: 10),
                                            Text(
                                                "النظام في وضع الصيانة حالياً. بعض الميزات معطلة.",
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11))
                                          ]),
                                        ),

                                      Expanded(
                                        child: SingleChildScrollView(
                                          physics:
                                              const BouncingScrollPhysics(),
                                          child: Column(
                                            children: [
                                              const SizedBox(height: 10),
                                              // 2. ROYAL TITLE
                                              _buildRoyalTitle(),
                                              const SizedBox(height: 30),

                                              // 3. WALLET BALANCES
                                              _buildWalletSection(userData),
                                              const SizedBox(height: 40),

                                              // 4. CENTRAL ROYAL ORB
                                              _buildRoyalOrb(
                                                  dailyGems, statusData),
                                              const SizedBox(height: 30),

                                              // 5. ORB ACTIONS (Activation & Packages)
                                              _buildOrbActions(
                                                  userData.uid,
                                                  statusData,
                                                  dailyGems,
                                                  isMaintenance,
                                                  userData),
                                              const SizedBox(height: 30),

                                              // 6. ACTIVE REWARDS CENTER (New Royal Card)
                                              _buildActiveCenterCard(
                                                  isActiveStatus),
                                              const SizedBox(height: 20),

                                              // 7. MARKETPLACE CARD (ADDED BACK)
                                              _buildMarketplacePromoCard(),
                                              const SizedBox(height: 20),

                                              // 8. HELP CENTER
                                              _buildHelpCenterCard(),
                                              const SizedBox(height: 20),

                                              // 9. HARVEST HISTORY
                                              _buildHarvestHistoryCard(
                                                  userData.uid),
                                              const SizedBox(height: 20),

                                              // 10. COMPREHENSIVE STATISTICS DASHBOARD
                                              _buildComprehensiveStatsCard(
                                                  userData.uid),
                                              const SizedBox(height: 20),

                                              // 11. DETAILED STATISTICS
                                              _buildStatisticsCard(
                                                  userData.uid),
                                              const SizedBox(height: 20),

                                              // 12. ACHIEVEMENTS CARD
                                              _buildAchievementsCard(
                                                  userData.uid),
                                              const SizedBox(height: 20),

                                              // 13. VIP STATUS CARD
                                              _buildVIPStatusCard(userData.uid),
                                              const SizedBox(height: 20),

                                              // 14. HARVEST COUNTDOWN TIMER
                                              _buildHarvestCountdownTimer(
                                                  userData.uid),
                                              const SizedBox(height: 20),

                                              // 15. SMART NOTIFICATIONS
                                              _buildSmartNotificationsCard(
                                                  userData.uid),
                                              const SizedBox(height: 20),

                                              // 16. LEADERBOARD CARD
                                              _buildLeaderboardCard(),
                                              const SizedBox(height: 20),

                                              // 17. TIPS AND HINTS CARD
                                              _buildTipsAndHintsCard(),
                                              const SizedBox(height: 20),

                                              // 18. TUTORIAL CARD
                                              _buildTutorialCard(),
                                              const SizedBox(height: 20),

                                              // MISSED REWARD ALERT
                                              _buildMissedRewardAlert(
                                                  userData.uid),
                                              const SizedBox(height: 60),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                });
          },
        ),
      ),
    );
  }

  Widget _buildHelpCenterCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15)),
            child: const Icon(Icons.lightbulb_outline,
                color: Colors.amber, size: 24),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("مركز المساعدة",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        fontFamily: 'Orbitron')),
                SizedBox(height: 4),
                Text("تعرف على كيفية مضاعفة مكافآتك الملكية",
                    style: TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showInstructionsDialog(context),
            icon: const Icon(Icons.arrow_forward_ios,
                color: Colors.white24, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildHarvestHistoryCard(String uid) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.cyanAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15)),
            child:
                const Icon(Icons.history, color: Colors.cyanAccent, size: 24),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("سجل الحصاد",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        fontFamily: 'Orbitron')),
                SizedBox(height: 4),
                Text("عرض تاريخ حصادك السابق",
                    style: TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showHarvestHistoryDialog(uid),
            icon: const Icon(Icons.arrow_forward_ios,
                color: Colors.white24, size: 16),
          ),
        ],
      ),
    );
  }

  void _showHarvestHistoryDialog(String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F2027),
        title: const Text('سجل الحصاد 📊',
            style: TextStyle(
                color: Colors.cyanAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('users')
                .doc(uid)
                .collection('harvest_stats')
                .where('type', isEqualTo: 'harvest')
                .orderBy('timestamp', descending: true)
                .limit(20)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.cyanAccent));
              }
              if (snapshot.data!.docs.isEmpty) {
                return const Center(
                    child: Text('لا يوجد سجل حصاد بعد',
                        style: TextStyle(color: Colors.white38)));
              }
              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final amount = data['amount'] ?? 0;
                  final timestamp = data['timestamp'] as Timestamp?;
                  final date = timestamp != null
                      ? DateFormat('yyyy/MM/dd HH:mm')
                          .format(timestamp.toDate())
                      : 'غير معروف';
                  return ListTile(
                    leading: const Icon(Icons.diamond,
                        color: Colors.cyanAccent, size: 20),
                    title: Text('+${_formatNumber(amount)} جوهرة',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(date,
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12)),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق', style: TextStyle(color: Colors.white24)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard(String uid) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.greenAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15)),
            child: const Icon(Icons.bar_chart,
                color: Colors.greenAccent, size: 24),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("إحصائيات مفصلة",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        fontFamily: 'Orbitron')),
                SizedBox(height: 4),
                Text("عرض إجمالي حصادك منذ البداية",
                    style: TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showStatisticsDialog(uid),
            icon: const Icon(Icons.arrow_forward_ios,
                color: Colors.white24, size: 16),
          ),
        ],
      ),
    );
  }

  void _showStatisticsDialog(String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F2027),
        title: const Text('إحصائيات مفصلة �',
            style: TextStyle(
                color: Colors.greenAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          height: 500,
          child: FutureBuilder<QuerySnapshot>(
            future: _db
                .collection('users')
                .doc(uid)
                .collection('harvest_stats')
                .orderBy('timestamp', descending: true)
                .limit(1000)
                .get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child:
                        CircularProgressIndicator(color: Colors.greenAccent));
              }

              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return const Center(
                  child: Text('لا توجد بيانات حصاد بعد',
                      style: TextStyle(color: Colors.white70)),
                );
              }

              double totalHarvest = 0;
              int harvestCount = 0;
              double maxHarvest = 0;
              List<double> harvestValues = [];

              for (var doc in docs) {
                final data = doc.data() as Map<String, dynamic>;
                if (data['type'] == 'harvest') {
                  final amount = (data['amount'] as num).toDouble();
                  totalHarvest += amount;
                  harvestCount++;
                  harvestValues.add(amount);
                  if (amount > maxHarvest) maxHarvest = amount;
                }
              }

              final avgHarvest =
                  harvestCount > 0 ? totalHarvest / harvestCount : 0;

              return SingleChildScrollView(
                child: Column(
                  children: [
                    _statItem('إجمالي الحصاد', _formatNumber(totalHarvest),
                        Icons.account_balance_wallet, Colors.greenAccent),
                    _statItem('عدد مرات الحصاد', harvestCount.toString(),
                        Icons.history, Colors.blueAccent),
                    _statItem('أعلى حصاد', _formatNumber(maxHarvest),
                        Icons.trending_up, Colors.amber),
                    _statItem('متوسط الحصاد', _formatNumber(avgHarvest),
                        Icons.analytics, Colors.purpleAccent),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 20),
                    const Text('رسم بياني للحصاد',
                        style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    SizedBox(
                      height: 150,
                      child: _buildHarvestChart(harvestValues),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق', style: TextStyle(color: Colors.white24)),
          ),
        ],
      ),
    );
  }

  Widget _buildHarvestChart(List<double> values) {
    if (values.isEmpty) {
      return const Center(
          child:
              Text('لا توجد بيانات', style: TextStyle(color: Colors.white38)));
    }

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final chartValues = values.take(10).toList(); // Show last 10 harvests

    return CustomPaint(
      size: const Size(double.infinity, 150),
      painter: _HarvestChartPainter(chartValues, maxValue),
    );
  }

  Widget _statItem(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 12)),
                Text(value,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        fontFamily: 'Orbitron')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartNotificationsCard(String uid) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.orangeAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15)),
            child: const Icon(Icons.notifications_active,
                color: Colors.orangeAccent, size: 24),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("تنبيهات ذكية",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        fontFamily: 'Orbitron')),
                SizedBox(height: 4),
                Text("تفعيل تنبيهات قبل وقت الحصاد",
                    style: TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showSmartNotificationsDialog(uid),
            icon: const Icon(Icons.arrow_forward_ios,
                color: Colors.white24, size: 16),
          ),
        ],
      ),
    );
  }

  void _showSmartNotificationsDialog(String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F2027),
        title: const Text('تنبيهات ذكية 🔔',
            style: TextStyle(
                color: Colors.orangeAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'تفعيل التنبيهات الذكية سيقوم بإرسال إشعار قبل انتهاء وقت الحصاد بـ 30 دقيقة.',
                style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 20),
            const Text('الميزات:',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _notificationFeature(
                'تنبيه قبل 30 دقيقة من وقت الحصاد', Icons.timer),
            _notificationFeature(
                'تنبيه قبل 1 ساعة من وقت الحصاد', Icons.access_time),
            _notificationFeature('تنبيه عند اقتراب وقت الحصاد', Icons.alarm),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق', style: TextStyle(color: Colors.white24)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('تم تفعيل التنبيهات الذكية ✅'),
                backgroundColor: Colors.green,
              ));
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            child: const Text('تفعيل الآن',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _notificationFeature(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.orangeAccent, size: 16),
          const SizedBox(width: 10),
          Expanded(
              child: Text(text,
                  style: const TextStyle(color: Colors.white70, fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildThemeToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(_isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: Colors.white70, size: 20),
              const SizedBox(width: 12),
              Text(_isDarkMode ? "الوضع الداكن" : "الوضع الفاتح",
                  style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
          Switch(
            value: _isDarkMode,
            onChanged: (value) {
              setState(() {
                _isDarkMode = value;
              });
            },
            activeThumbColor: Colors.purpleAccent,
            activeTrackColor: Colors.purpleAccent.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketplacePromoCard() {
    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const RoyalRewardsMarketplacePage())),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
          ),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
              color: Colors.blueAccent.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle),
              child: const Icon(Icons.storefront_rounded,
                  color: Colors.amber, size: 30),
            ),
            const SizedBox(width: 20),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("سوق بيع الباقات الملكية",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  SizedBox(height: 4),
                  Text("اعرض باقاتك للبيع أو اشترِ باقات بأسعار مميزة",
                      style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white54, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildTopNav(BuildContext context, UserModel userData) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _navActionIcon(Icons.refresh, () => setState(() {}),
                      size: 22, color: Colors.white70),
                  const SizedBox(width: 5),
                  _navActionIcon(
                      Icons.mail_outline_rounded,
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RewardsInboxPage())),
                      size: 22,
                      color: Colors.white70),
                  const SizedBox(width: 5),
                  _navActionIcon(Icons.card_giftcard_rounded,
                      () => _showGiftingDialog(userData),
                      size: 22, color: Colors.pinkAccent),
                  const SizedBox(width: 5),
                  _navActionIcon(
                      Icons.emoji_events_outlined,
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RewardsLeaderboardPage())),
                      size: 22,
                      color: Colors.amber),
                  const SizedBox(width: 5),
                  _navActionIcon(
                      Icons.storefront_rounded,
                      () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const RoyalRewardsMarketplacePage())),
                      size: 22,
                      color: Colors.amber),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text("المكافآت الملكية",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  fontFamily: 'Orbitron')),
          const SizedBox(width: 10),
          _navActionIcon(
              Icons.bar_chart_rounded,
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const RewardsStatsPage())),
              size: 24,
              color: Colors.amber),
          _navActionIcon(Icons.arrow_forward_ios, () => Navigator.pop(context),
              size: 18, color: Colors.white),
        ],
      ),
    );
  }

  Widget _navActionIcon(IconData icon, VoidCallback onTap,
      {double size = 20, Color color = Colors.white70}) {
    return IconButton(
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(),
      icon: Icon(icon, color: color, size: size),
      onPressed: onTap,
    );
  }

  Widget _buildActiveCenterCard(bool isActive) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF004D40).withValues(alpha: 0.4),
            const Color(0xFF00251A).withValues(alpha: 0.6)
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
            color: Colors.tealAccent.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.26),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    shape: BoxShape.circle),
                child: const Icon(Icons.verified_user,
                    color: Colors.amber, size: 20),
              ),
              const Text("مركز المكافآت النشط",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      fontFamily: 'Orbitron')),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.greenAccent.withValues(alpha: 0.5))),
                child: Row(
                  children: [
                    Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                            color: Colors.greenAccent, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    const Text("نشط",
                        style: TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Text("لماذا المكافآت النشطة؟ ✨",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            "طوّر محفظتك الرقمية للحصول على عوائد دورية تراكمية. استبدل جواهرك الآن لتفعيل ميزة \"النمو التلقائي\" واستمتع بمكافآت حصرية تضاف إلى رصيدك كل 30 يوماً.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(15)),
                  child: const Column(
                    children: [
                      Text("إجمالي المكافآت",
                          style:
                              TextStyle(color: Colors.white54, fontSize: 10)),
                      SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.diamond,
                              color: Colors.cyanAccent, size: 14),
                          SizedBox(width: 5),
                          Text("جارية",
                              style: TextStyle(
                                  color: Colors.greenAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(15)),
                  child: const Column(
                    children: [
                      Text("التحديث القادم",
                          style:
                              TextStyle(color: Colors.white54, fontSize: 10)),
                      SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.timer_outlined,
                              color: Colors.cyanAccent, size: 14),
                          SizedBox(width: 5),
                          Text("خلال 30 يوم",
                              style: TextStyle(
                                  color: Colors.cyanAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  fontFamily: 'Orbitron')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoyalTitle() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.amber, Colors.orangeAccent, Colors.amber])
              .createShader(bounds),
          child: const Text("المكافآت الملكية",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Orbitron',
                  letterSpacing: 2)),
        ),
        const Text("نظام المكافآت الملكية المتطور",
            style: TextStyle(
                color: Colors.white54,
                fontSize: 13,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildWalletSection(UserModel userData) {
    // حساب النجوم بناءً على سعر الجواهر (1 جوهرة = 2.6 نجمة)
    const gemsToStarsRate = 2.6;
    final calculatedStars = (userData.harvestWallet * gemsToStarsRate).toInt();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
              child: _glassWalletCard("النجوم الملكية",
                  _formatNumber(calculatedStars), Icons.stars, Colors.amber)),
          const SizedBox(width: 15),
          Expanded(
              child: _glassWalletCard(
                  "الجواهر المتوفرة",
                  _formatNumber(userData.harvestWallet),
                  Icons.diamond,
                  Colors.cyanAccent)),
        ],
      ),
    );
  }

  Widget _glassWalletCard(
      String label, String value, IconData icon, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(label,
                    style: const TextStyle(color: Colors.white70, fontSize: 11))
              ]),
              const SizedBox(height: 10),
              FittedBox(
                  child: Text(value,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Orbitron'))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoyalOrb(double dailyGems, Map<String, dynamic>? statusData) {
    return Center(
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          bool isWaiting = false;
          double progress = 0;
          if (statusData != null) {
            final lastActivation = statusData['lastActivation'] as Timestamp?;
            if (lastActivation != null) {
              final diff = DateTime.now().difference(lastActivation.toDate());
              if (diff.inSeconds < 24 * 3600) {
                isWaiting = true;
                progress = diff.inSeconds / (24 * 3600);
              }
            }
          }

          return Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: (isWaiting ? Colors.orange : Colors.purpleAccent)
                        .withValues(alpha: 0.3 * _pulseController.value),
                    blurRadius: 50,
                    spreadRadius: 15),
                BoxShadow(
                    color: (isWaiting ? Colors.orange : Colors.purpleAccent)
                        .withValues(alpha: 0.1),
                    blurRadius: 80,
                    spreadRadius: 30),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer Glow Ring
                AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) => Transform.rotate(
                    angle: -_rotationController.value * 2 * math.pi,
                    child: Container(
                      width: 270,
                      height: 270,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: (isWaiting
                                      ? Colors.orange
                                      : Colors.purpleAccent)
                                  .withValues(alpha: 0.2),
                              width: 1)),
                    ),
                  ),
                ),
                // Progress Ring
                if (isWaiting)
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 4,
                        backgroundColor: Colors.white10,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.orangeAccent),
                      ),
                    ),
                  ),
                // Rotating Ring with Particles
                AnimatedBuilder(
                  animation: _rotationController,
                  builder: (context, child) => Transform.rotate(
                    angle: _rotationController.value * 2 * math.pi,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white10, width: 2)),
                      child: Stack(children: [
                        Positioned(
                            top: 0,
                            left: 125,
                            child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                    color: Colors.amber,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.amber
                                              .withValues(alpha: 0.5),
                                          blurRadius: 10,
                                          spreadRadius: 5)
                                    ]))),
                        Positioned(
                            bottom: 0,
                            right: 125,
                            child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                    color: Colors.cyanAccent,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.cyanAccent
                                              .withValues(alpha: 0.5),
                                          blurRadius: 8,
                                          spreadRadius: 3)
                                    ]))),
                      ]),
                    ),
                  ),
                ),
                // Main Orb with 3D Effect
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: isWaiting
                              ? [
                                  const Color(0xFF232526),
                                  const Color(0xFF414345),
                                  const Color(0xFF232526)
                                ] // Dull Gray for waiting
                              : [
                                  const Color(0xFF16222A),
                                  const Color(0xFF3A6073),
                                  const Color(0xFF16222A)
                                ] // Active Blue
                          ),
                      boxShadow: [
                        BoxShadow(
                            color: isWaiting
                                ? Colors.orange.withValues(alpha: 0.3)
                                : Colors.purpleAccent.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: const Offset(0, 10)),
                      ]),
                  child: ClipOval(
                    child: AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, child) => CustomPaint(
                          painter: WavePainter(
                              animationValue: _waveController.value,
                              color: isWaiting
                                  ? Colors.grey.withValues(alpha: 0.3)
                                  : Colors.purpleAccent
                                      .withValues(alpha: 0.4))),
                    ),
                  ),
                ),
                // Inner Glow
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [
                        (isWaiting ? Colors.orange : Colors.purpleAccent)
                            .withValues(alpha: 0.1),
                        Colors.transparent,
                      ], stops: const [
                        0,
                        1
                      ])),
                ),
                // Text
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_formatNumber(dailyGems),
                        style: TextStyle(
                            color: isWaiting ? Colors.white38 : Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Orbitron',
                            shadows: [
                              Shadow(
                                  color: (isWaiting
                                          ? Colors.orange
                                          : Colors.purpleAccent)
                                      .withValues(alpha: 0.5),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2))
                            ])),
                    const SizedBox(height: 8),
                    Text(isWaiting ? "جاري التجهيز" : "جاهز للحصاد",
                        style: TextStyle(
                            color:
                                isWaiting ? Colors.white24 : Colors.greenAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                  color: (isWaiting
                                          ? Colors.orange
                                          : Colors.greenAccent)
                                      .withValues(alpha: 0.5),
                                  blurRadius: 5,
                                  offset: const Offset(0, 1))
                            ])),
                    if (isWaiting)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          "${(progress * 100).toInt()}% مكتمل",
                          style: const TextStyle(
                              color: Colors.orangeAccent,
                              fontSize: 11,
                              fontFamily: 'Orbitron',
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrbActions(String uid, Map<String, dynamic>? statusData,
      double dailyGems, bool isMaintenance, UserModel userData) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        bool isWaiting = false;
        if (statusData != null) {
          final lastActivation = statusData['lastActivation'] as Timestamp?;
          if (lastActivation != null) {
            final diff = DateTime.now().difference(lastActivation.toDate());
            if (diff.inSeconds < 24 * 3600) isWaiting = true;
          }
        }

        bool canActivate =
            !isWaiting && (dailyGems > 0) && !isMaintenance && !_isProcessing;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _actionButton(
              icon: isWaiting
                  ? Icons.timer_outlined
                  : (_isProcessing ? Icons.sync : Icons.bolt),
              label: isWaiting
                  ? "انتظار"
                  : (_isProcessing ? "جاري..." : "تفعيل العداد"),
              color: isWaiting ? Colors.orangeAccent : Colors.deepPurpleAccent,
              onTap: !canActivate ? null : () => _onActivateWithAd(uid),
              countdown: isWaiting ? _getCountdownText(statusData) : null,
              isPulse: canActivate,
            ),
            const SizedBox(width: 40),
            _actionButton(
                icon: Icons.shopping_bag_rounded,
                label: "الباقات",
                color: Colors.amber,
                onTap: () => _onOpenStore(userData)),
          ],
        );
      },
    );
  }

  Widget _actionButton(
      {required IconData icon,
      required String label,
      required Color color,
      VoidCallback? onTap,
      String? countdown,
      bool isPulse = false}) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) => Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.1),
                border:
                    Border.all(color: color.withValues(alpha: 0.4), width: 2),
                boxShadow: [
                  if (isPulse)
                    BoxShadow(
                        color: color.withValues(
                            alpha: 0.3 * _pulseController.value),
                        blurRadius: 15,
                        spreadRadius: 2)
                ],
              ),
              child: Icon(icon, color: color, size: 30),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(countdown ?? label,
            style: TextStyle(
                color: countdown != null ? Colors.orangeAccent : Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                fontFamily: countdown != null ? 'Orbitron' : null)),
      ],
    );
  }

  String _getCountdownText(Map<String, dynamic>? statusData) {
    if (statusData == null) return "00:00:00";
    final lastActivation = statusData['lastActivation'] as Timestamp?;
    if (lastActivation == null) return "00:00:00";
    final diff = DateTime.now().difference(lastActivation.toDate());
    final wait = const Duration(hours: 24) - diff;
    if (wait.isNegative) return "00:00:00";
    final hours = wait.inHours.toString().padLeft(2, '0');
    final minutes = (wait.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (wait.inSeconds % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }

  Widget _buildStarField() {
    return Stack(
        children: List.generate(15, (i) {
      final r = math.Random(i);
      return AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) => Positioned(
          left: r.nextDouble() * MediaQuery.of(context).size.width,
          top: (r.nextDouble() * MediaQuery.of(context).size.height +
                  (_rotationController.value * 50)) %
              MediaQuery.of(context).size.height,
          child: Container(
              width: 2,
              height: 2,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle)),
        ),
      );
    }));
  }

  // --- Actions & Helpers ---

  void _onActivateWithAd(String uid) {
    HapticFeedback.mediumImpact();
    _playSound();

    final adManager = AdManager();

    if (adManager.isFallbackEnabled) {
      _showFallbackActivationDialog(uid);
      return;
    }

    if (!adManager.isLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('جاري تجهيز الإعلان... يرجى الانتظار ثواني'),
          backgroundColor: Colors.orange));
      adManager.loadRewardedAd();
      return;
    }

    adManager.showRewardedAd(onUserEarnedReward: (RewardItem? reward) {
      _activateDailyReward(uid);
    }, onAdFailed: () {
      if (adManager.isFallbackEnabled) {
        _activateDailyReward(uid);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('فشل عرض الإعلان، حاول مرة أخرى'),
            backgroundColor: Colors.redAccent));
      }
    });
  }

  void _showFallbackActivationDialog(String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F2027),
        title: const Text('تنبيه ملكي 👑',
            style: TextStyle(color: Colors.amber, fontSize: 18)),
        content: const Text(
          'نعتذر، يبدو أن هناك مشكلة في مزود الإعلانات حالياً.\n\nتقديراً لولائك، سنسمح لك بتفعيل العداد الآن بدون إعلان لضمان عدم ضياع مكافآتك.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white24)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _activateDailyReward(uid);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
            child: const Text('تفعيل الآن',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _activateDailyReward(String uid) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    // التحقق من حالة الحظر
    final userDoc = await _db.collection('users').doc(uid).get();
    if (userDoc.exists && (userDoc.data()?['isBanned'] ?? false)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('حسابك محظور حالياً. لا يمكنك استخدام هذه الميزة.'),
          backgroundColor: Colors.redAccent,
        ));
      }
      setState(() => _isProcessing = false);
      return;
    }

    try {
      final totalHarvested =
          await _rewardsService.processDueDailyRewardsForUser(
        uid,
        isManualActivation: true,
        adWatched: true,
      );

      if (totalHarvested > 0) {
        _showSuccessAnimation(totalHarvested);
        // جدولة تنبيه للمرة القادمة
        NotificationsService.scheduleHarvestReminder();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('لا توجد مكافآت مستحقة حالياً أو تم الحصاد مسبقاً'),
            backgroundColor: Colors.blueGrey,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('خطأ: $e'), backgroundColor: Colors.redAccent));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _onOpenStore(UserModel userData) {
    HapticFeedback.selectionClick();
    _showPackageStoreDialog(userData);
  }

  void _showPackageStoreDialog(UserModel userData) {
    final packages = [
      {
        'name': 'الدر',
        'cost': 38500,
        'total': 40400,
        'color': Colors.amber,
        'icon': Icons.diamond
      },
      {
        'name': 'المرجان',
        'cost': 77000,
        'total': 80800,
        'color': Colors.orange,
        'icon': Icons.favorite
      },
      {
        'name': 'العقيق',
        'cost': 115000,
        'total': 121000,
        'color': Colors.redAccent,
        'icon': Icons.stars
      },
      {
        'name': 'الكريستال',
        'cost': 192000,
        'total': 201600,
        'color': Colors.cyanAccent,
        'icon': Icons.auto_awesome
      },
      {
        'name': 'الزبرجد',
        'cost': 288000,
        'total': 302400,
        'color': Colors.greenAccent,
        'icon': Icons.brightness_high
      },
      {
        'name': 'اللؤلؤ',
        'cost': 385000,
        'total': 404200,
        'color': Colors.white,
        'icon': Icons.circle
      },
      {
        'name': 'الفيروز',
        'cost': 462000,
        'total': 484600,
        'color': Colors.tealAccent,
        'icon': Icons.diamond_sharp
      },
      {
        'name': 'الماس',
        'cost': 500000,
        'total': 525000,
        'color': Colors.blueAccent,
        'icon': Icons.diamond_outlined
      },
      {
        'name': 'الزمرد',
        'cost': 538000,
        'total': 565000,
        'color': Colors.green,
        'icon': Icons.pentagon
      },
      {
        'name': 'الياقوت',
        'cost': 577000,
        'total': 606000,
        'color': Colors.red,
        'icon': Icons.favorite_border
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 20),
        decoration: const BoxDecoration(
            color: Color(0xFF0F2027),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('مركز المكافآت الملكية 👑',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Orbitron')),
                TextButton(
                  onPressed: () => _showPackageComparisonDialog(packages),
                  child: const Text('مقارنة الباقات',
                      style: TextStyle(color: Colors.cyanAccent, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: packages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) =>
                    _buildPackageCard(packages[index], userData),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageCard(Map<String, dynamic> plan, UserModel userData) {
    final color = plan['color'] as Color;
    final cost = (plan['cost'] as num).toDouble();
    final total = (plan['total'] as num).toDouble();
    final daily = total / 30;
    final netProfit = total - cost;
    final canAfford = userData.harvestWallet >= cost;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]),
                child: Icon(plan['icon'] as IconData, color: color, size: 28),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan['name'].toString(),
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            fontFamily: 'Orbitron')),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Colors.white38, size: 12),
                        const SizedBox(width: 4),
                        Text("صلاحية 30 يوم",
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("سعر الشراء",
                      style: TextStyle(color: Colors.white38, fontSize: 9)),
                  Row(
                    children: [
                      const Icon(Icons.diamond, color: Colors.amber, size: 14),
                      const SizedBox(width: 4),
                      Text(_formatNumber(cost),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              fontFamily: 'Orbitron')),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: Colors.white10, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _packageStatWithIcon(
                  "النمو اليومي",
                  "+${_formatNumber(daily.toInt())}",
                  Colors.cyanAccent,
                  Icons.trending_up),
              _packageStatWithIcon("الإجمالي", _formatNumber(total),
                  Colors.amber, Icons.account_balance_wallet),
              _packageStatWithIcon(
                  "الربح",
                  "+${_formatNumber(netProfit.toInt())}",
                  Colors.greenAccent,
                  Icons.attach_money),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canAfford ? () => _purchase(userData.uid, plan) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canAfford ? color : Colors.white10,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                elevation: canAfford ? 5 : 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (canAfford) ...[
                    const Icon(Icons.shopping_cart, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    canAfford ? "شراء وتفعيل الباقة" : "رصيد جواهر غير كافٍ",
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _packageStatWithIcon(
      String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(color: Colors.white38, fontSize: 9)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                fontFamily: 'Orbitron')),
      ],
    );
  }

  Future<void> _purchase(String uid, Map<String, dynamic> plan) async {
    Navigator.pop(context);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.amberAccent)),
    );

    try {
      await _rewardsService.purchaseReward(
        packageName: plan['name'].toString(),
        rewardAmount: (plan['cost'] as num).toDouble(),
        totalReward: (plan['total'] as num).toDouble(),
        dailyReward: (plan['total'] as num) / 30,
        durationDays: 30,
        paymentMethod: 'gems',
      );

      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        _showSuccessPurchaseDialog(
            plan['name'].toString(), (plan['total'] as num).toDouble());

        // إظهار إعلان ملء الشاشة بعد شراء باقة المكافآت
        AdManager().showInterstitialAd();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('خطأ في عملية الشراء: $e'),
            backgroundColor: Colors.redAccent));
      }
    }
  }

  void _showSuccessPurchaseDialog(String name, double total) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F2027),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset('assets/lottie/frame.json', width: 150, repeat: false),
            const Text('تهانينا! 👑',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron')),
            const SizedBox(height: 10),
            Text('لقد قمت بتفعيل باقة $name بنجاح.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 5),
            Text('إجمالي النجوم: ${_formatNumber(total)}',
                style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Orbitron')),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black),
                child: const Text('رائع'))
          ],
        ),
      ),
    );
  }

  void _showPackageComparisonDialog(List<Map<String, dynamic>> packages) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F2027),
        title: const Text('مقارنة الباقات 📊',
            style: TextStyle(
                color: Colors.cyanAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: packages.length,
            itemBuilder: (context, index) {
              final package = packages[index];
              final cost = (package['cost'] as num).toDouble();
              final total = (package['total'] as num).toDouble();
              final daily = total / 30;
              final roi = ((total - cost) / cost * 100).toStringAsFixed(1);

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(package['icon'] as IconData,
                            color: package['color'] as Color, size: 20),
                        const SizedBox(width: 10),
                        Text(package['name'].toString(),
                            style: TextStyle(
                                color: package['color'] as Color,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _comparisonItem('التكلفة', _formatNumber(cost)),
                        _comparisonItem('الإجمالي', _formatNumber(total)),
                        _comparisonItem('اليومي', _formatNumber(daily)),
                        _comparisonItem('العائد', '$roi%'),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق', style: TextStyle(color: Colors.white24)),
          ),
        ],
      ),
    );
  }

  Widget _comparisonItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9)),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11)),
      ],
    );
  }

  Widget _buildMissedRewardAlert(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('users')
          .doc(uid)
          .collection('harvest_stats')
          .where('type', isEqualTo: 'missed_harvest_penalty')
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }
        final docId = snapshot.data!.docs.first.id;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3))),
          child: Row(children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            const SizedBox(width: 12),
            const Expanded(
                child: Text(
                    'تنبيه: لقد فقدت مكافآت بسبب عدم تفعيل العداد يدوياً.',
                    style: TextStyle(color: Colors.white70, fontSize: 11))),
            IconButton(
                icon:
                    const Icon(Icons.close, color: Colors.redAccent, size: 18),
                onPressed: () async {
                  await _db
                      .collection('users')
                      .doc(uid)
                      .collection('harvest_stats')
                      .doc(docId)
                      .update({'isRead': true});
                })
          ]),
        );
      },
    );
  }

  void _showInstructionsDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F2027),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.only(
          top: 20,
          left: 25,
          right: 25,
          bottom: MediaQuery.of(context).padding.bottom + 25,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const Text(
              "دليل الحصاد الملكي 👑",
              style: TextStyle(
                color: Colors.amber,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                fontFamily: 'Orbitron',
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              "هنا يمكنك تفعيل عداد الحصاد كل 24 ساعة لاستلام نمو النجوم من الباقات النشطة بالمزايا الملكية.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 10),
            const Text(
              "تأكد من العودة يومياً لتفعيل الحصاد يدوياً لضمان عدم ضياع النمو اليومي.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _showGiftingDialog(UserModel userData) {
    final TextEditingController idController = TextEditingController();
    final TextEditingController amountController = TextEditingController();
    String selectedCurrency = 'gems';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF0F2027),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.pinkAccent, width: 1)),
          title: const Text('إرسال هدية ملكية 🎁',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('حول رصيدك لأي مستخدم في المملكة فوراً',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 20),
                _giftField(idController, 'الآيدي الملكي (Royal ID)',
                    Icons.person_search),
                const SizedBox(height: 15),
                _giftField(
                    amountController, 'المبلغ', Icons.account_balance_wallet,
                    isNumber: true),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(15)),
                  child: DropdownButton<String>(
                    value: selectedCurrency,
                    dropdownColor: const Color(0xFF0F2027),
                    underline: const SizedBox(),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                          value: 'gems',
                          child: Text('جواهر 💎',
                              style: TextStyle(color: Colors.white))),
                      DropdownMenuItem(
                          value: 'stars',
                          child: Text('نجوم ⭐',
                              style: TextStyle(color: Colors.white))),
                    ],
                    onChanged: (val) =>
                        setDialogState(() => selectedCurrency = val!),
                  ),
                ),
                const SizedBox(height: 10),
                const Text('سيتم استقطاع 5% رسوم لدعم صندوق المملكة',
                    style: TextStyle(color: Colors.pinkAccent, fontSize: 10)),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء',
                    style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text) ?? 0;
                if (amount <= 0 || idController.text.isEmpty) return;

                Navigator.pop(context);
                _processGift(idController.text, amount,
                    currency: selectedCurrency);
              },
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.pinkAccent),
              child: const Text('إرسال الآن',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _giftField(
      TextEditingController controller, String label, IconData icon,
      {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.pinkAccent, size: 18),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 12),
        enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white10),
            borderRadius: BorderRadius.circular(15)),
        focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.pinkAccent),
            borderRadius: BorderRadius.circular(15)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.02),
      ),
    );
  }

  Future<void> _processGift(String targetId, double amount,
      {required String currency}) async {
    // التحقق من الرصيد قبل الإرسال
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
    final userDoc = await _db.collection('users').doc(currentUserId).get();
    final userData = userDoc.data();

    if (userData == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('خطأ: لم يتم العثور على بياناتك'),
            backgroundColor: Colors.redAccent));
      }
      return;
    }

    double currentBalance = 0;
    if (currency == 'gems') {
      currentBalance = (userData['harvestWallet'] ??
              userData['rewards_wallet_gems'] ??
              userData['harvest_wallet'] ??
              0)
          .toDouble();
    } else if (currency == 'stars') {
      currentBalance = (userData['starsHarvestWallet'] ??
              userData['rewards_wallet_stars'] ??
              userData['harvest_stars_wallet'] ??
              0)
          .toDouble();
    }

    if (currentBalance < amount) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('رصيدك غير كافٍ لإرسال هذه الهدية'),
            backgroundColor: Colors.redAccent));
      }
      return;
    }

    try {
      await _rewardsService.transferRoyalGifts(
        senderId: currentUserId,
        recipientRoyalId: targetId,
        amount: amount,
        currency: currency,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('تم إرسال الهدية بنجاح! 🎁'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('خطأ في الإرسال: $e'),
            backgroundColor: Colors.redAccent));
      }
    }
  }

  void _showSuccessAnimation(double reward) {
    _triggerHeavyImpact();
    _playSound();
    _confettiController.play();
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF0F2027),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              Lottie.asset('assets/lottie/frame.json', width: 150),
              const Text('تم الحصاد بنجاح! 🎉',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Orbitron')),
              Text('+${_formatNumber(reward)} جوهرة',
                  style: const TextStyle(
                      color: Colors.amber,
                      fontFamily: 'Orbitron',
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ElevatedButton(
                  onPressed: () {
                    _triggerSelectionFeedback();
                    Navigator.pop(context);
                  },
                  child: const Text('استمرار'))
            ])));
  }

  Widget _buildComprehensiveStatsCard(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('users')
          .doc(userId)
          .collection('active_rewards')
          .snapshots(),
      builder: (context, activeSnapshot) {
        final activeRewards = activeSnapshot.data?.docs ?? [];
        final activeCount = activeRewards.length;

        return StreamBuilder<QuerySnapshot>(
          stream: _db
              .collection('users')
              .doc(userId)
              .collection('completed_rewards')
              .snapshots(),
          builder: (context, completedSnapshot) {
            final completedRewards = completedSnapshot.data?.docs ?? [];
            final completedCount = completedRewards.length;

            return StreamBuilder<DocumentSnapshot>(
              stream: _db.collection('users').doc(userId).snapshots(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) return const SizedBox();

                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>?;
                final totalGems = (userData?['harvestWallet'] ?? 0).toDouble();
                final totalStars =
                    (userData?['starsHarvestWallet'] ?? 0).toDouble();

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _isDarkMode
                          ? [const Color(0xFF1A237E), const Color(0xFF311B92)]
                          : [const Color(0xFFE8EAF6), const Color(0xFFC5CAE9)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.purpleAccent.withValues(alpha: 0.3),
                        width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.analytics_outlined,
                                color: Colors.purpleAccent, size: 28),
                            const SizedBox(width: 12),
                            const Text(
                              'لوحة الإحصائيات الشاملة',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatItem(
                                '💎 الجواهر',
                                _formatNumber(totalGems),
                                Colors.amber,
                              ),
                            ),
                            Expanded(
                              child: _buildStatItem(
                                '⭐ النجوم',
                                _formatNumber(totalStars),
                                Colors.purpleAccent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatItem(
                                '📦 باقات نشطة',
                                '$activeCount',
                                Colors.greenAccent,
                              ),
                            ),
                            Expanded(
                              child: _buildStatItem(
                                '✅ باقات مكتملة',
                                '$completedCount',
                                Colors.blueAccent,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsCard(String userId) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDarkMode
              ? [const Color(0xFF1A237E), const Color(0xFF311B92)]
              : [const Color(0xFFE8EAF6), const Color(0xFFC5CAE9)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.purpleAccent.withValues(alpha: 0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emoji_events_outlined,
                    color: Colors.amber, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'الإنجازات',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('users')
                  .doc(userId)
                  .collection('user_achievements')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child:
                        CircularProgressIndicator(color: Colors.purpleAccent),
                  );
                }

                final achievements = snapshot.data!.docs;
                if (achievements.isEmpty) {
                  return const Center(
                    child: Text(
                      'لا توجد إنجازات بعد',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: achievements.map((doc) {
                    final achievement = doc.data() as Map<String, dynamic>;
                    final title = achievement['title'] ?? '';
                    final icon = achievement['icon'] ?? '🏆';
                    final status = achievement['status'] ?? 'locked';
                    final isUnlocked =
                        status == 'unlocked' || status == 'claimed';

                    return AnimatedCard(
                      onTap: () {
                        _triggerSelectionFeedback();
                        _showAchievementDetails(achievement);
                      },
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isUnlocked
                                ? [
                                    Colors.amber.withValues(alpha: 0.3),
                                    Colors.orange.withValues(alpha: 0.1)
                                  ]
                                : [
                                    Colors.grey.withValues(alpha: 0.2),
                                    Colors.grey.withValues(alpha: 0.1)
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isUnlocked
                                ? Colors.amber.withValues(alpha: 0.5)
                                : Colors.grey.withValues(alpha: 0.3),
                            width: 2,
                          ),
                          boxShadow: isUnlocked
                              ? [
                                  BoxShadow(
                                    color: Colors.amber.withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              icon,
                              style: TextStyle(
                                fontSize: 32,
                                color: isUnlocked
                                    ? null
                                    : Colors.grey.withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              title.length > 8
                                  ? '${title.substring(0, 8)}...'
                                  : title,
                              style: TextStyle(
                                color: isUnlocked
                                    ? Colors.white
                                    : Colors.grey.withValues(alpha: 0.7),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAchievementDetails(Map<String, dynamic> achievement) {
    final title = achievement['title'] ?? '';
    final description = achievement['description'] ?? '';
    final icon = achievement['icon'] ?? '🏆';
    final rewardGems = achievement['rewardGems'] ?? 0;
    final rewardStars = achievement['rewardStars'] ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F2027),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (rewardGems > 0 || rewardStars > 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (rewardGems > 0)
                      Text(
                        '+$rewardGems 💎',
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (rewardGems > 0 && rewardStars > 0)
                      const SizedBox(width: 16),
                    if (rewardStars > 0)
                      Text(
                        '+$rewardStars ⭐',
                        style: const TextStyle(
                          color: Colors.purpleAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _triggerSelectionFeedback();
                Navigator.pop(context);
              },
              child: const Text('إغلاق'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVIPStatusCard(String userId) {
    return FutureBuilder<VIPStatus>(
      future: VIPService.getUserVIPStatus(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.purpleAccent),
          );
        }

        final vipStatus = snapshot.data!;
        final isVIP = vipStatus.isActive && !vipStatus.isExpired;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isVIP
                  ? [
                      vipStatus.levelColor.withValues(alpha: 0.3),
                      vipStatus.levelColor.withValues(alpha: 0.1)
                    ]
                  : (_isDarkMode
                      ? [const Color(0xFF1A237E), const Color(0xFF311B92)]
                      : [const Color(0xFFE8EAF6), const Color(0xFFC5CAE9)]),
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isVIP
                  ? vipStatus.levelColor
                  : Colors.purpleAccent.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      vipStatus.levelIcon,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isVIP
                                ? 'حالة VIP: ${vipStatus.levelName}'
                                : 'حالة VIP: غير VIP',
                            style: TextStyle(
                              color:
                                  isVIP ? vipStatus.levelColor : Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (isVIP && vipStatus.expiresAt != null)
                            Text(
                              'ينتهي خلال ${vipStatus.daysUntilExpiry} يوم',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!isVIP)
                      ElevatedButton(
                        onPressed: () {
                          // Show VIP packages dialog
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: const Text(
                          'ترقية',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
                if (isVIP)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'المزايا الحالية:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _buildVIPBenefit('مكافأة الحصاد',
                            '${(vipStatus.harvestBonus * 100).toInt()}%'),
                        _buildVIPBenefit('مكافأة التحويل',
                            '${(vipStatus.conversionBonus * 100).toInt()}%'),
                        _buildVIPBenefit('الحد الأقصى للباقات',
                            '${vipStatus.maxActivePackages}'),
                        _buildVIPBenefit(
                            'نقاط النشاط', '${vipStatus.activityPoints}'),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVIPBenefit(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHarvestCountdownTimer(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('users')
          .doc(userId)
          .collection('active_rewards')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final rewards = snapshot.data!.docs;
        if (rewards.isEmpty) {
          return const SizedBox();
        }

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _isDarkMode
                  ? [const Color(0xFF1A237E), const Color(0xFF311B92)]
                  : [const Color(0xFFE8EAF6), const Color(0xFFC5CAE9)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: Colors.greenAccent.withValues(alpha: 0.3), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.timer_outlined,
                        color: Colors.greenAccent, size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      'مؤقت الحصاد',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rewards.length,
                  itemBuilder: (context, index) {
                    final reward =
                        rewards[index].data() as Map<String, dynamic>;
                    final packageName = reward['packageName'] ?? 'Unknown';
                    final lastRewardDate =
                        (reward['lastRewardDate'] as Timestamp?)?.toDate();
                    final dailyReward = reward['dailyReward'] ?? 0;

                    if (lastRewardDate == null) {
                      return _buildCountdownItem(
                          packageName, dailyReward, 'متاح الآن', true);
                    }

                    final nextAvailable =
                        lastRewardDate.add(const Duration(hours: 24));
                    final now = DateTime.now();
                    final isAvailable = now.isAfter(nextAvailable);

                    if (isAvailable) {
                      return _buildCountdownItem(
                          packageName, dailyReward, 'متاح الآن', true);
                    }

                    final remaining = nextAvailable.difference(now);
                    return _buildCountdownItem(packageName, dailyReward,
                        _formatDuration(remaining), false);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCountdownItem(
      String packageName, double reward, String timeText, bool isAvailable) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isAvailable
            ? Colors.greenAccent.withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isAvailable
              ? Colors.greenAccent.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  packageName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '+${_formatNumber(reward)} 💎',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            timeText,
            style: TextStyle(
              color: isAvailable ? Colors.greenAccent : Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.bold,
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
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildLeaderboardCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDarkMode
              ? [const Color(0xFF1A237E), const Color(0xFF311B92)]
              : [const Color(0xFFE8EAF6), const Color(0xFFC5CAE9)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.orangeAccent.withValues(alpha: 0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.leaderboard_outlined,
                    color: Colors.orangeAccent, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'المتصدرون',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('users')
                  .orderBy('totalHarvested', descending: true)
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child:
                        CircularProgressIndicator(color: Colors.orangeAccent),
                  );
                }

                final users = snapshot.data!.docs;
                if (users.isEmpty) {
                  return const Center(
                    child: Text(
                      'لا توجد بيانات بعد',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final userData =
                        users[index].data() as Map<String, dynamic>;
                    final username =
                        userData['username'] ?? 'مستخدم ${index + 1}';
                    final totalHarvested = userData['totalHarvested'] ?? 0;
                    final rank = index + 1;

                    Color rankColor;
                    IconData rankIcon;
                    if (rank == 1) {
                      rankColor = Colors.amber;
                      rankIcon = Icons.emoji_events;
                    } else if (rank == 2) {
                      rankColor = Colors.grey;
                      rankIcon = Icons.emoji_events;
                    } else if (rank == 3) {
                      rankColor = Colors.brown;
                      rankIcon = Icons.emoji_events;
                    } else {
                      rankColor = Colors.white70;
                      rankIcon = Icons.person;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: rankColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Icon(
                                rankIcon,
                                color: rankColor,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  username,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'المرتبة #$rank',
                                  style: TextStyle(
                                    color: rankColor,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${_formatNumber(totalHarvested)} 💎',
                            style: const TextStyle(
                              color: Colors.amber,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsAndHintsCard() {
    final tips = [
      {
        'icon': '💎',
        'title': 'الحصاد اليومي',
        'description': 'احصد مكافآتك اليومية كل 24 ساعة لزيادة أرباحك',
      },
      {
        'icon': '📦',
        'title': 'شراء الباقات',
        'description': 'استثمر في الباقات للحصول على أرباح يومية لمدة 31 يوماً',
      },
      {
        'icon': '⭐',
        'title': 'تحويل النجوم',
        'description': 'بعد 31 يوماً، يتم تحويل الباقة تلقائياً إلى نجوم',
      },
      {
        'icon': '🏆',
        'title': 'الإنجازات',
        'description': 'أكمل المهام واحصل على مكافآت إضافية',
      },
      {
        'icon': '👑',
        'title': 'نظام VIP',
        'description': 'احصل على عضوية VIP لمكافآت إضافية ومزايا خاصة',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isDarkMode
              ? [const Color(0xFF1A237E), const Color(0xFF311B92)]
              : [const Color(0xFFE8EAF6), const Color(0xFFC5CAE9)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: Colors.cyanAccent.withValues(alpha: 0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb_outline,
                    color: Colors.cyanAccent, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'نصائح وإرشادات',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tips.length,
              itemBuilder: (context, index) {
                final tip = tips[index];
                return AnimatedCard(
                  onTap: () {
                    _triggerSelectionFeedback();
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          tip['icon'] ?? '💡',
                          style: const TextStyle(fontSize: 28),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tip['title'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tip['description'] ?? '',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialCard() {
    return AnimatedCard(
      onTap: () {
        _triggerMediumImpact();
        _showTutorialDialog();
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isDarkMode
                ? [const Color(0xFF1A237E), const Color(0xFF311B92)]
                : [const Color(0xFFE8EAF6), const Color(0xFFC5CAE9)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: Colors.pinkAccent.withValues(alpha: 0.3), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.school_outlined, color: Colors.pinkAccent, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'دليل المستخدم',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'تعلم كيفية استخدام التطبيق',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.pinkAccent, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showTutorialDialog() {
    final tutorialSteps = [
      {
        'title': 'مرحباً بك في نظام المكافآت الملكي',
        'description':
            'اكتشف كيفية كسب الجواهر والنجوم من خلال نظام المكافآت المتطور',
        'icon': '👋',
      },
      {
        'title': 'شراء الباقات',
        'description':
            'اختر من بين مجموعة متنوعة من الباقات وابدأ في كسب الأرباح اليومية',
        'icon': '📦',
      },
      {
        'title': 'الحصاد اليومي',
        'description': 'احصد مكافآتك كل 24 ساعة بعد مشاهدة الإعلان',
        'icon': '💎',
      },
      {
        'title': 'تحويل النجوم',
        'description': 'بعد 31 يوماً، يتم تحويل الباقة تلقائياً إلى نجوم',
        'icon': '⭐',
      },
      {
        'title': 'الإنجازات',
        'description': 'أكمل المهام واحصل على مكافآت إضافية',
        'icon': '🏆',
      },
      {
        'title': 'نظام VIP',
        'description': 'احصل على عضوية VIP لمكافآت إضافية ومزايا خاصة',
        'icon': '👑',
      },
    ];

    int currentStep = 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF0F2027),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tutorialSteps[currentStep]['icon'] ?? '',
                  style: const TextStyle(fontSize: 64),
                ),
                const SizedBox(height: 16),
                Text(
                  tutorialSteps[currentStep]['title'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  tutorialSteps[currentStep]['description'] ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (currentStep > 0)
                      TextButton(
                        onPressed: () {
                          _triggerSelectionFeedback();
                          setState(() => currentStep--);
                        },
                        child: const Text('السابق'),
                      ),
                    Row(
                      children: List.generate(
                        tutorialSteps.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: index == currentStep
                                ? Colors.pinkAccent
                                : Colors.grey.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    if (currentStep < tutorialSteps.length - 1)
                      ElevatedButton(
                        onPressed: () {
                          _triggerSelectionFeedback();
                          setState(() => currentStep++);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.pinkAccent,
                        ),
                        child: const Text('التالي'),
                      )
                    else
                      ElevatedButton(
                        onPressed: () {
                          _triggerSelectionFeedback();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                        ),
                        child: const Text('بدء'),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _triggerMediumImpact() {
    try {
      HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint('Haptic feedback error: $e');
    }
  }

  void _triggerHeavyImpact() {
    try {
      HapticFeedback.heavyImpact();
    } catch (e) {
      debugPrint('Haptic feedback error: $e');
    }
  }

  void _triggerSelectionFeedback() {
    try {
      HapticFeedback.selectionClick();
    } catch (e) {
      debugPrint('Haptic feedback error: $e');
    }
  }
}

enum NotificationType {
  success,
  error,
  warning,
  info,
}

class PageTransition {
  static Widget slideTransition(Widget child) {
    return AnimatedBuilder(
      animation: const AlwaysStoppedAnimation(0.0),
      builder: (context, child) {
        return child!;
      },
      child: child,
    );
  }

  static Widget fadeTransition(Widget child) {
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      child: child,
    );
  }

  static Widget scaleTransition(Widget child) {
    return AnimatedScale(
      scale: 1.0,
      duration: const Duration(milliseconds: 300),
      child: child,
    );
  }
}

class AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration duration;

  const AnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

class FadeInWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  const FadeInWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
  });

  @override
  State<FadeInWidget> createState() => _FadeInWidgetState();
}

class _FadeInWidgetState extends State<FadeInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: widget.child,
    );
  }
}

class SlideInWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;
  final SlideDirection direction;

  const SlideInWidget({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
    this.direction = SlideDirection.up,
  });

  @override
  State<SlideInWidget> createState() => _SlideInWidgetState();
}

class _SlideInWidgetState extends State<SlideInWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    Offset beginOffset;
    switch (widget.direction) {
      case SlideDirection.up:
        beginOffset = const Offset(0, 0.3);
        break;
      case SlideDirection.down:
        beginOffset = const Offset(0, -0.3);
        break;
      case SlideDirection.left:
        beginOffset = const Offset(0.3, 0);
        break;
      case SlideDirection.right:
        beginOffset = const Offset(-0.3, 0);
        break;
    }

    _slideAnimation =
        Tween<Offset>(begin: beginOffset, end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: widget.child,
    );
  }
}

enum SlideDirection {
  up,
  down,
  left,
  right,
}

class WavePainter extends CustomPainter {
  final double animationValue;
  final Color color;
  WavePainter({required this.animationValue, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    final yOffset = size.height * 0.6;
    path.moveTo(0, size.height);
    for (double x = 0; x <= size.width; x++) {
      double y = yOffset +
          math.sin((x / size.width * 2 * math.pi) +
                  (animationValue * 2 * math.pi)) *
              12;
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant WavePainter oldDelegate) => true;
}

class _HarvestChartPainter extends CustomPainter {
  final List<double> values;
  final double maxValue;

  _HarvestChartPainter(this.values, this.maxValue);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paint = Paint()
      ..color = Colors.greenAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final fillPaint = Paint()
      ..color = Colors.greenAccent.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    final barWidth = size.width / values.length;
    final spacing = barWidth * 0.2;

    for (int i = 0; i < values.length; i++) {
      final value = values[i];
      final normalizedValue = value / maxValue;
      final barHeight = normalizedValue * (size.height - 20);
      final x = i * barWidth + spacing / 2;
      final y = size.height - barHeight;

      // Draw bar
      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth - spacing, barHeight),
        const Radius.circular(4),
      );

      canvas.drawRRect(barRect, fillPaint);
      canvas.drawRRect(barRect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HarvestChartPainter oldDelegate) => true;
}
