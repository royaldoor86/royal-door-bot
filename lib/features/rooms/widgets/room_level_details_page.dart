import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoomLevelDetailsPage extends StatelessWidget {
  final String roomId;
  const RoomLevelDetailsPage({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A0F08), // ثيم بني داكن ملكي
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.amber),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text('مستوى النادي', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          centerTitle: true,
          actions: [
            IconButton(icon: const Icon(Icons.help_outline, color: Colors.amber), onPressed: () {}),
            IconButton(icon: const Icon(Icons.emoji_events_outlined, color: Colors.amber), onPressed: () {}),
          ],
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('rooms').doc(roomId).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.amber));
            
            final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            final int currentExp = data['exp'] ?? 0;
            final int level = data['level'] ?? 1;
            final String ownerName = data['ownerName'] ?? 'اناقه طالبه';
            final String ownerId = data['ownerId'] ?? '20848894636';

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  // بطاقة صاحب النادي
                  _buildUserCard(ownerName, ownerId),
                  const SizedBox(height: 25),
                  
                  // إجمالي النقاط
                  const Text('إجمالي نقاط النادي لهذه الدورة', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  Text('$currentExp', style: const TextStyle(color: Colors.amber, fontSize: 32, fontWeight: FontWeight.bold)),
                  const Text('الدورة الإحصائية: 18/01/2026 - 25/01/2026', style: TextStyle(color: Colors.white38, fontSize: 10)),
                  
                  const SizedBox(height: 30),
                  
                  // شريط التقدم والمراحل
                  _buildMilestones(currentExp),
                  
                  const SizedBox(height: 40),
                  
                  // شعار المستوى الحالي
                  _buildLevelBadge(level),
                  
                  const SizedBox(height: 30),
                  
                  // الامتيازات
                  _buildPrivilegesSection(),
                  
                  const SizedBox(height: 30),
                  
                  // قوانين كسب النقاط (الربط الحقيقي بالمقترحات)
                  _buildPointsRulesSection(),
                  
                  const SizedBox(height: 50),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUserCard(String name, String id) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.amber.withOpacity(0.3), Colors.brown.withOpacity(0.5)]),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amber.withOpacity(0.5), width: 1),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset('assets/images/avatar_placeholder.png', width: 50, height: 50, fit: BoxFit.cover),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10)),
                  child: Text('ID: $id', style: const TextStyle(color: Colors.amber, fontSize: 10)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestones(int exp) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              height: 6,
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(3)),
            ),
            Container(
              height: 6,
              width: 150, // حسب الحسبة الحقيقية
              decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(3)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _milestoneText('3.0M', 'الأسطوري'),
            _milestoneText('1.2M', 'الماسي'),
            _milestoneText('600.0K', 'الذهبي'),
          ],
        ),
      ],
    );
  }

  Widget _milestoneText(String val, String label) {
    return Column(
      children: [
        Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }

  Widget _buildLevelBadge(int level) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Image.asset('assets/images/trophy.png', width: 120, height: 120, errorBuilder: (c,e,s) => const Icon(Icons.shield, size: 100, color: Colors.amber)),
            Positioned(
              top: 40,
              child: Text('$level', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text('الذهبي', style: TextStyle(color: Colors.amber, fontSize: 20, fontWeight: FontWeight.bold)),
        const Text('لم يتم الوصول بعد إلى هذا المستوى.', style: TextStyle(color: Colors.white38, fontSize: 12)),
      ],
    );
  }

  Widget _buildPrivilegesSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.auto_awesome, color: Colors.amber, size: 18),
            SizedBox(width: 10),
            Text('الامتيازات 3/8', style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(width: 10),
            Icon(Icons.auto_awesome, color: Colors.amber, size: 18),
          ],
        ),
        const SizedBox(height: 20),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _privilegeCard('شعار المستوى', 'المستوى الذهبي'),
              _privilegeCard('موضوع الغرفة المخصص', '1 مرة/ الأسبوع'),
              _privilegeCard('استدعاء الأعضاء', '1 مرة/ الأسبوع'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _privilegeCard(String title, String sub) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(left: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.amber.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Icon(Icons.star, color: Colors.amber, size: 30),
          const SizedBox(height: 10),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(sub, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white38, fontSize: 9)),
        ],
      ),
    );
  }

  Widget _buildPointsRulesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('كيفية كسب نقاط النادي ⚡', style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          _ruleItem('الدردشة على المايك (كل ساعة)', '60 نقطة'),
          _ruleItem('إرسال الرسائل (لكل رسالة)', '1 نقطة'),
          _ruleItem('مشاركة الغرفة والانضمام', '40 نقطة'),
          _ruleItem('هدايا الجواهر (لكل هدية)', '5 نقاط'),
          _ruleItem('هدايا الكوينز (لكل هدية)', '5 نقاط'),
          _ruleItem('شراء موضوع بالغرفة', '25 نقطة'),
          _ruleItem('الفوز بالمعركة', '10 نقاط'),
        ],
      ),
    );
  }

  Widget _ruleItem(String title, String points) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          Text(points, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }
}
