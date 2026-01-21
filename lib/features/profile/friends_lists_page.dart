import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import 'profile_page.dart';

class FriendsListsPage extends StatelessWidget {
  final int initialIndex;
  const FriendsListsPage({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final firestoreService = FirestoreService();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const Scaffold(body: Center(child: Text('يرجى تسجيل الدخول')));

    return StreamBuilder<UserModel>(
      stream: firestoreService.streamUserData(user.uid),
      builder: (context, snapshot) {
        final userData = snapshot.data;
        
        return DefaultTabController(
          length: 3,
          initialIndex: initialIndex,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('قوائم التواصل'),
              centerTitle: true,
              bottom: const TabBar(
                labelColor: Colors.deepPurple,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.deepPurple,
                tabs: [
                  Tab(text: 'أصدقاء'),
                  Tab(text: 'تمت المتابعة'),
                  Tab(text: 'المعجبون'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _UserListStream(
                  stream: firestoreService.streamFriends(user.uid),
                  emptyMessage: 'لا يوجد أصدقاء حالياً',
                  buttonText: 'مراسلة',
                  buttonColor: Colors.blue,
                ),
                _UserListStream(
                  stream: firestoreService.streamUsersFromList(userData?.following ?? []),
                  emptyMessage: 'لم تقم بمتابعة أحد بعد',
                  buttonText: 'إلغاء المتابعة',
                  buttonColor: Colors.grey,
                ),
                _UserListStream(
                  stream: firestoreService.streamUsersFromList(userData?.followers ?? []),
                  emptyMessage: 'لا يوجد معجبون حالياً',
                  buttonText: 'رد المتابعة',
                  buttonColor: Colors.deepPurple,
                ),
              ],
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
  final String buttonText;
  final Color buttonColor;

  const _UserListStream({
    required this.stream,
    required this.emptyMessage,
    required this.buttonText,
    required this.buttonColor,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return Center(child: Text(emptyMessage, style: const TextStyle(color: Colors.grey)));
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: users.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              leading: CircleAvatar(
                radius: 25,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: user.profilePic.isNotEmpty ? NetworkImage(user.profilePic) : null,
                child: user.profilePic.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
              ),
              title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('ID: ${user.uid.substring(0, 8)}\n${user.bio}'),
              isThreeLine: true,
              trailing: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: Text(buttonText, style: const TextStyle(fontSize: 12)),
              ),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
              },
            );
          },
        );
      },
    );
  }
}
