import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'ui/animated_overlay_notification.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'app_theme.dart';

// Features
import 'package:flutter_application_1/features/profile/profile_page.dart';
import 'package:flutter_application_1/features/games/games_page.dart';
import 'package:flutter_application_1/features/chat/chat_page.dart';
import 'package:flutter_application_1/features/rooms/rooms_page.dart';
import 'package:flutter_application_1/features/diaries/diaries_page.dart';
import 'package:flutter_application_1/features/auth/welcome_screen.dart';
import 'package:flutter_application_1/features/auth/auth_page.dart';
import 'package:flutter_application_1/features/auth/login_page.dart';
import 'package:flutter_application_1/features/auth/signup_page.dart';

// Services
import 'package:flutter_application_1/services/auth_service.dart';
import 'package:flutter_application_1/services/user_bootstrap_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // إعادة الموديلات المفقودة لحل أخطاء صفحة الإعدادات والمظهر
  static void updateConfig(BuildContext context, {Locale? newLocale, bool? useRoyalTheme, bool? useLargeFont}) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    if (state != null) {
      state.updateConfig(newLocale: newLocale, useRoyalTheme: useRoyalTheme, useLargeFont: useLargeFont);
    }
  }

  static bool isRoyal(BuildContext context) => context.findAncestorStateOfType<_MyAppState>()?._useRoyalTheme ?? true;
  static bool isLargeFont(BuildContext context) => context.findAncestorStateOfType<_MyAppState>()?._useLargeFont ?? false;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('ar');
  bool _useRoyalTheme = true; // تفعيل الثيم الملكي افتراضياً
  bool _useLargeFont = false;

  void updateConfig({Locale? newLocale, bool? useRoyalTheme, bool? useLargeFont}) {
    setState(() {
      if (newLocale != null) _locale = newLocale;
      if (useRoyalTheme != null) _useRoyalTheme = useRoyalTheme;
      if (useLargeFont != null) _useLargeFont = useLargeFont;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Provider<AuthService>(
      create: (_) => AuthService(),
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Royale Dur',
        debugShowCheckedModeBanner: false,
        locale: _locale,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ar'), Locale('en')],
        theme: AppTheme.themeData(), // استخدام الثيم الأزرق الملكي الموحد
        initialRoute: '/',
        routes: {
          '/': (context) => const WelcomeScreen(),
          '/auth': (context) => const AuthPage(),
          '/login': (context) => const LoginPage(),
          '/signup': (context) => const SignupPage(),
          '/home': (context) => const MainNavigation(),
        },
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

  static final List<Widget> _pages = <Widget>[
    const ProfilePage(),
    const RoyaleMatchPage(),
    const ChatsPage(),
    const VoiceRoomsPage(),
    const DiariesPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.royalGold.withValues(alpha: 0.1), width: 0.5)),
        ),
        child: BottomNavigationBar(
          backgroundColor: AppTheme.backgroundBlack,
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          selectedItemColor: AppTheme.royalGold,
          unselectedItemColor: Colors.white24,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
          onTap: (i) => setState(() => _selectedIndex = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'بروفايل'),
            BottomNavigationBarItem(icon: Icon(Icons.stars_outlined), activeIcon: Icon(Icons.stars), label: 'الألعاب'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), activeIcon: Icon(Icons.chat_bubble), label: 'المحادثات'),
            BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore), label: 'الرومات'),
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'اليوميات'),
          ],
        ),
      ),
    );
  }
}
