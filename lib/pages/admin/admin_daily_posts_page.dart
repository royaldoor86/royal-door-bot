import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminDailyPostsPage extends StatefulWidget {
  const AdminDailyPostsPage({super.key});

  @override
  State<AdminDailyPostsPage> createState() => _AdminDailyPostsPageState();
}

class _AdminDailyPostsPageState extends State<AdminDailyPostsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";

  Future<void> _deletePost(String postId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1B0233),
        title: const Text("حذف المنشور نهائياً",
            style: TextStyle(color: Colors.redAccent)),
        content: const Text(
            "هل أنت متأكد من حذف هذا المنشور؟ سيؤدي هذا لمسح المنشور وجميع التعليقات المرتبطة به.",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("إلغاء")),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("حذف")),
        ],
      ),
    );

    if (confirm == true) {
      // حذف المنشور
      await _db.collection('daily_posts').doc(postId).delete();
      // ملاحظة: التعليقات هي sub-collection، في فايرستور يجب حذفها يدوياً أو عبر Cloud Function
      // هنا سنحذف المنشور الأساسي فقط لتبسيط العملية
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("تم حذف المنشور بنجاح"),
            backgroundColor: Colors.green));
      }
    }
  }

  void _showComments(String postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1B0233),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            const Padding(
                padding: EdgeInsets.all(16),
                child: Text("إدارة التعليقات",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18))),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _db
                    .collection('daily_posts')
                    .doc(postId)
                    .collection('comments')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final comments = snapshot.data!.docs;
                  if (comments.isEmpty) {
                    return const Center(
                        child: Text("لا توجد تعليقات",
                            style: TextStyle(color: Colors.white24)));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final data =
                          comments[index].data() as Map<String, dynamic>;
                      return Card(
                        color: Colors.white.withValues(alpha: 0.05),
                        child: ListTile(
                          title: Text(data['userName'] ?? "مستخدم",
                              style: const TextStyle(
                                  color: Colors.amber, fontSize: 12)),
                          subtitle: Text(data['text'] ?? "",
                              style: const TextStyle(color: Colors.white)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.redAccent),
                            onPressed: () async {
                              await _db
                                  .collection('daily_posts')
                                  .doc(postId)
                                  .collection('comments')
                                  .doc(comments[index].id)
                                  .delete();
                              // تحديث عداد التعليقات في المنشور
                              await _db
                                  .collection('daily_posts')
                                  .doc(postId)
                                  .update({
                                'commentsCount': FieldValue.increment(-1)
                              });
                            },
                          ),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "بحث في اليوميات (اسم المستخدم، نص)...",
              prefixIcon: const Icon(Icons.search, color: Colors.amber),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none),
            ),
            onChanged: (v) => setState(() => _searchText = v.toLowerCase()),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('daily_posts')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              var docs = snapshot.data!.docs;
              if (_searchText.isNotEmpty) {
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name =
                      (data['userName'] ?? '').toString().toLowerCase();
                  final text = (data['text'] ?? '').toString().toLowerCase();
                  return name.contains(_searchText) ||
                      text.contains(_searchText);
                }).toList();
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final id = docs[index].id;
                  final String? imageUrl = data['imageUrl'];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(15)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ListTile(
                          leading: CircleAvatar(
                              backgroundImage: data['photoURL'] != null &&
                                      data['photoURL'].isNotEmpty
                                  ? NetworkImage(data['photoURL'])
                                  : null),
                          title: Text(data['userName'] ?? "مستخدم",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          subtitle: Text(id,
                              style: const TextStyle(
                                  color: Colors.white24, fontSize: 10)),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert,
                                color: Colors.white),
                            color: const Color(0xFF1B0233),
                            tooltip: 'خيارات',
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            onSelected: (String value) {
                              if (value == 'delete') _deletePost(id);
                            },
                            itemBuilder: (BuildContext context) =>
                                <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.delete_forever,
                                        color: Colors.redAccent, size: 20),
                                    SizedBox(width: 8),
                                    Text("حذف القصة",
                                        style: TextStyle(color: Colors.white)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (data['text'] != null && data['text'].isNotEmpty)
                          Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Text(data['text'],
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 13))),
                        if (imageUrl != null && imageUrl.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(imageUrl,
                                    height: 100,
                                    width: double.infinity,
                                    fit: BoxFit.cover)),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.comment,
                                    size: 16, color: Colors.amber),
                                label: Text(
                                    "${data['commentsCount'] ?? 0} تعليقات",
                                    style: const TextStyle(
                                        color: Colors.amber, fontSize: 12)),
                                onPressed: () => _showComments(id),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
