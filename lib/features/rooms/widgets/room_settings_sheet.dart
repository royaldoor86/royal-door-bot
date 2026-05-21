import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'mic_modes_sheet.dart';

class RoomSettingsSheet extends StatefulWidget {
  final String roomId;
  final bool hasPower;

  const RoomSettingsSheet({
    super.key,
    required this.roomId,
    required this.hasPower,
  });

  @override
  State<RoomSettingsSheet> createState() => _RoomSettingsSheetState();
}

class _RoomSettingsSheetState extends State<RoomSettingsSheet> {
  bool _noiseReduction = true;
  bool _muteChat = false;
  bool _adminOnlyMic = false;
  int _membershipFee = 0;
  bool _mutePublic = false;
  int _minLevelRequired = 1;
  String? _roomPassword;
  bool _isLockPurchased = false;
  bool _canLockRoom = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final doc = await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .get();
    if (doc.exists && mounted) {
      final data = doc.data()!;
      final currentUser = FirebaseAuth.instance.currentUser?.uid;
      final ownerId = data['ownerId'];

      setState(() {
        _muteChat = data['muteChat'] ?? false;
        _adminOnlyMic = data['adminOnlyMic'] ?? false;
        _membershipFee = data['membershipFee'] ?? 0;
        _mutePublic = data['mutePublic'] ?? false;
        _minLevelRequired = data['minLevelRequired'] ?? 1;
        _roomPassword = data['password'];
        _isLockPurchased = data['isLockPurchased'] ?? false;

        if (currentUser == ownerId) {
          _canLockRoom = true;
        } else {
          final perms = data['moderatorPermissions'] as Map<String, dynamic>?;
          _canLockRoom = perms?['canLockRoom'] ?? false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF0F1A24),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          const Text('إعدادات الغرفة',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildTopActions(),
                  const SizedBox(height: 20),
                  _buildSectionHeader("تحكم الغرفة"),
                  _buildGrid(),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildActionItem(Icons.reply, "مشاركة", Colors.cyan),
          _buildActionItem(
              Icons.report_problem_outlined, "مشكلات الصوت", Colors.cyan),
          _buildToggleItem(Icons.waves, "تقليل الضوضاء", _noiseReduction,
              (v) => setState(() => _noiseReduction = v)),
          _buildActionItem(Icons.card_giftcard, "إعدادات الهدايا", Colors.cyan),
        ],
      ),
    );
  }

  Widget _buildActionItem(IconData icon, String label, Color color) {
    return Column(children: [
      Icon(icon, color: color, size: 28),
      const SizedBox(height: 6),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10))
    ]);
  }

  Widget _buildToggleItem(
      IconData icon, String label, bool value, Function(bool) onChanged) {
    return Column(
      children: [
        Icon(icon, color: Colors.cyan, size: 28),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 10)),
        Transform.scale(
            scale: 0.7,
            child: Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: Colors.green)),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          decoration: const BoxDecoration(
            color: Color(0xFF1B2B38),
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15), bottomLeft: Radius.circular(15)),
          ),
          child: Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold))),
    );
  }

  Widget _buildGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 4,
      mainAxisSpacing: 25,
      children: [
        _buildGridItem(Icons.mic, "نمط المايكات", Colors.amber,
            onTap: () => _showMicModes(context)),
        _buildGridItem(
            Icons.lock,
            _roomPassword != null ? "الغرفة مقفلة" : "قفل الغرفة",
            _roomPassword != null ? Colors.red : Colors.amber,
            onTap: _showLockRoomUI),
        _buildGridItem(Icons.mic_off, "إذن المايك",
            _adminOnlyMic ? Colors.red : Colors.green,
            onTap: _showMicPermissionUI),
        _buildGridItem(Icons.chat_bubble_outline, "قيود المراسلة",
            _muteChat || _mutePublic ? Colors.red : Colors.blue,
            onTap: _showMessagingRestrictionsUI),
        _buildGridItem(
            Icons.admin_panel_settings, "صلاحيات المشرف", Colors.purple,
            onTap: _showModeratorPermissionsUI),
        _buildGridItem(Icons.stars_rounded, "رسوم العضوية", Colors.yellow,
            onTap: _setMembershipFeesUI),
        _buildGridItem(
            Icons.person_remove_outlined, "تصفية الأعضاء", Colors.orange,
            onTap: _removeInactiveMembers),
        _buildGridItem(Icons.block, "قائمة الحظر", Colors.redAccent,
            onTap: _showBanListUI),
        _buildGridItem(Icons.group_remove, "إزالة الأعضاء", Colors.red,
            onTap: _showRemoveMembersUI),
        _buildGridItem(Icons.history, "سجل العقوبات", Colors.blueGrey,
            onTap: _showPenaltyLogsUI),
        _buildGridItem(Icons.palette, "موضوع", Colors.orange),
      ],
    );
  }

  Widget _buildGridItem(IconData icon, String label, Color color,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: widget.hasPower
          ? onTap
          : () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('هذا الخيار مخصص للمالك والمشرفين فقط 👑')));
            },
      child: Column(children: [
        Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.black26,
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.3))),
            child: Icon(icon, color: color, size: 24)),
        const SizedBox(height: 8),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 10))
      ]),
    );
  }

  void _showLockRoomUI() {
    if (!_canLockRoom) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('عذراً، لا تملك صلاحية التحكم بقفل الغرفة 👑')));
      return;
    }
    if (!_isLockPurchased) {
      _showPlaceholderDialog("ميزة القفل",
          "يجب على المالك شراء ميزة القفل الملكي أولاً من قائمة المزيد.");
      return;
    }
    showDialog(
      context: context,
      builder: (context) => _LockRoomDialog(
        roomId: widget.roomId,
        initialPassword: _roomPassword,
        onChanged: (val) => setState(() => _roomPassword = val),
      ),
    );
  }

  void _showMicModes(BuildContext context) {
    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => const MicModesSheet());
  }

  void _showMicPermissionUI() {
    showDialog(
        context: context,
        builder: (context) => _MicPermissionDialog(
            roomId: widget.roomId,
            initialValue: _adminOnlyMic,
            onChanged: (val) => setState(() => _adminOnlyMic = val)));
  }

  void _showMessagingRestrictionsUI() {
    showDialog(
        context: context,
        builder: (context) => _MessagingRestrictionsDialog(
            roomId: widget.roomId,
            muteChat: _muteChat,
            mutePublic: _mutePublic,
            minLevel: _minLevelRequired,
            onSave: (chat, public, level) {
              setState(() {
                _muteChat = chat;
                _mutePublic = public;
                _minLevelRequired = level;
              });
            }));
  }

  void _showModeratorPermissionsUI() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ModeratorPermissionsScreen(roomId: widget.roomId),
    );
  }

  void _setMembershipFeesUI() {
    showDialog(
        context: context,
        builder: (context) => _MembershipFeesDialog(
            roomId: widget.roomId,
            initialFee: _membershipFee,
            onChanged: (val) => setState(() => _membershipFee = val)));
  }

  void _removeInactiveMembers() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
                backgroundColor: const Color(0xFF1A242F),
                title: const Text('تصفية الأعضاء غير النشطين',
                    style: TextStyle(color: Colors.white)),
                content: const Text(
                    'سيتم إزالة جميع الأعضاء الذين لم يتواجدوا في الغرفة منذ أكثر من 30 يوماً. هل أنت متأكد؟',
                    style: TextStyle(color: Colors.white70)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إلغاء')),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange),
                    onPressed: () async {
                      Navigator.pop(context);
                      _processCleanup();
                    },
                    child: const Text('تأكيد التصفية'),
                  )
                ]));
  }

  void _processCleanup() async {
    final scaffold = ScaffoldMessenger.of(context);
    scaffold.showSnackBar(
        const SnackBar(content: Text('جاري تصفية الأعضاء غير النشطين... ⏳')));

    try {
      final membersRef = FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .collection('members');
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final inactiveMembers = await membersRef
          .where('lastVisited', isLessThan: thirtyDaysAgo)
          .get();

      if (inactiveMembers.docs.isEmpty) {
        scaffold.showSnackBar(const SnackBar(
            content: Text('لم يتم العثور على أعضاء غير نشطين لتصفيتهم.')));
        return;
      }

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in inactiveMembers.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      scaffold.showSnackBar(SnackBar(
          content: Text('تمت تصفية ${inactiveMembers.docs.length} عضو بنجاح ✅'),
          backgroundColor: Colors.green));
    } catch (e) {
      scaffold.showSnackBar(const SnackBar(
          content: Text('فشل في عملية التصفية ❌'),
          backgroundColor: Colors.redAccent));
    }
  }

  void _showBanListUI() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _BanListScreen(roomId: widget.roomId));
  }

  void _showRemoveMembersUI() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _RemoveMembersScreen(roomId: widget.roomId));
  }

  void _showPenaltyLogsUI() {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _PenaltyLogsScreen(roomId: widget.roomId));
  }

  void _showPlaceholderDialog(String title, String content) {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
                backgroundColor: const Color(0xFF1A242F),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                title: Text(title, style: const TextStyle(color: Colors.white)),
                content: Text(content,
                    style: const TextStyle(color: Colors.white70)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('إغلاق',
                          style: TextStyle(color: Colors.amber)))
                ]));
  }
}

class _LockRoomDialog extends StatefulWidget {
  final String roomId;
  final String? initialPassword;
  final ValueChanged<String?> onChanged;
  const _LockRoomDialog(
      {required this.roomId, this.initialPassword, required this.onChanged});

  @override
  State<_LockRoomDialog> createState() => _LockRoomDialogState();
}

class _LockRoomDialogState extends State<_LockRoomDialog> {
  late TextEditingController _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialPassword);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
            color: const Color(0xFFE0F2F1),
            borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              decoration: const BoxDecoration(
                  color: Color(0xFF4DB6AC),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20))),
              child: Stack(alignment: Alignment.center, children: [
                const Text('قفل الغرفة',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                Positioned(
                    left: 0,
                    child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context)))
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                      'أدخل رمز القفل المكون من 4 أرقام، أو اتركه فارغاً لفتح الغرفة.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54, fontSize: 13)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 10),
                    decoration: InputDecoration(
                      hintText: '----',
                      counterText: '',
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFA000),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25))),
                      onPressed: _isSaving ? null : _saveLock,
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('حفظ الإعدادات',
                              style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveLock() async {
    setState(() => _isSaving = true);
    try {
      String pass = _controller.text.trim();
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .update({'password': pass.isEmpty ? null : pass});
      widget.onChanged(pass.isEmpty ? null : pass);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل في حفظ كلمة المرور ❌')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _RemoveMembersScreen extends StatefulWidget {
  final String roomId;
  const _RemoveMembersScreen({required this.roomId});

  @override
  State<_RemoveMembersScreen> createState() => _RemoveMembersScreenState();
}

class _RemoveMembersScreenState extends State<_RemoveMembersScreen> {
  final List<String> _selectedUids = [];
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
          color: Color(0xFFE0F2F1),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      child: Column(
        children: [
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              decoration: const BoxDecoration(
                  color: Color(0xFF1B5E20),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(25))),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context)),
                    const Text('إزالة الأعضاء',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    const Icon(Icons.list, color: Colors.white)
                  ])),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rooms')
                  .doc(widget.roomId)
                  .collection('members')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final members = snapshot.data!.docs;
                if (members.isEmpty) {
                  return const Center(
                      child: Text('لا يوجد أعضاء حالياً',
                          style: TextStyle(color: Colors.black54)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final uid = members[index].id;
                    if (uid == FirebaseAuth.instance.currentUser?.uid) {
                      return const SizedBox.shrink();
                    }
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .get(),
                      builder: (context, userSnap) {
                        if (!userSnap.hasData) {
                          return const SizedBox(height: 70);
                        }
                        final userData =
                            userSnap.data!.data() as Map<String, dynamic>? ??
                                {};
                        final name = userData['name'] ?? 'مستخدم ملكي';
                        final avatar = userData['profilePic'] ?? '';
                        final level = userData['accountLevel'] ?? 1;
                        final gender = userData['gender'] ?? 'ذكر';
                        bool isSelected = _selectedUids.contains(uid);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.teal.withValues(alpha: 0.1)
                                  : Colors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            onTap: () => setState(() => isSelected
                                ? _selectedUids.remove(uid)
                                : _selectedUids.add(uid)),
                            leading: CircleAvatar(
                                radius: 25,
                                backgroundImage: avatar.isNotEmpty
                                    ? NetworkImage(avatar)
                                    : null,
                                backgroundColor: Colors.grey[300],
                                child: avatar.isEmpty
                                    ? const Icon(Icons.person,
                                        color: Colors.white)
                                    : null),
                            title: Row(children: [
                              Flexible(
                                  child: Text(name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14))),
                              const SizedBox(width: 5),
                              Icon(gender == 'أنثى' ? Icons.female : Icons.male,
                                  color: gender == 'أنثى'
                                      ? Colors.pink
                                      : Colors.blue,
                                  size: 16),
                              const SizedBox(width: 5),
                              Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                      color: Colors.amber,
                                      borderRadius: BorderRadius.circular(4)),
                                  child: Text(level.toString(),
                                      style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white)))
                            ]),
                            subtitle: const Text('عضو ملكي في الغرفة',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.black45)),
                            trailing: Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: isSelected
                                            ? Colors.teal
                                            : Colors.grey[400]!,
                                        width: 2),
                                    color: isSelected
                                        ? Colors.teal
                                        : Colors.transparent),
                                child: isSelected
                                    ? const Icon(Icons.check,
                                        size: 14, color: Colors.white)
                                    : null),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _selectedUids.isEmpty
                              ? Colors.grey
                              : Colors.redAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          elevation: 0),
                      onPressed: (_selectedUids.isEmpty || _isProcessing)
                          ? null
                          : _removeSelectedMembers,
                      child: _isProcessing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('إزالة المحددين',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold))))),
        ],
      ),
    );
  }

  void _removeSelectedMembers() async {
    setState(() => _isProcessing = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (var uid in _selectedUids) {
        batch.delete(FirebaseFirestore.instance
            .collection('rooms')
            .doc(widget.roomId)
            .collection('members')
            .doc(uid));
      }
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('تم إزالة ${_selectedUids.length} عضو بنجاح ✅'),
            backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل في إزالة الأعضاء ❌')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}

class _BanListScreen extends StatefulWidget {
  final String roomId;
  const _BanListScreen({required this.roomId});

  @override
  State<_BanListScreen> createState() => _BanListScreenState();
}

class _BanListScreenState extends State<_BanListScreen> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
          color: Color(0xFFE0F2F1),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      child: Column(
        children: [
          Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              decoration: const BoxDecoration(
                  color: Color(0xFF1B5E20),
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(25))),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context)),
                    const Text('قائمة الحظر',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    IconButton(
                        icon:
                            const Icon(Icons.help_outline, color: Colors.white),
                        onPressed: () {})
                  ])),
          Padding(
              padding: const EdgeInsets.all(15),
              child: Row(children: [
                Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                        color: Color(0xFF2E7D32), shape: BoxShape.circle),
                    child: const Icon(Icons.search,
                        color: Colors.white, size: 20)),
                const SizedBox(width: 10),
                Expanded(
                    child: Container(
                        height: 40,
                        decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(20)),
                        child: TextField(
                            style: const TextStyle(fontSize: 14),
                            onChanged: (v) => setState(() => _searchQuery = v),
                            decoration: const InputDecoration(
                                hintText: 'ابحث عن اسم أو معرف',
                                hintStyle: TextStyle(
                                    color: Colors.black26, fontSize: 12),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 10)))))
              ])),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rooms')
                  .doc(widget.roomId)
                  .collection('bans')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final bannedDocs = snapshot.data!.docs;
                if (bannedDocs.isEmpty) {
                  return const Center(
                      child: Text('قائمة الحظر فارغة 🕊️',
                          style: TextStyle(color: Colors.black45)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemCount: bannedDocs.length,
                  itemBuilder: (context, index) {
                    final uid = bannedDocs[index].id;
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .get(),
                      builder: (context, userSnap) {
                        if (!userSnap.hasData) {
                          return const SizedBox(height: 70);
                        }
                        final userData =
                            userSnap.data!.data() as Map<String, dynamic>? ??
                                {};
                        final name = userData['name'] ?? 'مستخدم محظور';
                        final avatar = userData['profilePic'] ?? '';
                        final level = userData['accountLevel'] ?? 0;
                        final gender = userData['gender'] ?? 'ذكر';
                        if (_searchQuery.isNotEmpty &&
                            !name.contains(_searchQuery)) {
                          return const SizedBox.shrink();
                        }
                        return Container(
                          margin: const EdgeInsets.only(bottom: 2),
                          decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(5)),
                          child: ListTile(
                            leading:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                      color: Colors.amber[800],
                                      borderRadius: BorderRadius.circular(4)),
                                  child: Text(level.toString(),
                                      style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white))),
                              const SizedBox(width: 8),
                              CircleAvatar(
                                  radius: 20,
                                  backgroundImage: avatar.isNotEmpty
                                      ? NetworkImage(avatar)
                                      : null,
                                  backgroundColor: Colors.grey[300])
                            ]),
                            title: Row(children: [
                              Icon(gender == 'أنثى' ? Icons.female : Icons.male,
                                  color: gender == 'أنثى'
                                      ? Colors.pink
                                      : Colors.blue,
                                  size: 14),
                              const SizedBox(width: 5),
                              Text(name,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600))
                            ]),
                            trailing: TextButton(
                                onPressed: () => _unbanUser(uid, name),
                                child: const Text('فك الحظر',
                                    style: TextStyle(color: Colors.redAccent))),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _unbanUser(String uid, String name) async {
    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .collection('bans')
        .doc(uid)
        .delete();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('تم فك الحظر عن $name بنجاح ✅'),
          backgroundColor: Colors.green));
    }
  }
}

class _MicPermissionDialog extends StatefulWidget {
  final String roomId;
  final bool initialValue;
  final ValueChanged<bool> onChanged;
  const _MicPermissionDialog(
      {required this.roomId,
      required this.initialValue,
      required this.onChanged});
  @override
  State<_MicPermissionDialog> createState() => _MicPermissionDialogState();
}

class _MicPermissionDialogState extends State<_MicPermissionDialog> {
  late bool _tempAdminOnly;
  bool _isSaving = false;
  @override
  void initState() {
    super.initState();
    _tempAdminOnly = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Container(
            decoration: BoxDecoration(
                color: const Color(0xFFE0F2F1),
                borderRadius: BorderRadius.circular(20)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  decoration: const BoxDecoration(
                      color: Color(0xFF4DB6AC),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20))),
                  child: Stack(alignment: Alignment.center, children: [
                    const Text('إذن المايك',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    Positioned(
                        left: 0,
                        child: IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.white, size: 24),
                            onPressed: () => Navigator.pop(context)))
                  ])),
              const SizedBox(height: 20),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(children: [
                    _buildOption('الجميع', !_tempAdminOnly,
                        () => setState(() => _tempAdminOnly = false)),
                    const SizedBox(height: 12),
                    _buildOption('المسؤولين فقط', _tempAdminOnly,
                        () => setState(() => _tempAdminOnly = true))
                  ])),
              const SizedBox(height: 25),
              Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  child: InkWell(
                      onTap: _isSaving ? null : _savePermission,
                      child: Container(
                          height: 45,
                          width: double.infinity,
                          decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFD54F),
                                    Color(0xFFFFA000)
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 4,
                                    offset: const Offset(0, 4))
                              ]),
                          alignment: Alignment.center,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Text('تأكيد',
                                  style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)))))
            ])));
  }

  Widget _buildOption(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
            height: 50,
            width: double.infinity,
            decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFB2DFDB)
                    : Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: isSelected
                        ? const Color(0xFF4DB6AC)
                        : Colors.transparent,
                    width: 1)),
            alignment: Alignment.center,
            child: Text(label,
                style: TextStyle(
                    color:
                        isSelected ? const Color(0xFF00695C) : Colors.black54,
                    fontSize: 15,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal))));
  }

  void _savePermission() async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .update({'adminOnlyMic': _tempAdminOnly});
      widget.onChanged(_tempAdminOnly);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل في حفظ التغييرات ❌')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _MembershipFeesDialog extends StatefulWidget {
  final String roomId;
  final int initialFee;
  final ValueChanged<int> onChanged;
  const _MembershipFeesDialog(
      {required this.roomId,
      required this.initialFee,
      required this.onChanged});
  @override
  State<_MembershipFeesDialog> createState() => _MembershipFeesDialogState();
}

class _MembershipFeesDialogState extends State<_MembershipFeesDialog> {
  late TextEditingController _controller;
  bool _isSaving = false;
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialFee.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        child: Container(
            decoration: BoxDecoration(
                color: const Color(0xFFE0F2F1),
                borderRadius: BorderRadius.circular(20)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  decoration: const BoxDecoration(
                      color: Color(0xFF4DB6AC),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20))),
                  child: Stack(alignment: Alignment.center, children: [
                    const Text('رسوم العضوية',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    Positioned(
                        left: 0,
                        child: IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.white, size: 24),
                            onPressed: () => Navigator.pop(context)))
                  ])),
              const SizedBox(height: 20),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(children: [
                    const Text(
                        'يرجى تحديد رسوم العضوية لغرفتك. يمكن للمستخدمين الانضمام إلى غرفتك من خلال دفع الرسوم. ستحصل على المكافأة على أساس الحد اليومي.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.black54, fontSize: 13, height: 1.4)),
                    const SizedBox(height: 25),
                    Container(
                        height: 80,
                        width: double.infinity,
                        decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(15)),
                        alignment: Alignment.center,
                        child: TextField(
                            controller: _controller,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                            decoration: const InputDecoration(
                                border: InputBorder.none, hintText: '0'))),
                    const SizedBox(height: 15),
                    const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.diamond, color: Colors.cyan, size: 20),
                      SizedBox(width: 5),
                      Text('الرسوم 0 - 2000',
                          style: TextStyle(
                              color: Colors.black45,
                              fontSize: 14,
                              fontWeight: FontWeight.bold))
                    ])
                  ])),
              const SizedBox(height: 25),
              Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  child: InkWell(
                      onTap: _isSaving ? null : _saveFees,
                      child: Container(
                          height: 45,
                          width: double.infinity,
                          decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFD54F),
                                    Color(0xFFFFA000)
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 4,
                                    offset: const Offset(0, 4))
                              ]),
                          alignment: Alignment.center,
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Text('تأكيد',
                                  style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)))))
            ])));
  }

  void _saveFees() async {
    int fee = int.tryParse(_controller.text) ?? 0;
    if (fee > 2000) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الحد الأقصى للرسوم هو 2000 💎')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .update({'membershipFee': fee});
      widget.onChanged(fee);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('فشل في حفظ الرسوم ❌')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _MessagingRestrictionsDialog extends StatefulWidget {
  final String roomId;
  final bool muteChat;
  final bool mutePublic;
  final int minLevel;
  final Function(bool, bool, int) onSave;
  const _MessagingRestrictionsDialog(
      {required this.roomId,
      required this.muteChat,
      required this.mutePublic,
      required this.minLevel,
      required this.onSave});
  @override
  State<_MessagingRestrictionsDialog> createState() =>
      _MessagingRestrictionsDialogState();
}

class _MessagingRestrictionsDialogState
    extends State<_MessagingRestrictionsDialog> {
  late bool _tempMuteChat;
  late bool _tempMutePublic;
  late int _tempLevel;
  bool _isSaving = false;
  @override
  void initState() {
    super.initState();
    _tempMuteChat = widget.muteChat;
    _tempMutePublic = widget.mutePublic;
    _tempLevel = widget.minLevel;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 30),
        child: Container(
            decoration: BoxDecoration(
                color: const Color(0xFFE0F2F1),
                borderRadius: BorderRadius.circular(20)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  decoration: const BoxDecoration(
                      color: Color(0xFF4DB6AC),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(20))),
                  child: Stack(alignment: Alignment.center, children: [
                    const Text('قيود المراسلة',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    Positioned(
                        left: 0,
                        child: IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.white, size: 24),
                            onPressed: () => Navigator.pop(context)))
                  ])),
              const SizedBox(height: 20),
              Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(children: [
                    _buildSwitchOption(
                        'لجميع المستخدمين',
                        'باستثناء مالك الغرفة ونواب المالك',
                        _tempMuteChat,
                        (v) => setState(() => _tempMuteChat = v)),
                    const Divider(
                        color: Colors.black12, height: 30, thickness: 1),
                    _buildLevelOption(),
                    const Divider(
                        color: Colors.black12, height: 30, thickness: 1),
                    _buildSwitchOption(
                        'للمستخدمين غير الأعضاء',
                        '',
                        _tempMutePublic,
                        (v) => setState(() => _tempMutePublic = v))
                  ])),
              const SizedBox(height: 25),
              Padding(
                  padding:
                      const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                  child: Row(children: [
                    Expanded(
                        child: InkWell(
                            onTap: _isSaving ? null : _saveRestrictions,
                            child: Container(
                                height: 45,
                                decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFFD54F),
                                          Color(0xFFFFA000)
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter),
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 4))
                                    ]),
                                alignment: Alignment.center,
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2))
                                    : const Text('حفظ',
                                        style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold))))),
                    const SizedBox(width: 15),
                    Expanded(
                        child: InkWell(
                            onTap: () => setState(() {
                                  _tempMuteChat = false;
                                  _tempMutePublic = false;
                                  _tempLevel = 1;
                                }),
                            child: Container(
                                height: 45,
                                decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF4DB6AC),
                                          Color(0xFF26A69A)
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter),
                                    borderRadius: BorderRadius.circular(25),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 4))
                                    ]),
                                alignment: Alignment.center,
                                child: const Text('إعادة التعيين',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)))))
                  ]))
            ])));
  }

  Widget _buildSwitchOption(
      String title, String subtitle, bool value, Function(bool) onChanged) {
    return Row(children: [
      Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: const Color(0xFF4DB6AC),
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: Colors.black12),
      const Spacer(),
      Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(title,
            textAlign: TextAlign.right,
            style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.bold)),
        if (subtitle.isNotEmpty)
          Text(subtitle,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.black38, fontSize: 10))
      ]))
    ]);
  }

  Widget _buildLevelOption() {
    return Row(children: [
      Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
            icon: const Icon(Icons.arrow_left,
                color: Color(0xFF4DB6AC), size: 30),
            onPressed: () => setState(
                () => _tempLevel = _tempLevel > 1 ? _tempLevel - 1 : 1)),
        Text('$_tempLevel',
            style: const TextStyle(
                color: Color(0xFF4DB6AC),
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        IconButton(
            icon: const Icon(Icons.arrow_right,
                color: Color(0xFF4DB6AC), size: 30),
            onPressed: () => setState(
                () => _tempLevel = _tempLevel < 100 ? _tempLevel + 1 : 100))
      ]),
      const Spacer(),
      const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('للمستخدمين الذين يقل مستواهم عن',
            textAlign: TextAlign.right,
            style: TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.bold)),
        Text('المستوى المطلوب',
            textAlign: TextAlign.right,
            style: TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.bold))
      ]))
    ]);
  }

  void _saveRestrictions() async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .update({
        'muteChat': _tempMuteChat,
        'mutePublic': _tempMutePublic,
        'minLevelRequired': _tempLevel
      });
      widget.onSave(_tempMuteChat, _tempMutePublic, _tempLevel);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('فشل في حفظ القيود ❌')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}

class _PenaltyLogsScreen extends StatefulWidget {
  final String roomId;
  const _PenaltyLogsScreen({required this.roomId});

  @override
  State<_PenaltyLogsScreen> createState() => _PenaltyLogsScreenState();
}

class _PenaltyLogsScreenState extends State<_PenaltyLogsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
          color: Color(0xFFE0F2F1),
          borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            decoration: const BoxDecoration(
                color: Color(0xFF1B5E20),
                borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context)),
                  const Text('تسجيلات عملية العقوبات',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 48)
                ]),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(children: [
              Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                      color: Color(0xFF2E7D32), shape: BoxShape.circle),
                  child:
                      const Icon(Icons.search, color: Colors.white, size: 20)),
              const SizedBox(width: 10),
              Expanded(
                  child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20)),
                      child: TextField(
                          style: const TextStyle(fontSize: 14),
                          onChanged: (v) => setState(() => _searchQuery = v),
                          decoration: const InputDecoration(
                              hintText: 'ابحث عن اسم',
                              hintStyle: TextStyle(
                                  color: Colors.black26, fontSize: 12),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 10))))),
            ]),
          ),
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF1B5E20),
            unselectedLabelColor: Colors.black38,
            indicatorColor: const Color(0xFF1B5E20),
            indicatorWeight: 3,
            labelStyle:
                const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'طرد'),
              Tab(text: 'إصمات'),
              Tab(text: 'حظر')
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLogList('kick'),
                _buildLogList('silence'),
                _buildLogList('ban'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogList(String type) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .collection('penalty_logs')
          .where('type', isEqualTo: type)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final logs = snapshot.data!.docs;
        if (logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                    width: 120,
                    height: 120,
                    decoration: const BoxDecoration(
                        color: Color(0xFFB2DFDB), shape: BoxShape.circle),
                    child: const Icon(Icons.sentiment_satisfied_alt,
                        size: 80, color: Color(0xFF00695C))),
                const SizedBox(height: 15),
                const Text('لا يوجد تسجيلات عقوبات',
                    style: TextStyle(color: Colors.black26, fontSize: 14)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final logData = logs[index].data() as Map<String, dynamic>;
            final adminName = logData['adminName'] ?? 'الإدارة';
            final userName = logData['userName'] ?? 'مستخدم';
            final timestamp = logData['timestamp'] as Timestamp?;
            final reason = logData['reason'] ?? 'بدون سبب';

            if (_searchQuery.isNotEmpty && !userName.contains(_searchQuery)) {
              return const SizedBox.shrink();
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                leading: CircleAvatar(
                    backgroundColor: _getColorForType(type),
                    child: Icon(_getIconForType(type),
                        color: Colors.white, size: 18)),
                title: Text('$adminName ➜ $userName',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('السبب: $reason',
                        style: const TextStyle(
                            fontSize: 11, color: Colors.black54)),
                    if (timestamp != null)
                      Text(timestamp.toDate().toString().split('.')[0],
                          style: const TextStyle(
                              fontSize: 10, color: Colors.black38)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'kick':
        return Colors.orange;
      case 'silence':
        return Colors.blueGrey;
      case 'ban':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'kick':
        return Icons.logout;
      case 'silence':
        return Icons.mic_off;
      case 'ban':
        return Icons.block;
      default:
        return Icons.history;
    }
  }
}

class _ModeratorPermissionsScreen extends StatefulWidget {
  final String roomId;
  const _ModeratorPermissionsScreen({required this.roomId});

  @override
  State<_ModeratorPermissionsScreen> createState() =>
      _ModeratorPermissionsScreenState();
}

class _ModeratorPermissionsScreenState
    extends State<_ModeratorPermissionsScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFFE0F2F1), // Mint background
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            decoration: const BoxDecoration(
              color: Color(0xFF1B5E20), // Dark Green
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context)),
                const Text('صلاحيات المشرف',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rooms')
                  .doc(widget.roomId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final roomData =
                    snapshot.data!.data() as Map<String, dynamic>? ?? {};
                final perms =
                    roomData['moderatorPermissions'] as Map<String, dynamic>? ??
                        {};

                return ListView(
                  padding: const EdgeInsets.all(15),
                  children: [
                    // Section 1: Activity Management
                    _buildPermissionContainer([
                      _buildPermissionSwitch(
                          'السماح للمشرف بإدارة معاينة النشاط',
                          perms['canManageActivities'] ?? false,
                          (v) => _updatePerm('canManageActivities', v)),
                    ]),
                    const SizedBox(height: 15),
                    // Section 2: Games
                    _buildPermissionContainer([
                      _buildPermissionSwitch(
                          'السماح للمشرف ببدء لعبة تيك تاك تو',
                          perms['canStartTicTacToe'] ?? false,
                          (v) => _updatePerm('canStartTicTacToe', v)),
                      _buildDivider(),
                      _buildPermissionSwitch(
                          'السماح للمشرف ببدء لوحة نجوم الهدايا ⭐',
                          perms['canStartPointsBoard'] ?? false,
                          (v) => _updatePerm('canStartPointsBoard', v)),
                      _buildDivider(),
                      _buildPermissionSwitch(
                          'السماح للمشرف ببدء "أنت تقول، أنا أخمن"',
                          perms['canStartGuessGame'] ?? false,
                          (v) => _updatePerm('canStartGuessGame', v)),
                      _buildDivider(),
                      _buildPermissionSwitch(
                          'السماح للمشرف ببدء سحب الحظ',
                          perms['canStartLuckyDraw'] ?? false,
                          (v) => _updatePerm('canStartLuckyDraw', v)),
                      _buildDivider(),
                      _buildPermissionSwitch(
                          'السماح للمشرف باستخدام الساعة',
                          perms['canUseClock'] ?? false,
                          (v) => _updatePerm('canUseClock', v)),
                      _buildDivider(),
                      _buildPermissionSwitch(
                          'السماح للمشرف ببدء التصويت',
                          perms['canStartVoting'] ?? false,
                          (v) => _updatePerm('canStartVoting', v)),
                      _buildDivider(),
                      _buildPermissionSwitch(
                          'السماح للمشرف ببدء لعبة حرب الفواكه',
                          perms['canStartFruitWar'] ?? false,
                          (v) => _updatePerm('canStartFruitWar', v)),
                      _buildDivider(),
                      _buildPermissionSwitch(
                          'السماح للمشرف ببدء نقل القنبلة',
                          perms['canStartBombTransfer'] ?? false,
                          (v) => _updatePerm('canStartBombTransfer', v)),
                      _buildDivider(),
                      _buildPermissionSwitch(
                          'السماح للمشرف ببدء لعبة طبيب أسنان التمساح',
                          perms['canStartCrocodileGame'] ?? false,
                          (v) => _updatePerm('canStartCrocodileGame', v)),
                      _buildDivider(),
                      _buildPermissionSwitch(
                          'السماح للمشرف بفتح صندوق المفاجآت',
                          perms['canOpenSurpriseBox'] ?? false,
                          (v) => _updatePerm('canOpenSurpriseBox', v)),
                    ]),
                    const SizedBox(height: 15),
                    // Section 3: Room Controls
                    _buildPermissionContainer([
                      _buildPermissionSwitch(
                          'السماح للمشرف بقفل/ فتح المايك',
                          perms['canManageMic'] ?? false,
                          (v) => _updatePerm('canManageMic', v)),
                      _buildDivider(),
                      _buildPermissionSwitch(
                          'السماح للمشرف بفتح المعركة وإنهائها',
                          perms['canManageBattle'] ?? false,
                          (v) => _updatePerm('canManageBattle', v)),
                      _buildDivider(),
                      _buildPermissionSwitch(
                          'السماح للمشرف بقفل وفتح الغرفة',
                          perms['canLockRoom'] ?? false,
                          (v) => _updatePerm('canLockRoom', v)),
                      _buildDivider(),
                      _buildPermissionSwitch(
                          'صلاحية الإصمات وفك الإصمات',
                          perms['canMute'] ?? false,
                          (v) => _updatePerm('canMute', v)),
                      _buildDivider(),
                      _buildPermissionSwitch(
                          'صلاحية حظر المستخدمين',
                          perms['canBan'] ?? false,
                          (v) => _updatePerm('canBan', v)),
                      _buildDivider(),
                      _buildPermissionSwitch(
                          'صلاحية إيقاع العقوبة',
                          perms['canPenalty'] ?? false,
                          (v) => _updatePerm('canPenalty', v)),
                      _buildDivider(),
                      _buildPermissionSwitch(
                          'صلاحية طرد الأعضاء',
                          perms['canKick'] ?? false,
                          (v) => _updatePerm('canKick', v)),
                    ]),
                    const SizedBox(height: 30),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildPermissionSwitch(
      String title, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: Row(
        children: [
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: Colors.white,
              activeTrackColor: Colors.greenAccent,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: Colors.grey[300],
            ),
          ),
          const Spacer(),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF1B5E20),
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: Divider(color: Colors.black12, height: 1, thickness: 0.5),
    );
  }

  void _updatePerm(String key, bool val) async {
    await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .set({
      'moderatorPermissions': {key: val}
    }, SetOptions(merge: true));
  }
}
