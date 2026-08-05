import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AntiCheatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // تخزين وقت آخر إجابة للمستخدم
  static DateTime? _lastAnswerTime;
  static int _answersInLastMinute = 0;
  static DateTime? _minuteWindowStart;

  // الحد الأقصى للإجابات في الدقيقة
  static const int maxAnswersPerMinute = 30;

  /// التحقق من أن المستخدم لا يجيب بسرعة غير طبيعية
  bool isAnsweringTooFast() {
    final now = DateTime.now();

    // إعادة تعيين النافذة إذا مرت دقيقة
    if (_minuteWindowStart == null || 
        now.difference(_minuteWindowStart!).inMinutes >= 1) {
      _minuteWindowStart = now;
      _answersInLastMinute = 0;
    }

    // التحقق من الوقت بين الإجابات
    if (_lastAnswerTime != null) {
      final timeSinceLastAnswer = now.difference(_lastAnswerTime!).inMilliseconds;
      // إذا أجاب في أقل من 500 مللي ثانية، مشبوه
      if (timeSinceLastAnswer < 500) {
        debugPrint('⚠️ Suspicious: Answer too fast (${timeSinceLastAnswer}ms)');
        return true;
      }
    }

    _lastAnswerTime = now;
    _answersInLastMinute++;

    // التحقق من عدد الإجابات في الدقيقة
    if (_answersInLastMinute > maxAnswersPerMinute) {
      debugPrint('⚠️ Suspicious: Too many answers in one minute ($_answersInLastMinute)');
      return true;
    }

    return false;
  }

  /// تسجيل نشاط مشبوه
  Future<void> logSuspiciousActivity(String reason) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _db.collection('suspicious_activity').add({
        'userId': userId,
        'reason': reason,
        'timestamp': FieldValue.serverTimestamp(),
        'userAgent': _getUserAgent(),
      });
      debugPrint('🚨 Suspicious activity logged: $reason');
    } catch (e) {
      debugPrint('Error logging suspicious activity: $e');
    }
  }

  /// التحقق من سلامة اللعبة من الخادم
  Future<bool> validateGameSession(String sessionId) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    try {
      final doc = await _db.collection('game_sessions').doc(sessionId).get();
      if (!doc.exists) return false;

      final data = doc.data() as Map<String, dynamic>;
      return data['userId'] == userId && data['isValid'] == true;
    } catch (e) {
      debugPrint('Error validating game session: $e');
      return false;
    }
  }

  /// إنشاء جلسة لعبة جديدة
  Future<String> createGameSession() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User not logged in');

    try {
      final docRef = await _db.collection('game_sessions').add({
        'userId': userId,
        'startTime': FieldValue.serverTimestamp(),
        'isValid': true,
        'answers': [],
        'cheatDetected': false,
      });
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating game session: $e');
      throw e;
    }
  }

  /// تسجيل إجابة في جلسة اللعبة
  Future<void> recordAnswer(String sessionId, int questionId, int answerIndex, bool isCorrect) async {
    try {
      await _db.collection('game_sessions').doc(sessionId).update({
        'answers': FieldValue.arrayUnion([
          {
            'questionId': questionId,
            'answerIndex': answerIndex,
            'isCorrect': isCorrect,
            'timestamp': FieldValue.serverTimestamp(),
          }
        ]),
      });
    } catch (e) {
      debugPrint('Error recording answer: $e');
    }
  }

  /// إلغاء صلاحية جلسة اللعبة عند اكتشاف غش
  Future<void> invalidateSession(String sessionId, String reason) async {
    try {
      await _db.collection('game_sessions').doc(sessionId).update({
        'isValid': false,
        'cheatDetected': true,
        'cheatReason': reason,
        'invalidatedAt': FieldValue.serverTimestamp(),
      });
      await logSuspiciousActivity(reason);
    } catch (e) {
      debugPrint('Error invalidating session: $e');
    }
  }

  /// التحقق من أن المستخدم لا يلعب أكثر من جلسة في نفس الوقت
  Future<bool> hasConcurrentSession() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    try {
      final snapshot = await _db
          .collection('game_sessions')
          .where('userId', isEqualTo: userId)
          .where('isValid', isEqualTo: true)
          .where('cheatDetected', isEqualTo: false)
          .get();

      // التحقق من أن الجلسات نشطة (أقل من ساعة)
      final now = DateTime.now();
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final startTime = (data['startTime'] as Timestamp).toDate();
        if (now.difference(startTime).inHours < 1) {
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('Error checking concurrent sessions: $e');
      return false;
    }
  }

  /// التحقق من معدل الفوز المشبوه
  Future<bool> isWinRateSuspicious() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    try {
      // جلب آخر 50 جلسة
      final snapshot = await _db
          .collection('game_sessions')
          .where('userId', isEqualTo: userId)
          .orderBy('startTime', descending: true)
          .limit(50)
          .get();

      if (snapshot.docs.length < 10) return false;

      int wins = 0;
      int total = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['cheatDetected'] == true) continue;

        total++;
        // إذا أكمل مرحلة أو أكثر، يعتبر فوز
        if (data['answers'] != null && (data['answers'] as List).length >= 10) {
          wins++;
        }
      }

      if (total == 0) return false;

      final winRate = wins / total;
      // إذا كان معدل الفوز أعلى من 90%، مشبوه
      if (winRate > 0.9) {
        debugPrint('⚠️ Suspicious win rate: ${(winRate * 100).toStringAsFixed(1)}%');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error checking win rate: $e');
      return false;
    }
  }

  String _getUserAgent() {
    // في الويب يمكن الحصول على user agent
    // في الموبايل نستخدم معلومات الجهاز
    return kIsWeb ? 'web' : 'mobile';
  }

  /// إعادة تعيين عدادات الاختبار
  static void resetCounters() {
    _lastAnswerTime = null;
    _answersInLastMinute = 0;
    _minuteWindowStart = null;
  }
}
