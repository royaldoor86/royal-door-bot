import 'package:cloud_firestore/cloud_firestore.dart';

class VIPPrivilegeService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<bool> hasRoyalEntryEffect(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (!doc.exists) return false;

      final data = doc.data();
      final isVIP = data?['isVIP'] ?? false;
      
      return isVIP;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> toggleVIPIncognito(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (!doc.exists) return false;

      final data = doc.data();
      final currentStatus = data?['vipIncognito'] ?? false;
      
      await _db.collection('users').doc(userId).update({
        'vipIncognito': !currentStatus,
      });
      
      return !currentStatus;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> activateVIPVerification(String userId) async {
    try {
      await _db.collection('users').doc(userId).update({
        'vipVerification': true,
        'vipVerificationAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> hasAnimatedFrame(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (!doc.exists) return false;

      final data = doc.data();
      return data?['vipAnimatedFrame'] ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> hasVIPKickProtection(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (!doc.exists) return false;

      final data = doc.data();
      return data?['vipKickProtection'] ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<double> getXPMultiplier(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (!doc.exists) return 1.0;

      final data = doc.data();
      return (data?['vipXPMultiplier'] ?? 1.0).toDouble();
    } catch (e) {
      return 1.0;
    }
  }

  static Future<bool> hasPrioritySupport(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (!doc.exists) return false;

      final data = doc.data();
      return data?['vipPrioritySupport'] ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<double> getStoreDiscount(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (!doc.exists) return 0.0;

      final data = doc.data();
      return (data?['vipStoreDiscount'] ?? 0.0).toDouble();
    } catch (e) {
      return 0.0;
    }
  }

  static Future<bool> sendVIPDailyGifts(String userId) async {
    try {
      await _db.collection('users').doc(userId).update({
        'vipDailyGiftsClaimed': FieldValue.increment(1),
        'vipLastGiftClaim': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> applyVIPPrivileges(String userId) async {
    try {
      await _db.collection('users').doc(userId).update({
        'isVIP': true,
        'vipActivatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> removeVIPPrivileges(String userId) async {
    try {
      await _db.collection('users').doc(userId).update({
        'isVIP': false,
      });
    } catch (e) {
      rethrow;
    }
  }
}
