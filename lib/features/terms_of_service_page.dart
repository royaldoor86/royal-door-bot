import 'package:flutter/material.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('شروط الخدمة'),
        centerTitle: true,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'شروط الخدمة',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple),
            ),
            SizedBox(height: 12),
            Text(
              'باستخدامك تطبيق Royal Door، فإنك توافق على الشروط التالية المتعلقة بالاستخدام، المحتوى، والأمان.',
              style: TextStyle(height: 1.6),
            ),
            SizedBox(height: 24),
            Text(
              '1. الاستخدام المقبول',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'التطبيق مخصص للاستخدام القانوني فقط. يُمنع نشر أو مشاركة أي محتوى مسيء، غير قانوني، أو ينتهك حقوق الآخرين.',
              style: TextStyle(height: 1.6),
            ),
            SizedBox(height: 24),
            Text(
              '2. مسؤولية الحساب',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'أنت مسؤول عن حماية بيانات حسابك وأي نشاط يتم من خلاله. يجب عليك إخطارنا فورًا عند الاشتباه بأي استخدام غير مصرح به.',
              style: TextStyle(height: 1.6),
            ),
            SizedBox(height: 24),
            Text(
              '3. المشتريات والعناصر الرقمية',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              '''جميع النجوم، الجواهر، والهدايا داخل رويال دور هي عناصر رقمية افتراضية (Virtual Items) مخصصة لتحسين التجربة الاجتماعية ودعم المنشئين.
- لا تملك هذه العناصر أي قيمة نقدية حقيقية خارج التطبيق.
- لا يمكن استبدال العناصر الرقمية بأموال نقدية أو بيعها خارج القنوات الرسمية.
- بيوت الدعم هي مراكز تطوعية لنمو المجتمع، ويُحظر أي تداول مالي غير رسمي من خلالها.''',
              style: TextStyle(height: 1.6),
            ),
            SizedBox(height: 24),
            Text(
              '4. الإعلانات وخدمات الطرف الثالث',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'قد يعرض التطبيق إعلانات أو يستخدم خدمات طرف ثالث. تعتمد هذه الخدمات على سياسات مستقلة، ونستخدمها فقط لتحسين تجربة التطبيق.',
              style: TextStyle(height: 1.6),
            ),
            SizedBox(height: 24),
            Text(
              '5. الحسابات والحظر',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'نحتفظ بالحق في إيقاف أو حذف أي حساب ينتهك هذه الشروط دون تحذير سابق. كل محاولة للالتفاف حول الحظر قد تؤدي إلى منع دائم.',
              style: TextStyle(height: 1.6),
            ),
            SizedBox(height: 24),
            Text(
              '6. التعديلات',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'نحتفظ بالحق في تعديل هذه الشروط في أي وقت. استمرارك في استخدام التطبيق بعد التحديث يعني قبولك للشروط الجديدة.',
              style: TextStyle(height: 1.6),
            ),
            SizedBox(height: 24),
            Text(
              '7. التنصل من المسؤولية',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'التطبيق يُوفّر بحالته الحالية. نحن لا نضمن خلو التطبيق من العيوب أو التوقفات المؤقتة. لا نتحمل مسؤولية الخسائر غير المباشرة الناتجة عن استخدام التطبيق.',
              style: TextStyle(height: 1.6),
            ),
            SizedBox(height: 24),
            Text(
              '8. القانون والاختصاص',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'تخضع هذه الشروط للقوانين السارية. أي نزاع يتم حله من خلال الطرق القانونية.',
              style: TextStyle(height: 1.6),
            ),
            SizedBox(height: 24),
            Text(
              '9. الاتصال بنا',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'البريد الإلكتروني: support@royaldoor.live\nالموقع الإلكتروني: www.royaldoor.live\nللدعم الفني والمساعدة، يرجى زيارة موقعنا أو التواصل عبر البريد الإلكتروني.',
              style: TextStyle(height: 1.6, color: Colors.blue),
            ),
            SizedBox(height: 32),
            Center(
              child: Text(
                'فريق Royal Door - جميع الحقوق محفوظة © 2026 | آخر تحديث: أبريل 2026',
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
