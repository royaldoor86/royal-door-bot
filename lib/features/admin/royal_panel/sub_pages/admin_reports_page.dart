import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../services/notifications_service.dart';
import 'package:intl/intl.dart' hide TextDirection;

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Color primaryDark = const Color(0xFF0A1F1C);
  final Color royalRed = const Color(0xFFE53935);
  final Color accentGold = const Color(0xFFC5A059);
  String _filterType = 'الكل';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: primaryDark,
        appBar: AppBar(
          backgroundColor: const Color(0xFF051211),
          title: Text('مركز الرقابة والسيادة ⚖️', style: TextStyle(color: accentGold, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: Column(
          children: [
            _buildQuickStats(),
            _buildFilterTabs(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _db.collection('reports').orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.amber));
                  }
                  var docs = snapshot.data?.docs ?? [];
                  if (_filterType != 'الكل') {
                    docs = docs.where((d) => (d.data() as Map)['type'] == _filterType).toList();
                  }
                  if (docs.isEmpty) return _buildEmptyState();
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final data = docs[index].data() as Map<String, dynamic>;
                      return _buildReportCard(docs[index].id, data);
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

  Widget _buildQuickStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('reports').where('status', isEqualTo: 'new').snapshots(),
      builder: (context, snapshot) {
        int newReports = snapshot.data?.docs.length ?? 0;
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(color: royalRed.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: royalRed.withValues(alpha: 0.3))),
                child: Text('بلاغات لم تُعالج: $newReports 🚩', style: TextStyle(color: royalRed, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterTabs() {
    final types = ['الكل', 'مستخدم', 'غرفة', 'منشور'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: types.map((t) => Padding(
          padding: const EdgeInsets.only(left: 8),
          child: ChoiceChip(
            label: Text(t),
            selected: _filterType == t,
            onSelected: (v) => setState(() => _filterType = t),
            selectedColor: accentGold,
            labelStyle: TextStyle(color: _filterType == t ? Colors.black : Colors.white70),
            backgroundColor: Colors.white.withValues(alpha: 0.05),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildReportCard(String docId, Map<String, dynamic> data) {
    final String status = data['status'] ?? 'new';
    final Color statusColor = status == 'new' ? Colors.red : (status == 'pending' ? Colors.orange : Colors.green);
    final String statusText = status == 'new' ? 'جديد 🔴' : (status == 'pending' ? 'قيد المراجعة 🟡' : 'مكتمل 🟢');

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              if (data['createdAt'] != null)
                Text(DateFormat('HH:mm | yyyy/MM/dd').format((data['createdAt'] as Timestamp).toDate()), style: const TextStyle(color: Colors.white24, fontSize: 10)),
            ],
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(backgroundColor: accentGold.withValues(alpha: 0.1), child: Icon(_getIconForType(data['type']), color: accentGold)),
            title: Text('البلاغ عن ${data['type'] ?? 'هدف'}: ${data['targetName']}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text('المبلّغ: ${data['reporterName']}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
            trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.white24), onPressed: () => _db.collection('reports').doc(docId).delete()),
          ),
          const Divider(color: Colors.white10),
          Text('📌 السبب: ${data['reason']}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          if (data['description'] != null) ...[
            const SizedBox(height: 5),
            Text('📝 الوصف: ${data['description']}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
          ],
          const SizedBox(height: 15),
          Row(
            children: [
              _buildActionBtn('حظر', Icons.block, royalRed, () => _banUser(data['targetId'], data['targetName'])),
              const SizedBox(width: 8),
              _buildActionBtn('كتم', Icons.mic_off, Colors.orange, () => _muteUser(data['targetId'], data['targetName'])),
              const SizedBox(width: 8),
              _buildActionBtn('تحذير', Icons.warning_amber, Colors.blue, () => _warnUser(data['targetId'], data['targetName'])),
              const SizedBox(width: 8),
              _buildActionBtn('تجاهل', Icons.done_all, Colors.white24, () => _ignoreReport(docId, data['reporterId'])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withValues(alpha: 0.2))),
          child: Column(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'غرفة': return Icons.meeting_room;
      case 'منشور': return Icons.post_add;
      default: return Icons.person;
    }
  }

  Future<void> _muteUser(String uid, String name) async {
    await _db.collection('users').doc(uid).update({'isMuted': true});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم كتم صوت $name نجاح 🤐')));
  }

  Future<void> _warnUser(String uid, String name) async {
    _sendInAppNotification(uid, 'تحذير ملكي أخير ⚠️', 'لقد تم رصد مخالفة في سلوكك. تكرار المخالفة سيؤدي للحظر النهائي.');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تم إرسال تحذير لـ $name ⚠️')));
  }

  Future<void> _banUser(String uid, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('تأكيد الحظر الملكي'),
        content: Text('هل أنت متأكد من حظر $name نهائياً؟ لن يتمكن من دخول التطبيق أبداً.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('حظر الآن')),
        ],
      ),
    );
    if (confirm == true) {
      await _db.collection('users').doc(uid).update({'isBanned': true, 'isActive': false});
      NotificationsService.sendPushNotification({
        'targetUid': uid,
        'title': 'تنبيه إداري عاجل 🚫',
        'body': 'لقد تم حظر حسابك نهائياً من رويال دور لمخالفة القوانين.',
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نفي المستخدم من المملكة بنجاح 🚫')));
    }
  }

  Future<void> _ignoreReport(String docId, String reporterId) async {
    await _db.collection('reports').doc(docId).delete();
    _sendInAppNotification(reporterId, 'تحديث البلاغ ⚠️', 'تمت مراجعة بلاغك وتبيّن أنه غير دقيق. يرجى تحري الدقة مستقبلاً.');
  }

  void _sendInAppNotification(String userId, String title, String body) {
    _db.collection('notifications').doc(userId).collection('items').add({
      'title': title,
      'body': body,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_user_rounded, size: 80, color: accentGold.withValues(alpha: 0.1)),
          const SizedBox(height: 16),
          const Text('المملكة آمنة حالياً، لا توجد بلاغات', style: TextStyle(color: Colors.white24, fontSize: 16)),
        ],
      ),
    );
  }
}
