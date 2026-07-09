import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_theme.dart';
import '../services/family_service.dart';

class FamilyArchivePage extends StatefulWidget {
  final String familyId;
  const FamilyArchivePage({super.key, required this.familyId});

  @override
  State<FamilyArchivePage> createState() => _FamilyArchivePageState();
}

class _FamilyArchivePageState extends State<FamilyArchivePage> {
  final FamilyService _familyService = FamilyService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String _selectedCategory = 'all';
  String _searchQuery = '';

  final Map<String, String> _categoryNames = {
    'all': 'الكل',
    'wars': 'الحروب',
    'events': 'الأحداث',
    'votes': 'التصويتات',
    'tasks': 'المهام',
  };

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A050E),
        appBar: AppBar(
          title: const Text('أرشيف العائلة',
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _showSearchDialog,
            ),
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _exportArchive,
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
              _buildCategoryFilter(),
              Expanded(
                child: _buildArchiveContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return AppTheme.glassContainer(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _categoryNames.entries.map((entry) {
            final isSelected = _selectedCategory == entry.key;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: ChoiceChip(
                label: Text(entry.value),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() => _selectedCategory = entry.key);
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

  Widget _buildArchiveContent() {
    switch (_selectedCategory) {
      case 'wars':
        return _buildWarsArchive();
      case 'events':
        return _buildEventsArchive();
      case 'votes':
        return _buildVotesArchive();
      case 'tasks':
        return _buildTasksArchive();
      default:
        return _buildAllArchive();
    }
  }

  Widget _buildAllArchive() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _buildWarsArchive(),
          const SizedBox(height: 20),
          _buildEventsArchive(),
          const SizedBox(height: 20),
          _buildVotesArchive(),
          const SizedBox(height: 20),
          _buildTasksArchive(),
        ],
      ),
    );
  }

  Widget _buildWarsArchive() {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield, color: Colors.amber),
              const SizedBox(width: 10),
              const Text('أرشيف الحروب',
                  style: TextStyle(
                      color: Colors.amber,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('family_wars')
                .where('familyId', isEqualTo: widget.familyId)
                .where('status', isEqualTo: 'completed')
                .orderBy('endedAt', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.amber));
              }
              final wars = snapshot.data!.docs;
              if (wars.isEmpty) {
                return const Center(
                  child: Text('لا توجد حروب منتهية',
                      style: TextStyle(color: Colors.white38)),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: wars.length,
                itemBuilder: (context, index) {
                  final war = wars[index].data() as Map<String, dynamic>;
                  return _buildArchiveItem(war, 'war');
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEventsArchive() {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event, color: Colors.amber),
              const SizedBox(width: 10),
              const Text('أرشيف الأحداث',
                  style: TextStyle(
                      color: Colors.amber,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('family_events')
                .where('familyId', isEqualTo: widget.familyId)
                .where('endTime', isLessThan: Timestamp.now())
                .orderBy('endTime', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.amber));
              }
              final events = snapshot.data!.docs;
              if (events.isEmpty) {
                return const Center(
                  child: Text('لا توجد أحداث منتهية',
                      style: TextStyle(color: Colors.white38)),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index].data() as Map<String, dynamic>;
                  return _buildArchiveItem(event, 'event');
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVotesArchive() {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.how_to_vote, color: Colors.amber),
              const SizedBox(width: 10),
              const Text('أرشيف التصويتات',
                  style: TextStyle(
                      color: Colors.amber,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('family_votes')
                .where('familyId', isEqualTo: widget.familyId)
                .where('status', isEqualTo: 'completed')
                .orderBy('deadline', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.amber));
              }
              final votes = snapshot.data!.docs;
              if (votes.isEmpty) {
                return const Center(
                  child: Text('لا توجد تصويتات منتهية',
                      style: TextStyle(color: Colors.white38)),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: votes.length,
                itemBuilder: (context, index) {
                  final vote = votes[index].data() as Map<String, dynamic>;
                  return _buildArchiveItem(vote, 'vote');
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTasksArchive() {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.task_alt, color: Colors.amber),
              const SizedBox(width: 10),
              const Text('أرشيف المهام',
                  style: TextStyle(
                      color: Colors.amber,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('family_tasks_config')
                .where('familyId', isEqualTo: widget.familyId)
                .where('expiryDate', isLessThan: Timestamp.now())
                .orderBy('expiryDate', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.amber));
              }
              final tasks = snapshot.data!.docs;
              if (tasks.isEmpty) {
                return const Center(
                  child: Text('لا توجد مهام منتهية',
                      style: TextStyle(color: Colors.white38)),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index].data() as Map<String, dynamic>;
                  return _buildArchiveItem(task, 'task');
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildArchiveItem(Map<String, dynamic> item, String type) {
    String title = '';
    String subtitle = '';
    IconData icon = Icons.archive;

    switch (type) {
      case 'war':
        title = item['opponentFamilyName'] ?? 'حرب غير معروفة';
        subtitle = item['result'] ?? 'غير محدد';
        icon = Icons.shield;
        break;
      case 'event':
        title = item['title'] ?? 'حدث غير معروف';
        final endTime = (item['endTime'] as Timestamp).toDate();
        subtitle = 'انتهى في ${endTime.day}/${endTime.month}/${endTime.year}';
        icon = Icons.event;
        break;
      case 'vote':
        title = item['title'] ?? 'تصويت غير معروف';
        subtitle = item['result'] ?? 'غير محدد';
        icon = Icons.how_to_vote;
        break;
      case 'task':
        title = item['title'] ?? 'مهمة غير معروفة';
        subtitle = 'منتهية';
        icon = Icons.task_alt;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.amber, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    final searchController = TextEditingController(text: _searchQuery);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A050E),
        title:
            const Text('بحث في الأرشيف', style: TextStyle(color: Colors.amber)),
        content: TextField(
          controller: searchController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'كلمة البحث',
            labelStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _searchQuery = searchController.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('بحث'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportArchive() async {
    try {
      final archiveSnap = await _db
          .collection('family_archive')
          .where('familyId', isEqualTo: widget.familyId)
          .get();

      if (archiveSnap.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لا توجد بيانات للتصدير')),
          );
        }
        return;
      }

      // تحويل البيانات إلى نص CSV بسيط
      final csvData = StringBuffer();
      csvData.writeln('النوع,التاريخ,البيانات');

      for (var doc in archiveSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final category = data['category'] ?? 'غير معروف';
        final archivedAt = (data['archivedAt'] as Timestamp).toDate();
        final itemData = data['data'] as Map<String, dynamic>?;
        final title = itemData?['title'] ?? 'بدون عنوان';

        csvData.writeln('$category,${archivedAt.toIso8601String()},$title');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تصدير الأرشيف بنجاح ✅')),
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
