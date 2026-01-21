import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../pages/admin/admin_payments_page.dart';
import '../../../gems_coins_page.dart';
import 'admin_special_ids_page.dart'; 
import 'admin_recharge_packages_page.dart';
import 'admin_bot_points_page.dart'; // استيراد الصفحة الجديدة

class AdminEconomyGrid extends StatelessWidget {
  const AdminEconomyGrid({Key? key}) : super(key: key);

  final Color bgColor = const Color(0xFF0A1F1C);
  final Color goldColor = const Color(0xFFD4AF37);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: const Color(0xFF051211),
          elevation: 0,
          title: Text('اقتصاد المملكة رويال', style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: GridView.count(
          padding: const EdgeInsets.all(20),
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          children: [
            _buildEconomyCard(context, 'طلبات الشحن', Icons.payments_rounded, Colors.greenAccent, const AdminPaymentsPage()),
            _buildEconomyCard(context, 'نقاط البوت', Icons.smart_toy_rounded, Colors.blueAccent, const AdminBotPointsPage()), // الأيقونة الجديدة
            _buildEconomyCard(context, 'باقات الجواهر', Icons.diamond_rounded, Colors.cyanAccent, const AdminRechargePackagesPage(initialType: 'gems')),
            _buildEconomyCard(context, 'باقات الكوينز', Icons.monetization_on_rounded, Colors.amberAccent, const AdminRechargePackagesPage(initialType: 'coins')),
            _buildEconomyCard(context, 'الآيدي المميز', Icons.badge_rounded, Colors.orangeAccent, const AdminSpecialIdsPage()),
            _buildEconomyCard(context, 'شحن يدوي', Icons.bolt_rounded, Colors.redAccent, const AdminPaymentsPage()),
          ],
        ),
      ),
    );
  }

  Widget _buildEconomyCard(BuildContext context, String title, IconData icon, Color color, Widget page) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 15),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
