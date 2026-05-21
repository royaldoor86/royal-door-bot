import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'app_theme.dart';
import 'services/localization_service.dart';
import 'widgets/profile_with_frame.dart';
import 'services/fcm_service.dart';
import 'services/notifications_service.dart';
import 'services/ad_manager.dart';
import 'services/daily_login_service.dart';
import 'widgets/daily_reward_popup.dart';
import 'widgets/id_change_request_dialog.dart';

// Features
import 'features/profile/profile_page.dart';
import 'features/games/games_page.dart';
import 'features/chat/chat_page.dart';
import 'features/rooms/rooms_page.dart';
import 'features/diaries/diaries_page.dart';
import 'features/auth/welcome_screen.dart';
import 'features/auth/auth_page.dart';
import 'features/auth/login_page.dart';
import 'features/auth/signup_page.dart';
import 'features/auth/forgot_password_page.dart';


// Services
import 'services/auth_service.dart';
import 'services/rewards_service.dart';
import 'services/task_tracking_service.dart';
import 'services/preload_service.dart';

import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  // تفعيل خاصية التخزين المحلي لـ Firestore
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // تفعيل خاصية التخزين المحلي لقاعدة البيانات الآنية (للمباريات والدردشة)
  FirebaseDatabase.instance.setPersistenceEnabled(true);
  FirebaseDatabase.instance.setPersistenceCacheSizeBytes(100 * 1024 * 1024); // 100MB

  await initializeDateFormatting('ar', null);

  unawaited(FcmService.initialize());
  unawaited(AdManager().init());

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static void updateConfig(BuildContext context,
      {Locale? newLocale,
      bool? useRoyalTheme,
      bool? useLargeFont,
      ThemeMode? themeMode}) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    if (state != null) {
      state.updateConfig(
          newLocale: newLocale,
          useRoyalTheme: useRoyalTheme,
          useLargeFont: useLargeFont,
          themeMode: themeMode);
    }
  }

  static bool isRoyal(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()?._useRoyalTheme ?? false;
  static bool isLargeFont(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()?._useLargeFont ?? false;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('ar');
  bool _useRoyalTheme = false;
  bool _useLargeFont = false;
  ThemeMode _themeMode = ThemeMode.dark;

  void updateConfig(
      {Locale? newLocale,
      bool? useRoyalTheme,
      bool? useLargeFont,
      ThemeMode? themeMode}) {
    setState(() {
      if (newLocale != null) _locale = newLocale;
      if (useRoyalTheme != null) _useRoyalTheme = useRoyalTheme;
      if (useLargeFont != null) _useLargeFont = useLargeFont;
      if (themeMode != null) _themeMode = themeMode;
    });
  }

  @override
  void initState() {
    super.initState();
    TaskTrackingService().startTracking();
    // محاولة إظهار إعلان الفتح عند البدء الأول
    Future.delayed(const Duration(seconds: 2), () {
      AdManager().showAppOpenAdIfAvailable();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // بدء التحميل المسبق للأصول في الخلفية فور تشغيل التطبيق
      if (mounted) PreloadService().init(context);

      await NotificationsService.initLocalNotifications();
      if (!mounted) return;
      await NotificationsService.setupInteractedMessage(context);
      await FcmService.registerTokenForCurrentUser();

      try {
        await RewardsService().cleanupExpiredRewards();
      } catch (e) {
        debugPrint('Error cleaning up expired rewards: $e');
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        try {
          // المعالجة عند تشغيل التطبيق تكون تلقائية فقط لحساب الأيام الفائتة
          await RewardsService().processDueDailyRewardsForUser(currentUser.uid,
              isManualActivation: false, adWatched: false);
        } catch (e) {
          debugPrint('Error processing due daily rewards: $e');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Provider<AuthService>(
      create: (_) => AuthService(),
      child: MaterialApp(
        navigatorKey: NotificationsService.navigatorKey,
        title: 'Royale Dur',
        debugShowCheckedModeBanner: false,
        locale: _locale,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ar'), Locale('en')],
        themeMode: _locale.languageCode == 'ar' ? ThemeMode.dark : _themeMode,
        theme:
            AppTheme.themeData(isRoyal: _useRoyalTheme, mode: ThemeMode.light),
        darkTheme:
            AppTheme.themeData(isRoyal: _useRoyalTheme, mode: ThemeMode.dark),
        initialRoute: '/',
        routes: {
          '/': (context) => const WelcomeScreen(),
          '/auth': (context) => const AuthPage(),
          '/login': (context) => const LoginPage(),
          '/signup': (context) => const SignupPage(),
          '/forgot-password': (context) => const ForgotPasswordPage(),
          '/home': (context) =>
              const MaintenanceWrapper(child: MainNavigation()),
          '/preview_frame': (context) =>
              const Scaffold(body: Center(child: ProfileWithFrame())),
        },
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(_useLargeFont ? 1.12 : 1.0),
            ),
            child: child!,
          );
        },
      ),
    );
  }
}

class MaintenanceWrapper extends StatelessWidget {
  final Widget child;
  const MaintenanceWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('system_settings')
          .doc('global')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) return child;

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        if (data == null || !(data['isMaintenanceMode'] ?? false)) return child;

        final String message =
            data['maintenanceMessage'] ?? "نحن في صيانة دورية، نعود قريباً 👑";

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser?.uid)
              .get(),
          builder: (context, userSnap) {
            if (userSnap.hasData &&
                userSnap.data != null &&
                userSnap.data!.exists) {
              final userData = userSnap.data!.data() as Map<String, dynamic>?;
              final role = userData?['role'] ?? 'user';
              bool isAdmin =
                  (role == 'admin' || role == 'owner' || role == 'developer');
              if (isAdmin) return child;
            }
            return _maintenanceScreen(message);
          },
        );
      },
    );
  }

  Widget _maintenanceScreen(String message) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1F1C),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.handyman_rounded,
                  size: 100, color: Color(0xFFD4AF37)),
              const SizedBox(height: 30),
              const Text(
                'عذراً، التطبيق في صيانة',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Text(message,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center),
              const SizedBox(height: 50),
              const CircularProgressIndicator(color: Color(0xFFD4AF37)),
            ],
          ),
        ),
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  StreamSubscription? _idRequestSub;

  static final List<Widget> _pages = <Widget>[
    const ProfilePage(),
    const RoyaleMatchPage(),
    const ChatsPage(),
    const VoiceRoomsPage(),
    const DiariesPage(),
  ];

  @override
  void initState() {
    super.initState();
    _checkDailyReward();
    _listenForIdRequests();
  }

  void _listenForIdRequests() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _idRequestSub = NotificationsService.notificationsStream(user.uid).listen((snapshot) {
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['type'] == 'royal_id_request' && data['read'] == false) {
          // إظهار الديالوج للطلب
          if (mounted) {
            IdChangeRequestDialog.show(context, data['data'], doc.id);
            // تعليم الإشعار كمقروء حتى لا يظهر مرة أخرى فوراً
            doc.reference.update({'read': true});
          }
        }
      }
    });
  }

  Future<void> _checkDailyReward() async {
    // ننتظر قليلاً حتى تكتمل واجهة المستخدم
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final isReady = await DailyLoginService.isRewardReady();
    if (isReady && mounted) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final streak = (doc.data()?['rewardStreak'] ?? 0) % 7;

        // جلب بيانات المكافأة التالية
        final List<Map<String, dynamic>> rewards = [
          {'day': '1', 'val': '500', 'type': 'coin'},
          {'day': '2', 'val': '800', 'type': 'coin'},
          {'day': '3', 'val': '5', 'type': 'gem'},
          {'day': '4', 'val': '1000', 'type': 'coin'},
          {'day': '5', 'val': '1500', 'type': 'coin'},
          {'day': '6', 'val': '2000', 'type': 'coin'},
          {'day': '7', 'val': '2000 نجمة ⭐ + 10 جواهر', 'type': 'mixed'},
        ];

        if (mounted) {
          DailyRewardPopup.show(context, rewards[streak]);
        }
      }
    }
  }

  @override
  void dispose() {
    _idRequestSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isRoyal = MyApp.isRoyal(context);
    bool isLight = Theme.of(context).brightness == Brightness.light;
    final trans = Translations.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
              top: BorderSide(
                  color: (isRoyal ? AppTheme.royalPink : AppTheme.royalGold)
                      .withAlpha(26),
                  width: 0.5)),
        ),
        child: BottomNavigationBar(
          backgroundColor: isLight
              ? Colors.white
              : (isRoyal ? const Color(0xFF1A051A) : const Color(0xFF020617)),
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          selectedItemColor: isRoyal ? AppTheme.royalPink : AppTheme.royalGold,
          unselectedItemColor: isLight ? Colors.black38 : Colors.white24,
          selectedLabelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          onTap: (i) => setState(() => _selectedIndex = i),
          items: [
            BottomNavigationBarItem(
                icon: const Icon(Icons.person_outline),
                activeIcon: const Icon(Icons.person),
                label: trans.get('profile')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.stars_outlined),
                activeIcon: const Icon(Icons.stars),
                label: trans.get('games')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.chat_bubble_outline),
                activeIcon: const Icon(Icons.chat_bubble),
                label: trans.get('chats')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.explore_outlined),
                activeIcon: const Icon(Icons.explore),
                label: trans.get('rooms')),
            BottomNavigationBarItem(
                icon: const Icon(Icons.home_outlined),
                activeIcon: const Icon(Icons.home),
                label: trans.get('diaries')),
          ],
        ),
      ),
    );
  }
}
