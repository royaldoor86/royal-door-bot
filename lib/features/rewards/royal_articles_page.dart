import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/design_tokens.dart';
import '../../theme/reusable_widgets.dart';
import '../../theme/app_theme.dart';
import '../../services/task_tracking_service.dart';

class RoyalArticlesPage extends StatefulWidget {
  const RoyalArticlesPage({super.key});

  @override
  State<RoyalArticlesPage> createState() => _RoyalArticlesPageState();
}

class _RoyalArticlesPageState extends State<RoyalArticlesPage> {
  final List<Map<String, String>> _articles = [
    {
      'title': 'أسرار النجاح في عالم التجارة الإلكترونية',
      'content': 'التجارة الإلكترونية ليست مجرد بيع وشراء، بل هي فن بناء العلاقات مع العملاء...',
      'image': 'https://images.unsplash.com/photo-1556742044-3c52d6e88c62?q=80&w=500',
    },
    {
      'title': 'كيف تحافظ على تركيزك في عصر المشتتات',
      'content': 'في عالم مليء بالتنبيهات ووسائل التواصل الاجتماعي، أصبح التركيز عملة نادرة...',
      'image': 'https://images.unsplash.com/photo-1484480974693-6ca0a78fb36b?q=80&w=500',
    },
    {
      'title': 'مستقبل الذكاء الاصطناعي في حياتنا اليومية',
      'content': 'لم يعد الذكاء الاصطناعي مجرد خيال علمي، بل أصبح جزءاً لا يتجزأ من هواتفنا...',
      'image': 'https://images.unsplash.com/photo-1677442136019-21780ecad995?q=80&w=500',
    },
  ];

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
          title: const HeadingText('المقالات الملكية', color: Colors.white),
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: _articles.length,
          itemBuilder: (context, index) {
            final article = _articles[index];
            return _buildArticleCard(article);
          },
        ),
      ),
    );
  }

  Widget _buildArticleCard(Map<String, String> article) {
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
                      const BodyText('مكافأة القراءة: 50 ذهبية', color: DesignTokens.primaryGold, fontSize: 12),
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

  void _openArticleDetail(Map<String, String> article) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArticleDetailPage(article: article),
      ),
    );
  }
}

class ArticleDetailPage extends StatefulWidget {
  final Map<String, String> article;
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
      AppTheme.showSuccessSnackbar(context, 'تمت القراءة بنجاح! حصلت على 50 عملة ذهبية 🎉');
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
        color: _rewarded ? Colors.green.withOpacity(0.2) : Colors.amber.withOpacity(0.2),
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
