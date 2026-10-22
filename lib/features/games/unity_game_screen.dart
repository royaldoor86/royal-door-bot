import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/acoura_service.dart';
import '../../services/unity_bridge.dart';
import '../../services/unity_game_service.dart';

enum GameStatus {
  waiting,
  playing,
  won,
  lost,
  completed,
  error,
}

/// شاشة Unity الشاملة لإدارة وعرض جميع ألعاب Unity المتعددة
class UnityGameScreen extends StatefulWidget {
  final UnityGameConfig? gameConfig;
  final Map<String, dynamic>? initialGameData;

  const UnityGameScreen({
    super.key,
    this.gameConfig,
    this.initialGameData,
  });

  @override
  State<UnityGameScreen> createState() => _UnityGameScreenState();
}

class _UnityGameScreenState extends State<UnityGameScreen> {
  late UnityGameConfig _config;

  String _playerName = 'اللاعب';
  String? _playerPhotoUrl;
  int _playerPoints = 0;
  bool _isLoadingProfile = true;
  GameStatus _gameStatus = GameStatus.waiting;
  String? _statusMessage;
  bool _rewardProcessed = false;

  StreamSubscription? _roomFailedSubscription;
  StreamSubscription? _gameFinishedSubscription;
  StreamSubscription? _backToGamesSubscription;
  StreamSubscription<DocumentSnapshot>? _userPointsSubscription;

  @override
  void initState() {
    super.initState();

    // إعداد التهيئة الافتراضية للعبة
    final initialData = widget.initialGameData ?? const {};
    _config = widget.gameConfig ??
        UnityGameConfig(
          gameId: (initialData['gameId'] as String?) ?? 'royal_snake',
          gameName: (initialData['gameName'] as String?) ?? 'Royal Unity Game',
          bundlePath: (initialData['bundlePath'] as String?) ?? '',
          sceneName: (initialData['sceneName'] as String?) ?? '',
          entryCost: (initialData['entryCost'] is num)
              ? (initialData['entryCost'] as num).toInt()
              : 100,
          winReward: (initialData['winReward'] is num)
              ? (initialData['winReward'] as num).toInt()
              : 200,
        );

    UnityBridge.instance.pointsBalance.addListener(_updatePointsFromBridge);
    unawaited(UnityBridge.instance.initialize());
    unawaited(AcouraService.requestMicrophonePermission());
    unawaited(AcouraService.syncMicStateOnStartup());

    _loadPlayerData();
    _listenToUserPointsStream();
    _listenToUnityEvents();
    _sendUserDataToUnity();
  }

  void _updatePointsFromBridge() {
    final balance = UnityBridge.instance.pointsBalance.value;
    if (!mounted || balance == null || balance == _playerPoints) return;
    setState(() => _playerPoints = balance);
  }

  void _listenToUserPointsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _userPointsSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((doc) {
      if (!doc.exists || !mounted) return;
      final rawPoints = doc.data()?['points'];
      if (rawPoints is num) {
        final newPoints = rawPoints.toInt();
        if (newPoints != _playerPoints) {
          setState(() {
            _playerPoints = newPoints;
          });
          UnityBridge.instance.pointsBalance.value = newPoints;
        }
      }
    });
  }

  void _listenToUnityEvents() {
    // 1. الاستماع إلى إخفاقات الغرف أو المود الإداري
    _roomFailedSubscription = UnityBridge.instance.onRoomFailed.listen((data) {
      if (!mounted) return;
      setState(() {
        _gameStatus = GameStatus.error;
        _statusMessage = data['reason']?.toString() ?? 'حدث خطأ في اللعبة';
      });
    });

    // 2. الاستماع لنهاية اللعبة (فوز / خسارة)
    _gameFinishedSubscription =
        UnityBridge.instance.onGameFinished.listen((data) {
      if (!mounted) return;

      final action = (data['action'] ?? data['type'] ?? data['result'])?.toString();
      if (action == 'win' || action == 'PlayerWon') {
        _handlePlayerWin();
      } else if (action == 'loss' || action == 'PlayerLost') {
        _handlePlayerLoss();
      } else {
        setState(() {
          _gameStatus = GameStatus.completed;
          _statusMessage = data['result']?.toString() ?? 'انتهت اللعبة';
        });
      }
    });

    // 3. الاستماع لطلب الرجوع
    _backToGamesSubscription =
        UnityBridge.instance.onBackToGamesRequested.listen((_) {
      if (mounted) Navigator.of(context).maybePop();
    });

    // 4. الاستماع لأي رسالة عامة من Unity
    UnityBridge.instance.registerCallback('setUserData', (_) {
      _sendUserDataToUnity();
    });
    UnityBridge.instance.registerCallback('PlayerWon', (_) {
      _handlePlayerWin();
    });
    UnityBridge.instance.registerCallback('PlayerLost', (_) {
      _handlePlayerLoss();
    });
  }

  Future<void> _sendUserDataToUnity() async {
    final payload = widget.initialGameData ??
        UnityGameService.instance.buildUserDataPayload(
          userProfile: {
            'name': _playerName,
            'profilePic': _playerPhotoUrl ?? '',
            'points': _playerPoints,
          },
          config: _config,
          currentPointsAfterDeduction: _playerPoints,
        );

    await UnityGameService.instance.sendUserDataToUnity(payload);
  }

  Future<void> _handlePlayerWin() async {
    if (_rewardProcessed || !mounted) return;
    _rewardProcessed = true;

    setState(() {
      _gameStatus = GameStatus.won;
      _statusMessage = 'تهانينا! فزت بـ ${_config.winReward} نقطة 🎉';
    });

    // إضافة النقاط فوراً في Firestore
    final success = await UnityGameService.instance.addWinReward(
      gameId: _config.gameId,
      winReward: _config.winReward,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تمت إضافة ${_config.winReward} نقطة إلى حسابك! 🏆'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handlePlayerLoss() {
    if (!mounted) return;
    setState(() {
      _gameStatus = GameStatus.lost;
      _statusMessage = 'للأسف، خسرت هذه الجولة 💔 حاول مرة أخرى!';
    });
  }

  Future<void> _loadPlayerData() async {
    final initialData = widget.initialGameData ?? const {};
    final currentUser = FirebaseAuth.instance.currentUser;

    try {
      String playerName = (initialData['name'] as String?) ??
          (initialData['playerName'] as String?) ??
          'اللاعب';
      String? playerPhotoUrl = (initialData['profilePic'] as String?) ??
          (initialData['playerPhotoUrl'] as String?);
      int playerPoints = 0;

      if (initialData['points'] is num) {
        playerPoints = (initialData['points'] as num).toInt();
      } else if (initialData['playerPoints'] is num) {
        playerPoints = (initialData['playerPoints'] as num).toInt();
      }

      if (currentUser != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        final userData = userDoc.data() ?? {};

        playerName = (userData['name'] ??
                userData['displayName'] ??
                currentUser.displayName ??
                playerName)
            .toString();

        playerPhotoUrl = (userData['profilePic'] ??
                userData['avatarUrl'] ??
                userData['photoUrl'] ??
                currentUser.photoURL ??
                playerPhotoUrl)
            .toString();

        final rawPoints = userData['points'];
        if (rawPoints is num) {
          playerPoints = rawPoints.toInt();
        }
      }

      if (!mounted) return;
      setState(() {
        _playerName = playerName;
        _playerPhotoUrl = (playerPhotoUrl != null && playerPhotoUrl.isNotEmpty)
            ? playerPhotoUrl
            : null;
        _playerPoints = playerPoints;
        _isLoadingProfile = false;
        _gameStatus = GameStatus.playing;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoadingProfile = false;
        _gameStatus = GameStatus.playing;
      });
    }
  }

  @override
  void dispose() {
    UnityBridge.instance.pointsBalance.removeListener(_updatePointsFromBridge);
    UnityBridge.instance.unregisterCallback('setUserData');
    UnityBridge.instance.unregisterCallback('PlayerWon');
    UnityBridge.instance.unregisterCallback('PlayerLost');

    _roomFailedSubscription?.cancel();
    _gameFinishedSubscription?.cancel();
    _backToGamesSubscription?.cancel();
    _userPointsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _config.gameName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(left: 16, right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.amber, width: 1),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars, color: Colors.amber, size: 18),
                const SizedBox(width: 6),
                Text(
                  '$_playerPoints',
                  style: const TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // 1. بطاقة معلومات اللاعب واللعبة
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _config.themeColor.withValues(alpha: 0.3),
                      Colors.black45,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _config.themeColor.withValues(alpha: 0.6),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white24,
                      backgroundImage: _playerPhotoUrl != null
                          ? NetworkImage(_playerPhotoUrl!)
                          : null,
                      child: _playerPhotoUrl == null
                          ? const Icon(Icons.person, color: Colors.white, size: 30)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _playerName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'الدخول: -${_config.entryCost}',
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'الفوز: +${_config.winReward}',
                                style: const TextStyle(
                                  color: Colors.greenAccent,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. حالة الرسالة الحالية
              if (_statusMessage != null)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _gameStatus == GameStatus.won
                        ? Colors.green.withValues(alpha: 0.2)
                        : _gameStatus == GameStatus.lost
                            ? Colors.red.withValues(alpha: 0.2)
                            : Colors.blue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _gameStatus == GameStatus.won
                          ? Colors.green
                          : _gameStatus == GameStatus.lost
                              ? Colors.red
                              : Colors.blue,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _gameStatus == GameStatus.won
                            ? Icons.emoji_events
                            : _gameStatus == GameStatus.lost
                                ? Icons.sentiment_dissatisfied
                                : Icons.info,
                        color: _gameStatus == GameStatus.won
                            ? Colors.amber
                            : _gameStatus == GameStatus.lost
                                ? Colors.redAccent
                                : Colors.lightBlue,
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          _statusMessage!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),

              const Spacer(),

              // 3. مساحة عرض Unity أو المحاكات التفاعلية
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sports_esports,
                      size: 80,
                      color: _config.themeColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _config.gameName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _config.bundlePath.isNotEmpty
                          ? 'المسار: ${_config.bundlePath}'
                          : 'جاري تشغيل محرك Unity...',
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // لوحة اختبار الألعاب (Simulation Test Controls)
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 10),
                    const Text(
                      'أدوات التحكم واختبار النقل التفاعلي:',
                      style: TextStyle(color: Colors.amber, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _handlePlayerWin,
                          icon: const Icon(Icons.emoji_events, size: 18),
                          label: const Text('فوز (+200)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _handlePlayerLoss,
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('خسارة (0)'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // 4. زر العودة
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _config.themeColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'العودة إلى قائمة الألعاب',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
