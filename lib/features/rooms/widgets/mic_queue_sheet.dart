import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart' as intl;
import '../../../app_theme.dart';

class MicQueueSheet extends StatelessWidget {
  final String roomId;
  final bool hasPower;
  final Function(String userId, String name, String photoUrl) onApprove;

  const MicQueueSheet({
    super.key,
    required this.roomId,
    required this.hasPower,
    required this.onApprove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F1B25), Color(0xFF070C11)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
        boxShadow: [
          BoxShadow(color: Colors.black54, blurRadius: 20, spreadRadius: 5)
        ],
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 50,
            height: 5,
            decoration: BoxDecoration(
                color: Colors.white12, borderRadius: BorderRadius.circular(10)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.royalGold.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic_external_on_rounded, color: AppTheme.royalGold, size: 24),
                ),
                const SizedBox(width: 15),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('قائمة الانتظار الملكية',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    Text('تحكم في طابور المايك بذكاء',
                        style: TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
                const Spacer(),
                if (hasPower)
                  _buildHeaderAction(
                    label: 'مسح الكل',
                    icon: Icons.delete_sweep_rounded,
                    color: Colors.redAccent,
                    onTap: () => _showClearConfirm(context),
                  ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rooms')
                  .doc(roomId)
                  .collection('mic_requests')
                  .where('status', isEqualTo: 'pending')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.royalGold));
                }
                final requests = snapshot.data?.docs ?? [];
                if (requests.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final doc = requests[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildRequestItem(context, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAction({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.hourglass_empty_rounded, size: 70, color: Colors.white.withValues(alpha: 0.05)),
        ),
        const SizedBox(height: 25),
        const Text('لا توجد طلبات انتظار حالياً',
            style: TextStyle(color: Colors.white38, fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        const Text('سيظهر المستخدمون هنا عند طلبهم صعود المايك',
            style: TextStyle(color: Colors.white12, fontSize: 12)),
      ],
    );
  }

  Widget _buildRequestItem(BuildContext context, Map<String, dynamic> data) {
    final userId = data['userId'] ?? '';
    final name = data['name'] ?? 'مستخدم ملكي';
    final photoUrl = data['photoUrl'] ?? '';
    final Timestamp? ts = data['timestamp'] as Timestamp?;
    final timeStr = ts != null ? intl.DateFormat('HH:mm').format(ts.toDate()) : 'الآن';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: Colors.transparent,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            leading: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.royalGold.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.black54,
                    backgroundImage: photoUrl.isNotEmpty ? CachedNetworkImageProvider(photoUrl) : null,
                    child: photoUrl.isEmpty ? const Icon(Icons.person, color: Colors.white24, size: 30) : null,
                  ),
                ),
                if (hasPower)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                    child: const Icon(Icons.online_prediction, color: Colors.white, size: 10),
                  ),
                ),
              ],
            ),
            title: Text(name,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            subtitle: Row(
              children: [
                const Icon(Icons.access_time, color: Colors.white24, size: 12),
                const SizedBox(width: 4),
                Text('طلب في $timeStr',
                    style: const TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
            trailing: hasPower
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildControlBtn(
                        icon: Icons.check_circle_rounded,
                        color: Colors.greenAccent,
                        label: 'قبول',
                        onTap: () => onApprove(userId, name, photoUrl),
                      ),
                      const SizedBox(width: 12),
                      _buildControlBtn(
                        icon: Icons.cancel_rounded,
                        color: Colors.redAccent,
                        label: 'رفض',
                        onTap: () => _rejectRequest(userId),
                      ),
                    ],
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.royalGold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('قيد الانتظار', 
                      style: TextStyle(color: AppTheme.royalGold, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildControlBtn({required IconData icon, required Color color, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _rejectRequest(String userId) {
    FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .collection('mic_requests')
        .doc(userId)
        .update({'status': 'rejected'});
  }

  void _showClearConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1B25),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('مسح جميع الطلبات؟', style: TextStyle(color: Colors.white)),
        content: const Text('سيتم رفض جميع طلبات الانتظار الحالية.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _clearAllRequests();
            }, 
            child: const Text('تأكيد المسح', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }

  void _clearAllRequests() async {
    final batch = FirebaseFirestore.instance.batch();
    final snap = await FirebaseFirestore.instance
        .collection('rooms')
        .doc(roomId)
        .collection('mic_requests')
        .get();
    for (var doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
