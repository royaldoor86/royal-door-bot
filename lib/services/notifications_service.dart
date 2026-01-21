// Service: إدارة الإشعارات (Push + سجل)
// ملاحظة: استقبال إشعارات FCM وعرضها محليًا يتم في main.dart عبر flutter_local_notifications.
// يمكن توسيع هذه الخدمة لاحقًا لمعالجة مخصصة أو منطق إضافي إذا لزم.
// Collection: notifications
// Cloud Function: sendPushNotification
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsService {
  static final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// إرسال إشعار Push Notification (Admin/System)
  static Future<Map<String, dynamic>> sendPushNotification(
      Map<String, dynamic> data) async {
    final callable = _functions.httpsCallable('sendPushNotification');
    final result = await callable.call(data);
    return Map<String, dynamic>.from(result.data);
  }

  /// جلب الإشعارات من Firestore
  static Stream<QuerySnapshot<Map<String, dynamic>>> notificationsStream(
      String uid) {
    if (uid.isEmpty) {
      // إرجاع Stream فارغ إذا لم يتم تحديد uid
      return const Stream.empty();
    }
    return _firestore
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .snapshots();
  }
}
