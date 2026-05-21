import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../features/rewards_page.dart';

// Service: إدارة الإشعارات (Push + سجل)
// ملاحظة: استقبال إشعارات FCM وعرضها محليًا يتم في main.dart عبر flutter_local_notifications.
// يمكن توسيع هذه الخدمة لاحقًا لمعالجة مخصصة أو منطق إضافي إذا لزم.
// Collection: notifications
// Cloud Function: sendPushNotification
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationsService {
  static final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      if (response.payload == 'rewards_daily' || response.payload == 'rewards_monthly' || response.payload == 'harvest_reminder') {
        navigatorKey.currentState?.push(MaterialPageRoute(builder: (_) => const RewardsPage()));
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
  }) async {
    try {
      // حفظ الإشعار في Firestore
      await _firestore
          .collection('notifications')
          .doc(userId)
          .collection('items')
          .add({
        'title': title,
        'message': message,
        'type': type,
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

    if (type == 'investment_ready' || type == 'rewards_ready') {
      navigator.push(MaterialPageRoute(builder: (_) => const RewardsPage()));
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

  /// جدولة تنبيه للحصاد القادم بعد 24 ساعة
  static Future<void> scheduleHarvestReminder() async {
    const androidDetails = AndroidNotificationDetails(
      'harvest_reminder_channel',
      'تذكير الحصاد الملكي',
      channelDescription: 'تذكير بموعد الحصاد اليومي للمكافآت',
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
        'حان وقت الحصاد الملكي! 👑',
        'مكافآتك اليومية جاهزة للاستلام الآن، لا تدعها تفوتك ✨',
        tz.TZDateTime.now(tz.local).add(const Duration(hours: 24)),
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'harvest_reminder',
      );
      debugPrint('تمت جدولة تذكير الحصاد بعد 24 ساعة');
    } catch (e) {
      debugPrint('خطأ في جدولة تذكير الحصاد: $e');
    }
  }
}
