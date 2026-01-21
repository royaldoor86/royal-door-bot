import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class AgentDashboardPage extends StatefulWidget {
  const AgentDashboardPage({super.key});

  @override
  State<AgentDashboardPage> createState() => _AgentDashboardPageState();
}

class _AgentDashboardPageState extends State<AgentDashboardPage> {
  double _chargingVolume = 1000; 
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  void _contactOwner() async {
    const phoneNumber = "9647770992966";
    final Uri whatsappUrl = Uri.parse("https://wa.me/$phoneNumber?text=${Uri.encodeComponent('السلام عليكم، أرغب في تقديم طلب للحصول على وكالة رويال دور معتمدة.')}");
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF021412),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverHeader(),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildExclusivityBadge(),
                  _buildSectionTitle('حاسبة الأرباح المتوقعة 💰'),
                  _buildProfitCalculator(),
                  _buildSectionTitle('المزايا السيادية للوكيل'),
                  _buildFeatureGrid(),
                  const SizedBox(height: 30),
                  _buildRevenuePlan(),
                  const SizedBox(height: 30),
                  _buildTrustStats(), // هذا الجزء أصبح ذكياً الآن
                  const SizedBox(height: 30),
                  _buildFAQSection(),
                  const SizedBox(height: 40),
                  _buildCTAButton(),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 280.0,
      pinned: true,
      backgroundColor: const Color(0xFF042F2C),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Color(0xFF0A3D38), Color(0xFF021412)],
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3), width: 2),
                    boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.1), blurRadius: 30)],
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, size: 70, color: Colors.amber),
                ),
                const SizedBox(height: 15),
                const Text('ديوان الوكلاء المعتمدين', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                const Text('كن شريكاً في الإمبراطورية الملكية', style: TextStyle(color: Colors.white54, fontSize: 13)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('users').where('isAgent', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        // إذا كان هناك بيانات، نحسب عدد الوكلاء الحقيقي، وإلا نظهر رقم 50 كبداية
        int agentCount = snapshot.hasData ? snapshot.data!.docs.length : 50;
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _statBox('+$agentCount', 'وكالة معتمدة'),
            _statBox('24/7', 'دعم فني للوكلاء'),
            _statBox('%100', 'أمان مالي'),
          ],
        );
      },
    );
  }

  Widget _statBox(String val, String label) {
    return Column(
      children: [
        Text(val, style: const TextStyle(color: Colors.amber, fontSize: 22, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }

  Widget _buildProfitCalculator() {
    double estimatedProfit = _chargingVolume * 0.05; 
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          const Text('حجم الشحن الشهري المستهدف:', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 10),
          Text('\$${_chargingVolume.toInt()}', style: const TextStyle(color: Colors.amber, fontSize: 32, fontWeight: FontWeight.bold)),
          Slider(
            value: _chargingVolume,
            min: 500,
            max: 10000,
            divisions: 19,
            activeColor: Colors.amber,
            inactiveColor: Colors.white10,
            onChanged: (val) => setState(() => _chargingVolume = val),
          ),
          const Divider(color: Colors.white10, height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('الربح الصافي المتوقع (5%):', style: TextStyle(color: Colors.white54, fontSize: 14)),
              Text('\$${estimatedProfit.toInt()}', style: const TextStyle(color: Colors.greenAccent, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection() {
    return Column(
      children: [
        _buildFAQItem('كيف استلم أرباحي؟', 'يتم تحويل الأرباح بشكل فوري وتلقائي لمحفظة الوكالة الخاصة بك بعد كل عملية.'),
        _buildFAQItem('هل أحتاج لمكتب رسمي؟', 'لا، يمكنك إدارة وكالتك بالكامل من خلال هاتفك ومن داخل غرف رويال دور.'),
        _buildFAQItem('ما هي شروط الاستمرار؟', 'الحفاظ على مستوى خدمة متميز والالتزام بالقوانين الملكية للتطبيق.'),
      ],
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.02), borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        title: Text(question, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        iconColor: Colors.amber,
        collapsedIconColor: Colors.white38,
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Text(answer, style: const TextStyle(color: Colors.white54, fontSize: 13, height: 1.5)),
          )
        ],
      ),
    );
  }

  Widget _buildExclusivityBadge() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.amber.withValues(alpha: 0.2))),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user, color: Colors.amber, size: 18),
          SizedBox(width: 10),
          Text('بقي 3 مقاعد فقط لوكالات جديدة هذا الشهر', style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 15),
      child: Align(alignment: Alignment.centerRight, child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildFeatureGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      childAspectRatio: 1.1,
      children: [
        _featureItem(Icons.diamond_outlined, 'شحن الجواهر', 'أسعار جملة حصرية للوكلاء'),
        _featureItem(Icons.stars_rounded, 'توزيع الكوينز', 'إدارة كاملة لاقتصاد الغرف'),
        _featureItem(Icons.emoji_events_outlined, 'رعاية الفعاليات', 'صلاحية إطلاق مسابقات رسمية'),
        _featureItem(Icons.security_outlined, 'الحصانة الملكية', 'حماية خاصة لحساب الوكالة'),
      ],
    );
  }

  Widget _featureItem(IconData icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.amber, size: 30),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(desc, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildRevenuePlan() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF042F2C), Color(0xFF0A3D38)]),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.auto_graph_rounded, color: Colors.amber),
              SizedBox(width: 15),
              Text('خارطة الطريق للوكيل', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          _stepItem('1', 'طلب الاعتماد من الإدارة الملكية'),
          _stepItem('2', 'تفعيل محفظة الوكالة بأسعار الجملة'),
          _stepItem('3', 'بناء قاعدة عملاء من مستخدمي التطبيق'),
          _stepItem('4', 'تحقيق أرباح مستدامة من عمليات الشحن'),
        ],
      ),
    );
  }

  Widget _stepItem(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(width: 24, height: 24, decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle), child: Center(child: Text(num, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)))),
          const SizedBox(width: 15),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildCTAButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _contactOwner,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 10,
          shadowColor: Colors.amber.withValues(alpha: 0.3),
        ),
        child: const Text('قدم طلب الوكالة الآن', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
