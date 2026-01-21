import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DailyLoginService {
  static final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// استدعاء Cloud Function لمكافأة تسجيل الدخول اليومي
  static Future<Map<String, dynamic>> claimDailyLogin() async {
    final callable = _functions.httpsCallable('claimDailyLogin');
    final result = await callable.call();
    return Map<String, dynamic>.from(result.data);
  }

  /// مراقبة بيانات streak والكوينز والرصيد والمستوى (ريل تايم)
  static Stream<DocumentSnapshot<Map<String, dynamic>>> userStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }
}
