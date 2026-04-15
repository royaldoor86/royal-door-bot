import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../models/post_model.dart';
import '../../../app_theme.dart';
import '../../../services/firestore_service.dart';
import '../../profile/user_details_view_page.dart';
import 'video_widget.dart';
import '../diaries_page.dart'; // for date formatting and downloadMedia helper

class PostCard extends StatefulWidget {
  final PostModel post;
  final String currentUid;
  final bool isFollowing;
  final bool isFriend;
  final bool requestSent;
  final bool requestReceived;
  final Function(String) onUpdate;

  const PostCard({
    super.key,
    required this.post,
    required this.currentUid,
    this.isFollowing = false,
    this.isFriend = false,
    this.requestSent = false,
    this.requestReceived = false,
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AppTheme.glassContainer(
        padding: const EdgeInsets.all(0),
        opacity: 0.03,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: InkWell(
                onTap: () => _navigateToUser(widget.post.authorId),
                borderRadius: BorderRadius.circular(24),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white10,
                  backgroundImage: widget.post.authorPic.isNotEmpty
                      ? CachedNetworkImageProvider(widget.post.authorPic)
                      : null,
                  child: widget.post.authorPic.isEmpty
                      ? const Icon(Icons.person, color: Colors.white24)
                      : null,
                ),
              ),
              title: Text(widget.post.authorName,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
              subtitle: Text(formatPostDate(widget.post.createdAt),
                  style: const TextStyle(color: Colors.white24, fontSize: 10)),
              trailing: IconButton(
                  icon: const Icon(Icons.more_vert,
                      color: Colors.white24, size: 18),
                  onPressed: () => _showPostOptions(context, widget.post)),
            ),
            
            if (widget.currentUid.isNotEmpty && widget.currentUid != widget.post.authorId)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: _buildRelationButtons(),
              ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildExpandableText(widget.post.content),
            ),

            if (widget.post.videoUrl != null && widget.post.videoUrl!.isNotEmpty)
              VideoWidget(videoUrl: widget.post.videoUrl!)
            else if (widget.post.imageUrl != null && widget.post.imageUrl!.isNotEmpty)
              _buildImageSection(context),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _interactionBtn(
                      isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                      isLiked ? Colors.redAccent : Colors.white54,
                      '${widget.post.likes.length}', () {
                    HapticFeedback.lightImpact();
                    _firestoreService.toggleLike(widget.post.id, widget.currentUid);
                  }),
                  const SizedBox(width: 20),
                  _interactionBtn(Icons.chat_bubble_outline_rounded, Colors.white54,
                      '${widget.post.commentCount}', () => openCommentsSheet(context, widget.post)),
                  const SizedBox(width: 16),
                  _interactionBtn(Icons.copy_rounded, Colors.white54, '', () {
                    if (widget.post.content.isNotEmpty) {
                      Clipboard.setData(ClipboardData(text: widget.post.content));
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تم نسخ نص المنشور')));
                    }
                  }),
                  const SizedBox(width: 16),
                  _interactionBtn(Icons.share_rounded, Colors.white54, '', () async {
                    await sharePostWithMedia(context, widget.post);
                  }),
                  const Spacer(),
                  if (widget.post.isVip)
                    const Icon(Icons.workspace_premium,
                        color: AppTheme.royalGold, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelationButtons() {
    return Row(children: [
      ElevatedButton(
        style: ElevatedButton.styleFrom(
            backgroundColor: widget.isFollowing ? Colors.grey[800] : AppTheme.royalGold,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            minimumSize: const Size(90, 32)),
        onPressed: () async {
          await _firestoreService.toggleFollow(widget.currentUid, widget.post.authorId);
          widget.onUpdate(widget.post.id);
        },
        child: Text(widget.isFollowing ? 'متابع' : 'متابعة',
            style: TextStyle(color: widget.isFollowing ? Colors.white70 : Colors.black, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
      const SizedBox(width: 8),
      if (widget.isFriend)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(border: Border.all(color: Colors.white24), borderRadius: BorderRadius.circular(20)),
          child: const Text('صديق', style: TextStyle(color: Colors.white70, fontSize: 12)))
      else if (widget.requestReceived)
        ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                minimumSize: const Size(100, 32)),
            onPressed: () async {
              final requestId = '${widget.post.authorId}_${widget.currentUid}';
              await _firestoreService.acceptFriendRequest(
                  requestId, widget.post.authorId, widget.currentUid);
              widget.onUpdate(widget.post.id);
            },
            child: const Text('قبول الصداقة', style: TextStyle(color: Colors.white, fontSize: 11)))
      else
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: widget.requestSent ? Colors.grey[800] : Colors.white10,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              minimumSize: const Size(100, 32)),
          onPressed: widget.requestSent ? null : () async {
              await _firestoreService.sendFriendRequest(widget.currentUid, widget.post.authorId);
              widget.onUpdate(widget.post.id);
          },
          child: Text(widget.requestSent ? 'تم الإرسال' : 'إضافة صديق',
              style: const TextStyle(color: Colors.white, fontSize: 11)),
        ),
    ]);
  }

  Widget _buildImageSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ImageViewer(
                          imageUrl: widget.post.imageUrl!,
                          postText: widget.post.content))),
              child: CachedNetworkImage(
                imageUrl: widget.post.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (c, u) => Container(
                    height: 200,
                    color: Colors.black12,
                    child: const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.royalGold))),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: _overlayBtn(Icons.download_rounded, () async {
                await downloadMedia(context, widget.post.imageUrl!, isImage: true);
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _overlayBtn(IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8)),
      child: IconButton(icon: Icon(icon, color: Colors.white, size: 20), onPressed: onTap),
    );
  }

  Widget _interactionBtn(IconData icon, Color color, String count, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 6),
        if (count.isNotEmpty)
          Text(count,
              style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold))
      ]),
    );
  }

  Widget _buildExpandableText(String text) {
    bool isLong = text.length > 120;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          maxLines: _isExpanded ? 100 : 3,
          overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
        ),
        if (isLong)
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(_isExpanded ? 'عرض أقل' : 'عرض المزيد...',
                  style: const TextStyle(
                      color: AppTheme.royalGold,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  void _navigateToUser(String uid) async {
    showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));
    try {
      final user = await _firestoreService.streamUserData(uid).first;
      if (mounted) Navigator.pop(context);
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => UserDetailsViewPage(user: user)));
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
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
                ListTile(leading: const Icon(Icons.share, color: Colors.white), title: const Text('مشاركة', style: TextStyle(color: Colors.white)), onTap: () => Navigator.pop(ctx, 'share')),
                if (isOwner) ListTile(leading: const Icon(Icons.edit, color: Colors.white), title: const Text('تعديل', style: TextStyle(color: Colors.white)), onTap: () => Navigator.pop(ctx, 'edit')),
                if (isOwner) ListTile(leading: const Icon(Icons.delete_forever, color: Colors.redAccent), title: const Text('حذف', style: TextStyle(color: Colors.redAccent)), onTap: () => Navigator.pop(ctx, 'delete')),
                const SizedBox(height: 10),
              ]),
            ));
    
    if (res == 'share') await sharePostWithMedia(context, post);
    if (res == 'delete') {
      final confirm = await showDialog<bool>(context: context, builder: (d) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('حذف المنشور', style: TextStyle(color: Colors.redAccent)),
        content: const Text('هل أنت متأكد؟', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('إلغاء')),
          ElevatedButton(onPressed: () => Navigator.pop(d, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('حذف')),
        ],
      ));
      if (confirm == true) await _firestoreService.deletePost(post.id);
    }
  }
}
