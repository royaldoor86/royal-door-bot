import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_theme.dart';

class FamilyActivityLogPage extends StatefulWidget {
  final String familyId;
  const FamilyActivityLogPage({super.key, required this.familyId});

  @override
  State<FamilyActivityLogPage> createState() => _FamilyActivityLogPageState();
}

class _FamilyActivityLogPageState extends State<FamilyActivityLogPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String _selectedFilter = 'all';

  final Map<String, String> _filterNames = {
    'all': 'الكل',
    'join': 'الانضمام',
    'leave': 'المغادرة',
    'promotion': 'الترقية',
    'demotion': 'التخفيض',
    'war': 'الحروب',
    'event': 'الأحداث',
    'vote': 'التصويت',
  };

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A050E),
        appBar: AppBar(
          title: const Text('سجل أنشطة العائلة',
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3D0B16), Color(0xFF1A050E), Color(0x00000000)],
            ),
          ),
          child: Column(
            children: [
              _buildFilterChips(),
              Expanded(
                child: _buildActivityLog(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return AppTheme.glassContainer(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filterNames.entries.map((entry) {
            final isSelected = _selectedFilter == entry.key;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: ChoiceChip(
                label: Text(entry.value),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedFilter = entry.key);
                },
                selectedColor: Colors.amber.withValues(alpha: 0.3),
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.amber : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildActivityLog() {
    Query query = _db
        .collection('families')
        .doc(widget.familyId)
        .collection('activity_log')
        .orderBy('timestamp', descending: true);

    if (_selectedFilter != 'all') {
      query = query.where('type', isEqualTo: _selectedFilter);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.limit(100).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: Colors.amber));
        }
        final activities = snapshot.data!.docs;
        if (activities.isEmpty) {
          return const Center(
            child: Text('لا توجد أنشطة',
                style: TextStyle(color: Colors.white38)),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index].data() as Map<String, dynamic>;
            return _buildActivityTile(activity);
          },
        );
      },
    );
  }

  Widget _buildActivityTile(Map<String, dynamic> activity) {
    final type = activity['type'] ?? 'unknown';
    final timestamp = activity['timestamp'] as Timestamp?;
    final userName = activity['userName'] ?? 'مستخدم غير معروف';
    final description = activity['description'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getActivityColor(type).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getActivityIcon(type),
              color: _getActivityColor(type),
              size: 24,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getActivityColor(type).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getActivityName(type),
                        style: TextStyle(
                            color: _getActivityColor(type), fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (timestamp != null)
                  Text(
                    _formatTimestamp(timestamp),
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'join':
        return Icons.login;
      case 'leave':
        return Icons.logout;
      case 'promotion':
        return Icons.arrow_upward;
      case 'demotion':
        return Icons.arrow_downward;
      case 'war':
        return Icons.shield;
      case 'event':
        return Icons.event;
      case 'vote':
        return Icons.how_to_vote;
      default:
        return Icons.info;
    }
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'join':
        return Colors.green;
      case 'leave':
        return Colors.red;
      case 'promotion':
        return Colors.amber;
      case 'demotion':
        return Colors.orange;
      case 'war':
        return Colors.redAccent;
      case 'event':
        return Colors.purple;
      case 'vote':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getActivityName(String type) {
    switch (type) {
      case 'join':
        return 'انضم';
      case 'leave':
        return 'غادر';
      case 'promotion':
        return 'ترقية';
      case 'demotion':
        return 'تخفيض';
      case 'war':
        return 'حرب';
      case 'event':
        return 'حدث';
      case 'vote':
        return 'تصويت';
      default:
        return 'نشاط';
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inHours < 1) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inDays < 1) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
