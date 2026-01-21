import 'dart:ui';
import 'package:flutter/material.dart';

class RoyalLevelPage extends StatefulWidget {
  const RoyalLevelPage({super.key});

  @override
  State<RoyalLevelPage> createState() => _RoyalLevelPageState();
}

class _RoyalLevelPageState extends State<RoyalLevelPage> with TickerProviderStateMixin {
  late TabController _tabController;

  // Levels from 20 down to 1
  final List<int> _levelNumbers = List.generate(20, (index) => 20 - index);

  // Define themes for different level groups
  Color _getLevelColor(int level) {
    if (level >= 17) return const Color(0xFFC5A059); // Gold/Elite
    if (level >= 13) return Colors.purpleAccent;      // Purple
    if (level >= 9) return Colors.blueAccent;        // Blue
    if (level >= 5) return Colors.tealAccent;        // Green/Teal
    return Colors.orangeAccent;                      // Bronze/Orange
  }

  final List<Map<String, dynamic>> _privileges = [
    {'title': 'إطار ميكروفون حصري', 'icon': Icons.mic_external_on, 'unlock': 1},
    {'title': 'شارة حصرية', 'icon': Icons.stars, 'unlock': 1},
    {'title': 'شارة الحالة', 'icon': Icons.workspace_premium, 'unlock': 1},
    {'title': 'فقاعة حصرية', 'icon': Icons.chat_bubble, 'unlock': 2},
    {'title': 'زيادة حد المتابعة', 'icon': Icons.person_add, 'unlock': 1},
    {'title': 'زيادة حد الأصدقاء', 'icon': Icons.people, 'unlock': 1},
    {'title': 'بيان الدخول', 'icon': Icons.login, 'unlock': 3},
    {'title': 'إخفاء الدولة', 'icon': Icons.public_off, 'unlock': 4},
    {'title': 'إخفاء آخر ظهور', 'icon': Icons.timer_off, 'unlock': 5},
    {'title': 'زيادة خبرة الألعاب', 'icon': Icons.sports_esports, 'unlock': 6},
    {'title': 'مركبة حصرية', 'icon': Icons.directions_car, 'unlock': 7},
    {'title': 'بانر البث', 'icon': Icons.live_tv, 'unlock': 7},
    {'title': 'منع حظر من الكتابة', 'icon': Icons.speaker_notes_off, 'unlock': 8},
    {'title': 'مكافأة EXP', 'icon': Icons.card_giftcard, 'unlock': 9},
    {'title': 'الرجل الغامض في الغرفة', 'icon': Icons.masks, 'unlock': 9},
    {'title': 'مقعد حصري', 'icon': Icons.chair, 'unlock': 10},
    {'title': 'بانر دخول بتأثير خاص', 'icon': Icons.auto_awesome, 'unlock': 10},
    {'title': 'هدية حصرية', 'icon': Icons.card_membership, 'unlock': 10},
    {'title': 'اسم ملون', 'icon': Icons.color_lens, 'unlock': 11},
    {'title': 'قسائم المتجر', 'icon': Icons.confirmation_number, 'unlock': 11},
    {'title': 'تجميد مستوى الجاذبية', 'icon': Icons.ac_unit, 'unlock': 12},
    {'title': 'صورة شخصية متحركة', 'icon': Icons.animation, 'unlock': 13},
    {'title': 'مضاد للإزالة', 'icon': Icons.security, 'unlock': 14},
    {'title': 'إخفاء الترتيب في القوائم', 'icon': Icons.list_alt, 'unlock': 15},
    {'title': 'إطار تزين البروفيل', 'icon': Icons.crop_free, 'unlock': 16},
    {'title': 'تزين البروفايل', 'icon': Icons.style, 'unlock': 16},
    {'title': 'بنر ترقية المستوى', 'icon': Icons.trending_up, 'unlock': 17},
    {'title': 'الرقم التعريفي', 'icon': Icons.badge, 'unlock': 17},
    {'title': 'مضاد للطرد من الغرفة', 'icon': Icons.admin_panel_settings, 'unlock': 18},
    {'title': 'إطار مخصوص', 'icon': Icons.military_tech, 'unlock': 18},
    {'title': 'شاشة ترحيبية للترقية', 'icon': Icons.celebration, 'unlock': 19},
    {'title': 'مركبة محددة للجنس', 'icon': Icons.commute, 'unlock': 19},
    {'title': 'شاشة ترحيبية باللقب', 'icon': Icons.star_half, 'unlock': 20},
    {'title': 'هدايا مخصصة', 'icon': Icons.redeem, 'unlock': 20},
    {'title': 'لقب مخصص حصري', 'icon': Icons.verified, 'unlock': 20},
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
    int currentLevel = _levelNumbers[_tabController.index];
    Color themeColor = _getLevelColor(currentLevel);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            _buildBackground(themeColor),
            SafeArea(
              child: Column(
                children: [
                  _buildAppBar(),
                  _buildLevelTabs(themeColor),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: _levelNumbers.map((level) => _buildLevelContent(level)).toList(),
                    ),
                  ),
                ],
              ),
            ),
            _buildBottomXPBar(themeColor),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground(Color themeColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            themeColor.withOpacity(0.15),
            Colors.black,
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
          const Text('توشاتي', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz, color: Colors.white),
            color: Colors.grey[900],
            offset: const Offset(0, 45),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            onSelected: (value) {
              if (value == 'center') _showPrivilegeCenter();
              if (value == 'rules') _showRules();
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'center', child: Row(children: [const Icon(Icons.admin_panel_settings, color: Colors.white, size: 18), const SizedBox(width: 8), Text('مركز الامتيازات', style: TextStyle(color: Colors.white.withOpacity(0.9)))])),
              PopupMenuItem(value: 'rules', child: Row(children: [const Icon(Icons.help_outline, color: Colors.white, size: 18), const SizedBox(width: 8), Text('القوانين', style: TextStyle(color: Colors.white.withOpacity(0.9)))])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLevelTabs(Color themeColor) {
    return SizedBox(
      height: 45,
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: themeColor, width: 3),
          insets: const EdgeInsets.symmetric(horizontal: 20),
        ),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey.withOpacity(0.7),
        tabs: _levelNumbers.map((l) => Tab(text: 'Royal $l')).toList(),
      ),
    );
  }

  Widget _buildLevelContent(int level) {
    Color themeColor = _getLevelColor(level);
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 30),
          _buildMainBadge(level, themeColor),
          _buildPrivilegesHeader(level),
          _buildPrivilegesGrid(level, themeColor),
          const SizedBox(height: 140),
        ],
      ),
    );
  }

  Widget _buildMainBadge(int level, Color themeColor) {
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Glow
          Container(
            width: 200, height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: themeColor.withOpacity(0.2), blurRadius: 60, spreadRadius: 10)],
            ),
          ),
          Positioned(
            right: MediaQuery.of(context).size.width * 0.1,
            child: Container(
              width: 140, height: 140,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/royal_shield.png'),
                  fit: BoxFit.contain,
                ),
              ),
              child: Icon(Icons.shield_moon_rounded, size: 90, color: themeColor),
            ),
          ),
          Positioned(
            left: MediaQuery.of(context).size.width * 0.15,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Royal $level', style: TextStyle(color: themeColor, fontSize: 36, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, shadows: [Shadow(color: themeColor.withOpacity(0.5), blurRadius: 10)])),
                const SizedBox(height: 10),
                Row(
                  children: const [
                    Icon(Icons.lock, color: Colors.grey, size: 16),
                    SizedBox(width: 5),
                    Text('مغلق', style: TextStyle(color: Colors.grey, fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivilegesHeader(int level) {
    int unlockedCount = _privileges.where((p) => p['unlock'] <= level).length;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          const Text('❦ امتيازاتي ❦', style: TextStyle(color: Color(0xFFC5A059), fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('$unlockedCount/35', style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildPrivilegesGrid(int level, Color themeColor) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.8),
      itemCount: _privileges.length,
      itemBuilder: (context, index) {
        final item = _privileges[index];
        bool isLocked = item['unlock'] > level;
        return _buildPrivilegeTile(item, isLocked, themeColor);
      },
    );
  }

  Widget _buildPrivilegeTile(Map<String, dynamic> item, bool isLocked, Color themeColor) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
              border: Border.all(color: isLocked ? Colors.white10 : const Color(0xFFC5A059).withOpacity(0.3)),
              boxShadow: isLocked ? [] : [BoxShadow(color: const Color(0xFFC5A059).withOpacity(0.1), blurRadius: 5)],
            ),
            child: Icon(item['icon'], color: isLocked ? Colors.grey[700] : const Color(0xFFF7D78A), size: 26),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(item['title'], textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: isLocked ? Colors.grey[600] : Colors.white, fontSize: 11, height: 1.2)),
          ),
          const SizedBox(height: 5),
          Text('Royal ${item['unlock']}', style: TextStyle(color: isLocked ? Colors.grey[800] : Colors.grey[500], fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildBottomXPBar(Color themeColor) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 15, 20, 25),
        decoration: BoxDecoration(
          color: const Color(0xFF121212).withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    children: [
                      const TextSpan(text: 'النقاط خبرة توشاتي '),
                      TextSpan(text: '0/100', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Container(
              height: 5,
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
              child: FractionallySizedBox(
                alignment: Alignment.centerRight,
                widthFactor: 0.05,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [themeColor, themeColor.withOpacity(0.5)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFF7D78A), Color(0xFFC5A059)]),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [BoxShadow(color: const Color(0xFFC5A059).withOpacity(0.3), blurRadius: 10)],
                    ),
                    child: const Text('إعادة الشحن', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
                Text('المستوى التالي: Royal ${_tabController.index < 19 ? _levelNumbers[_tabController.index] : 1}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showPrivilegeCenter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(color: Color(0xFF0F0F0F), borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
          children: [
            _buildSheetHeader('مركز الامتيازات'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildToggleOption('عرض مستوى الجاذبية كـ 0', 'عند التفعيل، سيتم عرض مستوى الجاذبية كـ 0'),
                  _buildToggleOption('إخفاء الترتيب', 'عند التفعيل، سيتم إخفاء معلوماتك عن التصنيفات خارج الغرفة'),
                  _buildActionOption('لقب مخصوص حصري', 'يمكن المطالبة به مرة واحدة فقط في الشهر', 'استلام'),
                  _buildActionOption('إخفاء الدولة أو وقت تسجيل الدخول', 'انتقل إلى إعدادات الخصوصية لتكوينه', 'اذهب'),
                  _buildActionOption('امتياز الرجل الغامض', 'عند التفعيل، ستظهر كرجل غامض في غرف الآخرين المباشرة', 'اذهب'),
                  _buildActionOption('المطالبة الايدي', 'المطالبة بالايدي الخاص بك', 'استلام'),
                ],
              ),
            ),
          ],
        ),
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
        decoration: const BoxDecoration(color: Color(0xFF0F0F0F), borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
          children: [
            _buildSheetHeader('القوانين'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildRuleCard('1. ما هي توشاتي؟', 'توشاتي هي نظام تصنيف الحالة في رويال دور الذي يظهر مكانة المستخدم ووجاهته.'),
                  _buildRuleCard('2. كيف يتم ترقية مستوى توشاتي؟', 'مقابل كل 1,000 كوينز تشحن، تحصل على 1 نقطة خبرة توشاتي. حقق نقاط الخبرة المطلوبة لمستوى توشاتي خلال الشهر لتصبح توشاتي ملكي  المقابل وتفتح المزايا ذات الصلة.'),
                  _buildRuleCard('3. لماذا لم أحصل على نقاط خبرة توشاتي بعد الشحن؟', 'قد يكون هناك تأخير بعد الشحن. يجب أن تصلك النقاط خلال 10 دقائق.'),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    child: Text('4. خبرة توشاتي المطلوبة لكل مستوى', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  _buildExpTable(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05)))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 22)),
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String title, String sub) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      child: Row(
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 6), Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 12))])),
          Switch(value: false, onChanged: (v) {}, activeColor: const Color(0xFFC5A059), trackColor: MaterialStateProperty.all(Colors.white10)),
        ],
      ),
    );
  }

  Widget _buildActionOption(String title, String sub, String btn) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      child: Row(
        children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)), const SizedBox(height: 6), Text(sub, style: const TextStyle(color: Colors.grey, fontSize: 12))])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFF7D78A), Color(0xFFC5A059)]), borderRadius: BorderRadius.circular(25)),
            child: Text(btn, style: const TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleCard(String title, String content) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.03))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)), const SizedBox(height: 12), Text(content, style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.6))]),
    );
  }

  Widget _buildExpTable() {
    final List<Map<String, String>> tableData = [
      {'level': 'Royal 1', 'exp': '100', 'keep': '60'},
      {'level': 'Royal 2', 'exp': '300', 'keep': '120'},
      {'level': 'Royal 3', 'exp': '700', 'keep': '240'},
      {'level': 'Royal 4', 'exp': '1,500', 'keep': '480'},
      {'level': 'Royal 5', 'exp': '4,000', 'keep': '1,500'},
      {'level': 'Royal 6', 'exp': '10,000', 'keep': '3,600'},
      {'level': 'Royal 7', 'exp': '30,000', 'keep': '12,000'},
      {'level': 'Royal 8', 'exp': '50,000', 'keep': '12,000'},
      {'level': 'Royal 9', 'exp': '100,000', 'keep': '30,000'},
      {'level': 'Royal 10', 'exp': '200,000', 'keep': '80,000'},
      {'level': 'Royal 20', 'exp': '12,000,000', 'keep': '2,000,000'},
    ];
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Table(
        border: TableBorder.all(color: Colors.white.withOpacity(0.05), width: 1),
        columnWidths: const {0: FlexColumnWidth(1), 1: FlexColumnWidth(1.2), 2: FlexColumnWidth(1.2)},
        children: [
          TableRow(
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05)),
            children: const [
              Padding(padding: EdgeInsets.all(12), child: Text('المستوى', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold))),
              Padding(padding: EdgeInsets.all(12), child: Text('نقاط الخبرة', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold))),
              Padding(padding: EdgeInsets.all(12), child: Text('خبرة الاحتفاظ', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold))),
            ],
          ),
          ...tableData.map((e) => TableRow(children: [
            Padding(padding: EdgeInsets.all(12), child: Text(e['level']!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11))),
            Padding(padding: EdgeInsets.all(12), child: Text(e['exp']!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11))),
            Padding(padding: EdgeInsets.all(12), child: Text(e['keep']!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11))),
          ])).toList(),
        ],
      ),
    );
  }
}
