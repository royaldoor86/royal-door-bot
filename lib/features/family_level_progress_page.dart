import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_theme.dart';
import '../models/family_model.dart';

class FamilyLevelProgressPage extends StatefulWidget {
  final String familyId;

  const FamilyLevelProgressPage({
    super.key,
    required this.familyId,
  });

  @override
  State<FamilyLevelProgressPage> createState() =>
      _FamilyLevelProgressPageState();
}

class _FamilyLevelProgressPageState extends State<FamilyLevelProgressPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // شروط الترقية لكل مستوى
  final Map<int, Map<String, dynamic>> _levelRequirements = {
    1: {'xp': 0, 'members': 5, 'reward': 'شارة المبتدئ'},
    2: {'xp': 1000, 'members': 10, 'reward': '5 جواهر'},
    3: {'xp': 3000, 'members': 15, 'reward': '10 جواهر'},
    4: {'xp': 7000, 'members': 20, 'reward': 'شارة محارب'},
    5: {'xp': 15000, 'members': 25, 'reward': '20 جواهر'},
    6: {'xp': 40000, 'members': 30, 'reward': 'شارة قائد'},
    7: {'xp': 100000, 'members': 35, 'reward': '50 جواهر'},
    8: {'xp': 300000, 'members': 40, 'reward': 'شارة أسطورة'},
    9: {'xp': 500000, 'members': 45, 'reward': '100 جواهر'},
    10: {'xp': 1000000, 'members': 50, 'reward': 'شارة ملكية'},
  };

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A050E),
        appBar: AppBar(
          title: const Text('ترقية العائلة',
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
          child: StreamBuilder<DocumentSnapshot>(
            stream: _db.collection('families').doc(widget.familyId).snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.amber));
              }

              final family = FamilyModel.fromFirestore(
                  snapshot.data! as DocumentSnapshot<Map<String, dynamic>>);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCurrentLevelCard(family),
                    const SizedBox(height: 20),
                    _buildProgressSection(family),
                    const SizedBox(height: 20),
                    _buildNextLevelRequirements(family),
                    const SizedBox(height: 20),
                    _buildLevelHistory(family),
                    const SizedBox(height: 20),
                    _buildAllLevelsList(family),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentLevelCard(FamilyModel family) {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.withValues(alpha: 0.3),
                      Colors.amber.withValues(alpha: 0.1),
                    ],
                  ),
                  border: Border.all(color: Colors.amber, width: 3),
                ),
                child: Center(
                  child: Text(
                    'LV.${family.level}',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(family.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text('${family.memberCount}/${family.maxMembers} عضو',
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildProgressSection(FamilyModel family) {
    final currentLevel = family.level;
    final nextLevel = currentLevel < 10 ? currentLevel + 1 : currentLevel;
    final currentXP = family.totalExp;
    final nextLevelXP = _levelRequirements[nextLevel]?['xp'] ?? currentXP;
    final prevLevelXP = _levelRequirements[currentLevel]?['xp'] ?? 0;
    final progress = nextLevel > currentLevel
        ? ((currentXP - prevLevelXP) / (nextLevelXP - prevLevelXP))
            .clamp(0.0, 1.0)
        : 1.0;

    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('التقدم للمستوى التالي',
              style: TextStyle(
                  color: Colors.amber,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('المستوى $currentLevel',
                  style: const TextStyle(color: Colors.white70)),
              Text('المستوى $nextLevel',
                  style: const TextStyle(color: Colors.amber)),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white10,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            minHeight: 10,
          ),
          const SizedBox(height: 10),
          Text('$currentXP / $nextLevelXP نقطة خبرة',
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 15),
          if (family.level >= 10)
            const Text('🎉 وصلت لأعلى مستوى!',
                style: TextStyle(color: Colors.cyanAccent, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildNextLevelRequirements(FamilyModel family) {
    final nextLevel = family.level < 10 ? family.level + 1 : family.level;
    final requirements = _levelRequirements[nextLevel];

    if (requirements == null || family.level >= 10) {
      return const SizedBox();
    }

    final currentXP = family.totalExp;
    final currentMembers = family.memberCount;
    final xpRequirement = requirements['xp'] as int;
    final membersRequirement = requirements['members'] as int;
    final reward = requirements['reward'] as String;

    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('شروط المستوى $nextLevel',
              style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          _requirementItem(
            'نقاط الخبرة',
            '$currentXP / $xpRequirement',
            currentXP >= xpRequirement,
            Icons.star,
          ),
          const SizedBox(height: 10),
          _requirementItem(
            'عدد الأعضاء',
            '$currentMembers / $membersRequirement',
            currentMembers >= membersRequirement,
            Icons.group,
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.card_giftcard, color: Colors.green),
                const SizedBox(width: 10),
                const Text('مكافأة المستوى: ',
                    style: TextStyle(color: Colors.white70)),
                Text(reward,
                    style: const TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _requirementItem(
      String label, String value, bool completed, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: completed ? Colors.green : Colors.white38, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: const TextStyle(color: Colors.white70)),
        ),
        Text(value,
            style: TextStyle(
                color: completed ? Colors.green : Colors.white38,
                fontWeight: FontWeight.bold)),
        const SizedBox(width: 5),
        Icon(completed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: completed ? Colors.green : Colors.white38, size: 16),
      ],
    );
  }

  Widget _buildLevelHistory(FamilyModel family) {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('تاريخ ترقية العائلة',
              style: TextStyle(
                  color: Colors.amber,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('families')
                .doc(widget.familyId)
                .collection('level_history')
                .orderBy('timestamp', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.amber));
              }

              final history = snapshot.data!.docs;

              if (history.isEmpty) {
                return const Center(
                  child: Text('لا يوجد سجل ترقيات بعد',
                      style: TextStyle(color: Colors.white38)),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final record = history[index].data() as Map<String, dynamic>;
                  return _historyItem(record);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _historyItem(Map<String, dynamic> record) {
    final level = record['level'] as int;
    final timestamp = record['timestamp'] as Timestamp;
    final date = timestamp.toDate();

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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text('LV.$level',
                  style: const TextStyle(
                      color: Colors.amber, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('ترقية إلى المستوى $level',
                    style: const TextStyle(color: Colors.white)),
                Text(
                  '${date.day}/${date.month}/${date.year} - ${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.trending_up, color: Colors.green),
        ],
      ),
    );
  }

  Widget _buildAllLevelsList(FamilyModel family) {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('جميع المستويات',
              style: TextStyle(
                  color: Colors.amber,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _levelRequirements.length,
            itemBuilder: (context, index) {
              final level = index + 1;
              final requirements = _levelRequirements[level]!;
              final isCurrent = level == family.level;
              final isCompleted = level < family.level;
              final isUnlocked = level <= family.level;

              return _levelListItem(
                  level, requirements, isCurrent, isCompleted, isUnlocked);
            },
          ),
        ],
      ),
    );
  }

  Widget _levelListItem(int level, Map<String, dynamic> requirements,
      bool isCurrent, bool isCompleted, bool isUnlocked) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrent
            ? Colors.amber.withValues(alpha: 0.2)
            : isCompleted
                ? Colors.green.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrent
              ? Colors.amber
              : isCompleted
                  ? Colors.green.withValues(alpha: 0.5)
                  : Colors.transparent,
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? (isCurrent
                      ? Colors.amber
                      : Colors.green.withValues(alpha: 0.3))
                  : Colors.white10,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: isUnlocked
                  ? Icon(
                      isCompleted ? Icons.check : Icons.star,
                      color: isCurrent ? Colors.amber : Colors.green,
                      size: 18,
                    )
                  : Text(
                      '$level',
                      style: const TextStyle(color: Colors.white38),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('المستوى $level',
                    style: TextStyle(
                        color: isUnlocked ? Colors.white : Colors.white38,
                        fontWeight:
                            isCurrent ? FontWeight.bold : FontWeight.normal)),
                Text(
                    '${requirements['xp']} نقطة | ${requirements['members']} عضو',
                    style:
                        const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
          if (isUnlocked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                requirements['reward'] as String,
                style: const TextStyle(color: Colors.amber, fontSize: 10),
              ),
            ),
        ],
      ),
    );
  }
}
