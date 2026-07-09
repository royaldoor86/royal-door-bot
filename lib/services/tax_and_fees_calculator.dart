import '../constants/rewards_constants.dart';

/// فئة مساعدة لحساب الرسوم والمساهمات
class TaxAndFeesCalculator {
  /// حساب الضريبة على المبلغ (0% - تم إيقافها)
  static double calculateTransferTax(double amount) {
    return 0.0;
  }

  /// حساب صافي المبلغ بعد الضريبة
  static double calculateNetAmount(double amount) {
    return amount;
  }

  /// حساب رسوم التحويل (5% من المبلغ المرسل)
  static double calculateGlobalSupportContribution(double amount) {
    return amount * 0.05;
  }

  /// حساب إجمالي الخصومات
  static double calculateTotalDeductions(double amount) {
    return calculateGlobalSupportContribution(amount);
  }

  /// حساب صافي المبلغ بعد جميع الخصومات
  static double calculateFinalNetAmount(double amount) {
    return amount - calculateTotalDeductions(amount);
  }

  /// حساب رسم تفعيل الباقة (تم تقليله من 5000 إلى 1000)
  static double getPackageActivationFee() {
    return RewardsConstants.packageActivationCost;
  }

  /// التحقق من صلاحية المبلغ للتحويل
  static bool isValidTransferAmount(double amount) {
    return amount >= RewardsConstants.minRedemptionAmount &&
        amount <= RewardsConstants.maxDailyRedemption;
  }

  /// التحقق من صلاحية المبلغ الشهري
  static bool isValidMonthlyAmount(double totalTransferred) {
    return totalTransferred <= RewardsConstants.maxMonthlyRedemption;
  }

  /// حساب الحد الأقصى للتحويل اليومي المتبقي
  static double getRemainingSailyLimit(double alreadyTransferred) {
    return RewardsConstants.maxDailyRedemption - alreadyTransferred;
  }

  /// حساب الحد الأقصى للتحويل الشهري المتبقي
  static double getRemainingMonthlyLimit(double alreadyTransferred) {
    return RewardsConstants.maxMonthlyRedemption - alreadyTransferred;
  }

  /// حساب نسبة الضريبة الفعلية
  static String getTaxRatePercentage() {
    return '0%';
  }

  /// حساب نسبة المساهمة الفعلية
  static String getContributionRatePercentage() {
    return '5%';
  }

  /// طباعة تقرير الخصومات
  static Map<String, double> getDeductionReport(double amount) {
    return {
      'original': amount,
      'tax': 0.0,
      'global_support': calculateGlobalSupportContribution(amount),
      'total_deductions': calculateTotalDeductions(amount),
      'net_amount': calculateFinalNetAmount(amount),
    };
  }

  /// حساب تكلفة الشراء
  static Map<String, double> getPurchaseCostBreakdown(double baseCost) {
    return {
      'base_cost': baseCost,
      'tax': 0.0,
      'global_support': 0.0,
      'total_cost': baseCost,
    };
  }
}
