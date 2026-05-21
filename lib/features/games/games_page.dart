import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../services/ad_manager.dart';
import 'package:provider/provider.dart';
import '../../features/domino/controllers/domino_controller.dart';
import '../domino/pages/domino_game_page.dart';
import '../../widgets/feature_lock_wrapper.dart';

class RoyaleMatchPage extends StatefulWidget {
  const RoyaleMatchPage({super.key});

  @override
  State<RoyaleMatchPage> createState() => _RoyaleMatchPageState();
}

class _RoyaleMatchPageState extends State<RoyaleMatchPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late List<Map<String, dynamic>> _gameList;

  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _initBannerAd();
    _gameList = [
      {
        'title': 'ROYAL DOMINO',
        'titleAr': 'الدومينو الملكية',
        'icon': 'assets/images/domino_icon.png',
        'image': 'assets/images/royal_domino_bg.jpg',
        'color': const Color(0xFFD4AF37),
        'onPlay': (context) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider(
                  create: (_) => DominoController(),
                  child: const RoyalDominoPage(),
                ),
              ),
            ),
      },
    ];
  }

  void _initBannerAd() {
    _bannerAd = AdManager().getBannerAd(
      size: AdSize.banner,
      onAdLoaded: () {
        if (mounted) {
          setState(() {
            _isAdLoaded = true;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
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
          _gameList.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sports_esports_outlined,
                          color: Colors.white24, size: 80),
                      SizedBox(height: 16),
                      Text(
                        'قريباً ألعاب ملكية جديدة',
                        style: TextStyle(color: Colors.white24, fontSize: 18),
                      ),
                    ],
                  ),
                )
              : PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemCount: _gameList.length,
                  itemBuilder: (context, index) =>
                      _buildGameView(_gameList[index]),
                ),
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Icon(Icons.castle, color: Color(0xFFFFD700), size: 30),
                  if (_gameList.isNotEmpty)
                    Row(
                      children: List.generate(
                        _gameList.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentPage == index
                                  ? Colors.white
                                  : Colors.white24),
                        ),
                      ),
                    ),
                  const Icon(Icons.emoji_events,
                      color: Color(0xFFFFD700), size: 30),
                ],
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _isAdLoaded && _bannerAd != null
          ? Container(
              color: Colors.black,
              height: _bannerAd!.size.height.toDouble(),
              width: _bannerAd!.size.width.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            )
          : null,
      ),
    );
  }

  Widget _buildGameView(Map<String, dynamic> game) {
    final Color gameColor = game['color'];
    return Stack(
      children: [
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [gameColor.withValues(alpha: 0.6), Colors.black])),
            child: Opacity(
                opacity: 0.8,
                child: Image.asset(game['image'],
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => const SizedBox())),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.8),
              ],
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const SizedBox(height: 40),
              Text(game['title'],
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      shadows: [
                        Shadow(
                            color: Colors.black,
                            blurRadius: 10,
                            offset: Offset(0, 4))
                      ])),
              Text(game['titleAr'],
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 24,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 60),
              ElevatedButton(
                onPressed: () => game['onPlay'](context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: gameColor,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 60, vertical: 18),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(40)),
                    elevation: 15),
                child: const Text('ابدأ اللعب الآن 👑',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 40),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.swipe, color: Colors.white54, size: 28),
                const SizedBox(width: 10),
                Text('اسحب للتنقل بين الألعاب الملكية',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 14))
              ]),
            ],
          ),
        ),
      ],
    );
  }
}
