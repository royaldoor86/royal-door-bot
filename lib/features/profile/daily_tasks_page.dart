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
    _initializeApp();
    AdManager().loadRewardedAd();
  }

  Future<void> _initializeApp() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // فحص التصفير فقط
        await DailyTasksService.checkAndResetTasks(user.uid);
        _listenUserTasks();
      }
      await _loadTasks();
    } catch (e) {
      debugPrint("Error initializing DailyTasks: $e");
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _showAdAndComplete(String taskId) {
    if (!AdManager().isLoaded) {
      AdManager().loadRewardedAd();
      Fluttertoast.showToast(msg: "جارٍ محاولة جلب إعلان.. يرجى الانتظار");
      setState(() => _loadingTaskId = taskId);
      return;
    }

    AdManager().showRewardedAd(
      onUserEarnedReward: (RewardItem? reward) async {
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
      // إضافة مهلة زمنية للجلب لتجنب التعليق اللانهائي
      final tasksFuture = DailyTasksService.fetchTasksTemplate(lang: 'ar');
      final tasks = await tasksFuture.timeout(const Duration(seconds: 10), onTimeout: () {
        debugPrint("DailyTasks: Fetching tasks timed out.");
        return [];
      });

      if (mounted) {
        setState(() {
          if (tasks.isEmpty) {
            _tasks = _getDefaultTasks();
          } else {
            _tasks = tasks;
          }
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading tasks list: $e");
      if (mounted) {
        setState(() {
          _tasks = _getDefaultTasks();
          _loading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _getDefaultTasks() {
    return [
      {
        'category': 'المهام الملكية اليومية',
        'tasks': [
          {'id': 'ad_task_1', 'title': 'المهمة 1: دعم المملكة', 'desc': '5 نجوم ⭐ ملكية', 'type': 'coin', 'reward': 5, 'order': 1},
          {'id': 'ad_task_2', 'title': 'المهمة 2: كنز الياقوت', 'desc': '5 مجوهرات زرقاء', 'type': 'gem', 'reward': 5, 'order': 2},
          {'id': 'ad_task_3', 'title': 'المهمة 3: هدية الملوك', 'desc': '7 نجوم ⭐ ملكية', 'type': 'coin', 'reward': 7, 'order': 3},
          {'id': 'ad_task_4', 'title': 'المهمة 4: جوهرة التاج', 'desc': '7 مجوهرات زرقاء', 'type': 'gem', 'reward': 7, 'order': 4},
          {'id': 'ad_task_5', 'title': 'المهمة 5: وسام الاستحقاق', 'desc': '10 نجوم ⭐ ملكية', 'type': 'coin', 'reward': 10, 'order': 5},
          {'id': 'ad_task_6', 'title': 'المهمة 6: الياقوت النادر', 'desc': '10 مجوهرات زرقاء', 'type': 'gem', 'reward': 10, 'order': 6},
          {'id': 'ad_task_7', 'title': 'المهمة 7: ثروة القصر', 'desc': '12 نجمة ⭐ ملكية', 'type': 'coin', 'reward': 12, 'order': 7},
          {'id': 'ad_task_8', 'title': 'المهمة 8: ماسة الامبراطور', 'desc': '12 مجوهرة زرقاء', 'type': 'gem', 'reward': 12, 'order': 8},
          {'id': 'ad_task_9', 'title': 'المهمة 9: خبرة ملكية', 'desc': '15 خبرة XP', 'type': 'xp', 'reward': 15, 'order': 9},
          {'id': 'ad_task_10', 'title': 'المهمة 10: الجائزة الكبرى', 'desc': '20 خبرة XP', 'type': 'xp', 'reward': 20, 'order': 10},
        ]
      }
    ];
  }

  void _listenUserTasks() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      DailyTasksService.dailyTasksStream(user.uid).listen((snap) {
        if (snap.exists && mounted) {
          setState(() => _userTasks = snap.data() ?? {});
        }
      }, onError: (e) {
        debugPrint("Error listening to user tasks: $e");
      });
    } catch (e) {
      debugPrint("Error setting up tasks listener: $e");
    }
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
              elevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                titlePadding: const EdgeInsets.only(bottom: 20),
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('المهمات الملكية اليومية', 
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, fontFamily: 'Cairo')),
                    const SizedBox(height: 8),
                    _buildHeaderBalance(user),
                  ],
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF4A148C), Color(0xFF14081F)],
                    ),
                  ),
                  child: const Center(
                    child: Opacity(
                      opacity: 0.1,
                      child: Icon(Icons.stars_rounded, size: 200, color: Colors.white),
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
            Text('${stars.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            const Icon(Icons.stars_rounded, color: Colors.amber, size: 16),
            const SizedBox(width: 15),
            Text('${gems.toInt()}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            const SizedBox(width: 4),
            const Icon(Icons.diamond, color: Colors.blueAccent, size: 16),
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
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 5))
        ]
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('إنجاز المهام الحقيقي', 
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
              Text('${(percent * 100).toInt()}%', 
                style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.w900, fontSize: 22)),
            ],
          ),
          const SizedBox(height: 15),
          Stack(
            children: [
              Container(height: 12, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10))),
              AnimatedContainer(
                duration: const Duration(milliseconds: 800),
                height: 12,
                width: (MediaQuery.of(context).size.width - 80) * percent,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF9C27B0), Color(0xFF2196F3)]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: Colors.purpleAccent.withOpacity(0.5), blurRadius: 10, spreadRadius: 1)
                  ],
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
    Color rewardColor = task['type'] == 'gem' ? Colors.blueAccent : (task['type'] == 'xp' ? Colors.purpleAccent : Colors.amber);

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isLocked ? 0.02 : 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDone ? Colors.green.withOpacity(0.5) : (isLocked ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.1)), 
          width: isDone ? 2 : 1
        ),
      ),
      child: Row(
        children: [
          // Icon Section
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: (isLocked ? Colors.grey : rewardColor).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isLocked ? Icons.lock : (task['type'] == 'gem' ? Icons.diamond : (task['type'] == 'xp' ? Icons.auto_awesome : Icons.stars_rounded)), 
                  color: isLocked ? Colors.white24 : rewardColor, 
                  size: 28
                ),
              ),
              if (isDone)
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.black, width: 2)),
                    child: const Icon(Icons.check, color: Colors.white, size: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 15),
          // Text Section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, 
              children: [
                Text(task['title'] ?? '', 
                  style: TextStyle(
                    color: isLocked ? Colors.white38 : Colors.white, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 15,
                    fontFamily: 'Cairo'
                  )
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text("الجائزة: ", style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                    Text(task['desc'] ?? '', 
                      style: TextStyle(color: isLocked ? Colors.white24 : rewardColor, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ]
            ),
          ),
          // Action Button Section
          _buildActionButton(task, isDone, isLocked),
        ],
      ),
    );
  }

  Widget _buildActionButton(Map<String, dynamic> task, bool isDone, bool isLocked) {
    String taskId = task['id'] ?? '';
    
    if (isDone) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.3))
        ),
        child: const Text('مكتمل', 
          style: TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
      );
    }

    if (isLocked) {
      return Container(
        padding: const EdgeInsets.all(10),
        child: const Icon(Icons.lock_outline, color: Colors.white12, size: 24),
      );
    }

    return StreamBuilder<bool>(
      stream: AdManager().adStatusStream,
      builder: (context, snapshot) {
        bool isAdReady = AdManager().isLoaded;
        bool isAdLoading = AdManager().isLoading;
        bool thisTaskLoading = _loadingTaskId == taskId;

        return SizedBox(
          height: 45,
          child: ElevatedButton(
            onPressed: (isAdReady && _loadingTaskId == null) ? () => _showAdAndComplete(taskId) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isAdReady ? Colors.amber : Colors.white10,
              foregroundColor: Colors.black,
              elevation: isAdReady ? 5 : 0,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: (thisTaskLoading || (isAdLoading && !isAdReady))
              ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.play_circle_fill, size: 18),
                    const SizedBox(width: 8),
                    Text(isAdReady ? 'شاهد' : 'تجهيز..', 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, fontFamily: 'Cairo')),
                  ],
                ),
          ),
        );
      },
    );
  }
}
