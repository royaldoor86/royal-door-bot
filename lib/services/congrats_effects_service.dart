// Service: إدارة التهاني والمؤثرات
// Collection: congrats_templates
// Cloud Function: manageCongratsEffect
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CongratsEffectsService {
  static final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// إضافة/تعديل/حذف تهنئة أو مؤثر (Admin)
  static Future<Map<String, dynamic>> manageCongratsEffect(
      Map<String, dynamic> data) async {
    final callable = _functions.httpsCallable('manageCongratsEffect');
    final result = await callable.call(data);
    return Map<String, dynamic>.from(result.data);
  }

  /// جلب التهاني/المؤثرات من Firestore
  static Stream<QuerySnapshot<Map<String, dynamic>>> congratsTemplatesStream() {
    return _firestore.collection('congrats_templates').snapshots();
  }
}
