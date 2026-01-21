import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_theme.dart';

class SupportCenterPage extends StatefulWidget {
  const SupportCenterPage({super.key});

  @override
  State<SupportCenterPage> createState() => _SupportCenterPageState();
}

class _SupportCenterPageState extends State<SupportCenterPage> {
  // دالة موحدة لفتح الروابط
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تعذر فتح الرابط، يرجى المحاولة لاحقاً')),
          );
        }
      }
    } catch (e) {
      debugPrint("Error launching URL: $e");
    }
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
          title: const Text('مركز الدعم والديوان', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: AppTheme.background(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 30),
                _buildSupportHeader(),
                const SizedBox(height: 40),
                _buildSectionTitle('قنوات التواصل الملكية'),
                _buildSocialGrid(),
                const SizedBox(height: 40),
                _buildInfoCard(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSupportHeader() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.royalGold.withValues(alpha: 0.3), width: 2),
            boxShadow: [BoxShadow(color: AppTheme.royalGold.withValues(alpha: 0.1), blurRadius: 30)],
          ),
          child: const Icon(Icons.headset_mic_rounded, size: 60, color: AppTheme.royalGold),
        ),
        const SizedBox(height: 20),
        const Text('كيف يمكننا خدمتك اليوم؟', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const Text('فريق الدعم الملكي متواجد لخدمتك على مدار الساعة', style: TextStyle(color: Colors.white38, fontSize: 13)),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Text(title, style: const TextStyle(color: AppTheme.royalGold, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildSocialGrid() {
    return Column(
      children: [
        _buildSocialItem(
          icon: Icons.chat_rounded,
          title: 'واتساب الدعم المباشر',
          subtitle: '07770992966',
          color: Colors.green,
          onTap: () => _launchURL("https://wa.me/9647770992966"),
        ),
        _buildSocialItem(
          icon: Icons.facebook,
          title: 'صفحة فيسبوك الرسمية',
          subtitle: 'اخبار رويال دور أولاً بأول',
          color: Colors.blue.shade800,
          onTap: () => _launchURL("https://www.facebook.com/share/181HLY246h/"),
        ),
        _buildSocialItem(
          icon: Icons.camera_alt_rounded,
          title: 'انستغرام رويال دور',
          subtitle: '@royaldoor86',
          color: Colors.pinkAccent,
          onTap: () => _launchURL("https://www.instagram.com/royaldoor86?igsh=MXhnbTVhcXFjdWViMw=="),
        ),
        _buildSocialItem(
          icon: Icons.send_rounded,
          title: 'بوت التلغرام الملكي',
          subtitle: '@royaldoor_bot',
          color: Colors.blueAccent,
          onTap: () => _launchURL("https://t.me/royaldoor_bot"),
        ),
        _buildSocialItem(
          icon: Icons.video_collection_rounded,
          title: 'تيك توك رويال دور',
          subtitle: 'مقاطع وتحديات حصرية',
          color: Colors.white,
          onTap: () => _launchURL("https://tiktok.com/@royaldoor86"),
        ),
      ],
    );
  }

  Widget _buildSocialItem({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: AppTheme.glassContainer(
        padding: const EdgeInsets.all(5),
        opacity: 0.03,
        child: ListTile(
          onTap: onTap,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          subtitle: Text(subtitle, style: const TextStyle(color: Colors.white24, fontSize: 11)),
          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white10, size: 14),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return AppTheme.glassContainer(
      opacity: 0.05,
      child: const Column(
        children: [
          Icon(Icons.info_outline, color: AppTheme.royalGold, size: 30),
          SizedBox(height: 10),
          Text(
            'تنبيه ملكي: لا يطلب موظفو الدعم الفني كلمات المرور الخاصة بك أبداً. يرجى الحفاظ على أمان حسابك.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}
