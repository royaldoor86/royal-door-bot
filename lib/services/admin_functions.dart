import 'package:cloud_functions/cloud_functions.dart';

class AdminFunctions {
  static final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');

  /// 🔴 حظر مستخدم
  static Future<void> banUser({
    required String uid,
    String? reason,
  }) async {
    final callable = _functions.httpsCallable('adminBanUser');

    await callable.call({
      'uid': uid,
      'reason': reason ?? 'بدون سبب',
    });
  }

  /// 🟢 فك حظر مستخدم
  static Future<void> unbanUser({
    required String uid,
  }) async {
    final callable = _functions.httpsCallable('adminUnbanUser');

    await callable.call({
      'uid': uid,
    });
  }
}
