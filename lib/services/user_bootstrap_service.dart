import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class UserBootstrapService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static Future<void> bootstrapUser() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final uid = user.uid;

    await Future.wait([
      _createUserIfNotExists(uid, user.displayName, user.email),
      _createWalletIfNotExists(uid),
      _createSettingsIfNotExists(uid),
      _createFollowersIfNotExists(uid),
      _createFollowsIfNotExists(uid),
    ]);
  }

  static Future<void> _createUserIfNotExists(
      String uid, String? name, String? email) async {
    final ref = _firestore.collection('users').doc(uid);
    final doc = await ref.get();

    if (!doc.exists) {
      // إنشاء مستخدم جديد كلياً
      final randomRoyalId = (10000000 + Random().nextInt(90000000)).toString();

      await ref.set({
        'uid': uid,
        'royalId': randomRoyalId,
        'shortId': randomRoyalId, // مزامنة الحقلين منذ البداية
        'name': name ?? 'مستخدم ملكي جديد',
        'email': email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'gems': 0,
        'coins': 0,
        'userLevel': 1,
        'accountLevel': 1,
        'royalXP': 0,
        'friends': [],
        'following': [],
        'followers': [],
        'agentData': {
          'friendlyPoints': 0,
          'invitedCount': 0,
          'referralEarnings': 0,
        }
      }, SetOptions(merge: true));
    } else {
      // تحديث البيانات المفقودة فقط للمستخدمين الحاليين لضمان عدم تغير الـ ID
      final data = doc.data() ?? {};
      Map<String, dynamic> updates = {};

      // لا نقوم بتحديث royalId أو shortId إذا كان المستخدم موجوداً بالفعل
      // الآيدي يجب أن يتغير فقط عبر: منح يدوي، شراء، أو موافقة طلب

      if (data['agentData'] == null) {
        updates['agentData'] = {
          'friendlyPoints': 0,
          'invitedCount': 0,
          'referralEarnings': 0,
        };
      }

      if (updates.isNotEmpty) {
        await ref.update(updates);
      }
    }
  }

  static Future<void> _createWalletIfNotExists(String uid) async {
    final ref = _firestore.collection('wallets').doc(uid);
    final doc = await ref.get();
    if (!doc.exists) {
      await ref.set({
        'uid': uid,
        'balance': 0,
        'coins': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  static Future<void> _createSettingsIfNotExists(String uid) async {
    final ref = _firestore.collection('settings').doc(uid);
    final doc = await ref.get();
    if (!doc.exists) {
      await ref.set({
        'uid': uid,
        'language': 'ar',
        'notifications': true,
        'theme': 'dark',
      });
    }
  }

  static Future<void> _createFollowersIfNotExists(String uid) async {
    final ref = _firestore.collection('followers').doc(uid);
    final doc = await ref.get();
    if (!doc.exists) await ref.set({'uid': uid, 'count': 0});
  }

  static Future<void> _createFollowsIfNotExists(String uid) async {
    final ref = _firestore.collection('follows').doc(uid);
    final doc = await ref.get();
    if (!doc.exists) await ref.set({'uid': uid, 'count': 0});
  }
}
