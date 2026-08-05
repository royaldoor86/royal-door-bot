import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import 'dart:convert';
import 'notification_router_service.dart';

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  static Future<void> initialize() async {
    // 1. Request permissions
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // 2. Initialize local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        if (details.payload != null) {
          final data = json.decode(details.payload!);
          
          // Check if this is an action button click
          if (details.actionId != null && details.actionId!.isNotEmpty) {
            NotificationRouterService.handleNotificationTap(
              data,
              action: details.actionId,
            );
          } else {
            _handleMessageClick(data);
          }
        }
      },
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 3. Try to register token multiple times if failed
    _tryRegisterToken();

    // 4. Foreground listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              importance: Importance.max,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
          payload: json.encode(message.data),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Use enhanced router for new notification types
      final type = message.data['type'];
      if (type != null && 
          ['message', 'friendRequest', 'like', 'battle', 'story', 'dailyPost']
              .contains(type)) {
        NotificationRouterService.handleNotificationTap(message.data);
      } else {
        _handleMessageClick(message.data);
      }
    });
  }

  static void _handleMessageClick(Map<String, dynamic> data) {
    debugPrint("Notification clicked with data: $data");
    // Legacy handling - can be removed once all notifications use enhanced format
  }

  static Future<void> _tryRegisterToken() async {
    for (int i = 0; i < 3; i++) {
      // محاولة 3 مرات في حال وجود ضعف إنترنت
      bool success = await registerTokenForCurrentUser();
      if (success) break;
      await Future.delayed(const Duration(seconds: 5));
    }
  }

  static Future<bool> registerTokenForCurrentUser() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        await _db.collection('users').doc(user.uid).set({
          'fcmToken': token,
          'lastTokenUpdate': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        debugPrint("👑 FCM SUCCESS: Token registered for ${user.uid}");
        return true;
      }
    } catch (e) {
      debugPrint("⚠️ FCM ERROR: Could not get token: $e");
    }
    return false;
  }

  static Future<void> unregisterTokenForCurrentUser() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await _db
          .collection('users')
          .doc(user.uid)
          .update({'fcmToken': FieldValue.delete()});
      await _messaging.deleteToken();
    } catch (_) {}
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important notifications.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  RemoteNotification? notification = message.notification;
  AndroidNotification? android = message.notification?.android;

  if (notification != null && android != null) {
    await flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        ),
      ),
    );
  }
}
