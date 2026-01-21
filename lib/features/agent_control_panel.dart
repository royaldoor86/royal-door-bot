import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

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

  Future<void> _handleUserCharging(UserModel agent, String currencyType) async {
    final targetId = _targetIdController.text.trim();
    final amount = int.tryParse(_amountController.text.trim()) ?? 0;

    if (targetId.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى إدخال آيدي صحيح وكمية أكبر من صفر')));
      return;
    }

    int agencyBalance = currencyType == 'gems' ? agent.agencyGems : agent.agencyCoins;
    
    if (agencyBalance < amount) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('عذراً، رصيد الوكالة الحالي ($agencyBalance) غير كافٍ لشحن $amount ❌'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final userQuery = await _db.collection('users').where('royalId', isEqualTo: targetId).limit(1).get();
      if (userQuery.docs.isEmpty) throw 'لم يتم العثور على مستخدم بهذا الآيدي الملكي';

      final targetUserDoc = userQuery.docs.first;
      final targetUserId = targetUserDoc.id;

      await _db.runTransaction((transaction) async {
        final agentRef = _db.collection('users').doc(agent.uid);
        final userRef = _db.collection('users').doc(targetUserId);

        String agentField = currencyType == 'gems' ? 'agencyGems' : 'agencyCoins';
        transaction.update(agentRef, {
          agentField: FieldValue.increment(-amount),
          'agentData.totalCharged': FieldValue.increment(amount),
        });

        transaction.update(userRef, {
          currencyType: FieldValue.increment(amount),
        });

        final logRef = _db.collection('agent_transactions').doc();
        transaction.set(logRef, {
          'agentId': agent.uid,
          'targetId': targetUserId,
          'amount': amount,
          'currency': currencyType,
          'timestamp': FieldValue.serverTimestamp(),
          'agencyName': agent.agentData?['agencyName'] ?? 'وكالة رويال',
        });
      });

      _targetIdController.clear();
      _amountController.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت عملية الشحن بنجاح ✅'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.redAccent));
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
          backgroundColor: const Color(0xFF0A1F1C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25), 
            side: BorderSide(color: Colors.amber.withValues(alpha: 0.3)) // تم إصلاح الخطأ هنا
          ),
          title: const Text('إطلاق "ساحة المنافسة الملكية"', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInputField(nameCtrl, 'عنوان المسابقة (مثلاً: ملك السهرة)', Icons.emoji_events),
                const SizedBox(height: 10),
                _buildInputField(prizeCtrl, 'قيمة الجائزة الكبرى', Icons.workspace_premium, isNumber: true),
                const SizedBox(height: 10),
                _buildInputField(hoursCtrl, 'مدة المسابقة (بالساعات)', Icons.timer, isNumber: true),
                const SizedBox(height: 15),
                Row(
                  children: [
                    const Text('نوع الجائزة:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(width: 10),
                    ChoiceChip(label: const Text('جواهر'), selected: currency == 'gems', onSelected: (s) => setModalState(() => currency = 'gems')),
                    const SizedBox(width: 5),
                    ChoiceChip(label: const Text('كوينز'), selected: currency == 'coins', onSelected: (s) => setModalState(() => currency = 'coins')),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () async {
                int prize = int.tryParse(prizeCtrl.text) ?? 0;
                int hours = int.tryParse(hoursCtrl.text) ?? 24;
                int agentBal = currency == 'gems' ? agent.agencyGems : agent.agencyCoins;

                if (prize <= 0 || nameCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('يرجى ملء كافة الحقول')));
                  return;
                }

                if (agentBal < prize) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رصيد الوكالة غير كافٍ لرصد هذه الجائزة ❌')));
                  return;
                }

                try {
                  await _db.runTransaction((transaction) async {
                    final agentRef = _db.collection('users').doc(agent.uid);
                    transaction.update(agentRef, {
                      currency == 'gems' ? 'agencyGems' : 'agencyCoins': FieldValue.increment(-prize)
                    });

                    final contestRef = _db.collection('royal_arena_contests').doc();
                    transaction.set(contestRef, {
                      'title': nameCtrl.text.trim(),
                      'prize': prize,
                      'currency': currency,
                      'agentId': agent.uid,
                      'agencyName': agent.agentData?['agencyName'] ?? 'وكالة رويال',
                      'startTime': FieldValue.serverTimestamp(),
                      'endTime': Timestamp.fromDate(DateTime.now().add(Duration(hours: hours))),
                      'status': 'active',
                      'participantsCount': 0,
                    });
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تفعيل "ساحة المنافسة" وخصم الجائزة بنجاح 🏆'), backgroundColor: Colors.green));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل في إطلاق المسابقة')));
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
            backgroundColor: const Color(0xFF0A1F1C),
            appBar: AppBar(
              backgroundColor: const Color(0xFF051211),
              elevation: 0,
              title: const Text('لوحة العمليات التجارية المعتمدة', style: TextStyle(color: Color(0xFFC5A059), fontWeight: FontWeight.bold)),
              centerTitle: true,
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildAgencyWalletCard(userData),
                  const SizedBox(height: 25),
                  _buildActionCard(
                    title: 'شحن أرصدة المستخدمين',
                    child: Column(
                      children: [
                        _buildInputField(_targetIdController, 'الآيدي الملكي (ID)', Icons.person_search),
                        const SizedBox(height: 15),
                        _buildInputField(_amountController, 'الكمية المطلوبة', Icons.monetization_on, isNumber: true),
                        const SizedBox(height: 25),
                        if (_isProcessing)
                          const CircularProgressIndicator(color: Colors.amber)
                        else
                          Row(
                            children: [
                              Expanded(child: _buildActionButton('شحن جواهر 💎', Colors.blue, () => _handleUserCharging(userData, 'gems'))),
                              const SizedBox(width: 10),
                              Expanded(child: _buildActionButton('شحن كوينز 🪙', Colors.amber.shade700, () => _handleUserCharging(userData, 'coins'))),
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

  Widget _buildAgencyWalletCard(UserModel agent) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF042F2C), Color(0xFF021412)]),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFC5A059).withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          const Text('محفظة الوكالة (رصيد المبيعات)', style: TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _walletItem('جواهر البيع', agent.agencyGems.toString(), Icons.diamond, Colors.blueAccent),
              Container(width: 1, height: 50, color: Colors.white10),
              _walletItem('كوينز البيع', agent.agencyCoins.toString(), Icons.monetization_on, Colors.amber),
            ],
          ),
          const Divider(height: 40, color: Colors.white10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('رصيدك الشخصي (غير قابل للبيع):', style: TextStyle(color: Colors.white30, fontSize: 11)),
              Row(
                children: [
                  _miniStat(agent.gems.toString(), Icons.diamond, Colors.blueAccent),
                  const SizedBox(width: 15),
                  _miniStat(agent.coins.toString(), Icons.monetization_on, Colors.amber),
                ],
              )
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

  Widget _miniStat(String val, IconData icon, Color color) {
    return Row(children: [Icon(icon, color: color, size: 12), const SizedBox(width: 4), Text(val, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold))]);
  }

  Widget _buildActionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
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
        prefixIcon: Icon(icon, color: const Color(0xFFC5A059), size: 20),
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
      title: 'الساحة الملكية للمنافسة',
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: const Icon(Icons.emoji_events_rounded, color: Colors.amber),
        ),
        title: const Text('إطلاق تحدي جديد', style: TextStyle(color: Colors.white, fontSize: 14)),
        subtitle: const Text('سيتم تجميد الجائزة فوراً لضمان حقوق المتسابقين', style: TextStyle(color: Colors.white38, fontSize: 11)),
        trailing: const Icon(Icons.rocket_launch, color: Colors.amber),
        onTap: () => _showContestDialog(agent),
      ),
    );
  }
}
