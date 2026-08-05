import 'package:cloud_firestore/cloud_firestore.dart';

class CustomCarService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<Map<String, dynamic>?> getActiveCar(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (!doc.exists) return null;

      final data = doc.data();
      final activeCar = data?['activeCar'];
      
      if (activeCar != null) {
        return activeCar as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getAvailableVipCars(String userId) async {
    try {
      final snapshot = await _db.collection('vip_cars').get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getPurchasedCars(String userId) async {
    try {
      final snapshot = await _db.collection('users').doc(userId).collection('purchased_cars').get();
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> setCustomCar(String userId, String type, String url) async {
    try {
      await _db.collection('users').doc(userId).update({
        'activeCar': {
          'type': type,
          'url': url,
          'setAt': FieldValue.serverTimestamp(),
        }
      });
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> setPurchasedCar(String userId, String carId, String imageUrl, String? type) async {
    try {
      await _db.collection('users').doc(userId).update({
        'activeCar': {
          'id': carId,
          'imageUrl': imageUrl,
          'type': type ?? 'purchased',
          'setAt': FieldValue.serverTimestamp(),
        }
      });
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> removeCustomCar(String userId) async {
    try {
      await _db.collection('users').doc(userId).update({
        'activeCar': FieldValue.delete(),
      });
    } catch (e) {
      rethrow;
    }
  }
}
