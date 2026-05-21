import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/wallet_model.dart';

class WalletService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// جلب محفظة المستخدم
  Future<Wallet?> getWallet(String walletType) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return null;

    try {
      final doc = await _db
          .collection('users')
          .doc(userId)
          .collection('wallets')
          .doc(walletType)
          .get();

      if (doc.exists) {
        return Wallet.fromMap(doc.data()!, doc.id);
      } else {
        // إنشاء محفظة جديدة
        return await _createWallet(userId, walletType);
      }
    } catch (e) {
      print('Error getting wallet: $e');
      return null;
    }
  }

  /// إنشاء محفظة جديدة
  Future<Wallet> _createWallet(String userId, String walletType) async {
    final wallet = Wallet(
      id: walletType,
      userId: userId,
      type: walletType,
      balance:
          (walletType == 'stars' || walletType == 'coins') ? 10000 : (walletType == 'gems' ? 5000 : 2000),
      lastUpdated: DateTime.now(),
    );

    await _db
        .collection('users')
        .doc(userId)
        .collection('wallets')
        .doc(walletType)
        .set(wallet.toMap());

    return wallet;
  }

  /// تحديث الرصيد بعد الصفقة
  Future<void> updateWalletAfterTrade({
    required String walletType,
    required double profitLoss,
    required bool isWin,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    final walletRef = _db
        .collection('users')
        .doc(userId)
        .collection('wallets')
        .doc(walletType);

    await _db.runTransaction((transaction) async {
      final walletSnap = await transaction.get(walletRef);
      if (!walletSnap.exists) return;

      final data = walletSnap.data() as Map<String, dynamic>;

      double parseDouble(dynamic value) {
        if (value == null) return 0.0;
        if (value is num) return value.toDouble();
        if (value is String) return double.tryParse(value) ?? 0.0;
        return 0.0;
      }

      int parseInt(dynamic value) {
        if (value == null) return 0;
        if (value is num) return value.toInt();
        if (value is String) return int.tryParse(value) ?? 0;
        return 0;
      }

      final currentBalance = parseDouble(data['balance']);
      final totalReward = parseDouble(data['totalReward'] ?? data['total_reward']);
      final totalTrades = parseInt(data['totalTrades']);
      final wins = parseInt(data['wins']);

      transaction.update(walletRef, {
        'balance': currentBalance + profitLoss,
        'totalReward': totalReward + profitLoss,
        'total_reward': totalReward + profitLoss,
        'totalTrades': totalTrades + 1,
        'wins': isWin ? wins + 1 : wins,
        'lastUpdated': Timestamp.now(),
      });
    });
  }

  /// حفظ سجل الصفقة
  Future<void> saveTrade(Trade trade) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _db
        .collection('users')
        .doc(userId)
        .collection('trades')
        .add(trade.toMap());
  }

  /// جلب سجل الصفقات
  Stream<List<Trade>> getTradeHistory(String walletType) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return Stream.value([]);

    return _db
        .collection('users')
        .doc(userId)
        .collection('trades')
        .where('walletId', isEqualTo: walletType)
        .orderBy('openTime', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Trade.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// جلب جميع محافظ المستخدم
  Future<List<Wallet>> getAllWallets() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    try {
      final snapshot =
          await _db.collection('users').doc(userId).collection('wallets').get();

      return snapshot.docs
          .map((doc) => Wallet.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting all wallets: $e');
      return [];
    }
  }
}
