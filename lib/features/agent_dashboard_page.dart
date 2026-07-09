import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/feature_lock_wrapper.dart';

/// صفحة طلب تأسيس بيت دعم ملكي (سابقاً الوكالة)
/// تم تحديثها لتتوافق مع سياسات جوجل العالمية عبر التركيز على دعم المجتمع والنمو
class AgentDashboardPage extends StatefulWidget {
  const AgentDashboardPage({super.key});

  @override
  State<AgentDashboardPage> createState() => _AgentDashboardPageState();
}

class _AgentDashboardPageState extends State<AgentDashboardPage> {
  double _supportVolume = 1000; 
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  void _contactOwner() async {
    const phoneNumber = "9647770992966";
    final Uri whatsappUrl = Uri.parse("https://wa.me/$phoneNumber?text=${Uri.encodeComponent('السلام عليكم، أرغب في تقديم طلب لاعتماد بيت دعم ملكي رسمي لخدمة المجتمع وتطوير المنشئين.')}");
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: FeatureLockWrapper(
        lockField: 'isAgencyLocked',
        child: Scaffold(
          backgroundColor: const Color(0xFF020617),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverHeader(),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildComplianceBadge(),
                  _buildSectionTitle('حاسبة نمو بيت الدعم 📈'),
                  _buildGrowthCalculator(),
                  _buildSectionTitle('المزايا القيادية لقائد الدعم'),
                  _buildFeatureGrid(),
                  const SizedBox(height: 30),
                  _buildGuildCharter(),
                  const SizedBox(height: 30),
                  _buildTrustStats(), 
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
    ),
    );
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 280.0,
      pinned: true,
      backgroundColor: const Color(0xFF1E293B),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [Color(0xFF334155), Color(0xFF020617)],
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
                  child: const Icon(Icons.castle_rounded, size: 70, color: Colors.amber),
                ),
                const SizedBox(height: 15),
                const Text('بيوت الدعم الملكية', 
                  style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                const Text('كن شريكاً قيادياً في نمو مجتمع رويال دور', 
                  style: TextStyle(color: Colors.white54, fontSize: 13)),
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
        int agentCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _statBox('+$agentCount', 'بيت دعم معتمد'),
            _statBox('24/7', 'تواصل مباشر مع الإدارة'),
            _statBox('%100', 'نظام حماية ملكي'),
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

  Widget _buildGrowthCalculator() {
    double estimatedGrowth = _supportVolume * 0.05; 
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
          const Text('حجم الدعم المجتمعي الشهري المستهدف:', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 10),
          Text('${_supportVolume.toInt()} نقطة نمو ⭐', style: const TextStyle(color: Colors.amber, fontSize: 32, fontWeight: FontWeight.bold)),
          Slider(
            value: _supportVolume,
            min: 500,
            max: 10000,
            divisions: 19,
            activeColor: Colors.amber,
            inactiveColor: Colors.white10,
            onChanged: (val) => setState(() => _supportVolume = val),
          ),
          const Divider(color: Colors.white10, height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('مكافأة القيادة المتوقعة (5%):', style: TextStyle(color: Colors.white54, fontSize: 12)),
              Text('${estimatedGrowth.toInt()} نجمة ⭐', style: const TextStyle(color: Colors.greenAccent, fontSize: 22, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFAQSection() {
    return Column(
      children: [
        _buildFAQItem('كيف استلم مكافآت القيادة؟', 'تضاف المكافآت بشكل دوري لمحفظة بيت الدعم الخاصة بك بناءً على مستوى نشاط أعضائك.'),
        _buildFAQItem('ما هو دور قائد بيت الدعم؟', 'توجيه الأعضاء الجدد، تقديم الدعم الفني، وتنظيم الفعاليات لزيادة التفاعل في المملكة.'),
        _buildFAQItem('هل هناك شروط تقنية؟', 'فقط أن تكون عضواً فعالاً وتلتزم بميثاق بيت الدعم وسياسات رويال دور.'),
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

  Widget _buildComplianceBadge() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.green.withValues(alpha: 0.2))),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_user_rounded, color: Colors.greenAccent, size: 18),
          SizedBox(width: 10),
          Text('نظام معتمد ومتوافق مع سياسات المجتمع العالمية', style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
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
        _featureItem(Icons.volunteer_activism_outlined, 'منح الدعم', 'توزيع نقاط النمو على أعضاء بيت الدعم'),
        _featureItem(Icons.groups_rounded, 'بناء المجتمعات', 'إدارة كاملة لفرق العمل والمنشئين'),
        _featureItem(Icons.emoji_events_outlined, 'رعاية الفعاليات', 'إطلاق مسابقات رسمية بدعم ملكي'),
        _featureItem(Icons.security_outlined, 'الحصانة القيادية', 'حماية خاصة لحساب بيت الدعم الرسمي'),
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

  Widget _buildGuildCharter() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)]),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.article_outlined, color: Colors.amber),
              SizedBox(width: 15),
              Text('ميثاق بيت الدعم الملكي', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          _stepItem('1', 'تقديم الدعم والنمو للأعضاء الموهوبين'),
          _stepItem('2', 'منع أي تبادل مالي خارج الأنظمة الرسمية'),
          _stepItem('3', 'الالتزام بقواعد الأخلاق الملكية في الرومات'),
          _stepItem('4', 'المساهمة في بناء مجتمع آمن ومبدع'),
        ],
      ),
    );
  }

  Widget _stepItem(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(width: 24, height: 24, decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle), child: Center(child: Text(num, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)))),
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
        child: const Text('طلب تأسيس بيت دعم الآن', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
