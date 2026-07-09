import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../app_theme.dart';

class FamilyAnalyticsPage extends StatefulWidget {
  final String familyId;

  const FamilyAnalyticsPage({super.key, required this.familyId});

  @override
  State<FamilyAnalyticsPage> createState() => _FamilyAnalyticsPageState();
}

class _FamilyAnalyticsPageState extends State<FamilyAnalyticsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String _selectedPeriod = 'week'; // week, month, all

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A050E),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('إحصائيات العائلة',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            DropdownButton<String>(
              value: _selectedPeriod,
              dropdownColor: const Color(0xFF1A050E),
              style: const TextStyle(color: Colors.white),
              icon: const Icon(Icons.filter_list, color: Colors.amber),
              underline: Container(),
              items: const [
                DropdownMenuItem(value: 'week', child: Text('أسبوعي')),
                DropdownMenuItem(value: 'month', child: Text('شهري')),
                DropdownMenuItem(value: 'all', child: Text('الكل')),
              ],
              onChanged: (value) {
                setState(() => _selectedPeriod = value!);
              },
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
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildOverviewCards(),
                const SizedBox(height: 30),
                _buildActivityChart(),
                const SizedBox(height: 30),
                _buildWarPerformance(),
                const SizedBox(height: 30),
                _buildContributionDistribution(),
                const SizedBox(height: 30),
                _buildFamilyComparison(),
                const SizedBox(height: 30),
                _buildMemberActivity(),
                const SizedBox(height: 30),
                _buildContributionStats(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewCards() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('families').doc(widget.familyId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: Colors.amber));
        }
        final family = snapshot.data!.data() as Map<String, dynamic>;
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'إجمالي الأعضاء',
                    value: '${family['memberCount'] ?? 0}',
                    icon: Icons.people,
                    color: Colors.blueAccent,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _StatCard(
                    title: 'المستوى',
                    value: 'LV.${family['level'] ?? 1}',
                    icon: Icons.military_tech,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'خزينة الجواهر',
                    value: '${family['familyGems'] ?? 0}',
                    icon: Icons.diamond,
                    color: Colors.cyanAccent,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _StatCard(
                    title: 'خزينة النجوم',
                    value: '${family['familyStars'] ?? 0}',
                    icon: Icons.stars_rounded,
                    color: Colors.orangeAccent,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildActivityChart() {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(20),
      opacity: 0.03,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('نشاط العائلة',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('families')
                .doc(widget.familyId)
                .collection('activity_log')
                .orderBy('timestamp', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final activities = snapshot.data!.docs;
              if (activities.isEmpty) {
                return const Center(
                  child: Text('لا يوجد نشاط مسجل',
                      style: TextStyle(color: Colors.white38)),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  final activity =
                      activities[index].data() as Map<String, dynamic>;
                  return _ActivityTile(activity);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMemberActivity() {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(20),
      opacity: 0.03,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('نشاط الأعضاء',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('users')
                .where('familyId', isEqualTo: widget.familyId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final members = snapshot.data!.docs;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: members.length > 5 ? 5 : members.length,
                itemBuilder: (context, index) {
                  final member = members[index].data() as Map<String, dynamic>;
                  return _MemberActivityTile(member);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContributionStats() {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(20),
      opacity: 0.03,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('إحصائيات المساهمات',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('families')
                .doc(widget.familyId)
                .collection('members')
                .orderBy('totalContribution', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final contributors = snapshot.data!.docs;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: contributors.length,
                itemBuilder: (context, index) {
                  final contributor =
                      contributors[index].data() as Map<String, dynamic>;
                  return _ContributorStatTile(contributor, index + 1);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWarPerformance() {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(20),
      opacity: 0.03,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('تحليل أداء الحروب',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('families')
                .doc(widget.familyId)
                .collection('wars')
                .orderBy('createdAt', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final wars = snapshot.data!.docs;
              if (wars.isEmpty) {
                return const Center(
                  child: Text('لا توجد حروب مسجلة',
                      style: TextStyle(color: Colors.white38)),
                );
              }
              int wins = wars
                  .where((w) =>
                      (w.data() as Map<String, dynamic>)['status'] == 'won')
                  .length;
              int losses = wars
                  .where((w) =>
                      (w.data() as Map<String, dynamic>)['status'] == 'lost')
                  .length;
              int total = wars.length;
              double winRate = total > 0 ? (wins / total) * 100 : 0;

              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _WarStatCard('الانتصارات', '$wins', Colors.green),
                      _WarStatCard('الهزائم', '$losses', Colors.red),
                      _WarStatCard('نسبة الفوز',
                          '${winRate.toStringAsFixed(1)}%', Colors.amber),
                    ],
                  ),
                  const SizedBox(height: 20),
                  LinearProgressIndicator(
                    value: winRate / 100,
                    backgroundColor: Colors.white10,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.amber),
                    minHeight: 10,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContributionDistribution() {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(20),
      opacity: 0.03,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('توزيع المساهمات',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('families')
                .doc(widget.familyId)
                .collection('members')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final members = snapshot.data!.docs;
              if (members.isEmpty) {
                return const Center(
                  child: Text('لا يوجد أعضاء',
                      style: TextStyle(color: Colors.white38)),
                );
              }

              int totalContribution = 0;
              List<Map<String, dynamic>> memberContributions = [];

              for (var doc in members) {
                final data = doc.data() as Map<String, dynamic>;
                final contribution = (data['totalContribution'] ?? 0) as num;
                totalContribution += contribution.toInt();
                memberContributions.add({
                  'uid': doc.id,
                  'contribution': contribution.toInt(),
                });
              }

              memberContributions.sort((a, b) => (b['contribution'] as int)
                  .compareTo(a['contribution'] as int));

              return Column(
                children: [
                  ...memberContributions.take(5).map((mc) {
                    final contribution = mc['contribution'] as int;
                    final percentage = totalContribution > 0
                        ? (contribution / totalContribution) * 100
                        : 0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StreamBuilder<DocumentSnapshot>(
                            stream: _db
                                .collection('users')
                                .doc(mc['uid'])
                                .snapshots(),
                            builder: (context, userSnapshot) {
                              if (!userSnapshot.hasData) {
                                return const SizedBox();
                              }
                              final userData = userSnapshot.data!.data()
                                  as Map<String, dynamic>?;
                              final name = userData?['name'] ?? 'بدون اسم';
                              return Text(name,
                                  style:
                                      const TextStyle(color: Colors.white70));
                            },
                          ),
                          const SizedBox(height: 5),
                          LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: Colors.white10,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.cyanAccent),
                            minHeight: 8,
                          ),
                          const SizedBox(height: 3),
                          Text(
                              '${percentage.toStringAsFixed(1)}% - $contribution نقطة',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 11)),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyComparison() {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(20),
      opacity: 0.03,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('مقارنة مع العوائل الأخرى',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          StreamBuilder<DocumentSnapshot>(
            stream: _db.collection('families').doc(widget.familyId).snapshots(),
            builder: (context, familySnapshot) {
              if (!familySnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final familyData =
                  familySnapshot.data!.data() as Map<String, dynamic>;
              final currentLevel = familyData['level'] ?? 1;
              final currentExp = familyData['totalExp'] ?? 0;

              return StreamBuilder<QuerySnapshot>(
                stream: _db
                    .collection('families')
                    .orderBy('totalExp', descending: true)
                    .limit(10)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final topFamilies = snapshot.data!.docs;
                  int rank =
                      topFamilies.indexWhere((f) => f.id == widget.familyId) +
                          1;

                  return Column(
                    children: [
                      _ComparisonCard('الترتيب العالمي', '#$rank',
                          Icons.leaderboard, Colors.amber),
                      const SizedBox(height: 10),
                      _ComparisonCard('المستوى', 'LV.$currentLevel',
                          Icons.military_tech, Colors.blueAccent),
                      const SizedBox(height: 10),
                      _ComparisonCard('نقاط الخبرة', '$currentExp', Icons.star,
                          Colors.orangeAccent),
                      const SizedBox(height: 15),
                      Text('أفضل 5 عوائل',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 10),
                      ...topFamilies.take(5).map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return ListTile(
                          dense: true,
                          leading: Text('#${topFamilies.indexOf(doc) + 1}',
                              style: const TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold)),
                          title: Text(data['name'] ?? 'بدون اسم',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12)),
                          trailing: Text('${data['totalExp'] ?? 0} نقطة',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 11)),
                        );
                      }).toList(),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _WarStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(label,
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _ComparisonCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white70)),
          ),
          Text(value,
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(title,
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final Map<String, dynamic> activity;

  const _ActivityTile(this.activity);

  @override
  Widget build(BuildContext context) {
    final timestamp = activity['timestamp'] as Timestamp?;
    final time = timestamp != null
        ? '${timestamp.toDate().hour}:${timestamp.toDate().minute}'
        : '';
    final type = activity['type'] ?? 'نشاط';
    final description = activity['description'] ?? 'بدون وصف';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.amber.withValues(alpha: 0.2),
        child: const Icon(Icons.history, color: Colors.amber, size: 20),
      ),
      title: Text(type,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Text(description,
          style: const TextStyle(color: Colors.white54, fontSize: 12)),
      trailing: Text(time,
          style: const TextStyle(color: Colors.white38, fontSize: 11)),
    );
  }
}

class _MemberActivityTile extends StatelessWidget {
  final Map<String, dynamic> member;

  const _MemberActivityTile(this.member);

  @override
  Widget build(BuildContext context) {
    final isActive = member['isActive'] ?? false;
    final lastSeen = member['lastSeen'] as Timestamp?;
    final lastSeenText =
        lastSeen != null ? _formatLastSeen(lastSeen.toDate()) : 'غير معروف';

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: (member['profilePic'] != null &&
                Uri.tryParse(member['profilePic'])?.host.isNotEmpty == true)
            ? NetworkImage(member['profilePic'])
            : null,
      ),
      title: Text(member['name'] ?? 'بدون اسم',
          style: const TextStyle(color: Colors.white)),
      subtitle: Row(
        children: [
          Icon(Icons.circle,
              color: isActive ? Colors.greenAccent : Colors.white24, size: 8),
          const SizedBox(width: 5),
          Text(isActive ? 'متصل الآن' : 'آخر دخول: $lastSeenText',
              style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }

  String _formatLastSeen(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return 'منذ ${difference.inDays} يوم';
    }
  }
}

class _ContributorStatTile extends StatelessWidget {
  final Map<String, dynamic> contributor;
  final int rank;

  const _ContributorStatTile(this.contributor, this.rank);

  @override
  Widget build(BuildContext context) {
    final contribution = contributor['totalContribution'] ?? 0;
    final uid = contributor['uid'];

    return StreamBuilder<DocumentSnapshot>(
      stream:
          FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final name = userData?['name'] ?? 'بدون اسم';
        final profilePic = userData?['profilePic'];

        return ListTile(
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('#$rank',
                  style: TextStyle(
                      color: rank == 1
                          ? Colors.amber
                          : (rank == 2 ? Colors.grey[400] : Colors.brown[300]),
                      fontWeight: FontWeight.bold)),
              const SizedBox(width: 10),
              CircleAvatar(
                backgroundImage: (profilePic != null &&
                        Uri.tryParse(profilePic)?.host.isNotEmpty == true)
                    ? NetworkImage(profilePic)
                    : null,
              ),
            ],
          ),
          title: Text(name, style: const TextStyle(color: Colors.white)),
          trailing: Text('$contribution 💎',
              style: const TextStyle(
                  color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
        );
      },
    );
  }
}
