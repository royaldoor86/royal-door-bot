import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/daily_login_service.dart';
import 'dart:math' as math;

class DailyRewardsPage extends StatefulWidget {
  const DailyRewardsPage({super.key});

  @override
  State<DailyRewardsPage> createState() => _DailyRewardsPageState();
}

class _DailyRewardsPageState extends State<DailyRewardsPage>
    with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();

  late AnimationController _glowController;
  late AnimationController _entryController;

  int _currentStreak = 0;
  bool _canClaim = false;
  bool _isSyncing = false;

  final List<Map<String, dynamic>> rewards = [
    {'day': '1', 'val': '500', 'type': 'coin'},
    {'day': '2', 'val': '800', 'type': 'coin'},
    {'day': '3', 'val': '5', 'type': 'gem'},
    {'day': '4', 'val': '1000', 'type': 'coin'},
    {'day': '5', 'val': '1500', 'type': 'coin'},
    {'day': '6', 'val': '2000', 'type': 'coin'},
  ];

  @override
  void initState() {
    super.initState();
    _glowController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _entryController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));

    _loadStatus();
    _entryController.forward();
  }

  Future<void> _loadStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final status = await _firestoreService.getDailyRewardStatus(user.uid);
        if (mounted) {
          setState(() {
            _currentStreak = status['streak'] ?? 0;
            final lastClaimed = status['lastClaimed'];
            _canClaim = lastClaimed == null ||
                DateTime.now().difference(lastClaimed.toDate()).inHours >= 24;
          });
        }
      } catch (e) {
        debugPrint("Error: $e");
      }
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
                'https://img.freepik.com/free-vector/dark-purple-background-with-sparkles_23-2148395011.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.8),
                const Color(0xFF2D0B5A).withOpacity(0.9)
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildTitleSection(),
                        const SizedBox(height: 40),
                        _buildRewardsGrid(),
                        const SizedBox(height: 30),
                        _buildDaySevenLuxuryCard(),
                        const SizedBox(height: 50),
                        _buildClaimButton(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context)),
          const Text('الكنز اليومي الملكي',
              style: TextStyle(
                  color: Colors.amber,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2)),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      children: [
        const Icon(Icons.stars, color: Colors.amber, size: 50),
        const SizedBox(height: 10),
        const Text(
          'افتح المكافأة كل 24 ساعة لرفع مستوى هيبتك',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildRewardsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.8,
        mainAxisSpacing: 15,
        crossAxisSpacing: 15,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        final reward = rewards[index];
        int status = (index < _currentStreak)
            ? 0
            : (index == _currentStreak && _canClaim ? 1 : 2);

        return AnimatedBuilder(
          animation: _entryController,
          builder: (context, child) {
            final delay = index * 0.1;
            final animValue = Curves.elasticOut.transform(
                math.max(0, math.min(1, (_entryController.value - delay) * 2)));
            return Transform.scale(
              scale: animValue,
              child: _buildRewardCard(reward, status),
            );
          },
        );
      },
    );
  }

  Widget _buildRewardCard(Map<String, dynamic> reward, int status) {
    bool isReady = status == 1;
    bool isClaimed = status == 0;

    return Container(
      decoration: BoxDecoration(
        color: isReady
            ? Colors.white.withOpacity(0.15)
            : Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isReady ? Colors.amber : Colors.white10,
          width: 2,
        ),
        boxShadow: isReady
            ? [
                BoxShadow(
                    color: Colors.amber.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 2)
              ]
            : [],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('اليوم ${reward['day']}',
                  style: TextStyle(
                      color: isReady ? Colors.amber : Colors.white38,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Icon(
                reward['type'] == 'gem' ? Icons.diamond : Icons.monetization_on,
                color: isReady
                    ? (reward['type'] == 'gem'
                        ? Colors.cyanAccent
                        : Colors.amber)
                    : Colors.white10,
                size: 35,
              ),
              const SizedBox(height: 5),
              Text(reward['val'],
                  style: TextStyle(
                      color: isReady ? Colors.white : Colors.white24,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ],
          ),
          if (isClaimed)
            const Positioned(
              child:
                  Icon(Icons.check_circle, color: Colors.greenAccent, size: 40),
            ),
        ],
      ),
    );
  }

  Widget _buildDaySevenLuxuryCard() {
    bool isReady = _currentStreak == 6 && _canClaim;
    bool isClaimed = _currentStreak > 6;

    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: 160,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isReady
                  ? [const Color(0xFFD4AF37), const Color(0xFFB8860B)]
                  : [
                      Colors.black.withOpacity(0.4),
                      Colors.black.withOpacity(0.2)
                    ],
            ),
            borderRadius: BorderRadius.circular(35),
            border: Border.all(
                color: isReady ? Colors.white : Colors.white10, width: 2),
            boxShadow: isReady
                ? [
                    BoxShadow(
                        color: Colors.amber
                            .withOpacity(0.3 * _glowController.value),
                        blurRadius: 20,
                        spreadRadius: 5)
                  ]
                : [],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isReady)
                const Positioned(
                  child: Icon(Icons.brightness_5,
                      color: Colors.white24, size: 200),
                ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('الجائزة الكبرى - اليوم 7',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.diamond,
                          color: Colors.cyanAccent, size: 30),
                      const SizedBox(width: 10),
                      Icon(Icons.redeem,
                          size: 70,
                          color: isReady ? Colors.white : Colors.white10),
                      const SizedBox(width: 10),
                      const Icon(Icons.monetization_on,
                          color: Colors.amber, size: 30),
                    ],
                  ),
                  const Text('2000 كوينز + 10 جواهر',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
              if (isClaimed)
                const Icon(Icons.check_circle,
                    color: Colors.greenAccent, size: 50),
            ],
          ),
        );
      },
    );
  }

  Widget _buildClaimButton() {
    return Container(
      width: double.infinity,
      height: 65,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(35),
        boxShadow: _canClaim
            ? [
                BoxShadow(
                    color: Colors.amber.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10))
              ]
            : [],
      ),
      child: ElevatedButton(
        onPressed: _canClaim
            ? () async {
                setState(() => _isSyncing = true);
                try {
                  final result = await DailyLoginService.claimDailyLogin();
                  if (mounted) {
                    setState(() {
                      _canClaim = false;
                      _currentStreak = result['streak'] ?? _currentStreak;
                    });
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content:
                            Text(result['message'] ?? 'تم استلام المكافأة!')),
                  );
                } catch (e) {
                  // تغيير الرسالة هنا لتكون واضحة وبدون كود برمجي
                  String errorMsg = e.toString();
                  if (errorMsg.contains('already-exists')) {
                    errorMsg = 'لقد استلمت مكافأة اليوم بالفعل. عُد غداً! 👑';
                  } else {
                    errorMsg = 'حدث خطأ بسيط، يرجى المحاولة لاحقاً.';
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(errorMsg), backgroundColor: Colors.orangeAccent),
                  );
                } finally {
                  if (mounted) setState(() => _isSyncing = false);
                }
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black,
          disabledBackgroundColor: Colors.white10,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(35)),
          elevation: 0,
        ),
        child: _isSyncing
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.black),
              )
            : Text(
                _canClaim ? 'استلم الكنز الآن' : 'عُد غداً للمزيد',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}
