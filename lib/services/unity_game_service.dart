import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../features/games/unity_game_screen.dart';
import 'unity_bridge.dart';

/// نموذج بيانات إعدادات لعبة Unity
class UnityGameConfig {
  final String gameId;
  final String gameName;
  final String bundlePath;
  final String sceneName;
  final int entryCost;
  final int winReward;
  final String? iconAsset;
  final String? imageAsset;
  final Color themeColor;
  final String description;

  const UnityGameConfig({
    required this.gameId,
    required this.gameName,
    this.bundlePath = '',
    this.sceneName = 'MenuScene',
    this.entryCost = 100,
    this.winReward = 200,
    this.iconAsset,
    this.imageAsset,
    this.themeColor = const Color(0xFFD4AF37),
    this.description = '',
  });

  Map<String, dynamic> toJson() => {
        'action': 'setUserData',
        'gameId': gameId,
        'gameName': gameName,
        'bundlePath': bundlePath,
        'sceneName': sceneName,
        'entryCost': entryCost,
        'winReward': winReward,
      };
}

/// سجل الألعاب الـ 10 المعرف المسبق لسهولة الوصول والإضافة المستقبلي
class UnityGameRegistry {
  static const Map<String, UnityGameConfig> games = {
    // 1. Lara Card
    'lara_card': UnityGameConfig(
      gameId: 'lara_card',
      gameName: 'Lara Card',
      bundlePath: 'bundles/lara_card',
      sceneName: 'MenuScene',
      entryCost: 100,
      winReward: 200,
      imageAsset: 'assets/images/royalcard1.png',
      themeColor: Color(0xFFD4AF37),
      description: 'جرب لعبة البطاقات الفريدة Lara Card 👑',
    ),

    // 2. Ludo Royal
    'ludo_royal': UnityGameConfig(
      gameId: 'ludo_royal',
      gameName: 'Ludo Royal',
      bundlePath: 'bundles/ludo_royal',
      sceneName: 'MenuScene',
      entryCost: 100,
      winReward: 200,
      imageAsset: 'assets/images/Royal_ludo.png',
      themeColor: Color(0xFF1B5E20),
      description: 'لعبة اللودو الكلاسيكية بتصميم ملكي 🎲',
    ),

    // 3. Royal Snake
    'royal_snake': UnityGameConfig(
      gameId: 'royal_snake',
      gameName: 'Royal Snake',
      bundlePath: 'bundles/royal_snake',
      sceneName: 'MenuScene',
      entryCost: 100,
      winReward: 200,
      imageAsset: 'assets/images/snake.png',
      themeColor: Color(0xFF7B3F00),
      description: 'استعد لمغامرة الثعبان الملكية 🐍',
    ),

    // 4. XO Royal
    'xo_royal': UnityGameConfig(
      gameId: 'xo_royal',
      gameName: 'XO Royal',
      bundlePath: 'bundles/xo_royal',
      sceneName: 'MenuScene',
      entryCost: 50,
      winReward: 100,
      imageAsset: 'assets/images/tic_tac_toe.png',
      themeColor: Color(0xFF0D47A1),
      description: 'اللعبة الكلاسيكية السريعة XO بلمسة ملكية ⚔️',
    ),

    // 5. Royal Backgammon
    'royal_backgammon': UnityGameConfig(
      gameId: 'royal_backgammon',
      gameName: 'Royal Backgammon',
      bundlePath: 'bundles/royal_backgammon',
      sceneName: 'MenuScene',
      entryCost: 150,
      winReward: 300,
      imageAsset: 'assets/images/Backgammon_royal_icon.png',
      themeColor: Color(0xFF4A148C),
      description: 'لعبة الطاولي الملكية الشهيرة 🎲',
    ),

    // 6. Domino Royal
    'domino_royal': UnityGameConfig(
      gameId: 'domino_royal',
      gameName: 'Domino Royal',
      bundlePath: 'bundles/domino_royal',
      sceneName: 'MenuScene',
      entryCost: 100,
      winReward: 200,
      imageAsset: 'assets/images/Dominoroyal.jpeg',
      themeColor: Color(0xFF37474F),
      description: 'تحدى أصدقائك في لعبة الدومينو الملكية 🀄',
    ),

    // 7. Royal War
    'royal_war': UnityGameConfig(
      gameId: 'royal_war',
      gameName: 'Royal War',
      bundlePath: 'bundles/royal_war',
      sceneName: 'MenuScene',
      entryCost: 200,
      winReward: 400,
      imageAsset: 'assets/images/War.png',
      themeColor: Color(0xFFB71C1C),
      description: 'استعد للمعركة الكبرى في الحرب الملكية ⚔️',
    ),

    // 8. Royal Mahjong
    'royal_mahjong': UnityGameConfig(
      gameId: 'royal_mahjong',
      gameName: 'Royal Mahjong',
      bundlePath: 'bundles/royal_mahjong',
      sceneName: 'MenuScene',
      entryCost: 150,
      winReward: 300,
      imageAsset: 'assets/images/MAHJONG.png',
      themeColor: Color(0xFFE65100),
      description: 'اكتشف أسرار رويال موهينجو المذهلة ✨',
    ),

    // 9. Royal Pool
    'royal_pool': UnityGameConfig(
      gameId: 'royal_pool',
      gameName: 'Royal Pool',
      bundlePath: 'bundles/royal_pool',
      sceneName: 'MenuScene',
      entryCost: 100,
      winReward: 200,
      imageAsset: 'assets/images/bool.png',
      themeColor: Color(0xFF004D40),
      description: 'أظهر مهاراتك في تصويب كرات البلياردو 🎱',
    ),

    // 10. Royal Fruit
    'royal_fruit': UnityGameConfig(
      gameId: 'royal_fruit',
      gameName: 'Royal Fruit',
      bundlePath: 'bundles/royal_fruit',
      sceneName: 'MenuScene',
      entryCost: 50,
      winReward: 100,
      imageAsset: 'assets/images/Fruit.png',
      themeColor: Color(0xFFC2185B),
      description: 'تحدى أصدقائك في حرب الفواكه الممتعة 🍎',
    ),
  };

  /// الحصول على إعدادات لعبة بالـ ID أو إنشاء إعدادات افتراضية
  static UnityGameConfig getGame(String gameId) {
    return games[gameId] ??
        UnityGameConfig(
          gameId: gameId,
          gameName: gameId,
          bundlePath: 'bundles/$gameId',
          sceneName: 'MenuScene',
          entryCost: 100,
          winReward: 200,
        );
  }
}

/// الخدمة المركزية لإدارة جميع ألعاب Unity الـ 10 في تطبيق Flutter
class UnityGameService {
  static UnityGameService? _instance;
  static UnityGameService get instance => _instance ??= UnityGameService._();

  UnityGameService._();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  /// جلب بيانات المستخدم الحالية من Firestore (users)
  Future<Map<String, dynamic>?> fetchUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final data = doc.data() ?? {};

      final rawPoints = data['points'];
      final points = rawPoints is num ? rawPoints.toInt() : 0;

      final name = (data['name'] ??
              data['displayName'] ??
              user.displayName ??
              'اللاعب')
          .toString();

      final profilePic = (data['profilePic'] ??
              data['avatarUrl'] ??
              data['photoUrl'] ??
              user.photoURL ??
              '')
          .toString();

      return {
        'uid': user.uid,
        'name': name,
        'points': points,
        'profilePic': profilePic,
      };
    } catch (e) {
      debugPrint('Error fetching user profile for Unity game: $e');
      return null;
    }
  }

  /// خصم نقاط الدخول عند فتح اللعبة (تحديث فوري في Firestore عبر Transaction)
  Future<bool> deductEntryPoints({
    required String gameId,
    required int entryCost,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    if (entryCost <= 0) return true;

    try {
      return await _firestore.runTransaction<bool>((transaction) async {
        final userRef = _firestore.collection('users').doc(user.uid);
        final snapshot = await transaction.get(userRef);

        if (!snapshot.exists) return false;

        final currentPoints =
            (snapshot.data()?['points'] as num?)?.toInt() ?? 0;
        if (currentPoints < entryCost) {
          return false; // نقاط غير كافية
        }

        final newPoints = currentPoints - entryCost;
        transaction.update(userRef, {
          'points': newPoints,
          'lastGameEntry': {
            'gameId': gameId,
            'entryCost': entryCost,
            'timestamp': FieldValue.serverTimestamp(),
          }
        });

        return true;
      });
    } catch (e) {
      debugPrint('Error deducting entry points in Firestore: $e');
      return false;
    }
  }

  /// إضافة نقاط المكافأة فور الفوز (تحديث فوري في Firestore)
  Future<bool> addWinReward({
    required String gameId,
    required int winReward,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return false;
    if (winReward <= 0) return true;

    try {
      final userRef = _firestore.collection('users').doc(user.uid);
      await userRef.update({
        'points': FieldValue.increment(winReward),
        'lastGameWin': {
          'gameId': gameId,
          'reward': winReward,
          'timestamp': FieldValue.serverTimestamp(),
        }
      });
      return true;
    } catch (e) {
      debugPrint('Error adding win reward in Firestore: $e');
      return false;
    }
  }

  /// تجهيز حمولة البيانات المطلوبة لنقلها إلى Unity:
  /// ```json
  /// {
  ///   "action": "setUserData",
  ///   "name": (من Firestore),
  ///   "points": (من Firestore بعد خصم تكلفة الدخول),
  ///   "profilePic": (من Firestore),
  ///   "entryCost": (تكلفة الدخول للعبة),
  ///   "winReward": (مكافأة الفوز للعبة),
  ///   "gameId": (معرف اللعبة),
  ///   "gameName": (اسم اللعبة),
  ///   "bundlePath": (مسار Bundle),
  ///   "sceneName": (اسم المشهد)
  /// }
  /// ```
  Map<String, dynamic> buildUserDataPayload({
    required Map<String, dynamic> userProfile,
    required UnityGameConfig config,
    required int currentPointsAfterDeduction,
  }) {
    return {
      'action': 'setUserData',
      'name': userProfile['name'] ?? 'اللاعب',
      'points': currentPointsAfterDeduction,
      'profilePic': userProfile['profilePic'] ?? '',
      'entryCost': config.entryCost,
      'winReward': config.winReward,
      'gameId': config.gameId,
      'gameName': config.gameName,
      'bundlePath': config.bundlePath,
      'sceneName': config.sceneName,
    };
  }

  /// إرسال حمولة البيانات إلى Unity عبر UnityBridge مع استهداف MenuManager
  Future<bool> sendUserDataToUnity(
    Map<String, dynamic> payload, {
    String target = 'MenuManager',
  }) async {
    try {
      final jsonMessage = jsonEncode(payload);

      // إرسال إلى MenuManager (الهدف المحدد في Unity)
      await UnityBridge.instance.sendMessageToUnity(
        target: target,
        method: 'SetUserDataFromFlutter',
        message: jsonMessage,
      );

      // إرسال كخيار احتياطي إلى PlayerInfoManager
      if (target != 'PlayerInfoManager') {
        await UnityBridge.instance.sendMessageToUnity(
          target: 'PlayerInfoManager',
          method: 'SetUserDataFromFlutter',
          message: jsonMessage,
        );
      }

      debugPrint('Sent Unity userData payload to target [$target]: $jsonMessage');
      return true;
    } catch (e) {
      debugPrint('Failed to send userData payload to Unity: $e');
      return false;
    }
  }

  /// الدالة العامة الموحدة لفتح أي لعبة Unity من الـ 10 ألعاب
  Future<void> launchUnityGame(
    BuildContext context,
    UnityGameConfig config,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب تسجيل الدخول للعب ألعاب Unity'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // 1. إظهار مؤشر التحميل
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.amber),
      ),
    );

    try {
      // 2. قراءة بيانات المستخدم من Firestore
      final userProfile = await fetchUserProfile();

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop(); // إغلاق مؤشر التحميل

      if (userProfile == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تعذر جلب بيانات ملف المستخدم'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final int currentPoints = userProfile['points'] as int;

      // 3. التحقق من توفر النقاط
      if (currentPoints < config.entryCost) {
        showDialog(
          context: context,
          builder: (dialogCtx) => AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.amber, width: 1.5),
            ),
            title: Row(
              children: [
                const Icon(Icons.stars, color: Colors.amber, size: 28),
                const SizedBox(width: 8),
                Text(
                  config.gameName,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'نقاطك غير كافية لدخول هذه اللعبة',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('تكلفة الدخول:',
                              style: TextStyle(color: Colors.amber)),
                          Text('${config.entryCost} نقطة',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('مكافأة الفوز:',
                              style: TextStyle(color: Colors.greenAccent)),
                          Text('${config.winReward} نقطة',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('رصيدك الحالي:',
                              style: TextStyle(color: Colors.white60)),
                          Text('$currentPoints نقطة',
                              style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('حسناً', style: TextStyle(color: Colors.amber)),
              ),
            ],
          ),
        );
        return;
      }

      // 4. خصم نقاط الدخول فوراً عبر Transaction
      final bool deducted = await deductEntryPoints(
        gameId: config.gameId,
        entryCost: config.entryCost,
      );

      if (!deducted) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل خصم نقاط الدخول، يرجى المحاولة لاحقاً'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final int pointsAfterDeduction = currentPoints - config.entryCost;

      // 5. بناء حمولة البيانات
      final payload = buildUserDataPayload(
        userProfile: userProfile,
        config: config,
        currentPointsAfterDeduction: pointsAfterDeduction,
      );

      // 6. التخزين المؤقت للبيانات
      UnityBridge.instance.cachePlayerInfo(
        name: payload['name'] as String,
        imageUrl: payload['profilePic'] as String,
        points: pointsAfterDeduction,
      );
      UnityBridge.instance.pointsBalance.value = pointsAfterDeduction;

      // 7. إرسال البيانات إلى Unity وفتح الشاشة
      await sendUserDataToUnity(payload, target: 'MenuManager');

      if (!context.mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UnityGameScreen(
            gameConfig: config,
            initialGameData: payload,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      debugPrint('Error launching Unity game: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء فتح اللعبة: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
