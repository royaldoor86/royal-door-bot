import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/family_service.dart';
import '../app_theme.dart';

class FamilyEventsPage extends StatefulWidget {
  final String familyId;
  const FamilyEventsPage({super.key, required this.familyId});

  @override
  State<FamilyEventsPage> createState() => _FamilyEventsPageState();
}

class _FamilyEventsPageState extends State<FamilyEventsPage> {
  final FamilyService _familyService = FamilyService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  DateTime _selectedMonth = DateTime.now();

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
              colors: [Color(0xFF3D0B16), Color(0xFF1A050E), Color(0x00000000)],
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildCalendarHeader(),
                const SizedBox(height: 20),
                _buildCalendarGrid(),
                const SizedBox(height: 20),
                _buildUpcomingEvents(),
              ],
            ),
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

  Widget _buildCalendarHeader() {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () {
              setState(() {
                _selectedMonth =
                    DateTime(_selectedMonth.year, _selectedMonth.month - 1);
              });
            },
            icon: const Icon(Icons.chevron_right, color: Colors.amber),
          ),
          Text(
            '${_getMonthName(_selectedMonth.month)} ${_selectedMonth.year}',
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _selectedMonth =
                    DateTime(_selectedMonth.year, _selectedMonth.month + 1);
              });
            },
            icon: const Icon(Icons.chevron_left, color: Colors.amber),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDayOfMonth =
        DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final startingWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('أحد',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
              Text('إثنين',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
              Text('ثلاثاء',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
              Text('أربعاء',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
              Text('خميس',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
              Text('جمعة',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
              Text('سبت',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('family_events')
                .where('familyId', isEqualTo: widget.familyId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.amber));
              }
              final events = snapshot.data!.docs;
              final eventDates = <int>{};
              for (var event in events) {
                final data = event.data() as Map<String, dynamic>;
                final startTime = (data['startTime'] as Timestamp).toDate();
                if (startTime.year == _selectedMonth.year &&
                    startTime.month == _selectedMonth.month) {
                  eventDates.add(startTime.day);
                }
              }

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1,
                ),
                itemCount: startingWeekday + daysInMonth,
                itemBuilder: (context, index) {
                  if (index < startingWeekday) {
                    return const SizedBox();
                  }
                  final day = index - startingWeekday + 1;
                  final hasEvent = eventDates.contains(day);
                  final isToday = day == DateTime.now().day &&
                      _selectedMonth.month == DateTime.now().month &&
                      _selectedMonth.year == DateTime.now().year;

                  return GestureDetector(
                    onTap: () => _showDayEvents(day),
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isToday
                            ? Colors.amber.withValues(alpha: 0.3)
                            : (hasEvent
                                ? Colors.blue.withValues(alpha: 0.2)
                                : Colors.transparent),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isToday
                              ? Colors.amber
                              : (hasEvent ? Colors.blue : Colors.white10),
                          width: isToday ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Stack(
                          children: [
                            Text(
                              '$day',
                              style: TextStyle(
                                color: isToday ? Colors.amber : Colors.white,
                                fontWeight: isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            if (hasEvent)
                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingEvents() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('family_events')
          .where('familyId', isEqualTo: widget.familyId)
          .where('startTime', isGreaterThan: Timestamp.now())
          .orderBy('startTime')
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.amber));
        }
        final events = snapshot.data!.docs;
        if (events.isEmpty) {
          return const Center(
            child: Text('لا توجد أحداث قادمة',
                style: TextStyle(color: Colors.white38)),
          );
        }
        return Column(
          children: [
            const Text('الأحداث القادمة',
                style: TextStyle(
                    color: Colors.amber,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final event = events[index].data() as Map<String, dynamic>;
                return _buildEventCard(event, events[index].id);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event, String eventId) {
    final startTime = (event['startTime'] as Timestamp).toDate();
    final isRecurring = event['isRecurring'] ?? false;
    final recurringType = event['recurringType'] ?? '';

    return AppTheme.glassContainer(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.event, color: Colors.amber, size: 24),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event['title'] ?? '',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(event['description'] ?? '',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 12)),
                  ],
                ),
              ),
              if (isRecurring)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getRecurringTypeText(recurringType),
                    style: const TextStyle(color: Colors.purple, fontSize: 10),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              const Icon(Icons.access_time, size: 14, color: Colors.white38),
              const SizedBox(width: 5),
              Text(
                '${startTime.day}/${startTime.month}/${startTime.year} - ${startTime.hour}:${startTime.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
              const SizedBox(width: 15),
              const Icon(Icons.people, size: 14, color: Colors.white38),
              const SizedBox(width: 5),
              Text(
                '${event['participants']?.length ?? 0} مشارك',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _joinEvent(eventId),
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('انضمام'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _inviteToEvent(eventId),
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('دعوة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر'
    ];
    return months[month - 1];
  }

  String _getRecurringTypeText(String type) {
    switch (type) {
      case 'daily':
        return 'يومي';
      case 'weekly':
        return 'أسبوعي';
      case 'monthly':
        return 'شهري';
      default:
        return '';
    }
  }

  void _showDayEvents(int day) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1A050E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'أحداث $day/${_selectedMonth.month}/${_selectedMonth.year}',
              style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream: _db
                  .collection('family_events')
                  .where('familyId', isEqualTo: widget.familyId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator(color: Colors.amber));
                }
                final events = snapshot.data!.docs;
                final dayEvents = events.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final startTime = (data['startTime'] as Timestamp).toDate();
                  return startTime.day == day &&
                      startTime.month == _selectedMonth.month &&
                      startTime.year == _selectedMonth.year;
                }).toList();

                if (dayEvents.isEmpty) {
                  return const Text('لا توجد أحداث في هذا اليوم',
                      style: TextStyle(color: Colors.white38));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: dayEvents.length,
                  itemBuilder: (context, index) {
                    final event =
                        dayEvents[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(event['title'] ?? '',
                          style: const TextStyle(color: Colors.white)),
                      subtitle: Text(event['description'] ?? '',
                          style: const TextStyle(color: Colors.white38)),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _joinEvent(String eventId) async {
    try {
      await _familyService.joinFamilyEvent(eventId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم الانضمام للحدث ✅')),
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

  void _inviteToEvent(String eventId) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ رابط الدعوة 🔗')),
    );
  }

  void _showCreateEventDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    DateTime startTime = DateTime.now();
    DateTime endTime = DateTime.now().add(const Duration(hours: 2));
    bool isRecurring = false;
    String recurringType = 'weekly';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A050E),
          title: const Text('إنشاء حدث', style: TextStyle(color: Colors.amber)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'العنوان',
                      labelStyle: TextStyle(color: Colors.white38),
                    )),
                TextField(
                    controller: descController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'الوصف',
                      labelStyle: TextStyle(color: Colors.white38),
                    )),
                const SizedBox(height: 15),
                SwitchListTile(
                  title: const Text('حدث متكرر',
                      style: TextStyle(color: Colors.white)),
                  value: isRecurring,
                  onChanged: (value) {
                    setDialogState(() => isRecurring = value);
                  },
                ),
                if (isRecurring)
                  DropdownButtonFormField<String>(
                    initialValue: recurringType,
                    style: const TextStyle(color: Colors.white),
                    dropdownColor: const Color(0xFF3D0B16),
                    decoration: const InputDecoration(
                      labelText: 'نوع التكرار',
                      labelStyle: TextStyle(color: Colors.white38),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'daily', child: Text('يومي')),
                      DropdownMenuItem(value: 'weekly', child: Text('أسبوعي')),
                      DropdownMenuItem(value: 'monthly', child: Text('شهري')),
                    ],
                    onChanged: (value) {
                      setDialogState(() => recurringType = value!);
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء')),
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
      ),
    );
  }
}
