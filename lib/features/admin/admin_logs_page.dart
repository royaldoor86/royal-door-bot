import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../services/admin_logs_service.dart';

class AdminLogsPage extends StatelessWidget {
  const AdminLogsPage({super.key});

  final Color primaryDark = const Color(0xFF0A1F1C);
  final Color accentGold = const Color(0xFFC5A059);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: primaryDark,
        appBar: AppBar(
          title: Text('سجل العمليات الإدارية 📜', style: TextStyle(color: accentGold, fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF051211),
          centerTitle: true,
        ),
        body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: AdminLogsService.adminLogsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text("لا توجد سجلات بعد", style: TextStyle(color: Colors.white54)));
            }

            final logs = snapshot.data!.docs;

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index].data();
                final timestamp = (log['timestamp'] as Timestamp).toDate();
                return _buildLogCard(log, timestamp);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log, DateTime timestamp) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontFamily: 'YourFontFamily', fontSize: 13, color: Colors.white70),
          children: [
            TextSpan(text: '${DateFormat('HH:mm').format(timestamp)} - ', style: TextStyle(color: accentGold, fontWeight: FontWeight.bold)),
            TextSpan(text: '${log['adminName'] ?? 'مشرف'}', style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            TextSpan(text: ' ${log['action']} '),
            TextSpan(text: '${log['targetName'] ?? ''}', style: const TextStyle(color: Colors.orangeAccent)),
            if (log['details'] != null) TextSpan(text: ' (${log['details']})', style: const TextStyle(fontSize: 11, color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}
