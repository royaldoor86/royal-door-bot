import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  final _replyController = TextEditingController();

  Future<void> _showReportDetails(
      String reportId, Map<String, dynamic> data) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B0233),
        title: const Text("تفاصيل البلاغ والرد",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("المُبلّغ عنه: ${data['targetUserName'] ?? 'غير معروف'}",
                  style: const TextStyle(color: Colors.amber)),
              const SizedBox(height: 10),
              Text("السبب: ${data['reason'] ?? ''}",
                  style: const TextStyle(color: Colors.white70)),
              const Divider(color: Colors.white10, height: 30),
              const Text("الرد الإداري:",
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              const SizedBox(height: 10),
              TextField(
                controller: _replyController..text = data['adminReply'] ?? "",
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  hintText: "اكتب ردك هنا...",
                  hintStyle: const TextStyle(color: Colors.white24),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('reports')
                  .doc(reportId)
                  .update({
                'adminReply': _replyController.text,
                'status': 'resolved',
                'resolvedAt': FieldValue.serverTimestamp(),
              });
              if (mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("إرسال الرد وإغلاق"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
            padding: EdgeInsets.all(16),
            child: Text("إدارة البلاغات والشكاوى ⚠️",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold))),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('reports')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(
                    child: CircularProgressIndicator(color: Colors.amber));
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final bool isResolved = data['status'] == 'resolved';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                      leading: Icon(
                          isResolved ? Icons.check_circle : Icons.error_outline,
                          color: isResolved ? Colors.green : Colors.redAccent),
                      title: Text(data['reason'] ?? "بلاغ جديد",
                          style: const TextStyle(color: Colors.white)),
                      subtitle: Text("من: ${data['reporterName'] ?? 'مستخدم'}",
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 11)),
                      trailing: ElevatedButton(
                        onPressed: () => _showReportDetails(doc.id, data),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white10),
                        child: const Text("معاينة",
                            style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
