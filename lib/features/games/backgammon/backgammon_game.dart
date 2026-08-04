import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart' show rootBundle, SystemChrome, DeviceOrientation;

class BackgammonGame extends StatefulWidget {
  const BackgammonGame({super.key});

  @override
  State<BackgammonGame> createState() => _BackgammonGameState();
}

class _BackgammonGameState extends State<BackgammonGame> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasPaid = false;
  bool _isLoadingUserData = true;
  int _entryFee = 50; // تكلفة الدخول بالجواهر
  int _userGems = 0;
  int _userCoins = 0;

  @override
  void initState() {
    super.initState();
    // Force landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _checkPaymentStatus();
    _initWebView();
  }

  @override
  void dispose() {
    // Reset to portrait orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  Future<void> _checkPaymentStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isLoadingUserData = false;
      });
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        
        // Parse gems and coins safely
        int parseGems(dynamic value) {
          if (value == null) return 0;
          if (value is num) return value.toInt();
          if (value is String) return int.tryParse(value) ?? 0;
          return 0;
        }

        setState(() {
          _userGems = parseGems(data['gems']);
          _userCoins = parseGems(data['coins'] ?? data['stars']);
          _isLoadingUserData = false;
        });
      } else {
        setState(() {
          _isLoadingUserData = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoadingUserData = false;
      });
    }
  }

  void _initWebView() async {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (error) {
            print('WebView Error: ${error.description} - ${error.errorType}');
          },
        ),
      );

    // Load the deployed version from GitHub Pages
    _controller.loadRequest(Uri.parse('https://royaldoor86.github.io/backgammon/'));
  }

  Future<void> _payWithGems() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_userGems < _entryFee) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ليس لديك جواهر كافية! 💎'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'gems': FieldValue.increment(-_entryFee),
      });

      setState(() {
        _hasPaid = true;
        _userGems -= _entryFee;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم الدفع بنجاح! ابدأ اللعب 🎲'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل الدفع: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _payWithCoins() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final coinFee = _entryFee * 10; // 1 جوهرة = 10 كوينز
    if (_userCoins < coinFee) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ليس لديك كوينز كافية! 🪙'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'coins': FieldValue.increment(-coinFee),
      });

      setState(() {
        _hasPaid = true;
        _userCoins -= coinFee;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم الدفع بنجاح! ابدأ اللعب 🎲'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل الدفع: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPaid) {
      return _buildPaymentScreen();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Container(
              color: Colors.black,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Color(0xFFFFD700),
                    ),
                    SizedBox(height: 20),
                    Text(
                      'جاري تحميل اللعبة...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Close button overlay
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentScreen() {
    if (_isLoadingUserData) {
      return Scaffold(
        backgroundColor: const Color(0xFF1A050E),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3D0B16), Color(0xFF1A050E)],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFFD700),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A050E),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF3D0B16), Color(0xFF1A050E)],
          ),
        ),
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
                      ),
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.casino,
                      size: 40,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'الطاولي الملكي',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'ادخل رسوم اللعب للبدء',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.diamond, color: Color(0xFF00E5FF), size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  'جواهرك: $_userGems',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  'كوينزك: $_userCoins',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: Colors.white24),
                        const SizedBox(height: 16),
                        const Text(
                          'تكلفة الدخول',
                          style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildPaymentOption(
                              icon: Icons.diamond,
                              label: '$_entryFee جوهرة',
                              color: const Color(0xFF00E5FF),
                              onTap: _payWithGems,
                            ),
                            _buildPaymentOption(
                              icon: Icons.monetization_on,
                              label: '${_entryFee * 10} كوينز',
                              color: const Color(0xFFFFD700),
                              onTap: _payWithCoins,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'إلغاء',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.2),
              color.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
