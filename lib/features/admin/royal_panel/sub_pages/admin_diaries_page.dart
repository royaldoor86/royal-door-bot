import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../models/post_model.dart';

class AdminDiariesPage extends StatefulWidget {
  const AdminDiariesPage({super.key});

  @override
  State<AdminDiariesPage> createState() => _AdminDiariesPageState();
}

class _AdminDiariesPageState extends State<AdminDiariesPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";

  final Color primaryDark = const Color(0xFF0A1F1C);
  final Color accentGold = const Color(0xFFC5A059);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: primaryDark,
        appBar: AppBar(
          backgroundColor: const Color(0xFF051211),
          title: Text('إدارة اليوميات الملكية', style: TextStyle(color: accentGold, fontWeight: FontWeight.bold)),
          centerTitle: true,
        ),
        body: Column(
          children: [
            _buildSearchBar(),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _db.collection('posts').orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.amber));
                  }

                  final docs = snapshot.data?.docs ?? [];
                  final filteredDocs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['authorName'] ?? '').toString().toLowerCase();
                    return name.contains(_searchText.toLowerCase());
                  }).toList();

                  if (filteredDocs.isEmpty) {
                    return const Center(child: Text('لا توجد منشورات تطابق بحثك', style: TextStyle(color: Colors.white24)));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final post = PostModel.fromMap(filteredDocs[index].data() as Map<String, dynamic>, filteredDocs[index].id);
                      return _buildAdminPostCard(post);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFF051211),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'ابحث عن منشورات مستخدم...',
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
          prefixIcon: Icon(Icons.search, color: accentGold),
          filled: true, fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        ),
        onChanged: (v) => setState(() => _searchText = v),
      ),
    );
  }

  Widget _buildAdminPostCard(PostModel post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: accentGold.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: CircleAvatar(radius: 25, backgroundImage: NetworkImage(post.authorPic)),
            title: Text(post.authorName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: Text('نُشر في: ${post.createdAt.toString().substring(0, 16)}', style: const TextStyle(color: Colors.white24, fontSize: 10)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 22),
              onPressed: () => _deletePost(post.id),
            ),
          ),
          if (post.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(post.content, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ),
          
          _buildMediaPreview(post),

          const Divider(color: Colors.white10, indent: 16, endIndent: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _statItem(Icons.favorite, '${post.likes.length}', Colors.redAccent),
                    const SizedBox(width: 15),
                    _statItem(Icons.comment, '${post.commentCount}', Colors.blueAccent),
                  ],
                ),
                TextButton.icon(
                  onPressed: () => _showCommentsManager(post.id),
                  icon: const Icon(Icons.forum_rounded, size: 16),
                  label: const Text('إدارة التعليقات', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: accentGold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview(PostModel post) {
    if (post.imageUrl != null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.network(post.imageUrl!, height: 180, width: double.infinity, fit: BoxFit.cover),
        ),
      );
    }
    if (post.videoUrl != null) {
      return Container(
        height: 60, margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(12)),
        child: const Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.play_circle_fill, color: Colors.amber), SizedBox(width: 10), Text('فيديو مرفق', style: TextStyle(color: Colors.white70))])),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _statItem(IconData icon, String val, Color color) {
    return Row(children: [Icon(icon, size: 14, color: color), const SizedBox(width: 4), Text(val, style: const TextStyle(color: Colors.white54, fontSize: 12))]);
  }

  void _showCommentsManager(String postId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(color: primaryDark, borderRadius: const BorderRadius.vertical(top: Radius.circular(30))),
        child: Column(
          children: [
            const SizedBox(height: 15),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10))),
            const Padding(
              padding: EdgeInsets.all(20.0),
              child: Text('الرقابة على التعليقات', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _db.collection('posts').doc(postId).collection('comments').orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final comments = snapshot.data!.docs;
                  if (comments.isEmpty) return const Center(child: Text('لا توجد تعليقات بعد', style: TextStyle(color: Colors.white24)));

                  return ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, i) {
                      final c = comments[i].data() as Map<String, dynamic>;
                      return ListTile(
                        leading: CircleAvatar(radius: 15, backgroundImage: NetworkImage(c['userPic'] ?? '')),
                        title: Text(c['userName'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        subtitle: Text(c['text'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 18),
                          onPressed: () => comments[i].reference.delete(),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePost(String postId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text("تأكيد الحذف", style: TextStyle(color: Colors.redAccent)),
        content: const Text("هل تريد إزالة هذا المنشور وكافة تعليقاته نهائياً؟"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("تراجع")),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text("حذف الآن")),
        ],
      ),
    );
    if (confirm == true) {
      await _db.collection('posts').doc(postId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف المنشور بنجاح')),
        );
      }
    }
  }
}
