import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/family_service.dart';
import '../app_theme.dart';

class FamilyTasksPage extends StatefulWidget {
  final String familyId;
  const FamilyTasksPage({super.key, required this.familyId});

  @override
  State<FamilyTasksPage> createState() => _FamilyTasksPageState();
}

class _FamilyTasksPageState extends State<FamilyTasksPage> {
  final FamilyService _familyService = FamilyService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _userId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A050E),
        appBar: AppBar(
          title: const Text('مهام العائلة الملكية',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                _buildFamilyProgressSection(),
                const SizedBox(height: 20),
                _buildLeaderboardSection(),
                const SizedBox(height: 20),
                _buildTasksSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFamilyProgressSection() {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('تقدم العائلة الجماعي',
              style: TextStyle(
                  color: Colors.amber,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          StreamBuilder<DocumentSnapshot>(
            stream: _db.collection('families').doc(widget.familyId).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.amber));
              }
              final family = snapshot.data!.data() as Map<String, dynamic>;
              final totalTasksCompleted = family['totalTasksCompleted'] ?? 0;
              final totalTasksTarget = family['totalTasksTarget'] ?? 100;
              final progress = totalTasksTarget > 0
                  ? (totalTasksCompleted / totalTasksTarget).clamp(0.0, 1.0)
                  : 0.0;

              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('المهام المكتملة جماعياً',
                          style: TextStyle(color: Colors.white70)),
                      Text('$totalTasksCompleted / $totalTasksTarget',
                          style: const TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white10,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.amber),
                    minHeight: 10,
                  ),
                  const SizedBox(height: 10),
                  if (totalTasksCompleted >= totalTasksTarget)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.green),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.card_giftcard, color: Colors.green),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                                '🎉 العائلة حققت الهدف الجماعي! مكافأة: 50 جوهرة للخزينة',
                                style: TextStyle(color: Colors.green)),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardSection() {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('تنافس الأعضاء',
              style: TextStyle(
                  color: Colors.amber,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('families')
                .doc(widget.familyId)
                .collection('members')
                .orderBy('tasksCompleted', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.amber));
              }
              final members = snapshot.data!.docs;
              if (members.isEmpty) {
                return const Center(
                  child: Text('لا يوجد أعضاء',
                      style: TextStyle(color: Colors.white38)),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index].data() as Map<String, dynamic>;
                  final tasksCompleted = member['tasksCompleted'] ?? 0;
                  return _buildLeaderboardItem(
                      member, index + 1, tasksCompleted);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(
      Map<String, dynamic> member, int rank, int tasksCompleted) {
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
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: rank == 1
                  ? Colors.amber.withValues(alpha: 0.3)
                  : (rank == 2
                      ? Colors.grey.withValues(alpha: 0.3)
                      : Colors.brown.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text('#$rank',
                  style: TextStyle(
                      color: rank == 1
                          ? Colors.amber
                          : (rank == 2 ? Colors.grey : Colors.brown),
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: _db.collection('users').doc(member['uid']).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Text('جاري التحميل...',
                      style: TextStyle(color: Colors.white38));
                }
                final userData = snapshot.data!.data() as Map<String, dynamic>?;
                return Text(userData?['name'] ?? 'بدون اسم',
                    style: const TextStyle(color: Colors.white));
              },
            ),
          ),
          const SizedBox(width: 10),
          Text('$tasksCompleted مهمة',
              style: const TextStyle(
                  color: Colors.amber, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTasksSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _familyService.streamFamilyTasks(widget.familyId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.amber));
        }

        final allTasks = snapshot.data!.docs;

        // تصفية المهام المنتهية الصلاحية
        final activeTasks = allTasks.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['isLimited'] == true && data['expiryDate'] != null) {
            final expiry = (data['expiryDate'] as Timestamp).toDate();
            return expiry.isAfter(DateTime.now());
          }
          return true;
        }).toList();

        if (activeTasks.isEmpty) {
          return const Center(
              child: Text('لا توجد مهام نشطة حالياً',
                  style: TextStyle(color: Colors.white38)));
        }

        return Column(
          children: [
            const Text('المهام اليومية المشتركة',
                style: TextStyle(
                    color: Colors.amber,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              itemCount: activeTasks.length,
              itemBuilder: (context, index) {
                final task = activeTasks[index].data() as Map<String, dynamic>;
                final taskId = activeTasks[index].id;

                return _buildTaskTile(taskId, task);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTaskTile(String taskId, Map<String, dynamic> task) {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    bool isLimited = task['isLimited'] ?? false;
    double progress = task['progress'] ?? 0.0;
    double targetProgress = task['targetProgress'] ?? 1.0;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('families')
          .doc(widget.familyId)
          .collection('members')
          .doc(_userId)
          .collection('task_logs')
          .doc('${taskId}_$today')
          .snapshots(),
      builder: (context, snapshot) {
        bool isCompleted = snapshot.hasData && snapshot.data!.exists;

        return AppTheme.glassContainer(
          margin: const EdgeInsets.only(bottom: 15),
          padding: const EdgeInsets.all(15),
          opacity: 0.05,
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIconData(task['icon'] ?? 'task'),
                      color: Colors.amber,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(task['title'] ?? '',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(task['description'] ?? '',
                            style: const TextStyle(
                                color: Colors.white38, fontSize: 11)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  isCompleted
                      ? const Icon(Icons.check_circle,
                          color: Colors.greenAccent, size: 30)
                      : ElevatedButton(
                          onPressed: () => _handleTaskAction(taskId, task),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 8),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(task['buttonText'] ?? 'انطلق',
                              style: const TextStyle(
                                  fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                ],
              ),
              const SizedBox(height: 12),
              // Progress indicator
              if (!isCompleted && targetProgress > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('التقدم',
                            style:
                                TextStyle(color: Colors.white38, fontSize: 11)),
                        Text('${(progress / targetProgress * 100).toInt()}%',
                            style: const TextStyle(
                                color: Colors.amber,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress / targetProgress,
                        backgroundColor: Colors.white10,
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.amber),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              const Divider(color: Colors.white10, height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _rewardBadge('${task['xp']} XP', Colors.purpleAccent),
                      const SizedBox(width: 8),
                      _rewardBadge('${task['coins']} 🪙', Colors.amber),
                      if ((task['gems'] ?? 0) > 0) ...[
                        const SizedBox(width: 8),
                        _rewardBadge('${task['gems']} 💎', Colors.cyanAccent),
                      ],
                    ],
                  ),
                  if (isLimited && task['expiryDate'] != null)
                    _CountdownWidget(
                        expiryDate: (task['expiryDate'] as Timestamp).toDate()),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _rewardBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'mic':
        return Icons.mic;
      case 'gift':
        return Icons.card_giftcard;
      case 'chat':
        return Icons.chat_bubble_outline;
      case 'room':
        return Icons.meeting_room;
      default:
        return Icons.task_alt;
    }
  }

  void _handleTaskAction(String taskId, Map<String, dynamic> task) async {
    String type = task['type'] ?? 'general';

    // إذا كانت المهمة تحتاج لحدث معين، نوجه المستخدم للقيام به
    if (type == 'mic' || type == 'room') {
      Navigator.pop(context); // العودة لصفحة العائلة ومنها للدخول للروم
      return;
    }

    // للمهام التي يمكن إتمامها بضغطة زر أو للمحاكاة حالياً
    try {
      await _familyService.completeFamilyTask(widget.familyId, _userId, taskId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم إكمال المهمة الملكية بنجاح! 🏰')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}

class _CountdownWidget extends StatefulWidget {
  final DateTime expiryDate;
  const _CountdownWidget({required this.expiryDate});

  @override
  State<_CountdownWidget> createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<_CountdownWidget> {
  late Timer _timer;
  late Duration _timeLeft;

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.expiryDate.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeLeft = widget.expiryDate.difference(DateTime.now());
        if (_timeLeft.isNegative) {
          _timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timeLeft.isNegative) return const SizedBox.shrink();

    String hours = _timeLeft.inHours.toString().padLeft(2, '0');
    String minutes = (_timeLeft.inMinutes % 60).toString().padLeft(2, '0');
    String seconds = (_timeLeft.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, color: Colors.redAccent, size: 14),
          const SizedBox(width: 4),
          Text('$hours:$minutes:$seconds',
              style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
