// Service: إدارة النقاط والخبرة
// Cloud Function: updateUserPointsXP
import 'package:cloud_functions/cloud_functions.dart';

class PointsXPService {
  static final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  /// تحديث نقاط/خبرة المستخدم (Admin/System)
  static Future<Map<String, dynamic>> updateUserPointsXP(
      Map<String, dynamic> data) async {
    final callable = _functions.httpsCallable('updateUserPointsXP');
    final result = await callable.call(data);
    return Map<String, dynamic>.from(result.data);
  }
}
