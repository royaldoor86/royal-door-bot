import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../widgets/feature_lock_wrapper.dart';
import 'royal_quest/royal_quest_game.dart';
import 'royal_quest/providers/game_provider.dart';
import 'royal_xo/royal_xo_mode_selection.dart';
import 'unity_game_screen.dart';
import '../../services/unity_bridge.dart';
import '../../services/unity_game_service.dart';
import 'dart:ui' as ui;

class RoyaleMatchPage extends StatefulWidget {
  const RoyaleMatchPage({super.key});

  @override
  State<RoyaleMatchPage> createState() => _RoyaleMatchPageState();
}

class _RoyaleMatchPageState extends State<RoyaleMatchPage> {
  static const MethodChannel _unityChannel = MethodChannel('com.royaldoor.unity');

  late final PageController _pageController;
  int _currentPage = 0;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late List<Map<String, dynamic>> _gameList;

  @override
  void initState() {
    super.initState();
    unawaited(UnityBridge.instance.initialize());
    _pageController = PageController(viewportFraction: 0.82);

    // تجهيز قائمة الألعاب الـ 10 المعرفة في UnityGameRegistry
    _gameList = [
      {
        'id': 'lara_card',
        'name': 'Lara Card',
        'image': 'assets/images/royalcard1.png',
        'color': const Color(0xFFD4AF37),
        'icon': Icons.style,
        'description': 'جرب لعبة البطاقات الفريدة Lara Card 👑 (الدخول: 100 | الفوز: 200)'
      },
      {
        'id': 'ludo_royal',
        'name': 'Ludo Royal',
        'image': 'assets/images/Royal_ludo.png',
        'color': const Color(0xFF1B5E20),
        'icon': Icons.grid_view_rounded,
        'description': 'لعبة اللودو الكلاسيكية بتصميم ملكي 🎲 (الدخول: 100 | الفوز: 200)'
      },
      {
        'id': 'royal_snake',
        'name': 'Royal Snake',
        'image': 'assets/images/snake.png',
        'color': const Color(0xFF7B3F00),
        'icon': Icons.pets,
        'description': 'استعد لمغامرة الثعبان الملكية 🐍 (الدخول: 100 | الفوز: 200)'
      },
      {
        'id': 'xo_royal',
        'name': 'XO Royal',
        'image': 'assets/images/tic_tac_toe.png',
        'bgImage': 'assets/images/xo1.png',
        'color': const Color(0xFF0D47A1),
        'icon': Icons.grid_3x3,
        'description': 'اللعبة الكلاسيكية السريعة بلمسة ملكية ⚔️ (الدخول: 50 | الفوز: 100)'
      },
      {
        'id': 'royal_backgammon',
        'name': 'Royal Backgammon',
        'image': 'assets/images/Backgammon_royal_icon.png',
        'bgImage': 'assets/images/Backgammon_royal_bg.jpg',
        'color': const Color(0xFF4A148C),
        'icon': Icons.casino,
        'description': 'لعبة الطاولي الملكية الشهيرة 🎲 (الدخول: 150 | الفوز: 300)'
      },
      {
        'id': 'domino_royal',
        'name': 'Domino Royal',
        'image': 'assets/images/Dominoroyal.jpeg',
        'color': const Color(0xFF37474F),
        'icon': Icons.view_comfortable_rounded,
        'description': 'تحدى أصدقائك في لعبة الدومينو الملكية 🀄 (الدخول: 100 | الفوز: 200)'
      },
      {
        'id': 'royal_war',
        'name': 'Royal War',
        'image': 'assets/images/War.png',
        'color': const Color(0xFFB71C1C),
        'icon': Icons.shield_rounded,
        'description': 'استعد للمعركة الكبرى في الحرب الملكية ⚔️ (الدخول: 200 | الفوز: 400)'
      },
      {
        'id': 'royal_mahjong',
        'name': 'Royal Mahjong',
        'image': 'assets/images/MAHJONG.png',
        'color': const Color(0xFFE65100),
        'icon': Icons.auto_awesome,
        'description': 'اكتشف أسرار رويال موهينجو المذهلة ✨ (الدخول: 150 | الفوز: 300)'
      },
      {
        'id': 'royal_pool',
        'name': 'Royal Pool',
        'image': 'assets/images/bool.png',
        'color': const Color(0xFF004D40),
        'icon': Icons.sports_handball_sharp,
        'description': 'أظهر مهاراتك في تصويب كرات البلياردو 🎱 (الدخول: 100 | الفوز: 200)'
      },
      {
        'id': 'royal_fruit',
        'name': 'Royal Fruit',
        'image': 'assets/images/Fruit.png',
        'color': const Color(0xFFC2185B),
        'icon': Icons.apple,
        'description': 'تحدى أصدقائك في حرب الفواكه الممتعة 🍎 (الدخول: 50 | الفوز: 100)'
      },
      {
        'id': 'royal_quest',
        'name': 'Royal Quest',
        'image': 'assets/images/quest2.png',
        'bgImage': 'assets/images/quest3.png',
        'color': const Color(0xFF1A237E),
        'icon': Icons.castle,
        'description': 'اختبر معلوماتك واحصل على هدية الفوز 🏆'
      },
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildGameCard(Map<String, dynamic> game) {
    final bool isChallenge = game['isChallenge'] == true;
    
    return GestureDetector(
      onTap: () async {
        if (isChallenge) {
          _joinChallenge(game['challengeData'], game['id']);
          return;
        }
        
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
        } else {
          final gameId = (game['id'] ?? '').toString();
          final config = UnityGameRegistry.getGame(gameId);

          // تشغيل لعبة Unity من خلال الخدمة الموحدة
          await UnityGameService.instance.launchUnityGame(context, config);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(45),
          border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.9),
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.8),
              blurRadius: 25,
              offset: const Offset(0, 15),
            ),
            BoxShadow(
              color: (game['color'] as Color? ?? Colors.blue).withValues(alpha: 0.5),
              blurRadius: 30,
              spreadRadius: -2,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(41),
          child: Stack(
            children: [
              Positioned.fill(
                child: isChallenge && game['image'] != null && game['image'].isNotEmpty
                  ? Image.network(
                    game['image'] as String,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                      Container(color: game['color'] as Color? ?? Colors.blue),
                    )
                    : (game['bgImage'] != null && (game['bgImage'] as String).isNotEmpty)
                        ? Image.asset(game['bgImage'] as String, fit: BoxFit.cover)
                        : (game['image'] != null && (game['image'] as String).isNotEmpty)
                            ? Image.asset(game['image'] as String, fit: BoxFit.cover)
                            : Container(color: game['color'] as Color? ?? Colors.blue),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.4),
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(45),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 2,
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
                            if (isChallenge && game['challengeData'] != null)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    game['challengeData']['title'] ?? 'تحدي الألعاب التنافسية',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFFFFD700),
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'Cairo',
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.62),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.55)),
                                    ),
                                    child: Text(
                                      'قيمة الهدية الممنوحة: ${game['challengeData']['prize'] ?? 0} ${game['challengeData']['currency'] == 'points' ? 'نقطة' : 'نجمة'}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  if (game['challengeData']['details'] != null && game['challengeData']['details'].toString().isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.6),
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(color: Colors.white24),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'التفاصيل:',
                                            style: TextStyle(
                                              color: Color(0xFFFFD700),
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            game['challengeData']['details'] ?? '',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  StreamBuilder<QuerySnapshot>(
                                    stream: _db
                                        .collection('challenge_participants')
                                        .where('challengeId', isEqualTo: game['id'])
                                        .where('userId', isEqualTo: _auth.currentUser?.uid)
                                        .snapshots(),
                                    builder: (context, participantSnapshot) {
                                      if (!participantSnapshot.hasData || participantSnapshot.data!.docs.isEmpty) {
                                        return const SizedBox.shrink();
                                      }
                                      final participant = participantSnapshot.data!.docs.first;
                                      final progress = participant['progress'] ?? 0;
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'تقدمك:',
                                            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: LinearProgressIndicator(
                                              value: progress / 100,
                                              backgroundColor: Colors.white24,
                                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                                              minHeight: 8,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFB8860B), Color(0xFF8B4513)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.6),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                          BoxShadow(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'العب الآن',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            letterSpacing: 2.0,
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

  Future<void> _joinChallenge(Map<String, dynamic> challengeData, String challengeId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يجب تسجيل الدخول للمشاركة في التحدي')),
      );
      return;
    }
    
    try {
      final existingParticipant = await _db
          .collection('challenge_participants')
          .where('challengeId', isEqualTo: challengeId)
          .where('userId', isEqualTo: userId)
          .get();

      if (existingParticipant.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('أنت مشارك بالفعل في هذا التحدي'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      await _db.collection('challenge_participants').add({
        'challengeId': challengeId,
        'userId': userId,
        'joinedAt': FieldValue.serverTimestamp(),
        'progress': 0,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم الانضمام للتحدي: ${challengeData['title']}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFFFD700),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FeatureLockWrapper(
      lockField: 'isGamesLocked',
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
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
            Positioned.fill(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.castle, color: Color(0xFFFFD700), size: 28),
                        const Text(
                          'مركز الألعاب الملكي',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
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
                        const Icon(Icons.emoji_events, color: Color(0xFFFFD700), size: 28),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _db
                          .collection('guild_challenges')
                          .where('status', isEqualTo: 'active')
                          .where('endTime', isGreaterThan: Timestamp.now())
                          .orderBy('endTime', descending: false)
                          .limit(5)
                          .snapshots(),
                      builder: (context, challengesSnapshot) {
                        List<Map<String, dynamic>> combinedList = List.from(_gameList);
                        
                        if (challengesSnapshot.hasData && challengesSnapshot.data!.docs.isNotEmpty) {
                          for (var doc in challengesSnapshot.data!.docs) {
                            final challenge = doc.data() as Map<String, dynamic>;
                            combinedList.add({
                              'id': doc.id,
                              'name': challenge['title'] ?? 'تحدي',
                              'image': challenge['imageUrl'] ?? '',
                              'bgImage': challenge['imageUrl'] ?? '',
                              'color': const Color(0xFFFFD700),
                              'icon': Icons.emoji_events,
                              'description': 'قيمة الهدية: ${challenge['prize']} ${challenge['currency'] == 'points' ? 'نقطة' : 'نجمة'}',
                              'isChallenge': true,
                              'challengeData': challenge,
                            });
                          }
                        }
                        
                        return PageView.builder(
                          controller: _pageController,
                          onPageChanged: (int page) {
                            setState(() {
                              _currentPage = page;
                            });
                          },
                          itemCount: combinedList.length,
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
                                        height: 500,
                                        width: double.infinity,
                                        child: child,
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: _buildGameCard(combinedList[index]),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _db
                          .collection('guild_challenges')
                          .where('status', isEqualTo: 'active')
                          .where('endTime', isGreaterThan: Timestamp.now())
                          .limit(5)
                          .snapshots(),
                      builder: (context, snapshot) {
                        int totalItems = _gameList.length;
                        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                          totalItems += snapshot.data!.docs.length;
                        }
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            totalItems,
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
                                    color: const Color(0xFFFFD700).withOpacity(0.5),
                                    blurRadius: 8,
                                  )
                                ] : [],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
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
}
