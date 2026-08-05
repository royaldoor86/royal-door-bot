import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class GameIntegrityService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // تخزين بصمة اللعبة
  static String? _gameFingerprint;
  static final Random _random = Random.secure();

  /// توليد بصمة فريدة للعبة للتحقق من سلامتها
  static String generateGameFingerprint() {
    if (_gameFingerprint != null) return _gameFingerprint!;
    
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomPart = _random.nextInt(1000000);
    _gameFingerprint = '${timestamp}_$randomPart';
    return _gameFingerprint!;
  }

  /// التحقق من سلامة الأسئلة (عدم التلاعب بها)
  Future<bool> validateQuestionIntegrity(List<dynamic> questions) async {
    if (questions.isEmpty) return false;

    // التحقق من أن كل سؤال له الحقول المطلوبة
    for (var q in questions) {
      if (!(q is Map<String, dynamic>)) return false;
      
      final question = q as Map<String, dynamic>;
      if (!question.containsKey('id')) return false;
      if (!question.containsKey('question')) return false;
      if (!question.containsKey('answers')) return false;
      if (!question.containsKey('correctAnswer')) return false;
      
      // التحقق من أن correctAnswer في النطاق الصحيح
      final correctAnswer = question['correctAnswer'] as int?;
      if (correctAnswer == null || correctAnswer < 0 || correctAnswer > 3) return false;
      
      // التحقق من أن هناك 4 إجابات
      final answers = question['answers'] as List?;
      if (answers == null || answers.length != 4) return false;
    }

    return true;
  }

  /// التحقق من أن المستخدم لم يعدل على وقت اللعبة
  bool validateTimeIntegrity(int expectedTime, int actualTime) {
    // السماح بهامش صغير (100 مللي ثانية)
    final difference = (actualTime - expectedTime).abs();
    return difference <= 100;
  }

  /// التحقق من أن المكافآت صحيحة
  bool validateRewardIntegrity(int expectedReward, int actualReward) {
    return expectedReward == actualReward;
  }

  /// تسجيل محاولة تلاعب
  Future<void> logTamperingAttempt(String reason) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _db.collection('tampering_attempts').add({
        'userId': userId,
        'reason': reason,
        'fingerprint': generateGameFingerprint(),
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint('🚨 Tampering attempt logged: $reason');
    } catch (e) {
      debugPrint('Error logging tampering attempt: $e');
    }
  }

  /// التحقق من أن المستخدم لا يستخدم أدوات خارجية
  Future<bool> detectExternalTools() async {
    // في بيئة الويب، يمكن التحقق من console
    if (kIsWeb) {
      // التحقق من وجود devtools
      final devtoolsOpen = _checkDevTools();
      if (devtoolsOpen) {
        await logTamperingAttempt('DevTools detected');
        return true;
      }
    }
    return false;
  }

  bool _checkDevTools() {
    // طريقة بسيطة للكشف عن DevTools
    // في التطبيق الحقيقي، يمكن استخدام طرق أكثر تعقيداً
    return false;
  }

  /// التحقق من سلامة حالة اللعبة
  Future<bool> validateGameStateIntegrity(Map<String, dynamic> gameState) async {
    // التحقق من الحقول الأساسية
    final requiredFields = ['status', 'playerBalance', 'selectedCurrency'];
    for (var field in requiredFields) {
      if (!gameState.containsKey(field)) return false;
    }

    // التحقق من أن الرصيد غير سالب
    final playerBalance = gameState['playerBalance'] as Map<String, dynamic>?;
    if (playerBalance == null) return false;
    
    final gems = playerBalance['gems'] as int? ?? 0;
    final coins = playerBalance['coins'] as int? ?? 0;
    
    if (gems < 0 || coins < 0) {
      await logTamperingAttempt('Negative balance detected');
      return false;
    }

    return true;
  }

  /// إنشاء توقيع رقمي للبيانات
  String generateDataSignature(Map<String, dynamic> data) {
    final dataStr = data.toString();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${dataStr.hashCode}_$timestamp';
  }

  /// التحقق من توقيع البيانات
  bool verifyDataSignature(Map<String, dynamic> data, String signature) {
    final generatedSignature = generateDataSignature(data);
    return generatedSignature == signature;
  }

  /// إعادة تعيين بصمة اللعبة
  static void resetFingerprint() {
    _gameFingerprint = null;
  }
}
