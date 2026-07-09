import 'dart:async';
import 'dart:math';

class TradeEngine {
  final Random _random = Random();
  late Timer _priceTimer;
  late StreamController<double> _priceStreamController;

  double _currentPrice = 100.0;
  double _priceChangeRate = 0.0;
  int _winStreak = 0;

  Stream<double> get priceStream => _priceStreamController.stream;
  double get currentPrice => _currentPrice;
  int get winStreak => _winStreak;

  TradeEngine() {
    _priceStreamController = StreamController<double>.broadcast();
    _startPriceSimulation();
  }

  void _startPriceSimulation() {
    _priceTimer = Timer.periodic(const Duration(milliseconds: 400), (_) {
      _updatePrice();
    });
  }

  void _updatePrice() {
    // Random walk with trend
    double trend = 0.02;
    double volatility = ((_random.nextDouble() - 0.5) * 2) * 0.5;

    // Occasional spike
    if (_random.nextInt(20) == 0) {
      volatility += _random.nextBool() ? 1.5 : -1.5;
    }

    _priceChangeRate = trend + volatility;
    _currentPrice += _priceChangeRate;
    _currentPrice = _currentPrice.clamp(1, 999999);

    _priceStreamController.add(_currentPrice);
  }

  /// تحديد نتيجة الصفقة بناءً على استراتيجية ذكية
  Future<TradeResult> executeTradeV2({
    required bool isBuy,
    required double entryPrice,
    required int durationSeconds,
  }) async {
    await Future.delayed(Duration(seconds: durationSeconds));

    // حساب معدل الفوز الديناميكي
    double baseWinRate = 0.55;
    double streakBonus = (_winStreak >= 3) ? -0.15 : 0;
    double finalWinRate = (baseWinRate + streakBonus).clamp(0.35, 0.75);

    bool isWin = _random.nextDouble() < finalWinRate;

    // تحديث السعر بناءً على النتيجة
    if (isWin) {
      _currentPrice += isBuy ? 2.5 : -2.5;
      _winStreak++;
    } else {
      _currentPrice += isBuy ? -2.5 : 2.5;
      _winStreak = 0;
    }

    double exitPrice = _currentPrice;
    double rewardPercentage = isWin ? 0.85 : -1.0; // 85% لمكافأة، -100% للخسارة

    return TradeResult(
      isWin: isWin,
      entryPrice: entryPrice,
      exitPrice: exitPrice,
      rewardPercentage: rewardPercentage,
    );
  }

  void resetStreak() {
    _winStreak = 0;
  }

  void dispose() {
    _priceTimer.cancel();
    _priceStreamController.close();
  }
}

class TradeResult {
  final bool isWin;
  final double entryPrice;
  final double exitPrice;
  final double rewardPercentage;

  TradeResult({
    required this.isWin,
    required this.entryPrice,
    required this.exitPrice,
    required this.rewardPercentage,
  });

  double getReward(double amount) => amount * rewardPercentage;
}
