import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionTrackingService {
  static final SessionTrackingService _instance =
      SessionTrackingService._internal();
  factory SessionTrackingService() => _instance;
  SessionTrackingService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final Uuid _uuid = const Uuid();

  String? _sessionId;
  String? _deviceId;
  String? _deviceType;
  String? _deviceName;

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _deviceId = prefs.getString('device_id');

      if (_deviceId == null) {
        _deviceId = _uuid.v4();
        await prefs.setString('device_id', _deviceId!);
      }

      await _loadDeviceInfo();
      await _trackSession();
    } catch (e) {
      debugPrint('Error initializing session tracking: $e');
    }
  }

  Future<void> _loadDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        _deviceType = 'android';
        _deviceName = '${androidInfo.brand} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        _deviceType = 'ios';
        _deviceName = '${iosInfo.model} iOS ${iosInfo.systemVersion}';
      } else if (Platform.isWindows) {
        final windowsInfo = await _deviceInfo.windowsInfo;
        _deviceType = 'windows';
        _deviceName = 'Windows ${windowsInfo.productName}';
      } else if (Platform.isMacOS) {
        final macOsInfo = await _deviceInfo.macOsInfo;
        _deviceType = 'mac';
        _deviceName = 'Mac ${macOsInfo.model}';
      } else if (Platform.isLinux) {
        _deviceType = 'linux';
        _deviceName = 'Linux';
      } else {
        _deviceType = 'web';
        _deviceName = 'Web Browser';
      }
    } catch (e) {
      debugPrint('Error loading device info: $e');
      _deviceType = 'unknown';
      _deviceName = 'Unknown Device';
    }
  }

  Future<void> _trackSession() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final sessionId = _uuid.v4();
      _sessionId = sessionId;

      await _db
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .doc(sessionId)
          .set({
        'sessionId': sessionId,
        'deviceId': _deviceId,
        'deviceType': _deviceType,
        'deviceName': _deviceName,
        'location': 'Unknown', // Can be enhanced with geolocation
        'lastActive': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'isActive': true,
      });

      // Update user's last active timestamp
      await _db.collection('users').doc(user.uid).update({
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error tracking session: $e');
    }
  }

  Future<void> updateSessionActivity() async {
    try {
      final user = _auth.currentUser;
      if (user == null || _sessionId == null) return;

      await _db
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .doc(_sessionId)
          .update({
        'lastActive': FieldValue.serverTimestamp(),
      });

      // Update user's last active timestamp
      await _db.collection('users').doc(user.uid).update({
        'lastActive': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating session activity: $e');
    }
  }

  Future<void> endSession() async {
    try {
      final user = _auth.currentUser;
      if (user == null || _sessionId == null) return;

      await _db
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .doc(_sessionId)
          .update({
        'isActive': false,
        'lastActive': FieldValue.serverTimestamp(),
      });

      _sessionId = null;
    } catch (e) {
      debugPrint('Error ending session: $e');
    }
  }

  Future<void> cleanupOldSessions() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Delete sessions older than 30 days
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final oldSessions = await _db
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .where('lastActive', isLessThan: thirtyDaysAgo)
          .get();

      final batch = _db.batch();
      for (var doc in oldSessions.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error cleaning up old sessions: $e');
    }
  }

  Future<void> revokeSession(String sessionId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _db
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .doc(sessionId)
          .delete();
    } catch (e) {
      debugPrint('Error revoking session: $e');
    }
  }

  Future<void> revokeAllSessions() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final sessions = await _db
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .get();

      final batch = _db.batch();
      for (var doc in sessions.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Error revoking all sessions: $e');
    }
  }
}
