import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import 'user_details_view_page.dart';

class FriendsListsPage extends StatelessWidget {
  final int initialIndex;
  const FriendsListsPage({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const Scaffold(backgroundColor: Color(0xFF020617), body: Center(child: Text('يرجى تسجيل الدخول', style: TextStyle(color: Colors.white))));

    return StreamBuilder<UserModel>(
      stream: firestoreService.streamUserData(user.uid),
      builder: (context, snapshot) {
        final userData = snapshot.data;
        
        return DefaultTabController(
          length: 3,
          initialIndex: initialIndex,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              backgroundColor: const Color(0xFF020617),
              appBar: AppBar(
                title: const Text('قوائم التواصل الملكي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                centerTitle: true,
                backgroundColor: const Color(0xFF1E293B),
                bottom: const TabBar(
                  labelColor: Colors.amber,
                  unselectedLabelColor: Colors.white38,
                  indicatorColor: Colors.amber,
                  tabs: [
                    Tab(text: 'أصدقاء'),
                    Tab(text: 'متابعة'),
                    Tab(text: 'معجبون'),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  _UserListStream(
                    stream: firestoreService.streamFriends(user.uid),
                    emptyMessage: 'لا يوجد أصدقاء حالياً',
                  ),
                  _UserListStream(
                    stream: firestoreService.streamUsersFromList(userData?.following ?? []),
                    emptyMessage: 'لم تقم بمتابعة أحد بعد',
                  ),
                  _UserListStream(
                    stream: firestoreService.streamUsersFromList(userData?.followers ?? []),
                    emptyMessage: 'لا يوجد معجبون حالياً',
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }
}

class _UserListStream extends StatelessWidget {
  final Stream<List<UserModel>> stream;
  final String emptyMessage;

  const _UserListStream({
    required this.stream,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.amber));
        }
        
        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return Center(child: Text(emptyMessage, style: const TextStyle(color: Colors.white24)));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          separatorBuilder: (context, index) => const Divider(color: Colors.white10, height: 20),
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              leading: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3), width: 1.5),
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white10,
                  backgroundImage: user.profilePic.isNotEmpty ? NetworkImage(user.profilePic) : null,
                  child: user.profilePic.isEmpty ? const Icon(Icons.person, color: Colors.white38) : null,
                ),
              ),
              title: Text(user.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white24),
              onTap: () {
                // فتح بروفايل المستخدم الحقيقي
                Navigator.push(context, MaterialPageRoute(builder: (_) => UserDetailsViewPage(user: user)));
              },
            );
          },
        );
      },
    );
  }
}
