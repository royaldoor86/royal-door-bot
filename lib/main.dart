import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app_theme.dart';
import 'services/localization_service.dart';
import 'widgets/profile_with_frame.dart';
import 'services/fcm_service.dart';
import 'services/notifications_service.dart';
import 'services/notification_router_service.dart';
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
import 'features/store_page.dart';
import 'features/gems_coins_page.dart';
import 'features/agent_dashboard_page.dart';
import 'features/admin/royal_panel/royal_admin_panel_page.dart';
import 'features/admin/royal_admin_panel_entry.dart';

// Services
import 'services/auth_service.dart';
import 'services/rewards_service.dart';
import 'services/task_tracking_service.dart';
import 'services/vip_expiry_service.dart';
import 'services/family_service.dart';
import 'services/telegram_bot_service.dart';
import 'services/telegram_web_app_service.dart';
// import 'widgets/banned_user_wrapper.dart'; // File not found

import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'dart:io' show Platform;

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تحميل متغيرات البيئة (اختياري)
  try {
    // محاولة تحميل assets/.env أولاً
    try {
      await dotenv.load(fileName: "assets/.env");
      debugPrint('✅ Environment variables loaded from assets/.env');
      debugPrint(
          '🔍 AGORA_APP_ID: ${dotenv.env['AGORA_APP_ID']?.substring(0, 8) ?? "NOT FOUND"}...');
    } catch (e) {
      // إذا فشل، حاول تحميل .env القديم
      await dotenv.load(fileName: ".env");

      debugPrint('✅ Environment variables loaded from .env');
    }
  } catch (e) {
    debugPrint('⚠️ Environment file not found, using default values: $e');
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set Firebase Auth persistence for web to handle OAuth redirects
  if (kIsWeb) {
    try {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
      debugPrint('✅ Firebase Auth persistence set to LOCAL for web');
    } catch (e) {
      debugPrint('⚠️ Error setting Firebase Auth persistence: $e');
    }
  }

  // تهيئة Telegram Web App - CRITICAL: Must be done before any routing
  debugPrint('🚀 Initializing Telegram Web App BEFORE routing...');
  await TelegramWebAppService.init();
  debugPrint('✅ Telegram Web App initialization completed');

  // تهيئة Firebase App Check
  try {
    if (!kIsWeb) {
      if (kReleaseMode) {
        await FirebaseAppCheck.instance.activate(
          providerAndroid: const AndroidPlayIntegrityProvider(),
          providerApple: const AppleAppAttestProvider(),
        );
      } else {
        final appCheckDebugToken =
            dotenv.env['FIREBASE_APP_CHECK_DEBUG_TOKEN'] ??
                '7EC16B69-02F8-4CC3-AF7F-CB818336D552';
        await FirebaseAppCheck.instance.activate(
          providerAndroid: AndroidDebugProvider(debugToken: appCheckDebugToken),
          providerApple: AppleDebugProvider(debugToken: appCheckDebugToken),
        );
        debugPrint('🛡️ App Check activated in Debug mode');
        debugPrint('🚀 App Check Debug Token: $appCheckDebugToken');
      }
      await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
    }
  } catch (e) {
    debugPrint('❌ App Check Activation Error: $e');
  }

  // تفعيل خاصية التخزين المحلي لـ Firestore
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // تفعيل خاصية التخزين المحلي لقاعدة البيانات الآنية (للمباريات والدردشة)
  if (!kIsWeb) {
    FirebaseDatabase.instance.setPersistenceEnabled(true);
    FirebaseDatabase.instance
        .setPersistenceCacheSizeBytes(100 * 1024 * 1024); // 100MB
  }

  await initializeDateFormatting('ar', null);

  // استخراج الـ Key Hash لفيسبوك
  if (!kIsWeb && Platform.isAndroid) {
    debugPrint(
        "💡 ملاحظة: إذا لم يظهر الـ Key Hash هنا، حاول تسجيل الدخول وسيظهر في الـ Logcat كرسالة خطأ من الفيسبوك.");
  }

  unawaited(FcmService.initialize());

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize Telegram Bot
  unawaited(TelegramBotService.instance.initialize());

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static bool isRoyal(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()?._useRoyalTheme ?? false;
  static bool isLargeFont(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()?._useLargeFont ?? false;
  static String getTheme(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()?._theme ?? 'royal';

  static void updateConfig(
    BuildContext context, {
    Locale? newLocale,
    bool? useRoyalTheme,
    bool? useLargeFont,
    ThemeMode? themeMode,
    String? theme,
  }) {
    context.findAncestorStateOfType<_MyAppState>()?._updateConfigInternal(
          newLocale: newLocale,
          useRoyalTheme: useRoyalTheme,
          useLargeFont: useLargeFont,
          themeMode: themeMode,
          theme: theme,
        );
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('ar');
  bool _useRoyalTheme = false;
  bool _useLargeFont = false;
  ThemeMode _themeMode = ThemeMode.dark;
  String _theme = 'royal';

  void _updateConfigInternal(
      {Locale? newLocale,
      bool? useRoyalTheme,
      bool? useLargeFont,
      ThemeMode? themeMode,
      String? theme}) {
    setState(() {
      if (newLocale != null) _locale = newLocale;
      if (useRoyalTheme != null) _useRoyalTheme = useRoyalTheme;
      if (useLargeFont != null) _useLargeFont = useLargeFont;
      if (themeMode != null) _themeMode = themeMode;
      if (theme != null) _theme = theme;
    });
  }

  @override
  void initState() {
    super.initState();
    TaskTrackingService().startTracking();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // CRITICAL: Ensure Telegram data is captured BEFORE any routing
      if (kIsWeb) {
        debugPrint('🚀🚀🚀 Post-frame callback: Re-initializing Telegram Web App to capture data');
        await TelegramWebAppService.init();
        debugPrint('✅ Telegram Web App re-initialized in post-frame callback');
      }

      // Handle OAuth redirect result on app startup for web
      if (kIsWeb) {
        try {
          final auth = FirebaseAuth.instance;
          final result = await auth.getRedirectResult();
          if (result.user != null) {
            debugPrint('✅ OAuth redirect result found on startup: ${result.user?.email}');
            // User is already signed in from redirect, no action needed
          }
        } catch (e) {
          debugPrint('⚠️ No OAuth redirect result on startup: $e');
        }
      }

      // بدء التحميل المسبق للأصول في الخلفية فور تشغيل التطبيق
      // تعطيل مؤقت لتجنب crash
      // if (mounted) PreloadService().init(context);

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
          // التحقق من انتهاء اشتراك VIP
          await VIPExpiryService.scheduleExpiryCheck();

          // حذف الدعوات المنتهية تلقائياً
          await FamilyService().cleanupExpiredInvitations();

          // تحميل إعدادات المظهر من Firestore
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();
          if (userDoc.exists && mounted) {
            final data = userDoc.data() as Map<String, dynamic>;
            final darkMode = data['darkMode'] ?? true;
            final fontSize = (data['fontSize'] ?? 16.0).toDouble();
            final theme = data['theme'] ?? 'royal';

            _updateConfigInternal(
              themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
              useLargeFont: fontSize > 16.0,
              useRoyalTheme: theme == 'royal',
              theme: theme,
            );
          }

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
        navigatorKey: NotificationRouterService.navigatorKey,
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
        theme: AppTheme.themeData(
            isRoyal: _useRoyalTheme, mode: ThemeMode.light, theme: _theme),
        darkTheme: AppTheme.themeData(
            isRoyal: _useRoyalTheme, mode: ThemeMode.dark, theme: _theme),
        initialRoute: '/',
        routes: {
          '/': (context) => const WelcomeScreen(),
          '/auth': (context) => const AuthPage(),
          '/login': (context) => const LoginPage(),
          '/signup': (context) => const SignupPage(),
          '/forgot-password': (context) => const ForgotPasswordPage(),
          '/home': (context) => const MaintenanceWrapper(child: MainNavigation()),
          '/preview_frame': (context) =>
              const Scaffold(body: Center(child: ProfileWithFrame())),
          // صفحات إضافية (بدون معاملات)
          '/store': (context) => const StorePage(),
          '/gems-coins': (context) => const GemsCoinsPage(),
          '/agent-dashboard': (context) => const AgentDashboardPage(),
          '/admin-panel': (context) => const RoyalAdminPanelEntry(),
        },
        builder: (context, child) {
          final originalPadding = MediaQuery.of(context).padding;
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(_useLargeFont ? 1.12 : 1.0),
              padding: EdgeInsets.only(
                top: originalPadding.top,
                bottom: originalPadding.bottom,
                left: originalPadding.left,
                right: (originalPadding.right - 11)
                    .clamp(0.0, originalPadding.right),
              ),
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
        final List<String> allowedEmails =
            List<String>.from(data['maintenanceAllowedEmails'] ?? []);

        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) return _maintenanceScreen(message);

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .snapshots(),
          builder: (context, userSnap) {
            // Check if user is the app owner by email
            if (currentUser.email == 'royaldoor86@gmail.com' ||
                currentUser.email == 'amjidhadi96@gmail.com' ||
                currentUser.email == 'shahadhadi.h@gmail.com') {
              return child;
            }

            // Check if user email is in allowed list
            if (currentUser.email != null &&
                allowedEmails.contains(currentUser.email)) {
              return child;
            }

            if (userSnap.hasData &&
                userSnap.data != null &&
                userSnap.data!.exists) {
              final userData = userSnap.data!.data() as Map<String, dynamic>?;
              final role = userData?['role'] ?? 'user';
              final bool isAdmin =
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

    _idRequestSub =
        NotificationsService.notificationsStream(user.uid).listen((snapshot) {
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
          {'day': '1', 'val': '500', 'type': 'star'},
          {'day': '2', 'val': '800', 'type': 'star'},
          {'day': '3', 'val': '5', 'type': 'gem'},
          {'day': '4', 'val': '1000', 'type': 'star'},
          {'day': '5', 'val': '1500', 'type': 'star'},
          {'day': '6', 'val': '2000', 'type': 'star'},
          {'day': '7', 'val': '2000 كوينز 🪙 + 10 جواهر', 'type': 'mixed'},
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
