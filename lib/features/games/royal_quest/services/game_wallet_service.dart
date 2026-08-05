import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GameWalletService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// جلب رصيد الجواهر
  Future<int> getGemsBalance() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      debugPrint('User not logged in, returning 0 gems');
      return 0;
    }

    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final gems = (data['gems'] ?? 0).toInt();
        debugPrint('User gems balance: $gems');
        return gems;
      } else {
        debugPrint('User document does not exist');
      }
    } catch (e) {
      debugPrint('Error getting gems balance: $e');
    }
    return 0;
  }

  /// جلب رصيد الكوينز
  Future<int> getCoinsBalance() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      debugPrint('User not logged in, returning 0 coins');
      return 0;
    }

    try {
      final doc = await _db.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final coins = (data['coins'] ?? 0).toInt();
        debugPrint('User coins balance: $coins');
        return coins;
      } else {
        debugPrint('User document does not exist');
      }
    } catch (e) {
      debugPrint('Error getting coins balance: $e');
    }
    return 0;
  }

  /// خصم من الجواهر
  Future<bool> deductGems(int amount) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    try {
      final userRef = _db.collection('users').doc(userId);
      
      await _db.runTransaction((transaction) async {
        final userSnap = await transaction.get(userRef);
        if (!userSnap.exists) return;

        final data = userSnap.data() as Map<String, dynamic>;
        final currentGems = (data['gems'] ?? 0).toInt();

        if (currentGems < amount) {
          throw Exception('Insufficient gems');
        }

        transaction.update(userRef, {
          'gems': currentGems - amount,
        });
      });
      
      return true;
    } catch (e) {
      debugPrint('Error deducting gems: $e');
      return false;
    }
  }

  /// خصم من الكوينز
  Future<bool> deductCoins(int amount) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    try {
      final userRef = _db.collection('users').doc(userId);
      
      await _db.runTransaction((transaction) async {
        final userSnap = await transaction.get(userRef);
        if (!userSnap.exists) return;

        final data = userSnap.data() as Map<String, dynamic>;
        final currentCoins = (data['coins'] ?? 0).toInt();

        if (currentCoins < amount) {
          throw Exception('Insufficient coins');
        }

        transaction.update(userRef, {
          'coins': currentCoins - amount,
        });
      });
      
      return true;
    } catch (e) {
      debugPrint('Error deducting coins: $e');
      return false;
    }
  }

  /// إضافة إلى الجواهر
  Future<bool> addGems(int amount) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    try {
      final userRef = _db.collection('users').doc(userId);
      
      await _db.runTransaction((transaction) async {
        final userSnap = await transaction.get(userRef);
        if (!userSnap.exists) return;

        final data = userSnap.data() as Map<String, dynamic>;
        final currentGems = (data['gems'] ?? 0).toInt();

        transaction.update(userRef, {
          'gems': currentGems + amount,
        });
      });
      
      return true;
    } catch (e) {
      debugPrint('Error adding gems: $e');
      return false;
    }
  }

  /// إضافة إلى الكوينز
  Future<bool> addCoins(int amount) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    try {
      final userRef = _db.collection('users').doc(userId);
      
      await _db.runTransaction((transaction) async {
        final userSnap = await transaction.get(userRef);
        if (!userSnap.exists) return;

        final data = userSnap.data() as Map<String, dynamic>;
        final currentCoins = (data['coins'] ?? 0).toInt();

        transaction.update(userRef, {
          'coins': currentCoins + amount,
        });
      });
      
      return true;
    } catch (e) {
      debugPrint('Error adding coins: $e');
      return false;
    }
  }

  /// تصفير الرصيد (عند الخسارة)
  Future<bool> resetBalance() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    try {
      await _db.collection('users').doc(userId).update({
        'gems': 0,
        'coins': 0,
      });
      return true;
    } catch (e) {
      debugPrint('Error resetting balance: $e');
      return false;
    }
  }
}
