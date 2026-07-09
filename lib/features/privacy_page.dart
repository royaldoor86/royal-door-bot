import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../app_theme.dart';
import '../services/ad_manager.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = AdManager().getBannerAd(
      size: AdSize.banner,
      onAdLoaded: () => setState(() => _isAdLoaded = true),
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundBlack,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'سياسة الخصوصية',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: AppTheme.background(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: AppTheme.glassContainer(
                    padding: const EdgeInsets.all(20),
                    opacity: 0.05,
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            'سياسة الخصوصية',
                            style: TextStyle(
                              color: AppTheme.royalGold,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 14),
                        Text(
                          'نحن في تطبيق Royal Door نلتزم بحماية خصوصيتك واتباع سياسات Google Play المتعلقة بالبيانات.',
                          textAlign: TextAlign.right,
                          style: TextStyle(color: Colors.white70, height: 1.5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          '• البيانات التي نجمعها:',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '''- معلومات الحساب: الاسم، البريد الإلكتروني، صورة الملف الشخصي، ورقم الهاتف عند التحقق.
- محتوى المستخدم: الرسائل، الصور، الفيديو، الصوت، والمشاركات داخل التطبيق.
- بيانات الجهاز: نوع الجهاز، نظام التشغيل، اللغة، إصدار التطبيق.
- بيانات الاستخدام: سلوكك داخل التطبيق، الغرف التي تدخلها، الرسائل التي ترسلها، والميزات التي تستخدمها.
- بيانات التحليلات والإعلانات: معرف الإعلان، التفاعل مع الإعلانات، وقياس أداء التطبيق.''',
                          textAlign: TextAlign.right,
                          style: TextStyle(color: Colors.white70, height: 1.5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          '• كيف نستخدم البيانات:',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '''- لتشغيل وظائف التطبيق الأساسية مثل الغرف الصوتية والمكالمات والدردشة.
- لإدارة الحساب وتسجيل الدخول والمصادقة.
- لإرسال الإشعارات والتنبيهات المتعلقة بالتحديثات والعروض.
- لتحسين جودة التطبيق وتطوير الميزات.
- لحماية التطبيق والمستخدمين من الإساءة والاحتيال.''',
                          textAlign: TextAlign.right,
                          style: TextStyle(color: Colors.white70, height: 1.5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          '• الطرف الثالث:',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'يستخدم التطبيق خدمات Firebase وGoogle AdMob ومزودي خدمات ضروريين آخرين لتشغيل التحليلات والإشعارات والتخزين. لا نشارك بياناتك إلا بما يخدم تشغيل التطبيق.',
                          textAlign: TextAlign.right,
                          style: TextStyle(color: Colors.white70, height: 1.5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          '• الأذونات:',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '''- الكاميرا والميكروفون: لتشغيل المكالمات الصوتية والفيديو داخل التطبيق.
- الصور والفيديو: لتحميل وعرض المحتوى داخل الحساب.
- الإشعارات: لتلقي التنبيهات والعروض.
- الإنترنت: لتشغيل التطبيق والتواصل مع الخادم.
- البلوتوث: لتحسين تجربة الصوت مع الأجهزة الخارجية عندما تدعم الميزة.''',
                          textAlign: TextAlign.right,
                          style: TextStyle(color: Colors.white70, height: 1.5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          '• حقوقك:',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '''- يمكنك طلب الاطلاع على بياناتك أو تعديلها.
- يمكنك طلب حذف بياناتك من التطبيق.
- يمكنك إيقاف الإشعارات من إعدادات التطبيق أو الجهاز.
- يمكنك تعطيل الإعلانات المخصصة من إعدادات Google إذا كانت متاحة.''',
                          textAlign: TextAlign.right,
                          style: TextStyle(color: Colors.white70, height: 1.5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          '• الأطفال:',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'التطبيق غير موجه للأطفال دون سن 13 عامًا. إذا كنت ولي أمر وتعتقد أن بيانات طفلٍ ما تم جمعها دون موافقتك، تواصل معنا لحذف تلك البيانات.',
                          textAlign: TextAlign.right,
                          style: TextStyle(color: Colors.white70, height: 1.5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          '• التحديثات:',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'قد يتم تعديل هذه السياسة من وقت لآخر. آخر تحديث يظهر في أسفل الصفحة، واستمرارك في استخدام التطبيق يعني قبولك بالإصدار الأخير.',
                          textAlign: TextAlign.right,
                          style: TextStyle(color: Colors.white70, height: 1.5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          '• التواصل:',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        _ContactEmail(),
                        SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'آخر تحديث: أبريل 2026',
                            style: TextStyle(color: Colors.white38, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_isAdLoaded)
                Container(
                  alignment: Alignment.center,
                  width: _bannerAd!.size.width.toDouble(),
                  height: _bannerAd!.size.height.toDouble(),
                  child: AdWidget(ad: _bannerAd!),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactEmail extends StatelessWidget {
  const _ContactEmail();

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final Uri websiteUri = Uri.parse('https://www.royaldoor.live');
        if (await canLaunchUrl(websiteUri)) {
          await launchUrl(websiteUri, mode: LaunchMode.externalApplication);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.royalGold.withValues(alpha: 0.3),
          ),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.language,
              color: AppTheme.royalGold,
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              'www.royaldoor.live',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: AppTheme.royalGold,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
