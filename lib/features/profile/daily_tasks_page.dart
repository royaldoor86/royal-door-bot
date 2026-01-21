import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/daily_tasks_service.dart';
import '../../app_theme.dart';

class DailyTasksPage extends StatefulWidget {
  const DailyTasksPage({super.key});

  @override
  State<DailyTasksPage> createState() => _DailyTasksPageState();
}

class _DailyTasksPageState extends State<DailyTasksPage> {
  List<Map<String, dynamic>> _tasks = [];
  bool _loading = true;
  Map<String, dynamic> _userTasks = {};
  bool _congratsShown = false;

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _listenUserTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await DailyTasksService.fetchTasksTemplate(lang: 'ar');
      setState(() {
        _tasks = tasks;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _listenUserTasks() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    DailyTasksService.dailyTasksStream(user.uid).listen((snap) {
      if (snap.exists && mounted) {
        setState(() => _userTasks = snap.data() ?? {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0416), // أرجواني مسائي غامق جداً
        appBar: AppBar(
          title: const Text('المهمات الملكية اليومية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0xFF1F0833), Color(0xFF0F0416)],
            ),
          ),
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: Colors.purpleAccent))
              : _tasks.isEmpty 
                ? _buildEmptyState()
                : Column(
                    children: [
                      _buildOverallProgress(),
                      Expanded(
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: _tasks.length,
                          itemBuilder: (context, index) {
                            final category = _tasks[index];
                            final List tasksList = category['tasks'] ?? [];
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 10),
                                  child: Text(
                                    category['category'] ?? 'تصنيف عام',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purpleAccent, letterSpacing: 1.1),
                                  ),
                                ),
                                ...tasksList.map<Widget>((task) => _buildTaskCard(Map<String, dynamic>.from(task))).toList(),
                              ],
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

  Widget _buildOverallProgress() {
    int total = 0;
    int done = 0;
    for (final category in _tasks) {
      final List tasksList = category['tasks'] ?? [];
      for (final task in tasksList) {
        total++;
        final taskId = task['id'] ?? task['title'] ?? '';
        if (_userTasks[taskId] == true) done++;
      }
    }
    double percent = total > 0 ? done / total : 0.0;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('إنجاز المسيرة اليومية', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
              Text('${(percent * 100).toInt()}%', style: const TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 8,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.purpleAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    String taskId = task['id'] ?? task['title'] ?? '';
    bool isDone = _userTasks[taskId] == true;
    Color rewardColor = task['type'] == 'gem' ? Colors.blue : (task['type'] == 'xp' ? Colors.purpleAccent : Colors.amber);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: isDone ? Colors.green.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: rewardColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(task['type'] == 'gem' ? Icons.diamond : (task['type'] == 'xp' ? Icons.stars : Icons.monetization_on), color: rewardColor, size: 24),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(task['title'] ?? 'مهمة ملكية', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(task['desc'] ?? '', style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
                      const SizedBox(height: 10),
                      _buildProgressBar(isDone),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _buildActionButton(isDone, task['isAd'] ?? false, taskId),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(bool isDone) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: LinearProgressIndicator(
        value: isDone ? 1.0 : 0.0,
        minHeight: 4,
        backgroundColor: Colors.white10,
        valueColor: AlwaysStoppedAnimation<Color>(isDone ? Colors.green : Colors.white24),
      ),
    );
  }

  Widget _buildActionButton(bool isDone, bool isAd, String taskId) {
    return ElevatedButton(
      onPressed: () {},
      style: ElevatedButton.styleFrom(
        backgroundColor: isDone ? Colors.green : (isAd ? Colors.orange : Colors.white.withValues(alpha: 0.05)),
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(70, 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(isDone ? 'استلام' : (isAd ? 'شاهد' : 'اذهب'), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text('لا توجد مهام حالياً الملك بانتظارك! 👑', style: TextStyle(color: Colors.white24)));
  }
}
