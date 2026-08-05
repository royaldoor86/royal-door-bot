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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('يرجى إدخال آيدي صحيح وكمية دعم أكبر من صفر')));
      return;
    }

    int agencyBalance =
        currencyType == 'gems' ? agent.agencyGems : agent.agencyCoins;

    if (agencyBalance < amount) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'رصيد بيت الدعم الحالي ($agencyBalance) لا يكفي لمنح $amount ❌'),
        backgroundColor: Colors.redAccent,
      ));
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final userQuery = await _db
          .collection('users')
          .where('royalId', isEqualTo: targetId)
          .limit(1)
          .get();
      if (userQuery.docs.isEmpty) {
        throw 'لم يتم العثور على عضو بهذا الآيدي الملكي';
      }

      final targetUserDoc = userQuery.docs.first;
      final targetUserId = targetUserDoc.id;

      await _db.runTransaction((transaction) async {
        final agentRef = _db.collection('users').doc(agent.uid);
        final userRef = _db.collection('users').doc(targetUserId);

        String agentField =
            currencyType == 'gems' ? 'agencyGems' : 'agencyCoins';
        transaction.update(agentRef, {
          agentField: FieldValue.increment(-amount),
          'agencyCoins': FieldValue.increment(-amount),
          'agentData.totalSupported': FieldValue.increment(
              amount), // تم تغيير المسمى من Charged إلى Supported
        });

        transaction.update(userRef, {
          currencyType == 'gems' ? 'gems' : 'coins':
              FieldValue.increment(amount),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('تم منح الدعم بنجاح للعضو ✅'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('خطأ في العملية: $e'),
            backgroundColor: Colors.redAccent));
      }
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
              side: const BorderSide(color: Colors.amber, width: 0.5)),
          title: const Text('إطلاق "تحدي بيت الدعم"',
              style:
                  TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInputField(nameCtrl, 'عنوان التحدي (مثلاً: بطل الأسبوع)',
                    Icons.emoji_events),
                const SizedBox(height: 10),
                _buildInputField(
                    prizeCtrl, 'رصيد الجائزة المخصص', Icons.workspace_premium,
                    isNumber: true),
                const SizedBox(height: 10),
                _buildInputField(
                    hoursCtrl, 'المدة الزمنية (بالساعات)', Icons.timer,
                    isNumber: true),
                const SizedBox(height: 15),
                Row(
                  children: [
                    const Text('نوع الجائزة:',
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text('جواهر'),
                      selected: currency == 'gems',
                      onSelected: (s) => setModalState(() => currency = 'gems'),
                      selectedColor: Colors.amber,
                      labelStyle: TextStyle(
                          color:
                              currency == 'gems' ? Colors.black : Colors.white),
                    ),
                    const SizedBox(width: 5),
                    ChoiceChip(
                      label: const Text('كوينز 🪙'),
                      selected: currency == 'coins',
                      onSelected: (s) =>
                          setModalState(() => currency = 'coins'),
                      selectedColor: Colors.amber,
                      labelStyle: TextStyle(
                          color: currency == 'coins'
                              ? Colors.black
                              : Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء',
                    style: TextStyle(color: Colors.white38))),
            ElevatedButton(
              onPressed: () async {
                int prize = int.tryParse(prizeCtrl.text) ?? 0;
                int hours = int.tryParse(hoursCtrl.text) ?? 24;
                int agentBal =
                    currency == 'gems' ? agent.agencyGems : agent.agencyCoins;

                if (prize <= 0 || nameCtrl.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('يرجى إكمال بيانات التحدي')));
                  return;
                }

                if (agentBal < prize) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('رصيد بيت الدعم غير كافٍ لرصد الجائزة ❌')));
                  return;
                }

                try {
                  await _db.runTransaction((transaction) async {
                    final agentRef = _db.collection('users').doc(agent.uid);
                    transaction.update(agentRef, {
                      currency == 'gems' ? 'agencyGems' : 'agencyCoins':
                          FieldValue.increment(-prize),
                    });

                    final contestRef = _db.collection('guild_challenges').doc();
                    transaction.set(contestRef, {
                      'title': nameCtrl.text.trim(),
                      'prize': prize,
                      'currency': currency,
                      'leaderId': agent.uid,
                      'guildName':
                          agent.agentData?['agencyName'] ?? 'بيت دعم رويal',
                      'startTime': FieldValue.serverTimestamp(),
                      'endTime': Timestamp.fromDate(
                          DateTime.now().add(Duration(hours: hours))),
                      'status': 'active',
                      'type': 'engagement_challenge',
                    });
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('تم إطلاق التحدي وبدء الدعم بنجاح 🏆'),
                      backgroundColor: Colors.green));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('فشل في إطلاق التحدي')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
              child: const Text('بدء التحدي',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
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
          stream:
              user != null ? _firestoreService.streamUserData(user.uid) : null,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }
            final userData = snapshot.data!;

            return Scaffold(
              backgroundColor: const Color(0xFF020617),
              extendBodyBehindAppBar: true,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: const Text('مركز الدعم المجتمعي الملكي',
                    style: TextStyle(
                        color: Colors.amber, fontWeight: FontWeight.bold)),
                centerTitle: true,
              ),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
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
                            _buildInputField(
                                _targetIdController,
                                'آيدي العضو المستهدف (ID)',
                                Icons.person_search),
                            const SizedBox(height: 15),
                            _buildInputField(_amountController,
                                'كمية نقاط الدعم', Icons.stars,
                                isNumber: true),
                            const SizedBox(height: 25),
                            if (_isProcessing)
                              const CircularProgressIndicator(
                                  color: Colors.amber)
                            else
                              Row(
                                children: [
                                  Expanded(
                                      child: _buildActionButton(
                                          'منح جواهر 💎',
                                          Colors.blue,
                                          () => _handleUserSupport(
                                              userData, 'gems'))),
                                  const SizedBox(width: 10),
                                  Expanded(
                                      child: _buildActionButton(
                                          'منح كوينز 🪙',
                                          Colors.amber.shade700,
                                          () => _handleUserSupport(
                                              userData, 'coins'))),
                                ],
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),
                      _buildAgencyContestCard(userData),
                      const SizedBox(height: 20),
                      _buildPinOffersCard(userData),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          }),
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
        gradient: const LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)]),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.2)),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 15, offset: Offset(0, 8))
        ],
      ),
      child: Column(
        children: [
          const Text('محفظة بيت الدعم الرسمية',
              style: TextStyle(
                  color: Colors.amber,
                  fontSize: 13,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _walletItem('جواهر الدعم', agent.agencyGems.toString(),
                  Icons.diamond, Colors.blueAccent),
              Container(width: 1, height: 50, color: Colors.white10),
              _walletItem('كوينز الدعم', agent.agencyCoins.toString(),
                  Icons.monetization_on, Colors.amber),
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
        Text(val,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900)),
        Text(label,
            style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }

  Widget _buildActionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildInputField(
      TextEditingController ctrl, String hint, IconData icon,
      {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
        prefixIcon: Icon(icon, color: Colors.amber, size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none),
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
      child: Text(label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildAgencyContestCard(UserModel agent) {
    return _buildActionCard(
      title: 'إدارة تحديات بيت الدعم',
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              shape: BoxShape.circle),
          child: const Icon(Icons.emoji_events_rounded, color: Colors.amber),
        ),
        title: const Text('إطلاق تحدي نمو جديد',
            style: TextStyle(color: Colors.white, fontSize: 14)),
        subtitle: const Text('سيتم رصد الجائزة من رصيد بيت الدعم فوراً',
            style: TextStyle(color: Colors.white38, fontSize: 11)),
        trailing: const Icon(Icons.rocket_launch, color: Colors.amber),
        onTap: () => _showContestDialog(agent),
      ),
    );
  }

  Widget _buildPinOffersCard(UserModel agent) {
    return _buildActionCard(
      title: 'خدمات التثبيت الملكي',
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              shape: BoxShape.circle),
          child: const Icon(Icons.push_pin, color: Colors.amber),
        ),
        title: const Text('إضافة عرض تثبيت جديد',
            style: TextStyle(color: Colors.white, fontSize: 14)),
        subtitle: const Text('إدارة بطاقات التثبيت التي تظهر في المتجر',
            style: TextStyle(color: Colors.white38, fontSize: 11)),
        trailing: const Icon(Icons.add, color: Colors.amber),
        onTap: () => _showManagePinOffersDialog(agent),
      ),
    );
  }

  void _showCreatePinOfferDialog(UserModel agent) {
    final titleCtrl = TextEditingController();
    final priceCoinsCtrl = TextEditingController();
    final priceGemsCtrl = TextEditingController();
    final durationCtrl = TextEditingController();
    final imageUrlCtrl = TextEditingController();
    bool isActive = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          title: const Text('إنشاء عرض تثبيت',
              style: TextStyle(color: Colors.amber)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInputField(titleCtrl, 'عنوان البطاقة (مثلاً: تثبيت ذهبي)',
                    Icons.title),
                const SizedBox(height: 8),
                _buildInputField(
                    imageUrlCtrl, 'رابط صورة البطاقة (URL)', Icons.image),
                const SizedBox(height: 8),
                _buildInputField(durationCtrl, 'المدة بالأيام', Icons.timer,
                    isNumber: true),
                const SizedBox(height: 8),
                _buildInputField(
                    priceCoinsCtrl, 'سعر بالكوينز', Icons.monetization_on,
                    isNumber: true),
                const SizedBox(height: 8),
                _buildInputField(priceGemsCtrl, 'سعر بالجواهر', Icons.diamond,
                    isNumber: true),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('مفعل', style: TextStyle(color: Colors.white70)),
                    const SizedBox(width: 10),
                    Switch(
                        value: isActive,
                        onChanged: (v) => setState(() => isActive = v)),
                  ],
                )
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء')),
            ElevatedButton(
                onPressed: () async {
                  final title = titleCtrl.text.trim();
                  final imageUrl = imageUrlCtrl.text.trim();
                  final duration = int.tryParse(durationCtrl.text.trim()) ?? 1;
                  final coins = int.tryParse(priceCoinsCtrl.text.trim()) ?? 0;
                  final gems = int.tryParse(priceGemsCtrl.text.trim()) ?? 0;

                  if (title.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('يرجى إدخال عنوان')));
                    return;
                  }

                  try {
                    final offerRef = _db.collection('pin_offers').doc();
                    await offerRef.set({
                      'title': title,
                      'imageUrl': imageUrl,
                      'durationDays': duration,
                      'priceCoins': coins,
                      'priceGems': gems,
                      'isActive': isActive,
                      'createdBy': agent.uid,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('تم إنشاء عرض التثبيت بنجاح')));
                  } catch (e) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text('خطأ: $e')));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                child: const Text('حفظ')),
          ],
        );
      }),
    );
  }

  void _showManagePinOffersDialog(UserModel agent) {
    showDialog(
        context: context,
        builder: (ctx) => Dialog(
              backgroundColor: const Color(0xFF0F172A),
              child: Container(
                width: 600,
                padding: const EdgeInsets.all(12),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('قائمة عروض التثبيت',
                          style: TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold)),
                      TextButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _showCreatePinOfferDialog(agent);
                          },
                          icon: const Icon(Icons.add, color: Colors.amber),
                          label: const Text('إضافة'))
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                        stream: _db
                            .collection('pin_offers')
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, snap) {
                          if (!snap.hasData) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }
                          final docs = snap.data!.docs;
                          if (docs.isEmpty) {
                            return const Center(
                                child: Text('لا توجد عروض حالياً',
                                    style: TextStyle(color: Colors.white70)));
                          }
                          return ListView.separated(
                            shrinkWrap: true,
                            itemCount: docs.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, index) {
                              final d = docs[index];
                              final data = d.data() as Map<String, dynamic>;
                              return ListTile(
                                leading: data['imageUrl'] != null &&
                                        data['imageUrl'].toString().isNotEmpty
                                    ? CircleAvatar(
                                        backgroundImage:
                                            NetworkImage(data['imageUrl']),
                                      )
                                    : const CircleAvatar(
                                        child: Icon(Icons.push_pin)),
                                title: Text(data['title'] ?? 'عرض',
                                    style:
                                        const TextStyle(color: Colors.white)),
                                subtitle: Text(
                                    'المدة: ${data['durationDays'] ?? data['duration'] ?? '-'} يوم · سعر: ${data['priceCoins'] ?? 0} كوينز / ${data['priceGems'] ?? 0} جواهر',
                                    style:
                                        const TextStyle(color: Colors.white54)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                        onPressed: () {
                                          Navigator.pop(ctx);
                                          _showEditPinOfferDialog(d.id, data);
                                        },
                                        icon: const Icon(Icons.edit,
                                            color: Colors.amber)),
                                    IconButton(
                                        onPressed: () async {
                                          final confirm = await showDialog<
                                                  bool>(
                                              context: context,
                                              builder: (c) => AlertDialog(
                                                    backgroundColor:
                                                        const Color(0xFF0F172A),
                                                    title: const Text(
                                                        'حذف العرض',
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white)),
                                                    content: const Text(
                                                        'هل أنت متأكد من حذف هذا العرض؟',
                                                        style: TextStyle(
                                                            color: Colors
                                                                .white70)),
                                                    actions: [
                                                      TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  c, false),
                                                          child: const Text(
                                                              'إلغاء')),
                                                      ElevatedButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  c, true),
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .red),
                                                          child:
                                                              const Text('حذف'))
                                                    ],
                                                  ));
                                          if (confirm == true) {
                                            await _db
                                                .collection('pin_offers')
                                                .doc(d.id)
                                                .delete();
                                            if (mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(const SnackBar(
                                                      content: Text(
                                                          'تم حذف العرض')));
                                            }
                                          }
                                        },
                                        icon: const Icon(Icons.delete,
                                            color: Colors.redAccent)),
                                  ],
                                ),
                              );
                            },
                          );
                        }),
                  ),
                ]),
              ),
            ));
  }

  void _showEditPinOfferDialog(String docId, Map<String, dynamic> data) {
    final titleCtrl = TextEditingController(text: data['title'] ?? '');
    final imageUrlCtrl = TextEditingController(text: data['imageUrl'] ?? '');
    final durationCtrl = TextEditingController(
        text: (data['durationDays'] ?? data['duration'] ?? '').toString());
    final coinsCtrl =
        TextEditingController(text: (data['priceCoins'] ?? 0).toString());
    final gemsCtrl =
        TextEditingController(text: (data['priceGems'] ?? 0).toString());
    bool isActive = data['isActive'] ?? true;

    showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(builder: (ctx, setState) {
              return AlertDialog(
                backgroundColor: const Color(0xFF0F172A),
                title: const Text('تعديل عرض التثبيت',
                    style: TextStyle(color: Colors.amber)),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildInputField(titleCtrl, 'عنوان البطاقة', Icons.title),
                      const SizedBox(height: 8),
                      _buildInputField(
                          imageUrlCtrl, 'رابط صورة البطاقة', Icons.image),
                      const SizedBox(height: 8),
                      _buildInputField(
                          durationCtrl, 'المدة بالأيام', Icons.timer,
                          isNumber: true),
                      const SizedBox(height: 8),
                      _buildInputField(
                          coinsCtrl, 'سعر بالكوينز', Icons.monetization_on,
                          isNumber: true),
                      const SizedBox(height: 8),
                      _buildInputField(gemsCtrl, 'سعر بالجواهر', Icons.diamond,
                          isNumber: true),
                      const SizedBox(height: 8),
                      Row(children: [
                        const Text('مفعل',
                            style: TextStyle(color: Colors.white70)),
                        const SizedBox(width: 10),
                        Switch(
                            value: isActive,
                            onChanged: (v) => setState(() => isActive = v))
                      ])
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('إلغاء')),
                  ElevatedButton(
                      onPressed: () async {
                        final title = titleCtrl.text.trim();
                        final imageUrl = imageUrlCtrl.text.trim();
                        final duration =
                            int.tryParse(durationCtrl.text.trim()) ?? 1;
                        final coins = int.tryParse(coinsCtrl.text.trim()) ?? 0;
                        final gems = int.tryParse(gemsCtrl.text.trim()) ?? 0;
                        if (title.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('يرجى إدخال عنوان')));
                          return;
                        }
                        try {
                          await _db.collection('pin_offers').doc(docId).update({
                            'title': title,
                            'imageUrl': imageUrl,
                            'durationDays': duration,
                            'priceCoins': coins,
                            'priceGems': gems,
                            'isActive': isActive,
                            'updatedAt': FieldValue.serverTimestamp(),
                          });
                          Navigator.pop(ctx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('تم تحديث العرض')));
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('خطأ: $e')));
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber),
                      child: const Text('حفظ'))
                ],
              );
            }));
  }
}
