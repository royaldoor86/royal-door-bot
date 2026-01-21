import 'package:flutter/material.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('شروط الاستخدام'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'اتفاقية شروط الاستخدام',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple),
            ),
            SizedBox(height: 12),
            Text(
              'باستخدامك لتطبيق Global Social App، فإنك توافق على الالتزام بالشروط والقواعد الموضحة أدناه. يرجى قراءتها بعناية.',
              style: TextStyle(height: 1.6),
            ),
            SizedBox(height: 24),
            Text(
              '1. قواعد السلوك',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'يمنع استخدام التطبيق لإرسال أي محتوى مسيء، غير قانوني، أو ينتهك خصوصية الآخرين. يلتزم المستخدم باحترام جميع الأعضاء في الغرف الصوتية والمحادثات.',
              style: TextStyle(height: 1.6),
            ),
            SizedBox(height: 24),
            Text(
              '2. الحسابات والأمان',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'أنت مسؤول عن حماية بيانات حسابك وعن جميع الأنشطة التي تحدث من خلاله. يحق لنا تعليق أو حذف أي حساب ينتهك هذه الشروط.',
              style: TextStyle(height: 1.6),
            ),
            SizedBox(height: 24),
            Text(
              '3. المشتريات الرقمية',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'الجواهر والكوينز هي عملات رقمية داخل التطبيق ولا يمكن استبدالها بأموال حقيقية خارج النظام الرسمي للتطبيق.',
              style: TextStyle(height: 1.6),
            ),
            SizedBox(height: 24),
            Text(
              '4. التعديلات',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'نحتفظ بالحق في تحديث هذه الشروط في أي وقت. استمرارك في استخدام التطبيق يعني موافقتك على التعديلات الجديدة.',
              style: TextStyle(height: 1.6),
            ),
            SizedBox(height: 32),
            Center(
              child: Text(
                'فريق Royal Door - جميع الحقوق محفوظة',
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
