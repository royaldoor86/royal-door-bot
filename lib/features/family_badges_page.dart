import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/family_service.dart';
import '../app_theme.dart';
import '../models/family_badge_model.dart';

class FamilyBadgesPage extends StatefulWidget {
  final String familyId;
  const FamilyBadgesPage({super.key, required this.familyId});

  @override
  State<FamilyBadgesPage> createState() => _FamilyBadgesPageState();
}

class _FamilyBadgesPageState extends State<FamilyBadgesPage> {
  final FamilyService _familyService = FamilyService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF1A050E),
        appBar: AppBar(
          title: const Text('شارات العائلة',
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3D0B16), Color(0xFF1A050E)],
            ),
          ),
          child: Column(
            children: [
              // Family Badges Section
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _db
                      .collection('families')
                      .doc(widget.familyId)
                      .collection('badges')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                          child:
                              CircularProgressIndicator(color: Colors.amber));
                    }

                    final familyBadges = snapshot.data!.docs;

                    return Column(
                      children: [
                        if (familyBadges.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('شارات العائلة',
                                    style: TextStyle(
                                        color: Colors.amber,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 15),
                                Wrap(
                                  spacing: 15,
                                  runSpacing: 15,
                                  children: familyBadges.map((doc) {
                                    final badgeData =
                                        doc.data() as Map<String, dynamic>;
                                    return FutureBuilder<DocumentSnapshot>(
                                      future: _db
                                          .collection('family_badges')
                                          .doc(badgeData['badgeId'])
                                          .get(),
                                      builder: (context, badgeSnapshot) {
                                        if (!badgeSnapshot.hasData ||
                                            !badgeSnapshot.data!.exists) {
                                          return const SizedBox();
                                        }

                                        final badge =
                                            FamilyBadgeModel.fromFirestore(
                                                badgeSnapshot.data!);
                                        return _buildBadgeCard(badge,
                                            isOwned: true);
                                      },
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),

                        const Divider(height: 30, color: Colors.white24),

                        // Available Badges Section
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: _db
                                .collection('family_badges')
                                .where('isActive', isEqualTo: true)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(
                                    child: CircularProgressIndicator(
                                        color: Colors.amber));
                              }

                              final availableBadges = snapshot.data!.docs;

                              return Column(
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.all(20),
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                          'الشارات المتاحة للشراء',
                                          style: TextStyle(
                                              color: Colors.amber,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  Expanded(
                                    child: GridView.builder(
                                      padding: const EdgeInsets.all(15),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        childAspectRatio: 0.6,
                                        crossAxisSpacing: 10,
                                        mainAxisSpacing: 10,
                                      ),
                                      itemCount: availableBadges.length,
                                      itemBuilder: (context, index) {
                                        final badge =
                                            FamilyBadgeModel.fromFirestore(
                                                availableBadges[index]);
                                        final isOwned = familyBadges.any(
                                            (doc) =>
                                                (doc.data() as Map<String,
                                                    dynamic>)['badgeId'] ==
                                                badge.id);

                                        if (badge.type == 'war_reward' ||
                                            badge.type == 'contributor') {
                                          return const SizedBox(); // Don't show reward badges in shop
                                        }

                                        return _buildBadgeCard(badge,
                                            isOwned: isOwned);
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
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

  Widget _buildBadgeCard(FamilyBadgeModel badge, {required bool isOwned}) {
    return AppTheme.glassContainer(
      padding: const EdgeInsets.all(10),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundImage: NetworkImage(badge.imageUrl),
            backgroundColor: Colors.white.withValues(alpha: 0.1),
          ),
          const SizedBox(height: 8),
          Text(badge.name,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(badge.description,
              style: const TextStyle(color: Colors.white38, fontSize: 9),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          if (isOwned)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
              ),
              child: const Text('مملوكة',
                  style: TextStyle(color: Colors.green, fontSize: 10)),
            )
          else if (badge.type == 'purchase')
            ElevatedButton(
              onPressed: () => _purchaseBadge(badge),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                minimumSize: const Size(double.infinity, 30),
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text('${badge.cost} 💎',
                  style: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
        ],
      ),
    );
  }

  Future<void> _purchaseBadge(FamilyBadgeModel badge) async {
    try {
      await _familyService.purchaseFamilyBadge(widget.familyId, badge.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('تم شراء الشارة بنجاح! 🎉'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
