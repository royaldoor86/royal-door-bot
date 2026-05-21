import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class TaskTrackingService with WidgetsBindingObserver {
  static final TaskTrackingService _instance = TaskTrackingService._internal();
  factory TaskTrackingService() => _instance;
  TaskTrackingService._internal();

  Timer? _appUsageTimer;
  DateTime? _sessionStartTime;
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  void startTracking() {
    WidgetsBinding.instance.addObserver(this);
    _startSession();
  }

  void _startSession() {
    _sessionStartTime = DateTime.now();
    _appUsageTimer?.cancel();
    _appUsageTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _incrementWatchTime();
    });
  }

  void _stopSession() {
    _appUsageTimer?.cancel();
    _sessionStartTime = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startSession();
    } else if (state == AppLifecycleState.paused) {
      _stopSession();
    }
  }

  Future<void> _incrementWatchTime() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('users').doc(user.uid).update({
      'watch_minutes': FieldValue.increment(1),
      'last_active_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> completeArticleRead() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection('users').doc(user.uid).update({
      'read_articles': FieldValue.increment(1),
      'gold_coins': FieldValue.increment(50), // مكافأة قراءة مقال
    });
  }
}
