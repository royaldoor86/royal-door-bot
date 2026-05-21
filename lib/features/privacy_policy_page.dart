import 'package:flutter/material.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سياسة الخصوصية'),
        centerTitle: true,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'التزام الخصوصية',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple),
            ),
            SizedBox(height: 12),
            Text(
              'تطبيق Royal Door يحترم خصوصيتك ويعمل بموجب متطلبات Google Play بشأن الشفافية وحماية البيانات.',
              style: TextStyle(height: 1.6),
            ),
            SizedBox(height: 24),
            Text(
              '1. البيانات التي نجمعها',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '''- معلومات الحساب: الاسم، البريد الإلكتروني، صورة الملف الشخصي، ورقم الهاتف عند التحقق.
- محتوى المستخدم: الرسائل، الصور، الفيديو، الصوت، والمشاركات داخل التطبيق.
- بيانات الجهاز: نوع الجهاز، نظام التشغيل، اللغة، إصدار التطبيق.
- بيانات الاستخدام: تفاعلك مع الغرف، الرسائل، الألعاب، الميزات، وأداء التطبيق.
- بيوت الدعم والمجتمعات: قد يتم مشاركة معرفك الملكي (Royal ID) مع قادة بيوت الدعم لغرض التوجيه الفني وإدارة الفعاليات داخل التطبيق.
- بيانات التتبع والتحليل: معرف الإعلان، التفاعل مع الإعلانات، وقياس أداء التطبيق.''',
              style: TextStyle(height: 1.6),
            ),
            SizedBox(height: 24),
            Text(
              '2. كيف نستخدم البيانات',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '''- لتشغيل التطبيق والخدمات الأساسية مثل الغرف الصوتية والمكالمات والدردشة.
- لإدارة الحساب والمصادقة.
- لدعم نمو المجتمع عبر "بيوت الدعم الملكية" المعتمدة.
- لإرسال الإشعارات والعروض.
- لتحسين جودة التطبيق وتطوير المزايا.
- لحماية المستخدمين والتعامل مع السلوك المسيء أو الاحتيالي.''',
              style: TextStyle(height: 1.6),
            ),
            SizedBox(height: 24),
            Text(
              '3. الجهات الخارجية',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'يُستخدم التطبيق خدمات Firebase وGoogle AdMob ومزودي خدمات ضروريين آخرين لتشغيل التحليلات والإشعارات والتخزين. تُستخدم البيانات معهم فقط لدعم وظائف التطبيق، ولا نبيع بيانات المستخدمين.',
              style: TextStyle(height: 1.6),
            ),
            SizedBox(height: 24),
            Text(
              '4. الأذونات',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '''- الكاميرا والميكروفون: لتشغيل المكالمات الصوتية والفيديو داخل التطبيق.
- الصور والفيديو: لتحميل وعرض المحتوى داخل الحساب.
- الإشعارات: لتلقي التنبيهات والعروض.
- الإنترنت: لتشغيل التطبيق والتواصل مع الخادم.
- البلوتوث: لتحسين تجربة الصوت مع الأجهزة الخارجية عند الحاجة.''',
              style: TextStyle(height: 1.6),
            ),
            SizedBox(height: 24),
            Text(
              '5. أمن البيانات',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'نطبق إجراءات أمان لحماية بياناتك من الوصول غير المصرح به. نشارك البيانات فقط مع الجهات الضرورية لتشغيل التطبيق.',
              style: TextStyle(height: 1.6),
            ),
            SizedBox(height: 24),
            Text(
              '6. حقوق المستخدم',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '''- يمكنك طلب الاطلاع على بياناتك أو تعديلها.
- يمكنك طلب حذف بياناتك من التطبيق.
- يمكنك إيقاف الإشعارات من إعدادات التطبيق أو الجهاز.
- يمكنك تعطيل الإعلانات المخصصة عبر إعدادات Google إذا كانت متاحة.''',
              style: TextStyle(height: 1.6),
            ),
            SizedBox(height: 24),
            Text(
              '7. الأطفال',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'التطبيق غير مخصص للأطفال دون سن 13 عامًا. إذا كنت ولي أمر وتعتقد أن بيانات طفلٍ ما تم جمعها دون موافقتك، تواصل معنا لحذفها.',
              style: TextStyle(height: 1.6),
            ),
            SizedBox(height: 24),
            Text(
              '8. التحديثات',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'قد يتم تحديث سياسة الخصوصية هذه. آخر تحديث يظهر في أسفل الصفحة، واستمرارك في استخدام التطبيق يعني قبولك للإصدار الأخير.',
              style: TextStyle(height: 1.6),
            ),
            SizedBox(height: 24),
            Text(
              '9. حقوق إضافية للمستخدم (GDPR و القوانين الدولية)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'إذا كنت في الاتحاد الأوروبي أو دول أخرى لديها قوانين حماية بيانات صارمة، لك الحق في: الوصول الكامل للبيانات، التصحيح، الحذف، نقل البيانات، والاعتراض على المعالجة.',
              style: TextStyle(height: 1.6),
            ),
            SizedBox(height: 24),
            Text(
              '10. الاتصال بنا',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'البريد الإلكتروني: support@royaldoor.live\nالموقع الإلكتروني: www.royaldoor.live\nللاستفسارات عن الخصوصية والبيانات الشخصية، يرجى التواصل معنا عبر البريد الإلكتروني المذكور أعلاه.',
              style: TextStyle(height: 1.6, color: Colors.blue),
            ),
            SizedBox(height: 32),
            Center(
              child: Text(
                'آخر تحديث: أبريل 2026 | جميع الحقوق محفوظة © Royal Door',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
