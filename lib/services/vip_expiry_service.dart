import 'package:cloud_firestore/cloud_firestore.dart';

class VIPExpiryService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> scheduleExpiryCheck() async {
    try {
      // Check for expired VIP subscriptions
      final snapshot = await _db
          .collection('users')
          .where('vipExpiryDate', isLessThan: DateTime.now())
          .where('isVIP', isEqualTo: true)
          .get();

      for (var doc in snapshot.docs) {
        await _db.collection('users').doc(doc.id).update({
          'isVIP': false,
          'vipExpiredAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      // Handle error
    }
  }
}
