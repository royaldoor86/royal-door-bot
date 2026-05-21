import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/family_service.dart';
import '../app_theme.dart';

class FamilyLeaderboardPage extends StatefulWidget {
  final String familyId;
  const FamilyLeaderboardPage({super.key, required this.familyId});

  @override
  State<FamilyLeaderboardPage> createState() => _FamilyLeaderboardPageState();
}

class _FamilyLeaderboardPageState extends State<FamilyLeaderboardPage> {
  final FamilyService _familyService = FamilyService();

  @override
  void initState() {
    super.initState();
    _familyService.updateMemberRanks(widget.familyId);
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A050E),
        appBar: AppBar(
          title: const Text('ترتيب أعضاء العائلة',
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
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('families')
                .doc(widget.familyId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final familyData = snapshot.data!.data() as Map<String, dynamic>;
              final ranks =
                  Map<String, String>.from(familyData['memberRanks'] ?? {});
              return FutureBuilder<List<Map<String, dynamic>>>(
                future: _getMembersWithRanks(ranks),
                builder: (context, membersSnapshot) {
                  if (!membersSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final members = membersSnapshot.data!;
                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: members.length,
                    itemBuilder: (context, i) {
                      final member = members[i];
                      return AppTheme.glassContainer(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(15),
                        opacity: 0.05,
                        child: ListTile(
                          leading: Text('#${i + 1}',
                              style: const TextStyle(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.bold)),
                          title: Text(member['name'] ?? 'Unknown',
                              style: const TextStyle(color: Colors.white)),
                          subtitle: Text('الرتبة: ${member['rank']}',
                              style: const TextStyle(color: Colors.white70)),
                          trailing: Text('${member['contribution']} نقطة',
                              style: const TextStyle(color: Colors.cyanAccent)),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getMembersWithRanks(
      Map<String, String> ranks) async {
    List<Map<String, dynamic>> members = [];
    for (var entry in ranks.entries) {
      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(entry.key)
          .get();
      final memberSnap = await FirebaseFirestore.instance
          .collection('families')
          .doc(widget.familyId)
          .collection('members')
          .doc(entry.key)
          .get();
      if (userSnap.exists && memberSnap.exists) {
        members.add({
          'name': userSnap.data()?['name'] ?? 'Unknown',
          'rank': entry.value,
          'contribution': memberSnap.data()?['totalContribution'] ?? 0,
        });
      }
    }
    members.sort((a, b) =>
        (b['contribution'] as int).compareTo(a['contribution'] as int));
    return members;
  }
}
