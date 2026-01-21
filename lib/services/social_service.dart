import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SocialService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  // ------------------------
  // Followers & Following (Layer 2 - Social Initializer)
  // ------------------------
  static Future<void> followUser(String targetUid) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null || currentUid == targetUid) return;

    final batch = _firestore.batch();

    // 1. تحديث قائمة المتابعين للشخص المستهدف (followers/{targetUid})
    final followerRef = _firestore.collection('followers').doc(targetUid);
    batch.set(followerRef, {
      'count': FieldValue.increment(1),
      'lastFollower': currentUid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // إضافة الشخص لقائمة المتابعين التفصيلية
    final followerItemRef = followerRef.collection('items').doc(currentUid);
    batch.set(followerItemRef, {
      'uid': currentUid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 2. تحديث قائمة المتابعة للشخص الحالي (follows/{currentUid})
    final followRef = _firestore.collection('follows').doc(currentUid);
    batch.set(followRef, {
      'count': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // إضافة الشخص لقائمة المتابعة التفصيلية
    final followItemRef = followRef.collection('items').doc(targetUid);
    batch.set(followItemRef, {
      'uid': targetUid,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 3. تحديث مصفوفات اليوزر (للتوافق مع الكود القديم إن وجد)
    batch.update(_firestore.collection('users').doc(currentUid), {
      'following': FieldValue.arrayUnion([targetUid])
    });
    batch.update(_firestore.collection('users').doc(targetUid), {
      'followers': FieldValue.arrayUnion([currentUid])
    });

    await batch.commit();
  }

  // ------------------------
  // Notifications (Initializers)
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
}
