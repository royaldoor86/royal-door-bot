import 'package:flutter/material.dart';
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
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3D0B16), Color(0xFF1A050E), Color(0xFF000000)],
            ),
          ),
          child: StreamBuilder<List<FamilyNotificationModel>>(
            stream: _familyService.streamFamilyNotifications(widget.familyId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final notifications = snapshot.data!;
              if (notifications.isEmpty) {
                return const Center(
                    child: Text('لا توجد إشعارات',
                        style: TextStyle(color: Colors.white38)));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: notifications.length,
                itemBuilder: (context, i) {
                  final notif = notifications[i];
                  return AppTheme.glassContainer(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(15),
                    opacity: notif.isRead ? 0.05 : 0.1,
                    child: ListTile(
                      leading: Icon(_getIcon(notif.type), color: Colors.amber),
                      title: Text(notif.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      subtitle: Text(notif.message,
                          style: const TextStyle(color: Colors.white70)),
                      trailing: !notif.isRead
                          ? const Icon(Icons.circle,
                              color: Colors.red, size: 10)
                          : null,
                      onTap: () async {
                        if (!notif.isRead) {
                          await _familyService.markNotificationAsRead(notif.id);
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
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
}
