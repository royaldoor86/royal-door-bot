import 'package:cloud_firestore/cloud_firestore.dart';

class PrivilegeService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<bool> hasPrivilege(String userId, String privilege) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (!doc.exists) return false;

      final data = doc.data();
      final privileges = data?['privileges'] as List<dynamic>?;
      
      return privileges?.contains(privilege) ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<List<String>> getActivePrivileges(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (!doc.exists) return [];

      final data = doc.data();
      final privileges = data?['privileges'] as List<dynamic>?;

      return privileges?.map((e) => e.toString()).toList() ?? [];
    } catch (e) {
      return [];
    }
  }

  static Future<void> grantPrivilege(String userId, String privilege) async {
    try {
      await _db.collection('users').doc(userId).update({
        'privileges': FieldValue.arrayUnion([privilege])
      });
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> revokePrivilege(String userId, String privilege) async {
    try {
      await _db.collection('users').doc(userId).update({
        'privileges': FieldValue.arrayRemove([privilege])
      });
    } catch (e) {
      rethrow;
    }
  }
}
