import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import '../../theme/design_tokens.dart';
import '../../theme/reusable_widgets.dart';
import '../../theme/app_theme.dart';
import '../../services/ad_manager.dart';
import '../../services/task_tracking_service.dart';
import '../../services/notifications_service.dart';
import 'royal_articles_page.dart';

class RoyalTaskCenterPage extends StatefulWidget {
  const RoyalTaskCenterPage({super.key});

  @override
  State<RoyalTaskCenterPage> createState() => _RoyalTaskCenterPageState();
}

class _RoyalTaskCenterPageState extends State<RoyalTaskCenterPage> {
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  final AdManager _adManager = AdManager();
  Offset _chestOffset = const Offset(20, 500);
  int _secondsToNextChest = 3600;
  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;
  
  @override
  void initState() {
    super.initState();
    _startChestTimer();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = _adManager.getBannerAd(
      size: AdSize.banner,
      onAdLoaded: () => setState(() => _isBannerLoaded = true),
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  void _startChestTimer() {
    Stream.periodic(const Duration(seconds: 1)).listen((_) {
      if (_secondsToNextChest > 0 && mounted) {
        setState(() => _secondsToNextChest--);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF050505),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            
            final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            final int taskStep = userData['reward_task_step'] ?? 1; // عداد التسلسل

            return Stack(
              children: [
                CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildRoyalHeader(userData),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Column(
                          children: [
                            const SizedBox(height: 20),
                            _buildSectionLabel('رحلة المكافآت الملكية 👑'),
                            const SizedBox(height: 10),
                            
                            // نظام ساعة الحظ (تنبيه مرئي)
                            _buildGoldenHourStatus(),
                            const SizedBox(height: 15),

                            // بنك العملات (Savings Vault)
                            _buildSavingsVault(userData),
                            const SizedBox(height: 25),
                            
                            // 1. مهمة إعلان فيديو (2 جوهرة)
                            _buildTaskItem(
                              title: 'مشاهدة فيديو سريع',
                              subtitle: 'المهمة الأولى في رحلتك',
                              reward: '2 جوهرة 💎',
                              icon: Icons.play_circle_outline,
                              onTap: () => _handleTask(taskStep, 'video'),
                            ),

                            // 2. مهمة مقال (2 نجمة)
                            _buildTaskItem(
                              title: 'قراءة مقال اليوم',
                              subtitle: 'ثقف نفسك واربح النجوم',
                              reward: '2 نجمة ⭐',
                              icon: Icons.article_outlined,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoyalArticlesPage())),
                            ),

                            // 3. مهمة مشاهدة مسلسل (ترقية مستوى)
                            _buildTaskItem(
                              title: 'شاهد مسلسلاً قصيراً',
                              subtitle: 'شاهد محتوى ممتع لترقية مستواك',
                              reward: 'ترقية مستوى +10 XP 📈',
                              icon: Icons.movie_filter_outlined,
                              onTap: () => _handleTask(taskStep, 'series'),
                            ),

                            // 4. مهمة إعلان لعبة (4 جواهر)
                            _buildTaskItem(
                              title: 'اكتشف أحدث الألعاب',
                              subtitle: 'شاهد إعلان اللعبة المقترح',
                              reward: '4 جوهرة 💎',
                              icon: Icons.games_outlined,
                              onTap: () => _handleTask(taskStep, 'game_ad'),
                            ),

                            // 5. مهمة مركبة (اقرأ مقالتين)
                            _buildTaskItem(
                              title: 'تحدي القراءة الملكي',
                              subtitle: 'اقرأ مقالتين مختلفتين بالكامل',
                              reward: '4 نجمة ⭐',
                              icon: Icons.menu_book_rounded,
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RoyalArticlesPage())),
                            ),

                            // 6. مهمة تحميل وعرض (عروض عالمية)
                            _buildTaskItem(
                              title: 'قم بتحميل وعرض التطبيقات',
                              subtitle: 'أكبر مكافأة في الرحلة الملكية',
                              reward: 'مكافأة ضخمة 🎁',
                              icon: Icons.download_for_offline_outlined,
                              onTap: () => _openGlobalOffers(),
                            ),

                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                _buildFloatingChest(userData),
                if (_isBannerLoaded)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      color: Colors.black,
                      height: _bannerAd!.size.height.toDouble(),
                      child: AdWidget(ad: _bannerAd!),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSavingsVault(Map<String, dynamic> userData) {
    int progress = userData['vault_progress'] ?? 0;
    double percent = (progress / 50).clamp(0.0, 1.0);
    bool isReady = progress >= 50;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isReady 
            ? [const Color(0xFFD4AF37), const Color(0xFF8A6E2F)] 
            : [Colors.white.withValues(alpha: 0.05), Colors.white.withValues(alpha: 0.02)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isReady ? Colors.amber : Colors.white.withValues(alpha: 0.1), width: 1.5),
        boxShadow: [
          if (isReady) 
            BoxShadow(color: Colors.amber.withValues(alpha: 0.3), blurRadius: 25, spreadRadius: 2),
          BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildAnimatedIcon(
                isReady ? Icons.account_balance_wallet : Icons.lock_outline,
                color: isReady ? Colors.white : Colors.amber,
                lottieUrl: isReady 
                  ? 'https://assets10.lottiefiles.com/packages/lf20_t9m64r.json' 
                  : 'https://assets10.lottiefiles.com/packages/lf20_5n8ybe.json',
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('بنك العملات الملكي 🏦', 
                      style: TextStyle(
                        color: isReady ? Colors.black : Colors.white, 
                        fontWeight: FontWeight.w900, 
                        fontSize: 17,
                        fontFamily: 'Orbitron'
                      )
                    ),
                    const SizedBox(height: 4),
                    Text(isReady ? 'مبروك! الخزنة ممتلئة بالذهب' : 'اجمع 50 نشاطاً لفتح الخزنة ($progress/50)', 
                      style: TextStyle(fontSize: 11, color: isReady ? Colors.black87 : Colors.white60, fontWeight: FontWeight.bold)
                    ),
                  ],
                ),
              ),
              if (isReady)
                const Text('5 💎 + 5 ⭐', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 20),
          _buildRoyalProgressBar(percent, isReady),
        ],
      ),
    );
  }

  Widget _buildAnimatedIcon(IconData icon, {required Color color, String? lottieUrl}) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      child: lottieUrl != null 
        ? Lottie.network(
            lottieUrl,
            width: 60,
            height: 60,
            errorBuilder: (context, error, stackTrace) => Icon(icon, color: color, size: 35),
          )
        : Icon(icon, color: color, size: 35),
    );
  }

  Widget _buildRoyalProgressBar(double percent, bool isReady) {
    return Stack(
      children: [
        Container(
          height: 12,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 800),
          height: 12,
          width: (MediaQuery.of(context).size.width - 70) * percent,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isReady 
                ? [Colors.white, Colors.amberAccent] 
                : [const Color(0xFFD4AF37), const Color(0xFFF9D423)]
            ),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: Colors.amber.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 1)
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoldenHourStatus() {
    final now = DateTime.now();
    bool isGolden = now.hour >= 21 && now.hour < 22;
    if (!isGolden) return const SizedBox.shrink();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(seconds: 1),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.amber.shade700.withValues(alpha: 0.2), Colors.orange.shade800.withValues(alpha: 0.1)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.4), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.amber.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 1)
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPulsingIcon(Icons.bolt, color: Colors.amber),
              const SizedBox(width: 15),
              const Expanded(
                child: Text('ساعة الحظ مفعلة! المكافآت مضاعفة 🔥', 
                  style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 13, fontFamily: 'Cairo')
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPulsingIcon(IconData icon, {required Color color}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.2),
      duration: const Duration(milliseconds: 600),
      builder: (context, scale, child) => Transform.scale(
        scale: scale,
        child: Icon(icon, color: color, size: 28),
      ),
    );
  }

  Widget _buildRoyalHeader(Map<String, dynamic> userData) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      stretch: true,
      backgroundColor: const Color(0xFF050505),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white), 
        onPressed: () => Navigator.pop(context)
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Stack(
          alignment: Alignment.center,
          children: [
            // Premium background design
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1E3C72), Color(0xFF2A5298), Color(0xFF050505)],
                ),
              ),
            ),
            // Floating particles or subtle light
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200, height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, 
                  color: Colors.amber.withValues(alpha: 0.05),
                  boxShadow: [
                    BoxShadow(color: Colors.amber.withValues(alpha: 0.1), blurRadius: 100, spreadRadius: 50)
                  ]
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                const Text('مركز المهام الملكي 💎', 
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, fontFamily: 'Orbitron', letterSpacing: 1.2)
                ),
                const SizedBox(height: 8),
                const Text('أكمل المهام واجمع الكنوز اليومية', 
                  style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _balanceBadge('${userData['gems'] ?? 0}', Icons.diamond, Colors.cyanAccent),
                    const SizedBox(width: 15),
                    _balanceBadge('${userData['stars'] ?? 0}', Icons.stars, Colors.amber),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _balanceBadge(String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 15, spreadRadius: 1)
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Text(val, 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, fontFamily: 'Orbitron')
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem({required String title, required String subtitle, required String reward, required IconData icon, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [DesignTokens.primaryGold.withValues(alpha: 0.2), Colors.transparent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: DesignTokens.primaryGold.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: DesignTokens.primaryGold, size: 28),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Cairo')
                ),
                const SizedBox(height: 2),
                Text(subtitle, 
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(reward, 
                    style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.w900)
                  ),
                ),
              ],
            ),
          ),
          RoyalButton(
            label: 'ابدأ', 
            onPressed: onTap, 
            width: 75, 
            height: 38, 
            fontSize: 12, 
            gradient: const [Color(0xFFD4AF37), Color(0xFF8A6E2F)],
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingChest(Map<String, dynamic> userData) {
    bool isReady = _secondsToNextChest == 0;
    return Positioned(
      left: _chestOffset.dx, top: _chestOffset.dy,
      child: GestureDetector(
        onPanUpdate: (details) => setState(() => _chestOffset += details.delta),
        onTap: () => isReady ? _openChest(userData) : null,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1.0),
          duration: const Duration(seconds: 1),
          curve: Curves.easeInOut,
          builder: (context, scale, child) => Transform.scale(
            scale: isReady ? scale : 1.0,
            child: Column(
              children: [
                _buildAnimatedIcon(
                  isReady ? Icons.card_giftcard : Icons.hourglass_empty,
                  color: isReady ? Colors.amber : Colors.white38,
                  lottieUrl: isReady 
                    ? 'https://assets10.lottiefiles.com/packages/lf20_t9m64r.json' 
                    : 'https://assets10.lottiefiles.com/packages/lf20_5n8ybe.json',
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isReady 
                        ? [Colors.green, Colors.teal] 
                        : [Colors.black54, Colors.black87]
                    ),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: isReady ? Colors.greenAccent : Colors.white10),
                    boxShadow: [
                      if (isReady) BoxShadow(color: Colors.green.withValues(alpha: 0.4), blurRadius: 10)
                    ]
                  ),
                  child: Text(
                    isReady ? 'افتح الكنز!' : _formatTimer(_secondsToNextChest), 
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openChest(Map<String, dynamic> userData) async {
    final now = DateTime.now();
    final lastOpen = (userData['last_chest_open_time'] as Timestamp?)?.toDate();

    if (lastOpen != null) {
      final difference = now.difference(lastOpen);
      if (difference.inHours < 12) {
        final remaining = const Duration(hours: 12) - difference;
        AppTheme.showInfoSnackbar(context, 'يجب الانتظار ${remaining.inHours} ساعة و ${remaining.inMinutes % 60} دقيقة لفتح الكنز مجدداً ⏳');
        return;
      }
    }

    bool lastWasStar = userData['last_chest_reward_was_star'] ?? false;
    String rewardType = lastWasStar ? 'gems' : 'stars';
    
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      rewardType: FieldValue.increment(5),
      'last_chest_reward_was_star': !lastWasStar,
      'last_chest_open_time': FieldValue.serverTimestamp(),
    });

    setState(() => _secondsToNextChest = 12 * 3600); // 12 ساعة
    if (mounted) {
      HapticFeedback.vibrate(); // اهتزاز مميز عند فتح الكنز
      AppTheme.showSuccessSnackbar(context, 'مبروك! عثرت على 5 ${rewardType == 'stars' ? 'نجوم' : 'جواهر'} 🎁');
      // إظهار إعلان ملء الشاشة بعد فتح الكنز
      _adManager.showInterstitialAd();
    }

    // جدولة إشعار بعد 12 ساعة
    NotificationsService.sendNotification(
      userId: userId,
      title: 'الكنز الملكي جاهز! 🎁',
      message: 'لقد مر 12 ساعة، الذهب ينتظرك الآن في مركز المهام ✨',
      type: 'chest_ready',
    );
  }

  void _handleTask(int currentStep, String type) {
    _adManager.showRewardedAd(
      onUserEarnedReward: (reward) async {
        String rewardType = 'gems';
        int amount = 0;
        String message = '';

        if (type == 'video') {
          amount = 2;
          rewardType = 'gems';
          message = 'حصلت على $amount جوهرة 💎';
        } else if (type == 'series') {
          // مهمة المسلسلات تعطي خبرة XP
          rewardType = 'royalXP';
          amount = 10;
          message = 'ارتفع مستوى خبرتك الملكية +$amount XP 📈';
        } else if (type == 'game_ad') {
          amount = 4;
          rewardType = 'gems';
          message = 'حصلت على $amount جوهرة 💎';
        }

        // تسجيل النشاط وتوزيع المكافأة تلقائياً
        await TaskTrackingService().recordActivity(userId, 
          rewardType: rewardType == 'royalXP' ? null : rewardType, 
          rewardAmount: rewardType == 'royalXP' ? null : amount
        );

        // إذا كانت مكافأة خبرة فقط
        if (rewardType == 'royalXP') {
          await FirebaseFirestore.instance.collection('users').doc(userId).update({
            'royalXP': FieldValue.increment(amount),
          });
        }

        await FirebaseFirestore.instance.collection('users').doc(userId).update({
          'reward_task_step': FieldValue.increment(1),
        });

        if (mounted) {
          AppTheme.showSuccessSnackbar(context, 'تمت المهمة بنجاح! $message 🎉');
        }
      },
      onAdFailed: () => AppTheme.showErrorSnackbar(context, 'الإعلان غير جاهز حالياً، يرجى المحاولة بعد قليل'),
    );
  }

  void _openGlobalOffers() {
    AppTheme.showInfoSnackbar(context, 'يتم توجيهك للعروض العالمية الآمنة...');
    // فتح رابط CPALead
  }

  String _formatTimer(int s) => '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  Widget _buildSectionLabel(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 15, 0, 12), 
    child: Align(
      alignment: Alignment.centerRight, 
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, 
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'Cairo')
          ),
          const SizedBox(height: 4),
          Container(width: 40, height: 3, decoration: BoxDecoration(color: DesignTokens.primaryGold, borderRadius: BorderRadius.circular(10))),
        ],
      )
    )
  );
}
