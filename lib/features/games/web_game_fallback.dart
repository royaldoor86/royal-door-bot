import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Minimal safe fallback widget for web/desktop.
class WebGameFallback extends StatefulWidget {
  const WebGameFallback({super.key});

  @override
  State<WebGameFallback> createState() => _WebGameFallbackState();
}

class _WebGameFallbackState extends State<WebGameFallback> {
  int score = 0;
  int multiplier = 1;
  bool running = false;
  int gemsBalance = 0;
  Stream<DocumentSnapshot<Map<String, dynamic>>>? _userStream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _userStream = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots();
      _userStream!.listen((snap) {
        if (!mounted) return;
        final data = snap.data();
        setState(() {
          final raw = data?['gems'];
          if (raw is int) {
            gemsBalance = raw;
          } else if (raw is num) {
            gemsBalance = raw.toInt();
          } else {
            gemsBalance = 0;
          }
        });
      });
    }
  }

  void start() {
    setState(() {
      score = 0;
      running = true;
    });
  }

  void stop() {
    setState(() => running = false);
  }

  void tap() {
    if (!running) return;
    setState(() => score += multiplier);
  }

  Future<void> _startWithGem() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يرجى تسجيل الدخول للعب')));
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final userRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(userRef);
        final current = snap.data()?['gems'];
        final currentGems =
            current is int ? current : (current is num ? current.toInt() : 0);
        if (currentGems <= 0) throw Exception('Not enough gems');
        tx.update(userRef, {'gems': currentGems - 1});
      });
      if (!mounted) return;
      start();
    } catch (_) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
          const SnackBar(content: Text('لا يوجد رصيد كافٍ من الجواهر')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width.clamp(0.0, 600.0);
    return Center(
      child: Container(
        width: width * 0.95,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Web Game Fallback',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'This fallback runs when Unity is not available. Tap the button to start and use one gem.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.grade, color: Colors.amber),
                const SizedBox(width: 8),
                Text('الجواهر: $gemsBalance',
                    style: const TextStyle(color: Colors.white, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text('النقاط: $score',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: running ? tap : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                    ),
                    child: Text(
                        running ? 'اضغط للربح' : 'ابدأ (تخصم جوهرة واحدة)',
                        style: const TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: running ? stop : _startWithGem,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black),
                        child: Text(running ? 'إيقاف' : 'بدء'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () =>
                            setState(() => multiplier = (multiplier % 5) + 1),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white10,
                            foregroundColor: Colors.white),
                        child: Text('x$multiplier',
                            style: const TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
