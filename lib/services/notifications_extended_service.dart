import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../constants/rewards_constants.dart';

enum NotificationType {
  rewardActivated, // تم تفعيل المكافأة
  rewardCompleted, // اكتملت المكافأة
  dailyRewardAvailable, // المكافأة اليومية متاحة
  transferInitiated, // تم بدء التحويل
  transferCompleted, // اكتمل التحويل
  transferFailed, // فشل التحويل
  redemptionApproved, // تم الموافقة على الاسترجاع
  redemptionRejected, // تم رفض الاسترجاع
  largeTransferAlert, // تنبيه تحويل كبير
  monthlyReportReady, // التقرير الشهري جاهز
  systemMaintenance, // صيانة النظام
  securityAlert, // تنبيه أمني
}

class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final String? actionUrl;
  final Map<String, dynamic> data;
  final DateTime sentAt;
  final bool isRead;
  final String channel; // push, email, in-app

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.actionUrl,
    required this.data,
    required this.sentAt,
    required this.isRead,
    required this.channel,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> data, String id) {
    return NotificationModel(
      id: id,
      userId: data['userId'] as String? ?? '',
      type: _parseNotificationType(data['type'] as String?),
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      actionUrl: data['actionUrl'] as String?,
      data: Map<String, dynamic>.from(data['data'] as Map? ?? {}),
      sentAt: (data['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] as bool? ?? false,
      channel: data['channel'] as String? ?? 'in-app',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.toString().split('.').last,
      'title': title,
      'body': body,
      'actionUrl': actionUrl,
      'data': data,
      'sentAt': Timestamp.fromDate(sentAt),
      'isRead': isRead,
      'channel': channel,
    };
  }

  static NotificationType _parseNotificationType(String? type) {
    switch (type) {
      case 'rewardActivated':
        return NotificationType.rewardActivated;
      case 'rewardCompleted':
        return NotificationType.rewardCompleted;
      case 'dailyRewardAvailable':
        return NotificationType.dailyRewardAvailable;
      case 'transferInitiated':
        return NotificationType.transferInitiated;
      case 'transferCompleted':
        return NotificationType.transferCompleted;
      case 'transferFailed':
        return NotificationType.transferFailed;
      case 'redemptionApproved':
        return NotificationType.redemptionApproved;
      case 'redemptionRejected':
        return NotificationType.redemptionRejected;
      case 'largeTransferAlert':
        return NotificationType.largeTransferAlert;
      case 'monthlyReportReady':
        return NotificationType.monthlyReportReady;
      case 'systemMaintenance':
        return NotificationType.systemMaintenance;
      case 'securityAlert':
        return NotificationType.securityAlert;
      default:
        return NotificationType.systemMaintenance;
    }
  }
}

/// خدمة إدارة الإشعارات الشاملة
class NotificationsExtendedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String collectionNotifications = 'notifications';
  static const String collectionEmailLogs = 'email_logs';
  static const String collectionPushLogs = 'push_logs';

  /// إرسال إشعار شامل (Push + Email + In-App)
  Future<void> sendNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    String? actionUrl,
    Map<String, dynamic>? data,
    bool enablePush = true,
    bool enableEmail = true,
    bool enableInApp = true,
  }) async {
    try {
      final notificationRef =
          _firestore.collection(collectionNotifications).doc();

      final notification = NotificationModel(
        id: notificationRef.id,
        userId: userId,
        type: type,
        title: title,
        body: body,
        actionUrl: actionUrl,
        data: data ?? {},
        sentAt: DateTime.now(),
        isRead: false,
        channel: 'in-app',
      );

      // حفظ الإشعار الداخلي
      if (enableInApp) {
        await notificationRef.set(notification.toMap());
      }

      // إرسال إشعار Push
      if (enablePush && RewardsConstants.enablePushNotifications) {
        await _sendPushNotification(userId, title, body, notification.id);
      }

      // إرسال بريد إلكتروني للتحويلات الكبيرة
      if (enableEmail &&
          RewardsConstants.enableEmailNotifications &&
          _shouldSendEmail(type)) {
        await _sendEmailNotification(userId, title, body, type);
      }
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }

  /// إرسال إشعار Push
  Future<void> _sendPushNotification(
    String userId,
    String title,
    String body,
    String notificationId,
  ) async {
    try {
      // سيتم التكامل مع Firebase Cloud Messaging (FCM) في المستقبل
      final logRef = _firestore.collection(collectionPushLogs).doc();

      await logRef.set({
        'userId': userId,
        'title': title,
        'body': body,
        'notificationId': notificationId,
        'sentAt': FieldValue.serverTimestamp(),
        'status': 'sent',
      });

      debugPrint('Push notification sent to $userId');
    } catch (e) {
      debugPrint('Error sending push notification: $e');
    }
  }

  /// إرسال بريد إلكتروني
  Future<void> _sendEmailNotification(
    String userId,
    String title,
    String body,
    NotificationType type,
  ) async {
    try {
      final emailContent = _generateEmailContent(title, body, type);

      final logRef = _firestore.collection(collectionEmailLogs).doc();

      await logRef.set({
        'userId': userId,
        'title': title,
        'body': body,
        'emailContent': emailContent,
        'sentAt': FieldValue.serverTimestamp(),
        'status': 'queued',
        'type': type.toString().split('.').last,
      });

      // في الإنتاج، سيتم إرسال البريد عبر Cloud Function
      debugPrint('Email notification queued for $userId');
    } catch (e) {
      debugPrint('Error queuing email notification: $e');
    }
  }

  /// تحديد ما إذا كان يجب إرسال بريد إلكتروني
  bool _shouldSendEmail(NotificationType type) {
    return [
      NotificationType.transferCompleted,
      NotificationType.transferFailed,
      NotificationType.largeTransferAlert,
      NotificationType.redemptionApproved,
      NotificationType.monthlyReportReady,
      NotificationType.securityAlert,
    ].contains(type);
  }

  /// توليد محتوى البريد الإلكتروني
  String _generateEmailContent(
    String title,
    String body,
    NotificationType type,
  ) {
    return '''
    <!DOCTYPE html>
    <html dir="rtl">
    <head>
      <meta charset="utf-8">
      <style>
        body { font-family: Arial, sans-serif; direction: rtl; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #1a1a2e; color: white; padding: 20px; text-align: center; border-radius: 5px; }
        .content { background-color: #f5f5f5; padding: 20px; margin-top: 20px; border-radius: 5px; }
        .footer { text-align: center; margin-top: 20px; color: #666; font-size: 12px; }
        .button { background-color: #16213e; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>الملك الملكي - Royal Door</h1>
        </div>
        <div class="content">
          <h2>$title</h2>
          <p>$body</p>
          <p>وقت الرسالة: ${DateTime.now().toString()}</p>
        </div>
        <div class="footer">
          <p>هذا البريد الإلكتروني تم إرساله بناءً على إعداداتك. يمكنك تغيير إعدادات الإشعارات من التطبيق.</p>
          <p>&copy; 2026 Royal Door. جميع الحقوق محفوظة.</p>
        </div>
      </div>
    </body>
    </html>
    ''';
  }

  /// الحصول على إشعارات المستخدم
  Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection(collectionNotifications)
        .where('userId', isEqualTo: userId)
        .orderBy('sentAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NotificationModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  /// تحديث حالة الإشعار إلى مقروء
  Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore
          .collection(collectionNotifications)
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// حذف إشعار
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection(collectionNotifications)
          .doc(notificationId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  /// حذف جميع إشعارات المستخدم
  Future<void> deleteAllUserNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(collectionNotifications)
          .where('userId', isEqualTo: userId)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Error deleting all notifications: $e');
    }
  }

  /// الحصول على عدد الإشعارات غير المقروءة
  Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(collectionNotifications)
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.size;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  /// إرسال إشعار تحويل كبير
  Future<void> sendLargeTransferAlert({
    required String userId,
    required double amount,
    required String currency,
    required String recipientName,
  }) async {
    await sendNotification(
      userId: userId,
      type: NotificationType.largeTransferAlert,
      title: 'تحويل كبير قيد المعالجة',
      body:
          'تم بدء تحويل بمبلغ $amount $currency إلى $recipientName. سيتم إكمال العملية خلال 24 ساعة.',
      data: {
        'amount': amount,
        'currency': currency,
        'recipient': recipientName,
      },
      enableEmail: true,
    );
  }

  /// إرسال إشعار التقرير الشهري
  Future<void> sendMonthlyReportNotification({
    required String userId,
    required String monthName,
    required double totalEarned,
    required double totalTransferred,
  }) async {
    await sendNotification(
      userId: userId,
      type: NotificationType.monthlyReportReady,
      title: 'تقريرك الشهري جاهز',
      body:
          'تقريرك لشهر $monthName جاهز الآن. الأرباح: $totalEarned، التحويلات: $totalTransferred',
      actionUrl: '/reports/$monthName',
      data: {
        'month': monthName,
        'totalEarned': totalEarned,
        'totalTransferred': totalTransferred,
      },
      enableEmail: true,
    );
  }

  /// إرسال إشعار تنبيه أمني
  Future<void> sendSecurityAlert({
    required String userId,
    required String alertMessage,
    required String severity, // low, medium, high
  }) async {
    await sendNotification(
      userId: userId,
      type: NotificationType.securityAlert,
      title: 'تنبيه أمني مهم',
      body: alertMessage,
      data: {
        'severity': severity,
        'timestamp': DateTime.now().toIso8601String(),
      },
      enablePush: true,
      enableEmail: severity == 'high',
    );
  }

  /// إرسال إشعار المكافأة اليومية
  Future<void> sendDailyRewardNotification({
    required String userId,
    required double rewardAmount,
  }) async {
    await sendNotification(
      userId: userId,
      type: NotificationType.dailyRewardAvailable,
      title: 'مكافأة يومية متاحة',
      body: 'يمكنك استلام مكافأتك اليومية بقيمة $rewardAmount الآن!',
      data: {
        'rewardAmount': rewardAmount,
      },
    );
  }

  /// إرسال إشعار التحويل
  Future<void> sendTransferNotification({
    required String userId,
    required double amount,
    required String recipientName,
    required bool isSuccess,
  }) async {
    final type = isSuccess
        ? NotificationType.transferCompleted
        : NotificationType.transferFailed;
    final title = isSuccess ? 'تم التحويل بنجاح' : 'فشل التحويل';
    final body = isSuccess
        ? 'تم تحويل $amount إلى $recipientName بنجاح'
        : 'فشل تحويل $amount إلى $recipientName. يرجى محاولة مرة أخرى.';

    await sendNotification(
      userId: userId,
      type: type,
      title: title,
      body: body,
      data: {
        'amount': amount,
        'recipient': recipientName,
        'success': isSuccess,
      },
      enablePush: true,
      enableEmail: amount > 100000, // بريد للتحويلات الكبيرة
    );
  }
}
