// Service: إدارة الصلاحيات المتقدمة
// Cloud Function: updateUserRole
import 'package:cloud_functions/cloud_functions.dart';

class RolesPermissionsService {
  static final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  /// تعديل صلاحيات المستخدم (Admin/Owner)
  static Future<Map<String, dynamic>> updateUserRole(
      Map<String, dynamic> data) async {
    final callable = _functions.httpsCallable('updateUserRole');
    final result = await callable.call(data);
    return Map<String, dynamic>.from(result.data);
  }
}
