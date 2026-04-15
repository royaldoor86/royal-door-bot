import 'package:flutter/material.dart';
import '../app_theme.dart';

class UserAgreementPage extends StatelessWidget {
  const UserAgreementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundBlack,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('اتفاقية المستخدم',
              style: TextStyle(color: Colors.white)),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: AppTheme.background(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: AppTheme.glassContainer(
              padding: const EdgeInsets.all(18),
              opacity: 0.05,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'اتفاقية المستخدم',
                    style: TextStyle(
                      color: AppTheme.royalGold,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'باستخدامك تطبيق Royal Door، فإنك توافق على هذه الاتفاقية وتقر بأنك قرأت الشروط وفهمتها.',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 13, height: 1.5),
                    textAlign: TextAlign.right,
                  ),
                  SizedBox(height: 14),
                  Text(
                    '١. قبول الشروط',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  SizedBox(height: 6),
                  Text(
                    'باستخدام التطبيق، أنت توافق على الالتزام بالشروط والسياسات المطبقة، بما في ذلك سياسة الخصوصية وشروط الاستخدام.',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 13, height: 1.5),
                    textAlign: TextAlign.right,
                  ),
                  SizedBox(height: 14),
                  Text(
                    '٢. مسؤوليتك',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  SizedBox(height: 6),
                  Text(
                    'أنت مسؤول عن الحفاظ على سرية معلومات حسابك وعن أي نشاط يحدث من خلاله. إذا كنت تشتبه في اختراق حسابك، يجب التواصل معنا فورًا.',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 13, height: 1.5),
                    textAlign: TextAlign.right,
                  ),
                  SizedBox(height: 14),
                  Text(
                    '٣. المحتوى المتبادل',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  SizedBox(height: 6),
                  Text(
                    'يُحظر إرسال أو نشر أي محتوى يخالف القوانين أو يحرض على العنف أو الكراهية أو ينتهك حقوق الآخرين. التواصل غير اللائق قد يؤدي إلى تعليق الحساب.',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 13, height: 1.5),
                    textAlign: TextAlign.right,
                  ),
                  SizedBox(height: 14),
                  Text(
                    '٤. التعديلات',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  SizedBox(height: 6),
                  Text(
                    'يمكن لتطبيق Royal Door تعديل هذه الاتفاقية في أي وقت. ستصبح التعديلات سارية عند نشرها داخل التطبيق، واستمرارك في الاستخدام يعني قبولك بها.',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 13, height: 1.5),
                    textAlign: TextAlign.right,
                  ),
                  SizedBox(height: 14),
                  Text(
                    '٥. الحقوق والمسؤوليات',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  SizedBox(height: 6),
                  Text(
                    'لديك الحق في طلب الوصول لبياناتك الشخصية وتصحيحها وحذفها. نحن نلتزم بحماية خصوصيتك وفقاً للقوانين الدولية.',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 13, height: 1.5),
                    textAlign: TextAlign.right,
                  ),
                  SizedBox(height: 14),
                  Text(
                    '٦. الامتثال والقوانين',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  SizedBox(height: 6),
                  Text(
                    'يلتزم Royal Door بسياسات Google Play وقوانين حماية البيانات الدولية بما فيها GDPR. نحن نتعامل مع محتوى مخالف بحزم.',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 13, height: 1.5),
                    textAlign: TextAlign.right,
                  ),
                  SizedBox(height: 14),
                  Text(
                    '٧. التواصل بنا',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.right,
                  ),
                  SizedBox(height: 6),
                  Text(
                    'البريد الإلكتروني: support@royaldoor.live\nالموقع الإلكتروني: www.royaldoor.live\nللاستفسارات والدعم الفني، يرجى التواصل معنا من خلال القنوات المذكورة أعلاه.',
                    style: TextStyle(
                        color: Colors.blue, fontSize: 13, height: 1.5),
                    textAlign: TextAlign.right,
                  ),
                  SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'آخر تحديث: أبريل 2026 | © 2026 Royal Door - جميع الحقوق محفوظة',
                      style: TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
