import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../services/localization_service.dart';
import '../../app_theme.dart';
import '../../theme/design_tokens.dart';
import '../../theme/reusable_widgets.dart';
import '../voice_room_page.dart';
import '../profile/profile_page.dart';
import '../../widgets/feature_lock_wrapper.dart';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../services/ad_manager.dart';

class VoiceRoomsPage extends StatefulWidget {
  const VoiceRoomsPage({super.key});

  @override
  State<VoiceRoomsPage> createState() => _VoiceRoomsPageState();
}

class _VoiceRoomsPageState extends State<VoiceRoomsPage>
    with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  int _activeTabIndex = 0;
  String _activeFilter = "New";
  String _searchQuery = "";
  bool _isSearching = false;
  late AnimationController _pulseController;
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _pulseController =
    AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _searchController.addListener(() {
      setState(
              () => _searchQuery = _searchController.text.trim().toLowerCase());
    });
    _loadBannerAd();
  }

  void _loadBannerAd() {
    _bannerAd = AdManager().getBannerAd(
      size: AdSize.banner,
      onAdLoaded: () {
        setState(() {
          _isAdLoaded = true;
        });
      },
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchController.dispose();
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<String?> _uploadRoomImage(File imageFile) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('room_covers/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  void _createNewRoom(Translations trans) async {
    final user = _authService.currentUser;
    if (user == null) return;

    // التحقق من قفل إنشاء الغرف
    final systemDoc = await FirebaseFirestore.instance.collection('system_settings').doc('global').get();
    if (systemDoc.exists) {
      final data = systemDoc.data()!;
      if (data['isCreateRoomLocked'] == true) {
        // التحقق مما إذا كان مديراً
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final userData = userDoc.data() ?? {};
        final String role = userData['role'] ?? 'user';
        final bool isAdmin = userData['isAdmin'] ?? false;
        if (!isAdmin && !['admin', 'owner', 'developer', 'staff'].contains(role)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('عذراً، ميزة إنشاء الغرف قيد التطوير حالياً 👑'),
              backgroundColor: Colors.orange,
            ));
          }
          return;
        }
      }
    }

    final bool isEn = trans.locale.languageCode == 'en';
    File? selectedImage;
    final nameController = TextEditingController();

    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: GlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                HeadingText(isEn ? "Found Royal Room" : "تأسيس غرفة ملكية",
                    color: DesignTokens.primaryGold),
                const SizedBox(height: DesignTokens.spacingSm),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: DesignTokens.spacingMd,
                      vertical: DesignTokens.spacingXs),
                  decoration: BoxDecoration(
                    color: DesignTokens.primaryGold.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(DesignTokens.borderRadiusMd),
                    border: Border.all(
                        color: DesignTokens.primaryGold.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.diamond,
                          color: DesignTokens.primarySapphireLight, size: 16),
                      const SizedBox(width: DesignTokens.spacingXs),
                      BodyText(
                        isEn ? "Cost: 10,000 Gems" : "التكلفة: 10,000 جوهرة",
                        fontSize: DesignTokens.fontSizeSm,
                        fontWeight: DesignTokens.fontWeightBold,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingLg),
                GestureDetector(
                  onTap: () async {
                    final XFile? image =
                        await _picker.pickImage(source: ImageSource.gallery);
                    if (image != null) {
                      setDialogState(() => selectedImage = File(image.path));
                    }
                  },
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: DesignTokens.neutralWhite.withValues(alpha: 0.05),
                      borderRadius:
                          BorderRadius.circular(DesignTokens.borderRadiusXl),
                      border: Border.all(
                          color: DesignTokens.primaryGold
                              .withValues(alpha: 0.2)),
                      image: selectedImage != null
                          ? DecorationImage(
                              image: FileImage(selectedImage!),
                              fit: BoxFit.cover)
                          : null,
                    ),
                    child: selectedImage == null
                        ? const Icon(Icons.add_photo_alternate_outlined,
                            color: DesignTokens.primaryGold, size: 40)
                        : null,
                  ),
                ),
                const SizedBox(height: DesignTokens.spacingLg),
                RoyalTextField(
                  controller: nameController,
                  hintText: isEn ? "Room Name" : "اسم الغرفة",
                  prefixIcon: Icons.stars_rounded,
                ),
                const SizedBox(height: DesignTokens.spacingXl),
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                        label: trans.get('logout').contains('خروج')
                            ? 'إلغاء'
                            : 'Cancel',
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: DesignTokens.spacingMd),
                    Expanded(
                      child: RoyalButton(
                        label: trans.get('save'),
                        onPressed: () => Navigator.pop(context, true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!context.mounted) return;

    if (confirmed == true && nameController.text.isNotEmpty) {
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
              child: RoyalLoadingIndicator(message: "Creating room...")));

      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final userData = userDoc.data() ?? {};
        final int currentGems = (userData['gems'] ?? 0).toInt();
        const int roomCost = 10000;

        if (currentGems < roomCost) {
          if (mounted) {
            Navigator.pop(context); // Close loading
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(isEn
                    ? 'Insufficient gems. You need 10,000 gems.'
                    : 'رصيد الجواهر غير كافٍ. تحتاج إلى 10,000 جوهرة.'),
                backgroundColor: DesignTokens.semanticError));
          }
          return;
        }

        // خصم الجواهر
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'gems': FieldValue.increment(-roomCost)});

        String? imageUrl;
        if (selectedImage != null) {
          imageUrl = await _uploadRoomImage(selectedImage!);
        }

        String roomId = await _firestoreService.createRoom(
            ownerId: user.uid,
            roomName: nameController.text.trim(),
            roomImage: imageUrl);

        if (mounted) {
          Navigator.pop(context); // Close loading
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => VoiceRoomPage(
                        roomId: roomId,
                        roomName: nameController.text.trim(),
                        roomImage: imageUrl,
                        ownerId: user.uid,
                      )));
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(isEn ? 'An error occurred: $e' : 'حدث خطأ: $e'),
              backgroundColor: DesignTokens.semanticError));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final trans = Translations.of(context);
    final isEn = trans.locale.languageCode == 'en';

    return Directionality(
      textDirection: isEn ? TextDirection.ltr : TextDirection.rtl,
      child: FeatureLockWrapper(
        lockField: 'isRoomsLocked',
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        bottomNavigationBar: _isAdLoaded && _bannerAd != null
            ? Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                height: _bannerAd!.size.height.toDouble(),
                width: _bannerAd!.size.width.toDouble(),
                child: AdWidget(
                  key: ObjectKey(_bannerAd),
                  ad: _bannerAd!,
                ),
              )
            : null,
        floatingActionButton:
        (_activeTabIndex == 2) ? _buildAnimatedCreateButton(trans) : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        body: AppTheme.background(
          child: SafeArea(
            child: Column(
              children: [
                _buildTopBar(trans),
                if (_isSearching) _buildSearchBar() else _buildTopTabs(trans),
                _buildFilterBar(trans),
                Expanded(child: _buildRoomsList()),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildTopBar(Translations trans) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
              icon: Icon(_isSearching ? Icons.search_off : Icons.search,
                  color: DesignTokens.neutralWhite.withValues(alpha: 0.7)),
              onPressed: () => setState(() => _isSearching = !_isSearching)),
          HeadingText(trans.get('rooms'), fontSize: DesignTokens.fontSizeXl),
          _buildProfileBadge(),
        ],
      ),
    );
  }

  Widget _buildTopTabs(Translations trans) {
    final tabs = trans.locale.languageCode == 'ar'
        ? ["اكتشاف", "شائعة", "غرفتي"]
        : ["Discover", "Popular", "My Room"];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: tabs
            .asMap()
            .entries
            .map((entry) => _buildTabItem(entry.value, entry.key))
            .toList(),
      ),
    );
  }

  Widget _buildTabItem(String title, int index) {
    bool isSelected = _activeTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() {
        _activeTabIndex = index;
        // عند تغيير التبويب العلوي، قد نرغب في إعادة الفلتر الافتراضي
        if (index == 1) _activeFilter = "Popular";
        if (index == 2) _activeFilter = "My";
      }),
      child: AnimatedContainer(
        duration: DesignTokens.durationBase,
        margin: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingSm),
        padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingXl, vertical: DesignTokens.spacingSm),
        decoration: BoxDecoration(
          color: isSelected
              ? DesignTokens.primaryGold
              : DesignTokens.neutralWhite.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusFull),
        ),
        child: Text(title,
            style: TextStyle(
                color: isSelected
                    ? DesignTokens.neutralBlack
                    : DesignTokens.neutralWhite.withValues(alpha: 0.54),
                fontWeight: DesignTokens.fontWeightBold,
                fontSize: DesignTokens.fontSizeSm)),
      ),
    );
  }

  Widget _buildFilterBar(Translations trans) {
    final filters = trans.locale.languageCode == 'ar'
        ? ["حديثاً", "تم الانضمام", "تم المتابعة", "الأصدقاء"]
        : ["New", "Joined", "Following", "Friends"];

    return Container(
      height: 40,
      margin: const EdgeInsets.only(top: 10, bottom: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: filters.map<Widget>((f) => _filterChip(f)).toList(),
      ),
    );
  }

  Widget _filterChip(String label) {
    bool isSelected = _activeFilter == label;
    return GestureDetector(
      onTap: () => setState(() {
        _activeFilter = label;
        _activeTabIndex =
            0; // العودة لتبويب "اكتشاف" عند اختيار فلتر فرعي لضمان المنطق
      }),
      child: Container(
        margin: const EdgeInsets.only(right: DesignTokens.spacingSm),
        padding: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingLg),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(
              color: isSelected
                  ? DesignTokens.primaryGold.withValues(alpha: 0.5)
                  : DesignTokens.neutralWhite.withValues(alpha: 0.1)),
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusLg),
          color: isSelected
              ? DesignTokens.primaryGold.withValues(alpha: 0.05)
              : Colors.transparent,
        ),
        child: Text(label,
            style: TextStyle(
                color: isSelected
                    ? DesignTokens.primaryGold
                    : DesignTokens.neutralWhite.withValues(alpha: 0.38),
                fontSize: 11)),
      ),
    );
  }

  Widget _buildRoomsList() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Center(
          child:
          Text("يرجى تسجيل الدخول", style: TextStyle(color: Colors.white)));
    }

    return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .snapshots(),
        builder: (context, userSnap) {
          final userData = userSnap.data?.data() as Map<String, dynamic>? ?? {};
          final List following = List.from(userData['following'] ?? []);
          final List friends = List.from(userData['friends'] ?? []);

          return StreamBuilder<QuerySnapshot>(
            stream: _getFilteredQuery(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: BodyText("خطأ في تحميل البيانات: ${snapshot.error}",
                      color: DesignTokens.semanticError,
                      fontSize: DesignTokens.fontSizeXs),
                );
              }
              if (!snapshot.hasData) {
                return const RoyalShimmerGrid(
                  itemCount: 6,
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                );
              }

              var rooms = snapshot.data!.docs
                  .map((doc) =>
              {...doc.data() as Map<String, dynamic>, 'id': doc.id})
                  .toList();

              // ترتيب يدوي لتبويب "غرفتي" لأننا أزلنا orderBy من الاستعلام لتجنب خطأ الـ Index
              if (_activeTabIndex == 2) {
                rooms.sort((a, b) {
                  final aTime = a['createdAt'] as Timestamp?;
                  final bTime = b['createdAt'] as Timestamp?;
                  if (aTime == null || bTime == null) return 0;
                  return bTime.compareTo(aTime);
                });
              }

              // تطبيق الفلاتر التي تتطلب معالجة جانب العميل (بسبب قيود Firestore في الاستعلامات المركبة)
              if (_activeFilter == "تم المتابعة" ||
                  _activeFilter == "Following") {
                rooms = rooms
                    .where((r) => following.contains(r['ownerId']))
                    .toList();
              } else if (_activeFilter == "الأصدقاء" ||
                  _activeFilter == "Friends") {
                rooms =
                    rooms.where((r) => friends.contains(r['ownerId'])).toList();
              } else if (_activeFilter == "تم الانضمام" ||
                  _activeFilter == "Joined") {
                // عرض الغرف التي زارها المستخدم (يمكن تحسينها بسجل دخول الغرف)
                rooms = rooms
                    .where((r) => r['ownerId'] != currentUser.uid)
                    .toList();
              }

              if (_searchQuery.isNotEmpty) {
                rooms = rooms
                    .where((r) => (r['name'] ?? '')
                    .toString()
                    .toLowerCase()
                    .contains(_searchQuery))
                    .toList();
              }

              if (rooms.isEmpty) {
                return const EmptyStateWidget(
                  icon: Icons.meeting_room_outlined,
                  title: "لا توجد غرف متاحة حالياً",
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(15),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 15,
                  crossAxisSpacing: 15,
                  childAspectRatio: 0.85,
                ),
                itemCount: rooms.length,
                itemBuilder: (context, index) => _buildRoomCard(rooms[index]),
              );
            },
          );
        });
  }

  Stream<QuerySnapshot> _getFilteredQuery() {
    CollectionReference roomsRef =
    FirebaseFirestore.instance.collection('rooms');
    final currentUser = FirebaseAuth.instance.currentUser;

    // تبويب "غرفتي"
    if (_activeTabIndex == 2) {
      // إزالة orderBy لتجنب الحاجة إلى Index فوري، وسنقوم بالترتيب برمجياً في Dart
      return roomsRef
          .where('ownerId', isEqualTo: currentUser?.uid)
          .snapshots();
    }

    // تبويب "شائعة"
    if (_activeTabIndex == 1) {
      return roomsRef
          .orderBy('membersCount', descending: true)
          .limit(50)
          .snapshots();
    }

    // الفلاتر في تبويب "اكتشاف"
    if (_activeFilter == "حديثاً" || _activeFilter == "New") {
      return roomsRef
          .orderBy('createdAt', descending: true)
          .limit(50)
          .snapshots();
    }

    // الافتراضي
    return roomsRef
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  ImageProvider _getRoomImageProvider(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) {
      return const AssetImage('assets/images/default_room.png');
    }
    try {
      final uri = Uri.parse(imagePath);
      if (uri.host.isEmpty) {
        return const AssetImage('assets/images/default_room.png');
      }
      return NetworkImage(imagePath);
    } catch (e) {
      return const AssetImage('assets/images/default_room.png');
    }
  }

  Widget _buildRoomCard(Map<String, dynamic> room) {
    final String? displayImage = room['roomImage'] ?? room['image'];

    return GlassCard(
      padding: EdgeInsets.zero,
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => VoiceRoomPage(
                    roomId: room['id'],
                    roomName: room['name'],
                    roomImage: displayImage,
                    ownerId: room['ownerId'],
                  ))),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(DesignTokens.borderRadiusXl2)),
                    image: DecorationImage(
                      image: _getRoomImageProvider(displayImage),
                      fit: BoxFit.cover,
                      onError: (error, stackTrace) {},
                    ),
                  ),
                  width: double.infinity,
                ),
                Positioned(
                  top: DesignTokens.spacingSm,
                  left: DesignTokens.spacingSm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacingSm, vertical: 2),
                    decoration: BoxDecoration(
                        color: DesignTokens.neutralBlack.withValues(alpha: 0.54),
                        borderRadius: BorderRadius.circular(
                            DesignTokens.borderRadiusMd)),
                    child: Row(children: [
                      const Icon(Icons.people,
                          color: DesignTokens.primaryGold, size: 10),
                      const SizedBox(width: 4),
                      Text("${room['membersCount'] ?? 0}",
                          style: const TextStyle(
                              color: DesignTokens.neutralWhite, fontSize: 9)),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(DesignTokens.spacingSm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BodyText(room['name'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    fontSize: DesignTokens.fontSizeSm,
                    fontWeight: DesignTokens.fontWeightBold),
                const SizedBox(height: 4),
                const Row(children: [
                  Icon(Icons.circle,
                      color: DesignTokens.primaryEmerald, size: 8),
                  SizedBox(width: 5),
                  CaptionText("Active Now", fontSize: 9)
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: RoyalTextField(
        controller: _searchController,
        hintText: "Search rooms...",
        prefixIcon: Icons.search,
      ),
    );
  }

  Widget _buildAnimatedCreateButton(Translations trans) {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 1.05).animate(CurvedAnimation(
          parent: _pulseController, curve: DesignTokens.curveEaseInOut)),
      child: FloatingActionButton.extended(
        onPressed: () => _createNewRoom(trans),
        backgroundColor: DesignTokens.primaryGold,
        label: Text(
            trans.get('agency_create').contains('إنشاء')
                ? 'إنشاء غرفة ملكية'
                : 'Create Royal Room',
            style: const TextStyle(
                color: DesignTokens.neutralBlack,
                fontWeight: DesignTokens.fontWeightBold)),
        icon: const Icon(Icons.add, color: DesignTokens.neutralBlack),
      ),
    );
  }

  Widget _buildProfileBadge() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const CircleAvatar(
                radius: 15, backgroundColor: Colors.white10);
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final String? profilePic = userData['profilePic'];

          return GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfilePage())),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: DesignTokens.primaryGold, width: 1)),
              child: CircleAvatar(
                radius: 15,
                backgroundColor: DesignTokens.neutralWhite.withValues(alpha: 0.1),
                backgroundImage: (profilePic != null && profilePic.isNotEmpty)
                    ? NetworkImage(profilePic)
                    : null,
                child: (profilePic == null || profilePic.isEmpty)
                    ? Icon(Icons.person,
                        size: 18,
                        color: DesignTokens.neutralWhite.withValues(alpha: 0.24))
                    : null,
              ),
            ),
          );
        });
  }
}
