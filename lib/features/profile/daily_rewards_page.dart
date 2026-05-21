import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:confetti/confetti.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sensors_plus/sensors_plus.dart';
import '../../services/firestore_service.dart';
import '../../services/daily_login_service.dart';
import 'package:flutter/rendering.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:intl/intl.dart' as intl;
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/ad_manager.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class DailyRewardsPage extends StatefulWidget {
  const DailyRewardsPage({super.key});

  @override
  State<DailyRewardsPage> createState() => _DailyRewardsPageState();
}

class _DailyRewardsPageState extends State<DailyRewardsPage>
    with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late ConfettiController _confettiController;
  StreamSubscription<AccelerometerEvent>? _sensorSubscription;
  final GlobalKey _streakKey = GlobalKey();

  late AnimationController _glowController;
  late AnimationController _entryController;
  late AnimationController _pulseController;
  late AnimationController _shineController;
  late AnimationController _fireController;

  double _offsetX = 0;
  double _offsetY = 0;

  int _rawStreak = 0;
  bool _canClaim = false;
  bool _isSyncing = false;
  DateTime? _lastClaimedAt;

  BannerAd? _bannerAd;
  bool _isBannerLoaded = false;

  // Helpers to determine visual state
  int get _claimedCount {
    if (_rawStreak == 0) return 0;
    if (_canClaim) return _rawStreak % 7;
    return ((_rawStreak - 1) % 7) + 1;
  }

  int get _currentDayIndex {
    if (!_canClaim) return -1;
    return _rawStreak % 7;
  }

  final List<Map<String, dynamic>> rewards = [
    {'day': '1', 'val': '500', 'type': 'star'},
    {'day': '2', 'val': '800', 'type': 'star'},
    {'day': '3', 'val': '5', 'type': 'gem'},
    {'day': '4', 'val': '1000', 'type': 'star'},
    {'day': '5', 'val': '1500', 'type': 'star'},
    {'day': '6', 'val': '2000', 'type': 'star'},
  ];

  @override
  void initState() {
    super.initState();
    _glowController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);
    _entryController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..repeat();
    _shineController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();

    // إضافة اهتزازات خفيفة جداً عند تدوير الأيقونات لإعطاء شعور مادي (مثل حركة التروس)
    _shineController.addListener(() {
      // تفعيل اهتزاز "تكة" خفيفة عند كل ربع دورة للأيقونة
      if ((_shineController.value * 4).floor() !=
          ((_shineController.value - 0.03).clamp(0, 1) * 4).floor()) {
        HapticFeedback.selectionClick();
      }
    });

    _fireController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..repeat();

    // الاشتراك في بيانات حساس الحركة لتأثير الـ Parallax
    _sensorSubscription = accelerometerEventStream().listen((AccelerometerEvent event) {
      if (mounted) {
        setState(() {
          // ضبط الحساسية (Sensitivity) ومدى الحركة (Clamping)
          _offsetX = (event.x * -4).clamp(-25, 25);
          _offsetY = (event.y * 4).clamp(-25, 25);
        });
      }
    });

    _loadStatus();
    _loadBannerAd();
    _entryController.forward();
  }

  void _loadBannerAd() {
    _bannerAd = AdManager().getBannerAd(
      size: AdSize.banner,
      onAdLoaded: () => setState(() => _isBannerLoaded = true),
    );
  }

  Future<void> _loadStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final status = await _firestoreService.getDailyRewardStatus(user.uid);
        if (mounted) {
          setState(() {
            _rawStreak = status['streak'] ?? 0;
            final lastClaimed = status['lastClaimed'];
            _lastClaimedAt = lastClaimed?.toDate();

            if (_lastClaimedAt == null) {
              _canClaim = true;
            } else {
              final difference = DateTime.now().difference(_lastClaimedAt!);
              // Allow claim if more than 24 hours passed
              _canClaim = difference.inHours >= 24;
            }
          });
        }
      } catch (e) {
        debugPrint("Error loading status: $e");
      }
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _glowController.dispose();
    _entryController.dispose();
    _pulseController.dispose();
    _shineController.dispose();
    _fireController.dispose();
    _confettiController.dispose();
    _sensorSubscription?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  /// دالة مساعدة لتشغيل المؤثرات الصوتية
  Future<void> _playSound(String path) async {
    try {
      await _audioPlayer.play(AssetSource(path));
    } catch (e) {
      debugPrint("Error playing sound $path: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Transform.translate(
            offset: Offset(_offsetX, _offsetY),
            child: Transform.scale(
              scale: 1.15, // تكبير الصورة قليلاً لتغطية الحركة دون فراغات
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: _getBackgroundImage(),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.85),
                        const Color(0xFF1A0533).withValues(alpha: 0.95)
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: RepaintBoundary(
                      key: _streakKey,
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          _buildTitleSection(),
                          const SizedBox(height: 30),
                          _buildProgressInfo(),
                          const SizedBox(height: 30),
                          _buildRewardsGrid(),
                          const SizedBox(height: 25),
                          _buildDaySevenLuxuryCard(),
                          const SizedBox(height: 40),
                          _buildClaimButton(),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_isBannerLoaded)
                  Container(
                    color: Colors.black45,
                    width: _bannerAd!.size.width.toDouble(),
                    height: _bannerAd!.size.height.toDouble(),
                    child: AdWidget(ad: _bannerAd!),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider _getBackgroundImage() {
    const url =
        'https://img.freepik.com/free-vector/dark-purple-background-with-sparkles_23-2148395011.jpg';
    if (Uri.tryParse(url)?.host.isNotEmpty == true) {
      return const NetworkImage(url);
    }
    return const AssetImage(
        'assets/images/bg_placeholder.png'); // Fallback local asset
  }

  Future<void> _captureAndShareStreak() async {
    try {
      // الحصول على الكائن الرسومي من المفتاح
      RenderRepaintBoundary? boundary = 
          _streakKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      
      if (boundary == null) return;

      // 1. التقاط الصورة الأساسية
      ui.Image originalImage = await boundary.toImage(pixelRatio: 3.0);

      // الحصول على اسم المستخدم
      final user = FirebaseAuth.instance.currentUser;
      final String userName = user?.displayName ?? "مستكشف رويال";

      // الحصول على التاريخ الحالي وتنسيقه
      final String currentDate = 
          intl.DateFormat('yyyy/MM/dd').format(DateTime.now());

      // 2. تحميل شعار التطبيق كعلامة مائية
      final ByteData logoData = await rootBundle.load('assets/app/app_icon.png');
      final ui.Codec codec = await ui.instantiateImageCodec(logoData.buffer.asUint8List());
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      ui.Image watermarkLogo = frameInfo.image;

      // 3. إنشاء Canvas للدمج
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final paint = Paint();

      // رسم الصورة الأصلية
      canvas.drawImage(originalImage, Offset.zero, paint);

      // حساب موضع وأبعاد العلامة المائية (أسفل اليمين)
      const double padding = 60.0;
      const double logoWidth = 180.0; // عرض الشعار في الصورة
      double aspectRatio = watermarkLogo.width / watermarkLogo.height;
      double logoHeight = logoWidth / aspectRatio;

      double x = originalImage.width - logoWidth - padding;
      double y = originalImage.height - logoHeight - padding;

      // 4. رسم النص الترحيبي (اسم المستخدم)
      final textPainter = TextPainter(
        text: TextSpan(
          children: [
            TextSpan(
              text: 'بواسطة الملك: $userName\n',
              style: GoogleFonts.cairo(
                color: Colors.amber,
                fontSize: 45,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    blurRadius: 12,
                    color: Colors.black.withValues(alpha: 0.7),
                    offset: const Offset(3, 3),
                  ),
                ],
              ),
            ),
            TextSpan(
              text: 'التاريخ: $currentDate',
              style: GoogleFonts.cairo(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 32,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.left,
      );

      textPainter.layout();
      // رسم النص بجانب الشعار (على يساره)
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width - 20, y + (logoHeight / 2) - (textPainter.height / 2)),
      );

      // رسم العلامة المائية مع شفافية بسيطة لتكون احترافية
      paint.color = Colors.white.withValues(alpha: 0.8);
      canvas.drawImageRect(
        watermarkLogo,
        Rect.fromLTWH(0, 0, watermarkLogo.width.toDouble(), watermarkLogo.height.toDouble()),
        Rect.fromLTWH(x, y, logoWidth, logoHeight),
        paint,
      );

      // 5. إنتاج الصورة النهائية
      ui.Picture picture = recorder.endRecording();
      ui.Image finalImage = await picture.toImage(originalImage.width, originalImage.height);

      ByteData? byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // حفظ الصورة مؤقتاً
      final directory = await getTemporaryDirectory();
      final file = await File('${directory.path}/streak_share.png').create();
      await file.writeAsBytes(pngBytes);

      // فتح واجهة المشاركة
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'انظر إلى تقدمي في تطبيق رويال دور! 🔥 لقد حققت سلسلة مكافآت مذهلة! 👑✨',
      );
    } catch (e) {
      debugPrint("Error sharing streak: $e");
    }
  }

  Widget _buildProgressInfo() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.08),
            Colors.white.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.1),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildEnhancedInfoItem(
            'سلسلة الأيام',
            '$_rawStreak',
            Icons.local_fire_department,
            Colors.orange,
            _fireController,
          ),
          Container(
            width: 1,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white10,
                  Colors.amber.withValues(alpha: 0.3),
                  Colors.white10,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          _buildEnhancedInfoItem(
            'الحالة',
            _canClaim ? 'جاهز' : _getRemainingTime(),
            _canClaim ? Icons.check_circle : Icons.timer,
            _canClaim ? Colors.greenAccent : Colors.amber,
            _pulseController,
          ),
        ],
      ),
    );
  }

  String _getRemainingTime() {
    if (_lastClaimedAt == null) return "جاهز";
    final nextClaim = _lastClaimedAt!.add(const Duration(hours: 24));
    final diff = nextClaim.difference(DateTime.now());
    if (diff.isNegative) return "جاهز";
    return "${diff.inHours}س ${diff.inMinutes % 60}د";
  }

  Widget _buildEnhancedInfoItem(
    String label,
    String val,
    IconData icon,
    Color color,
    AnimationController controller,
  ) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            return Column(
              children: [
                Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ShaderMask(
                shaderCallback: (bounds) {
                  // Liquid Wave Effect using gradient offset
                  final waveOffset = math.sin(controller.value * 2 * math.pi) * 0.2;
                  return LinearGradient(
                    colors: [
                      color,
                      Colors.white.withValues(alpha: 0.9),
                      color,
                    ],
                    stops: [0.0, 0.5 + waveOffset, 1.0],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds);
                },
                child: Text(
                  val,
                  style: const TextStyle(
                    color: Colors.white, // Color is overridden by ShaderMask
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildAppBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.withValues(alpha: 0.1), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          bottom: BorderSide(
            color: Colors.amber.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // زر الإغلاق بتأثير hover
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 26),
                onPressed: () {
                  // اهتزاز خفيف عند الإغلاق
                  HapticFeedback.lightImpact();
                  _playSound('sounds/popup.mp3');
                  Navigator.pop(context);
                },
                tooltip: 'إغلاق',
              ),
            ),
            // العنوان بتاج ملكي وتدرج ذهبي
            Row(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) {
                    return const LinearGradient(
                      colors: [
                        Colors.amber,
                        Colors.yellow,
                        Colors.amber,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds);
                  },
                  child: const Text(
                    '👑',
                    style: TextStyle(fontSize: 28),
                  ),
                ),
                const SizedBox(width: 12),
                Shimmer.fromColors(
                  baseColor: Colors.amber,
                  highlightColor: Colors.yellow,
                  period: const Duration(milliseconds: 2000),
                  child: const Text(
                    'الكنز الملكي',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            // زر المشاركة الجديد
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
                border: Border.all(color: Colors.white10),
              ),
              child: IconButton(
                icon: const Icon(Icons.share_rounded, color: Colors.amber, size: 22),
                onPressed: () async {
                  HapticFeedback.mediumImpact();
                  await _captureAndShareStreak();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // حلقات دوارة ملونة
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.amber.withValues(
                          alpha: (0.3 *
                                  math.sin(
                                      _pulseController.value * 2 * math.pi))
                              .abs()
                              .clamp(0.1, 0.5)),
                      width: 2,
                    ),
                  ),
                );
              },
            ),
            // التوهج الخارجي
            AnimatedBuilder(
              animation: _glowController,
              builder: (context, child) {
                return Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(
                          alpha: (0.4 * _glowController.value).clamp(0.0, 1.0),
                        ),
                        blurRadius: 30,
                        spreadRadius: 15,
                      ),
                      BoxShadow(
                        color: Colors.yellow.withValues(
                          alpha: (0.2 * _glowController.value).clamp(0.0, 1.0),
                        ),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                );
              },
            ),
            // الأيقونة الرئيسية مع دوران
            Transform.rotate(
              angle: _shineController.value * 2 * math.pi,
              child: const Icon(Icons.stars, color: Colors.amber, size: 70),
            ),
            // جزيئات ساقطة
            const Positioned(
              top: 20,
              left: 30,
              child: Opacity(
                opacity: 0.6,
                child: Icon(
                  Icons.star_rounded,
                  color: Colors.yellow,
                  size: 20,
                ),
              ),
            ),
            const Positioned(
              bottom: 30,
              right: 25,
              child: Opacity(
                opacity: 0.5,
                child: Icon(
                  Icons.diamond,
                  color: Colors.amber,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 25),
        // نص بتأثير نبض
        AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1.0 +
                  (0.05 * math.sin(_pulseController.value * 2 * math.pi)).abs(),
              child: child,
            );
          },
          child: const Text(
            'استمر في الحضور يومياً لتحصل على جوائز أثمن',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
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
        childAspectRatio: 0.85,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        final reward = rewards[index];
        bool isClaimed = index < _claimedCount;
        bool isCurrent = index == _currentDayIndex;
        bool isLocked = !isClaimed && !isCurrent;

        return AnimatedBuilder(
          animation: _entryController,
          builder: (context, child) {
            final delay = index * 0.1;
            final animValue = Curves.easeOutBack.transform(
                math.max(0, math.min(1, (_entryController.value - delay) * 2)));
            return Transform.scale(
              scale: animValue,
              child: _buildRewardCard(reward, isClaimed, isCurrent, isLocked),
            );
          },
        );
      },
    );
  }

  Widget _buildRewardCard(Map<String, dynamic> reward, bool isClaimed,
      bool isCurrent, bool isLocked) {
    // Edge lighting color based on tilt
    final edgeColor = Color.lerp(
      Colors.white24,
      Colors.amber.withValues(alpha: 0.5),
      (_offsetX.abs() / 25).clamp(0, 1),
    )!;

    return AnimatedBuilder(
      animation: isCurrent ? _pulseController : const AlwaysStoppedAnimation(0.0),
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              if (isCurrent)
                BoxShadow(
                  color: Colors.amber.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 3,
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(
                sigmaX: isLocked ? 10 : 0,
                sigmaY: isLocked ? 10 : 0,
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isClaimed
                        ? [Colors.black54, Colors.black45]
                        : isCurrent
                            ? [
                                Colors.amber.withValues(alpha: 0.3),
                                Colors.yellow.withValues(alpha: 0.1),
                              ]
                            : [
                                Colors.white.withValues(alpha: 0.1),
                                Colors.white.withValues(alpha: 0.05),
                              ],
                  ),
                  border: Border.all(
                    color: isCurrent
                        ? Colors.amber
                        : isLocked
                            ? edgeColor // Dynamic Edge Lighting
                            : Colors.white24,
                    width: isCurrent ? 2.5 : 1.0,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'اليوم ${reward['day']}',
                          style: TextStyle(
                            color: isCurrent ? Colors.amber : Colors.white60,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Icon(
                          reward['type'] == 'gem' ? Icons.diamond : Icons.stars,
                          color: isLocked ? Colors.white10 : Colors.amber,
                          size: 32,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          reward['val'],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDaySevenLuxuryCard() {
    bool isClaimed = _claimedCount >= 7;
    bool isCurrent = _currentDayIndex == 6;
    bool isLocked = !isClaimed && !isCurrent;

    return AnimatedBuilder(
      animation: Listenable.merge([_glowController, _pulseController]),
      builder: (context, child) {
        final pulseScale = isCurrent
            ? 1.0 +
                (0.06 * math.sin(_pulseController.value * 2 * math.pi)).abs()
            : 1.0;

        return Transform.scale(
          scale: pulseScale,
          child: Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              gradient: isCurrent
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: const [
                        Color(0xFFE0E0E0), // Holographic Chrome Base
                        Color(0xFFB8860B),
                        Color(0xFFE0E0E0),
                      ],
                      stops: [
                        0.0,
                        (_shineController.value).clamp(0.0, 1.0),
                        1.0
                      ],
                    )
                  : null,
              color: isLocked ? Colors.white.withValues(alpha: 0.05) : null,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isCurrent
                    ? Colors.white
                    : isClaimed
                        ? Colors.greenAccent.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.15),
                width: isCurrent ? 2.5 : 1.5,
              ),
              boxShadow: [
                if (isCurrent)
                  BoxShadow(
                    color: Colors.amber.withValues(
                      alpha: (0.4 * _glowController.value).clamp(0.0, 1.0),
                    ),
                    blurRadius: 25,
                    spreadRadius: 8,
                  ),
                if (isCurrent)
                  BoxShadow(
                    color: Colors.yellow.withValues(alpha: 0.2),
                    blurRadius: 15,
                    spreadRadius: 3,
                  ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Holographic Shimmer Overlay
                if (isCurrent)
                  Positioned.fill(
                    child: ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          colors: [
                            Colors.cyanAccent.withValues(alpha: 0.2),
                            Colors.purpleAccent.withValues(alpha: 0.2),
                            Colors.yellowAccent.withValues(alpha: 0.2),
                          ],
                          begin: Alignment(
                              _offsetX / 25, -1), // Reactive to Gyroscope
                          end: Alignment(-_offsetX / 25, 1),
                        ).createShader(bounds);
                      },
                      blendMode: BlendMode.colorDodge,
                      child: Container(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                  ),

                // ستار ذهبي خلفي للحالة الحالية
                if (isCurrent)
                  Positioned(
                    right: -30,
                    top: -30,
                    child: Opacity(
                      opacity: 0.15,
                      child: Transform.rotate(
                        angle: _shineController.value * 2 * math.pi,
                        child: const Icon(
                          Icons.stars,
                          color: Colors.white,
                          size: 200,
                        ),
                      ),
                    ),
                  ),
                // المحتوى الرئيسي
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'الجائزة الكبرى 👑',
                      style: TextStyle(
                        color: isCurrent ? Colors.white : Colors.white54,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        letterSpacing: 1.0,
                        shadows: isCurrent
                            ? [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                )
                              ]
                            : [],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // الرموز الثلاثة مع حركة دوارة
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: isCurrent
                              ? _shineController
                              : const AlwaysStoppedAnimation(0.0),
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: isCurrent
                                  ? _shineController.value * 2 * math.pi
                                  : 0,
                              child: Icon(
                                Icons.diamond,
                                color: isLocked
                                    ? Colors.white10
                                    : Colors.cyanAccent,
                                size: 28,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 20),
                        AnimatedBuilder(
                          animation: isCurrent
                              ? _pulseController
                              : const AlwaysStoppedAnimation(0.0),
                          builder: (context, child) {
                            final scale = 1.0 +
                                (0.15 *
                                        math.sin(_pulseController.value *
                                            2 *
                                            math.pi))
                                    .abs();
                            return Transform.scale(
                              scale: scale,
                              child: Icon(
                                Icons.redeem,
                                size: 64,
                                color: isCurrent
                                    ? Colors.white
                                    : isLocked
                                        ? Colors.white10
                                        : Colors.amber,
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 20),
                        AnimatedBuilder(
                          animation: isCurrent
                              ? _shineController
                              : const AlwaysStoppedAnimation(0.0),
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: isCurrent
                                  ? -_shineController.value * 2 * math.pi
                                  : 0,
                              child: Icon(
                                Icons.stars_rounded,
                                color: isLocked ? Colors.white10 : Colors.amber,
                                size: 28,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // نص الجائزة
                    ShaderMask(
                      shaderCallback: (bounds) {
                        return const LinearGradient(
                          colors: [
                            Colors.amber,
                            Colors.yellow,
                            Colors.amber,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds);
                      },
                      child: Text(
                        '2000 نجمة ⭐ + 10 جواهر 💎',
                        style: TextStyle(
                          color: isCurrent ? Colors.white : Colors.white24,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                // رمز التحقق للمستلمة
                if (isClaimed)
                  Positioned(
                    top: 15,
                    right: 20,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.greenAccent,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.greenAccent.withValues(alpha: 0.5),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildClaimButton() {
    return AnimatedBuilder(
      animation: Listenable.merge([_shineController, _pulseController]),
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: 70,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(35),
            gradient: LinearGradient(
              colors: _canClaim
                  ? [
                      Colors.amber.withValues(alpha: 0.9),
                      Colors.yellow.withValues(alpha: 0.7)
                    ]
                  : [
                      Colors.white.withValues(alpha: 0.1),
                      Colors.white.withValues(alpha: 0.05)
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: _canClaim
                ? [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.yellow.withValues(alpha: 0.2),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ],
            border: Border.all(
              color: _canClaim
                  ? Colors.white.withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.1),
              width: 1.5,
            ),
          ),
          child: Stack(
            children: [
              // تأثير الشين المتحرك
              if (_canClaim)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(35),
                    child: Opacity(
                      opacity: 0.3,
                      child: Transform.translate(
                        offset: Offset(
                          (_shineController.value * 300) - 150,
                          0,
                        ),
                        child: Container(
                          width: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.white.withValues(alpha: 0.6),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              // محتوى الزر
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _canClaim && !_isSyncing
                      ? () async {
                          // اهتزاز متوسط عند الضغط للبدء
                          await HapticFeedback.mediumImpact();
                          setState(() => _isSyncing = true);
                          // تشغيل صوت النقر الملكي فوراً
                          _playSound('sounds/popup.mp3');
                          try {
                            final result =
                                await DailyLoginService.claimDailyLogin();
                            if (mounted) {
                              setState(() {
                                _canClaim = false;
                                _rawStreak =
                                    result['streak'] ?? (_rawStreak + 1);
                                _lastClaimedAt = DateTime.now();
                              });
                              // اهتزاز قوي أو رنة اهتزازية عند النجاح الفعلي
                              await HapticFeedback.vibrate();
                              // تشغيل صوت رنين العملات عند استلام المكافأة
                              _playSound('sounds/coins.mp3');
                              _showSuccessDialog(result['message'] ??
                                  'تم استلام الكنز الملكي بنجاح! 👑');
                              
                              // إظهار إعلان ملء الشاشة بعد استلام المكافأة
                              AdManager().showInterstitialAd();
                            }
                          } catch (e) {
                            String errorMsg = e.toString();
                            if (errorMsg.contains('already-exists')) {
                              errorMsg =
                                  'لقد استلمت مكافأة اليوم بالفعل. عُد غداً! 👑';
                            } else {
                              errorMsg = 'حدث خطأ: ${e.toString()}';
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(errorMsg),
                                  backgroundColor: Colors.redAccent),
                            );
                          } finally {
                            if (mounted) setState(() => _isSyncing = false);
                          }
                        }
                      : null,
                  borderRadius: BorderRadius.circular(35),
                  splashColor: Colors.white.withValues(alpha: 0.3),
                  highlightColor: Colors.white.withValues(alpha: 0.1),
                  child: Center(
                    child: _isSyncing
                        ? SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation(
                                _canClaim ? Colors.black : Colors.white38,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_canClaim)
                                Padding(
                                  padding: const EdgeInsets.only(right: 12.0),
                                  child: Transform.rotate(
                                    angle: _shineController.value * 2 * math.pi,
                                    child: const Icon(
                                      Icons.stars_rounded,
                                      color: Colors.black,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              Text(
                                _canClaim
                                    ? 'استلم الكنز الملكي 👑'
                                    : 'عد بعد ${_getRemainingTime()}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      _canClaim ? Colors.black : Colors.white38,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    // بدء انفجار القصاصات الورقية بمجرد استدعاء الحوار
    _confettiController.play();

    // تشغيل صوت النجاح الاحتفالي عند ظهور الحوار
    _playSound('sounds/success-fanfare-trumpets-6185.mp3');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setLocalState) {
          return PopScope(
            canPop: true,
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.amber.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.7),
                    ],
                    center: Alignment.center,
                  ),
                ),
                child: Dialog(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // الأيقونة الاحتفالية مع تأثير
                        TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Transform.rotate(
                              angle: value * 2 * math.pi * 0.5,
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.amber.withValues(
                                          alpha: 0.3 + (value * 0.2)),
                                      Colors.orange.withValues(
                                          alpha: 0.1 + (value * 0.1)),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber
                                          .withValues(alpha: 0.4 * value),
                                      blurRadius: 30,
                                      spreadRadius: 15,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.celebration,
                                  color: Colors.amber,
                                  size: 80,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 30),
                      // البطاقة الرئيسية
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutBack,
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, (1 - value) * 50),
                            child: Opacity(
                              opacity: value.clamp(0.0, 1.0),
                              child: child,
                            ),
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                const Color(0xFF2D0B5A).withValues(alpha: 0.9),
                                Colors.black.withValues(alpha: 0.9),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.amber.withValues(alpha: 0.5),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withValues(alpha: 0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) {
                                  return const LinearGradient(
                                    colors: [Colors.amber, Colors.yellow],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(bounds);
                                },
                                child: const Text(
                                  'مبروك! 👑',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                message,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  height: 1.5,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 30),
                              // زر الإغلاق
                              Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.amber, Colors.yellow],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.amber.withValues(alpha: 0.4),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () {
                                      // اهتزاز خفيف عند تأكيد استلام الجائزة
                                      HapticFeedback.lightImpact();
                                      _playSound('sounds/popup.mp3');
                                      _confettiController.stop();
                                      Navigator.pop(context);
                                    },
                                    borderRadius: BorderRadius.circular(20),
                                    splashColor:
                                        Colors.white.withValues(alpha: 0.3),
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 40,
                                        vertical: 14,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.check_circle,
                                              color: Colors.black, size: 22),
                                          SizedBox(width: 10),
                                          Text(
                                            'رائع!',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
      },
    ),
  );
}
}
