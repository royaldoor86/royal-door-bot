import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/notifications_service.dart';

class AdminPaymentsPage extends StatefulWidget {
  const AdminPaymentsPage({super.key});

  @override
  State<AdminPaymentsPage> createState() => _AdminPaymentsPageState();
}

class _AdminPaymentsPageState extends State<AdminPaymentsPage> {
  String _statusFilter = 'pending'; 
  final Color primaryEmerald = const Color(0xFF042F2C);
  final Color royalGold = const Color(0xFFC5A059);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF021412),
        appBar: AppBar(
          backgroundColor: primaryEmerald,
          elevation: 0,
          title: Text('إدارة الحوالات والمدفوعات', style: TextStyle(color: royalGold, fontWeight: FontWeight.bold)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.person_search_rounded, color: Colors.amber),
              tooltip: 'شحن مباشر للمستخدمين',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const _ManualChargeUsersPage())),
            ),
          ],
        ),
        body: Column(
          children: [
            _buildStatusFilters(),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('payments').orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: Colors.amber));
                  
                  final docs = snapshot.data?.docs.where((d) {
                    if (_statusFilter == 'all') return true;
                    return d.data()['status'] == _statusFilter;
                  }).toList() ?? [];

                  if (docs.isEmpty) return const Center(child: Text('لا توجد سجلات حالياً', style: TextStyle(color: Colors.white24)));

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data();
                      final id = docs[index].id;
                      return _buildPaymentCard(id, data);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: primaryEmerald.withOpacity(0.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _filterChip('قيد المراجعة', 'pending'),
          _filterChip('مقبولة', 'approved'),
          _filterChip('مرفوضة', 'rejected'),
          _filterChip('الكل', 'all'),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    bool isSelected = _statusFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = value),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? royalGold : Colors.white10,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.black : Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }

  Widget _buildPaymentCard(String docId, Map<String, dynamic> data) {
    String status = data['status'] ?? 'pending';
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: royalGold.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['userName'] ?? 'مستخدم ملكي', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(status == 'approved' ? 'تم الشحن ✅' : (status == 'rejected' ? 'مرفوض ❌' : 'ينتظر المراجعة ⏳'), 
                       style: TextStyle(color: status == 'approved' ? Colors.greenAccent : (status == 'rejected' ? Colors.redAccent : Colors.amber), fontSize: 11)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 24),
                onPressed: () => _confirmDelete(docId),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(data['type'] == 'gem_bundle' ? Icons.diamond : Icons.monetization_on, color: royalGold, size: 20),
              const SizedBox(width: 8),
              Text('${data['amount']} - عبر ${data['method']}', style: TextStyle(color: royalGold, fontWeight: FontWeight.w900, fontSize: 15)),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.cyanAccent.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.cyanAccent.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('بيانات التحقق المرسلة من المستخدم:', style: TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                SelectableText(
                  data['paymentRef'] ?? 'لا توجد بيانات', 
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)
                ),
              ],
            ),
          ),
          if (status == 'pending') ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _approvePayment(docId, data),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    child: const Text('موافقة وشحن', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _rejectPayment(docId, data),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent.withOpacity(0.8), padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    child: const Text('رفض الطلب', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _approvePayment(String docId, Map<String, dynamic> data) async {
    try {
      final db = FirebaseFirestore.instance;
      final type = data['type'] == 'gem_bundle' ? 'gems' : 'coins';
      final userId = data['userId'];
      final amount = data['amount'];

      await db.runTransaction((tx) async {
        final userRef = db.collection('users').doc(userId);
        final payRef = db.collection('payments').doc(docId);
        final userSnap = await tx.get(userRef);
        
        if (userSnap.exists) {
          int current = (userSnap.data()?[type] ?? 0);
          tx.update(userRef, {type: current + amount});
          tx.update(payRef, {'status': 'approved', 'processedAt': FieldValue.serverTimestamp()});
          
          _sendNotification(userId, 'تم شحن حسابك 🎉', 'لقد تمت إضافة $amount من الـ ${type == 'gems' ? "جواهر" : "كوينز"} بنجاح. استمتع!');
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت الموافقة وشحن المستخدم بنجاح ✅'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _rejectPayment(String docId, Map<String, dynamic> data) async {
    await FirebaseFirestore.instance.collection('payments').doc(docId).update({
      'status': 'rejected',
      'processedAt': FieldValue.serverTimestamp()
    });
    _sendNotification(data['userId'], 'تنبيه بخصوص طلب الشحن ⚠️', 'عذراً، تم رفض طلب الشحن الخاص بك. يرجى التأكد من صحة بيانات التحويل.');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم رفض الطلب وإبلاغ المستخدم ❌')));
  }

  void _sendNotification(String userId, String title, String body) {
    FirebaseFirestore.instance.collection('notifications').doc(userId).collection('items').add({
      'title': title,
      'body': body,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });
    NotificationsService.sendPushNotification({
      'targetUid': userId,
      'title': title,
      'body': body,
    }).catchError((e) => debugPrint("Push Error: $e"));
  }

  Future<void> _confirmDelete(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('حذف السجل نهائياً', style: TextStyle(color: Colors.white)),
        content: const Text('هل أنت متأكد من حذف هذا الطلب من السجلات؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('حذف')),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance.collection('payments').doc(docId).delete();
    }
  }
}

class _ManualChargeUsersPage extends StatefulWidget {
  const _ManualChargeUsersPage();
  @override
  State<_ManualChargeUsersPage> createState() => _ManualChargeUsersPageState();
}

class _ManualChargeUsersPageState extends State<_ManualChargeUsersPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  Future<void> _manualCharge(String uid, String name, String type, int amount, bool isAdd) async {
    try {
      int finalAmount = isAdd ? amount.abs() : -amount.abs();
      await _db.collection('users').doc(uid).update({type: FieldValue.increment(finalAmount)});
      
      String action = isAdd ? "إضافة" : "خصم";
      String currency = type == 'gems' ? "جوهرة 💎" : "كوينز 🪙";
      
      _db.collection('notifications').doc(uid).collection('items').add({
        'title': 'تحديث الرصيد الملكي',
        'body': 'لقد تم $action ${amount.abs()} $currency لحسابك من قبل الإدارة.',
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التحديث وإرسال الإشعار بنجاح ✅'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1A24),
      appBar: AppBar(
        backgroundColor: const Color(0xFF042F2C),
        title: const Text('شحن وخصم ملكي مباشر', style: TextStyle(color: Color(0xFFC5A059), fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchText = v.toLowerCase()),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'ابحث عن ملك (الاسم أو الآيدي)...',
                hintStyle: const TextStyle(color: Colors.white24),
                prefixIcon: const Icon(Icons.search, color: Colors.amber),
                filled: true, fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _db.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs.where((d) {
                  final data = d.data();
                  String n = (data['name'] ?? '').toString().toLowerCase();
                  String rid = (data['royalId'] ?? '').toString().toLowerCase();
                  return n.contains(_searchText) || rid.contains(_searchText);
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data();
                    final uid = docs[i].id;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 25,
                          backgroundColor: Colors.amber.withOpacity(0.1),
                          backgroundImage: (data['profilePic'] ?? '').isNotEmpty ? NetworkImage(data['profilePic']) : null,
                          child: (data['profilePic'] ?? '').isEmpty ? const Icon(Icons.person, color: Colors.amber) : null,
                        ),
                        title: Text(data['name'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: Text('ID: ${data['royalId']} | 💎 ${data['gems']} | 🪙 ${data['coins']}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildCurrencyButton(uid, data['name'], 'gems', Icons.diamond, Colors.cyanAccent),
                            const SizedBox(width: 12),
                            _buildCurrencyButton(uid, data['name'], 'coins', Icons.monetization_on, Colors.amber),
                          ],
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
    );
  }

  Widget _buildCurrencyButton(String uid, String name, String type, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => _showManagementDialog(uid, name, type, icon, color),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
    );
  }

  void _showManagementDialog(String uid, String name, String type, IconData icon, Color color) {
    final ctrl = TextEditingController();
    String currencyName = type == 'gems' ? "الجواهر" : "الكوينز";
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: color.withOpacity(0.3))),
          title: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Expanded(child: Text('إدارة $currencyName لـ $name', style: const TextStyle(color: Colors.white, fontSize: 16))),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'أدخل الكمية هنا...',
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        int amt = int.tryParse(ctrl.text) ?? 0;
                        if (amt > 0) {
                          _manualCharge(uid, name, type, amt, true);
                          Navigator.pop(ctx);
                        }
                      },
                      icon: const Icon(Icons.add_circle_outline, size: 18),
                      label: const Text('إضافة'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        int amt = int.tryParse(ctrl.text) ?? 0;
                        if (amt > 0) {
                          _manualCharge(uid, name, type, amt, false);
                          Navigator.pop(ctx);
                        }
                      },
                      icon: const Icon(Icons.remove_circle_outline, size: 18),
                      label: const Text('خصم'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
