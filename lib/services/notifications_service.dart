import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../features/rewards_page.dart';
import '../features/diaries/story_viewer.dart';
import '../models/story_model.dart';
import '../constants/rewards_constants.dart';
import 'notification_router_service.dart';
import 'user_settings_service.dart';

// Service: إدارة الإشعارات (Push + سجل)
// ملاحظة: استقبال إشعارات FCM وعرضها محليًا يتم في main.dart عبر flutter_local_notifications.
// يمكن توسيع هذه الخدمة لاحقًا لمعالجة مخصصة أو منطق إضافي إذا لزم.
// Collection: notifications
// Cloud Function: sendPushNotification
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../features/diaries/single_post_page.dart';

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
  general, // عام
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
      case 'general':
        return NotificationType.general;
      default:
        return NotificationType.general;
    }
  }
}

class NotificationsService {
  static final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String collectionNotifications = 'notifications';
  static const String collectionEmailLogs = 'email_logs';
  static const String collectionPushLogs = 'push_logs';

  // مفتاح تنقل عالمي لاستخدامه عند الضغط على الإشعار
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// تهيئة الإشعارات المحلية (يجب استدعاؤها في main.dart)
  static Future<void> initLocalNotifications() async {
    tz.initializeTimeZones();
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
        InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );
  }

  /// معالجة الضغط على أزرار الإشعار
  static void _onNotificationResponse(NotificationResponse response) {
    if (response.payload == null) return;

    try {
      final payload = response.payload!;
      
      // Check if this is an action button click
      if (response.actionId != null && response.actionId!.isNotEmpty) {
        try {
          final Map<String, dynamic> obj = jsonDecode(payload);
          NotificationRouterService.handleNotificationTap(
            obj,
            action: response.actionId,
          );
          return;
        } catch (e) {
          debugPrint('Error handling notification action: $e');
        }
      }

      // Handle main notification tap
      try {
        final Map<String, dynamic> obj = jsonDecode(payload);
        
        // Use new router service for enhanced notifications
        if (obj.containsKey('type') && obj['type'] is String) {
          final notificationType = obj['type'] as String;
          
          // Check if this is an enhanced notification format
          if (['message', 'friendRequest', 'like', 'battle', 'story', 'dailyPost']
              .contains(notificationType)) {
            NotificationRouterService.handleNotificationTap(obj);
            return;
          }
        }
        
        // Fallback to legacy handling
        final String? type = obj['type'] as String?;
        final dynamic data = obj['data'];
        if (type == 'post' && data != null && data['postId'] != null) {
          navigatorKey.currentState?.push(MaterialPageRoute(
              builder: (_) => SinglePostPage(postId: data['postId'])));
          return;
        }
        if (type == 'story' && data != null && data['storyId'] != null) {
          _openStoryById(data['storyId']);
          return;
        }
      } catch (_) {
        // fallback to string keys
        if (payload == 'rewards_daily' ||
            payload == 'rewards_monthly' ||
            payload == 'harvest_reminder') {
          navigatorKey.currentState
              ?.push(MaterialPageRoute(builder: (_) => const RewardsPage()));
          return;
        }
      }
    } catch (e) {
      debugPrint('Error in _onNotificationResponse: $e');
    }
  }

  /// إرسال إشعار Push Notification (Admin/System)
  static Future<Map<String, dynamic>> sendPushNotification(
      Map<String, dynamic> data) async {
    final callable = _functions.httpsCallable('sendPushNotification');
    final result = await callable.call(data);
    return Map<String, dynamic>.from(result.data);
  }

  /// جلب الإشعارات من Firestore
  static Stream<QuerySnapshot<Map<String, dynamic>>> notificationsStream(
      String uid) {
    if (uid.isEmpty) {
      // إرجاع Stream فارغ إذا لم يتم تحديد uid
      return const Stream.empty();
    }
    return _firestore
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .snapshots();
  }

  /// إرسال إشعار محلي للمستخدم
  static Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    String type = 'general',
    Map<String, dynamic>? data,
  }) async {
    try {
      // التحقق من إعدادات الإشعارات للمستخدم
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == userId) {
        // التحقق من تفعيل الإشعارات الداخلية
        final internalEnabled = await UserSettingsService.areInternalNotificationsEnabled();
        if (!internalEnabled) {
          debugPrint('Internal notifications disabled for user $userId');
          return;
        }
      }

      // التحقق من نوع الإشعار المحدد
      bool shouldSend = true;
      switch (type) {
        case 'follow':
          shouldSend = await UserSettingsService.areFollowNotificationsEnabled();
          break;
        case 'like':
          shouldSend = await UserSettingsService.areLikeNotificationsEnabled();
          break;
        case 'comment':
          shouldSend = await UserSettingsService.areCommentNotificationsEnabled();
          break;
        case 'gift':
          shouldSend = await UserSettingsService.areGiftNotificationsEnabled();
          break;
        case 'badge':
          shouldSend = await UserSettingsService.areBadgeNotificationsEnabled();
          break;
        case 'battle':
          shouldSend = await UserSettingsService.areBattleNotificationsEnabled();
          break;
        case 'reward':
          shouldSend = await UserSettingsService.areRewardNotificationsEnabled();
          break;
        case 'friend_request':
          shouldSend = await UserSettingsService.areFriendRequestNotificationsEnabled();
          break;
        case 'chat':
          shouldSend = await UserSettingsService.areChatNotificationsEnabled();
          break;
        case 'system':
          shouldSend = await UserSettingsService.areSystemNotificationsEnabled();
          break;
        default:
          // للإشعارات العامة، نتحقق من الإشعارات الداخلية
          shouldSend = await UserSettingsService.areInternalNotificationsEnabled();
      }

      if (!shouldSend) {
        debugPrint('Notification type $type disabled for user $userId');
        return;
      }

      // حفظ الإشعار في Firestore
      await _firestore
          .collection('notifications')
          .doc(userId)
          .collection('items')
          .add({
        'title': title,
        'message': message,
        'type': type,
        'data': data ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'read': false,
      });

      // إرسال إشعار محلي إذا كان التطبيق مفتوحاً
      const androidDetails = AndroidNotificationDetails(
        'general_channel',
        'إشعارات عامة',
        channelDescription: 'إشعارات النظام والتحديثات',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        enableVibration: true,
        playSound: true,
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000, // ID فريد
        title,
        message,
        const NotificationDetails(android: androidDetails),
        payload: jsonEncode({'type': type, 'data': data ?? {}}),
      );

      debugPrint('تم إرسال الإشعار: $title');
    } catch (e) {
      debugPrint('خطأ في إرسال الإشعار: $e');
    }
  }

  /// حفظ FCM Token في ملف المستخدم (يجب استدعاؤها عند فتح التطبيق)
  static Future<void> saveDeviceToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final FirebaseMessaging fcm = FirebaseMessaging.instance;

    // طلب الإذن (مهم للـ iOS و Android 13+)
    await fcm.requestPermission();

    final token = await fcm.getToken();
    if (token != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
      });
    }
  }

  /// إعداد التعامل مع النقر على الإشعارات
  static Future<void> setupInteractedMessage(BuildContext context) async {
    // 1. عند فتح التطبيق من حالة الإغلاق التام (Terminated)
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // 2. عند فتح التطبيق من الخلفية (Background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessage(message);
    });
  }

  static void _handleMessage(RemoteMessage message) {
    final String? type = message.data['type'];
    final navigator = navigatorKey.currentState;

    if (navigator == null) return;

    // Use new router service for enhanced notifications
    if (type != null && 
        ['message', 'friendRequest', 'like', 'battle', 'story', 'dailyPost']
            .contains(type)) {
      NotificationRouterService.handleNotificationTap(message.data);
      return;
    }

    // Fallback to legacy handling
    if (type == 'investment_ready' || type == 'rewards_ready') {
      navigator.push(MaterialPageRoute(builder: (_) => const RewardsPage()));
      return;
    }

    if (type == 'post' && message.data['postId'] != null) {
      final postId = message.data['postId'];
      navigator.push(
          MaterialPageRoute(builder: (_) => SinglePostPage(postId: postId)));
      return;
    }

    if (type == 'story' && message.data['storyId'] != null) {
      _openStoryById(message.data['storyId']);
      return;
    }
  }

  static Future<void> _openStoryById(String storyId) async {
    try {
      final storyDoc =
          await _firestore.collection('stories').doc(storyId).get();
      if (!storyDoc.exists) return;

      final storyData = storyDoc.data();
      if (storyData == null) return;

      final authorId = storyData['userId'] as String?;
      if (authorId == null || authorId.isEmpty) return;

      final storiesSnap = await _firestore
          .collection('stories')
          .where('userId', isEqualTo: authorId)
          .orderBy('createdAt', descending: true)
          .get();

      final stories = storiesSnap.docs
          .map((doc) => StoryModel.fromMap(doc.data(), doc.id))
          .toList();

      int initialIndex = stories.indexWhere((s) => s.id == storyId);
      if (initialIndex < 0) {
        initialIndex = 0;
      }

      navigatorKey.currentState?.push(MaterialPageRoute(
        builder: (_) => StoryViewer(
          stories: stories,
          initialIndex: initialIndex,
        ),
      ));
    } catch (e) {
      debugPrint('Error opening story from notification: $e');
    }
  }

  /// عرض إشعار محلي عند اكتمال المكافأة اليومية
  static Future<void> showDailyRewardsNotification(
      double rewardedAmount, String type) async {
    final String typeLabel =
        type == 'gems' ? 'جوهرة' : (type == 'stars' ? 'نجمة' : 'نقطة');

    const androidDetails = AndroidNotificationDetails(
      'rewards_channel',
      'إشعارات المكافآت',
      channelDescription: 'إشعارات اكتمال المكافأة اليومية والشهرية',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    try {
      await _localNotifications.show(
        1001,
        'تم استلام المكافأة اليومية بنجاح! 🎉',
        'حصلت على ${rewardedAmount.toStringAsFixed(0)} $typeLabel',
        const NotificationDetails(android: androidDetails),
        payload: 'rewards_daily',
      );
    } catch (e) {
      debugPrint('Error showing daily rewards notification: $e');
    }
  }

  /// عرض إشعار محلي عند اكتمال المكافأة الشهرية
  static Future<void> showMonthlyRewardsNotification(
      double amount, String packageName,
      {String unit = 'نجمة'}) async {
    const androidDetails = AndroidNotificationDetails(
      'monthly_rewards_channel',
      'إشعارات المكافآت الشهرية',
      channelDescription: 'إشعارات اكتمال الباقات الشهرية',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
    );

    try {
      await _localNotifications.show(
        1002,
        'اكتملت باقة $packageName! 👑',
        'تم تحويل ${amount.toStringAsFixed(0)} $unit إلى محفظتك ✨',
        const NotificationDetails(android: androidDetails),
        payload: 'rewards_monthly',
      );
    } catch (e) {
      debugPrint('Error showing monthly rewards notification: $e');
    }
  }

  /// جدولة تنبيه للمكافآت القادم بعد 24 ساعة
  static Future<void> scheduleHarvestReminder() async {
    const androidDetails = AndroidNotificationDetails(
      'harvest_reminder_channel',
      'تذكير المكافآت الملكية',
      channelDescription: 'تذكير بموعد المكافآت اليومية',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    try {
      // إلغاء أي تذكير سابق لتجنب التكرار
      await _localNotifications.cancel(2001);

      await _localNotifications.zonedSchedule(
        2001,
        'حان وقت المكافآت الملكية! 👑',
        'مكافآتك اليومية جاهزة للاستلام الآن، لا تدعها تفوتك ✨',
        tz.TZDateTime.now(tz.local).add(const Duration(hours: 24)),
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'harvest_reminder',
      );
      debugPrint('تمت جدولة تذكير المكافآت بعد 24 ساعة');
    } catch (e) {
      debugPrint('خطأ في جدولة تذكير المكافآت: $e');
    }
  }

  /// إرسال إشعار شامل (Push + Email + In-App)
  static Future<void> sendExtendedNotification({
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
      final notificationRef = _firestore
          .collection(collectionNotifications)
          .doc(userId)
          .collection('items')
          .doc();

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
        await _sendPushNotificationExtended(
            userId, title, body, notification.id);
      }

      // إرسال بريد إلكتروني للتحويلات الكبيرة
      if (enableEmail &&
          RewardsConstants.enableEmailNotifications &&
          _shouldSendEmail(type)) {
        await _sendEmailNotification(userId, title, body, type);
      }
    } catch (e) {
      debugPrint('Error sending extended notification: $e');
    }
  }

  /// إرسال إشعار Push موسع
  static Future<void> _sendPushNotificationExtended(
    String userId,
    String title,
    String body,
    String notificationId,
  ) async {
    try {
      // تسجيل محاولة إرسال Push Notification
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
  static Future<void> _sendEmailNotification(
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

      debugPrint('Email notification queued for $userId');
    } catch (e) {
      debugPrint('Error queuing email notification: $e');
    }
  }

  /// تحديد ما إذا كان يجب إرسال بريد إلكتروني
  static bool _shouldSendEmail(NotificationType type) {
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
  static String _generateEmailContent(
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

  /// الحصول على إشعارات المستخدم كـ Stream من NotificationModel
  static Stream<List<NotificationModel>> getUserNotifications(String userId) {
    return _firestore
        .collection(collectionNotifications)
        .doc(userId)
        .collection('items')
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
  static Future<void> markAsRead(String notificationId, String userId) async {
    try {
      await _firestore
          .collection(collectionNotifications)
          .doc(userId)
          .collection('items')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// حذف إشعار
  static Future<void> deleteNotification(
      String notificationId, String userId) async {
    try {
      await _firestore
          .collection(collectionNotifications)
          .doc(userId)
          .collection('items')
          .doc(notificationId)
          .delete();
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  /// حذف جميع إشعارات المستخدم
  static Future<void> deleteAllUserNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(collectionNotifications)
          .doc(userId)
          .collection('items')
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      debugPrint('Error deleting all notifications: $e');
    }
  }

  /// الحصول على عدد الإشعارات غير المقروءة
  static Future<int> getUnreadCount(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(collectionNotifications)
          .doc(userId)
          .collection('items')
          .where('isRead', isEqualTo: false)
          .get();

      return snapshot.size;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  /// إرسال إشعار تحويل كبير
  static Future<void> sendLargeTransferAlert({
    required String userId,
    required double amount,
    required String currency,
    required String recipientName,
  }) async {
    await sendExtendedNotification(
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
  static Future<void> sendMonthlyReportNotification({
    required String userId,
    required String monthName,
    required double totalEarned,
    required double totalTransferred,
  }) async {
    await sendExtendedNotification(
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
  static Future<void> sendSecurityAlert({
    required String userId,
    required String alertMessage,
    required String severity, // low, medium, high
  }) async {
    await sendExtendedNotification(
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
  static Future<void> sendDailyRewardNotification({
    required String userId,
    required double rewardAmount,
  }) async {
    await sendExtendedNotification(
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
  static Future<void> sendTransferNotification({
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

    await sendExtendedNotification(
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

  /// تصفير الإشعارات القديمة (أكثر من 24 ساعة)
  static Future<void> clearOldNotifications(String userId) async {
    try {
      final twentyFourHoursAgo =
          DateTime.now().subtract(const Duration(hours: 24));

      final snapshot = await _firestore
          .collection(collectionNotifications)
          .doc(userId)
          .collection('items')
          .where('sentAt', isLessThan: twentyFourHoursAgo)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      debugPrint('تم تصفير ${snapshot.size} إشعار قديم للمستخدم $userId');
    } catch (e) {
      debugPrint('Error clearing old notifications: $e');
    }
  }

  /// تصفير جميع إشعارات المستخدم (لإعادة العداد)
  static Future<void> resetNotificationCounter(String userId) async {
    try {
      await _firestore
          .collection(collectionNotifications)
          .doc(userId)
          .collection('items')
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.update({'isRead': true});
        }
      });

      debugPrint('تم تصفير عداد الإشعارات للمستخدم $userId');
    } catch (e) {
      debugPrint('Error resetting notification counter: $e');
    }
  }

  // ==================== Enhanced Notification Methods ====================

  /// إرسال إشعار رسالة مع أزرار (رد، عرض)
  static Future<void> sendMessageNotification({
    required String userId,
    required String senderName,
    required String message,
    required String chatId,
    required String senderId,
    String? messageId,
  }) async {
    final data = EnhancedNotificationData.forMessage(
      chatId: chatId,
      userId: senderId,
      messageId: messageId,
    );

    await sendNotification(
      userId: userId,
      title: 'رسالة جديدة من $senderName',
      message: message,
      type: 'message',
      data: data.toMap(),
    );

    // Show notification with actions
    await NotificationRouterService.showNotificationWithActions(
      title: 'رسالة جديدة من $senderName',
      body: message,
      data: data,
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  /// إرسال إشعار طلب صداقة مع أزرار (قبول، رفض)
  static Future<void> sendFriendRequestNotification({
    required String userId,
    required String senderName,
    required String requestId,
  }) async {
    final data = EnhancedNotificationData.forFriendRequest(
      userId: userId,
      requestId: requestId,
    );

    await sendNotification(
      userId: userId,
      title: 'طلب صداقة جديد',
      message: '$senderName أرسل لك طلب صداقة',
      type: 'friendRequest',
      data: data.toMap(),
    );

    // Show notification with actions
    await NotificationRouterService.showNotificationWithActions(
      title: 'طلب صداقة جديد',
      body: '$senderName أرسل لك طلب صداقة',
      data: data,
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  /// إرسال إشعار إعجاب (تمييز كمقروء وإخفاء بعد النقر)
  static Future<void> sendLikeNotification({
    required String userId,
    required String likerName,
    required String targetId,
    required String targetType, // post, story
  }) async {
    final data = EnhancedNotificationData.forLike(
      userId: userId,
      targetId: targetId,
      targetType: targetType,
    );

    final targetLabel = targetType == 'post' ? 'منشور' : 'ستوري';

    await sendNotification(
      userId: userId,
      title: 'إعجاب جديد',
      message: '$likerName أعجب بـ $targetLabel',
      type: 'like',
      data: data.toMap(),
    );
  }

  /// إرسال إشعار معركة مع أزرار (دخول، خروج)
  static Future<void> sendBattleNotification({
    required String userId,
    required String roomName,
    required String roomId,
    required String battleId,
    String? battleName,
  }) async {
    final data = EnhancedNotificationData.forBattle(
      roomId: roomId,
      battleId: battleId,
    );

    await sendNotification(
      userId: userId,
      title: 'معركة جديدة!',
      message: battleName != null 
          ? '$battleName في $roomName'
          : 'معركة في $roomName',
      type: 'battle',
      data: data.toMap(),
    );

    // Show notification with actions
    await NotificationRouterService.showNotificationWithActions(
      title: 'معركة جديدة!',
      body: battleName != null 
          ? '$battleName في $roomName'
          : 'معركة في $roomName',
      data: data,
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  /// إرسال إشعار ستوري مع زر إلغاء
  static Future<void> sendStoryNotification({
    required String userId,
    required String authorName,
    required String storyId,
  }) async {
    final data = EnhancedNotificationData.forStory(
      storyId: storyId,
      userId: userId,
    );

    await sendNotification(
      userId: userId,
      title: 'ستوري جديد',
      message: '$authorName نشر ستوري جديد',
      type: 'story',
      data: data.toMap(),
    );

    // Show notification with cancel action (for author only)
    await NotificationRouterService.showNotificationWithActions(
      title: 'ستوري جديد',
      body: '$authorName نشر ستوري جديد',
      data: data,
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  /// إرسال إشعار منشور يومي مع زر إلغاء
  static Future<void> sendDailyPostNotification({
    required String userId,
    required String authorName,
    required String postId,
  }) async {
    final data = EnhancedNotificationData.forDailyPost(
      postId: postId,
      userId: userId,
    );

    await sendNotification(
      userId: userId,
      title: 'منشور يومي جديد',
      message: '$authorName نشر منشور يومي جديد',
      type: 'dailyPost',
      data: data.toMap(),
    );

    // Show notification with cancel action (for author only)
    await NotificationRouterService.showNotificationWithActions(
      title: 'منشور يومي جديد',
      body: '$authorName نشر منشور يومي جديد',
      data: data,
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }
}
