import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'battle_setup_sheet.dart';
import 'room_theme_shop_sheet.dart';
import 'room_settings_sheet.dart';
import 'room_earnings_sheet.dart';
import '../../store_page.dart';

class RoomMoreMenuSheet extends StatefulWidget {
  final String roomId;
  final String roomName;
  final String? roomImage;
  final String? ownerId;
  final bool hasPower;
  final bool isBattleActive;
  final String micMode;
  final bool noiseReduction;
  final bool eyeComfort;
  final Function(bool) onNoiseReductionChanged;
  final Function(bool) onEyeComfortChanged;
  final VoidCallback onEndBattle;
  final VoidCallback? onFixAudio;
  final List<Widget>? extraWidgets;
  final VoidCallback? onShowLeaderboard; // إضافة الكولباك هنا

  const RoomMoreMenuSheet({
    super.key,
    required this.roomId,
    required this.roomName,
    this.roomImage,
    this.ownerId,
    required this.hasPower,
    required this.isBattleActive,
    required this.micMode,
    required this.noiseReduction,
    required this.eyeComfort,
    required this.onNoiseReductionChanged,
    required this.onEyeComfortChanged,
    required this.onEndBattle,
    this.onFixAudio,
    this.extraWidgets,
    this.onShowLeaderboard, // إضافة الكولباك هنا
  });

  @override
  State<RoomMoreMenuSheet> createState() => _RoomMoreMenuSheetState();
}

class _RoomMoreMenuSheetState extends State<RoomMoreMenuSheet> {
  late bool _localNoise;
  late bool _localEye;
  String? _roomPassword;
  late String _selectedMicMode;

  @override
  void initState() {
    super.initState();
    _localNoise = widget.noiseReduction;
    _localEye = widget.eyeComfort;
    _selectedMicMode = widget.micMode;
    _fetchRoomData();
  }

  void _fetchRoomData() async {
    final doc = await FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .get();
    if (doc.exists) {
      if (mounted) {
        setState(() {
          _roomPassword = doc.data()?['password'];
        });
      }
    }
  }

  void _showMicModesMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Color(0xFF0F1B25),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              border:
                  Border(top: BorderSide(color: Colors.cyanAccent, width: 0.5)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 15),
                const Text('نمط المايكات',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.count(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    crossAxisCount: 2,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15,
                    childAspectRatio: 1.1,
                    children: [
                      _buildModeCard(
                          setModalState, 'دردشة - 5 مايكات', 'chat-5', [5]),
                      _buildModeCard(setModalState, 'بث - 5 مايكات',
                          'broadcast-5', [1, 4]),
                      _buildMicCard(
                          setModalState, 'دردشة - 10 مايكات', 'normal', [5, 5]),
                      _buildMicCard(setModalState, 'فريق - 10 مايكات', '2-4-4',
                          [2, 4, 4]),
                      _buildMicCard(setModalState, 'بث - 11 مايك',
                          'broadcast-11', [1, 4, 6]),
                      _buildMicCard(setModalState, 'دردشة - 15 مايك', 'chat-15',
                          [5, 5, 5],
                          isLocked: true),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(25),
                  child: SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)),
                        elevation: 10,
                        shadowColor: Colors.amber.withValues(alpha: 0.5),
                      ),
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('rooms')
                            .doc(widget.roomId)
                            .update({'micMode': _selectedMicMode});
                        if (mounted) Navigator.pop(context);
                      },
                      child: const Text('تأكيد',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _buildModeCard(
      StateSetter setModalState, String title, String mode, List<int> rows,
      {bool isLocked = false}) {
    bool isSelected = _selectedMicMode == mode;
    return GestureDetector(
      onTap:
          isLocked ? null : () => setModalState(() => _selectedMicMode = mode),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black26,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
              color: isSelected ? Colors.greenAccent : Colors.white10,
              width: 2),
        ),
        child: Stack(
          children: [
            if (isSelected)
              const Positioned(
                  top: 5,
                  right: 5,
                  child: Icon(Icons.check_circle,
                      color: Colors.greenAccent, size: 20)),
            if (isLocked)
              const Positioned(
                  top: 5,
                  right: 5,
                  child: Icon(Icons.lock, color: Colors.white24, size: 18)),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                Text(title,
                    style: TextStyle(
                        color: isLocked ? Colors.white24 : Colors.white70,
                        fontSize: 12)),
                const SizedBox(height: 15),
                Column(
                  children: rows
                      .map((count) => Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                                count,
                                (index) => Container(
                                      width: 8,
                                      height: 8,
                                      margin: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: isLocked
                                            ? Colors.white10
                                            : (isSelected
                                                ? Colors.greenAccent
                                                : Colors.white38),
                                        shape: BoxShape.circle,
                                      ),
                                    )),
                          ))
                      .toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // دالة مكررة لتجنب الأخطاء
  Widget _buildMicCard(
          StateSetter setModalState, String title, String mode, List<int> rows,
          {bool isLocked = false}) =>
      _buildModeCard(setModalState, title, mode, rows, isLocked: isLocked);

  void _shareRoom() {
    final String shareText = '''
🔥 انضم الآن إلى غرفة "${widget.roomName}" في رويال دور!
🎙️ دردشة صوتية، هدايا، ومعارك حماسية PK.

✅ إذا كان لديك التطبيق، انقر للولوج مباشرة:
royaldoor://room/${widget.roomId}

📥 إذا لم يكن لديك التطبيق، حمله الآن من هنا:
https://play.google.com/store/apps/details?id=com.royaldoor.live
''';
    Share.share(shareText, subject: 'دعوة للانضمام إلى رويال دور 👑');
  }

  void _showLockRoomDialog() {
    final controller = TextEditingController(text: _roomPassword);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A242F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('قفل الغرفة بنمط ملكي',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'أدخل رقم سري لمنع الدخول غير المصرح به، اتركه فارغاً لفتح الغرفة.',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                  fontSize: 20),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '----',
                hintStyle: const TextStyle(color: Colors.white24),
                enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.amber),
                    borderRadius: BorderRadius.circular(15)),
                focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.amber, width: 2),
                    borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text('إلغاء', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15))),
            onPressed: () async {
              String pass = controller.text.trim();
              await FirebaseFirestore.instance
                  .collection('rooms')
                  .doc(widget.roomId)
                  .update({
                'password': pass.isEmpty ? null : pass,
              });
              setState(() {
                _roomPassword = pass.isEmpty ? null : pass;
              });
              if (mounted) Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(pass.isEmpty
                      ? 'تم فتح الغرفة 🔓'
                      : 'تم قفل الغرفة بنجاح 🔒')));
            },
            child: const Text('حفظ',
                style: TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _callMembers() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A242F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('استدعاء ملكي',
            style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        content: const Text(
            'هل تريد إرسال نداء لجميع الأعضاء والمنظمين للانضمام إلى الغرفة الآن؟',
            style: TextStyle(color: Colors.white70, fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child:
                  const Text('إلغاء', style: TextStyle(color: Colors.white54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إرسال النداء',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final membersSnap = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .collection('members')
          .get();
      final batch = FirebaseFirestore.instance.batch();
      final currentUserName =
          FirebaseAuth.instance.currentUser?.displayName ?? 'المالك';

      for (var doc in membersSnap.docs) {
        if (doc.id == FirebaseAuth.instance.currentUser?.uid) continue;
        final notifRef = FirebaseFirestore.instance
            .collection('users')
            .doc(doc.id)
            .collection('notifications')
            .doc();
        batch.set(notifRef, {
          'type': 'room_call',
          'roomId': widget.roomId,
          'roomName': widget.roomName,
          'senderName': currentUserName,
          'timestamp': FieldValue.serverTimestamp(),
          'message':
              'يدعوكم للانضمام إلى غرفة ${widget.roomName} 🎙️ أسرعوا بالحضور!',
        });
      }
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('تم إرسال النداء الملكي لجميع الأعضاء 📢'),
            backgroundColor: Colors.orange));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('فشل إرسال النداء ❌'),
            backgroundColor: Colors.redAccent));
      }
    }
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          RoomSettingsSheet(roomId: widget.roomId, hasPower: widget.hasPower),
    );
  }

  void _showEarningsMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RoomEarningsSheet(roomId: widget.roomId),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isBattle = widget.isBattleActive;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F1B25),
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2)),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _quickActionItem(Icons.card_giftcard, 'إعدادات الهدايا',
                            Colors.cyan),
                        _quickActionItem(
                            Icons.graphic_eq, 'تقليل الضوضاء', Colors.teal,
                            hasSwitch: true,
                            switchVal: _localNoise, onChanged: (v) {
                          setState(() => _localNoise = v);
                          widget.onNoiseReductionChanged(v);
                        }),
                        _quickActionItem(
                            Icons.mic_none, 'مشكلات الصوت', Colors.cyan,
                            onTap: () {
                          Navigator.pop(context);
                          if (widget.onFixAudio != null) widget.onFixAudio!();
                        }),
                        _quickActionItem(Icons.reply, 'مشاركة', Colors.blueGrey,
                            onTap: _shareRoom),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 80,
                        margin: const EdgeInsets.only(left: 10),
                        child: _quickActionItem(
                            Icons.nightlight_round, 'راحة العين', Colors.blue,
                            hasSwitch: true,
                            switchVal: _localEye, onChanged: (v) {
                          setState(() => _localEye = v);
                          widget.onEyeComfortChanged(v);
                        }),
                      ),
                    ),
                    const SizedBox(height: 15),
                    if (widget.extraWidgets != null) ...widget.extraWidgets!,
                    const SizedBox(height: 15),
                    _sectionHeader('إعدادات الغرفة'),
                    const SizedBox(height: 15),
                    GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 10,
                      children: [
                        if (widget.hasPower)
                          _buildGridItem(
                              Icons.mic, 'نمط المايكات', Colors.orange,
                              onTap: () {
                            Navigator.pop(context);
                            _showMicModesMenu();
                          }),
                        _buildGridItem(
                            isBattle ? Icons.flash_off : Icons.flash_on,
                            isBattle ? 'إنهاء المعركة' : 'معركة الفريق',
                            isBattle ? Colors.red : Colors.blue, onTap: () {
                          Navigator.pop(context);
                          if (isBattle) {
                            widget.onEndBattle();
                          } else {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) =>
                                  BattleSetupSheet(roomId: widget.roomId),
                            );
                          }
                        }),
                        if (widget.hasPower)
                          _buildGridItem(
                              _roomPassword != null
                                  ? Icons.lock
                                  : Icons.lock_open,
                              _roomPassword != null
                                  ? 'الغرفة مقفلة'
                                  : 'قفل الغرفة',
                              Colors.amber, onTap: () {
                            Navigator.pop(context);
                            _showLockRoomDialog();
                          }),
                        _buildGridItem(Icons.brush, 'موضوع', Colors.brown,
                            onTap: () {
                          Navigator.pop(context);
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) =>
                                RoomThemeShopSheet(roomId: widget.roomId),
                          );
                        }),
                        if (widget.hasPower)
                          _buildGridItem(
                              Icons.settings, 'الإعدادات', Colors.purple,
                              onTap: () {
                            Navigator.pop(context);
                            _showSettingsMenu();
                          }),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _sectionHeader('أخرى'),
                    const SizedBox(height: 15),
                    GridView.count(
                      crossAxisCount: 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 20,
                      crossAxisSpacing: 10,
                      children: [
                        _buildGridItem(
                            Icons.emoji_events, 'متصدر الدعم', Colors.amber,
                            onTap: () {
                          Navigator.pop(context);
                          if (widget.onShowLeaderboard != null) {
                            widget.onShowLeaderboard!();
                          }
                        }), // الزر الجديد هنا
                        _buildGridItem(
                            Icons.campaign, 'استدعاء الأعضاء', Colors.orange,
                            onTap: () {
                          if (widget.hasPower) {
                            _callMembers();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'عذراً، هذا الخيار للمشرفين فقط 👑')));
                          }
                        }),
                        _buildGridItem(
                            Icons.thumb_up, 'توصية للأصدقاء', Colors.pink,
                            onTap: _shareRoom),
                        _buildGridItem(
                            Icons.shopping_cart, 'المتجر', Colors.blue,
                            onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const StorePage()));
                        }),
                        _buildGridItem(Icons.inventory_2, 'مكافآتي', Colors.red,
                            onTap: () {
                          Navigator.pop(context);
                          _showEarningsMenu();
                        }),
                        _buildGridItem(Icons.report_problem_outlined, 'إبلاغ',
                            Colors.orange, onTap: () async {
                          Navigator.pop(context);
                          await FirebaseFirestore.instance
                              .collection('reports')
                              .add({
                            'reporterId':
                                FirebaseAuth.instance.currentUser?.uid,
                            'targetId': widget.roomId,
                            'type': 'room',
                            'reason': 'User report from room menu',
                            'content': 'Room: ${widget.roomName}',
                            'timestamp': FieldValue.serverTimestamp(),
                            'status': 'pending',
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        'تم إرسال بلاغ عن هذه الغرفة للإدارة 🛡️')));
                          }
                        }),
                      ],
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGridItem(IconData icon, String label, Color color,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: color.withValues(alpha: 0.3))),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Flexible(
              child: Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 10))),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 15),
        decoration: BoxDecoration(
          color: const Color(0xFF1A3B4F).withValues(alpha: 0.8),
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(5), bottomLeft: Radius.circular(5)),
        ),
        child: Text(title,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            textAlign: TextAlign.right),
      );

  Widget _quickActionItem(IconData icon, String label, Color color,
          {bool hasSwitch = false,
          bool switchVal = false,
          Function(bool)? onChanged,
          VoidCallback? onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: color.withValues(alpha: 0.5), width: 1)),
                      child: Icon(icon, color: color, size: 28)),
                  if (hasSwitch)
                    Positioned(
                        bottom: -15,
                        child: Transform.scale(
                            scale: 0.6,
                            child: Switch(
                                value: switchVal,
                                onChanged: onChanged,
                                activeThumbColor: Colors.green))),
                ]),
            const SizedBox(height: 15),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
                textAlign: TextAlign.center),
          ],
        ),
      );
}
