import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/post_model.dart';
import '../../../app_theme.dart';
import '../../../services/firestore_service.dart';
import '../../profile/user_details_view_page.dart';
import 'video_widget.dart';
import '../diaries_utils.dart';
import '../edit_post_page.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final String currentUid;
  final bool isFollowing;
  final bool isFriend;
  final Function(String) onUpdate;

  const PostCard({
    super.key,
    required this.post,
    required this.currentUid,
    this.isFollowing = false,
    this.isFriend = false,
    required this.onUpdate,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final bool isLiked = widget.post.likes.contains(widget.currentUid);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: AppTheme.glassContainer(
        padding: const EdgeInsets.all(0),
        opacity: 0.1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              leading: GestureDetector(
                onTap: () => _navigateToUser(widget.post.authorId),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [AppTheme.royalGold, Colors.orangeAccent]),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.black,
                    backgroundImage: widget.post.authorPic.isNotEmpty && Uri.tryParse(widget.post.authorPic)?.host.isNotEmpty == true
                        ? CachedNetworkImageProvider(widget.post.authorPic)
                        : null,
                    child: widget.post.authorPic.isEmpty ? const Icon(Icons.person, color: Colors.white24) : null,
                  ),
                ),
              ),
              title: Text(widget.post.authorName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text(formatPostDate(widget.post.createdAt),
                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
              trailing: IconButton(
                icon: const Icon(Icons.more_horiz, color: Colors.white54),
                onPressed: () => _showPostOptions(context, widget.post),
              ),
            ),
            
            // Content Text
            if (widget.post.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHashtagContent(widget.post.content),
                    if (widget.post.content.length > 100 || '\n'.allMatches(widget.post.content).length >= 3)
                      GestureDetector(
                        onTap: () => setState(() => _isExpanded = !_isExpanded),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _isExpanded ? 'عرض أقل' : '... المزيد',
                            style: const TextStyle(color: AppTheme.royalGold, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // Media Section
            _buildMediaSection(context),

            // Interaction Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  if (widget.post.likes.isNotEmpty) ...[
                    const Icon(Icons.favorite, color: Colors.redAccent, size: 14),
                    const SizedBox(width: 4),
                    Text('${widget.post.likes.length}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    const Spacer(),
                  ],
                  if (widget.post.commentCount > 0)
                    Text('${widget.post.commentCount} تعليق', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),

            const Divider(color: Colors.white10, height: 1, indent: 12, endIndent: 12),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  _actionBtn(
                    isLiked ? Icons.favorite : Icons.favorite_border_rounded,
                    isLiked ? 'أعجبني' : 'إعجاب',
                    isLiked ? Colors.redAccent : Colors.white70,
                    () {
                      HapticFeedback.lightImpact();
                      _firestoreService.toggleLike(widget.post.id, widget.currentUid);
                    },
                  ),
                  _actionBtn(Icons.chat_bubble_outline_rounded, 'تعليق', Colors.white70, () => openCommentsSheet(context, widget.post)),
                  _actionBtn(Icons.share_outlined, 'مشاركة', Colors.white70, () => sharePostWithMedia(context, widget.post)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaSection(BuildContext context) {
    if (widget.post.videoUrl != null && widget.post.videoUrl!.isNotEmpty) {
      return VideoWidget(videoUrl: widget.post.videoUrl!);
    } else if (widget.post.imageUrls != null && widget.post.imageUrls!.isNotEmpty) {
      return _buildFacebookStyleImages(context, widget.post.imageUrls!);
    } else if (widget.post.imageUrl != null && widget.post.imageUrl!.isNotEmpty) {
      return _buildImageSection(context, widget.post.imageUrl!);
    }
    return const SizedBox.shrink();
  }

  // --- نظام عرض الصور المتطور (Facebook Style) ---
  Widget _buildFacebookStyleImages(BuildContext context, List<String> urls) {
    if (urls.isEmpty) return const SizedBox.shrink();
    if (urls.length == 1) return _buildImageSection(context, urls[0]);

    double height = 300; // ارتفاع ثابت للقسم البرمجي للصور

    if (urls.length == 2) {
      return SizedBox(
        height: height,
        child: Row(
          children: [
            Expanded(child: _buildSingleGridItem(urls[0])),
            const SizedBox(width: 2),
            Expanded(child: _buildSingleGridItem(urls[1])),
          ],
        ),
      );
    }

    if (urls.length == 3) {
      return SizedBox(
        height: height,
        child: Row(
          children: [
            Expanded(child: _buildSingleGridItem(urls[0])),
            const SizedBox(width: 2),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: _buildSingleGridItem(urls[1])),
                  const SizedBox(height: 2),
                  Expanded(child: _buildSingleGridItem(urls[2])),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 4 صور أو أكثر
    return SizedBox(
      height: height,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildSingleGridItem(urls[0])),
                const SizedBox(width: 2),
                Expanded(child: _buildSingleGridItem(urls[1])),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildSingleGridItem(urls[2])),
                const SizedBox(width: 2),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildSingleGridItem(urls[3]),
                      if (urls.length > 4)
                        Container(
                          color: Colors.black54,
                          child: Center(
                            child: Text(
                              '+${urls.length - 4}',
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleGridItem(String url) {
    final bool isValidUrl = url.isNotEmpty && Uri.tryParse(url)?.host.isNotEmpty == true;
    return GestureDetector(
      onTap: () => isValidUrl ? Navigator.push(context, MaterialPageRoute(builder: (_) => ImageViewer(imageUrl: url, postText: widget.post.content))) : null,
      child: isValidUrl 
        ? CachedNetworkImage(
            imageUrl: url,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            placeholder: (c, u) => Container(color: Colors.white10, child: const Center(child: CircularProgressIndicator(color: AppTheme.royalGold, strokeWidth: 1))),
            errorWidget: (c, u, e) => const Icon(Icons.error, color: Colors.white24),
          )
        : Container(color: Colors.white10, child: const Icon(Icons.broken_image, color: Colors.white24)),
    );
  }

  Widget _buildImageSection(BuildContext context, String url) {
    final bool isValidUrl = url.isNotEmpty && Uri.tryParse(url)?.host.isNotEmpty == true;
    return GestureDetector(
      onTap: () => isValidUrl ? Navigator.push(context, MaterialPageRoute(builder: (_) => ImageViewer(imageUrl: url, postText: widget.post.content))) : null,
      child: isValidUrl
        ? CachedNetworkImage(
            imageUrl: url,
            width: double.infinity,
            fit: BoxFit.cover,
            placeholder: (c, u) => Container(height: 250, color: Colors.white10, child: const Center(child: CircularProgressIndicator(color: AppTheme.royalGold, strokeWidth: 2))),
            errorWidget: (c, u, e) => const Icon(Icons.error, color: Colors.white24),
          )
        : Container(height: 200, color: Colors.white10, child: const Icon(Icons.broken_image, color: Colors.white24)),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHashtagContent(String content) {
    final List<TextSpan> spans = [];
    final words = content.split(' ');
    for (var word in words) {
      if (word.startsWith('#')) {
        spans.add(TextSpan(text: '$word ', style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)));
      } else {
        spans.add(TextSpan(text: '$word ', style: const TextStyle(color: Colors.white)));
      }
    }
    return RichText(
      maxLines: _isExpanded ? 100 : 3,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(children: spans, style: const TextStyle(fontSize: 14, height: 1.4, fontFamily: 'Cairo')),
    );
  }

  void _navigateToUser(String uid) async {
    try {
      final user = await _firestoreService.streamUserData(uid).first;
      if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => UserDetailsViewPage(user: user)));
    } catch (e) {
      debugPrint('Error navigating to user: $e');
    }
  }

  void _showPostOptions(BuildContext context, PostModel post) async {
    final isOwner = post.authorId == widget.currentUid;
    final res = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.share_outlined, color: Colors.white), title: const Text('مشاركة المنشور', style: TextStyle(color: Colors.white)), onTap: () => Navigator.pop(ctx, 'share')),
          if (!isOwner) ListTile(leading: const Icon(Icons.report_problem_outlined, color: Colors.orangeAccent), title: const Text('إبلاغ عن المنشور', style: TextStyle(color: Colors.orangeAccent)), onTap: () => Navigator.pop(ctx, 'report')),
          if (isOwner) ListTile(leading: const Icon(Icons.edit_outlined, color: Colors.white), title: const Text('تعديل المنشور', style: TextStyle(color: Colors.white)), onTap: () => Navigator.pop(ctx, 'edit')),
          if (isOwner) ListTile(leading: const Icon(Icons.delete_forever_outlined, color: Colors.redAccent), title: const Text('حذف المنشور', style: TextStyle(color: Colors.redAccent)), onTap: () => Navigator.pop(ctx, 'delete')),
          const SizedBox(height: 10),
        ]),
      ),
    );

    if (res == 'share') sharePostWithMedia(context, post);
    if (res == 'report') _reportPost(context, post);
    if (res == 'edit') {
      if (context.mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => EditPostPage(post: post)));
      }
    }
    if (res == 'delete') _confirmDeletePost(context, post.id);
  }

  void _confirmDeletePost(BuildContext context, String postId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('حذف المنشور', style: TextStyle(color: Colors.white)),
        content: const Text('هل أنت متأكد من حذف هذا المنشور نهائياً؟', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.white38))),
          TextButton(onPressed: () async {
            await _firestoreService.deletePost(postId);
            if (context.mounted) Navigator.pop(ctx);
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف المنشور')));
          }, child: const Text('حذف', style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }

  void _reportPost(BuildContext context, PostModel post) async {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('إبلاغ عن محتوى غير لائق', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'سبب الإبلاغ...',
            hintStyle: TextStyle(color: Colors.white24),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء', style: TextStyle(color: Colors.white38))),
          TextButton(onPressed: () async {
            if (reasonController.text.trim().isEmpty) return;
            await FirebaseFirestore.instance.collection('reports').add({
              'type': 'post',
              'targetId': post.id,
              'targetName': post.authorName,
              'reason': reasonController.text.trim(),
              'reporterId': widget.currentUid,
              'reporterName': 'User', // Could be fetched
              'createdAt': FieldValue.serverTimestamp(),
              'status': 'new',
            });
            if (context.mounted) Navigator.pop(ctx);
            if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال البلاغ للإدارة')));
          }, child: const Text('إرسال', style: TextStyle(color: AppTheme.royalGold))),
        ],
      ),
    );
  }
}
