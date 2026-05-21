import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../../theme/design_tokens.dart';
import '../../theme/reusable_widgets.dart';
import '../../theme/app_theme.dart';

class RoyalTaskCenterPage extends StatefulWidget {
  const RoyalTaskCenterPage({super.key});

  @override
  State<RoyalTaskCenterPage> createState() => _RoyalTaskCenterPageState();
}

class _RoyalTaskCenterPageState extends State<RoyalTaskCenterPage> {
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F0F), // لون غامق جداً للفخامة
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const HeadingText('مركز المهام الملكي', color: Colors.white),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildTopWalletSection(),
              _buildDailyCheckInSection(),
              _buildAdsTaskSection(),
              _buildReadingTasksSection(),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  // 1. قسم المحفظة العلوية
  Widget _buildTopWalletSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.stars, color: DesignTokens.primaryGold, size: 30),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BodyText('عملاتك الذهبية', color: Colors.white70),
              Text(
                '840', 
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: DesignTokens.primaryGold,
                  fontFamily: DesignTokens.secondaryFont,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. نظام تسجيل الدخول اليومي (7 أيام)
  Widget _buildDailyCheckInSection() {
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Column(
        children: [
          const ListTile(
            title: HeadingText('تسجيل الدخول للحصول على المكافأة', fontSize: 16),
            subtitle: BodyText('ترقية مكافآت تسجيل الدخول >', color: Colors.pinkAccent, fontSize: 12),
          ),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4, 
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            padding: const EdgeInsets.all(10),
            children: List.generate(7, (index) {
              bool isToday = index == 1; 
              bool isDone = index == 0;
              return Container(
                decoration: BoxDecoration(
                  color: isToday ? Colors.pink.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isToday ? Colors.pinkAccent : Colors.white10),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    BodyText('اليوم ${index + 1}', fontSize: 10),
                    const Icon(Icons.monetization_on, color: DesignTokens.primaryGold, size: 18),
                    BodyText(index < 4 ? '50+' : '80+', fontSize: 12, fontWeight: FontWeight.bold),
                    if (isDone) const Icon(Icons.check_circle, color: Colors.green, size: 14),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: RoyalButton(
              label: 'احصل على 100 عملة إضافية 📺',
              onPressed: () {
                // سيتم ربطها بـ AdManager لاحقاً
              },
              gradient: [Colors.pinkAccent, Colors.redAccent],
            ),
          ),
        ],
      ),
    );
  }

  // 3. قسم مهام الإعلانات
  Widget _buildAdsTaskSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: HeadingText('مهام الإعلانات', fontSize: 20),
        ),
        _buildTaskItem(
          title: 'شاهد مسلسلاً قصيراً للحصول على عملات',
          subtitle: 'شاهد 15 دقيقة واحصل على ما يصل لـ 735 عملة',
          icon: Icons.movie_creation_outlined,
          progress: 0.4,
          reward: '735+',
          onTap: () {},
        ),
        _buildTaskItem(
          title: 'شاهد الإعلانات لكسب ما يصل لـ 1520',
          subtitle: 'أكمل مهمة مشاهدة الإعلانات (0/30)',
          icon: Icons.play_circle_filled,
          progress: 0.0,
          reward: '1520+',
          isAd: true,
          onTap: () {},
        ),
      ],
    );
  }

  // 4. قسم مهام التفاعل
  Widget _buildReadingTasksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: HeadingText('مهام التفاعل', fontSize: 20),
        ),
        _buildTaskItem(
          title: 'اقرأ مقالتين مختلفتين',
          subtitle: 'تصفح المقالات لمدة دقيقة (0/10)',
          icon: Icons.article_outlined,
          progress: 0.0,
          reward: '100+',
          onTap: () {},
        ),
        _buildTaskItem(
          title: 'افتح 3 صفحات واقرأها بدقة',
          subtitle: 'زيادة التفاعل في صفحات التطبيق (0/10)',
          icon: Icons.menu_book_rounded,
          progress: 0.0,
          reward: '100+',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildTaskItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required double progress,
    required String reward,
    bool isAd = false,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: DesignTokens.primaryGold),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BodyText(title, fontWeight: FontWeight.bold, fontSize: 14),
                BodyText(subtitle, color: Colors.white54, fontSize: 11),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white10,
                  color: DesignTokens.primaryGold,
                  minHeight: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          Column(
            children: [
              BodyText(reward, color: DesignTokens.primaryGold, fontWeight: FontWeight.bold),
              const SizedBox(height: 5),
              SizedBox(
                height: 30,
                width: 70,
                child: RoyalButton(
                  label: 'اذهب',
                  onPressed: onTap,
                  fontSize: 10,
                  gradient: [Colors.purpleAccent, Colors.deepPurple],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
