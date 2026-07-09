import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/family_service.dart';
import '../models/family_event_model.dart';
import '../app_theme.dart';
import 'dart:ui' as ui;

class FamilyEventsManagementPage extends StatefulWidget {
  final String familyId;
  final String familyName;

  const FamilyEventsManagementPage({
    super.key,
    required this.familyId,
    required this.familyName,
  });

  @override
  State<FamilyEventsManagementPage> createState() =>
      _FamilyEventsManagementPageState();
}

class _FamilyEventsManagementPageState
    extends State<FamilyEventsManagementPage> {
  final FamilyService _familyService = FamilyService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A050E),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'إدارة الأحداث',
            style: TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.amber),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add, color: Colors.amber),
              onPressed: () => _showCreateEventDialog(),
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3D0B16), Color(0xFF1A050E)],
            ),
          ),
          child: StreamBuilder<List<FamilyEventModel>>(
            stream: _familyService.streamFamilyEvents(widget.familyId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.amber),
                );
              }

              final events = snapshot.data!;

              if (events.isEmpty) {
                return const Center(
                  child: Text(
                    'لا توجد أحداث حالياً',
                    style: TextStyle(color: Colors.white38),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return _buildEventCard(event);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(FamilyEventModel event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: AppTheme.glassContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان
            Text(
              event.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // الوصف
            if (event.description.isNotEmpty)
              Text(
                event.description,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            if (event.description.isNotEmpty) const SizedBox(height: 12),

            // التاريخ والوقت
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.amber, size: 16),
                const SizedBox(width: 8),
                Text(
                  _formatTimestamp(event.startTime),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, color: Colors.amber, size: 16),
                const SizedBox(width: 8),
                Text(
                  _formatTimestamp(event.endTime),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // المشاركون
            Row(
              children: [
                const Icon(Icons.people, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${event.participants.length} مشارك',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),

            // الأزرار
            const SizedBox(height: 12),
            AppTheme.gradientButton(
              text: 'التفاصيل',
              onPressed: () => _showEventDetailsDialog(event),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateEventDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D0F1A),
        title: const Text(
          'إنشاء حدث جديد',
          style: TextStyle(color: Colors.amber),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'عنوان الحدث',
                  labelStyle: const TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'الوصف',
                  labelStyle: const TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              ListTile(
                title: const Text('تاريخ البدء',
                    style: TextStyle(color: Colors.white)),
                subtitle: Text(
                  _selectedStartDate != null
                      ? _formatDate(_selectedStartDate!)
                      : 'اختر التاريخ',
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: const Icon(Icons.calendar_today, color: Colors.amber),
                onTap: () => _selectStartDate(context),
              ),
              ListTile(
                title: const Text('تاريخ الانتهاء',
                    style: TextStyle(color: Colors.white)),
                subtitle: Text(
                  _selectedEndDate != null
                      ? _formatDate(_selectedEndDate!)
                      : 'اختر التاريخ',
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: const Icon(Icons.calendar_today, color: Colors.amber),
                onTap: () => _selectEndDate(context),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.white70)),
          ),
          AppTheme.gradientButton(
            text: 'إنشاء',
            onPressed: () => _createEvent(),
          ),
        ],
      ),
    );
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedStartDate = picked);
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedEndDate = picked);
    }
  }

  Future<void> _createEvent() async {
    if (_titleController.text.isEmpty ||
        _selectedStartDate == null ||
        _selectedEndDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى ملء جميع الحقول المطلوبة')),
      );
      return;
    }

    try {
      await _familyService.createFamilyEvent(
        widget.familyId,
        _titleController.text,
        _descriptionController.text,
        _selectedStartDate!,
        _selectedEndDate!,
        {},
      );

      Navigator.pop(context);
      _titleController.clear();
      _descriptionController.clear();
      setState(() {
        _selectedStartDate = null;
        _selectedEndDate = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنشاء الحدث بنجاح')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    }
  }

  void _showEventDetailsDialog(FamilyEventModel event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D0F1A),
        title: Text(
          event.title,
          style: const TextStyle(color: Colors.amber),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.description,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    _formatTimestamp(event.startTime),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    _formatTimestamp(event.endTime),
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'المشاركون: ${event.participants.length}',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
