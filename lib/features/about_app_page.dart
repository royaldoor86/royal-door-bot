import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../app_theme.dart';
import '../services/ad_manager.dart';
import 'privacy_page.dart';
import 'terms_page.dart';
import 'user_agreement_page.dart';
import 'support_rate_page.dart';

class AboutAppPage extends StatefulWidget {
  const AboutAppPage({super.key});

  @override
  State<AboutAppPage> createState() => _AboutAppPageState();
}

class _AboutAppPageState extends State<AboutAppPage> {
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
          title: const Text('حول رويال دور',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: AppTheme.background(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Logo & Version Section
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(25),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.royalGold.withValues(alpha: 0.1),
                                border: Border.all(
                                    color: AppTheme.royalGold.withValues(alpha: 0.4),
                                    width: 2),
                                boxShadow: [
                                  BoxShadow(
                                      color: AppTheme.royalGold.withValues(alpha: 0.2),
                                      blurRadius: 40,
                                      spreadRadius: 5)
                                ],
                              ),
                              child: const Icon(Icons.shield_moon_rounded,
                                  size: 85, color: AppTheme.royalGold),
                            ),
                            const SizedBox(height: 25),
                            const Text(
                              'Royal Door',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                  fontFamily: 'Serif'),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.royalGold.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: AppTheme.royalGold.withValues(alpha: 0.2)),
                              ),
                              child: const Text(
                                'الإصدار 1.0.0 (نسخة الديوان الملكي)',
                                style: TextStyle(
                                    color: AppTheme.royalGold,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 35),

                      // Main Description Section
                      AppTheme.glassContainer(
                        padding: const EdgeInsets.all(20),
                        opacity: 0.07,
                        borderGlow: true,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "عن رويال دور",
                              style: TextStyle(
                                color: AppTheme.royalGold,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "تطبيق غرف صوتية وألعاب جماعية مصمم ليجمع الأصدقاء في جو ترفيهي ممتع، "
                              "مع نظام رومات، بروفايل متطور، وهدايا وتأثيرات جميلة داخل الغرفة.",
                              style: TextStyle(
                                  color: Colors.white, fontSize: 15, height: 1.6),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 15),
                              child: Divider(color: Colors.white10, thickness: 1),
                            ),
                            const Text(
                              "رويال دور هو أكثر من مجرد تطبيق اجتماعي؛ إنه منصة عالمية ملكية تجمع بين:",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 15),
                            _buildBulletPoint(
                                Icons.mic_external_on_rounded, "الغرف الصوتية للتواصل الفوري."),
                            _buildBulletPoint(
                                Icons.videogame_asset_rounded, "الألعاب التفاعلية لزيادة المتعة والمنافسة."),
                            _buildBulletPoint(Icons.card_giftcard_rounded,
                                "الهدايا الرقمية والإطارات المزخرفة لتعزيز الهوية الشخصية."),
                            _buildBulletPoint(Icons.auto_awesome_rounded,
                                "خلفيات وتصاميم فاخرة تمنح كل مستخدم إحساسًا بالتميز."),
                            const SizedBox(height: 15),
                            const Text(
                              "يهدف التطبيق إلى أن يكون جسرًا عالميًا يربط الأفراد من أكثر من 180 دولة، مع أكثر من 5 مليون عضو، في بيئة آمنة وخصوصية عالية.",
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  height: 1.5,
                                  fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Vision Section
                      AppTheme.glassContainer(
                        padding: const EdgeInsets.all(20),
                        opacity: 0.05,
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.track_changes_rounded,
                                    color: AppTheme.royalGold, size: 24),
                                SizedBox(width: 10),
                                Text(
                                  "🎯 رؤيتنا",
                                  style: TextStyle(
                                    color: AppTheme.royalGold,
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text(
                              "أن نصنع منصة اجتماعية راقية، حيث يلتقي الترف الملكي مع التقنية الحديثة، ليحصل كل مستخدم على تجربة لا مثيل لها في التواصل والترفيه.",
                              style: TextStyle(
                                  color: Colors.white, fontSize: 14, height: 1.6),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Founder Section
                      AppTheme.glassContainer(
                        padding: const EdgeInsets.all(20),
                        opacity: 0.05,
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "عني ؟",
                              style: TextStyle(
                                color: AppTheme.royalGold,
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              "أنا ، مؤسس ومصمم ومطور تطبيق رويال دور. شغفي هو الجمع بين الفخامة الرقمية و التقنيات الحديثة لصناعة منصات اجتماعية عالمية تمنح المستخدمين تجربة ملكية فريدة. خبرتي تشمل تصميم واجهات فاخرة، تطوير أنظمة تفاعلية، ودمج الألعاب والهدايا الرقمية داخل بيئة آمنة وخصوصية عالية.",
                              style: TextStyle(
                                  color: Colors.white, fontSize: 14, height: 1.6),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 25),

                      // Links List
                      AppTheme.glassContainer(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        opacity: 0.04,
                        child: Column(
                          children: [
                            _buildLinkTile(context, Icons.privacy_tip_outlined,
                                'سياسة الخصوصية', const PrivacyPage()),
                            _buildDivider(),
                            _buildLinkTile(context, Icons.gavel_rounded,
                                'شروط الاستخدام', const TermsPage()),
                            _buildDivider(),
                            _buildLinkTile(context, Icons.description_outlined,
                                'اتفاقية المستخدم', const UserAgreementPage()),
                            _buildDivider(),
                            _buildLinkTile(
                              context,
                              Icons.star_rate_rounded,
                              'قيمنا وادعمنا',
                              const SupportRatePage(),
                              url:
                                  'https://play.google.com/store/apps/details?id=com.royaldoor.live',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),
                      const Text(
                        'جميع الحقوق محفوظة لمنصة رويال دور © 2025',
                        style: TextStyle(
                            color: Colors.white24, fontSize: 12, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 40),
                    ],
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

  Widget _buildBulletPoint(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.royalGold.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.royalGold, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  color: Colors.white, fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Divider(color: Colors.white10, height: 1),
    );
  }

  Widget _buildLinkTile(
      BuildContext context, IconData icon, String title, Widget page,
      {String? url}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.royalGold.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.royalGold, size: 22),
      ),
      title: Text(title,
          style: const TextStyle(
              color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios,
          color: Colors.white24, size: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      onTap: () async {
        if (url != null) {
          final uri = Uri.parse(url);
          try {
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              // fallback or message
            }
          } catch (e) {
            debugPrint('Error launching URL: $e');
          }
        } else {
          // إظهار إعلان قبل الانتقال لصفحات الخصوصية والشروط
          AdManager().showInterstitialAd();
          Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        }
      },
    );
  }
}
