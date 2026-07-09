import 'package:cloud_firestore/cloud_firestore.dart';

class Wallet {
  final String id;
  final String userId;
  final String type; // coins, gems, royalPoints
  double balance;
  double totalReward;
  int totalTrades;
  int wins;
  DateTime lastUpdated;

  Wallet({
    required this.id,
    required this.userId,
    required this.type,
    required this.balance,
    this.totalReward = 0,
    this.totalTrades = 0,
    this.wins = 0,
    required this.lastUpdated,
  });

  double get winRate => totalTrades > 0 ? (wins / totalTrades) * 100 : 0;

  factory Wallet.fromMap(Map<String, dynamic> data, String docId) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return Wallet(
      id: docId,
      userId: data['userId'] ?? '',
      type: data['type'] ?? 'currency',
      balance: parseDouble(data['balance']),
      totalReward: parseDouble(data['totalReward'] ?? data['total_reward']),
      totalTrades: (data['totalTrades'] ?? 0).toInt(),
      wins: (data['wins'] ?? 0).toInt(),
      lastUpdated: data['lastUpdated'] != null
          ? (data['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'type': type,
        'balance': balance,
        'totalReward': totalReward,
        'totalTrades': totalTrades,
        'wins': wins,
        'lastUpdated': Timestamp.fromDate(lastUpdated),
      };
}

class Trade {
  final String id;
  final String walletId;
  final String tradeType; // BUY or SELL
  final double entryPrice;
  double? exitPrice;
  final double amount;
  final int durationSeconds;
  final DateTime openTime;
  DateTime? closeTime;
  bool? isWin;
  double? reward;
  String status; // open, closed, cancelled

  Trade({
    required this.id,
    required this.walletId,
    required this.tradeType,
    required this.entryPrice,
    required this.amount,
    required this.durationSeconds,
    required this.openTime,
    this.exitPrice,
    this.closeTime,
    this.isWin,
    this.reward,
    this.status = 'open',
  });

  factory Trade.fromMap(Map<String, dynamic> data, String docId) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return Trade(
      id: docId,
      walletId: data['walletId'] ?? '',
      tradeType: data['tradeType'] ?? 'BUY',
      entryPrice: parseDouble(data['entryPrice']),
      amount: parseDouble(data['amount']),
      durationSeconds: (data['durationSeconds'] ?? 5).toInt(),
      openTime: data['openTime'] != null
          ? (data['openTime'] as Timestamp).toDate()
          : DateTime.now(),
      exitPrice: data['exitPrice'] != null ? parseDouble(data['exitPrice']) : null,
      closeTime: data['closeTime'] != null
          ? (data['closeTime'] as Timestamp).toDate()
          : null,
      isWin: data['isWin'],
      reward: data['reward'] != null ? parseDouble(data['reward']) : (data['reward_amount'] != null ? parseDouble(data['reward_amount']) : null),
      status: data['status'] ?? 'open',
    );
  }

  Map<String, dynamic> toMap() => {
        'walletId': walletId,
        'tradeType': tradeType,
        'entryPrice': entryPrice,
        'amount': amount,
        'durationSeconds': durationSeconds,
        'openTime': Timestamp.fromDate(openTime),
        'exitPrice': exitPrice,
        'closeTime': closeTime != null ? Timestamp.fromDate(closeTime!) : null,
        'isWin': isWin,
        'reward': reward,
        'status': status,
      };
}
