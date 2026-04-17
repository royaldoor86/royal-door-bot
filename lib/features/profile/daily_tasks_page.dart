import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/daily_tasks_service.dart';
import '../../services/ad_manager.dart';

class DailyTasksPage extends StatefulWidget {
  const DailyTasksPage({super.key});

  @override
  State<DailyTasksPage> createState() => _DailyTasksPageState();
}

class _DailyTasksPageState extends State<DailyTasksPage> {
  List<Map<String, dynamic>> _tasks = [];
  bool _loading = true;
  Map<String, dynamic> _userTasks = {};
  String? _loadingTaskId;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    
    // تحديث القالب الجديد للمهام لمرة واحدة لضمان ظهور الـ 10 مهام
    DailyTasksService.setupAdTasks().then((_) {
      if (user != null) {
        DailyTasksService.checkAndResetTasks(user.uid).then((_) {
          _loadTasks();
          _listenUserTasks();
        });
      } else {
        _loadTasks();
      }
    });

    AdManager().loadRewardedAd();
  }

  void _showAdAndComplete(String taskId) {
    if (!AdManager().isLoaded) {
      AdManager().loadRewardedAd();
      Fluttertoast.showToast(msg: "جارٍ محاولة جلب إعلان.. يرجى الانتظار");
      setState(() => _loadingTaskId = taskId);
      return;
    }

    AdManager().showRewardedAd(
      onUserEarnedReward: (RewardItem reward) async {
        try {
          await DailyTasksService.completeTask(taskId);
          Fluttertoast.showToast(msg: "مبروك! تم استلام الجائزة 🎉", backgroundColor: Colors.green);
          if (mounted) setState(() => _loadingTaskId = null);
        } catch (e) {
          Fluttertoast.showToast(msg: e.toString());
        }
      },
      onAdFailed: () {
        if (mounted) setState(() => _loadingTaskId = null);
        Fluttertoast.showToast(msg: "حدث خطأ في عرض الإعلان");
      },
    );
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

  bool _isTaskLocked(Map<String, dynamic> task) {
    int order = task['order'] ?? 0;
    if (order <= 1) return false;
    for (var category in _tasks) {
      final List tasksList = category['tasks'] ?? [];
      for (var t in tasksList) {
        if (t['order'] == order - 1) {
          String prevTaskId = t['id'] ?? t['title'] ?? '';
          return _userTasks[prevTaskId] != true;
        }
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF14081F), 
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 180.0,
              pinned: true,
              backgroundColor: const Color(0xFF1A0A2E),
              elevation: 10,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                titlePadding: const EdgeInsets.only(bottom: 20),
                title: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('المهمات الملكية اليومية', 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 6),
                      _buildHeaderBalance(user),
                    ],
                  ),
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF6A1B9A), Color(0xFF14081F)],
                    ),
                  ),
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: Colors.purpleAccent)),
              )
            else
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    _buildOverallProgressSection(),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) {
                        final List tasksList = _tasks[index]['tasks'] ?? [];
                        return Column(
                          children: tasksList.map<Widget>((task) => _buildTaskCard(Map<String, dynamic>.from(task))).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBalance(User? user) {
    if (user == null) return const SizedBox();
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final stars = userData?['stars'] ?? userData?['coins'] ?? 0;
        final gems = userData?['gems'] ?? 0;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.stars_rounded, color: Colors.amber, size: 12),
            const SizedBox(width: 4),
            Text('$stars', style: const TextStyle(color: Colors.white70, fontSize: 11)),
            const SizedBox(width: 12),
            const Icon(Icons.diamond, color: Colors.blue, size: 12),
            const SizedBox(width: 4),
            Text('$gems', style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        );
      },
    );
  }

  Widget _buildOverallProgressSection() {
    int total = 0;
    int done = 0;
    for (final category in _tasks) {
      final List tasksList = category['tasks'] ?? [];
      for (final task in tasksList) {
        total++;
        if (_userTasks[task['id'] ?? ''] == true) done++;
      }
    }
    double percent = total > 0 ? done / total : 0.0;
    return Container(
      margin: const EdgeInsets.all(22),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('إنجاز المهام الحقيقي', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
              Text('${(percent * 100).toInt()}%', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(height: 10, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10))),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                height: 10,
                width: MediaQuery.of(context).size.width * 0.75 * percent,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.purpleAccent, Colors.blueAccent]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: Colors.purpleAccent.withValues(alpha: 0.3), blurRadius: 8)],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    String taskId = task['id'] ?? '';
    bool isDone = _userTasks[taskId] == true;
    bool isLocked = _isTaskLocked(task);
    Color rewardColor = task['type'] == 'gem' ? Colors.blue : (task['type'] == 'xp' ? Colors.purpleAccent : Colors.amber);

    return Opacity(
      opacity: isLocked ? 0.4 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isDone 
            ? LinearGradient(colors: [Colors.green.withValues(alpha: 0.1), Colors.black12])
            : LinearGradient(colors: [Colors.white.withValues(alpha: 0.05), Colors.white.withValues(alpha: 0.02)]),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: isDone ? Colors.green.withValues(alpha: 0.5) : Colors.white10, width: isDone ? 2 : 1),
        ),
        child: Row(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: rewardColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(isLocked ? Icons.lock : (task['type'] == 'gem' ? Icons.diamond : (task['type'] == 'xp' ? Icons.stars : Icons.stars_rounded)), color: isLocked ? Colors.grey : rewardColor, size: 24),
                ),
                if (isDone)
                  const Positioned(
                    bottom: 0,
                    right: 0,
                    child: Icon(Icons.check_circle, color: Colors.green, size: 16),
                  ),
              ],
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(task['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Row(
                  children: [
                    Text("الجائزة: ", style: TextStyle(color: Colors.white54, fontSize: 10)),
                    Text(task['desc'] ?? '', style: TextStyle(color: rewardColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ]),
            ),
            StreamBuilder<bool>(
              stream: AdManager().adStatusStream,
              builder: (context, snapshot) {
                bool isAdReady = AdManager().isLoaded;
                bool isAdLoading = AdManager().isLoading;
                
                if (isDone) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                    child: const Text('مكتمل', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                  );
                }

                if (isLocked) {
                  return const Icon(Icons.lock_outline, color: Colors.white24);
                }

                return ElevatedButton(
                  onPressed: (isAdReady && _loadingTaskId == null) ? () => _showAdAndComplete(taskId) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAdReady ? Colors.amber : Colors.white10,
                    foregroundColor: isAdReady ? Colors.black : Colors.white38,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: (_loadingTaskId == taskId || isAdLoading) && !isAdReady
                    ? const SizedBox(height: 15, width: 15, child: CircularProgressIndicator(color: Colors.white38, strokeWidth: 2))
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(isAdReady ? Icons.play_circle_fill : Icons.hourglass_empty, size: 16),
                          const SizedBox(width: 4),
                          Text(isAdReady ? 'شاهد' : 'تجهيز..', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
