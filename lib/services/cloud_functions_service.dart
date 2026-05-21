import 'package:cloud_functions/cloud_functions.dart';

class CloudFunctionsService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// استلام مكافأة تسجيل الدخول اليومي
  Future<Map<String, dynamic>> claimDailyReward() async {
    try {
      final HttpsCallable callable =
          _functions.httpsCallable('claimDailyReward');
      final response = await callable.call();
      return Map<String, dynamic>.from(response.data);
    } on FirebaseFunctionsException catch (e) {
      return {'success': false, 'error': e.message};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// دالة لإضافة نجوم ⭐ للمستخدم عبر السيرفر (أكثر أماناً)
  Future<bool> addStars(String uid, int amount) async {
    try {
      final HttpsCallable callable =
          _functions.httpsCallable('updateUserStars');
      final response = await callable.call({
        'uid': uid,
        'amount': amount,
      });
      return response.data['success'] ?? false;
    } catch (e) {
      print('خطأ في استدعاء الفنكشن (addStars): $e');
      return false;
    }
  }

  /// دالة لإرسال إشعار لمستخدم معين عبر السيرفر
  Future<void> sendNotification({
    required String targetUid,
    required String title,
    required String body,
    String type = 'general',
    Map<String, String>? additionalData,
  }) async {
    try {
      final HttpsCallable callable =
          _functions.httpsCallable('sendPushNotification');
      await callable.call({
        'targetUid': targetUid,
        'title': title,
        'body': body,
        'type': type,
        'additionalData': additionalData,
      });
    } catch (e) {
      print('خطأ في إرسال الإشعار: $e');
    }
  }

  /// دالة للتحقق من عمليات الشراء (In-App Purchases)
  Future<bool> verifyPurchase(String purchaseToken) async {
    try {
      final HttpsCallable callable =
          _functions.httpsCallable('verifySubscription');
      final response = await callable.call({'token': purchaseToken});
      return response.data['valid'] ?? false;
    } catch (e) {
      print('خطأ في التحقق من الشراء: $e');
      return false;
    }
  }
}
