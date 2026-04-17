import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_manager.dart';

class GemsCoinsPage extends StatefulWidget {
  const GemsCoinsPage({super.key});

  @override
  State<GemsCoinsPage> createState() => _GemsCoinsPageState();
}

class _GemsCoinsPageState extends State<GemsCoinsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F1A24),
        bottomNavigationBar: SizedBox(
          height: 55,
          child: AdWidget(ad: AdManager().getBannerAd()),
        ),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1B2B38),
          elevation: 0,
          title: const Text('مركز الشحن الملكي',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.amber,
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white54,
            tabs: const [
              Tab(text: 'شحن كوينز 🪙'),
              Tab(text: 'شحن جواهر 💎'),
            ],
          ),
        ),
        body: StreamBuilder<UserModel>(
          stream:
              user != null ? _firestoreService.streamUserData(user.uid) : null,
          builder: (context, snapshot) {
            final userData = snapshot.data;
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: Colors.amber));
            }

            return Column(
              children: [
                _buildWalletHeader(userData),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPackagesList('coins'),
                      _buildPackagesList('gems'),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildWalletHeader(UserModel? user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Color(0xFF1B2B38),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBalanceItem('كوينز', user?.stars.toString() ?? '0',
              Icons.monetization_on, Colors.amber),
          Container(width: 1, height: 40, color: Colors.white10),
          _buildBalanceItem('جواهر', user?.gems.toString() ?? '0',
              Icons.diamond, Colors.cyanAccent),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(
      String label, String amount, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(amount,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  Widget _buildPackagesList(String type) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('recharge_packages')
          .where('type', isEqualTo: type)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(
              child: CircularProgressIndicator(color: Colors.amber));
        final docs = snapshot.data!.docs;
        if (docs.isEmpty)
          return const Center(
              child: Text('لا توجد باقات متاحة',
                  style: TextStyle(color: Colors.white38)));

        final sortedDocs = docs.toList()
          ..sort((a, b) => (a['price'] as num).compareTo(b['price'] as num));

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: sortedDocs.length,
          itemBuilder: (context, index) {
            final data = sortedDocs[index].data() as Map<String, dynamic>;
            return _buildPackageCard(data, type);
          },
        );
      },
    );
  }

  Widget _buildPackageCard(Map<String, dynamic> data, String type) {
    final color = type == 'coins' ? Colors.amber : Colors.cyanAccent;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(type == 'coins' ? Icons.monetization_on : Icons.diamond,
              color: color, size: 40),
          const SizedBox(height: 10),
          Text('${data['amount']} ${type == 'coins' ? 'كوينز' : 'جوهرة'}',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          Text('${data['price']} \$',
              style: const TextStyle(
                  color: Colors.greenAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _showPaymentMethods(data, type),
            style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('تفعيل',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  void _showPaymentMethods(Map<String, dynamic> package, String type) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Color(0xFF1B2B38),
          borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 25),
            const Text('اختر وسيلة الدفع الملكية',
                style: TextStyle(
                    color: Colors.amber,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
                'لشراء ${package['amount']} ${type == 'coins' ? 'كوينز' : 'جوهرة'} بمبلغ ${package['price']}\$',
                style: const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 30),
            Expanded(
              child: ListView(
                children: [
                  _paymentTile(
                      'زين كاش (Zain Cash)',
                      '07855900447',
                      Icons.wallet,
                      Colors.redAccent,
                      () => _processPayment(
                          package, type, 'زين كاش', '07855900447')),
                  _paymentTile(
                      'آسيا باي (AsiaPay)',
                      '07770992966',
                      Icons.account_balance_wallet,
                      Colors.red,
                      () => _processPayment(
                          package, type, 'آسيا باي', '07770992966')),
                  _paymentTile(
                      'رصيد آسيا سيل / زين',
                      'تحويل رصيد',
                      Icons.phone_android,
                      Colors.greenAccent,
                      () => _processPayment(package, type, 'رصيد هاتف',
                          '07855900447 - 07770992966')),
                  _paymentTile(
                      'ماستر كارد / فيزا / كي كارد',
                      '910113911184',
                      Icons.credit_card,
                      Colors.blueAccent,
                      () => _processPayment(
                          package, type, 'بطاقة بنكية', '910113911184')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paymentTile(String title, String subtitle, IconData icon, Color color,
      VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 26),
        ),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle,
            style: const TextStyle(color: Colors.white38, fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios,
            color: Colors.white24, size: 16),
        onTap: onTap,
      ),
    );
  }

  Future<void> _processPayment(Map<String, dynamic> package, String type,
      String method, String transferTo) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final referenceController = TextEditingController();

    Navigator.pop(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1A24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(25),
          side: BorderSide(
              color: Colors.amber.withOpacity(0.3)), // تم إصلاح هذا السطر
        ),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.amber),
            const SizedBox(width: 10),
            Text('تعليمات الدفع: $method',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('يرجى تحويل المبلغ إلى الرقم/الحساب التالي:',
                  style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.amber.withOpacity(0.2))),
                child: Column(
                  children: [
                    SelectableText(transferTo,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.amber,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            letterSpacing: 1.5)),
                    const SizedBox(height: 5),
                    const Text('انقر طويلاً للنسخ',
                        style: TextStyle(color: Colors.white24, fontSize: 10)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Divider(color: Colors.white10),
              const SizedBox(height: 15),
              const Text('أدخل رقم العملية أو رقم هاتفك المحول منه:',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              TextField(
                controller: referenceController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'رقم العملية (Ref ID) أو رقم هاتفك',
                  hintStyle:
                      const TextStyle(color: Colors.white24, fontSize: 12),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.03),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 10),
              const Text('* يجب إدخال بيانات صحيحة لضمان قبول الطلب.',
                  style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 10,
                      fontStyle: FontStyle.italic)),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text('إلغاء', style: TextStyle(color: Colors.white38))),
          ElevatedButton(
            onPressed: () async {
              if (referenceController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('يرجى إدخال رقم العملية أو هاتفك للتحقق')));
                return;
              }

              await FirebaseFirestore.instance.collection('payments').add({
                'userId': user.uid,
                'userName': user.displayName ?? 'مستخدم ملكي',
                'amount': package['amount'],
                'price': package['price'],
                'type': type == 'coins' ? 'coins_bundle' : 'gem_bundle',
                'method': method,
                'status': 'pending',
                'paymentRef': referenceController.text.trim(),
                'transferTo': transferTo,
                'createdAt': FieldValue.serverTimestamp(),
              });

              await FirebaseFirestore.instance
                  .collection('admin_notifications')
                  .add({
                'title': 'طلب شحن جديد 💰',
                'body':
                    'المستخدم ${user.displayName} طلب شحن ${package['amount']} عبر $method',
                'userId': user.uid,
                'type': 'payment_request',
                'isRead': false,
                'createdAt': FieldValue.serverTimestamp(),
              });

              Navigator.pop(ctx);
              _showSuccessDialog(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('تم التحويل، إرسال الطلب',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1A24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline,
                color: Colors.greenAccent, size: 80),
            const SizedBox(height: 20),
            const Text('تم استلام طلبك بنجاح!',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text(
                'سيقوم الديوان الملكي بمراجعة التحويل وإضافة الرصيد لحسابك خلال دقائق قليلة. شكراً لثقتك 👑',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  minimumSize: const Size(120, 45)),
              child: const Text('حسناً',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      ),
    );
  }
}
