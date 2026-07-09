import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../app_theme.dart';
import '../services/ad_manager.dart';

class TermsPage extends StatefulWidget {
  const TermsPage({super.key});

  @override
  State<TermsPage> createState() => _TermsPageState();
}

class _TermsPageState extends State<TermsPage> {
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
          title: const Text('شروط الاستخدام',
              style: TextStyle(color: Colors.white)),
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
                            'شروط الاستخدام',
                            style: TextStyle(
                              color: AppTheme.royalGold,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'باستخدام تطبيق Royal Door، فإنك توافق على الالتزام بشروط الاستخدام التالية. يُرجى قراءة هذه الشروط بعناية قبل الاستمرار في الاستخدام.',
                          textAlign: TextAlign.right,
                          style: TextStyle(color: Colors.white70, height: 1.5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          '١. أهلية الاستخدام',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'يجب أن يكون عمرك 13 عامًا أو أكثر لاستخدام التطبيق. إذا كنت تحت هذا العمر، يجب الحصول على موافقة ولي الأمر.',
                          textAlign: TextAlign.right,
                          style: TextStyle(color: Colors.white70, height: 1.5),
                        ),
                        SizedBox(height: 14),
                        Text(
                          '٢. سلوك المستخدم',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'يُمنع استخدام التطبيق لأي غرض غير قانوني أو لنشر المحتوى المسيء أو المخل بحقوق الآخرين. يجب احترام جميع المستخدمين داخل الغرف والمحادثات.',
                          textAlign: TextAlign.right,
                          style: TextStyle(color: Colors.white70, height: 1.5),
                        ),
                        SizedBox(height: 14),
                        Text(
                          '٣. المحتوى والمشاركة',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'أنت المسؤول عن أي محتوى تنشره أو ترسله داخل التطبيق. لا يجوز نشر المحتوى الذي ينتهك حقوق الملكية الفكرية أو الخصوصية أو القوانين المحلية.',
                          textAlign: TextAlign.right,
                          style: TextStyle(color: Colors.white70, height: 1.5),
                        ),
                        SizedBox(height: 14),
                        Text(
                          '٤. الحساب والأمان',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'أنت مسؤول عن الحفاظ على سرية بيانات حسابك. أي نشاط يحدث من خلال حسابك يُعتبر مسؤوليتك.',
                          textAlign: TextAlign.right,
                          style: TextStyle(color: Colors.white70, height: 1.5),
                        ),
                        SizedBox(height: 14),
                        Text(
                          '٥. المشتريات الداخلية',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'العملات الرقمية أو المزايا المشتراة داخل التطبيق غير قابلة للتحويل خارج النظام. أي عملية شراء تُنفذ عبر المتجر الرسمي تصبح نهائية بحسب سياسات المتجر.',
                          textAlign: TextAlign.right,
                          style: TextStyle(color: Colors.white70, height: 1.5),
                        ),
                        SizedBox(height: 14),
                        Text(
                          '٦. الإعلانات',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'قد يحتوي التطبيق على إعلانات من Google AdMob أو شركاء آخرين. عرض الإعلانات يخضع لسياساتهم، ويمكنك تعطيل الإعلانات المخصصة عبر إعدادات Google.',
                          textAlign: TextAlign.right,
                          style: TextStyle(color: Colors.white70, height: 1.5),
                        ),
                        SizedBox(height: 14),
                        Text(
                          '٧. التعليق أو الإنهاء',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'نحتفظ بالحق في تعليق أو إيقاف الحسابات التي تنتهك هذه الشروط أو التي تشكل خطرًا على المجتمع دون إشعار مسبق.',
                          textAlign: TextAlign.right,
                          style: TextStyle(color: Colors.white70, height: 1.5),
                        ),
                        SizedBox(height: 14),
                        Text(
                          '٨. التعديلات على الشروط',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'قد نجري تغييرات على هذه الشروط من وقت لآخر. استمرارك في استخدام التطبيق بعد التعديل يعني قبولك للشروط الجديدة.',
                          textAlign: TextAlign.right,
                          style: TextStyle(color: Colors.white70, height: 1.5),
                        ),
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
