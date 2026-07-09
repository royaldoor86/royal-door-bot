import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

/// لوحة تحكم قائد بيت الدعم (سابقاً الوكيل)
/// تم تحديثها لتكون "مركز دعم مجتمعي" للامتثال لسياسات جوجل
class AgentControlPanel extends StatefulWidget {
  const AgentControlPanel({super.key});

  @override
  State<AgentControlPanel> createState() => _AgentControlPanelState();
}

class _AgentControlPanelState extends State<AgentControlPanel> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _targetIdController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _targetIdController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleUserSupport(UserModel agent, String currencyType) async {
    final targetId = _targetIdController.text.trim();
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;

    if (targetId.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إدخال آيدي صحيح وكمية دعم أكبر من صفر')));
      return;
    }

    int agencyBalance = currencyType == 'gems' ? agent.agencyGems : agent.agencyStars;
    
    if (agencyBalance < amount) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('رصيد بيت الدعم الحالي ($agencyBalance) لا يكفي لمنح $amount ❌'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final userQuery = await _db.collection('users').where('royalId', isEqualTo: targetId).limit(1).get();
      if (userQuery.docs.isEmpty) throw 'لم يتم العثور على عضو بهذا الآيدي الملكي';

      final targetUserDoc = userQuery.docs.first;
      final targetUserId = targetUserDoc.id;

      await _db.runTransaction((transaction) async {
        final agentRef = _db.collection('users').doc(agent.uid);
        final userRef = _db.collection('users').doc(targetUserId);

        String agentField = currencyType == 'gems' ? 'agencyGems' : 'agencyStars';
        transaction.update(agentRef, {
          agentField: FieldValue.increment(-amount),
          'agencyCoins': FieldValue.increment(-amount), 
          'agentData.totalSupported': FieldValue.increment(amount), // تم تغيير المسمى من Charged إلى Supported
        });

        transaction.update(userRef, {
          currencyType == 'gems' ? 'gems' : 'stars': FieldValue.increment(amount),
          if (currencyType != 'gems') 'coins': FieldValue.increment(amount),
        });

        final logRef = _db.collection('guild_support_logs').doc();
        transaction.set(logRef, {
          'leaderId': agent.uid,
          'targetId': targetUserId,
          'amount': amount,
          'currency': currencyType,
          'type': 'growth_support',
          'timestamp': FieldValue.serverTimestamp(),
          'guildName': agent.agentData?['agencyName'] ?? 'بيت دعم رويال',
        });
      });

      _targetIdController.clear();
      _amountController.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم منح الدعم بنجاح للعضو ✅'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ في العملية: $e'), backgroundColor: Colors.redAccent));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showContestDialog(UserModel agent) {
    final nameCtrl = TextEditingController();
    final prizeCtrl = TextEditingController();
    final hoursCtrl = TextEditingController(text: '24');
    String currency = 'gems';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25), 
            side: const BorderSide(color: Colors.amber, width: 0.5) 
          ),
          title: const Text('إطلاق "تحدي بيت الدعم"', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInputField(nameCtrl, 'عنوان التحدي (مثلاً: بطل الأسبوع)', Icons.emoji_events),
                const SizedBox(height: 10),
                _buildInputField(prizeCtrl, 'رصيد الجائزة المخصص', Icons.workspace_premium, isNumber: true),
                const SizedBox(height: 10),
                _buildInputField(hoursCtrl, 'المدة الزمنية (بالساعات)', Icons.timer, isNumber: true),
                const SizedBox(height: 15),
                Row(
                  children: [
                    const Text('نوع الجائزة:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text('جواهر'), 
                      selected: currency == 'gems', 
                      onSelected: (s) => setModalState(() => currency = 'gems'),
                      selectedColor: Colors.amber,
                      labelStyle: TextStyle(color: currency == 'gems' ? Colors.black : Colors.white),
                    ),
                    const SizedBox(width: 5),
                    ChoiceChip(
                      label: const Text('نجوم ⭐'), 
                      selected: currency == 'stars', 
                      onSelected: (s) => setModalState(() => currency = 'stars'),
                      selectedColor: Colors.amber,
                      labelStyle: TextStyle(color: currency == 'stars' ? Colors.black : Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.white38))),
            ElevatedButton(
              onPressed: () async {
                int prize = int.tryParse(prizeCtrl.text) ?? 0;
                int hours = int.tryParse(hoursCtrl.text) ?? 24;
                int agentBal = currency == 'gems' ? agent.agencyGems : agent.agencyStars;

                if (prize <= 0 || nameCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إكمال بيانات التحدي')));
                  return;
                }

                if (agentBal < prize) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رصيد بيت الدعم غير كافٍ لرصد الجائزة ❌')));
                  return;
                }

                try {
                  await _db.runTransaction((transaction) async {
                    final agentRef = _db.collection('users').doc(agent.uid);
                    transaction.update(agentRef, {
                      currency == 'gems' ? 'agencyGems' : 'agencyStars': FieldValue.increment(-prize),
                      if (currency != 'gems') 'agencyCoins': FieldValue.increment(-prize),
                    });

                    final contestRef = _db.collection('guild_challenges').doc();
                    transaction.set(contestRef, {
                      'title': nameCtrl.text.trim(),
                      'prize': prize,
                      'currency': currency,
                      'leaderId': agent.uid,
                      'guildName': agent.agentData?['agencyName'] ?? 'بيت دعم رويal',
                      'startTime': FieldValue.serverTimestamp(),
                      'endTime': Timestamp.fromDate(DateTime.now().add(Duration(hours: hours))),
                      'status': 'active',
                      'type': 'engagement_challenge',
                    });
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إطلاق التحدي وبدء الدعم بنجاح 🏆'), backgroundColor: Colors.green));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل في إطلاق التحدي')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              child: const Text('بدء التحدي', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: StreamBuilder<UserModel>(
        stream: user != null ? _firestoreService.streamUserData(user.uid) : null,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
          final userData = snapshot.data!;

          return Scaffold(
            backgroundColor: const Color(0xFF020617),
            appBar: AppBar(
              backgroundColor: const Color(0xFF0F172A),
              elevation: 0,
              title: const Text('مركز الدعم المجتمعي الملكي', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
              centerTitle: true,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildComplianceNotice(),
                  const SizedBox(height: 20),
                  _buildAgencyWalletCard(userData),
                  const SizedBox(height: 25),
                  _buildActionCard(
                    title: 'منح دعم النمو للأعضاء',
                    child: Column(
                      children: [
                        _buildInputField(_targetIdController, 'آيدي العضو المستهدف (ID)', Icons.person_search),
                        const SizedBox(height: 15),
                        _buildInputField(_amountController, 'كمية نقاط الدعم', Icons.stars, isNumber: true),
                        const SizedBox(height: 25),
                        if (_isProcessing)
                          const CircularProgressIndicator(color: Colors.amber)
                        else
                          Row(
                            children: [
                              Expanded(child: _buildActionButton('منح جواهر 💎', Colors.blue, () => _handleUserSupport(userData, 'gems'))),
                              const SizedBox(width: 10),
                              Expanded(child: _buildActionButton('منح نجوم ⭐', Colors.amber.shade700, () => _handleUserSupport(userData, 'stars'))),
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),
                  _buildAgencyContestCard(userData),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  Widget _buildComplianceNotice() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blueAccent, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'رصيد الدعم مخصص لتحفيز الأعضاء والنمو المجتمعي فقط، ويُمنع تداوله تجارياً خارج التطبيق لضمان سلامة حسابك.',
              style: TextStyle(color: Colors.blueAccent, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgencyWalletCard(UserModel agent) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF0F172A)]),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 15, offset: Offset(0, 8))],
      ),
      child: Column(
        children: [
          const Text('محفظة بيت الدعم الرسمية', style: TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _walletItem('جواهر الدعم', agent.agencyGems.toString(), Icons.diamond, Colors.blueAccent),
              Container(width: 1, height: 50, color: Colors.white10),
              _walletItem('نجوم الدعم', agent.agencyStars.toString(), Icons.stars, Colors.amber),
            ],
          ),
        ],
      ),
    );
  }

  Widget _walletItem(String label, String val, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }

  Widget _buildActionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03), 
        borderRadius: BorderRadius.circular(25), 
        border: Border.all(color: Colors.white.withValues(alpha: 0.05))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildInputField(TextEditingController ctrl, String hint, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.amber, size: 20),
        filled: true, fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildAgencyContestCard(UserModel agent) {
    return _buildActionCard(
      title: 'إدارة تحديات بيت الدعم',
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(Icons.emoji_events_rounded, color: Colors.amber),
        ),
        title: const Text('إطلاق تحدي نمو جديد', style: TextStyle(color: Colors.white, fontSize: 14)),
        subtitle: const Text('سيتم رصد الجائزة من رصيد بيت الدعم فوراً', style: TextStyle(color: Colors.white38, fontSize: 11)),
        trailing: const Icon(Icons.rocket_launch, color: Colors.amber),
        onTap: () => _showContestDialog(agent),
      ),
    );
  }
}
