import 'package:cloud_firestore/cloud_firestore.dart';

class AntiKickService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<bool> canKickUser(String targetUserId, String currentUserId) async {
    try {
      // Check if target user has anti-kick protection
      final targetDoc = await _db.collection('users').doc(targetUserId).get();
      if (!targetDoc.exists) return true;

      final data = targetDoc.data();
      final hasAntiKick = data?['hasAntiKick'] ?? false;
      
      // Admins can always kick
      final currentDoc = await _db.collection('users').doc(currentUserId).get();
      if (!currentDoc.exists) return true;

      final currentData = currentDoc.data();
      final isAdmin = currentData?['isAdmin'] ?? false;
      
      if (isAdmin) return true;
      
      return !hasAntiKick;
    } catch (e) {
      return true; // Allow kick on error
    }
  }

  static Future<void> logKickAttempt(String targetUserId, String currentUserId, bool success) async {
    try {
      await _db.collection('kick_logs').add({
        'targetUserId': targetUserId,
        'currentUserId': currentUserId,
        'success': success,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Ignore logging errors
    }
  }
}
