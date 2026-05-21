import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/storage_service.dart';
import 'room_level_details_page.dart';
import '../../../app_theme.dart';
import '../../diaries/widgets/post_card.dart';
import '../../../models/post_model.dart';

class RoomInfoSheet extends StatefulWidget {
  final String roomId;
  final String roomName;
  final String? ownerId;
  final void Function(String newName)? onRoomNameChanged;

  const RoomInfoSheet(
      {super.key,
      required this.roomId,
      required this.roomName,
      this.ownerId,
      this.onRoomNameChanged});

  @override
  State<RoomInfoSheet> createState() => _RoomInfoSheetState();
}

class _RoomInfoSheetState extends State<RoomInfoSheet> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isFollowing = false;
  bool _isMember = false;
  bool _isEditingName = false;
  bool _isEditingNotice = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _noticeController = TextEditingController();
  final TextEditingController _clubNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.roomName;
    _checkStatus();
    _loadRoomData();
  }

  Future<void> _loadRoomData() async {
    final doc = await _db.collection('rooms').doc(widget.roomId).get();
    if (doc.exists) {
      if (mounted) {
        setState(() {
          _noticeController.text =
              doc.data()?['notice'] ?? 'اهلا بكم في رويال دور';
          _clubNameController.text = doc.data()?['fanClubName'] ?? 'نادي رويال';
        });
      }
    }
  }

  Future<void> _checkStatus() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final followDoc = await _db
        .collection('users')
        .doc(user.uid)
        .collection('following_rooms')
        .doc(widget.roomId)
        .get();
    final memberDoc = await _db
        .collection('rooms')
        .doc(widget.roomId)
        .collection('members')
        .doc(user.uid)
        .get();
    if (mounted) {
      setState(() {
        _isFollowing = followDoc.exists;
        _isMember = memberDoc.exists;
      });
    }
  }

  Future<void> _saveClubName() async {
    if (_clubNameController.text.trim().isEmpty) return;
    try {
      await _db
          .collection('rooms')
          .doc(widget.roomId)
          .update({'fanClubName': _clubNameController.text.trim()});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث اسم النادي بنجاح ✅')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('فشل تحديث الاسم ❌')));
      }
    }
  }

  Future<void> _saveRoomName() async {
    if (_nameController.text.trim().isEmpty) return;
    try {
      await _db
          .collection('rooms')
          .doc(widget.roomId)
          .update({'name': _nameController.text.trim()});
      setState(() => _isEditingName = false);
      if (widget.onRoomNameChanged != null) {
        widget.onRoomNameChanged!(_nameController.text.trim());
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث اسم الغرفة بنجاح ✅')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('فشل تحديث الاسم ❌')));
      }
    }
  }

  Future<void> _saveRoomNotice() async {
    try {
      await _db
          .collection('rooms')
          .doc(widget.roomId)
          .update({'notice': _noticeController.text.trim()});
      setState(() => _isEditingNotice = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث إشعار الغرفة بنجاح ✅')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل تحديث إشعار الغرفة ❌')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: DefaultTabController(
        length: 3,
        initialIndex: 0,
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Color(0xFF08141E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildInfoTab(context),
                    _buildMembersTab(),
                    _buildMomentsTab(), // تفعيل اللحظات هنا
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 5),
      decoration: const BoxDecoration(
        color: Color(0xFF0A121A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Stack(
        children: [
          const TabBar(
            indicatorColor: AppTheme.royalGold,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white38,
            labelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: "المعلومات"),
              Tab(text: "الأعضاء"),
              Tab(text: "اللحظات")
            ],
          ),
          Positioned(
            left: 5,
            top: 0,
            bottom: 0,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white54, size: 26),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          _buildIdentityCard(),
          const SizedBox(height: 15),
          _buildEditableSection(
            label: "اسم الغرفة",
            controller: _nameController,
            isEditing: _isEditingName,
            onEdit: () => setState(() => _isEditingName = true),
            onSave: _saveRoomName,
          ),
          const SizedBox(height: 15),
          _buildInfoSection(
            label: "مستوى الغرفة",
            content: GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            RoomLevelDetailsPage(roomId: widget.roomId)));
              },
              child: _buildLevelProgress(),
            ),
          ),
          const SizedBox(height: 15),
          _buildEditableSection(
            label: "إشعار الغرفة",
            controller: _noticeController,
            isEditing: _isEditingNotice,
            onEdit: () => setState(() => _isEditingNotice = true),
            onSave: _saveRoomNotice,
          ),
          const SizedBox(height: 20),
          _buildClubSection(),
          const SizedBox(height: 25),
          _buildActionButtons(),
          const SizedBox(height: 15),
          if (widget.ownerId != _auth.currentUser?.uid) _buildReportButton(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildReportButton() {
    return Center(
      child: TextButton.icon(
        icon: const Icon(Icons.report_problem_outlined,
            color: Colors.orangeAccent, size: 18),
        label: const Text("إبلاغ عن الغرفة",
            style: TextStyle(color: Colors.orangeAccent, fontSize: 13)),
        onPressed: _showReportRoomDialog,
      ),
    );
  }

  void _showReportRoomDialog() {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('إبلاغ عن محتوى الغرفة',
            style: TextStyle(color: Colors.white, fontSize: 16)),
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
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text('إلغاء', style: TextStyle(color: Colors.white38))),
          TextButton(
              onPressed: () async {
                if (reasonController.text.trim().isEmpty) return;
                await _db.collection('reports').add({
                  'type': 'room',
                  'targetId': widget.roomId,
                  'targetName': widget.roomName,
                  'reason': reasonController.text.trim(),
                  'reporterId': _auth.currentUser?.uid,
                  'reporterName': _auth.currentUser?.displayName ?? 'User',
                  'createdAt': FieldValue.serverTimestamp(),
                  'status': 'new',
                });
                if (mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم إرسال البلاغ للإدارة')));
                }
              },
              child: const Text('إرسال',
                  style: TextStyle(color: AppTheme.royalGold))),
        ],
      ),
    );
  }

  Widget _buildMomentsTab() {
    if (widget.ownerId == null) {
      return const Center(
          child: Text("لا توجد لحظات متاحة",
              style: TextStyle(color: Colors.white38)));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('posts')
          .where('authorId', isEqualTo: widget.ownerId)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: AppTheme.royalGold));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text("مالك الغرفة لم ينشر أي لحظات بعد",
                  style: TextStyle(color: Colors.white38)));
        }

        final posts = snapshot.data!.docs
            .map((doc) =>
                PostModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 10),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            return PostCard(
              post: posts[index],
              currentUid: _auth.currentUser?.uid ?? '',
              onUpdate: (s) {},
            );
          },
        );
      },
    );
  }

  Widget _buildClubSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
            padding: EdgeInsets.only(right: 5, bottom: 10),
            child: Text("نادي الأعضاء الملكي",
                style: TextStyle(color: Colors.white38, fontSize: 13))),
        Row(
          children: [
            StreamBuilder<QuerySnapshot>(
                stream: _db
                    .collection('rooms')
                    .doc(widget.roomId)
                    .collection('members')
                    .snapshots(),
                builder: (context, snapshot) {
                  final count = snapshot.data?.docs.length ?? 0;
                  return _buildClubBox("الأعضاء", count.toString(), false);
                }),
            const SizedBox(width: 12),
            _buildClubBox("اسم النادي", _clubNameController.text, true),
          ],
        ),
      ],
    );
  }

  Widget _buildClubBox(String label, String value, bool editable) {
    return Expanded(
      child: GestureDetector(
        onTap: editable ? () => _showEditClubNameDialog() : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF11212D),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              Text(label,
                  style: const TextStyle(color: Colors.white38, fontSize: 11)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (editable)
                    const Icon(Icons.edit, color: AppTheme.royalGold, size: 12),
                  if (editable) const SizedBox(width: 5),
                  Flexible(
                      child: Text(value,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditClubNameDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A242F),
        title: const Text('تعديل اسم النادي',
            style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: _clubNameController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
              enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppTheme.royalGold))),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text('إلغاء', style: TextStyle(color: Colors.white38))),
          TextButton(
              onPressed: () {
                _saveClubName();
                Navigator.pop(ctx);
              },
              child: const Text('حفظ',
                  style: TextStyle(color: AppTheme.royalGold))),
        ],
      ),
    );
  }

  Future<void> _toggleJoin() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      if (_isMember) {
        await _db
            .collection('rooms')
            .doc(widget.roomId)
            .collection('members')
            .doc(user.uid)
            .delete();
      } else {
        if (!_isFollowing) await _toggleFollow();
        final membersSnap = await _db
            .collection('rooms')
            .doc(widget.roomId)
            .collection('members')
            .get();
        final int memberNumber = membersSnap.docs.length + 1;
        await _db
            .collection('rooms')
            .doc(widget.roomId)
            .collection('members')
            .doc(user.uid)
            .set({
          'uid': user.uid,
          'name': user.displayName ?? 'مستخدم رويال',
          'joinedAt': FieldValue.serverTimestamp(),
          'role': 'member',
          'memberNumber': memberNumber,
        });
      }
      setState(() => _isMember = !_isMember);
    } catch (e) {
      debugPrint("Join Error: $e");
    }
  }

  Widget _buildIdentityCard() {
    return StreamBuilder<DocumentSnapshot>(
        stream: _db.collection('rooms').doc(widget.roomId).snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final String roomImageUrl = data['roomImage'] ?? '';
          return Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
                color: const Color(0xFF11212D),
                borderRadius: BorderRadius.circular(15)),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _changeRoomImage,
                  child: Stack(
                    children: [
                      Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                  image: roomImageUrl.isNotEmpty
                                      ? NetworkImage(roomImageUrl)
                                      : const AssetImage(
                                              'assets/images/room_global.jpg')
                                          as ImageProvider,
                                  fit: BoxFit.cover))),
                      Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.camera_alt,
                                  color: Colors.amber, size: 14))),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Row(
                        children: [
                          Flexible(
                              child: Text("معرف: ${widget.roomId}",
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 8),
                          const Icon(Icons.copy,
                              color: Colors.blueAccent, size: 16)
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Icon(Icons.public,
                              color: Colors.greenAccent, size: 18),
                          _buildLangTag("العربية", true),
                          _buildLangTag("الإنجليزية", false)
                        ],
                      ),
                    ])),
              ],
            ),
          );
        });
  }

  Widget _buildLangTag(String label, bool active) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: active ? const Color(0xFF006064) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white10)),
      child: Text(label,
          style: TextStyle(
              color: active ? Colors.cyanAccent : Colors.white38,
              fontSize: 10)));

  Widget _buildEditableSection(
      {required String label,
      required TextEditingController controller,
      required bool isEditing,
      required VoidCallback onEdit,
      required VoidCallback onSave}) {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
            color: const Color(0xFF11212D).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: isEditing
                    ? TextField(
                        controller: controller,
                        autofocus: true,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                        decoration:
                            const InputDecoration(border: InputBorder.none))
                    : Text(controller.text,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis)),
            IconButton(
                icon: Icon(isEditing ? Icons.check : Icons.edit,
                    color: Colors.amber, size: 18),
                onPressed: isEditing ? onSave : onEdit)
          ])
        ]));
  }

  Widget _buildInfoSection({required String label, required Widget content}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
            padding: const EdgeInsets.only(right: 5, bottom: 5),
            child: Text(label,
                style: const TextStyle(color: Colors.white38, fontSize: 12))),
        Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
                color: const Color(0xFF11212D).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              Expanded(child: content),
              const Icon(Icons.chevron_left, color: Colors.white24, size: 20)
            ]))
      ]);

  Widget _buildLevelProgress() {
    return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomId)
            .snapshots(),
        builder: (context, snapshot) {
          final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final int exp = data['exp'] ?? 0;
          final int level = data['level'] ?? 1;

          // معادلة حساب الحد الأقصى للخبرة للمستوى الحالي
          final int nextLevelExp = (level * 10000);
          final double progress = (exp / nextLevelExp).clamp(0.0, 1.0);

          return Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: const Color(0xFF1B5E20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.greenAccent.withValues(alpha: 0.4)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4)
                    ]),
                child: Row(
                  children: [
                    Text("$level",
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                    const SizedBox(width: 4),
                    const Icon(Icons.shield, color: Colors.white, size: 14),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 20,
                            backgroundColor: Colors.black45,
                            color: const Color(0xFF009688),
                          ),
                        ),
                        Text("$exp / $nextLevelExp",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(blurRadius: 2, color: Colors.black)
                                ])),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text("يتبقى ${nextLevelExp - exp} للمستوى التالي",
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 9)),
                  ],
                ),
              ),
            ],
          );
        });
  }

  Widget _buildMembersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('rooms')
          .doc(widget.roomId)
          .collection('members')
          .orderBy('joinedAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final members = snapshot.data!.docs;
        if (members.isEmpty) {
          return const Center(
              child: Text("لا يوجد أعضاء في النادي حالياً",
                  style: TextStyle(color: Colors.white38)));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: members.length,
          itemBuilder: (context, index) {
            final memberData = members[index].data() as Map<String, dynamic>;
            final uid = members[index].id;
            final role = memberData['role'] ?? 'member';
            final int? mNumber = memberData['memberNumber'];

            return FutureBuilder<DocumentSnapshot>(
              future: _db.collection('users').doc(uid).get(),
              builder: (context, userSnap) {
                if (!userSnap.hasData) return const SizedBox(height: 70);
                final userData =
                    userSnap.data!.data() as Map<String, dynamic>? ?? {};
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: const Color(0xFF11212D),
                      borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    leading: CircleAvatar(
                        backgroundImage: userData['profilePic'] != null
                            ? NetworkImage(userData['profilePic'])
                            : null,
                        backgroundColor: Colors.grey[800],
                        child: userData['profilePic'] == null
                            ? const Icon(Icons.person, color: Colors.white)
                            : null),
                    title: Row(children: [
                      Text(userData['name'] ?? 'مستخدم ملكي',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14)),
                      const SizedBox(width: 8),
                      if (mNumber != null)
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                                color:
                                    AppTheme.royalGold.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                    color: AppTheme.royalGold
                                        .withValues(alpha: 0.5))),
                            child: Text("No.$mNumber",
                                style: const TextStyle(
                                    color: AppTheme.royalGold,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)))
                    ]),
                    subtitle: Text(
                        role == 'admin' ? "مسؤول الغرفة" : "عضو النادي",
                        style: TextStyle(
                            color:
                                role == 'admin' ? Colors.amber : Colors.white54,
                            fontSize: 11)),
                    trailing: _buildMemberActions(uid, role),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildMemberActions(String uid, String currentRole) {
    if (widget.ownerId == null ||
        _auth.currentUser?.uid != widget.ownerId ||
        uid == _auth.currentUser?.uid) {
      return const SizedBox.shrink();
    }
    return IconButton(
        icon: Icon(
            currentRole == 'admin'
                ? Icons.admin_panel_settings
                : Icons.person_add_alt_1,
            color: Colors.amber,
            size: 22),
        onPressed: () => _showRoleOptions(uid, currentRole));
  }

  void _showRoleOptions(String uid, String currentRole) {
    showModalBottomSheet(
        context: context,
        backgroundColor: const Color(0xFF0F1A24),
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (context) => Column(mainAxisSize: MainAxisSize.min, children: [
              const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("تعيين رتبة العضو",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold))),
              ListTile(
                  leading: const Icon(Icons.admin_panel_settings,
                      color: Colors.amber),
                  title: const Text("تعيين كمسؤول",
                      style: TextStyle(color: Colors.white)),
                  onTap: () => _updateMemberRole(uid, 'admin')),
              ListTile(
                  leading: const Icon(Icons.person, color: Colors.cyanAccent),
                  title: const Text("تعيين كعضو عادي",
                      style: TextStyle(color: Colors.white)),
                  onTap: () => _updateMemberRole(uid, 'member')),
              const SizedBox(height: 20)
            ]));
  }

  Future<void> _updateMemberRole(String uid, String newRole) async {
    try {
      await _db
          .collection('rooms')
          .doc(widget.roomId)
          .collection('members')
          .doc(uid)
          .update({'role': newRole});
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم تحديث الرتبة ✅')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('فشل التحديث ❌')));
      }
    }
  }

  Future<void> _toggleFollow() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final roomRef = _db.collection('rooms').doc(widget.roomId);
      final userFollowRef = _db
          .collection('users')
          .doc(user.uid)
          .collection('following_rooms')
          .doc(widget.roomId);
      final roomFollowerRef = roomRef.collection('followers').doc(user.uid);
      if (_isFollowing) {
        await userFollowRef.delete();
        await roomFollowerRef.delete();
      } else {
        await userFollowRef.set({
          'roomId': widget.roomId,
          'roomName': widget.roomName,
          'followedAt': FieldValue.serverTimestamp()
        });
        await roomFollowerRef
            .set({'uid': user.uid, 'followedAt': FieldValue.serverTimestamp()});
      }
      setState(() => _isFollowing = !_isFollowing);
    } catch (e) {
      debugPrint("Follow Error: $e");
    }
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
            child: GestureDetector(
                onTap: _toggleFollow,
                child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                        color: _isFollowing
                            ? Colors.white10
                            : const Color(0xFF006064),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white10)),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_isFollowing ? Icons.check : Icons.add,
                              color: _isFollowing
                                  ? Colors.white54
                                  : Colors.cyanAccent,
                              size: 20),
                          const SizedBox(width: 8),
                          Text(_isFollowing ? "تمت المتابعة" : "متابعة",
                              style: TextStyle(
                                  color: _isFollowing
                                      ? Colors.white54
                                      : Colors.white,
                                  fontWeight: FontWeight.bold))
                        ])))),
        const SizedBox(width: 15),
        Expanded(
            child: GestureDetector(
                onTap: _toggleJoin,
                child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                        gradient: _isMember
                            ? null
                            : const LinearGradient(
                                colors: [Color(0xFF00ACC1), Color(0xFF00838F)]),
                        color: _isMember ? Colors.white10 : null,
                        borderRadius: BorderRadius.circular(24)),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_isMember ? Icons.group_remove : Icons.group_add,
                              color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(_isMember ? "مغادرة النادي" : "انضمام للنادي",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold))
                        ])))),
      ],
    );
  }

  Future<void> _changeRoomImage() async {
    final picker = ImagePicker();
    final image =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      try {
        final url = await StorageService.uploadRoomImage(File(image.path));
        await _db
            .collection('rooms')
            .doc(widget.roomId)
            .update({'roomImage': url});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم التحديث بنجاح ✅')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('فشل التحديث ❌')));
        }
      }
    }
  }
}
