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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'التزامنا بالخصوصية',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            SizedBox(height: 12),
            Text(
              'نحن في فريق Royal Door نولي أهمية قصوى لخصوصية بياناتك. توضح هذه السياسة كيفية جمعنا واستخدامنا وحمايتنا لمعلوماتك الشخصية عند استخدام تطبيقنا.',
              style: TextStyle(height: 1.6),
            ),
            SizedBox(height: 24),
            Text(
              '1. المعلومات التي نجمعها',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'نجمع المعلومات التي تقدمها لنا مباشرة عند إنشاء الحساب، مثل الاسم، البريد الإلكتروني، وصورة الملف الشخصي. كما نجمع بيانات تقنية حول استخدامك للتطبيق لتحسين جودة الخدمة.',
              style: TextStyle(height: 1.6),
            ),
            SizedBox(height: 24),
            Text(
              '2. كيفية استخدام البيانات',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'نستخدم بياناتك لتشغيل الغرف الصوتية، وتخصيص تجربتك داخل التطبيق، وإرسال تنبيهات حول التحديثات والفعاليات، ولضمان بيئة آمنة لجميع المستخدمين.',
              style: TextStyle(height: 1.6),
            ),
            SizedBox(height: 24),
            Text(
              '3. حماية البيانات',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'نطبق معايير أمان عالية لحماية معلوماتك من الوصول غير المصرح به. لا نقوم ببيع بياناتك الشخصية لأي أطراف ثالثة.',
              style: TextStyle(height: 1.6),
            ),
            SizedBox(height: 32),
            Center(
              child: Text(
                'آخر تحديث: يونيو 2024',
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
