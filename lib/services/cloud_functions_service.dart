import 'package:cloud_functions/cloud_functions.dart';

class CloudFunctionsService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// استلام مكافأة تسجيل الدخول اليومي
  Future<Map<String, dynamic>> claimDailyReward() async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('claimDailyReward');
      final response = await callable.call();
      return Map<String, dynamic>.from(response.data);
    } on FirebaseFunctionsException catch (e) {
      return {'success': false, 'error': e.message};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// دالة لإضافة كوينز للمستخدم عبر السيرفر (أكثر أماناً)
  Future<bool> addCoins(String uid, int amount) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('updateUserCoins');
      final response = await callable.call({
        'uid': uid,
        'amount': amount,
      });
      return response.data['success'] ?? false;
    } catch (e) {
      print('خطأ في استدعاء الفنكشن (addCoins): $e');
      return false;
    }
  }

  /// دالة لإرسال إشعار لمستخدم معين عبر السيرفر
  Future<void> sendNotification(String targetUid, String title, String body) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('sendPushNotification');
      await callable.call({
        'targetUid': targetUid,
        'title': title,
        'body': body,
      });
    } catch (e) {
      print('خطأ في إرسال الإشعار: $e');
    }
  }

  /// دالة للتحقق من عمليات الشراء (In-App Purchases)
  Future<bool> verifyPurchase(String purchaseToken) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('verifySubscription');
      final response = await callable.call({'token': purchaseToken});
      return response.data['valid'] ?? false;
    } catch (e) {
      print('خطأ في التحقق من الشراء: $e');
      return false;
    }
  }
}
