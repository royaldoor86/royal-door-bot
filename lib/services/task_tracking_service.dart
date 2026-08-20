import 'ad_manager.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'presence_service.dart';

class TaskTrackingService with WidgetsBindingObserver {
  static final TaskTrackingService _instance = TaskTrackingService._internal();
  factory TaskTrackingService() => _instance;
  TaskTrackingService._internal();

  Timer? _appUsageTimer;
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final PresenceService _presenceService = PresenceService();

  void startTracking() {
    WidgetsBinding.instance.addObserver(this);
    
    // بدء تتبع التواجد الحقيقي
    _presenceService.startTracking();
    
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _updateOnlineStatus(true);
      }
    });
    _updateOnlineStatus(true);
    _startSession();
  }

  void _startSession() {
    _appUsageTimer?.cancel();
    _appUsageTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _incrementWatchTime();
    });
  }

  void _stopSession() {
    _appUsageTimer?.cancel();
    _updateOnlineStatus(false);
    // إيقاف تتبع التواجد الحقيقي
    _presenceService.stopTracking();
  }

  Future<void> _updateOnlineStatus(bool isOnline) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _db.collection('users').doc(user.uid).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating online status: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updateOnlineStatus(true);
      _presenceService.startTracking(); // إعادة تشغيل التواجد الحقيقي
      _startSession();
      // إظهار إعلان فتح التطبيق عند العودة من الخلفية
      AdManager().showAppOpenAdIfAvailable();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.inactive) {
      _stopSession();
    }
  }

  Future<void> _incrementWatchTime() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // فحص الغش (VPN)
    if (await _isUsingVpn()) {
      debugPrint('Fraud detected: VPN usage');
      return;
    }

    final userDoc = await _db.collection('users').doc(user.uid).get();
    final data = userDoc.data() ?? {};

    // فحص النشاط السريع (Auto-clicker protection)
    if (_isTooFast(data['last_active_at'])) return;

    int currentMinutes = data['watch_minutes'] ?? 0;
    int nextMinutes = currentMinutes + 1;

    // جلب إعدادات المكافآت
    final settings =
        await _db.collection('admin_settings').doc('task_rewards').get();
    int stayRewardAmount = settings.data()?['stay_reward_per_15m'] ?? 100;

    // تطبيق ساعة الحظ (مضاعفة المكافأة)
    if (_isGoldenHour()) {
      stayRewardAmount *= 2;
    }

    Map<String, dynamic> updates = {
      'watch_minutes': FieldValue.increment(1),
      'last_active_at': FieldValue.serverTimestamp(),
    };

    // إذا أكمل 15 دقيقة، أعطه مكافأة تلقائية
    if (nextMinutes % 15 == 0) {
      updates['gold_stars'] = FieldValue.increment(stayRewardAmount);
    }

    await _db.collection('users').doc(user.uid).update(updates);
  }

  Future<void> recordActivity(String userId,
      {String? rewardType, int? rewardAmount}) async {
    final userDoc = await _db.collection('users').doc(userId).get();
    final data = userDoc.data() ?? {};
    int newCount = (data['total_activity_count'] ?? 0) + 1;
    int vaultProgress = (data['vault_progress'] ?? 0) + 1;

    Map<String, dynamic> updates = {
      'total_activity_count': FieldValue.increment(1),
      'vault_progress': FieldValue.increment(1),
    };

    // إضافة المكافأة المحددة إن وجدت
    if (rewardType != null && rewardAmount != null) {
      updates[rewardType] = FieldValue.increment(rewardAmount);
    }

    // بنك العملات (Savings Vault): كل 50 إعلان يحصل على 5 نقاط و 5 نجوم
    if (vaultProgress >= 50) {
      updates['points'] = FieldValue.increment(5);
      updates['stars'] = FieldValue.increment(5);
      updates['vault_progress'] = 0; // تصفير العداد
    }

    // كل 5 نشاطات (إعلان أو مقال) يحصل على خبرة XP
    if (newCount % 5 == 0) {
      updates['royalXP'] = FieldValue.increment(500);

      // إظهار إعلان ملء الشاشة عند تحقيق إنجاز نشاط
      AdManager().showInterstitialAd();
    }

    await _db.collection('users').doc(userId).update(updates);
  }

  bool _isGoldenHour() {
    final now = DateTime.now();
    // ساعة الحظ من 9 مساءً إلى 10 مساءً
    return now.hour >= 21 && now.hour < 22;
  }

  Future<bool> _isUsingVpn() async {
    // محاكاة كشف الـ VPN عبر التحقق من نوع الاتصال ومزود الخدمة
    // في الإنتاج يمكن استخدام باقات مخصصة أو فحص الـ Proxy
    return false;
  }

  bool _isTooFast(Timestamp? lastActive) {
    if (lastActive == null) return false;
    final diff = DateTime.now().difference(lastActive.toDate());
    return diff.inSeconds < 30; // منع النشاط الذي يتم في أقل من 30 ثانية
  }

  Future<void> completeArticleRead() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final settings =
        await _db.collection('admin_settings').doc('task_rewards').get();
    final int reward = settings.data()?['article_read_reward'] ??
        2; // المكافأة الافتراضية 2 كما في مركز المهام

    // تسجيل النشاط وإضافة نجوم المكافأة
    await recordActivity(user.uid, rewardType: 'stars', rewardAmount: reward);

    await _db.collection('users').doc(user.uid).update({
      'read_articles': FieldValue.increment(1),
    });
  }
}
