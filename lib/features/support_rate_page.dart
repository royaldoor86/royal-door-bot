import 'package:flutter/material.dart';
import '../app_theme.dart';

class SupportRatePage extends StatelessWidget {
  const SupportRatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundBlack,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text("قيمنا وادعمنا", style: TextStyle(color: Colors.white)),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: AppTheme.background(
          child: Center(
            child: AppTheme.glassContainer(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(30),
              opacity: 0.05,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, size: 80, color: AppTheme.royalGold),
                  const SizedBox(height: 20),
                  const Text(
                    "هل تستمتع بـ رويال دور؟",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "دعمك لنا بالتقييم يساعدنا على تقديم الأفضل دائماً وتطوير ميزات ملكية جديدة تليق بك.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.royalGold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () {
                      // هنا يمكن إضافة رابط المتجر لاحقاً
                    },
                    icon: const Icon(Icons.rate_review_rounded),
                    label: const Text("قيمنا الآن على المتجر", style: TextStyle(fontWeight: FontWeight.bold)),
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
