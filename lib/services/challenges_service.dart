import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

class ChallengesService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  // أنواع التحديات اليومية
  static const String typeChat = 'chat_messages';
  static const String typeGift = 'send_gifts';
  static const String typeRoomTime = 'room_stay_time';
  static const String typeFollow = 'new_follows';
  static const String typeLike = 'give_likes';

  /// تحديث التقدم في تحدي معين بشكل حقيقي (Real-time tracking)
  static Future<void> updateProgress(String type, {int increment = 1}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final today = DateTime.now();
    final dateId = "${today.year}-${today.month}-${today.day}";
    final progressRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('daily_challenges_progress')
        .doc(dateId);

    try {
      await _firestore.runTransaction((transaction) async {
        final snap = await transaction.get(progressRef);
        int current = 0;
        Map<String, dynamic> data = {};

        if (snap.exists) {
          data = Map<String, dynamic>.from(snap.data()!);
          current = (data[type] ?? 0).toInt();
        }

        int newProgress = current + increment;
        data[type] = newProgress;
        data['last_updated'] = FieldValue.serverTimestamp();

        transaction.set(progressRef, data, SetOptions(merge: true));

        // التحقق من اكتمال التحدي ومنح الجوائز
        await _checkAndReward(user.uid, type, newProgress, transaction);
      });
    } catch (e) {
      print("Error updating challenge progress: $e");
    }
  }

  static Future<void> _checkAndReward(
      String uid, String type, int newProgress, Transaction transaction) async {
    // إعدادات أهداف التحديات
    final thresholds = {
      typeChat: {
        'goal': 50,
        'reward': 20,
        'reward_type': 'stars',
        'title': 'متحدث لبق 🎙️'
      },
      typeGift: {
        'goal': 3,
        'reward': 100,
        'reward_type': 'stars',
        'title': 'كريم النفس 🎁'
      },
      typeRoomTime: {
        'goal': 30,
        'reward': 50,
        'reward_type': 'xp',
        'title': 'مواطن وفي 🛡️'
      }, // 30 دقيقة
      typeFollow: {
        'goal': 5,
        'reward': 15,
        'reward_type': 'stars',
        'title': 'اجتماعي نشط 👥'
      },
      typeLike: {
        'goal': 10,
        'reward': 10,
        'reward_type': 'stars',
        'title': 'ناشر السعادة ❤️'
      },
    };

    final config = thresholds[type];
    if (config == null) return;

    int goal = config['goal'] as int;

    // نمنح الجائزة فقط لحظة الوصول للهدف بالضبط لمنع التكرار في نفس اليوم
    if (newProgress == goal) {
      final userRef = _firestore.collection('users').doc(uid);
      final reward = config['reward'] as int;
      final rewardType = config['reward_type'] as String;

      if (rewardType == 'stars') {
        transaction.update(userRef, {
          'stars': FieldValue.increment(reward),
          'coins': FieldValue.increment(reward), // Keep in sync
        });
      } else if (rewardType == 'xp') {
        transaction.update(userRef, {'royalXP': FieldValue.increment(reward)});
      }

      // إضافة إشعار في قائمة إشعارات المستخدم
      final notifRef = _firestore
          .collection('notifications')
          .doc(uid)
          .collection('items')
          .doc();
      final rewardName = rewardType == 'stars' ? 'نجمة ⭐' : 'نقطة خبرة';
      transaction.set(notifRef, {
        'title': 'تحدي مكتمل! 🏆',
        'body':
            'لقد أكملت تحدي "${config['title']}" وحصلت على $reward $rewardName',
        'type': 'challenge_complete',
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
      });

      // تسجيل في سجل الجوائز اليومية لمنع المطالبة المتكررة
      final dateId =
          "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}";
      final claimRef = _firestore
          .collection('daily_rewards_claims')
          .doc("${uid}_${type}_$dateId");
      transaction.set(claimRef, {
        'userId': uid,
        'type': type,
        'reward': reward,
        'rewardType': rewardType,
        'claimedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// الاستماع للتحديات العامة (من الإدارة)
  static Stream<QuerySnapshot<Map<String, dynamic>>> challengesStream() {
    return _firestore
        .collection('challenges')
        .where('isActive', isEqualTo: true)
        .snapshots();
  }

  /// استلام مكافأة تحدي عام عبر Cloud Function
  static Future<void> claimChallengeReward(Map<String, dynamic> data) async {
    final callable = _functions.httpsCallable('claimChallengeReward');
    await callable.call(data);
  }

  /// إدارة التحديات (للأدمن)
  static Future<Map<String, dynamic>> manageChallenge(
      Map<String, dynamic> data) async {
    final callable = _functions.httpsCallable('manageChallenge');
    final result = await callable.call(data);
    return Map<String, dynamic>.from(result.data);
  }

  /// تحديث مستوى/خبرة المستخدم (للأدمن)
  static Future<Map<String, dynamic>> updateUserLevelXP(
      {String? uid, int? stars, int? xp, int? level}) async {
    final callable = _functions.httpsCallable('updateUserPointsXP');
    final result = await callable.call({
      'uid': uid,
      'stars': stars,
      'coins': stars, // Legacy sync
      'xp': xp,
      'level': level,
    });
    return Map<String, dynamic>.from(result.data);
  }

  /// الاستماع لتقدم المستخدم اليومي (للعرض في الواجهة)
  static Stream<DocumentSnapshot<Map<String, dynamic>>> userDailyProgressStream(
      String uid) {
    final today = DateTime.now();
    final dateId = "${today.year}-${today.month}-${today.day}";
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('daily_challenges_progress')
        .doc(dateId)
        .snapshots();
  }
}
