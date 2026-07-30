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
import '../../services/room_navigation_service.dart';

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
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchController.dispose();
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
    final systemDoc = await FirebaseFirestore.instance
        .collection('system_settings')
        .doc('global')
        .get();
    if (systemDoc.exists) {
      final data = systemDoc.data()!;
      if (data['isCreateRoomLocked'] == true) {
        // التحقق مما إذا كان مديراً
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final userData = userDoc.data() ?? {};
        final String role = userData['role'] ?? 'user';
        final bool isAdmin = userData['isAdmin'] ?? false;
        if (!isAdmin &&
            !['admin', 'owner', 'developer', 'staff'].contains(role)) {
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
                          color:
                              DesignTokens.primaryGold.withValues(alpha: 0.2)),
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
          floatingActionButton:
              (_activeTabIndex == 3) ? _buildAnimatedCreateButton(trans) : null,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
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
        ? ["اكتشاف", "شائعة", "الأصدقاء", "غرفتي"]
        : ["Discover", "Popular", "Friends", "My Room"];

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
        if (index == 2) _activeFilter = "Friends";
        if (index == 3) _activeFilter = "My";
      }),
      child: AnimatedContainer(
        duration: DesignTokens.durationBase,
        margin: const EdgeInsets.symmetric(horizontal: DesignTokens.spacingSm),
        padding: const EdgeInsets.symmetric(
            horizontal: DesignTokens.spacingXl,
            vertical: DesignTokens.spacingSm),
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

          final visitedRoomIds =
              FirestoreService.normalizeVisitedRoomIds(userData);

          return StreamBuilder<QuerySnapshot>(
            stream: _getFilteredQuery(
              following: following,
              friends: friends,
              visitedRoomIds: visitedRoomIds,
            ),
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

              // تحقق من انتهاء صلاحية التثبيت (فلترة برمجية إضافية لضمان الدقة)
              if (_activeTabIndex == 1) {
                final now = DateTime.now();
                for (var room in rooms) {
                  if (room['isPinned'] == true) {
                    final expiry = room['pinExpiry'] as Timestamp?;
                    if (expiry != null && expiry.toDate().isBefore(now)) {
                      // تحديث قاعدة البيانات لإزالة التثبيت المنتهي (Async)
                      FirebaseFirestore.instance
                          .collection('rooms')
                          .doc(room['id'])
                          .update({'isPinned': false});
                      room['isPinned'] = false;
                    }
                  }
                }
                // إعادة الترتيب بعد التحقق من الصلاحية
                // نعرض الغرف المثبتة أولاً، ثم نرتب المثبتة بحسب تاريخ انتهاء التثبيت (الأطول زمنياً أولاً)،
                // ثم بحسب عدد الأعضاء كعامل ثانوي. الغرف غير المثبتة تُرتب بحسب عدد الأعضاء.
                rooms.sort((a, b) {
                  bool aPinned = a['isPinned'] ?? false;
                  bool bPinned = b['isPinned'] ?? false;
                  if (aPinned && !bPinned) return -1; // a قبل b
                  if (!aPinned && bPinned) return 1; // b قبل a

                  if (aPinned && bPinned) {
                    final aExpiry = (a['pinExpiry'] as Timestamp?)?.toDate();
                    final bExpiry = (b['pinExpiry'] as Timestamp?)?.toDate();
                    if (aExpiry != null && bExpiry != null) {
                      // الغرفة التي لديها صلاحية أطول تظهر أولاً
                      final cmp = bExpiry.compareTo(aExpiry);
                      if (cmp != 0) return cmp;
                    } else if (aExpiry != null) {
                      return -1;
                    } else if (bExpiry != null) {
                      return 1;
                    }
                  }

                  int aMembers = a['membersCount'] ?? 0;
                  int bMembers = b['membersCount'] ?? 0;
                  return bMembers.compareTo(aMembers);
                });
              }

              // ترتيب يدوي لتبويب "غرفتي" لأننا أزلنا orderBy من الاستعلام لتجنب خطأ الـ Index
              if (_activeTabIndex == 3) {
                rooms.sort((a, b) {
                  final aTime = a['createdAt'] as Timestamp?;
                  final bTime = b['createdAt'] as Timestamp?;
                  if (aTime == null || bTime == null) return 0;
                  return bTime.compareTo(aTime);
                });
              }

              // تطبيق الفلاتر التي تتطلب معالجة جانب العميل (بسبب قيود Firestore في الاستعلامات المركبة)
              if (_activeFilter == "تم المتابعة" ||
                  _activeFilter == "Following" ||
                  _activeFilter == "تم المتابعه") {
                rooms = rooms
                    .where((r) => following.contains(r['ownerId']))
                    .toList();
              } else if (_activeFilter == "الأصدقاء" ||
                  _activeFilter == "Friends" ||
                  _activeFilter == "الاصدقاء") {
                rooms =
                    rooms.where((r) => friends.contains(r['ownerId'])).toList();
              } else if (_activeFilter == "تم الانضمام" ||
                  _activeFilter == "Joined") {
                rooms = rooms
                    .where((r) => visitedRoomIds.contains(r['id'].toString()))
                    .toList();
              }

              if (_searchQuery.isNotEmpty) {
                rooms = rooms.where((r) {
                  final name = (r['name'] ?? '').toString().toLowerCase();
                  final shortId = (r['shortId'] ?? '').toString().toLowerCase();
                  final royalId = (r['royalId'] ?? '').toString().toLowerCase();
                  final fullId = (r['id'] ?? '').toString().toLowerCase();

                  return name.contains(_searchQuery) ||
                      shortId.contains(_searchQuery) ||
                      royalId.contains(_searchQuery) ||
                      fullId.contains(_searchQuery);
                }).toList();
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

  Stream<QuerySnapshot> _getFilteredQuery({
    List<dynamic>? following,
    List<dynamic>? friends,
    List<String>? visitedRoomIds,
  }) {
    CollectionReference roomsRef =
        FirebaseFirestore.instance.collection('rooms');
    final currentUser = FirebaseAuth.instance.currentUser;

    // تبويب "الأصدقاء"
    if (_activeTabIndex == 2) {
      if (friends == null || friends.isEmpty) {
        return roomsRef.where('ownerId', isEqualTo: '___NONE___').snapshots();
      }
      return roomsRef
          .where('ownerId', whereIn: friends.take(30).toList())
          .snapshots();
    }

    // تبويب "غرفتي"
    if (_activeTabIndex == 3) {
      return roomsRef.where('ownerId', isEqualTo: currentUser?.uid).snapshots();
    }

    // تبويب "شائعة" (يدعم التثبيت)
    if (_activeTabIndex == 1) {
      // جلب الغرف المثبتة أولاً برمجياً لتجنب مشاكل الـ Index المركب
      return roomsRef
          .orderBy('isPinned', descending: true)
          .limit(50)
          .snapshots();
    }

    // الفلاتر في تبويب "اكتشاف"
    if (_activeFilter == "تم المتابعة" ||
        _activeFilter == "Following" ||
        _activeFilter == "تم المتابعه") {
      if (following == null || following.isEmpty) {
        return roomsRef.where('ownerId', isEqualTo: '___NONE___').snapshots();
      }
      return roomsRef
          .where('ownerId', whereIn: following.take(30).toList())
          .snapshots();
    }

    if (_activeFilter == "الأصدقاء" ||
        _activeFilter == "Friends" ||
        _activeFilter == "الاصدقاء") {
      if (friends == null || friends.isEmpty) {
        return roomsRef.where('ownerId', isEqualTo: '___NONE___').snapshots();
      }
      return roomsRef
          .where('ownerId', whereIn: friends.take(30).toList())
          .snapshots();
    }

    if (_activeFilter == "تم الانضمام" || _activeFilter == "Joined") {
      if (visitedRoomIds == null || visitedRoomIds.isEmpty) {
        return roomsRef
            .where(FieldPath.documentId, isEqualTo: '___NONE___')
            .snapshots();
      }
      return roomsRef
          .where(FieldPath.documentId,
              whereIn: visitedRoomIds.take(30).toList())
          .snapshots();
    }

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

  void _joinRoom(Map<String, dynamic> room) {
    final roomId = room['id']?.toString();
    if (roomId != null && roomId.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser?.uid)
          .set({
        'visitedRooms': FieldValue.arrayUnion([roomId]),
        'lastRoomVisitAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    RoomNavigationService.joinRoom(context, room);
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
    final bool isLocked =
        room['password'] != null && room['password'].toString().isNotEmpty;

    return GlassCard(
      padding: EdgeInsets.zero,
      onTap: () => _joinRoom(room),
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
                  child: Row(
                    children: [
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('rooms')
                            .doc(room['id'])
                            .collection('online_users')
                            .snapshots(),
                        builder: (context, snapshot) {
                          int onlineCount = 0;
                          if (snapshot.hasData) {
                            onlineCount = snapshot.data!.docs.length;
                          }
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: DesignTokens.spacingSm,
                                vertical: 2),
                            decoration: BoxDecoration(
                                color: DesignTokens.neutralBlack
                                    .withValues(alpha: 0.54),
                                borderRadius: BorderRadius.circular(
                                    DesignTokens.borderRadiusMd)),
                            child: Row(children: [
                              const Icon(Icons.people,
                                  color: DesignTokens.primaryGold, size: 10),
                              const SizedBox(width: 4),
                              Text("$onlineCount",
                                  style: const TextStyle(
                                      color: DesignTokens.neutralWhite,
                                      fontSize: 9)),
                            ]),
                          );
                        },
                      ),
                      if (isLocked) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(
                                DesignTokens.borderRadiusMd),
                          ),
                          child: const Icon(Icons.lock,
                              color: Colors.amber, size: 10),
                        ),
                      ],
                    ],
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
                backgroundColor:
                    DesignTokens.neutralWhite.withValues(alpha: 0.1),
                backgroundImage: (profilePic != null && profilePic.isNotEmpty)
                    ? NetworkImage(profilePic)
                    : null,
                child: (profilePic == null || profilePic.isEmpty)
                    ? Icon(Icons.person,
                        size: 18,
                        color:
                            DesignTokens.neutralWhite.withValues(alpha: 0.24))
                    : null,
              ),
            ),
          );
        });
  }
}
