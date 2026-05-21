import 'package:flutter/material.dart';
import '../../../../pages/admin/admin_payments_page.dart';
import 'admin_special_ids_page.dart';
import 'admin_recharge_packages_page.dart';
import 'admin_rewards_wallet_mgmt_page.dart';
import 'admin_rewards_mgmt_page.dart';
import '../../admin_gifts_page.dart';

class AdminEconomyGrid extends StatelessWidget {
  const AdminEconomyGrid({super.key});

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
          title: Text('اقتصاد المملكة رويال',
              style: TextStyle(color: goldColor, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: GridView.count(
          padding: const EdgeInsets.all(20),
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          children: [
            _buildEconomyCard(context, 'طلبات الشحن', Icons.payments_rounded,
                Colors.greenAccent, const AdminPaymentsPage()),
            _buildEconomyCard(
                context,
                'شحن وتعديل الأرصدة',
                Icons.account_balance_wallet_rounded,
                Colors.green,
                const AdminHarvestWalletMgmtPage()),
            _buildEconomyCard(
                context,
                'باقات الحصاد الملكي',
                Icons.workspace_premium_rounded,
                Colors.amberAccent,
                const AdminRewardsMgmtPage(type: 'harvest')),
            _buildEconomyCard(
                context,
                'مصنع الهدايا',
                Icons.card_giftcard_rounded,
                Colors.pinkAccent,
                const AdminGiftsPage(initialPlacement: 'chat')),
            _buildEconomyCard(
                context,
                'باقات الشحن',
                Icons.shopping_bag_rounded,
                Colors.blueAccent,
                const AdminRechargePackagesPage(initialType: 'gems')),
            _buildEconomyCard(context, 'الآيدي المميز', Icons.badge_rounded,
                Colors.orangeAccent, const AdminSpecialIdsPage()),
          ],
        ),
      ),
    );
  }

  Widget _buildEconomyCard(BuildContext context, String title, IconData icon,
      Color color, Widget page) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 15),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
