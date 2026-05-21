import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/social_points_model.dart';
import 'challenges_service.dart';

class SocialService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  // ------------------------
  // Followers & Following
  // ------------------------
  static Future<void> followUser(String targetUid) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null || currentUid == targetUid) return;

    final batch = _firestore.batch();

    // 1. تحديث قائمة المتابعين للشخص المستهدف
    final followerRef = _firestore.collection('followers').doc(targetUid);
    batch.set(
        followerRef,
        {
          'count': FieldValue.increment(1),
          'lastFollower': currentUid,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true));

    final followerItemRef = followerRef.collection('items').doc(currentUid);
    batch.set(followerItemRef, {
      'uid': currentUid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 2. تحديث قائمة المتابعة للشخص الحالي
    final followRef = _firestore.collection('follows').doc(currentUid);
    batch.set(
        followRef,
        {
          'count': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true));

    final followItemRef = followRef.collection('items').doc(targetUid);
    batch.set(followItemRef, {
      'uid': targetUid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 3. تحديث مصفوفات اليوزر
    batch.update(_firestore.collection('users').doc(currentUid), {
      'following': FieldValue.arrayUnion([targetUid])
    });
    batch.update(_firestore.collection('users').doc(targetUid), {
      'followers': FieldValue.arrayUnion([currentUid])
    });

    await batch.commit();

    // إضافة نجوم اجتماعية ونجوم ودية ⭐
    await addSocialPoints(currentUid, 'follow_given', 5);
    await addSocialPoints(targetUid, 'follow_received', 10);

    // ربط التحديات اليومية (تحدي المتابعات الجديدة)
    await ChallengesService.updateProgress(ChallengesService.typeFollow);

    await sendNotification(
      targetUid: targetUid,
      title: 'متابع جديد 👤',
      body: 'قام أحدهم بمتابعة بروفايلك الملكي!',
      type: 'follow',
    );
  }

  static Future<void> unfollowUser(String targetUid) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null || currentUid == targetUid) return;

    final batch = _firestore.batch();

    final followerRef = _firestore.collection('followers').doc(targetUid);
    batch.set(followerRef, {'count': FieldValue.increment(-1)},
        SetOptions(merge: true));
    batch.delete(followerRef.collection('items').doc(currentUid));

    final followRef = _firestore.collection('follows').doc(currentUid);
    batch.set(followRef, {'count': FieldValue.increment(-1)},
        SetOptions(merge: true));
    batch.delete(followRef.collection('items').doc(targetUid));

    batch.update(_firestore.collection('users').doc(currentUid), {
      'following': FieldValue.arrayRemove([targetUid])
    });
    batch.update(_firestore.collection('users').doc(targetUid), {
      'followers': FieldValue.arrayRemove([currentUid])
    });

    await batch.commit();
  }

  // ------------------------
  // Notifications
  // ------------------------
  static Future<void> sendNotification({
    required String targetUid,
    required String title,
    required String body,
    required String type,
  }) async {
    final notificationRef = _firestore
        .collection('notifications')
        .doc(targetUid)
        .collection('items')
        .doc();

    await notificationRef.set({
      'title': title,
      'body': body,
      'type': type,
      'isRead': false,
      'senderId': _auth.currentUser?.uid,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ------------------------
  // Social & Friendly Stars System ⭐ (REAL LINK)
  // ------------------------
  static Future<void> addSocialPoints(
      String userId, String type, int points) async {
    final pointsRef = _firestore.collection('social_points').doc(userId);
    final userRef = _firestore.collection('users').doc(userId);

    await _firestore.runTransaction((tx) async {
      // 1. تحديث مستوى النجوم الاجتماعي (تراكمية لا تنقص)
      final snap = await tx.get(pointsRef);
      int currentTotal =
          (snap.data()?['totalStars'] ?? snap.data()?['totalPoints'] ?? 0)
              .toInt();
      Map<String, int> pointsByType =
          Map<String, int>.from(snap.data()?['pointsByType'] ?? {});

      pointsByType[type] = (pointsByType[type] ?? 0) + points;
      int newTotal = currentTotal + points;

      // حساب المستوى الجديد (مثلاً كل 500 نجمة مستوى)
      int newLevel = (newTotal / 500).floor() + 1;

      tx.set(
          pointsRef,
          {
            'totalStars': newTotal,
            'totalPoints': newTotal, // Legacy sync
            'level': newLevel,
            'pointsByType': pointsByType,
            'lastUpdated': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));

      // 2. تحديث رصيد النجوم الودية ⭐ (قابل للتحويل لنجوم ملكية ⭐)
      tx.update(userRef, {
        'agentData.friendlyStars': FieldValue.increment(points),
        'agentData.friendlyPoints': FieldValue.increment(points), // Legacy sync
        'socialLevel': newLevel, // مزامنة المستوى في وثيقة المستخدم أيضاً
      });

      // تسجيل لوج العملية
      final logRef = userRef.collection('friendly_logs').doc();
      tx.set(logRef, {
        'type': type,
        'points': points,
        'timestamp': FieldValue.serverTimestamp(),
        'action': _getActionName(type),
      });
    });
  }

  static String _getActionName(String type) {
    switch (type) {
      case 'follow_given':
        return 'منح متابعة ⭐';
      case 'follow_received':
        return 'تلقي متابعة ⭐';
      case 'like_given':
        return 'منح إعجاب ⭐';
      case 'like_received':
        return 'تلقي إعجاب ⭐';
      case 'comment_given':
        return 'كتابة تعليق ⭐';
      case 'comment_received':
        return 'تلقي تعليق ⭐';
      case 'share_given':
        return 'مشاركة ملف ⭐';
      case 'share_received':
        return 'تمت مشاركة ملفك ⭐';
      case 'gift_sent':
        return 'إرسال هدية ⭐';
      case 'gift_received':
        return 'تلقي هدية ⭐';
      default:
        return 'نشاط اجتماعي ⭐';
    }
  }

  static Future<SocialPointsModel?> getSocialPoints(String userId) async {
    final snap = await _firestore.collection('social_points').doc(userId).get();
    if (!snap.exists) return null;
    return SocialPointsModel.fromFirestore(snap);
  }

  static Stream<SocialPointsModel?> streamSocialPoints(String userId) {
    return _firestore
        .collection('social_points')
        .doc(userId)
        .snapshots()
        .map((snap) {
      if (!snap.exists) return null;
      return SocialPointsModel.fromFirestore(snap);
    });
  }

  // ------------------------
  // Social Interactions (With Real Point Values)
  // ------------------------
  static Future<void> likeUser(String targetUid) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null || currentUid == targetUid) return;

    await addSocialPoints(currentUid, 'like_given', 2);
    await addSocialPoints(targetUid, 'like_received', 5);

    // ربط التحديات اليومية (تحدي الإعجابات)
    await ChallengesService.updateProgress(ChallengesService.typeLike);

    await sendNotification(
      targetUid: targetUid,
      title: 'إعجاب ملكي ❤️',
      body: 'شخص ما معجب ببروفايلك وتفاعلك!',
      type: 'like',
    );
  }

  static Future<void> commentOnUser(String targetUid, String comment) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null || currentUid == targetUid) return;

    await addSocialPoints(currentUid, 'comment_given', 5);
    await addSocialPoints(targetUid, 'comment_received', 8);

    await sendNotification(
      targetUid: targetUid,
      title: 'تعليق جديد 💬',
      body: 'ترك أحدهم تعليقاً لطيفاً على يومياتك.',
      type: 'comment',
    );
  }

  static Future<void> shareUser(String targetUid) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null || currentUid == targetUid) return;

    await addSocialPoints(currentUid, 'share_given', 10);
    await addSocialPoints(targetUid, 'share_received', 15);

    await sendNotification(
      targetUid: targetUid,
      title: 'مشاركة الملف 🔗',
      body: 'قام أحدهم بمشاركة بروفايلك مع أصدقائه!',
      type: 'share',
    );
  }
}
