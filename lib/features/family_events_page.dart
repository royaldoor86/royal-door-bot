import 'package:flutter/material.dart';
import '../services/family_service.dart';
import '../models/family_event_model.dart';
import '../app_theme.dart';

class FamilyEventsPage extends StatefulWidget {
  final String familyId;
  const FamilyEventsPage({super.key, required this.familyId});

  @override
  State<FamilyEventsPage> createState() => _FamilyEventsPageState();
}

class _FamilyEventsPageState extends State<FamilyEventsPage> {
  final FamilyService _familyService = FamilyService();

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A050E),
        appBar: AppBar(
          title: const Text('أحداث العائلة',
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
          child: StreamBuilder<List<FamilyEventModel>>(
            stream: _familyService.streamFamilyEvents(widget.familyId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final events = snapshot.data!;
              if (events.isEmpty) {
                return const Center(
                    child: Text('لا توجد أحداث',
                        style: TextStyle(color: Colors.white38)));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: events.length,
                itemBuilder: (context, i) {
                  final event = events[i];
                  return AppTheme.glassContainer(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(15),
                    opacity: 0.05,
                    child: ListTile(
                      leading: const Icon(Icons.event, color: Colors.amber),
                      title: Text(event.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      subtitle: Text(event.description,
                          style: const TextStyle(color: Colors.white70)),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          await _familyService.joinFamilyEvent(event.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('تم الانضمام للحدث')));
                        },
                        child: const Text('انضمام'),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showCreateEventDialog,
          backgroundColor: Colors.amber,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _showCreateEventDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime startTime = DateTime.now();
    DateTime endTime = DateTime.now().add(const Duration(hours: 2));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A050E),
        title: const Text('إنشاء حدث', style: TextStyle(color: Colors.amber)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'العنوان')),
            TextField(
                controller: descController,
                decoration: const InputDecoration(labelText: 'الوصف')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              await _familyService.createFamilyEvent(
                widget.familyId,
                titleController.text,
                descController.text,
                startTime,
                endTime,
                {'coins': 100, 'gems': 10},
              );
              Navigator.pop(ctx);
            },
            child: const Text('إنشاء'),
          ),
        ],
      ),
    );
  }
}
