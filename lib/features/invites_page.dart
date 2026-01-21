import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

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
    if (count >= 100) return "سفير ملكي 👑";
    if (count >= 20) return "سفير ذهبي 🥇";
    if (count >= 5) return "سفير فضي 🥈";
    return "سفير مبتدئ 🌱";
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ كود الدعوة الملكي بنجاح 📋'), backgroundColor: Colors.amber),
    );
  }

  void _shareInvite(String code) {
    Share.share(
      'انضم إلي في تطبيق رويال دور واستخدم كودي الملكي ($code) للحصول على مكافأة ترحيبية! 👑\nرابط التحميل: https://royaldur.com/app',
      subject: 'دعوة ملكية لانضمام لرويال دور',
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
          final userData = snapshot.data;
          if (userData == null) return const Scaffold(backgroundColor: Color(0xFF0F0F1E), body: Center(child: CircularProgressIndicator()));

          // قراءة البيانات الحقيقية من المستند
          int invitedCount = userData.agentData?['invitedCount'] ?? 0;
          double totalEarnings = (userData.agentData?['referralEarnings'] ?? 0).toDouble();
          String myCode = userData.royalId;

          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
              title: const Text('مركز السفراء الملكي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              centerTitle: true,
            ),
            body: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight, end: Alignment.bottomLeft,
                  colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F0F1E)],
                ),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 100),
                    _buildProfileHeader(userData, invitedCount),
                    const SizedBox(height: 30),
                    _buildEarningsCard(invitedCount, totalEarnings),
                    const SizedBox(height: 20),
                    _buildInviteCodeCard(myCode),
                    const SizedBox(height: 30),
                    _buildSectionTitle('خارطة الطريق للربح'),
                    _buildVisualSteps(invitedCount),
                    const SizedBox(height: 30),
                    _buildSectionTitle('النخبة الذين دعوتهم'),
                    _buildInvitedFriendsList(userData.uid),
                    const SizedBox(height: 40),
                    _buildShareOptions(myCode),
                    const SizedBox(height: 50),
                  ],
                ),
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user, int count) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Container(height: 120, width: 120, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.3), blurRadius: 30, spreadRadius: 10)])),
            CircleAvatar(
              radius: 50, backgroundColor: Colors.amber,
              child: CircleAvatar(radius: 47, backgroundImage: user.profilePic.isNotEmpty ? NetworkImage(user.profilePic) : null, child: user.profilePic.isEmpty ? const Icon(Icons.person, size: 50) : null),
            ),
            Positioned(
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Colors.amber, Colors.orange]), borderRadius: BorderRadius.circular(15)),
                child: Text(_getAmbassadorRank(count), style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
        const Text('رصيد أرباحك يتزايد مع كل صديق ينضم إلينا', style: TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  Widget _buildEarningsCard(int count, double earnings) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white.withValues(alpha: 0.1))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildEarningItem('أصدقاء مدعوون', count.toString(), Icons.people_alt, Colors.blue),
          Container(height: 40, width: 1, color: Colors.white10),
          _buildEarningItem('إجمالي الأرباح', earnings.toStringAsFixed(0), Icons.monetization_on, Colors.amber),
        ],
      ),
    );
  }

  Widget _buildEarningItem(String label, String val, IconData icon, Color color) {
    return Column(children: [Icon(icon, color: color, size: 24), const SizedBox(height: 8), Text(val, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11))]);
  }

  Widget _buildInviteCodeCard(String code) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 160, width: double.infinity,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(30), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFD4AF37), Color(0xFFB8860B)]), boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))]),
      child: Stack(
        children: [
          Positioned(right: -20, top: -20, child: Icon(Icons.stars, size: 150, color: Colors.white.withValues(alpha: 0.1))),
          Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('كود الدعوة الملكي الخاص بك', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(code, style: const TextStyle(color: Colors.black, fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    GestureDetector(onTap: () => _copyCode(code), child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(15)), child: const Icon(Icons.copy, color: Colors.amber, size: 20))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10), child: Align(alignment: Alignment.centerRight, child: Text(title, style: const TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold))));
  }

  Widget _buildVisualSteps(int count) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStepCircle(Icons.share, 'شارك الكود', true),
          _buildStepConnector(true),
          _buildStepCircle(Icons.person_add, 'يسجل صديقك', count > 0),
          _buildStepConnector(count > 0),
          _buildStepCircle(Icons.redeem, 'اربح الذهب', count > 0),
        ],
      ),
    );
  }

  Widget _buildStepCircle(IconData icon, String label, bool isActive) {
    return Column(children: [Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: isActive ? Colors.amber : Colors.white10, shape: BoxShape.circle, boxShadow: isActive ? [BoxShadow(color: Colors.amber.withValues(alpha: 0.3), blurRadius: 10)] : []), child: Icon(icon, color: isActive ? Colors.black : Colors.white30, size: 24)), const SizedBox(height: 8), Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.white30, fontSize: 10))]);
  }

  Widget _buildStepConnector(bool isActive) {
    return Container(height: 2, width: 30, color: isActive ? Colors.amber.withValues(alpha: 0.5) : Colors.white10);
  }

  Widget _buildInvitedFriendsList(String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('users').doc(uid).collection('referrals').orderBy('joinedAt', descending: true).limit(5).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(padding: EdgeInsets.all(20), child: Text('لم ينضم أحد عن طريقك بعد.. ابدأ بالمشاركة! 🌱', style: TextStyle(color: Colors.white24, fontSize: 12)));
        }
        return ListView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final friend = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: CircleAvatar(backgroundColor: Colors.white10, backgroundImage: friend['profilePic'] != null ? NetworkImage(friend['profilePic']) : null, child: friend['profilePic'] == null ? const Icon(Icons.person, color: Colors.white24) : null),
              title: Text(friend['name'] ?? 'مستخدم جديد', style: const TextStyle(color: Colors.white, fontSize: 14)),
              subtitle: const Text('انضم للديوان ✅', style: TextStyle(color: Colors.greenAccent, fontSize: 11)),
              trailing: const Text('+500 🪙', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
            );
          },
        );
      },
    );
  }

  Widget _buildShareOptions(String code) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: () => _shareInvite(code),
            icon: const Icon(Icons.share_outlined),
            label: const Text('مشاركة الرابط الملكي', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black, minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
          ),
          const SizedBox(height: 20),
          const Text('أو شارك مباشرة عبر:', style: TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _socialIcon(Icons.message, Colors.green, () => _shareInvite(code)),
              _socialIcon(Icons.send, Colors.blue, () => _shareInvite(code)),
              _socialIcon(Icons.facebook, Colors.blue.shade800, () => _shareInvite(code)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _socialIcon(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Container(margin: const EdgeInsets.symmetric(horizontal: 10), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: 0.3))), child: Icon(icon, color: color, size: 24)));
  }
}
