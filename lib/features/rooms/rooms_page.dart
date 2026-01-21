import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../app_theme.dart';
import '../voice_room_details_page.dart';

class VoiceRoomsPage extends StatefulWidget {
  const VoiceRoomsPage({super.key});

  @override
  State<VoiceRoomsPage> createState() => _VoiceRoomsPageState();
}

class _VoiceRoomsPageState extends State<VoiceRoomsPage> with SingleTickerProviderStateMixin {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  String _activeTab = "اكتشاف";
  String _activeFilter = "حديثاً";
  String _searchQuery = "";
  bool _isSearching = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
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
      final ref = FirebaseStorage.instance.ref().child('room_covers/${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(imageFile);
      return await ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  void _createNewRoom() async {
    final user = _authService.currentUser;
    if (user == null) return;

    File? selectedImage;
    String roomName = "";

    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.primaryBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25), side: BorderSide(color: AppTheme.royalGold.withValues(alpha: 0.3))),
          title: const Text("تأسيس ديوان ملكي", textAlign: TextAlign.center, style: TextStyle(color: AppTheme.royalGold, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                    if (image != null) setDialogState(() => selectedImage = File(image.path));
                  },
                  child: Container(
                    height: 120, width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.royalGold.withValues(alpha: 0.2)),
                      image: selectedImage != null ? DecorationImage(image: FileImage(selectedImage!), fit: BoxFit.cover) : null,
                    ),
                    child: selectedImage == null ? const Icon(Icons.add_photo_alternate_outlined, color: AppTheme.royalGold, size: 40) : null,
                  ),
                ),
                const SizedBox(height: 20),
                AppTheme.royalInputField(controller: TextEditingController(text: roomName), hint: "اسم الغرفة الملكية", icon: Icons.stars_rounded),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("إلغاء", style: TextStyle(color: Colors.white24))),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.royalGold, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
              child: const Text("إنشاء الآن", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      showDialog(context: context, builder: (context) => const Center(child: CircularProgressIndicator(color: AppTheme.royalGold)));
      String? imageUrl;
      if (selectedImage != null) imageUrl = await _uploadRoomImage(selectedImage!);
      String roomId = await _firestoreService.createRoom(ownerId: user.uid, roomName: roomName, roomImage: imageUrl);
      if (mounted) {
        Navigator.pop(context);
        Navigator.push(context, MaterialPageRoute(builder: (context) => VoiceRoomDetailsPage(roomId: roomId, roomName: roomName, roomImage: imageUrl)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundBlack,
        floatingActionButton: (_activeTab == "غرفتي") ? _buildAnimatedCreateButton() : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        body: AppTheme.background(
          child: SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                if (_isSearching) _buildSearchBar() else _buildTopTabs(),
                _buildFilterBar(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        if (_activeTab == "غرفتي") _buildMyRoomHeader(),
                        _buildRoomsGrid(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: Icon(_isSearching ? Icons.search_off : Icons.search, color: Colors.white70), onPressed: () => setState(() => _isSearching = !_isSearching)),
          const Text("الرومات الملكية", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          _buildProfileBadge(),
        ],
      ),
    );
  }

  Widget _buildTopTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: ["اكتشاف", "شائعة", "غرفتي"].map((tab) => _buildTabItem(tab)).toList(),
      ),
    );
  }

  Widget _buildTabItem(String title) {
    bool isSelected = _activeTab == title;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.royalGold : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(title, style: TextStyle(color: isSelected ? Colors.black : Colors.white54, fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(top: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        reverse: true,
        children: ["الأصدقاء", "تم المتابعة", "تم الانضمام", "حديثاً"].map((f) => _buildFilterChip(f)).toList(),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = _activeFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = label),
      child: Container(
        margin: const EdgeInsets.only(left: 10),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(border: Border.all(color: isSelected ? AppTheme.royalGold.withValues(alpha: 0.5) : Colors.white10), borderRadius: BorderRadius.circular(15)),
        child: Text(label, style: TextStyle(color: isSelected ? AppTheme.royalGold : Colors.white38, fontSize: 11)),
      ),
    );
  }

  Widget _buildRoomsGrid() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firestoreService.streamRooms(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppTheme.royalGold));
        var rooms = snapshot.data!;
        return GridView.builder(
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 15, crossAxisSpacing: 15, childAspectRatio: 0.85),
          itemCount: rooms.length,
          itemBuilder: (context, index) => _buildRoomCard(rooms[index]),
        );
      },
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => VoiceRoomDetailsPage(roomId: room['id'], roomName: room['name'], roomImage: room['image']))),
      child: AppTheme.glassContainer(
        padding: const EdgeInsets.all(0),
        opacity: 0.03,
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                      image: (room['image'] != null && room['image'] != '') ? DecorationImage(image: NetworkImage(room['image']), fit: BoxFit.cover) : null,
                    ),
                    width: double.infinity,
                    child: (room['image'] == null || room['image'] == '') ? const Icon(Icons.meeting_room_outlined, color: Colors.white10, size: 40) : null,
                  ),
                  Positioned(top: 10, left: 10, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)), child: Row(children: [const Icon(Icons.people, color: AppTheme.royalGold, size: 12), const SizedBox(width: 4), Text("${room['membersCount'] ?? 0}", style: const TextStyle(color: Colors.white, fontSize: 10))]))),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(room['name'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Row(children: [const Icon(Icons.circle, color: Colors.green, size: 8), const SizedBox(width: 5), const Text("نشط الآن", style: TextStyle(color: Colors.white24, fontSize: 9))]),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedCreateButton() {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 1.05).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)),
      child: FloatingActionButton.extended(onPressed: _createNewRoom, backgroundColor: AppTheme.royalGold, label: const Text("إنشاء غرفة ملكية", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)), icon: const Icon(Icons.add, color: Colors.black)),
    );
  }

  Widget _buildMyRoomHeader() { return const SizedBox(); }
  Widget _buildSearchBar() { return const SizedBox(); }
  Widget _buildProfileBadge() { return Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppTheme.royalGold, width: 1)), child: const CircleAvatar(radius: 15, backgroundColor: Colors.white10, child: Icon(Icons.person, size: 18, color: Colors.white24))); }
}
