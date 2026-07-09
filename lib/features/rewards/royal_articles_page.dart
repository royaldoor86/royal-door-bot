import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../theme/reusable_widgets.dart';
import '../../theme/app_theme.dart';
import '../../services/ad_manager.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../services/task_tracking_service.dart';
import '../../services/global_news_service.dart';

class RoyalArticlesPage extends StatefulWidget {
  const RoyalArticlesPage({super.key});

  @override
  State<RoyalArticlesPage> createState() => _RoyalArticlesPageState();
}

class _RoyalArticlesPageState extends State<RoyalArticlesPage> {
  final GlobalNewsService _newsService = GlobalNewsService();
  List<dynamic> _items = []; // قائمة مختلطة (مقالات + إعلانات)
  bool _isLoading = true;
  NativeAd? _nativeAd;
  bool _isNativeAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadGlobalNews();
    _loadNativeAd();
  }

  void _loadNativeAd() {
    _nativeAd = AdManager().getNativeAd(
      onAdLoaded: () => setState(() => _isNativeAdLoaded = true),
      onAdFailed: (error) => debugPrint('Native Ad Failed: $error'),
    );
  }

  Future<void> _loadGlobalNews() async {
    final news = await _newsService.fetchGlobalArticles();
    if (mounted) {
      setState(() {
        _items = List.from(news);
        // حقن الإعلان المدمج في المركز الثالث
        if (news.length >= 3) {
          _items.insert(2, 'native_ad');
        }
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF08080E),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const HeadingText('المقالات العالمية 🌍', color: Colors.white),
          actions: [
            IconButton(icon: const Icon(Icons.refresh, color: Colors.amber), onPressed: _loadGlobalNews),
          ],
        ),
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.amber))
          : ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                if (item is String && item == 'native_ad') {
                  return _isNativeAdLoaded 
                    ? Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        height: 300,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: AdWidget(ad: _nativeAd!),
                      )
                    : const SizedBox.shrink();
                }
                return _buildArticleCard(item as Map<String, dynamic>);
              },
            ),
      ),
    );
  }

  Widget _buildArticleCard(Map<String, dynamic> article) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 15),
      child: InkWell(
        onTap: () => _openArticleDetail(article),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                article['image']!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BodyText(article['title']!, fontWeight: FontWeight.bold, fontSize: 16),
                  const SizedBox(height: 10),
                  BodyText(article['content']!, maxLines: 2, color: Colors.white60),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const BodyText('مكافأة القراءة: 2 نجمة ⭐', color: DesignTokens.primaryGold, fontSize: 12),
                      RoyalButton(
                        label: 'اقرأ الآن',
                        onPressed: () => _openArticleDetail(article),
                        width: 80,
                        height: 30,
                        fontSize: 10,
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

  void _openArticleDetail(Map<String, dynamic> article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArticleDetailPage(article: article),
      ),
    );
  }
}

class ArticleDetailPage extends StatefulWidget {
  final Map<String, dynamic> article;
  const ArticleDetailPage({super.key, required this.article});

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  int _secondsRemaining = 30;
  Timer? _timer;
  bool _rewarded = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _timer?.cancel();
        _claimReward();
      }
    });
  }

  void _claimReward() {
    if (!_rewarded) {
      TaskTrackingService().completeArticleRead();
      setState(() => _rewarded = true);
      AppTheme.showSuccessSnackbar(context, 'تمت القراءة بنجاح! حصلت على 2 نجمة ملكية ⭐');
      
      // إظهار إعلان بيني (Interstitial) بعد إنهاء المقال لزيادة الربح
      AdManager().showInterstitialAd();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF08080E),
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 250,
              pinned: true,
              backgroundColor: const Color(0xFF0D0D14),
              flexibleSpace: FlexibleSpaceBar(
                background: Image.network(widget.article['image']!, fit: BoxFit.cover),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: HeadingText(widget.article['title']!, fontSize: 22)),
                        _buildTimerBadge(),
                      ],
                    ),
                    const SizedBox(height: 20),
                    BodyText(
                      widget.article['content']! * 20, // تكرار المحتوى لمحاكاة مقال طويل
                      fontSize: 16,
                      lineHeight: 1.8,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _rewarded ? Colors.green.withValues(alpha: 0.2) : Colors.amber.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _rewarded ? Colors.green : Colors.amber),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_rewarded ? Icons.check_circle : Icons.timer, 
               color: _rewarded ? Colors.green : Colors.amber, size: 16),
          const SizedBox(width: 5),
          BodyText(
            _rewarded ? 'تم الاستلام' : '$_secondsRemaining ثانية',
            color: _rewarded ? Colors.green : Colors.amber,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ],
      ),
    );
  }
}
