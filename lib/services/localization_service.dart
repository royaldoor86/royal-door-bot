// Service: إدارة النصوص واللغات
// Collection: app_texts
// Cloud Function: manageAppText
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocalizationService {
  static final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// إضافة/تعديل/حذف نص (Admin)
  static Future<Map<String, dynamic>> manageAppText(
      Map<String, dynamic> data) async {
    final callable = _functions.httpsCallable('manageAppText');
    final result = await callable.call(data);
    return Map<String, dynamic>.from(result.data);
  }

  /// جلب النصوص من Firestore
  static Stream<QuerySnapshot<Map<String, dynamic>>> appTextsStream(
      String lang) {
    return _firestore
        .collection('app_texts')
        .doc(lang)
        .collection('items')
        .snapshots();
  }
}
