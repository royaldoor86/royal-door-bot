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
import '../voice_room_page.dart';
import '../profile/profile_page.dart';

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

    File? selectedImage;
    final nameController = TextEditingController();

    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1A0202),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
              side: BorderSide(color: AppTheme.royalGold.withValues(alpha: 0.3))),
          title: Column(
            children: [
              Text(trans.get('agency_create'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppTheme.royalGold, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.diamond, color: Colors.cyanAccent, size: 16),
                    SizedBox(width: 4),
                    Text("التكلفة: 10,000 جوهرة",
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppTheme.royalGold.withValues(alpha: 0.2)),
                      image: selectedImage != null
                          ? DecorationImage(
                          image: FileImage(selectedImage!),
                          fit: BoxFit.cover)
                          : null,
                    ),
                    child: selectedImage == null
                        ? const Icon(Icons.add_photo_alternate_outlined,
                        color: AppTheme.royalGold, size: 40)
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Room Name",
                    hintStyle: const TextStyle(color: Colors.white24),
                    prefixIcon: const Icon(Icons.stars_rounded,
                        color: AppTheme.royalGold),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                    trans.get('logout').contains('خروج') ? 'إلغاء' : 'Cancel',
                    style: const TextStyle(color: Colors.white24))),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.royalGold,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15))),
              child: Text(trans.get('save'),
                  style: const TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && nameController.text.isNotEmpty) {
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
              child: CircularProgressIndicator(color: AppTheme.royalGold)));

      try {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final userData = userDoc.data() ?? {};
        final int currentGems = userData['harvestWallet'] ?? 0;
        const int roomCost = 25000;

        if (currentGems < roomCost) {
          if (mounted) {
            Navigator.pop(context); // Close loading
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('رصيد الجواهر غير كافٍ. تحتاج إلى 10,000 جوهرة.'),
                backgroundColor: Colors.redAccent));
          }
          return;
        }

        // خصم الجواهر
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
          'harvestWallet': FieldValue.increment(-roomCost)
        });

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
              content: Text('حدث خطأ: $e'),
              backgroundColor: Colors.redAccent));
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
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        bottomNavigationBar: SizedBox(
          height: 50,
          child: AdWidget(ad: AdManager().getBannerAd()),
        ),
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
                  color: Colors.white70),
              onPressed: () => setState(() => _isSearching = !_isSearching)),
          Text(trans.get('rooms'),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
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
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color:
          isSelected ? AppTheme.royalGold : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(title,
            style: TextStyle(
                color: isSelected ? Colors.black : Colors.white54,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
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
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(
              color: isSelected
                  ? AppTheme.royalGold.withValues(alpha: 0.5)
                  : Colors.white10),
          borderRadius: BorderRadius.circular(15),
          color: isSelected
              ? AppTheme.royalGold.withValues(alpha: 0.05)
              : Colors.transparent,
        ),
        child: Text(label,
            style: TextStyle(
                color: isSelected ? AppTheme.royalGold : Colors.white38,
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
              if (!snapshot.hasData) {
                return const Center(
                    child:
                    CircularProgressIndicator(color: AppTheme.royalGold));
              }

              var rooms = snapshot.data!.docs
                  .map((doc) =>
              {...doc.data() as Map<String, dynamic>, 'id': doc.id})
                  .toList();

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
                return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.meeting_room_outlined,
                            size: 64, color: Colors.white.withValues(alpha: 0.1)),
                        const SizedBox(height: 16),
                        Text("لا توجد غرف متاحة حالياً",
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.3))),
                      ],
                    ));
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
      return roomsRef
          .where('ownerId', isEqualTo: currentUser?.uid)
          .orderBy('createdAt', descending: true)
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
    if (imagePath.startsWith('http') || imagePath.startsWith('https')) {
      return NetworkImage(imagePath);
    } else {
      return AssetImage(imagePath);
    }
  }

  Widget _buildRoomCard(Map<String, dynamic> room) {
    final String? displayImage = room['roomImage'] ?? room['image'];

    return GestureDetector(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => VoiceRoomPage(
                roomId: room['id'],
                roomName: room['name'],
                roomImage: displayImage,
                ownerId: room['ownerId'],
              ))),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(20)),
                      image: DecorationImage(
                        image: _getRoomImageProvider(displayImage),
                        fit: BoxFit.cover,
                        onError: (error, stackTrace) {
                          // يمكن إضافة معالجة للخطأ هنا إذا لزم الأمر
                        },
                      ),
                    ),
                    width: double.infinity,
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8)),
                      child: Row(children: [
                        const Icon(Icons.people,
                            color: AppTheme.royalGold, size: 10),
                        const SizedBox(width: 4),
                        Text("${room['membersCount'] ?? 0}",
                            style: const TextStyle(
                                color: Colors.white, fontSize: 9)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(room['name'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  const SizedBox(height: 4),
                  const Row(children: [
                    Icon(Icons.circle, color: Colors.green, size: 8),
                    SizedBox(width: 5),
                    Text("Active Now",
                        style: TextStyle(color: Colors.white24, fontSize: 9))
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: "Search rooms...",
          hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: AppTheme.royalGold),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildAnimatedCreateButton(Translations trans) {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 1.05).animate(
          CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)),
      child: FloatingActionButton.extended(
        onPressed: () => _createNewRoom(trans),
        backgroundColor: AppTheme.royalGold,
        label: Text(
            trans.get('agency_create').contains('إنشاء')
                ? 'إنشاء غرفة ملكية'
                : 'Create Royal Room',
            style: const TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold)),
        icon: const Icon(Icons.add, color: Colors.black),
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
                  border: Border.all(color: AppTheme.royalGold, width: 1)),
              child: CircleAvatar(
                radius: 15,
                backgroundColor: Colors.white10,
                backgroundImage: (profilePic != null && profilePic.isNotEmpty)
                    ? NetworkImage(profilePic)
                    : null,
                child: (profilePic == null || profilePic.isEmpty)
                    ? const Icon(Icons.person, size: 18, color: Colors.white24)
                    : null,
              ),
            ),
          );
        });
  }
}
