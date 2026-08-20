import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// خدمة التواجد الحقيقية - تعتمد على Firebase Realtime Database
/// توفر تتبعاً دقيقاً للحالة الفعلية للمستخدمين المتصلين
class PresenceService {
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;
  PresenceService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String? _currentUserId;
  DatabaseReference? _userStatusRef;
  Timer? _disconnectTimer;
  static const Duration _presenceTimeout = Duration(seconds: 30);

  /// بدء تتبع التواجد للمستخدم الحالي
  Future<void> startTracking() async {
    final user = _auth.currentUser;
    if (user == null) {
      debugPrint('Presence: No user logged in');
      return;
    }

    _currentUserId = user.uid;
    _userStatusRef = _database.child('presence').child(_currentUserId!);

    // الاستماع لتغييرات حالة المصادقة
    _auth.authStateChanges().listen((user) {
      if (user == null) {
        _setOffline();
      } else {
        _setOnline();
      }
    });

    // البدء بتعيين الحالة على الإنترنت
    await _setOnline();

    // إعداد اتصال على الانقطاع
    _setupOnDisconnect();

    debugPrint('Presence: Started tracking for user $_currentUserId');
  }

  /// إيقاف تتبع التواجد
  Future<void> stopTracking() async {
    await _setOffline();
    _currentUserId = null;
    _userStatusRef = null;
    _disconnectTimer?.cancel();
    debugPrint('Presence: Stopped tracking');
  }

  /// تعيين المستخدم على الإنترنت
  Future<void> _setOnline() async {
    if (_currentUserId == null || _userStatusRef == null) return;

    try {
      await _userStatusRef!.set({
        'online': true,
        'last_seen': ServerValue.timestamp,
        'user_id': _currentUserId,
      });
      
      // تحديث حالة كل دقيقة للحفاظ على الاتصال نشطاً
      _disconnectTimer?.cancel();
      _disconnectTimer = Timer.periodic(const Duration(seconds: 20), (_) {
        _heartbeat();
      });
      
      debugPrint('Presence: User $_currentUserId is now online');
    } catch (e) {
      debugPrint('Presence: Error setting online status: $e');
    }
  }

  /// تعيين المستخدم على غير متصل
  Future<void> _setOffline() async {
    if (_currentUserId == null || _userStatusRef == null) return;

    try {
      await _userStatusRef!.set({
        'online': false,
        'last_seen': ServerValue.timestamp,
        'user_id': _currentUserId,
      });
      
      _disconnectTimer?.cancel();
      debugPrint('Presence: User $_currentUserId is now offline');
    } catch (e) {
      debugPrint('Presence: Error setting offline status: $e');
    }
  }

  /// نبضات القلب للحفاظ على الاتصال نشطاً
  Future<void> _heartbeat() async {
    if (_currentUserId == null || _userStatusRef == null) return;

    try {
      await _userStatusRef!.update({
        'last_seen': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('Presence: Error sending heartbeat: $e');
    }
  }

  /// إعداد ما يحدث عند انقطاع الاتصال
  void _setupOnDisconnect() {
    if (_currentUserId == null || _userStatusRef == null) return;

    _userStatusRef!.onDisconnect().set({
      'online': false,
      'last_seen': ServerValue.timestamp,
      'user_id': _currentUserId,
    });

    debugPrint('Presence: On-disconnect handler set up');
  }

  /// الحصول على عدد المستخدمين المتصلين حالياً
  Stream<int> getOnlineUsersCount() {
    return _database
        .child('presence')
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return 0;

      int count = 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      data.forEach((key, value) {
        if (value is Map) {
          final online = value['online'] == true;
          final lastSeen = value['last_seen'] as int?;
          
          // نعتبر المستخدم متصلاً إذا كان على الإنترنت
          // أو كان آخر ظهور له خلال 30 ثانية
          if (online || (lastSeen != null && (now - lastSeen) < _presenceTimeout.inMilliseconds)) {
            count++;
          }
        }
      });

      return count;
    });
  }

  /// الحصول على قائمة المستخدمين المتصلين حالياً
  Stream<List<Map<String, dynamic>>> getOnlineUsers() {
    return _database
        .child('presence')
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return [];

      final List<Map<String, dynamic>> onlineUsers = [];
      final now = DateTime.now().millisecondsSinceEpoch;
      
      data.forEach((key, value) {
        if (value is Map) {
          final online = value['online'] == true;
          final lastSeen = value['last_seen'] as int?;
          final userId = value['user_id']?.toString();
          
          // نعتبر المستخدم متصلاً إذا كان على الإنترنت
          // أو كان آخر ظهور له خلال 30 ثانية
          if (online || (lastSeen != null && (now - lastSeen) < _presenceTimeout.inMilliseconds)) {
            if (userId != null && userId.isNotEmpty) {
              onlineUsers.add({
                'user_id': userId,
                'online': online,
                'last_seen': lastSeen,
              });
            }
          }
        }
      });

      return onlineUsers;
    });
  }

  /// التحقق مما إذا كان مستخدم معين متصلاً
  Stream<bool> isUserOnline(String userId) {
    return _database
        .child('presence')
        .child(userId)
        .onValue
        .map((event) {
      final data = event.snapshot.value as Map?;
      if (data == null) return false;

      final online = data['online'] == true;
      final lastSeen = data['last_seen'] as int?;
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // نعتبر المستخدم متصلاً إذا كان على الإنترنت
      // أو كان آخر ظهور له خلال 30 ثانية
      return online || (lastSeen != null && (now - lastSeen) < _presenceTimeout.inMilliseconds);
    });
  }

  /// تحديث حالة التواجد يدوياً (مفيد عند التبديل بين الغرف)
  Future<void> updateRoomStatus(String? roomId) async {
    if (_currentUserId == null || _userStatusRef == null) return;

    try {
      await _userStatusRef!.update({
        'current_room': roomId,
        'last_seen': ServerValue.timestamp,
      });
    } catch (e) {
      debugPrint('Presence: Error updating room status: $e');
    }
  }
}