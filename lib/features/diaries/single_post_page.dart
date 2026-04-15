import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/post_model.dart';
import '../../services/firestore_service.dart';
import '../../app_theme.dart';
import 'widgets/post_card.dart';

class SinglePostPage extends StatelessWidget {
  final String postId;
  const SinglePostPage({super.key, required this.postId});

  @override
  Widget build(BuildContext context) {
    final FirestoreService fs = FirestoreService();
    final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text('المنشور', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: FutureBuilder<PostModel?>(
        future: fs.getPostById(postId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.royalGold));
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('عذراً، هذا المنشور غير موجود أو تم حذفه.', style: TextStyle(color: Colors.white54)));
          }

          final post = snapshot.data!;
          return SingleChildScrollView(
            child: PostCard(
              post: post,
              currentUid: currentUid,
              onUpdate: (_) {}, // لا نحتاج للتحديث هنا في صفحة العرض المفرد
            ),
          );
        },
      ),
    );
  }
}
