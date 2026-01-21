import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/post_model.dart';
import '../../models/story_model.dart';
import '../../app_theme.dart';
import 'create_post_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:video_player/video_player.dart'; // تأكد من وجود المكتبة في pubspec.yaml

class DiariesPage extends StatefulWidget {
  const DiariesPage({super.key});

  @override
  State<DiariesPage> createState() => _DiariesPageState();
}

class _DiariesPageState extends State<DiariesPage> {
  final FirestoreService _firestoreService = FirestoreService();
  final Map<String, bool> _expandedPosts = {}; // لتتبع المنشورات المفتوحة

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundBlack,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('اليوميات الملكية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
          centerTitle: true,
          actions: [
            IconButton(icon: const Icon(Icons.history_edu_rounded, color: AppTheme.royalGold), onPressed: () {}),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePostPage())),
          backgroundColor: AppTheme.royalGold,
          child: const Icon(Icons.add_photo_alternate_rounded, color: Colors.black),
        ),
        body: AppTheme.background(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildStoriesSection()),
              const SliverToBoxAdapter(child: SizedBox(height: 10)),
              StreamBuilder<List<PostModel>>(
                stream: _firestoreService.streamPosts(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppTheme.royalGold)));
                  final posts = snapshot.data!;
                  if (posts.isEmpty) return const SliverFillRemaining(child: Center(child: Text('لا توجد منشورات ملكية بعد ✍️', style: TextStyle(color: Colors.white24))));

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildPostCard(posts[index]),
                      childCount: posts.length,
                    ),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoriesSection() {
    return Container(
      height: 110,
      margin: const EdgeInsets.only(top: 10),
      child: StreamBuilder<List<StoryModel>>(
        stream: _firestoreService.streamStories(),
        builder: (context, snapshot) {
          final stories = snapshot.data ?? [];
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: stories.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) return _buildAddStoryBtn();
              return _buildStoryItem(stories[index - 1]);
            },
          );
        },
      ),
    );
  }

  Widget _buildAddStoryBtn() {
    return Column(
      children: [
        Container(
          width: 65, height: 65,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.royalGold.withValues(alpha: 0.5), width: 2)),
          child: const Icon(Icons.add, color: AppTheme.royalGold, size: 30),
        ),
        const SizedBox(height: 5),
        const Text('قصتي', style: TextStyle(color: Colors.white54, fontSize: 10)),
      ],
    );
  }

  Widget _buildStoryItem(StoryModel story) {
    return GestureDetector(
      onTap: () => _viewStory(story), // فتح الحالة
      child: Column(
        children: [
          Container(
            width: 65, height: 65,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.royalGold, width: 2),
              image: story.imageUrl != null 
                  ? DecorationImage(image: NetworkImage(story.imageUrl!), fit: BoxFit.cover)
                  : null,
            ),
            child: story.imageUrl == null ? const Icon(Icons.videocam, color: AppTheme.royalGold) : null,
          ),
          const SizedBox(height: 5),
          Text(story.userName, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildPostCard(PostModel post) {
    final currentUser = FirebaseAuth.instance.currentUser;
    bool isLiked = post.likes.contains(currentUser?.uid);
    bool isExpanded = _expandedPosts[post.id] ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: AppTheme.glassContainer(
        padding: const EdgeInsets.all(0),
        opacity: 0.03,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white10,
                backgroundImage: post.authorPic.isNotEmpty ? NetworkImage(post.authorPic) : null,
                child: post.authorPic.isEmpty ? const Icon(Icons.person, color: Colors.white24) : null,
              ),
              title: Text(post.authorName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('نشط الآن', style: TextStyle(color: Colors.white24, fontSize: 10)),
              trailing: IconButton(icon: const Icon(Icons.more_vert, color: Colors.white24, size: 18), onPressed: () {}),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _buildExpandableText(post.id, post.content, isExpanded),
            ),
            
            // عرض الميديا المطور (فيديو أو صورة)
            if (post.videoUrl != null && post.videoUrl!.isNotEmpty)
              _VideoWidget(videoUrl: post.videoUrl!)
            else if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.network(post.imageUrl!, width: double.infinity, fit: BoxFit.cover),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _interactionBtn(isLiked ? Icons.favorite : Icons.favorite_border, isLiked ? Colors.redAccent : Colors.white54, '${post.likes.length}', () {
                    if (currentUser != null) _firestoreService.toggleLike(post.id, currentUser.uid);
                  }),
                  const SizedBox(width: 20),
                  _interactionBtn(Icons.chat_bubble_outline, Colors.white54, '${post.commentCount}', () {}),
                  const Spacer(),
                  if (post.isVip) const Icon(Icons.workspace_premium, color: AppTheme.royalGold, size: 18),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableText(String postId, String text, bool isExpanded) {
    bool isLong = text.length > 120;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          maxLines: isExpanded ? 100 : 3,
          overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
        ),
        if (isLong)
          GestureDetector(
            onTap: () => setState(() => _expandedPosts[postId] = !isExpanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(isExpanded ? 'عرض أقل' : 'عرض المزيد...', style: const TextStyle(color: AppTheme.royalGold, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }

  void _viewStory(StoryModel story) {
    // كود فتح واجهة عرض القصة بالكامل (فيديو/صور)
  }

  Widget _interactionBtn(IconData icon, Color color, String count, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(children: [Icon(icon, color: color, size: 20), const SizedBox(width: 6), Text(count, style: const TextStyle(color: Colors.white38, fontSize: 12, fontWeight: FontWeight.bold))]),
    );
  }
}

// ويدجيت مخصص لتشغيل الفيديوهات داخل المنشورات
class _VideoWidget extends StatefulWidget {
  final String videoUrl;
  const _VideoWidget({required this.videoUrl});

  @override
  State<_VideoWidget> createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<_VideoWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() => _isInitialized = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250, width: double.infinity,
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(15)),
      child: _isInitialized
          ? Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(15), child: AspectRatio(aspectRatio: _controller.value.aspectRatio, child: VideoPlayer(_controller))),
                IconButton(
                  icon: Icon(_controller.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill, color: Colors.white70, size: 50),
                  onPressed: () => setState(() => _controller.value.isPlaying ? _controller.pause() : _controller.play()),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator(color: AppTheme.royalGold)),
    );
  }
}
