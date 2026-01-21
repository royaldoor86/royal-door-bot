import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../services/notifications_service.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({Key? key}) : super(key: key);

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Color primaryDark = const Color(0xFF0A1F1C);
  final Color royalRed = const Color(0xFFE53935);
  final Color accentGold = const Color(0xFFC5A059);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: primaryDark,
        appBar: AppBar(
          backgroundColor: const Color(0xFF051211),
          title: Text('مركز الرقابة والبلاغات الملكية', style: TextStyle(color: accentGold, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _db.collection('reports').orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.amber));
            }
            final docs = snapshot.data?.docs ?? [];
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
    );
  }

  Widget _buildReportCard(String docId, Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: royalRed.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(backgroundColor: royalRed.withOpacity(0.1), child: Icon(Icons.report_problem, color: royalRed)),
            title: Text('بلاغ عن: ${data['targetName'] ?? 'مستخدم'}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            subtitle: Text('المبلّغ: ${data['reporterName']}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
            trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.white24), onPressed: () => _db.collection('reports').doc(docId).delete()),
          ),
          const Divider(color: Colors.white10),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text('السبب: ${data['reason']}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _banUser(data['targetId'], data['targetName']),
                  icon: const Icon(Icons.block, size: 16),
                  label: const Text('حظر نهائي'),
                  style: ElevatedButton.styleFrom(backgroundColor: royalRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _ignoreReport(docId, data['reporterId']),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text('تجاهل وبلاغ كاذب', style: TextStyle(color: Colors.white54, fontSize: 11)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
      // إرسال إشعار خارج التطبيق (Push) للمخالف
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
          Icon(Icons.verified_user_rounded, size: 80, color: accentGold.withOpacity(0.1)),
          const SizedBox(height: 16),
          const Text('المملكة آمنة حالياً، لا توجد بلاغات', style: TextStyle(color: Colors.white24, fontSize: 16)),
        ],
      ),
    );
  }
}
