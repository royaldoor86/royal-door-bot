import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../app_theme.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

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
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: AppTheme.glassContainer(
                padding: const EdgeInsets.all(20),
                opacity: 0.05,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        'سياسة الخصوصية',
                        style: TextStyle(
                          color: AppTheme.royalGold,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'نحن نحترم خصوصيتك ونلتزم بحماية بياناتك. توضح هذه السياسة كيفية جمع معلوماتك واستخدامها داخل التطبيق.',
                      textAlign: TextAlign.right,
                      style: TextStyle(color: Colors.white70, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '• المعلومات التي يتم جمعها:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '- معلومات الحساب (الاسم – البريد – الصورة).\n'
                      '- بيانات الجهاز ونظام التشغيل.\n'
                      '- البيانات المتعلقة بالاستخدام (الغرف – الرسائل – الألعاب).',
                      textAlign: TextAlign.right,
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '• كيفية استخدام البيانات:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '- تحسين تجربة المستخدم.\n'
                      '- تطوير مزايا التطبيق.\n'
                      '- الحماية من الإساءة والاحتيال.',
                      textAlign: TextAlign.right,
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '• مشاركة البيانات:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'يتم مشاركة بياناتك فقط مع خدمات ضرورية مثل Firebase ولا يتم بيع بياناتك لأي طرف.',
                      textAlign: TextAlign.right,
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '• أمان البيانات:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'نستخدم تقنيات حماية حديثة لحماية بياناتك من أي وصول غير مصرح به.',
                      textAlign: TextAlign.right,
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '• للتواصل:',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _ContactEmail(),
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'آخر تحديث: 2025',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactEmail extends StatelessWidget {
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
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.royalGold.withOpacity(0.3),
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
