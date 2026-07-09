import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import 'user_details_view_page.dart';

class VisitorsPage extends StatelessWidget {
  const VisitorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF020617),
        body: Center(
          child: Text('يرجى تسجيل الدخول', style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF020617),
        appBar: AppBar(
          title: const Text('زوار الملف الملكي',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          centerTitle: true,
          backgroundColor: const Color(0xFF1E293B),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: StreamBuilder<List<UserModel>>(
          stream: firestoreService.streamVisitors(user.uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.amber));
            }

            final visitors = snapshot.data ?? [];

            if (visitors.isEmpty) {
              return const Center(
                child: Text('لا يوجد زوار لملفك الشخصي حالياً',
                    style: TextStyle(color: Colors.white38)),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: visitors.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: Colors.white10, height: 20),
              itemBuilder: (context, index) {
                final visitor = visitors[index];
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  leading: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.white10,
                      backgroundImage: visitor.profilePic.isNotEmpty
                          ? NetworkImage(visitor.profilePic)
                          : null,
                      child: visitor.profilePic.isEmpty
                          ? const Icon(Icons.person, color: Colors.white38)
                          : null,
                    ),
                  ),
                  title: Text(visitor.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  trailing: const Icon(Icons.arrow_forward_ios,
                      size: 14, color: Colors.white24),
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => UserDetailsViewPage(user: visitor)));
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
