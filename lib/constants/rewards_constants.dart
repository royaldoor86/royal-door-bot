/// ثوابت نظام المكافآت الملكية
class RewardsConstants {
  // أنواع العملات
  static const String currencyGems = 'gems';
  static const String currencyStars = 'stars';
  static const String currencyRoyalPoints = 'royal_points';

  // أسماء الحقول في Firestore (المحفظة)
  static const String walletGemsField = 'rewards_wallet_gems';
  static const String walletStarsField = 'rewards_wallet_stars';
  static const String walletPointsField = 'rewards_wallet_points';

  // مفاتيح الإعدادات (Config Keys)
  static const String configExchangeRate = 'exchange_rate';
  static const String configMinRedemption = 'min_redemption_amount';
  static const String configIsMaintenance = 'is_maintenance';
  static const String configTransferFee = 'transfer_fee';

  // أسماء مجموعات Firestore
  static const String collectionActiveRewards = 'active_rewards';
  static const String collectionCompletedRewards = 'completed_rewards';
  static const String collectionRedemptions = 'reward_redemptions';
  static const String collectionStats = 'reward_stats';
  static const String collectionTransfers = 'reward_transfers';
  static const String collectionPackages = 'reward_packages';
  static const String collectionConfig = 'reward_config';
  static const String collectionSettings = 'settings';
  static const String collectionAuditLogs = 'audit_logs';
  static const String collectionOtpStorage = 'otp_storage';
  static const String collectionRateLimits = 'rate_limits';
  static const String collectionLeaderboard = 'reward_leaderboard';
  static const String collectionAchievements = 'user_achievements';

  // أسماء الحقول المشتركة
  static const String fieldTitle = 'title';
  static const String fieldCost = 'cost';
  static const String fieldDurationDays = 'days';
  static const String fieldTotalReward = 'total_reward';
  static const String fieldDailyReward = 'daily_reward';
  static const String fieldCollectedReward = 'collected_reward';
  static const String fieldRewardAmount = 'reward_amount';
  static const String fieldHarvestAmount =
      fieldRewardAmount; // alias for compatibility
  static const String fieldStatus = 'status';
  static const String fieldUserId = 'userId';
  static const String fieldCreatedAt = 'created_at';
  static const String fieldUpdatedAt = 'updated_at';

  // حدود العمليات
  static const double maxDailyRedemption = 500000.0;
  static const double maxMonthlyRedemption = 5000000.0;
  static const double minRedemptionAmount = 10000.0;

  // معايير OTP
  static const int otpLength = 6;
  static const Duration otpExpiry = Duration(minutes: 10);
  static const int maxOtpAttempts = 5;

  // Rate Limiting
  static const int maxDailyRequests = 10;
  static const int maxHourlyRequests = 3;
  static const int maxConcurrentRequests = 1;
  static const Duration rateLimitWindow = Duration(hours: 1);
  static const int rateLimitMaxRequests = 5;

  // Encryption
  static const String encryptionKey = 'royal_rewards_encryption_key_v2';
  static const int keyLength = 32;
  static const int ivLength = 16;

  // Audit Log
  static const String auditActionUserLogin = 'user_login';
  static const String auditActionUserLogout = 'user_logout';
  static const String auditActionOtpSent = 'otp_sent';
  static const String auditActionOtpVerified = 'otp_verified';
  static const String auditActionOtpFailed = 'otp_verification_failed';
  static const String auditActionRedemptionRequest = 'redemption_request';
  static const String auditActionRedemptionApproved = 'redemption_approved';
  static const String auditActionRedemptionRejected = 'redemption_rejected';
  static const String auditActionRateLimitExceeded = 'rate_limit_exceeded';
  static const String auditActionEncryptionError = 'encryption_error';
  static const int auditLogMaxEntries = 10000;

  // ثوابت الإشعارات
  static const bool enablePushNotifications = true;
  static const bool enableEmailNotifications = true;
  static const bool enableInAppNotifications = true;
  static const Duration notificationTimeout = Duration(seconds: 30);

  // ثوابت التقارير
  static const int reportGenerationDayOfMonth = 1; // أول يوم من الشهر
  static const bool enableMonthlyReports = true;
  static const bool enableYearlyComparison = true;

  // ثوابت سياسة المكافآت
  static const int rewardDurationDays = 30;
  static const double missingDayPenalty =
      0.0; // لا يوجد تعويض، يتم الخصم من الباقة
  static const bool autoDistributeRewards = false; // لا يوجد توزيع تلقائي
  static const Duration rewardClaimWindow = Duration(hours: 24);

  // ثوابت صندوق التفعيل
  static const double activationBoxMinimumSize =
      5000.0; // الحد الأدنى لصندوق التفعيل
  static const double activationBoxMaximumSize =
      50000.0; // الحد الأقصى لصندوق التفعيل
  static const double packageActivationCost =
      1000.0; // تكلفة تفعيل الباقة (تقليل من 5000)
  static const int auditLogRetention = 90; // days

  // Error Messages
  static const String errorOtpInvalid = 'رمز التحقق غير صحيح';
  static const String errorOtpExpired = 'انتهت صلاحية رمز التحقق';
  static const String errorOtpMaxAttempts = 'تم تجاوز محاولات التحقق';
  static const String errorRateLimitExceeded = 'تم تجاوز حد الطلبات المسموح';
  static const String errorEncryptionFailed = 'فشل في تشفير البيانات';
  static const String errorDecryptionFailed = 'فشل في فك تشفير البيانات';
  static const String errorAuditLogFailed = 'فشل في تسجيل العملية';

  // Maintenance Mode
  static const String maintenanceModeKey = 'reward_maintenance_mode';
  static const String maintenanceReasonKey = 'reward_maintenance_reason';
  static const String maintenanceEstimatedTimeKey =
      'reward_maintenance_estimated_time';
}
