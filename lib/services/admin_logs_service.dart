// Service: سجل العمليات الإدارية
// Collection: admin_logs
// Cloud Function: logAdminAction
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminLogsService {
  static final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// تسجيل عملية إدارية (Admin)
  static Future<Map<String, dynamic>> logAdminAction(
      Map<String, dynamic> data) async {
    final callable = _functions.httpsCallable('logAdminAction');
    final result = await callable.call(data);
    return Map<String, dynamic>.from(result.data);
  }

  /// جلب سجل العمليات من Firestore
  static Stream<QuerySnapshot<Map<String, dynamic>>> adminLogsStream() {
    return _firestore
        .collection('admin_logs')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
