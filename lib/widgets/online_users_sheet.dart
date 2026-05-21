import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../app_theme.dart';
import '../features/profile/user_profile_page.dart';

class OnlineUsersSheet extends StatelessWidget {
  final String roomId;

  const OnlineUsersSheet({super.key, required this.roomId});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0F1B25), Color(0xFF051211)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border.all(color: AppTheme.royalGold.withValues(alpha: 0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 5,
          )
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 45,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.group_rounded, color: AppTheme.royalGold, size: 24),
                SizedBox(width: 10),
                Text(
                  'المتواجدون الآن',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1, indent: 20, endIndent: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rooms')
                  .doc(roomId)
                  .collection('online_users')
                  .orderBy('joinedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.royalGold));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person_off_rounded, color: Colors.white.withValues(alpha: 0.1), size: 60),
                        const SizedBox(height: 10),
                        const Text('الغرفة خالية حالياً', style: TextStyle(color: Colors.white38)),
                      ],
                    ),
                  );
                }

                final onlineDocs = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  itemCount: onlineDocs.length,
                  itemBuilder: (context, index) {
                    final onlineData = onlineDocs[index].data() as Map<String, dynamic>;
                    final String uid = onlineData['uid'] ?? '';

                    // جلب البيانات الحقيقية من مجموعة المستخدمين
                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
                      builder: (context, userSnap) {
                        if (!userSnap.hasData || !userSnap.data!.exists) {
                          return const SizedBox.shrink();
                        }

                        final userData = userSnap.data!.data() as Map<String, dynamic>;
                        final String name = userData['name'] ?? 'مستخدم ملكي';
                        final String royalId = userData['royalId']?.toString() ?? '------';
                        final String? photoUrl = userData['profilePic'];
                        final String? nobleLevel = userData['nobleLevel'];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                            leading: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _getNobleColor(nobleLevel),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 25,
                                    backgroundColor: Colors.white12,
                                    backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                                        ? CachedNetworkImageProvider(photoUrl)
                                        : null,
                                    child: (photoUrl == null || photoUrl.isEmpty)
                                        ? const Icon(Icons.person, color: Colors.white38)
                                        : null,
                                  ),
                                ),
                                if (userData['isActive'] == true)
                                  Positioned(
                                    right: 2,
                                    bottom: 2,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.greenAccent,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: const Color(0xFF0F1B25), width: 2),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Text('ID: ', style: TextStyle(color: Colors.white38, fontSize: 11)),
                                    Text(
                                      royalId,
                                      style: const TextStyle(
                                        color: AppTheme.royalGold,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: _buildRankBadge(nobleLevel),
                            onTap: () {
                              Navigator.pop(context); // إغلاق المنسدلة أولاً
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => UserProfilePage(
                                    userId: uid,
                                    roomId: roomId,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getNobleColor(String? level) {
    switch (level) {
      case 'N1': return Colors.grey;
      case 'N2': return Colors.blue;
      case 'N3': return Colors.purple;
      case 'N4': return Colors.orange;
      case 'N5': return Colors.red;
      case 'N6': return AppTheme.royalGold;
      default: return Colors.white24;
    }
  }

  Widget _buildRankBadge(String? level) {
    if (level == null || level == 'N1') return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getNobleColor(level).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getNobleColor(level).withValues(alpha: 0.5)),
      ),
      child: Text(
        level,
        style: TextStyle(
          color: _getNobleColor(level),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
