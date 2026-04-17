import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../services/localization_service.dart';
import '../../models/post_model.dart';
import '../../models/story_model.dart';
import '../../app_theme.dart';
import 'create_post_page.dart';
import 'story_viewer.dart';
import 'widgets/post_card.dart';
import 'widgets/story_card.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../services/ad_manager.dart';

class DiariesPage extends StatefulWidget {
  const DiariesPage({super.key});

  @override
  State<DiariesPage> createState() => _DiariesPageState();
}

class _DiariesPageState extends State<DiariesPage>
    with TickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _onRefresh() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final trans = Translations.of(context);
    final isEn = trans.locale.languageCode == 'en';

    return Scaffold(
      backgroundColor: Colors.black,
      bottomNavigationBar: SizedBox(
        height: 50,
        child: AdWidget(ad: AdManager().getBannerAd()),
      ),
      body: AppTheme.background(
        child: StreamBuilder<dynamic>(
          stream: _firestoreService.streamUserData(currentUid),
          builder: (ctx, userSnap) {
            if (!userSnap.hasData) {
              return const Center(
                  child: CircularProgressIndicator(color: AppTheme.royalGold));
            }
            final me = userSnap.data as dynamic;
            final following =
                (me?.following as List<dynamic>?)?.cast<String>() ?? <String>[];
            final friends =
                (me?.friends as List<dynamic>?)?.cast<String>() ?? <String>[];

            final feedAuthors = {currentUid, ...following, ...friends}.toList();

            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    pinned: true,
                    floating: true,
                    snap: true,
                    backgroundColor: const Color(0xFF121212).withValues(alpha: 0.9),
                    elevation: 0,
                    title: Text(trans.get('diaries'),
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20)),
                    centerTitle: true,
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.add_box_outlined,
                            color: Colors.white, size: 26),
                        onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const CreatePostPage())),
                      )
                    ],
                    bottom: TabBar(
                      controller: _tabController,
                      tabs: [
                        Tab(text: isEn ? 'Feed' : 'آخر الأخبار'),
                        Tab(text: isEn ? 'My Posts' : 'يومياتي'),
                      ],
                      indicatorColor: AppTheme.royalGold,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                      unselectedLabelColor: Colors.white38,
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _PostsListTabView(
                    key: const PageStorageKey('feed_posts'),
                    currentUid: currentUid,
                    authorIds: feedAuthors,
                    onRefresh: _onRefresh,
                    firestoreService: _firestoreService,
                    isFeed: true,
                  ),
                  _PostsListTabView(
                    key: const PageStorageKey('my_posts'),
                    currentUid: currentUid,
                    authorIds: [currentUid],
                    onRefresh: _onRefresh,
                    firestoreService: _firestoreService,
                    isFeed: false,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PostsListTabView extends StatefulWidget {
  final String currentUid;
  final List<String> authorIds;
  final Future<void> Function() onRefresh;
  final FirestoreService firestoreService;
  final bool isFeed;

  const _PostsListTabView({
    super.key,
    required this.currentUid,
    required this.authorIds,
    required this.onRefresh,
    required this.firestoreService,
    required this.isFeed,
  });

  @override
  State<_PostsListTabView> createState() => _PostsListTabViewState();
}

class _PostsListTabViewState extends State<_PostsListTabView>
    with AutomaticKeepAliveClientMixin {
  final ImagePicker _picker = ImagePicker();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder<List<PostModel>>(
      stream: widget.firestoreService.streamPostsFromAuthors(widget.authorIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.royalGold));
        }
        final posts = snapshot.data ?? [];

        return RefreshIndicator(
          onRefresh: widget.onRefresh,
          color: AppTheme.royalGold,
          backgroundColor: const Color(0xFF121212),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            slivers: [
              if (widget.isFeed)
                SliverToBoxAdapter(
                  child: _StoriesSection(
                    firestoreService: widget.firestoreService,
                    onAddStory: () =>
                        _showAddStoryOptions(context, Translations.of(context)),
                  ),
                ),
              if (posts.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_awesome_motion_outlined,
                            size: 60, color: Colors.white10),
                        const SizedBox(height: 16),
                        Text(
                          widget.isFeed
                              ? 'لا توجد منشورات في آخر الأخبار'
                              : 'لم تنشر أي يوميات بعد',
                          style: const TextStyle(
                              color: Colors.white24, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.only(bottom: 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final post = posts[index];
                        return PostCard(
                          post: post,
                          currentUid: widget.currentUid,
                          isFriend: true,
                          isFollowing: true,
                          onUpdate: (_) => setState(() {}),
                        );
                      },
                      childCount: posts.length,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showAddStoryOptions(BuildContext context, Translations trans) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A050E), // Match app theme
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2))),
            const Padding(
                padding: EdgeInsets.all(20),
                child: Text('إضافة قصة جديدة',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold))),
            ListTile(
              leading: const Icon(Icons.image_outlined, color: Colors.green),
              title: const Text('صورة من المعرض',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _handleStoryAction(ImageSource.gallery, false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam_outlined, color: Colors.blue),
              title: const Text('فيديو من المعرض',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _handleStoryAction(ImageSource.gallery, true);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.camera_alt_outlined, color: Colors.orange),
              title: const Text('التقاط بالكاميرا',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _handleStoryAction(ImageSource.camera, false);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _handleStoryAction(ImageSource source, bool isVideo) async {
    try {
      final XFile? file = isVideo
          ? await _picker.pickVideo(source: source)
          : await _picker.pickImage(source: source);
      if (file == null) return;

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('جاري رفع القصة... ⏳'),
          backgroundColor: AppTheme.royalGold));

      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final userData = await widget.firestoreService.streamUserData(uid).first;

      String? url;
      if (isVideo) {
        url = await StorageService.uploadStoryVideo(File(file.path));
      } else {
        url = await StorageService.uploadStoryImage(File(file.path));
      }

      await widget.firestoreService.addStory(
        userId: uid,
        userName: userData.name,
        userPic: userData.profilePic,
        imageUrl: isVideo ? null : url,
        videoUrl: isVideo ? url : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('تم نشر القصة بنجاح! 🎉'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('حدث خطأ: $e'), backgroundColor: Colors.redAccent));
      }
    }
  }
}

class _StoriesSection extends StatelessWidget {
  final FirestoreService firestoreService;
  final VoidCallback onAddStory;

  const _StoriesSection({
    required this.firestoreService,
    required this.onAddStory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: StreamBuilder<List<StoryModel>>(
        stream: firestoreService.streamStories(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox(height: 110);
          final stories = snapshot.data ?? [];
          final Map<String, List<StoryModel>> grouped = {};
          for (final s in stories) {
            grouped.putIfAbsent(s.userId, () => []).add(s);
          }
          final groups = grouped.entries.map((e) => e.value).toList();

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: groups.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return StoryCard(
                  group: const [],
                  isAddButton: true,
                  onTap: onAddStory,
                );
              }
              final group = groups[index - 1];

              int flatStartIndex = 0;
              for (int i = 0; i < index - 1; i++) {
                flatStartIndex += groups[i].length;
              }

              return StoryCard(
                group: group,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StoryViewer(
                      stories: stories,
                      initialIndex: flatStartIndex,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
