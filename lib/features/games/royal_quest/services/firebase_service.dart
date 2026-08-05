import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _balanceKey = 'user_balance';
  static const String _gemsKey = 'user_gems';
  static const String _coinsKey = 'user_coins';

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream for auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Initialize Firebase and check for existing session
  Future<void> initialize() async {
    await _auth.setPersistence(Persistence.LOCAL);
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'email': email,
        'gems': 5000,
        'coins': 10000,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      return credential;
    } catch (e) {
      throw Exception('Failed to register: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get user balance from Firestore
  Future<Map<String, int>> getUserBalance() async {
    if (currentUser == null) {
      // Return local balance if not authenticated
      return await _getLocalBalance();
    }

    try {
      final doc = await _firestore.collection('users').doc(currentUser!.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final gems = data['gems'] as int? ?? 5000;
        final coins = data['coins'] as int? ?? 10000;
        
        // Save to local storage for offline use
        await _saveLocalBalance(gems, coins);
        
        return {'gems': gems, 'coins': coins};
      }
    } catch (e) {
      print('Error fetching balance from Firestore: $e');
    }

    // Return local balance as fallback
    return await _getLocalBalance();
  }

  // Update user balance in Firestore
  Future<void> updateUserBalance({
    required int gems,
    required int coins,
  }) async {
    if (currentUser == null) {
      // Save to local storage if not authenticated
      await _saveLocalBalance(gems, coins);
      return;
    }

    try {
      await _firestore.collection('users').doc(currentUser!.uid).update({
        'gems': gems,
        'coins': coins,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Also save to local storage for offline use
      await _saveLocalBalance(gems, coins);
    } catch (e) {
      print('Error updating balance in Firestore: $e');
      // Save to local storage as fallback
      await _saveLocalBalance(gems, coins);
    }
  }

  // Deduct gems from balance
  Future<void> deductGems(int amount) async {
    final balance = await getUserBalance();
    final newGems = balance['gems']! - amount;
    await updateUserBalance(gems: newGems, coins: balance['coins']!);
  }

  // Deduct coins from balance
  Future<void> deductCoins(int amount) async {
    final balance = await getUserBalance();
    final newCoins = balance['coins']! - amount;
    await updateUserBalance(gems: balance['gems']!, coins: newCoins);
  }

  // Add gems to balance
  Future<void> addGems(int amount) async {
    final balance = await getUserBalance();
    final newGems = balance['gems']! + amount;
    await updateUserBalance(gems: newGems, coins: balance['coins']!);
  }

  // Add coins to balance
  Future<void> addCoins(int amount) async {
    final balance = await getUserBalance();
    final newCoins = balance['coins']! + amount;
    await updateUserBalance(gems: balance['gems']!, coins: newCoins);
  }

  // Reset balance to zero (on game over)
  Future<void> resetBalance() async {
    await updateUserBalance(gems: 0, coins: 0);
  }

  // Save balance to local storage
  Future<void> _saveLocalBalance(int gems, int coins) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_gemsKey, gems);
    await prefs.setInt(_coinsKey, coins);
  }

  // Get balance from local storage
  Future<Map<String, int>> _getLocalBalance() async {
    final prefs = await SharedPreferences.getInstance();
    final gems = prefs.getInt(_gemsKey) ?? 5000;
    final coins = prefs.getInt(_coinsKey) ?? 10000;
    return {'gems': gems, 'coins': coins};
  }

  // Stream for real-time balance updates
  Stream<Map<String, int>> balanceStream() {
    if (currentUser == null) {
      return Stream.value({'gems': 5000, 'coins': 10000});
    }

    return _firestore
        .collection('users')
        .doc(currentUser!.uid)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        final gems = data['gems'] as int? ?? 5000;
        final coins = data['coins'] as int? ?? 10000;
        return {'gems': gems, 'coins': coins};
      }
      return {'gems': 5000, 'coins': 10000};
    });
  }

  // Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  // Get user ID
  String? get userId => currentUser?.uid;
}
