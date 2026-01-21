import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firestore_service.dart';
import '../services/family_service.dart';
import '../services/storage_service.dart';
import '../models/user_model.dart';
import '../models/family_model.dart';
import '../app_theme.dart';
import 'create_family_page.dart';
import 'family_chat_page.dart';

class FamilyPage extends StatefulWidget {
  const FamilyPage({super.key});

  @override
  State<FamilyPage> createState() => _FamilyPageState();
}

class _FamilyPageState extends State<FamilyPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final FamilyService _familyService = FamilyService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
    );
  }

  void _showSuccessSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating)
    );
  }

  Future<void> _repairStaleStatus(String uid) async {
    try {
      await _db.collection('users').doc(uid).update({'familyId': FieldValue.delete(), 'familyRole': FieldValue.delete()});
      _showSuccessSnack('تم تحديث حالتك الملكية بنجاح ✅');
    } catch (e) { _showErrorSnack('فشل التحديث'); }
  }

  void _showMoreOptions(FamilyModel family, bool isLeader) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(color: Color(0xFF1A050E), borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _optionTile(Icons.person_add, 'دعوة عضو جديد', Colors.blue, () { Navigator.pop(ctx); _showInviteDialog(family.id); }),
              _optionTile(Icons.campaign, 'تحديث الإعلان', Colors.orange, () { Navigator.pop(ctx); _showAnnouncementDialog(family); }),
              _optionTile(Icons.settings, 'إعدادات المملكة', Colors.grey, () { Navigator.pop(ctx); _showFamilySettings(family, isLeader); }),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionTile(IconData icon, String title, Color color, VoidCallback onTap) => ListTile(leading: Icon(icon, color: color), title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)), onTap: onTap);

  void _showInviteDialog(String familyId) {
    final idController = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(backgroundColor: const Color(0xFF1A050E), title: const Text('دعوة صديق', style: TextStyle(color: Colors.amber)), content: TextField(controller: idController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'أدخل الآيدي الملكي...')), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')), ElevatedButton(onPressed: () async { try { await _familyService.addMemberByShortId(familyId, idController.text.trim()); Navigator.pop(ctx); _showSuccessSnack('تمت الإضافة بنجاح'); } catch (e) { _showErrorSnack(e.toString()); } }, child: const Text('إضافة'))]));
  }

  void _showAnnouncementDialog(FamilyModel family) {
    final sloganController = TextEditingController(text: family.slogan);
    showDialog(context: context, builder: (ctx) => AlertDialog(backgroundColor: const Color(0xFF1A050E), title: const Text('إعلان العائلة', style: TextStyle(color: Colors.amber)), content: TextField(controller: sloganController, maxLines: 2, style: const TextStyle(color: Colors.white)), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')), ElevatedButton(onPressed: () async { await _familyService.updateFamily(familyId: family.id, slogan: sloganController.text.trim()); Navigator.pop(ctx); _showSuccessSnack('تم التحديث'); }, child: const Text('تحديث'))]));
  }

  void _showFamilySettings(FamilyModel family, bool isLeader) {
    final nameController = TextEditingController(text: family.name);
    final descController = TextEditingController(text: family.description);
    File? newLogo;
    bool updating = false;
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (context) => StatefulBuilder(builder: (ctx, setModalState) => Container(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20), decoration: const BoxDecoration(color: Color(0xFF1A050E), borderRadius: BorderRadius.vertical(top: Radius.circular(30))), child: Column(mainAxisSize: MainAxisSize.min, children: [const Text('إعدادات المملكة', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 20), GestureDetector(onTap: () async { final picker = ImagePicker(); final image = await picker.pickImage(source: ImageSource.gallery); if (image != null) setModalState(() => newLogo = File(image.path)); }, child: CircleAvatar(radius: 40, backgroundColor: Colors.white10, backgroundImage: newLogo != null ? FileImage(newLogo!) : (family.logoUrl != '' ? NetworkImage(family.logoUrl) : null) as ImageProvider?)), const SizedBox(height: 20), AppTheme.royalInputField(controller: nameController, hint: 'اسم العائلة', icon: Icons.shield), const SizedBox(height: 30), updating ? const CircularProgressIndicator() : AppTheme.gradientButton(text: 'حفظ التغييرات', onPressed: () async { setModalState(() => updating = true); String? logoUrl; if (newLogo != null) logoUrl = await StorageService.uploadFamilyLogo(family.id, newLogo!); await _familyService.updateFamily(familyId: family.id, name: nameController.text.trim(), description: descController.text.trim(), logoUrl: logoUrl); Navigator.pop(context); _showSuccessSnack('تم التحديث ✅'); }), if (isLeader) TextButton(onPressed: () { Navigator.pop(context); _deleteFamilyConfirm(family.id, family.name); }, child: const Text('تفكيك العائلة', style: TextStyle(color: Colors.redAccent))), const SizedBox(height: 40)]))));
  }

  void _deleteFamilyConfirm(String familyId, String familyName) {
    showDialog(context: context, builder: (ctx) => AlertDialog(backgroundColor: const Color(0xFF2A0000), title: const Text('حذف نهائي'), content: Text('هل أنت متأكد من تفكيك عائلة ($familyName)؟'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')), ElevatedButton(onPressed: () async { Navigator.pop(ctx); setState(() => _isDeleting = true); await _familyService.deleteFamily(familyId); setState(() => _isDeleting = false); _showSuccessSnack('تم التفكيك'); }, child: const Text('حذف'))]));
  }

  @override
  Widget build(BuildContext context) {
    final userAuth = FirebaseAuth.instance.currentUser;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Stack(
        children: [
          StreamBuilder<UserModel>(
            stream: userAuth != null ? _firestoreService.streamUserData(userAuth.uid) : null,
            builder: (context, userSnapshot) {
              final userData = userSnapshot.data;
              if (userData == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
              bool hasFamily = userData.familyId != null && userData.familyId!.isNotEmpty;
              return Scaffold(
                backgroundColor: const Color(0xFF1A050E),
                body: Container(
                  decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3D0B16), Color(0xFF1A050E), Color(0xFF000000)])),
                  child: NestedScrollView(
                    physics: const BouncingScrollPhysics(),
                    headerSliverBuilder: (context, innerBoxIsScrolled) => [
                      _buildSliverAppBar(userData),
                      SliverToBoxAdapter(child: _buildSearchBox()),
                      SliverPersistentHeader(pinned: true, delegate: _SliverAppBarDelegate(TabBar(controller: _tabController, indicatorColor: Colors.amber, labelColor: Colors.amber, unselectedLabelColor: Colors.white38, physics: const BouncingScrollPhysics(), tabs: const [Tab(text: 'أقوى العوائل'), Tab(text: 'عائلتي'), Tab(text: 'البحث')]))),
                    ],
                    body: TabBarView(controller: _tabController, physics: const BouncingScrollPhysics(), children: [_buildTopFamiliesList(hasFamily), _buildMyFamilyView(userData), _buildSearchList(hasFamily)]),
                  ),
                ),
                floatingActionButton: !hasFamily ? FloatingActionButton.extended(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateFamilyPage())), backgroundColor: Colors.redAccent, label: const Text('تأسيس عائلة ملكية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), icon: const Icon(Icons.shield_rounded, color: Colors.white)) : null,
              );
            }
          ),
          if (_isDeleting) Container(color: Colors.black87, child: const Center(child: CircularProgressIndicator(color: Colors.amber))),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(UserModel user) {
    bool canManage = user.familyId != null && (user.familyRole == 'leader' || user.familyRole == 'organizer');
    return SliverAppBar(
      expandedHeight: 80.0, backgroundColor: Colors.transparent, elevation: 0,
      title: const Text('نظام العوائل الملكي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), centerTitle: true,
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
      actions: [
        if (canManage) StreamBuilder<DocumentSnapshot>(
          stream: _db.collection('families').doc(user.familyId).snapshots(),
          builder: (context, snap) {
            if (!snap.hasData || !snap.data!.exists) return const SizedBox();
            final family = FamilyModel.fromFirestore(snap.data! as DocumentSnapshot<Map<String, dynamic>>);
            return IconButton(icon: const Icon(Icons.more_horiz, color: Colors.white, size: 30), onPressed: () => _showMoreOptions(family, user.familyRole == 'leader'));
          }
        ),
      ],
    );
  }

  Widget _buildSearchBox() => Padding(padding: const EdgeInsets.all(20), child: AppTheme.glassContainer(padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 2), opacity: 0.03, child: TextField(controller: _searchController, style: const TextStyle(color: Colors.white), onChanged: (v) => setState(() {}), decoration: const InputDecoration(hintText: 'ابحث عن عائلة...', prefixIcon: Icon(Icons.search, color: Colors.redAccent), border: InputBorder.none))));

  Widget _buildTopFamiliesList(bool hasFam) => StreamBuilder<List<FamilyModel>>(stream: _familyService.getLeaderboard('total'), builder: (context, snapshot) => snapshot.hasData ? ListView.builder(padding: const EdgeInsets.all(20), physics: const BouncingScrollPhysics(), itemCount: snapshot.data!.length, itemBuilder: (context, i) => _familyListItem(snapshot.data![i], i + 1, hasFam)) : const Center(child: CircularProgressIndicator()));

  Widget _buildMyFamilyView(UserModel user) {
    if (user.familyId == null || user.familyId!.isEmpty) return const Center(child: Text('لا تنتمي لعائلة حالياً', style: TextStyle(color: Colors.white24)));
    
    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('families').doc(user.familyId).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        if (!snap.data!.exists) return Center(child: ElevatedButton(onPressed: () => _repairStaleStatus(user.uid), child: const Text('تحديث الحالة')));
        final family = FamilyModel.fromFirestore(snap.data! as DocumentSnapshot<Map<String, dynamic>>);
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(), padding: const EdgeInsets.all(20),
          child: Column(children: [
            _buildFamilyHeaderCard(family, user),
            const SizedBox(height: 25),
            _buildFamilyStatsRow(family),
            const SizedBox(height: 30),
            _buildQuickServices(family),
            const SizedBox(height: 30),
            _buildSectionTitle('أعضاء متصلون الآن 🟢'),
            _buildMembersList(family.id),
          ]),
        );
      }
    );
  }

  Widget _buildQuickServices(FamilyModel family) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _serviceBox('دردشة العائلة', Icons.chat_bubble_outline, Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => FamilyChatPage(familyId: family.id)))),
        _serviceBox('غرفة العائلة', Icons.mic_none_rounded, Colors.purple, () {}),
        _serviceBox('مهام العائلة', Icons.assignment_outlined, Colors.orange, () {}),
      ],
    );
  }

  Widget _serviceBox(String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AppTheme.glassContainer(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          padding: const EdgeInsets.symmetric(vertical: 15),
          opacity: 0.03,
          child: Column(children: [Icon(icon, color: color, size: 28), const SizedBox(height: 8), Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10))]),
        ),
      ),
    );
  }

  Widget _buildMembersList(String familyId) => StreamBuilder<QuerySnapshot>(stream: _db.collection('users').where('familyId', isEqualTo: familyId).snapshots(), builder: (context, snap) =>
 snap.hasData ? ListView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: snap.data!.docs.length, itemBuilder: (context, i) {
    final m = snap.data!.docs[i].data() as Map<String, dynamic>;
    bool isOnline = m['isActive'] ?? false;
    String roleName = m['familyRole'] == 'leader' ? 'رئيس العائلة' : (m['familyRole'] == 'organizer' ? 'نائب' : 'عضو ملكي');
    Color roleColor = m['familyRole'] == 'leader' ? Colors.red.withValues(alpha: 0.1) : (m['familyRole'] == 'organizer' ? Colors.orange.withValues(alpha: 0.1) : Colors.white10);
    Color textColor = m['familyRole'] == 'leader' ? Colors.redAccent : (m['familyRole'] == 'organizer' ? Colors.orangeAccent : Colors.white38);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: AppTheme.glassContainer(
        padding: const EdgeInsets.all(10), opacity: 0.02,
        child: ListTile(
          leading: CircleAvatar(backgroundImage: NetworkImage(m['profilePic'] ?? '')),
          title: Text(m['name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 14)),
          subtitle: Text(isOnline ? 'متصل الآن' : 'غير متصل', style: TextStyle(color: isOnline ? Colors.greenAccent : Colors.white24, fontSize: 10)),
          trailing: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: roleColor, borderRadius: BorderRadius.circular(8)), child: Text(roleName, style: TextStyle(color: textColor, fontSize: 10, fontWeight: FontWeight.bold))),
        ),
      ),
    );
  }) : const CircularProgressIndicator());

  Widget _buildFamilyHeaderCard(FamilyModel f, UserModel u) => Column(children: [
    Container(
      width: 120, height: 120,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.amber, width: 3), boxShadow: [BoxShadow(color: Colors.amber.withValues(alpha: 0.2), blurRadius: 20)]),
      child: ClipOval(child: Image.network(f.logoUrl, fit: BoxFit.cover)),
    ),
    const SizedBox(height: 15),
    Text(f.name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
    Text('شعارنا: ${f.slogan}', style: const TextStyle(color: Colors.amber, fontSize: 12)),
    Text('ID: ${f.id.substring(0,8)}', style: const TextStyle(color: Colors.white24, fontSize: 11)),
  ]);

  Widget _buildFamilyStatsRow(FamilyModel f) => Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [_statBox('LV.${f.level}', 'المستوى'), _statBox('${f.memberCount}/${f.maxMembers}', 'الأعضاء'), _statBox('#${f.totalPoints}', 'الترتيب')]);

  Widget _statBox(String v, String l) => Column(children: [Text(v, style: const TextStyle(color: Colors.deepPurpleAccent, fontSize: 18, fontWeight: FontWeight.bold)), Text(l, style: const TextStyle(color: Colors.white38, fontSize: 11))]);

  Widget _buildSectionTitle(String t) => Align(alignment: Alignment.centerRight, child: Padding(padding: const EdgeInsets.only(bottom: 15, top: 10), child: Text(t, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))));

  Widget _familyListItem(FamilyModel f, int r, bool hasFam) => Container(margin: const EdgeInsets.only(bottom: 10), child: AppTheme.glassContainer(padding: const EdgeInsets.all(5), opacity: 0.02, child: ListTile(leading: Row(mainAxisSize: MainAxisSize.min, children: [Text('#$r', style: TextStyle(color: r <= 3 ? Colors.amber : Colors.white24, fontWeight: FontWeight.bold)), const SizedBox(width: 10), CircleAvatar(backgroundImage: NetworkImage(f.logoUrl))]), title: Text(f.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), subtitle: Text('المستوى ${f.level}'), onTap: () => _showFamilyJoinSheet(f, hasFam))));

  void _showFamilyJoinSheet(FamilyModel f, bool hasFam) => showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (context) => SafeArea(child: Container(padding: const EdgeInsets.all(25), decoration: const BoxDecoration(color: Color(0xFF1A050E), borderRadius: BorderRadius.vertical(top: Radius.circular(30))), child: Column(mainAxisSize: MainAxisSize.min, children: [CircleAvatar(radius: 40, backgroundImage: NetworkImage(f.logoUrl)), const SizedBox(height: 15), Text(f.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)), Text(f.description, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 13)), const SizedBox(height: 25), if (!hasFam) AppTheme.gradientButton(text: 'طلب انضمام', onPressed: () async { try { await _familyService.joinFamily(f.id); Navigator.pop(context); _showSuccessSnack('تم الانضمام بنجاح'); } catch (e) { _showErrorSnack(e.toString()); } }), const SizedBox(height: 20)]))));

  Widget _buildSearchList(bool hasFam) => StreamBuilder<List<FamilyModel>>(stream: _familyService.searchFamilies(_searchQuery), builder: (c, snapshot) => snapshot.hasData ? ListView.builder(padding: const EdgeInsets.all(20), itemCount: snapshot.data!.length, itemBuilder: (c, i) => _familyListItem(snapshot.data![i], i + 1, hasFam)) : const Center(child: CircularProgressIndicator()));
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override double get minExtent => _tabBar.preferredSize.height;
  @override double get maxExtent => _tabBar.preferredSize.height;
  @override Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => Container(color: const Color(0xFF1A050E), child: _tabBar);
  @override bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
