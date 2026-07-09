import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import '../../app_theme.dart';
import '../gems_coins_page.dart';

class RoyalLevelPage extends StatefulWidget {
  const RoyalLevelPage({super.key});

  @override
  State<RoyalLevelPage> createState() => _RoyalLevelPageState();
}

class Privilege {
  final String id;
  final String title;
  final IconData icon;
  final int unlockLevel;
  final Color color;

  const Privilege(
      {required this.id,
      required this.title,
      required this.icon,
      required this.unlockLevel,
      required this.color});
}

class _RoyalLevelPageState extends State<RoyalLevelPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  final List<int> _levelNumbers = List.generate(20, (index) => index + 1);

  final List<int> _levelThresholds = [
    0,
    100,
    300,
    700,
    1500,
    4000,
    10000,
    30000,
    50000,
    100000,
    200000,
    400000,
    800000,
    1500000,
    3000000,
    5000000,
    8000000,
    10000000,
    11000000,
    12000000
  ];

  int _calculateLevel(int xp) {
    for (int i = _levelThresholds.length - 1; i >= 0; i--) {
      if (xp >= _levelThresholds[i]) return i + 1;
    }
    return 1;
  }

  Color _getLevelColor(int level) {
    if (level >= 17) return const Color(0xFFFFD700);
    if (level >= 13) return Colors.purpleAccent;
    if (level >= 9) return Colors.blueAccent;
    if (level >= 5) return Colors.cyanAccent;
    return Colors.orangeAccent;
  }

  final List<Privilege> _privileges = [
    const Privilege(
        id: 'mic_frame',
        title: 'إطار ميكروفون حصري',
        icon: Icons.mic_external_on,
        unlockLevel: 1,
        color: Colors.greenAccent),
    const Privilege(
        id: 'exclusive_badge',
        title: 'شارة حصرية',
        icon: Icons.stars,
        unlockLevel: 1,
        color: Colors.amberAccent),
    const Privilege(
        id: 'status_badge',
        title: 'شارة الحالة',
        icon: Icons.workspace_premium,
        unlockLevel: 1,
        color: Colors.blueAccent),
    const Privilege(
        id: 'chat_bubble',
        title: 'فقاعة حصرية',
        icon: Icons.chat_bubble,
        unlockLevel: 2,
        color: Colors.pinkAccent),
    const Privilege(
        id: 'follow_limit',
        title: 'زيادة حد المتابعة',
        icon: Icons.person_add,
        unlockLevel: 1,
        color: Colors.tealAccent),
    const Privilege(
        id: 'friends_limit',
        title: 'زيادة حد الأصدقاء',
        icon: Icons.people,
        unlockLevel: 1,
        color: Colors.orangeAccent),
    const Privilege(
        id: 'entry_statement',
        title: 'بيان الدخول',
        icon: Icons.login,
        unlockLevel: 3,
        color: Colors.lightBlueAccent),
    const Privilege(
        id: 'hide_country',
        title: 'إخفاء الدولة',
        icon: Icons.public_off,
        unlockLevel: 4,
        color: Colors.grey),
    const Privilege(
        id: 'hide_last_seen',
        title: 'إخفاء آخر ظهور',
        icon: Icons.timer_off,
        unlockLevel: 5,
        color: Colors.redAccent),
    const Privilege(
        id: 'game_exp',
        title: 'خبرة الألعاب x2',
        icon: Icons.sports_esports,
        unlockLevel: 6,
        color: Colors.indigoAccent),
    const Privilege(
        id: 'exclusive_car',
        title: 'مركبة حصرية',
        icon: Icons.directions_car,
        unlockLevel: 7,
        color: Colors.amber),
    const Privilege(
        id: 'stream_banner',
        title: 'بانر البث المباشر',
        icon: Icons.live_tv,
        unlockLevel: 7,
        color: Colors.red),
    const Privilege(
        id: 'anti_mute',
        title: 'منع حظر الكتابة',
        icon: Icons.speaker_notes_off,
        unlockLevel: 8,
        color: Colors.deepPurpleAccent),
    const Privilege(
        id: 'extra_exp',
        title: 'مكافأة EXP إضافية',
        icon: Icons.card_giftcard,
        unlockLevel: 9,
        color: Colors.lightGreenAccent),
    const Privilege(
        id: 'mystery_man',
        title: 'الرجل الغامض',
        icon: Icons.masks,
        unlockLevel: 9,
        color: Colors.white),
    const Privilege(
        id: 'exclusive_seat',
        title: 'مقعد رويال حصري',
        icon: Icons.chair,
        unlockLevel: 10,
        color: Colors.brown),
    const Privilege(
        id: 'entry_effect',
        title: 'تأثير دخول ملكي',
        icon: Icons.auto_awesome,
        unlockLevel: 10,
        color: Colors.yellowAccent),
    const Privilege(
        id: 'monthly_gift',
        title: 'هدية حصرية شهرياً',
        icon: Icons.card_membership,
        unlockLevel: 10,
        color: Colors.deepOrangeAccent),
    const Privilege(
        id: 'glowing_name',
        title: 'اسم ملون متوهج',
        icon: Icons.color_lens,
        unlockLevel: 11,
        color: Colors.cyan),
    const Privilege(
        id: 'store_coupons',
        title: 'قسائم متجر مجانية',
        icon: Icons.confirmation_number,
        unlockLevel: 11,
        color: Colors.purple),
    const Privilege(
        id: 'freeze_charm',
        title: 'تجميد الجاذبية',
        icon: Icons.ac_unit,
        unlockLevel: 12,
        color: Colors.blue),
    const Privilege(
        id: 'animated_profile',
        title: 'بروفايل متحرك',
        icon: Icons.animation,
        unlockLevel: 13,
        color: Colors.pink),
    const Privilege(
        id: 'anti_remove',
        title: 'مضاد للإزالة',
        icon: Icons.security,
        unlockLevel: 14,
        color: Colors.green),
    const Privilege(
        id: 'hide_rank',
        title: 'إخفاء الترتيب',
        icon: Icons.list_alt,
        unlockLevel: 15,
        color: Colors.white54),
    const Privilege(
        id: 'elite_frame',
        title: 'إطار بروفايل فاخر',
        icon: Icons.crop_free,
        unlockLevel: 16,
        color: Colors.amberAccent),
    const Privilege(
        id: 'profile_deco',
        title: 'تزيين البروفايل',
        icon: Icons.style,
        unlockLevel: 16,
        color: Colors.deepPurple),
    const Privilege(
        id: 'global_promo_notif',
        title: 'إشعار ترقية عالمي',
        icon: Icons.trending_up,
        unlockLevel: 17,
        color: Colors.orange),
    const Privilege(
        id: 'special_id',
        title: 'رقم تعريفي مميز',
        icon: Icons.badge,
        unlockLevel: 17,
        color: Colors.teal),
    const Privilege(
        id: 'anti_kick',
        title: 'مضاد للطرد',
        icon: Icons.admin_panel_settings,
        unlockLevel: 18,
        color: Colors.redAccent),
    const Privilege(
        id: 'military_frame',
        title: 'إطار عسكري ملكي',
        icon: Icons.military_tech,
        unlockLevel: 18,
        color: Colors.yellow),
    const Privilege(
        id: 'vip_welcome',
        title: 'شاشة ترحيب VIP',
        icon: Icons.celebration,
        unlockLevel: 19,
        color: Colors.pinkAccent),
    const Privilege(
        id: 'custom_car',
        title: 'مركبة مخصصة',
        icon: Icons.commute,
        unlockLevel: 19,
        color: Colors.lightBlue),
    const Privilege(
        id: 'crowned_title',
        title: 'لقب ملكي متوج',
        icon: Icons.star_half,
        unlockLevel: 20,
        color: Colors.amber),
    const Privilege(
        id: 'admin_gifts',
        title: 'هدايا الإدارة',
        icon: Icons.redeem,
        unlockLevel: 20,
        color: Colors.red),
    const Privilege(
        id: 'account_verify',
        title: 'توثيق الحساب',
        icon: Icons.verified,
        unlockLevel: 20,
        color: Colors.blueAccent),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _levelNumbers.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel>(
        stream: _firestoreService.streamUserData(_currentUserId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
                backgroundColor: Colors.black,
                body: Center(
                    child:
                        CircularProgressIndicator(color: AppTheme.royalGold)));
          }

          final userData = snapshot.data!;
          int userRealLevel = _calculateLevel(userData.royalXP);
          int viewedLevel = _levelNumbers[_tabController.index];
          Color themeColor = _getLevelColor(viewedLevel);

          return Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              backgroundColor: Colors.black,
              body: Stack(
                children: [
                  _buildBackground(themeColor),
                  SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        _buildAppBar(userData),
                        _buildLevelTabs(themeColor),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: _levelNumbers
                                .map((level) =>
                                    _buildLevelContent(level, userRealLevel))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _RoyalXPBar(
                    userData: userData,
                    currentLevel: userRealLevel,
                    levelThresholds: _levelThresholds,
                    getLevelColor: _getLevelColor,
                    onChargePressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const GemsCoinsPage()));
                    },
                  ),
                ],
              ),
            ),
          );
        });
  }

  Widget _buildBackground(Color themeColor) {
    return SizedBox.expand(
      child: Stack(
        children: [
          Container(
            color: const Color(0xFF0a0a15),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.center,
                colors: [
                  const Color(0xFF0066ff).withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.center,
                colors: [
                  const Color(0xFF9d00ff).withValues(alpha: 0.25),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.center,
                colors: [
                  const Color(0xFF00ffff).withValues(alpha: 0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00ffff).withValues(alpha: 0.25),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -120,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9d00ff).withValues(alpha: 0.3),
                    blurRadius: 120,
                    spreadRadius: 60,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(UserModel userData) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
              icon: const Icon(Icons.arrow_back_ios,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context)),
          const Text('توشاتي الملكية',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz, color: Colors.white),
            color: Colors.grey[900],
            offset: const Offset(0, 45),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            onSelected: (value) {
              if (value == 'center') _showPrivilegeCenter(userData);
              if (value == 'rules') _showRules();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                  value: 'center',
                  child: Row(children: [
                    Icon(Icons.admin_panel_settings,
                        color: AppTheme.royalGold, size: 18),
                    SizedBox(width: 8),
                    Text('مركز الامتيازات',
                        style: TextStyle(color: Colors.white))
                  ])),
              const PopupMenuItem(
                  value: 'rules',
                  child: Row(children: [
                    Icon(Icons.help_outline, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text('القوانين والشروط',
                        style: TextStyle(color: Colors.white))
                  ])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelTabs(Color themeColor) {
    return SizedBox(
      height: 50,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: themeColor,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
        labelColor: themeColor,
        unselectedLabelColor: Colors.white24,
        tabs: _levelNumbers.map((l) => Tab(text: 'رويال $l')).toList(),
      ),
    );
  }

  Widget _buildLevelContent(int level, int userRealLevel) {
    Color themeColor = _getLevelColor(level);
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: 30),
              _buildMainBadge(level, themeColor, userRealLevel >= level),
              _buildPrivilegesHeader(level),
            ],
          ),
        ),
        _buildPrivilegesSliverGrid(level, themeColor),
        const SliverToBoxAdapter(child: SizedBox(height: 180)),
      ],
    );
  }

  Widget _buildMainBadge(int level, Color themeColor, bool isUnlocked) {
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: themeColor.withValues(alpha: 0.3),
                    blurRadius: 80,
                    spreadRadius: 15)
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                  isUnlocked
                      ? Icons.shield_moon_rounded
                      : Icons.shield_outlined,
                  size: 100,
                  color: themeColor),
              const SizedBox(height: 10),
              Text('ROYAL $level',
                  style: TextStyle(
                      color: themeColor,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      shadows: [
                        Shadow(
                            color: themeColor.withValues(alpha: 0.8), blurRadius: 20),
                      ])),
              const SizedBox(height: 5),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                      isUnlocked
                          ? Icons.check_circle_outline
                          : Icons.lock_outline,
                      color: isUnlocked ? Colors.greenAccent : Colors.white24,
                      size: 14),
                  const SizedBox(width: 5),
                  Text(isUnlocked ? 'تم الوصول للمستوى' : 'يتطلب الشحن للفتح',
                      style: TextStyle(
                          color:
                              isUnlocked ? Colors.greenAccent : Colors.white24,
                          fontSize: 12)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrivilegesHeader(int level) {
    int unlockedCount = _privileges.where((p) => p.unlockLevel <= level).length;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 25),
      child: Column(
        children: [
          const Text('❦ قائمة الامتيازات المتاحة ❦',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('يمنحك هذا المستوى $unlockedCount ميزة حصرية',
              style: const TextStyle(color: Colors.white38, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildPrivilegesSliverGrid(int level, Color themeColor) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 15,
            crossAxisSpacing: 15,
            childAspectRatio: 0.8),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = _privileges[index];
            bool isLocked = item.unlockLevel > level;

            return _buildPrivilegeTile(item, isLocked, themeColor);
          },
          childCount: _privileges.length,
        ),
      ),
    );
  }

  Widget _buildPrivilegeTile(Privilege item, bool isLocked, Color themeColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isLocked
                ? Colors.white.withValues(alpha: 0.05)
                : item.color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isLocked ? Colors.transparent : item.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon,
                color: isLocked ? Colors.white10 : item.color, size: 28),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(item.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: isLocked ? Colors.white24 : Colors.white,
                    fontSize: 10,
                    fontWeight:
                        isLocked ? FontWeight.normal : FontWeight.bold)),
          ),
          const SizedBox(height: 5),
          Text('رويال ${item.unlockLevel}',
              style: TextStyle(
                  color: isLocked ? Colors.white10 : Colors.white38,
                  fontSize: 9)),
        ],
      ),
    );
  }

  void _showPrivilegeCenter(UserModel userData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PrivilegeCenterSheet(
        userData: userData,
        currentUserId: _currentUserId,
      ),
    );
  }

  void _showRules() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
            color: Color(0xFF0F0F0F),
            borderRadius: BorderRadius.vertical(top: Radius.circular(35))),
        child: Column(
          children: [
            const _BottomSheetHeader(title: 'قوانين نظام رويال'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(25),
                children: [
                  _buildRuleCard('1. ما هو نظام رويال؟',
                      'هو نظام حصري يمنح المستخدمين هيبة ومكانة خاصة داخل تطبيق رويال دور بناءً على مستوى مساهماتهم في الشحن والدعم.'),
                  _buildRuleCard('2. كيف أرتقي في المستويات؟',
                      'كل عملية شحن بقيمة 1,000 نجمة ⭐ تمنحك (1 XP). كلما زاد مستواك، زادت رتبتك الملكية تلقائياً.'),
                  _buildRuleCard('3. الحفاظ على المستوى',
                      'تتطلب المستويات العليا (10+) الحفاظ على حد أدنى من الخبرة شهرياً لضمان بقاء التاج والامتيازات مفعلة.'),
                  _buildRuleCard('4. حماية الحساب',
                      'الامتيازات الملكية هي مكافأة للمستخدمين الداعمين، وأي محاولة للتلاعب بمستوى الخبرة قد تعرض الحساب للمساءلة.'),
                  const SizedBox(height: 20),
                  const Text('جدول ترقية المستويات الملكية:',
                      style: TextStyle(
                          color: AppTheme.royalGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  const SizedBox(height: 15),
                  _buildExpTable(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuleCard(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15)),
        const SizedBox(height: 8),
        Text(content,
            style: const TextStyle(
                color: Colors.white54, fontSize: 13, height: 1.5)),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildExpTable() {
    final List<Map<String, String>> tableData = [
      {'level': 'رويال 1', 'exp': '10000', 'keep': '6000'},
      {'level': 'رويال 5', 'exp': '400,000', 'keep': '10,500'},
      {'level': 'رويال 10', 'exp': '2000,000', 'keep': '800,000'},
      {'level': 'رويال 20', 'exp': '120,000,000', 'keep': '20,000,000'},
    ];
    return Container(
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Table(
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05)),
            children: const [
              Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('المستوى',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppTheme.royalGold,
                          fontWeight: FontWeight.bold))),
              Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('الخبرة (XP)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppTheme.royalGold,
                          fontWeight: FontWeight.bold))),
              Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('الاحتفاظ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppTheme.royalGold,
                          fontWeight: FontWeight.bold))),
            ],
          ),
          ...tableData.map((e) => TableRow(children: [
                Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(e['level']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12))),
                Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(e['exp']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12))),
                Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(e['keep']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12))),
              ])),
        ],
      ),
    );
  }
}

class _PrivilegeCenterSheet extends StatefulWidget {
  final UserModel userData;
  final String currentUserId;

  const _PrivilegeCenterSheet({
    required this.userData,
    required this.currentUserId,
  });

  @override
  State<_PrivilegeCenterSheet> createState() => _PrivilegeCenterSheetState();
}

class _PrivilegeCenterSheetState extends State<_PrivilegeCenterSheet> {
  final FirestoreService _firestoreService = FirestoreService();
  late Map<String, dynamic> _settings;

  @override
  void initState() {
    super.initState();
    _settings = Map.from(widget.userData.privilegeSettings);
  }

  void _updateSetting(String key, bool value) {
    setState(() => _settings[key] = value);
    _firestoreService.updateSingleField(
        widget.currentUserId, 'privilegeSettings.$key', value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
          color: Color(0xFF0F0F0F),
          borderRadius: BorderRadius.vertical(top: Radius.circular(35))),
      child: Column(
        children: [
          const _BottomSheetHeader(title: 'مركز إدارة الامتيازات'),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                _buildToggleOption(
                  'إخفاء الجاذبية',
                  'إخفاء مستوى جاذبيتك عن الآخرين',
                  _settings['hide_charm'] ?? false,
                  (val) => _updateSetting('hide_charm', val),
                ),
                _buildToggleOption(
                  'إخفاء الترتيب',
                  'عدم ظهور اسمك في قوائم التوب',
                  _settings['hide_rank'] ?? false,
                  (val) => _updateSetting('hide_rank', val),
                ),
                _buildToggleOption(
                  'الرجل الغامض',
                  'الدخول للغرف بشكل متخفي',
                  _settings['mystery_man'] ?? false,
                  (val) => _updateSetting('mystery_man', val),
                ),
                _buildToggleOption(
                  'إخفاء الدولة',
                  'عدم إظهار علم الدولة في البروفايل',
                  _settings['hide_country'] ?? false,
                  (val) => _updateSetting('hide_country', val),
                ),
                const SizedBox(height: 20),
                _buildActionOption('تخصيص الآيدي',
                    'تعديل الرقم الملكي الخاص بك', 'اذهب', () {}),
                _buildActionOption('استلام مكافأة المستوى',
                    'استلم هداياك المجانية', 'استلام', () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(
      String title, String sub, bool value, Function(bool) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Row(
        children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(sub,
                    style: const TextStyle(color: Colors.white38, fontSize: 11))
              ])),
          Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: AppTheme.royalGold),
        ],
      ),
    );
  }

  Widget _buildActionOption(
      String title, String sub, String btn, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(20)),
      child: Row(
        children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(sub,
                    style: const TextStyle(color: Colors.white38, fontSize: 11))
              ])),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.royalGold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                padding: const EdgeInsets.symmetric(horizontal: 20)),
            child: Text(btn,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _BottomSheetHeader extends StatelessWidget {
  final String title;
  const _BottomSheetHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const CircleAvatar(
                  backgroundColor: Colors.white10,
                  child: Icon(Icons.close, color: Colors.white, size: 20))),
        ],
      ),
    );
  }
}

class _RoyalXPBar extends StatelessWidget {
  const _RoyalXPBar({
    required this.userData,
    required this.currentLevel,
    required this.levelThresholds,
    required this.getLevelColor,
    required this.onChargePressed,
  });

  final UserModel userData;
  final int currentLevel;
  final List<int> levelThresholds;
  final Color Function(int) getLevelColor;
  final VoidCallback onChargePressed;

  @override
  Widget build(BuildContext context) {
    int nextLevel = currentLevel < 20 ? currentLevel + 1 : 20;
    int currentLevelThreshold = levelThresholds[currentLevel - 1];
    int nextLevelThreshold = levelThresholds[nextLevel - 1];

    int xpInCurrentLevel = userData.royalXP - currentLevelThreshold;
    int xpNeededForNext = nextLevelThreshold - currentLevelThreshold;
    double progress = xpNeededForNext > 0
        ? (xpInCurrentLevel / xpNeededForNext).clamp(0.0, 1.0)
        : 1.0;

    Color themeColor = getLevelColor(currentLevel);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: EdgeInsets.fromLTRB(
            25, 20, 25, MediaQuery.of(context).padding.bottom + 20),
        decoration: BoxDecoration(
          color: const Color(0xFF121212),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 30)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('خبرة رويال (XP)',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                Text('${userData.royalXP} / $nextLevelThreshold',
                    style: TextStyle(
                        color: themeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ],
            ),
            const SizedBox(height: 15),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.white10,
                  color: themeColor,
                  minHeight: 6),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onChargePressed,
                style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    elevation: 10,
                    shadowColor: themeColor.withValues(alpha: 0.5)),
                child: const Text('اشحن الآن وارتقِ بمستواك',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
