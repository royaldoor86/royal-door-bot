import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/family_service.dart';
import '../models/family_notification_model.dart';
import '../app_theme.dart';

class FamilyNotificationsPage extends StatefulWidget {
  final String familyId;
  const FamilyNotificationsPage({super.key, required this.familyId});

  @override
  State<FamilyNotificationsPage> createState() =>
      _FamilyNotificationsPageState();
}

class _FamilyNotificationsPageState extends State<FamilyNotificationsPage> {
  final FamilyService _familyService = FamilyService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String _selectedFilter = 'all';

  final Map<String, String> _filterNames = {
    'all': 'الكل',
    'unread': 'غير مقروءة',
    'join': 'الانضمام',
    'war': 'الحروب',
    'task': 'المهام',
    'level_up': 'الترقية',
    'event': 'الأحداث',
  };

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A050E),
        appBar: AppBar(
          title: const Text('إشعارات العائلة',
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.amber),
              onPressed: _markAllAsRead,
            ),
          ],
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
              _buildFilterSection(),
              Expanded(
                child: StreamBuilder<List<FamilyNotificationModel>>(
                  stream:
                      _familyService.streamFamilyNotifications(widget.familyId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                          child:
                              CircularProgressIndicator(color: Colors.amber));
                    }
                    final notifications = snapshot.data!;
                    final filteredNotifications =
                        _filterNotifications(notifications);

                    if (filteredNotifications.isEmpty) {
                      return const Center(
                          child: Text('لا توجد إشعارات',
                              style: TextStyle(color: Colors.white38)));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: filteredNotifications.length,
                      itemBuilder: (context, i) {
                        final notif = filteredNotifications[i];
                        return _buildNotificationCard(notif);
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

  Widget _buildFilterSection() {
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

  List<FamilyNotificationModel> _filterNotifications(
      List<FamilyNotificationModel> notifications) {
    if (_selectedFilter == 'all') return notifications;
    if (_selectedFilter == 'unread')
      return notifications.where((n) => !n.isRead).toList();
    return notifications.where((n) => n.type == _selectedFilter).toList();
  }

  Widget _buildNotificationCard(FamilyNotificationModel notif) {
    return AppTheme.glassContainer(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      opacity: notif.isRead ? 0.05 : 0.1,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            if (!notif.isRead) {
              await _familyService.markNotificationAsRead(notif.id);
            }
          },
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      _getNotificationColor(notif.type).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIcon(notif.type),
                  color: _getNotificationColor(notif.type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notif.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notif.message,
                      style:
                          const TextStyle(color: Colors.white38, fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (!notif.isRead)
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'join':
        return Colors.green;
      case 'war':
        return Colors.red;
      case 'task':
        return Colors.blue;
      case 'level_up':
        return Colors.amber;
      case 'event':
        return Colors.purple;
      default:
        return Colors.white;
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'join':
        return Icons.person_add;
      case 'war':
        return Icons.shield;
      case 'task':
        return Icons.task;
      case 'level_up':
        return Icons.upgrade;
      case 'event':
        return Icons.event;
      default:
        return Icons.notifications;
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final notifications = await _db
          .collection('family_notifications')
          .where('familyId', isEqualTo: widget.familyId)
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _db.batch();
      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديد جميع الإشعارات كمقروءة ✅')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      }
    }
  }
}
