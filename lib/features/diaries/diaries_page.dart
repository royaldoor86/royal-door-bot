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

import '../../theme/design_tokens.dart';
import '../../theme/reusable_widgets.dart';

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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
      body: AppTheme.background(
        child: StreamBuilder<dynamic>(
          stream: _firestoreService.streamUserData(currentUid),
          builder: (ctx, userSnap) {
            if (!userSnap.hasData) {
              return const RoyalLoadingIndicator();
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
                    backgroundColor:
                        const Color(0xFF121212).withValues(alpha: 0.9),
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
                      indicatorColor: DesignTokens.primaryGold,
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
          return const RoyalShimmerList(itemCount: 3, itemHeight: 350);
        }
        final posts = snapshot.data ?? [];

        return RefreshIndicator(
          onRefresh: widget.onRefresh,
          color: DesignTokens.primaryGold,
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
            ListTile(
              leading: const Icon(Icons.text_fields, color: Colors.purple),
              title: const Text('قصة نصية فقط',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(ctx);
                _showTextStoryDialog(context);
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

      // إذا كانت صورة، نعرض خيارات الفلتر
      if (!isVideo) {
        await _showFilterOptions(context, File(file.path));
      } else {
        // الفيديو يرفع مباشرة بدون فلتر
        await _uploadStory(file.path, true, null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('حدث خطأ: $e'), backgroundColor: Colors.redAccent));
      }
    }
  }

  Future<void> _showFilterOptions(BuildContext context, File imageFile) async {
    final List<Map<String, dynamic>> filters = [
      {'name': 'بدون فلتر', 'filter': null, 'color': Colors.transparent},
      {
        'name': 'رمادي',
        'filter': const ColorFilter.matrix(<double>[
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0.2126,
          0.7152,
          0.0722,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
        'color': Colors.grey
      },
      {
        'name': 'سبيا',
        'filter': const ColorFilter.matrix(<double>[
          0.393,
          0.769,
          0.189,
          0,
          0,
          0.349,
          0.686,
          0.168,
          0,
          0,
          0.272,
          0.534,
          0.131,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
        'color': Colors.brown
      },
      {
        'name': 'أزرق بارد',
        'filter': const ColorFilter.matrix(<double>[
          0.2,
          0.5,
          0.3,
          0,
          0,
          0.2,
          0.5,
          0.3,
          0,
          0,
          0.2,
          0.5,
          0.3,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
        'color': Colors.blue
      },
      {
        'name': 'دافئ',
        'filter': const ColorFilter.matrix(<double>[
          1.2,
          0.1,
          0.1,
          0,
          0,
          0.1,
          1.1,
          0.1,
          0,
          0,
          0.1,
          0.1,
          1.0,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
        ]),
        'color': Colors.orange
      },
    ];

    int selectedFilterIndex = 0;

    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final bottomPadding = MediaQuery.of(ctx).viewPadding.bottom;
          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding + 20),
            child: Column(
          children: [
            const Text('اختر فلتر للصورة',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: Builder(
                builder: (context) {
                  final filter = filters[selectedFilterIndex]['filter'] as ColorFilter?;
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: filter != null
                        ? ColorFiltered(
                            colorFilter: filter,
                            child: Image.file(imageFile, fit: BoxFit.cover),
                          )
                        : Image.file(imageFile, fit: BoxFit.cover),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: filters.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () =>
                        setModalState(() => selectedFilterIndex = index),
                    child: Container(
                      width: 70,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selectedFilterIndex == index
                              ? AppTheme.royalGold
                              : Colors.white24,
                          width: selectedFilterIndex == index ? 3 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: filters[index]['color'],
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            filters[index]['name'],
                            style: TextStyle(
                              color: selectedFilterIndex == index
                                  ? AppTheme.royalGold
                                  : Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white24,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('إلغاء'),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _uploadStory(imageFile.path, false,
                          filters[selectedFilterIndex]['filter']);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.royalGold,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('نشر'),
                  ),
                ),
              ],
            ),
          ],
        ),
        );
        },
      ),
    );
  }

  Future<void> _uploadStory(
      String filePath, bool isVideo, ColorFilter? filter) async {
    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('جاري رفع القصة... ⏳'),
          backgroundColor: DesignTokens.primaryGold));

      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final userData = await widget.firestoreService.streamUserData(uid).first;

      String? url;
      if (isVideo) {
        url = await StorageService.uploadStoryVideo(File(filePath));
      } else {
        url = await StorageService.uploadStoryImage(File(filePath));
      }

      // تحويل الفلتر إلى سلسلة JSON للحفظ
      String? filterData;
      if (filter != null) {
        // سنحفظ نوع الفلتر فقط للتبسيط
        filterData = 'applied';
      }

      await widget.firestoreService.addStory(
        userId: uid,
        userName: userData.name,
        userPic: userData.profilePic,
        imageUrl: isVideo ? null : url,
        videoUrl: isVideo ? url : null,
        storyFilter: filterData,
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

  Future<void> _showTextStoryDialog(BuildContext context) async {
    final TextEditingController textController = TextEditingController();
    final List<Color> backgroundColors = [
      const Color(0xFF833AB4),
      const Color(0xFFE1306C),
      const Color(0xFFF77737),
      const Color(0xFF25D366),
      const Color(0xFF1DA1F2),
      const Color(0xFF000000),
    ];
    int selectedColorIndex = 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          scrollable: true,
          backgroundColor: const Color(0xFF1A1A1A),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('قصة نصية',
              style: TextStyle(color: Colors.white, fontSize: 18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                maxLines: 5,
                maxLength: 200,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                decoration: const InputDecoration(
                  hintText: 'اكتب نص قصتك هنا...',
                  hintStyle: TextStyle(color: Colors.white24),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              const Text('اختر لون الخلفية',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                children: List.generate(backgroundColors.length, (index) {
                  return GestureDetector(
                    onTap: () =>
                        setDialogState(() => selectedColorIndex = index),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: backgroundColors[index],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selectedColorIndex == index
                              ? Colors.white
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text('إلغاء', style: TextStyle(color: Colors.white38)),
            ),
            TextButton(
              onPressed: () async {
                if (textController.text.trim().isEmpty) return;
                Navigator.pop(ctx);
                await _uploadTextStory(
                  textController.text.trim(),
                  backgroundColors[selectedColorIndex],
                );
              },
              child: const Text('نشر',
                  style: TextStyle(color: AppTheme.royalGold)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadTextStory(String text, Color backgroundColor) async {
    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('جاري نشر القصة... ⏳'),
          backgroundColor: DesignTokens.primaryGold));

      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final userData = await widget.firestoreService.streamUserData(uid).first;

      // إنشاء صورة من النص والخلفية
      // سنقوم بحفظ النص واللون كبيانات في القصة
      await widget.firestoreService.addStory(
        userId: uid,
        userName: userData.name,
        userPic: userData.profilePic,
        imageUrl: null,
        videoUrl: null,
        storyText: text,
        storyBackgroundColor: backgroundColor.toARGB32().toString(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('تم نشر القصة النصية بنجاح! 🎉'),
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
          if (!snapshot.hasData) {
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) => RoyalShimmer(
                child: Container(
                  width: 80,
                  height: 100,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            );
          }
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
