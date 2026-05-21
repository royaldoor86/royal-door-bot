import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/notifications_service.dart';

class AdminRewardsPage extends StatefulWidget {
  const AdminRewardsPage({super.key});

  @override
  State<AdminRewardsPage> createState() => _AdminRewardsPageState();
}

class _AdminRewardsPageState extends State<AdminRewardsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';
  bool _isProcessing = false;
  bool _checkingAccess = true;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  // (نقطة الأمان 3) التحقق من الصلاحيات داخل الصفحة
  Future<void> _checkAdminAccess() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final doc = await _db.collection('users').doc(user.uid).get();
    final role = doc.data()?['role'] ?? 'user';

    if (mounted) {
      if (role == 'admin' || role == 'owner') {
        setState(() {
          _checkingAccess = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('عذراً، لا تملك صلاحية الوصول لهذه الصفحة')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // (نقطة الأداء 2 و3) بحث سيرفر سايد مع ليميت
  Query _getUsersQuery() {
    Query query = _db.collection('users');
    if (_searchText.isNotEmpty) {
      // البحث بالـ Royal ID كأولوية
      return query.where('royalId', isEqualTo: _searchText).limit(1);
    }
    return query.orderBy('name').limit(25);
  }

  Future<void> _addStars(
      String uid, String userName, double currentStars) async {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1B0233),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('تعديل رصيد $userName',
              style: const TextStyle(color: Colors.white, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('الرصيد الحالي: $currentStars 🌟',
                  style: const TextStyle(color: Colors.amber, fontSize: 12)),
              const SizedBox(height: 15),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: true),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'الكمية (مثال: 100 أو -50)',
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: reasonController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'السبب (اختياري)',
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('إلغاء')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
              child: const Text('تأكيد العملية',
                  style: TextStyle(color: Colors.black)),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    // (نقطة التحقق 1) التحقق من المدخلات
    final amount = double.tryParse(amountController.text.trim());
    if (amount == null || amount == 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('يرجى إدخال مبلغ صحيح')));
      return;
    }

    // (نقطة التأكيد 5) تأكيد المبالغ الكبيرة
    if (amount.abs() >= 10000) {
      final confirmBig = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('تنبيه: مبلغ كبير!'),
          content: Text(
              'أنت على وشك تعديل الرصيد بمقدار $amount نجمة. هل أنت متأكد؟'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('تراجع')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('نعم، متأكد')),
          ],
        ),
      );
      if (confirmBig != true) return;
    }

    setState(() => _isProcessing = true);

    try {
      final adminUid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
      final batch = _db.batch();
      final userRef = _db.collection('users').doc(uid);

      // (نقطة توحيد الحقول 4) استخدام الحقل الموحد فقط
      batch.update(
          userRef, {'harvest_stars_wallet': FieldValue.increment(amount)});

      // (نقطة سجل العمليات 2) تسجيل الرصيد قبل وبعد
      final logRef = _db.collection('transactions').doc();
      batch.set(logRef, {
        'userId': uid,
        'userName': userName,
        'adminId': adminUid,
        'amount': amount,
        'balanceBefore': currentStars,
        'balanceAfter': currentStars + amount,
        'reason': reasonController.text.trim().isNotEmpty
            ? reasonController.text.trim()
            : 'تعديل إداري',
        'type': 'admin_reward_stars',
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      await NotificationsService.sendNotification(
        userId: uid,
        title: amount > 0 ? 'مكافأة ملكية 🌟' : 'تحديث رصيد 🏦',
        message:
            'تم تعديل رصيد النجوم الخاص بك بمقدار ${amount.toStringAsFixed(0)}',
        type: 'reward',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('تمت العملية بنجاح ✅'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAccess) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator(color: Colors.amber)));
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AppTheme.background(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            title: const Text('إدارة المكافآت 👑'),
          ),
          body: Column(
            children: [
              if (_isProcessing)
                const LinearProgressIndicator(color: Colors.amber),
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  onSubmitted: (v) => setState(() => _searchText = v.trim()),
                  decoration: InputDecoration(
                    hintText: 'ابحث بالآيدي الملكي (Royal ID)...',
                    prefixIcon: const Icon(Icons.search, color: Colors.amber),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15)),
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _getUsersQuery().snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                          child: Text('حدث خطأ في تحميل البيانات',
                              style: TextStyle(color: Colors.red)));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final stars =
                            _parseDouble(data['harvest_stars_wallet'] ?? 0);
                        return Card(
                          color: Colors.white.withValues(alpha: 0.05),
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: ListTile(
                            title: Text(data['name'] ?? 'مستخدم',
                                style: const TextStyle(color: Colors.white)),
                            subtitle: Text(
                                'ID: ${data['royalId']} | الرصيد: $stars 🌟',
                                style: const TextStyle(color: Colors.white54)),
                            trailing: ElevatedButton(
                              onPressed: _isProcessing
                                  ? null
                                  : () => _addStars(docs[index].id,
                                      data['name'] ?? 'مستخدم', stars),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amber),
                              child: const Text('تعديل',
                                  style: TextStyle(color: Colors.black)),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
