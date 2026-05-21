import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/post_model.dart';
import '../../models/chat_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../app_theme.dart';

String formatPostDate(DateTime dt) {
  try {
    final now = DateTime.now();
    final localDt = dt.toLocal();
    final diff = now.difference(localDt);

    if (diff.inSeconds < 60) return 'الآن';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      if (m == 1) return 'منذ دقيقة';
      return 'منذ $m دقيقة';
    }
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    return DateFormat('d MMMM yyyy', 'ar').format(localDt);
  } catch (e) {
    return DateFormat('yyyy-MM-dd').format(dt);
  }
}

Future<void> downloadMedia(BuildContext context, String url, {required bool isImage}) async {
  try {
    final status = await Permission.storage.request();
    if (!status.isGranted) {
       if (Platform.isAndroid) {
         await Permission.photos.request();
         await Permission.videos.request();
       }
    }
    final uri = Uri.parse(url);
    final res = await http.get(uri);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/download_${DateTime.now().millisecondsSinceEpoch}.${isImage ? 'jpg' : 'mp4'}');
    await file.writeAsBytes(res.bodyBytes);
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم التحميل بنجاح ✅')));
  } catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فشل التحميل')));
  }
}

Future<void> sharePostWithMedia(BuildContext context, PostModel post) async {
  const String playStoreUrl = 'https://play.google.com/store/apps/details?id=com.royaldur.app';
  const String appStoreUrl = 'https://apps.apple.com/app/id6739543323';
  final String shareLink = 'https://royaldur.app/post/${post.id}';
  
  final String shareText = '''
👑 رويال دور - Royal Dur 👑
🌟 منشور ملكي من: ${post.authorName}
📝 "${post.content.take(150)}"
🔗 $shareLink
📥 Android: $playStoreUrl
🍎 iOS: $appStoreUrl
''';

  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1A1A1A),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 15),
          const Text('مشاركة المنشور', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 20),
          ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.blueAccent, child: Icon(Icons.send_rounded, color: Colors.white)),
            title: const Text('إرسال للأصدقاء (داخل التطبيق)', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(ctx);
              _showShareToFriendsSheet(context, post, shareLink);
            },
          ),
          ListTile(
            leading: const CircleAvatar(backgroundColor: AppTheme.royalGold, child: Icon(Icons.share, color: Colors.black)),
            title: const Text('مشاركة للتطبيقات الخارجية', style: TextStyle(color: Colors.white)),
            onTap: () async {
              Navigator.pop(ctx);
              try {
                final String? imgUrl = (post.imageUrls?.isNotEmpty == true) ? post.imageUrls![0] : post.imageUrl;
                if (imgUrl != null && imgUrl.isNotEmpty) {
                  final res = await http.get(Uri.parse(imgUrl));
                  final dir = await getTemporaryDirectory();
                  final file = File('${dir.path}/share_img.jpg');
                  await file.writeAsBytes(res.bodyBytes);
                  await Share.shareXFiles([XFile(file.path)], text: shareText);
                } else {
                  await Share.share(shareText);
                }
              } catch (e) {
                await Share.share(shareText);
              }
            },
          ),
          const SizedBox(height: 10),
        ],
      ),
    ),
  );
}

void _showShareToFriendsSheet(BuildContext context, PostModel post, String link) {
  final FirestoreService fs = FirestoreService();
  final String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final Set<String> sentTo = {}; 

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF121212),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
    builder: (ctx) => StatefulBuilder(
      builder: (context, setModalState) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const Padding(padding: EdgeInsets.all(20), child: Text('مشاركة مع الأصدقاء', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
            Expanded(
              child: StreamBuilder<List<UserModel>>(
                stream: fs.streamFriends(uid),
                builder: (context, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AppTheme.royalGold));
                  final friends = snap.data!;
                  return ListView.builder(
                    controller: scrollController,
                    itemCount: friends.length,
                    itemBuilder: (context, i) {
                      final f = friends[i];
                      final bool isSent = sentTo.contains(f.uid);
                      return ListTile(
                        leading: CircleAvatar(backgroundImage: CachedNetworkImageProvider(f.profilePic)),
                        title: Text(f.name, style: const TextStyle(color: Colors.white)),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: isSent ? Colors.grey : AppTheme.royalGold),
                          onPressed: isSent ? null : () async {
                            setModalState(() { sentTo.add(f.uid); });
                            final roomId = await fs.ensureChatRoomExists(uid, f.uid);
                            await fs.sendMessage(roomId, MessageModel(id: '', senderId: uid, text: 'POST_CARD|${post.id}|${post.authorName}|${post.content.take(50)}|${(post.imageUrls?.isNotEmpty == true) ? post.imageUrls![0] : (post.imageUrl ?? "")}', timestamp: DateTime.now(), type: MessageType.text));
                          },
                          child: Text(isSent ? 'تم' : 'إرسال'),
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
    ),
  );
}

void openCommentsSheet(BuildContext context, PostModel post) {
  final FirestoreService firestoreService = FirestoreService();
  final String currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final TextEditingController controller = TextEditingController();
  
  // لتعقب الرد على تعليق معين
  String? replyingToId;
  String? replyingToName;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setModalState) {
        final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
        final double safeAreaBottom = MediaQuery.of(context).padding.bottom;

        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: const Color(0xFF121212).withValues(alpha: 0.98),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 15),
              Container(width: 45, height: 5, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(10))),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('التعليقات', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: firestoreService.streamPostComments(post.id),
                  builder: (context, snap) {
                    if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AppTheme.royalGold));
                    final allComments = snap.data!;
                    
                    // فصل التعليقات الأساسية عن الردود
                    final mainComments = allComments.where((c) => c['parentId'] == null).toList();
                    
                    return ListView.builder(
                      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
                      itemCount: mainComments.length,
                      itemBuilder: (context, i) {
                        final cm = mainComments[i];
                        final String commentId = cm['id'];
                        final List replies = allComments.where((c) => c['parentId'] == commentId).toList();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCommentItem(context, cm, post.id, currentUid, firestoreService, (id, name) {
                              setModalState(() {
                                replyingToId = id;
                                replyingToName = name;
                              });
                            }),
                            
                            // عرض الردود تحت التعليق
                            if (replies.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(right: 40),
                                child: Column(
                                  children: replies.map((reply) => _buildCommentItem(
                                    context, reply, post.id, currentUid, firestoreService, (id, name) {
                                      setModalState(() {
                                        replyingToId = commentId; // الردود ترتبط بالتعليق الأب
                                        replyingToName = name;
                                      });
                                    },
                                    isReply: true
                                  )).toList(),
                                ),
                              ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),

              // شريط كتابة التعليق
              Container(
                padding: EdgeInsets.only(
                  bottom: keyboardHeight > 0 ? keyboardHeight + 15 : safeAreaBottom + 25, 
                  left: 16, right: 16, top: 10
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (replyingToName != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8, right: 10),
                        child: Row(
                          children: [
                            const Icon(Icons.reply, color: AppTheme.royalGold, size: 16),
                            const SizedBox(width: 5),
                            Text('الرد على $replyingToName', style: const TextStyle(color: AppTheme.royalGold, fontSize: 12)),
                            const Spacer(),
                            GestureDetector(
                              onTap: () => setModalState(() { replyingToId = null; replyingToName = null; }),
                              child: const Icon(Icons.close, color: Colors.white38, size: 16),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05), 
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: TextField(
                              controller: controller,
                              maxLines: null,
                              style: const TextStyle(color: Colors.white, fontSize: 15),
                              decoration: const InputDecoration(
                                hintText: 'اكتب تعليقاً ملكياً...', 
                                hintStyle: TextStyle(color: Colors.white24), 
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () async {
                            final text = controller.text.trim();
                            if (text.isEmpty) return;
                            final user = await firestoreService.streamUserData(currentUid).first;
                            await firestoreService.addPostComment(
                              post.id, currentUid, user.name, user.profilePic, text,
                              parentId: replyingToId,
                              replyToName: replyingToName,
                            );
                            controller.clear();
                            setModalState(() { replyingToId = null; replyingToName = null; });
                            FocusScope.of(context).unfocus();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(color: AppTheme.royalGold, shape: BoxShape.circle),
                            child: const Icon(Icons.send_rounded, color: Colors.black, size: 22),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

Widget _buildCommentItem(
  BuildContext context, 
  Map<String, dynamic> cm, 
  String postId, 
  String currentUid, 
  FirestoreService fs,
  Function(String, String) onReply,
  {bool isReply = false}
) {
  final bool isMe = cm['userId'] == currentUid;
  final List likes = List.from(cm['likes'] ?? []);
  final bool isLiked = likes.contains(currentUid);

  return Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: isReply ? 15 : 20, 
          backgroundImage: CachedNetworkImageProvider(cm['userPic'] ?? '')
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: isReply ? 0.03 : 0.06),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(cm['userName'] ?? '', style: TextStyle(color: AppTheme.royalGold, fontWeight: FontWeight.bold, fontSize: isReply ? 11 : 13)),
                        if (isMe) 
                          GestureDetector(
                            onTapDown: (details) => _showCommentMenu(context, postId, cm, details.globalPosition),
                            child: const Icon(Icons.more_horiz, color: Colors.white38, size: 18),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    if (cm['replyToName'] != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text('@${cm['replyToName']}', style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    Text(cm['text'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => fs.togglePostCommentLike(postId, cm['id'], currentUid),
                    child: Row(
                      children: [
                        Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.redAccent : Colors.white38, size: 14),
                        if (likes.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Text('${likes.length}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                        ]
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  GestureDetector(
                    onTap: () => onReply(cm['id'], cm['userName']),
                    child: const Text('رد', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 20),
                  Text(formatPostDate((cm['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now()), style: const TextStyle(color: Colors.white24, fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

void _showCommentMenu(BuildContext context, String postId, Map<String, dynamic> comment, Offset position) {
  final FirestoreService fs = FirestoreService();
  showMenu(
    context: context,
    position: RelativeRect.fromLTRB(position.dx, position.dy, 20, 0),
    color: const Color(0xFF1E1E1E),
    items: [
      const PopupMenuItem(value: 'edit', child: Text('تعديل', style: TextStyle(color: Colors.white))),
      const PopupMenuItem(value: 'delete', child: Text('حذف', style: TextStyle(color: Colors.redAccent))),
    ],
  ).then((val) {
    if (val == 'edit') _showEditCommentDialog(context, postId, comment);
    if (val == 'delete') fs.deletePostComment(postId, comment['id']);
  });
}

void _showEditCommentDialog(BuildContext context, String postId, Map<String, dynamic> comment) {
  final TextEditingController editController = TextEditingController(text: comment['text']);
  final FirestoreService fs = FirestoreService();

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('تعديل التعليق', style: TextStyle(color: Colors.white, fontSize: 16)),
      content: TextField(
        controller: editController,
        maxLines: null,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.royalGold)),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.white38))),
        TextButton(
          onPressed: () async {
            if (editController.text.trim().isNotEmpty) {
              await fs.editPostComment(postId, comment['id'], editController.text.trim());
              if (context.mounted) Navigator.pop(ctx);
            }
          }, 
          child: const Text('حفظ', style: TextStyle(color: AppTheme.royalGold))
        ),
      ],
    ),
  );
}

extension StringExtension on String {
  String take(int n) => length <= n ? this : '${substring(0, n)}...';
}

class ImageViewer extends StatelessWidget {
  final String imageUrl;
  final String? postText;
  const ImageViewer({super.key, required this.imageUrl, this.postText});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, iconTheme: const IconThemeData(color: Colors.white)),
      body: Center(child: InteractiveViewer(child: CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.contain))),
    );
  }
}
