import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../app_theme.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';

class BlockListPage extends StatefulWidget {
  const BlockListPage({super.key});

  @override
  State<BlockListPage> createState() => _BlockListPageState();
}

class _BlockListPageState extends State<BlockListPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  void _unblockUser(UserModel user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('رفع الحظر', style: TextStyle(color: Colors.white)),
        content: Text('هل أنت متأكد من رفع الحظر عن ${user.name}؟', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.white24))),
          ElevatedButton(
            onPressed: () async {
              await _firestoreService.unblockUser(_currentUserId, user.uid);
              if (mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم رفع الحظر بنجاح ✅')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.royalGold),
            child: const Text('تأكيد', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('قائمة الحظر', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: AppTheme.background(
          child: StreamBuilder<UserModel>(
            stream: _firestoreService.streamUserData(_currentUserId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.royalGold));
              }
              
              final blockedUids = snapshot.data?.blockedUsers ?? [];
              
              if (blockedUids.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.block_rounded, size: 80, color: Colors.white.withValues(alpha: 0.1)),
                      const SizedBox(height: 16),
                      const Text('لا يوجد مستخدمون محظورون', style: TextStyle(color: Colors.white38)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                itemCount: blockedUids.length,
                itemBuilder: (context, index) {
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(blockedUids[index]).get(),
                    builder: (context, userSnap) {
                      if (!userSnap.hasData) return const SizedBox.shrink();
                      final user = UserModel.fromMap(userSnap.data!.data() as Map<String, dynamic>, userSnap.data!.id);
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: AppTheme.glassContainer(
                          padding: const EdgeInsets.all(0),
                          opacity: 0.03,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: user.profilePic.isNotEmpty ? NetworkImage(user.profilePic) : null,
                              child: user.profilePic.isEmpty ? const Icon(Icons.person) : null,
                            ),
                            title: Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                            subtitle: Text('ID: ${user.royalId}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                            trailing: TextButton(
                              onPressed: () => _unblockUser(user),
                              child: const Text('رفع الحظر', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                            ),
                          ),
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
}
