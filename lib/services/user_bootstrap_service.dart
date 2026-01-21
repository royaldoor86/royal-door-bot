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

  static Future<void> _createUserIfNotExists(String uid, String? name, String? email) async {
    final ref = _firestore.collection('users').doc(uid);
    final doc = await ref.get();

    if (!doc.exists) {
      // تم التعديل: لا نقوم بتصفير البيانات إذا كان التسجيل قد أنشأ المستند بالفعل
      final randomRoyalId = (10000000 + Random().nextInt(90000000)).toString();
      
      await ref.set({
        'uid': uid,
        'royalId': randomRoyalId,
        'name': name ?? 'مستخدم ملكي جديد',
        'email': email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'gems': 0,
        'coins': 0,
        'userLevel': 1,
        'accountLevel': 1,
        'friends': [],
        'following': [],
        'followers': [],
        'agentData': {
          'friendlyPoints': 0,
          'invitedCount': 0,
          'referralEarnings': 0,
        }
      }, SetOptions(merge: true)); // استخدام merge لضمان عدم مسح البيانات الموجودة
    } else {
      // تحديث البيانات المفقودة فقط للمستخدمين القدامى
      Map<String, dynamic> updates = {};
      if (doc.data()?['royalId'] == null) {
        updates['royalId'] = (10000000 + Random().nextInt(90000000)).toString();
      }
      if (doc.data()?['agentData'] == null) {
        updates['agentData'] = {
          'friendlyPoints': 0,
          'invitedCount': 0,
          'referralEarnings': 0,
        };
      }
      if (updates.isNotEmpty) await ref.update(updates);
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
