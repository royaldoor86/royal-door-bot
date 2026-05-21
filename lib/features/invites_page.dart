import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../app_theme.dart';
import '../theme/design_tokens.dart';

class InvitesPage extends StatefulWidget {
  const InvitesPage({super.key});

  @override
  State<InvitesPage> createState() => _InvitesPageState();
}

class _InvitesPageState extends State<InvitesPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // الحصول على رتبة السفير بناءً على عدد المدعوين
  String _getAmbassadorRank(int count) {
    if (count >= 100) return "سفير ملكي فوق العادة 👑";
    if (count >= 50) return "سفير ماسي 💎";
    if (count >= 20) return "سفير ذهبي 🥇";
    if (count >= 5) return "سفير فضي 🥈";
    return "سفير ملكي ناشئ 🌱";
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تم نسخ كود الدعوة الملكي بنجاح 📋', textAlign: TextAlign.center),
        backgroundColor: DesignTokens.primaryGold,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  void _shareInvite(String code, String name) {
    final String shareMessage = '''
👑 دعوة ملكية خاصة من [$name] 👑

انضم الآن إلى "رويال دور" - المجتمع الأكثر رقياً للأصوات والنخبة!

🎁 مكافأة انضمام حصرية لك:
✅ 50 جوهرة ملكية 💎
✅ 50 نجمة ذهبية ⭐

استخدم كود الدعوة الخاص بي عند التسجيل:
📌 الكود: $code

🔗 حمل التطبيق الآن وابدأ رحلتك الملكية:
https://royaldur.com/app
''';

    Share.share(
      shareMessage,
      subject: 'دعوة للانضمام إلى نخبة رويال دور',
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAuth = FirebaseAuth.instance.currentUser;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: StreamBuilder<UserModel>(
        stream: userAuth != null ? _firestoreService.streamUserData(userAuth.uid) : null,
        builder: (context, snapshot) {
          if (snapshot.hasError) return _buildErrorState();
          final userData = snapshot.data;
          if (userData == null) return const Scaffold(backgroundColor: Color(0xFF0A0A12), body: Center(child: CircularProgressIndicator(color: Colors.amber)));

          // قراءة البيانات الحقيقية من المستند
          int invitedCount = userData.agentData?['invitedCount'] ?? 0;
          int totalGems = (userData.agentData?['referralEarnings'] ?? 0).toInt();
          String myCode = userData.royalId;

          return Scaffold(
            backgroundColor: const Color(0xFF020617),
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('مركز السفراء الملكي', 
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
              centerTitle: true,
            ),
            body: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/auth_bg.png'), // خلفية ملكية إن وجدت
                  fit: BoxFit.cover,
                  opacity: 0.1,
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 120),
                    _buildProfileHeader(userData, invitedCount),
                    const SizedBox(height: 40),
                    _buildStatsGrid(invitedCount, totalGems),
                    const SizedBox(height: 30),
                    _buildInviteCodeSection(myCode),
                    const SizedBox(height: 40),
                    _buildMilestones(invitedCount),
                    const SizedBox(height: 40),
                    _buildInvitedListHeader(),
                    _buildInvitedFriendsList(userData.uid),
                    const SizedBox(height: 40),
                    _buildGlobalShareCard(myCode, userData.name),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildErrorState() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A12),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 50),
            const SizedBox(height: 20),
            const Text('حدث خطأ في تحميل البيانات الملكية', style: TextStyle(color: Colors.white70)),
            TextButton(onPressed: () => setState(() {}), child: const Text('إعادة المحاولة')),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user, int count) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // هالة ضوئية
            Container(
              height: 140, width: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.amber.withValues(alpha: 0.15), blurRadius: 40, spreadRadius: 5)
                ],
              ),
            ),
            // إطار الصورة
            Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFFFD700), Color(0xFFB8860B)]),
              ),
              child: CircleAvatar(
                radius: 55,
                backgroundColor: const Color(0xFF1A1A2E),
                backgroundImage: user.profilePic.isNotEmpty ? NetworkImage(user.profilePic) : null,
                child: user.profilePic.isEmpty ? const Icon(Icons.person, size: 60, color: Colors.white24) : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
          ),
          child: Text(_getAmbassadorRank(count), 
            style: const TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(int count, int gems) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: _statCard('أصدقاء الدعوة', count.toString(), Icons.group_add, Colors.blueAccent)),
          const SizedBox(width: 15),
          Expanded(child: _statCard('أرباح الجواهر', gems.toString(), Icons.diamond_rounded, Colors.cyanAccent)),
          const SizedBox(width: 15),
          Expanded(child: _statCard('نجوم المكافأة', (count * 50).toString(), Icons.stars_rounded, Colors.orangeAccent)),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(15),
      borderRadius: BorderRadius.circular(20),
      opacity: 0.05,
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildInviteCodeSection(String code) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerRight,
            child: Text('هويتك الملكية للدعوات:', style: TextStyle(color: Colors.white70, fontSize: 14)),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(code, 
                    style: const TextStyle(color: Colors.amber, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4)),
                ),
                VerticalDivider(color: Colors.white.withValues(alpha: 0.1)),
                IconButton(
                  onPressed: () => _copyCode(code),
                  icon: const Icon(Icons.copy_rounded, color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text('شارك هذا الكود مع أصدقائك للحصول على 50 جوهرة فورية عن كل عملية تسجيل', 
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white24, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildMilestones(int current) {
    return Column(
      children: [
        _buildSectionTitle('خارطة الطريق للمكافآت 🗺️'),
        const SizedBox(height: 15),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _buildMilestoneItem(1, 'البداية الملكية', current >= 1),
              _buildConnector(current >= 5),
              _buildMilestoneItem(5, 'السفير الفضي', current >= 5),
              _buildConnector(current >= 20),
              _buildMilestoneItem(20, 'السفير الذهبي', current >= 20),
              _buildConnector(current >= 50),
              _buildMilestoneItem(50, 'السفير الماسي', current >= 50),
              _buildConnector(current >= 100),
              _buildMilestoneItem(100, 'الأسطورة', current >= 100),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMilestoneItem(int target, String name, bool completed) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed ? Colors.amber : Colors.white.withValues(alpha: 0.05),
            boxShadow: completed ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.3), blurRadius: 10)] : [],
          ),
          child: Icon(completed ? Icons.check : Icons.lock, 
            color: completed ? Colors.black : Colors.white24, size: 20),
        ),
        const SizedBox(height: 8),
        Text('$target دعوة', style: TextStyle(color: completed ? Colors.white : Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
        Text(name, style: TextStyle(color: completed ? Colors.amber : Colors.white24, fontSize: 9)),
      ],
    );
  }

  Widget _buildConnector(bool active) {
    return Container(width: 30, height: 2, color: active ? Colors.amber : Colors.white10, margin: const EdgeInsets.only(bottom: 25));
  }

  Widget _buildInvitedListHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('نخبة أصدقائك', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          TextButton(onPressed: () {}, child: const Text('رؤية الكل', style: TextStyle(color: Colors.amber))),
        ],
      ),
    );
  }

  Widget _buildInvitedFriendsList(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('users').doc(uid).collection('referrals').orderBy('joinedAt', descending: true).limit(5).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              children: [
                Icon(Icons.person_add_disabled_rounded, color: Colors.white.withValues(alpha: 0.05), size: 60),
                const SizedBox(height: 15),
                const Text('لم ينضم أحد بعد.. كن أول من يفتح بوابة المملكة لأصدقائه!', 
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white24, fontSize: 12)),
              ],
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final friend = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              child: AppTheme.glassContainer(
                padding: const EdgeInsets.symmetric(vertical: 10),
                opacity: 0.03,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.white10, 
                    backgroundImage: (friend['profilePic'] != null && friend['profilePic'] != '') ? NetworkImage(friend['profilePic']) : null, 
                    child: (friend['profilePic'] == null || friend['profilePic'] == '') ? const Icon(Icons.person, color: Colors.white24) : null
                  ),
                  title: Text(friend['name'] ?? 'مستخدم جديد', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: Text('انضم في: ${_formatTimestamp(friend['joinedAt'])}', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Text('+50 💎', style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGlobalShareCard(String code, String name) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF0F172A)]),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Column(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.amber, size: 40),
          const SizedBox(height: 15),
          const Text('شارك الرابط الملكي الآن', 
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text('أرسل رابطاً أنيقاً يحتوي على كودك الخاص وابدأ في جني الثمار الملكية فوراً', 
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => _shareInvite(code, name),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 60),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 10,
              shadowColor: Colors.amber.withValues(alpha: 0.3),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.share_rounded),
                SizedBox(width: 12),
                Text('إرسال البطاقة الملكية', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _socialCircle(Icons.message, Colors.green, () => _shareInvite(code, name)),
              const SizedBox(width: 20),
              _socialCircle(Icons.send_rounded, Colors.blue, () => _shareInvite(code, name)),
              const SizedBox(width: 20),
              _socialCircle(Icons.facebook, Colors.blue.shade800, () => _shareInvite(code, name)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _socialCircle(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Align(alignment: Alignment.centerRight, child: Text(title, 
        style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold))),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'غير معروف';
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.year}/${date.month}/${date.day}';
    }
    return '';
  }
}
