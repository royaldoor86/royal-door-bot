import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/user_model.dart';
import 'profile_page.dart';

class VisitorsPage extends StatelessWidget {
  const VisitorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final firestoreService = FirestoreService();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const Scaffold(body: Center(child: Text('يرجى تسجيل الدخول')));

    return Scaffold(
      appBar: AppBar(
        title: const Text('زوار الملف الشخصي'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<UserModel>>(
        stream: firestoreService.streamVisitors(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final visitors = snapshot.data ?? [];

          if (visitors.isEmpty) {
            return const Center(
              child: Text('لا يوجد زوار لملفك الشخصي حالياً', style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.separated(
            itemCount: visitors.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final visitor = visitors[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: visitor.profilePic.isNotEmpty ? NetworkImage(visitor.profilePic) : null,
                  child: visitor.profilePic.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
                ),
                title: Text(visitor.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('ID: ${visitor.uid.substring(0, 8)}'),
                trailing: const Icon(Icons.chevron_left, size: 16, color: Colors.grey),
                onTap: () {
                  // فتح بروفايل الزائر
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
                },
              );
            },
          );
        },
      ),
    );
  }
}
