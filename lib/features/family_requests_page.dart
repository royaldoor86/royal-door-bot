import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/family_service.dart';
import '../app_theme.dart';

class FamilyRequestsPage extends StatefulWidget {
  final String familyId;
  const FamilyRequestsPage({super.key, required this.familyId});

  @override
  State<FamilyRequestsPage> createState() => _FamilyRequestsPageState();
}

class _FamilyRequestsPageState extends State<FamilyRequestsPage>
    with SingleTickerProviderStateMixin {
  final FamilyService _familyService = FamilyService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A050E),
        appBar: AppBar(
          title: const Text('طلبات الانضمام',
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'المعلقة'),
              Tab(text: 'المقبولة'),
              Tab(text: 'المرفوضة'),
            ],
            labelColor: Colors.amber,
            unselectedLabelColor: Colors.white54,
            indicatorColor: Colors.amber,
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3D0B16), Color(0xFF1A050E)],
            ),
          ),
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildRequestsList('pending'),
              _buildRequestsList('accepted'),
              _buildRequestsList('rejected'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestsList(String status) {
    return Column(
      children: [
        _buildStatisticsSection(),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('families')
                .doc(widget.familyId)
                .collection('requests')
                .where('status', isEqualTo: status)
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.amber));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    status == 'pending'
                        ? 'لا توجد طلبات معلقة'
                        : (status == 'accepted'
                            ? 'لا توجد طلبات مقبولة'
                            : 'لا توجد طلبات مرفوضة'),
                    style: const TextStyle(color: Colors.white38),
                  ),
                );
              }

              final requests = snapshot.data!.docs;
              return ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final req = requests[index].data() as Map<String, dynamic>;
                  final String uid = req['uid'];
                  final String requestId = requests[index].id;

                  return _buildRequestCard(req, uid, requestId, status);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('families')
          .doc(widget.familyId)
          .collection('requests')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final requests = snapshot.data!.docs;
        int pending = 0;
        int accepted = 0;
        int rejected = 0;

        for (var doc in requests) {
          final req = doc.data() as Map<String, dynamic>;
          final status = req['status'] ?? 'pending';
          if (status == 'pending') pending++;
          if (status == 'accepted') accepted++;
          if (status == 'rejected') rejected++;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('المعلقة', pending, Colors.orange),
              _buildStatItem('المقبولة', accepted, Colors.green),
              _buildStatItem('المرفوضة', rejected, Colors.red),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildRequestCard(
      Map<String, dynamic> req, String uid, String requestId, String status) {
    return AppTheme.glassContainer(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: (req['profilePic'] != null &&
                        req['profilePic'].toString().isNotEmpty)
                    ? NetworkImage(req['profilePic'])
                    : null,
                child: (req['profilePic'] == null ||
                        req['profilePic'].toString().isEmpty)
                    ? const Icon(Icons.person, color: Colors.amber)
                    : null,
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      req['name'] ?? 'مستخدم',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'المستوى ${req['level'] ?? 1}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.calendar_today,
                            color: Colors.white38, size: 12),
                        const SizedBox(width: 4),
                        if (req['timestamp'] != null)
                          Text(
                            _formatDate(req['timestamp']),
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 12),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (req['message'] != null && req['message'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.message, color: Colors.amber, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        req['message'],
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          if (status == 'pending')
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await _familyService.acceptJoinRequest(
                            widget.familyId, uid);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم قبول الطلب بنجاح'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('فشل: $e')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.check_circle, size: 18),
                    label: const Text('قبول'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        await _familyService.rejectJoinRequest(
                            widget.familyId, uid);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('تم رفض الطلب'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('فشل: $e')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.cancel, size: 18),
                    label: const Text('رفض'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            )
          else
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: status == 'accepted'
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.red.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: status == 'accepted' ? Colors.green : Colors.red,
                  ),
                ),
                child: Text(
                  status == 'accepted' ? 'تم القبول' : 'تم الرفض',
                  style: TextStyle(
                    color: status == 'accepted' ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays} يوم';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} ساعة';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} دقيقة';
      } else {
        return 'الآن';
      }
    }
    return '';
  }
}
