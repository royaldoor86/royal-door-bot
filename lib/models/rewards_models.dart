import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/rewards_constants.dart';

/// حالات المكافآت المختلفة
enum RewardsStatus { active, completed, redeemed, expired, cancelled }

/// نموذج المكافأة النشطة
class ActiveReward {
  final String id;
  final String userId;
  final String packageName;
  final double totalReward;
  final double dailyReward;
  final double rewardAmount;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime? lastRewardDate;
  final RewardsStatus status;
  final String paymentMethod; // 'gems' or 'stars'
  final Map<String, dynamic>? metadata;

  ActiveReward({
    required this.id,
    required this.userId,
    required this.packageName,
    required this.totalReward,
    required this.dailyReward,
    required this.rewardAmount,
    required this.startTime,
    required this.endTime,
    this.lastRewardDate,
    required this.status,
    required this.paymentMethod,
    this.metadata,
  });

  factory ActiveReward.fromMap(Map<String, dynamic> data, String id) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) {
        return double.tryParse(value.replaceAll('%', '')) ?? 0.0;
      }
      return 0.0;
    }

    return ActiveReward(
      id: id,
      userId: data[RewardsConstants.fieldUserId] ?? '',
      packageName: data['packageName'] ?? '',
      totalReward: parseDouble(
          data[RewardsConstants.fieldTotalReward] ?? data['total_reward']),
      dailyReward: parseDouble(
          data[RewardsConstants.fieldDailyReward] ?? data['daily_reward']),
      rewardAmount: parseDouble(
          data[RewardsConstants.fieldHarvestAmount] ?? data['reward_amount']),
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (data['endTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastRewardDate: (data['lastHarvestDate'] as Timestamp? ??
              data['lastRewardDate'] as Timestamp?)
          ?.toDate(),
      status: _parseStatus(data[RewardsConstants.fieldStatus] ?? true),
      paymentMethod: data['paymentMethod'] ?? RewardsConstants.currencyGems,
      metadata: data['metadata'],
    );
  }

  static RewardsStatus _parseStatus(dynamic status) {
    if (status is String) {
      switch (status.toLowerCase()) {
        case 'active':
          return RewardsStatus.active;
        case 'completed':
          return RewardsStatus.completed;
        case 'redeemed':
        case 'transferred':
          return RewardsStatus.redeemed;
        case 'expired':
          return RewardsStatus.expired;
        case 'cancelled':
          return RewardsStatus.cancelled;
        default:
          return RewardsStatus.active;
      }
    } else if (status is bool) {
      return status ? RewardsStatus.active : RewardsStatus.completed;
    }
    return RewardsStatus.active;
  }

  Map<String, dynamic> toMap() {
    return {
      RewardsConstants.fieldUserId: userId,
      'packageName': packageName,
      RewardsConstants.fieldTotalReward: totalReward,
      RewardsConstants.fieldDailyReward: dailyReward,
      RewardsConstants.fieldHarvestAmount: rewardAmount,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'lastRewardDate':
          lastRewardDate != null ? Timestamp.fromDate(lastRewardDate!) : null,
      RewardsConstants.fieldStatus: status.name,
      'paymentMethod': paymentMethod,
      'metadata': metadata,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  // حساب الأيام المتبقية
  int get remainingDays {
    final now = DateTime.now();
    if (now.isAfter(endTime)) return 0;
    return endTime.difference(now).inDays + 1;
  }

  // حساب الأيام المنقضية
  int get elapsedDays {
    final now = DateTime.now();
    if (now.isBefore(startTime)) return 0;
    return now.difference(startTime).inDays;
  }

  // حساب إجمالي الأيام للمكافأة
  int get totalDays {
    return endTime.difference(startTime).inDays;
  }

  // حساب المكافآت المكتسبة حتى الآن (محسن)
  double get earnedReward {
    final now = DateTime.now();
    if (now.isBefore(startTime)) return 0.0;
    if (now.isAfter(endTime) || status == RewardsStatus.completed) {
      return totalReward;
    }

    final totalDuration = endTime.difference(startTime);
    final elapsedDuration = now.difference(startTime);

    if (totalDuration.inDays <= 0) return 0.0;

    // حساب النسبة الزمنية المنقضية بدقة أكبر
    final elapsedRatio =
        elapsedDuration.inMilliseconds / totalDuration.inMilliseconds;

    // التأكد من أن النسبة لا تتجاوز 1.0
    final clampedRatio = elapsedRatio.clamp(0.0, 1.0);

    return (totalReward * clampedRatio).clamp(0.0, totalReward);
  }

  // حساب المكافآت المتبقية
  double get remainingReward =>
      (totalReward - earnedReward).clamp(0.0, totalReward);

  // حساب المكافآت اليومية الحالية
  double get currentDailyReward {
    if (isExpired || isCompleted) return 0.0;
    return dailyReward;
  }

  // حساب العائد على المكافأة (ROI)
  double get roiPercentage {
    if (rewardAmount <= 0) return 0.0;
    return (totalReward / rewardAmount) * 100;
  }

  // حساب العائد اليومي كنسبة مئوية
  double get dailyRoiPercentage {
    if (rewardAmount <= 0) return 0.0;
    return (dailyReward / rewardAmount) * 100;
  }

  // نسبة الإنجاز
  double get progressPercentage {
    final totalDays = endTime.difference(startTime).inDays;
    if (totalDays <= 0) return 100.0;

    final elapsedDays = DateTime.now().difference(startTime).inDays;
    return ((elapsedDays / totalDays) * 100).clamp(0.0, 100.0);
  }

  // نسبة التقدم (0.0 إلى 1.0)
  double get progress => progressPercentage / 100;

  // التحقق من حالة المكافأة
  bool get isExpired =>
      DateTime.now().isAfter(endTime) && status != RewardsStatus.completed;
  bool get isCompleted => status == RewardsStatus.completed;
  bool get isActive => status == RewardsStatus.active;
  bool get canRedeem => isCompleted && status != RewardsStatus.redeemed;
  bool get canCancel => isActive && !isExpired;
  bool get canTransferReward => isActive && remainingReward > 0;

  // معلومات إضافية للعرض
  String get statusText {
    switch (status) {
      case RewardsStatus.active:
        return isExpired ? 'منتهي الصلاحية' : 'نشط';
      case RewardsStatus.completed:
        return 'مكتمل';
      case RewardsStatus.redeemed:
        return 'محول';
      case RewardsStatus.expired:
        return 'منتهي الصلاحية';
      case RewardsStatus.cancelled:
        return 'ملغي';
    }
  }

  String get timeRemainingText {
    if (isExpired) return 'انتهى';
    if (isCompleted) return 'مكتمل';

    final days = remainingDays;
    if (days == 0) return 'اليوم';
    if (days == 1) return 'يوم واحد';
    if (days < 7) return '$days أيام';
    if (days < 30) return '${(days / 7).round()} أسابيع';
    return '${(days / 30).round()} أشهر';
  }

  ActiveReward copyWith({
    String? id,
    String? userId,
    String? packageName,
    double? totalReward,
    double? dailyReward,
    double? rewardAmount,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? lastRewardDate,
    RewardsStatus? status,
    String? paymentMethod,
    Map<String, dynamic>? metadata,
  }) {
    return ActiveReward(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      packageName: packageName ?? this.packageName,
      totalReward: totalReward ?? this.totalReward,
      dailyReward: dailyReward ?? this.dailyReward,
      rewardAmount: rewardAmount ?? this.rewardAmount,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      lastRewardDate: lastRewardDate ?? this.lastRewardDate,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// نموذج المكافأة المكتملة
class CompletedReward {
  final String id;
  final String userId;
  final String packageName;
  final double totalReward;
  final double transferredAmount;
  final DateTime completedAt;
  final DateTime? redeemedAt;
  final bool isArchived;
  final String paymentMethod;
  final Map<String, dynamic>? metadata;

  CompletedReward({
    required this.id,
    required this.userId,
    required this.packageName,
    required this.totalReward,
    required this.transferredAmount,
    required this.completedAt,
    this.redeemedAt,
    this.isArchived = false,
    required this.paymentMethod,
    this.metadata,
  });

  factory CompletedReward.fromMap(Map<String, dynamic> data, String id) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return CompletedReward(
      id: id,
      userId: data[RewardsConstants.fieldUserId] ?? '',
      packageName: data['packageName'] ?? '',
      totalReward: parseDouble(
          data[RewardsConstants.fieldTotalReward] ?? data['total_reward']),
      transferredAmount: parseDouble(data['transferredAmount']),
      completedAt:
          (data['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      redeemedAt: (data['redeemedAt'] as Timestamp? ??
              data['transferredAt'] as Timestamp?)
          ?.toDate(),
      isArchived: data['isArchived'] ?? false,
      paymentMethod: data['paymentMethod'] ?? RewardsConstants.currencyGems,
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      RewardsConstants.fieldUserId: userId,
      'packageName': packageName,
      RewardsConstants.fieldTotalReward: totalReward,
      'transferredAmount': transferredAmount,
      'completedAt': Timestamp.fromDate(completedAt),
      'redeemedAt': redeemedAt != null ? Timestamp.fromDate(redeemedAt!) : null,
      'isArchived': isArchived,
      'paymentMethod': paymentMethod,
      'metadata': metadata,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  // حساب المكافآت الصافية (بعد الضرائب أو الرسوم)
  double get netReward => transferredAmount;

  // حساب الضرائب أو الرسوم المخصومة
  double get deductedFees => totalReward - transferredAmount;

  // حساب معدل الضرائب كنسبة مئوية
  double get deductionRate {
    if (totalReward <= 0) return 0.0;
    return (deductedFees / totalReward) * 100;
  }

  // التحقق من حالة التحويل
  bool get isRedeemed => redeemedAt != null;
  bool get canRedeem => !isRedeemed && !isArchived;
  bool get isPendingRedemption => !isRedeemed && !isArchived;

  // معلومات إضافية للعرض
  String get statusText {
    if (isArchived) return 'مؤرشف';
    if (isRedeemed) return 'محول';
    return 'متاح للتحويل';
  }

  String get completionDateText {
    final now = DateTime.now();
    final diff = now.difference(completedAt);

    if (diff.inDays == 0) return 'اليوم';
    if (diff.inDays == 1) return 'أمس';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام';
    if (diff.inDays < 30) return 'منذ ${(diff.inDays / 7).round()} أسابيع';
    return 'منذ ${(diff.inDays / 30).round()} أشهر';
  }

  String get redemptionDateText {
    if (redeemedAt == null) return 'لم يتم التحويل بعد';

    final now = DateTime.now();
    final diff = now.difference(redeemedAt!);

    if (diff.inDays == 0) return 'اليوم';
    if (diff.inDays == 1) return 'أمس';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام';
    if (diff.inDays < 30) return 'منذ ${(diff.inDays / 7).round()} أسابيع';
    return 'منذ ${(diff.inDays / 30).round()} أشهر';
  }

  CompletedReward copyWith({
    String? id,
    String? userId,
    String? packageName,
    double? totalReward,
    double? transferredAmount,
    DateTime? completedAt,
    DateTime? redeemedAt,
    bool? isArchived,
    String? paymentMethod,
    Map<String, dynamic>? metadata,
  }) {
    return CompletedReward(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      packageName: packageName ?? this.packageName,
      totalReward: totalReward ?? this.totalReward,
      transferredAmount: transferredAmount ?? this.transferredAmount,
      completedAt: completedAt ?? this.completedAt,
      redeemedAt: redeemedAt ?? this.redeemedAt,
      isArchived: isArchived ?? this.isArchived,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// حالات طلبات التحويل
enum RedemptionStatus { pending, approved, rejected, completed, cancelled }

/// نموذج طلب التحويل
class RedemptionRequest {
  final String id;
  final String userId;
  final String userName;
  final String userRoyalId;
  final double amount;
  final String currency; // 'gems' or 'stars'
  final String method; // 'VirtualReward' - المكافآت الافتراضية فقط
  final String wallet;
  final String phone;
  final RedemptionStatus status;
  final DateTime requestDate;
  final DateTime? processedDate;
  final String? adminId;
  final String? adminNote;
  final String? proofImageUrl;
  final Map<String, dynamic>? metadata;

  RedemptionRequest({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userRoyalId,
    required this.amount,
    required this.currency,
    required this.method,
    required this.wallet,
    required this.phone,
    required this.status,
    required this.requestDate,
    this.processedDate,
    this.adminId,
    this.adminNote,
    this.proofImageUrl,
    this.metadata,
  });

  factory RedemptionRequest.fromMap(Map<String, dynamic> data, String id) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return RedemptionRequest(
      id: id,
      userId: data[RewardsConstants.fieldUserId] ?? '',
      userName: data['userName'] ?? '',
      userRoyalId: data['userRoyalId'] ?? '',
      amount: parseDouble(data['amount']),
      currency: data['currency'] ?? RewardsConstants.currencyStars,
      method: data['method'] ?? '',
      wallet: data['wallet'] ?? '',
      phone: data['phone'] ?? '',
      status: _parseRedemptionStatus(
          data[RewardsConstants.fieldStatus] ?? 'pending'),
      requestDate:
          (data['requestDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      processedDate: (data['processedDate'] as Timestamp?)?.toDate(),
      adminId: data['adminId'],
      adminNote: data['adminNote'],
      proofImageUrl: data['proofImageUrl'],
      metadata: data['metadata'],
    );
  }

  static RedemptionStatus _parseRedemptionStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return RedemptionStatus.pending;
      case 'approved':
        return RedemptionStatus.approved;
      case 'rejected':
        return RedemptionStatus.rejected;
      case 'completed':
        return RedemptionStatus.completed;
      case 'cancelled':
        return RedemptionStatus.cancelled;
      default:
        return RedemptionStatus.pending;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      RewardsConstants.fieldUserId: userId,
      'userName': userName,
      'userRoyalId': userRoyalId,
      'amount': amount,
      'currency': currency,
      'method': method,
      'wallet': wallet,
      'phone': phone,
      RewardsConstants.fieldStatus: status.name,
      'requestDate': Timestamp.fromDate(requestDate),
      'processedDate':
          processedDate != null ? Timestamp.fromDate(processedDate!) : null,
      'adminId': adminId,
      'adminNote': adminNote,
      'proofImageUrl': proofImageUrl,
      'metadata': metadata,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  // التحقق من الحالات
  bool get isPending => status == RedemptionStatus.pending;
  bool get isApproved => status == RedemptionStatus.approved;
  bool get isRejected => status == RedemptionStatus.rejected;
  bool get isCompleted => status == RedemptionStatus.completed;
  bool get isCancelled => status == RedemptionStatus.cancelled;
  bool get isProcessed => processedDate != null;
  bool get canApprove => isPending;
  bool get canReject => isPending;
  bool get canCancel => isPending;

  // معلومات إضافية للعرض
  String get statusText {
    switch (status) {
      case RedemptionStatus.pending:
        return 'قيد المراجعة';
      case RedemptionStatus.approved:
        return 'مُعتمد';
      case RedemptionStatus.rejected:
        return 'مرفوض';
      case RedemptionStatus.completed:
        return 'مكتمل';
      case RedemptionStatus.cancelled:
        return 'ملغي';
    }
  }

  String get statusColor {
    switch (status) {
      case RedemptionStatus.pending:
        return 'orange';
      case RedemptionStatus.approved:
        return 'green';
      case RedemptionStatus.rejected:
        return 'red';
      case RedemptionStatus.completed:
        return 'blue';
      case RedemptionStatus.cancelled:
        return 'grey';
    }
  }

  String get methodText {
    return 'البوابه الملكيه للجواهر والكوينز';
  }

  String get currencyText {
    switch (currency.toLowerCase()) {
      case 'gems':
        return 'جواهر';
      case 'stars':
      case 'points':
        return 'نجوم';
      default:
        return currency;
    }
  }

  String get requestDateText {
    final now = DateTime.now();
    final diff = now.difference(requestDate);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return 'منذ ${diff.inMinutes} دقيقة';
      }
      return 'منذ ${diff.inHours} ساعة';
    }
    if (diff.inDays == 1) return 'أمس';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام';
    if (diff.inDays < 30) return 'منذ ${(diff.inDays / 7).round()} أسابيع';
    return 'منذ ${(diff.inDays / 30).round()} أشهر';
  }

  String get processedDateText {
    if (processedDate == null) return 'لم تتم المعالجة';

    final now = DateTime.now();
    final diff = now.difference(processedDate!);

    if (diff.inDays == 0) {
      if (diff.inHours == 0) {
        return 'منذ ${diff.inMinutes} دقيقة';
      }
      return 'منذ ${diff.inHours} ساعة';
    }
    if (diff.inDays == 1) return 'أمس';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام';
    if (diff.inDays < 30) return 'منذ ${(diff.inDays / 7).round()} أسابيع';
    return 'منذ ${(diff.inDays / 30).round()} أشهر';
  }

  // التحقق من صحة البيانات
  bool get isValid {
    return amount > 0 &&
        userId.isNotEmpty &&
        method.isNotEmpty &&
        wallet.isNotEmpty &&
        phone.isNotEmpty;
  }

  // حساب الرسوم المحتملة
  double get estimatedFees {
    return amount * 0.01; // عمولة إدارية موحدة 1%
  }

  // حساب المبلغ الصافي بعد الرسوم
  double get netAmount => amount - estimatedFees;

  RedemptionRequest copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userRoyalId,
    double? amount,
    String? currency,
    String? method,
    String? wallet,
    String? phone,
    RedemptionStatus? status,
    DateTime? requestDate,
    DateTime? processedDate,
    String? adminId,
    String? adminNote,
    String? proofImageUrl,
    Map<String, dynamic>? metadata,
  }) {
    return RedemptionRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userRoyalId: userRoyalId ?? this.userRoyalId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      method: method ?? this.method,
      wallet: wallet ?? this.wallet,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      requestDate: requestDate ?? this.requestDate,
      processedDate: processedDate ?? this.processedDate,
      adminId: adminId ?? this.adminId,
      adminNote: adminNote ?? this.adminNote,
      proofImageUrl: proofImageUrl ?? this.proofImageUrl,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// نموذج إحصائيات مستخدم المكافآت
class RewardsUserStats {
  final String userId;
  final int totalRewards;
  final int activeRewards;
  final int completedRewards;
  final double totalRewardedAmount;
  final double totalEarned;
  final double totalRedeemed;
  final double currentBalance;
  final int totalRedemptions;
  final int pendingRedemptions;
  final DateTime lastActivity;
  final Map<String, dynamic>? metadata;

  RewardsUserStats({
    required this.userId,
    required this.totalRewards,
    required this.activeRewards,
    required this.completedRewards,
    required this.totalRewardedAmount,
    required this.totalEarned,
    required this.totalRedeemed,
    required this.currentBalance,
    required this.totalRedemptions,
    required this.pendingRedemptions,
    required this.lastActivity,
    this.metadata,
  });

  factory RewardsUserStats.fromMap(Map<String, dynamic> data) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return RewardsUserStats(
      userId: data[RewardsConstants.fieldUserId] ?? '',
      totalRewards: data['totalRewards'] ?? data['totalHarvests'] ?? 0,
      activeRewards: data['activeRewards'] ?? data['activeHarvests'] ?? 0,
      completedRewards:
          data['completedRewards'] ?? data['completedHarvests'] ?? 0,
      totalRewardedAmount: parseDouble(
          data['totalRewardedAmount'] ?? data['totalHarvestedAmount']),
      totalEarned: parseDouble(data['totalEarned']),
      totalRedeemed:
          parseDouble(data['totalRedeemed'] ?? data['total_redeemed']),
      currentBalance: parseDouble(data['currentBalance']),
      totalRedemptions:
          data['totalRedemptions'] ?? data['total_redemptions'] ?? 0,
      pendingRedemptions:
          data['pendingRedemptions'] ?? data['pending_redemptions'] ?? 0,
      lastActivity:
          (data['lastActivity'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      RewardsConstants.fieldUserId: userId,
      'totalRewards': totalRewards,
      'activeRewards': activeRewards,
      'completedRewards': completedRewards,
      'totalRewardedAmount': totalRewardedAmount,
      'totalEarned': totalEarned,
      'totalRedeemed': totalRedeemed,
      'currentBalance': currentBalance,
      'totalRedemptions': totalRedemptions,
      'pendingRedemptions': pendingRedemptions,
      'lastActivity': Timestamp.fromDate(lastActivity),
      'metadata': metadata,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  // حسابات إضافية
  double get netReward => totalEarned - totalRedeemed;
  double get yieldPercentage =>
      totalRewardedAmount > 0 ? (netReward / totalRewardedAmount) * 100 : 0.0;
  double get redemptionRate =>
      totalEarned > 0 ? (totalRedeemed / totalEarned) * 100 : 0.0;
  bool get hasActiveRewards => activeRewards > 0;
  bool get hasPendingRedemptions => pendingRedemptions > 0;
}

/// نموذج تقرير النظام
class RewardsSystemReport {
  final DateTime reportDate;
  final int totalUsers;
  final int activeUsers;
  final int totalRewards;
  final int activeRewards;
  final int completedRewards;
  final double totalRewardedAmount;
  final double totalEarned;
  final double totalRedeemed;
  final int totalRedemptions;
  final int pendingRedemptions;
  final Map<String, int> rewardsByPackage;
  final Map<String, double> earningsByCurrency;
  final Map<String, dynamic>? metadata;

  RewardsSystemReport({
    required this.reportDate,
    required this.totalUsers,
    required this.activeUsers,
    required this.totalRewards,
    required this.activeRewards,
    required this.completedRewards,
    required this.totalRewardedAmount,
    required this.totalEarned,
    required this.totalRedeemed,
    required this.totalRedemptions,
    required this.pendingRedemptions,
    required this.rewardsByPackage,
    required this.earningsByCurrency,
    this.metadata,
  });

  factory RewardsSystemReport.fromMap(Map<String, dynamic> data) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return RewardsSystemReport(
      reportDate:
          (data['reportDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      totalUsers: data['totalUsers'] ?? 0,
      activeUsers: data['activeUsers'] ?? 0,
      totalRewards: data['totalRewards'] ?? data['totalHarvests'] ?? 0,
      activeRewards: data['activeRewards'] ?? data['activeHarvests'] ?? 0,
      completedRewards:
          data['completedRewards'] ?? data['completedHarvests'] ?? 0,
      totalRewardedAmount: parseDouble(
          data['totalRewardedAmount'] ?? data['totalHarvestedAmount']),
      totalEarned: parseDouble(data['totalEarned']),
      totalRedeemed:
          parseDouble(data['totalRedeemed'] ?? data['total_redeemed']),
      totalRedemptions:
          data['totalRedemptions'] ?? data['total_redemptions'] ?? 0,
      pendingRedemptions:
          data['pendingRedemptions'] ?? data['pending_redemptions'] ?? 0,
      rewardsByPackage: Map<String, int>.from(
          data['rewardsByPackage'] ?? data['harvestsByPackage'] ?? {}),
      earningsByCurrency:
          Map<String, double>.from(data['earningsByCurrency'] ?? {}),
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reportDate': Timestamp.fromDate(reportDate),
      'totalUsers': totalUsers,
      'activeUsers': activeUsers,
      'totalRewards': totalRewards,
      'activeRewards': activeRewards,
      'completedRewards': completedRewards,
      'totalRewardedAmount': totalRewardedAmount,
      'totalEarned': totalEarned,
      'totalRedeemed': totalRedeemed,
      'totalRedemptions': totalRedemptions,
      'pendingRedemptions': pendingRedemptions,
      'rewardsByPackage': rewardsByPackage,
      'earningsByCurrency': earningsByCurrency,
      'metadata': metadata,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  // حسابات إضافية
  double get completionRate =>
      totalRewards > 0 ? (completedRewards / totalRewards) * 100 : 0.0;
  double get activeUserRate =>
      totalUsers > 0 ? (activeUsers / totalUsers) * 100 : 0.0;
  double get redemptionRate =>
      totalEarned > 0 ? (totalRedeemed / totalEarned) * 100 : 0.0;
  double get averageReward =>
      totalUsers > 0 ? totalRewardedAmount / totalUsers : 0.0;
  double get averageEarnings =>
      activeUsers > 0 ? totalEarned / activeUsers : 0.0;
}

/// استثناءات نظام المكافآت
class RewardsException implements Exception {
  final String message;
  final String code;
  final Map<String, dynamic>? data;

  RewardsException(this.message, {this.code = 'UNKNOWN_ERROR', this.data});

  @override
  String toString() => 'RewardsException: $code - $message';
}

/// أخطاء محددة لنظام المكافآت
class InsufficientFundsException extends RewardsException {
  InsufficientFundsException(String currency, double required, double available)
      : super(
          'الرصيد غير كافي. مطلوب: $required $currency، متوفر: $available $currency',
          code: 'INSUFFICIENT_FUNDS',
          data: {
            'required': required,
            'available': available,
            'currency': currency
          },
        );
}

class RewardNotFoundException extends RewardsException {
  RewardNotFoundException(String rewardId)
      : super(
          'المكافأة غير موجودة: $rewardId',
          code: 'REWARD_NOT_FOUND',
          data: {'rewardId': rewardId},
        );
}

class InvalidRewardStatusException extends RewardsException {
  InvalidRewardStatusException(String currentStatus, String requiredStatus)
      : super(
          'حالة المكافأة غير صحيحة. الحالية: $currentStatus، المطلوبة: $requiredStatus',
          code: 'INVALID_STATUS',
          data: {'current': currentStatus, 'required': requiredStatus},
        );
}

class RedemptionLimitExceededException extends RewardsException {
  RedemptionLimitExceededException(double requested, double limit)
      : super(
          'تم تجاوز حد التحويل. المطلوب: $requested، الحد الأقصى: $limit',
          code: 'REDEMPTION_LIMIT_EXCEEDED',
          data: {'requested': requested, 'limit': limit},
        );
}

/// نموذج عرض التداول
class RewardListing {
  final String id;
  final String sellerId;
  final String rewardId;
  final String packageName;
  final double askingPrice;
  final String currency;
  final Map<String, dynamic> rewardData;
  final String? description;
  final String status; // 'active', 'sold', 'cancelled'
  final DateTime createdAt;
  final DateTime? soldAt;
  final String? buyerId;

  RewardListing({
    required this.id,
    required this.sellerId,
    required this.rewardId,
    required this.packageName,
    required this.askingPrice,
    required this.currency,
    required this.rewardData,
    this.description,
    required this.status,
    required this.createdAt,
    this.soldAt,
    this.buyerId,
  });

  factory RewardListing.fromMap(Map<String, dynamic> data) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return RewardListing(
      id: data['id'] ?? '',
      sellerId: data['sellerId'] ?? '',
      rewardId: data['rewardId'] ?? data['harvestId'] ?? '',
      packageName: data['packageName'] ?? '',
      askingPrice: parseDouble(data['askingPrice']),
      currency: data['currency'] ?? 'gems',
      rewardData: data['rewardData'] ?? data['harvestData'] ?? {},
      description: data['description'],
      status: data['status'] ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      soldAt: (data['soldAt'] as Timestamp?)?.toDate(),
      buyerId: data['buyerId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sellerId': sellerId,
      'rewardId': rewardId,
      'packageName': packageName,
      'askingPrice': askingPrice,
      'currency': currency,
      'rewardData': rewardData,
      'description': description,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'soldAt': soldAt != null ? Timestamp.fromDate(soldAt!) : null,
      'buyerId': buyerId,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  bool get isActive => status == 'active';
  bool get isSold => status == 'sold';
  bool get isCancelled => status == 'cancelled';
}

/// نموذج إنجاز المكافآت
class RewardAchievement {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String icon;
  final int rewardGems;
  final DateTime unlockedAt;
  final bool isClaimed;

  RewardAchievement({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.icon,
    required this.rewardGems,
    required this.unlockedAt,
    this.isClaimed = false,
  });

  factory RewardAchievement.fromMap(Map<String, dynamic> data, String id) {
    return RewardAchievement(
      id: id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      icon: data['icon'] ?? '',
      rewardGems: data['rewardGems'] ?? 0,
      unlockedAt:
          (data['unlockedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isClaimed: data['isClaimed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'icon': icon,
      'rewardGems': rewardGems,
      'unlockedAt': Timestamp.fromDate(unlockedAt),
      'isClaimed': isClaimed,
    };
  }
}

/// إعدادات نظام المكافآت
class RewardsSettings {
  final double minReward;
  final double maxReward;
  final double dailyRewardRate;
  final int maxActiveRewards;
  final double redemptionFee;
  final double zainCashFee;
  final double asiaPayFee;
  final double bankTransferFee;
  final int maxRedemptionsPerDay;
  final double maxRedemptionAmount;
  final bool autoApproveRedemptions;
  final int rewardDurationDays;
  final Map<String, dynamic> packageConfigs;
  final Map<String, dynamic>? metadata;

  RewardsSettings({
    required this.minReward,
    required this.maxReward,
    required this.dailyRewardRate,
    required this.maxActiveRewards,
    required this.redemptionFee,
    required this.zainCashFee,
    required this.asiaPayFee,
    required this.bankTransferFee,
    required this.maxRedemptionsPerDay,
    required this.maxRedemptionAmount,
    required this.autoApproveRedemptions,
    required this.rewardDurationDays,
    required this.packageConfigs,
    this.metadata,
  });

  factory RewardsSettings.fromMap(Map<String, dynamic> data) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return RewardsSettings(
      minReward: parseDouble(data['minReward'] ?? data['minHarvest'] ?? 100),
      maxReward: parseDouble(data['maxReward'] ?? data['maxHarvest'] ?? 10000),
      dailyRewardRate: parseDouble(data['dailyRewardRate'] ??
          data['daily_reward_rate'] ??
          data['dailyRewardRate'] ??
          0.01),
      maxActiveRewards:
          data['maxActiveRewards'] ?? data['maxActiveHarvests'] ?? 5,
      redemptionFee:
          parseDouble(data['redemptionFee'] ?? data['transfer_fee'] ?? 0.05),
      zainCashFee: parseDouble(data['zainCashFee'] ?? 0.02),
      asiaPayFee: parseDouble(data['asiaPayFee'] ?? 0.015),
      bankTransferFee: parseDouble(data['bankTransferFee'] ?? 1.0),
      maxRedemptionsPerDay:
          data['maxRedemptionsPerDay'] ?? data['max_redemptions_per_day'] ?? 3,
      maxRedemptionAmount: parseDouble(
          data['maxRedemptionAmount'] ?? data['max_redemption_amount'] ?? 1000),
      autoApproveRedemptions: data['autoApproveRedemptions'] ??
          data['auto_approve_redemptions'] ??
          false,
      rewardDurationDays:
          data['rewardDurationDays'] ?? data['harvestDurationDays'] ?? 30,
      packageConfigs: data['packageConfigs'] ?? {},
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'minReward': minReward,
      'maxReward': maxReward,
      'dailyRewardRate': dailyRewardRate,
      'maxActiveRewards': maxActiveRewards,
      'redemptionFee': redemptionFee,
      'zainCashFee': zainCashFee,
      'asiaPayFee': asiaPayFee,
      'bankTransferFee': bankTransferFee,
      'maxRedemptionsPerDay': maxRedemptionsPerDay,
      'maxRedemptionAmount': maxRedemptionAmount,
      'autoApproveRedemptions': autoApproveRedemptions,
      'rewardDurationDays': rewardDurationDays,
      'packageConfigs': packageConfigs,
      'metadata': metadata,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  // حساب الرسوم حسب طريقة الدفع
  double getFeeForMethod(String method) {
    return redemptionFee;
  }

  // التحقق من صحة مبلغ المكافأة
  bool isValidRewardAmount(double amount) {
    return amount >= minReward && amount <= maxReward;
  }

  // التحقق من صحة مبلغ التحويل
  bool isValidRedemptionAmount(double amount) {
    return amount > 0 && amount <= maxRedemptionAmount;
  }
}

/// نموذج حزمة المكافآت
class RewardPackage {
  final String id;
  final String name;
  final String description;
  final double cost;
  final double dailyReward;
  final double totalReward;
  final int durationDays;
  final String currency;
  final bool isActive;
  final int sortOrder;
  final String? iconUrl;
  final Map<String, dynamic>? features;
  final Map<String, dynamic>? metadata;

  RewardPackage({
    required this.id,
    required this.name,
    required this.description,
    required this.cost,
    required this.dailyReward,
    required this.totalReward,
    required this.durationDays,
    required this.currency,
    required this.isActive,
    required this.sortOrder,
    this.iconUrl,
    this.features,
    this.metadata,
  });

  factory RewardPackage.fromMap(Map<String, dynamic> data, String id) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return RewardPackage(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      cost: parseDouble(data['cost']),
      dailyReward: parseDouble(
          data[RewardsConstants.fieldDailyReward] ?? data['daily_reward']),
      totalReward: parseDouble(
          data[RewardsConstants.fieldTotalReward] ?? data['total_reward']),
      durationDays: data['durationDays'] ?? 30,
      currency: data['currency'] ?? RewardsConstants.currencyGems,
      isActive: data['isActive'] ?? true,
      sortOrder: data['sortOrder'] ?? 0,
      iconUrl: data['iconUrl'],
      features: data['features'],
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'cost': cost,
      RewardsConstants.fieldDailyReward: dailyReward,
      RewardsConstants.fieldTotalReward: totalReward,
      'durationDays': durationDays,
      'currency': currency,
      'isActive': isActive,
      'sortOrder': sortOrder,
      'iconUrl': iconUrl,
      'features': features,
      'metadata': metadata,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  // حسابات إضافية
  double get yieldPercentage => cost > 0 ? (totalReward / cost) * 100 : 0.0;
  double get dailyYieldPercentage =>
      cost > 0 ? (dailyReward / cost) * 100 : 0.0;
  String get currencyText =>
      (currency == 'gems' || currency == 'diamonds') ? 'جواهر' : 'نجوم';
  bool get isAvailable => isActive && cost > 0;
}
