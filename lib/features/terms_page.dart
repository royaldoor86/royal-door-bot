import 'package:flutter/material.dart';
import '../app_theme.dart';

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundBlack,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('شروط الاستخدام', style: TextStyle(color: Colors.white)),
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
                      'باستخدامك لتطبيقنا فإنك توافق على الالتزام بشروط الاستخدام التالية. '
                      'نرجو قراءة هذه الشروط بعناية قبل البدء في استخدام التطبيق.',
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
                    SizedBox(height: 4),
                    Text(
                      'يجب أن يكون عمرك 13 عامًا أو أكثر لاستخدام هذا التطبيق، '
                      'وفي حال كنت أصغر من ذلك يجب الحصول على إذن وليّ الأمر.',
                      textAlign: TextAlign.right,
                      style: TextStyle(color: Colors.white70),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '٢. السلوك المقبول',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'يُمنع استخدام التطبيق لأي غرض غير قانوني أو لمضايقة الآخرين أو الإساءة لهم، '
                      'كما يُمنع نشر المحتوى المسيء أو المخالف للقوانين المحلية.',
                      textAlign: TextAlign.right,
                      style: TextStyle(color: Colors.white70),
                    ),
                    SizedBox(height: 12),
                    Text(
                      '٣. إيقاف أو تقييد الحساب',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'يحتفظ فريق التطبيق بالحق في إيقاف أو حظر أي حساب يخالف الشروط بدون سابق إنذار.',
                      textAlign: TextAlign.right,
                      style: TextStyle(color: Colors.white70),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '٤. التعديلات على الشروط',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'قد نقوم بتحديث شروط الاستخدام من وقت لآخر، وسيتم اعتبار استمرارك في استخدام التطبيق موافقة على الشروط المحدَّثة.',
                      textAlign: TextAlign.right,
                      style: TextStyle(color: Colors.white70),
                    ),
                    SizedBox(height: 20),
                    Align(
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
