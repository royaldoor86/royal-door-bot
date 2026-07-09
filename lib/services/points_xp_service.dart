// Service: إدارة المستوى والخبرة
// Cloud Function: updateUserLevelXP
import 'package:cloud_functions/cloud_functions.dart';

class LevelXPService {
  static final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  /// تحديث مستوى/خبرة المستخدم (Admin/System)
  static Future<Map<String, dynamic>> updateUserLevelXP(
      Map<String, dynamic> data) async {
    final callable = _functions.httpsCallable('updateUserPointsXP');
    final result = await callable.call(data);
    return Map<String, dynamic>.from(result.data);
  }
}
