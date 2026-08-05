import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/feature_lock_wrapper.dart';
import '../../widgets/growth_challenge_widget.dart';
import 'royal_quest/royal_quest_game.dart';
import 'royal_quest/providers/game_provider.dart';
import 'backgammon/backgammon_game.dart';
import 'dart:ui' as ui;

class RoyaleMatchPage extends StatefulWidget {
  const RoyaleMatchPage({super.key});

  @override
  State<RoyaleMatchPage> createState() => _RoyaleMatchPageState();
}

class _RoyaleMatchPageState extends State<RoyaleMatchPage> {
  late final PageController _pageController;
  int _currentPage = 0;

  late List<Map<String, dynamic>> _gameList;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.82);
    _gameList = [
      {
        'id': 'royal_quest',
        'name': 'Royal Quest',
        'image': 'assets/images/quest2.png',
        'bgImage': 'assets/images/quest3.png',
        'color': const Color(0xFF1A237E),
        'icon': Icons.castle,
        'description': 'اختبر معلوماتك واربح الجوائز الملكية 🏆'
      },
      {
        'id': 'backgammon',
        'name': 'الطاولي',
        'image': 'assets/images/Backgammon_royal_bg.jpg',
        'color': const Color(0xFF4A148C),
        'icon': Icons.casino,
        'description': 'العب الطاولة الكلاسيكية بأسلوب ملكي فاخر 🎲'
      },
      {
        'id': 'ludo',
        'name': 'Royal Ludo',
        'image': 'assets/images/Royal_ludo.png',
        'color': const Color(0xFF1B5E20),
        'icon': Icons.grid_view_rounded,
        'description': 'لعبة اللودو الكلاسيكية بتصميم ملكي 🎲'
      },
      {
        'id': 'domino',
        'name': 'Royal Domino',
        'image': 'assets/images/Dominoroyal.jpeg',
        'color': const Color(0xFF37474F),
        'icon': Icons.view_comfortable_rounded,
        'description': 'تحدى أصدقائك في لعبة الدومينو الشهيرة 🀄'
      },
      {
        'id': 'royal_war',
        'name': 'الحرب الملكية',
        'image': 'assets/images/War.png',
        'color': const Color(0xFFB71C1C),
        'icon': Icons.shield_rounded,
        'description': 'استعد للمعركة الكبرى في الحرب الملكية ⚔️'
      },
      {
        'id': 'mohenjo',
        'name': 'رويال موهينجو',
        'image': 'assets/images/MAHJONG.png',
        'color': const Color(0xFFE65100),
        'icon': Icons.auto_awesome,
        'description': 'اكتشف أسرار رويال موهينجو المذهلة ✨'
      },
      {
        'id': 'billiards',
        'name': 'بلياردو',
        'image': 'assets/images/bool.png',
        'color': const Color(0xFF004D40),
        'icon': Icons.sports_handball_sharp,
        'description': 'أظهر مهاراتك في تصويب الكرات على الطاولة 🎱'
      },
      {
        'id': 'Royal XO',
        'name': 'Royal XO',
        'image': 'assets/images/tic_tac_toe.png',
        'bgImage': 'assets/images/xo1.png',
        'color': const Color(0xFF0D47A1),
        'icon': Icons.grid_3x3,
        'description': 'اللعبة الكلاسيكية بلمسة ملكية ⚔️'
      },
      {
        'id': 'fruit_war',
        'name': 'حرب الفواكه',
        'image': 'assets/images/Fruit.png',
        'color': const Color(0xFFB71C1C),
        'icon': Icons.apple,
        'description': 'تحدى أصدقائك في حرب الفواكه الممتعة 🍎'
      },
      {
        'id': 'lucky_draw',
        'name': 'صندوق الحظ',
        'image': 'assets/images/Luky.png',
        'color': const Color(0xFFE65100),
        'icon': Icons.card_giftcard,
        'description': 'جرب حظك واربح هدايا قيمة 🎁'
      },
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FeatureLockWrapper(
      lockField: 'isGamesLocked',
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.asset(
                'assets/images/games_bg.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0A1929), Color(0xFF000000)],
                    ),
                  ),
                ),
              ),
            ),
            
            // Blur effect and gradient overlay
            Positioned.fill(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.castle, color: Color(0xFFFFD700), size: 30),
                        const Text(
                          'مركز الألعاب الملكي',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Cairo',
                            shadows: [
                              Shadow(
                                color: Color(0xFFFFD700),
                                blurRadius: 15,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 30),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  const GrowthChallengeWidget(),
                  
                  // Main Carousel
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (int page) {
                        setState(() {
                          _currentPage = page;
                        });
                      },
                      itemCount: _gameList.length,
                      itemBuilder: (context, index) {
                        return AnimatedBuilder(
                          animation: _pageController,
                          builder: (context, child) {
                            double value = 1.0;
                            if (_pageController.position.haveDimensions) {
                              value = _pageController.page! - index;
                              value = (1 - (value.abs() * 0.25)).clamp(0.0, 1.0);
                            }
                            return Center(
                              child: Transform.scale(
                                scale: Curves.easeOut.transform(value),
                                child: Opacity(
                                  opacity: value.clamp(0.5, 1.0),
                                  child: SizedBox(
                                    height: 480,
                                    width: double.infinity,
                                    child: child,
                                  ),
                                ),
                              ),
                            );
                          },
                          child: _buildGameCard(_gameList[index]),
                        );
                      },
                    ),
                  ),
                  
                  // Page Indicators
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _gameList.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          height: 8,
                          width: _currentPage == index ? 24 : 8,
                          decoration: BoxDecoration(
                            color: _currentPage == index 
                                ? const Color(0xFFFFD700) 
                                : Colors.white24,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: _currentPage == index ? [
                              BoxShadow(
                                color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                                blurRadius: 8,
                              )
                            ] : [],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Back Button
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameCard(Map<String, dynamic> game) {
    return GestureDetector(
      onTap: () {
        if (game['id'] == 'royal_quest') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChangeNotifierProvider(
                create: (_) => GameProvider(),
                child: const RoyalQuestGame(),
              ),
            ),
          );
        } else if (game['id'] == 'backgammon') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const BackgammonGame(),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('قيد التطوير ستنطلق قريبا 👑'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: game['color'],
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(game['bgImage'] ?? game['image']),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: game['color'].withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: Stack(
            children: [
              // Dark overlay to make Flutter widgets readable over the background image
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.2),
                        Colors.black.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                    // Play Button
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'العب الآن',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
