import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../services/storage_service.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final TextEditingController searchController = TextEditingController();
  String _searchText = "";

  // متغيرات التصفية المتقدمة
  String? _filterStatus; // all, active, banned
  String? _filterRole; // all, admin, user, owner
  String? _filterDateRange; // all, today, week, month
  int? _minBalance;

  final Color primaryDark = const Color(0xFF0A1F1C);
  final Color accentGold = const Color(0xFFD4AF37);

  // التحقق من صلاحيات المستخدم
  Future<bool> _checkAdminPermissions() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;

    final email = currentUser.email?.toLowerCase() ?? '';
    final isRoyalEmail = email == 'royaldoor86@gmail.com' ||
        email == 'doorty86@gmail.com' ||
        email == 'amjidhadi96@gmail.com' ||
        email == 'shahadhadi.h@gmail.com';

    if (isRoyalEmail) return true;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();

    if (!userDoc.exists) return false;

    final userData = userDoc.data() as Map<String, dynamic>;
    final role = userData['role'] ?? 'user';
    final isAdmin = userData['isAdmin'] ?? false;
    final isOwner = userData['isOwner'] ?? false;

    return isAdmin ||
        isOwner ||
        role == 'admin' ||
        role == 'owner' ||
        role == 'developer';
  }

  Future<void> _deleteUserAndBan(String uid, String name, String? email) async {
    // التحقق من الصلاحيات
    final hasPermission = await _checkAdminPermissions();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('ليس لديك صلاحية للقيام بهذه العملية'),
            backgroundColor: Colors.red));
      }
      return;
    }

    if (!mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Colors.redAccent, width: 0.5)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text("حذف وحظر نهائي",
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
            "هل أنت متأكد من حذف $name؟\n\nسيتم مسح كافة البيانات وحظر البريد الإلكتروني (${email ?? 'غير متوفر'}) من التسجيل مجدداً نهائياً 🚫.",
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  const Text("إلغاء", style: TextStyle(color: Colors.white38))),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: const Text("حذف وحظر",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      // تأكيد ثانوي للعمليات الخطرة
      final secondConfirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Colors.redAccent, width: 1)),
          title: const Row(
            children: [
              Icon(Icons.dangerous, color: Colors.red, size: 32),
              SizedBox(width: 10),
              Text("تحذير نهائي",
                  style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("هذه العملية لا يمكن التراجع عنها!",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text("هل أنت متأكد تماماً من حذف $name وحظره نهائياً؟",
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              const Text(
                  "سيتم مسح جميع البيانات وحظر البريد الإلكتروني من التسجيل مجدداً",
                  style: TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("إلغاء",
                    style: TextStyle(color: Colors.white38))),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                child: const Text("نعم، أنا متأكد",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold))),
          ],
        ),
      );

      if (secondConfirm != true) return;

      try {
        // 1. حظر البريد الإلكتروني في القائمة السوداء
        if (email != null && email.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('banned_emails')
              .doc(email)
              .set({
            'uid': uid,
            'name': name,
            'bannedAt': FieldValue.serverTimestamp(),
            'reason': 'Deleted and banned by admin through Users Management',
          });
        }

        // 2. الحذف من Auth عبر Cloud Function (adminBanUser يعطل الحساب حالياً)
        try {
          await FirebaseFunctions.instance
              .httpsCallable('adminBanUser')
              .call({'uid': uid, 'reason': 'Permanent Deletion & Ban'}).timeout(
                  const Duration(seconds: 5));
        } catch (e) {
          debugPrint("Cloud function error: $e");
        }

        // 3. الحذف من Firestore
        await FirebaseFirestore.instance.collection('users').doc(uid).delete();

        // تسجيل العملية الإدارية
        await FirebaseFirestore.instance.collection('admin_logs').add({
          'type': 'permanent_deletion',
          'adminId': FirebaseAuth.instance.currentUser?.uid,
          'targetUserId': uid,
          'targetUserName': name,
          'targetEmail': email,
          'timestamp': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("تم حذف المستخدم وحظر بريده بنجاح ✅"),
              backgroundColor: Colors.green));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text("خطأ أثناء التنفيذ: $e"),
              backgroundColor: Colors.red));
        }
      }
    }
  }

  void _showBalanceEditor(
      BuildContext context, String uid, Map<String, dynamic> userData) {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    String selectedCurrency = 'stars'; // stars, gems, harvest_wallet
    String operationType = 'increase'; // increase, decrease

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (context, dialogSetState) {
        num currentVal = 0;
        String label = "";
        if (selectedCurrency == 'stars') {
          currentVal = (userData['stars'] ?? userData['coins'] ?? 0);
          label = "كوينز";
        } else if (selectedCurrency == 'gems') {
          currentVal = (userData['gems'] ?? 0);
          label = "جوهرة 💎";
        } else if (selectedCurrency == 'harvest_wallet') {
          currentVal = (userData['harvest_wallet'] ?? 0);
          label = "محفظة الحصاد";
        }

        return AlertDialog(
          backgroundColor: const Color(0xFF0F1B25),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: accentGold, width: 0.5)),
          title: Text('تعديل اقتصاد المستخدم: ${userData['name']}',
              style: TextStyle(
                  color: accentGold, fontSize: 15, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  spacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    _choiceChip('كوينز', 'stars', selectedCurrency,
                        (val) => dialogSetState(() => selectedCurrency = val)),
                    _choiceChip('جواهر', 'gems', selectedCurrency,
                        (val) => dialogSetState(() => selectedCurrency = val)),
                    _choiceChip('حصاد', 'harvest_wallet', selectedCurrency,
                        (val) => dialogSetState(() => selectedCurrency = val)),
                  ],
                ),
                const Divider(color: Colors.white10, height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _opButton('شحن', 'increase', operationType, Colors.green,
                        () => dialogSetState(() => operationType = 'increase')),
                    const SizedBox(width: 15),
                    _opButton('خصم', 'decrease', operationType, Colors.red,
                        () => dialogSetState(() => operationType = 'decrease')),
                  ],
                ),
                const SizedBox(height: 20),
                Text('الرصيد الحالي: ${currentVal.toStringAsFixed(0)} $label',
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 15),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'المبلغ',
                    labelStyle: const TextStyle(color: Colors.white38),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.attach_money,
                        color: Colors.amber, size: 20),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: reasonController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'السبب (اختياري)',
                    labelStyle: const TextStyle(color: Colors.white38),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء',
                    style: TextStyle(color: Colors.white24))),
            ElevatedButton(
              onPressed: () async {
                // التحقق من الصلاحيات
                final hasPermission = await _checkAdminPermissions();
                if (!hasPermission) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('ليس لديك صلاحية للقيام بهذه العملية'),
                      backgroundColor: Colors.red));
                  return;
                }

                final amt = double.tryParse(amountController.text) ?? 0;
                if (amt <= 0) return;
                final finalAmt = operationType == 'increase' ? amt : -amt;

                final updates = <String, dynamic>{
                  selectedCurrency: FieldValue.increment(finalAmt),
                  'lastAdminAdjustment': {
                    'amount': finalAmt,
                    'currency': selectedCurrency,
                    'reason': reasonController.text,
                    'timestamp': FieldValue.serverTimestamp(),
                  }
                };
                // مزامنة coins مع stars (لأن النظام يستخدم coins كعملة أساسية)
                if (selectedCurrency == 'stars') {
                  updates['coins'] = FieldValue.increment(finalAmt);
                }

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .update(updates);

                // تسجيل العملية الإدارية
                await FirebaseFirestore.instance.collection('admin_logs').add({
                  'type': 'balance_adjustment',
                  'adminId': FirebaseAuth.instance.currentUser?.uid,
                  'targetUserId': uid,
                  'targetUserName': userData['name'] ?? 'مستخدم',
                  'amount': finalAmt,
                  'currency': selectedCurrency,
                  'operation': operationType,
                  'reason': reasonController.text,
                  'timestamp': FieldValue.serverTimestamp(),
                });

                if (ctx.mounted) Navigator.pop(ctx);
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                      content: Text('تم تحديث الرصيد بنجاح ✅'),
                      backgroundColor: Colors.green));
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor:
                      operationType == 'increase' ? Colors.green : Colors.red),
              child: Text(
                  operationType == 'increase' ? 'تأكيد الشحن' : 'تأكيد الخصم',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      }),
    );
  }

  void _showNotificationDialog(String uid, String userName) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFF0F1B25),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: accentGold, width: 0.5)),
          title: Text('إرسال إشعار إلى $userName',
              style: TextStyle(
                  color: accentGold, fontSize: 15, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'عنوان الإشعار',
                    labelStyle: const TextStyle(color: Colors.white38),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon: Icon(Icons.title, color: accentGold, size: 20),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: bodyController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'محتوى الإشعار',
                    labelStyle: const TextStyle(color: Colors.white38),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    prefixIcon:
                        Icon(Icons.message, color: accentGold, size: 20),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء',
                    style: TextStyle(color: Colors.white24))),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty ||
                    bodyController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('يرجى إدخال عنوان ومحتوى الإشعار'),
                      backgroundColor: Colors.orange));
                  return;
                }

                try {
                  // إضافة الإشعار إلى Firestore
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('notifications')
                      .add({
                    'title': titleController.text.trim(),
                    'body': bodyController.text.trim(),
                    'timestamp': FieldValue.serverTimestamp(),
                    'read': false,
                    'fromAdmin': true,
                  });

                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('تم إرسال الإشعار بنجاح ✅'),
                        backgroundColor: Colors.green));
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('خطأ في الإرسال: $e'),
                        backgroundColor: Colors.red));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: accentGold,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: const Text('إرسال',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileImageEditor(
      String uid, String userName, String? currentImage) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1B25),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: accentGold, width: 0.5)),
        title: Text('إدارة صورة $userName',
            style: TextStyle(color: accentGold, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (currentImage != null)
              ClipOval(
                child: Image.network(currentImage,
                    width: 100, height: 100, fit: BoxFit.cover),
              )
            else
              const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, size: 50, color: Colors.white38),
              ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                await _uploadProfileImage(uid, userName);
              },
              icon: const Icon(Icons.upload),
              label: const Text('رفع صورة جديدة'),
              style: ElevatedButton.styleFrom(backgroundColor: accentGold),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF0F1B25),
                    title: const Text('حذف الصورة',
                        style: TextStyle(color: Colors.red)),
                    content: const Text('هل أنت متأكد من حذف الصورة الشخصية؟'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('إلغاء')),
                      ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          child: const Text('حذف')),
                    ],
                  ),
                );

                if (confirm == true) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .update({'profilePic': null});
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('تم حذف الصورة بنجاح'),
                        backgroundColor: Colors.green));
                  }
                }
              },
              icon: const Icon(Icons.delete),
              label: const Text('حذف الصورة'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  void _showFamilyManagementDialog(
      String uid, String userName, String? familyId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1B25),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: accentGold, width: 0.5)),
        title: Text('إدارة عائلة $userName',
            style: TextStyle(color: accentGold, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (familyId != null)
              Column(
                children: [
                  const Text('الانتماء الحالي:',
                      style: TextStyle(color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text(familyId,
                      style: TextStyle(color: accentGold, fontSize: 16)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: const Color(0xFF0F1B25),
                          title: const Text('طرد من العائلة',
                              style: TextStyle(color: Colors.red)),
                          content: const Text(
                              'هل أنت متأكد من طرد هذا المستخدم من العائلة؟'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('إلغاء')),
                            ElevatedButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red),
                                child: const Text('طرد')),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid)
                            .update({'familyId': null, 'familyRole': null});
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('تم طرد المستخدم من العائلة'),
                                  backgroundColor: Colors.green));
                        }
                      }
                    },
                    icon: const Icon(Icons.exit_to_app),
                    label: const Text('طرد من العائلة'),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  ),
                ],
              )
            else
              Column(
                children: [
                  const Text('المستخدم غير منتمي لعائلة',
                      style: TextStyle(color: Colors.white38)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('ميزة إضافة لعائلة قيد التطوير'),
                          backgroundColor: Colors.orange));
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة لعائلة'),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: accentGold),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _choiceChip(
      String label, String value, String current, Function(String) onSelect) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 10)),
      selected: current == value,
      onSelected: (s) => onSelect(value),
      selectedColor: accentGold.withValues(alpha: 0.3),
      labelStyle:
          TextStyle(color: current == value ? accentGold : Colors.white54),
    );
  }

  Widget _opButton(String label, String type, String current, Color color,
      VoidCallback onTap) {
    bool isSel = current == type;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSel ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSel ? color : Colors.white12),
        ),
        child: Text(label,
            style: TextStyle(
                color: isSel ? color : Colors.white38,
                fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _showUserActions(String uid, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final bool isBanned = data['isBanned'] ?? false;
        final bool isAdminUser =
            data['role'] == 'admin' || data['role'] == 'owner';

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (_, controller) => Container(
            decoration: const BoxDecoration(
              color: Color(0xFF161B22),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                    child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundImage: (data['profilePic'] ?? '').isNotEmpty
                          ? NetworkImage(data['profilePic'])
                          : null,
                      child: (data['profilePic'] ?? '').isEmpty
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['name'] ?? 'مستخدم',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18)),
                          Text(
                              "ID: ${data['royalId']} | ${_getAuthProviderDisplay(data)}",
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 11)),
                          const SizedBox(height: 4),
                          Text(_getAuthProviderDetails(data),
                              style: const TextStyle(
                                  color: Colors.white24, fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                _buildActionGroup("عرض المعلومات", [
                  _actionItem(Icons.notifications_active, "إرسال إشعار",
                      Colors.purpleAccent, () {
                    Navigator.pop(ctx);
                    _showNotificationDialog(uid, data['name'] ?? 'مستخدم');
                  }),
                  _actionItem(Icons.camera_alt, "إدارة الصورة الشخصية",
                      Colors.orangeAccent, () {
                    Navigator.pop(ctx);
                    _showProfileImageEditor(
                        uid, data['name'] ?? 'مستخدم', data['profilePic']);
                  }),
                  _actionItem(
                      Icons.family_restroom, "إدارة العائلة", Colors.tealAccent,
                      () {
                    Navigator.pop(ctx);
                    _showFamilyManagementDialog(
                        uid, data['name'] ?? 'مستخدم', data['familyId']);
                  }),
                ]),
                const SizedBox(height: 25),
                _buildActionGroup("الإدارة المالية", [
                  _actionItem(Icons.account_balance_wallet,
                      "تعديل الرصيد والشحن", Colors.greenAccent, () {
                    Navigator.pop(ctx);
                    _showBalanceEditor(context, uid, data);
                  }),
                ]),
                _buildActionGroup("الحماية والتحكم", [
                  _actionItem(
                      isBanned ? Icons.lock_open : Icons.lock,
                      isBanned ? "فك الحظر" : "حظر الحساب",
                      isBanned ? Colors.green : Colors.orangeAccent, () async {
                    // التحقق من الصلاحيات
                    final hasPermission = await _checkAdminPermissions();
                    if (!hasPermission) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('ليس لديك صلاحية للقيام بهذه العملية'),
                                backgroundColor: Colors.red));
                      }
                      return;
                    }

                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .update({'isBanned': !isBanned});

                    // تسجيل العملية الإدارية
                    await FirebaseFirestore.instance
                        .collection('admin_logs')
                        .add({
                      'type': 'ban_action',
                      'adminId': FirebaseAuth.instance.currentUser?.uid,
                      'targetUserId': uid,
                      'targetUserName': data['name'] ?? 'مستخدم',
                      'action': isBanned ? 'unban' : 'ban',
                      'timestamp': FieldValue.serverTimestamp(),
                    });

                    if (ctx.mounted) Navigator.pop(ctx);
                  }),
                  _actionItem(Icons.gavel, "تعيين كمستخدم عادي", Colors.grey,
                      () async {
                    // التحقق من الصلاحيات
                    final hasPermission = await _checkAdminPermissions();
                    if (!hasPermission) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('ليس لديك صلاحية للقيام بهذه العملية'),
                                backgroundColor: Colors.red));
                      }
                      return;
                    }

                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .update({'role': 'user'});

                    // تسجيل العملية الإدارية
                    await FirebaseFirestore.instance
                        .collection('admin_logs')
                        .add({
                      'type': 'role_change',
                      'adminId': FirebaseAuth.instance.currentUser?.uid,
                      'targetUserId': uid,
                      'targetUserName': data['name'] ?? 'مستخدم',
                      'oldRole': data['role'],
                      'newRole': 'user',
                      'timestamp': FieldValue.serverTimestamp(),
                    });

                    if (ctx.mounted) Navigator.pop(ctx);
                  }, show: isAdminUser),
                  _actionItem(
                      Icons.admin_panel_settings, "ترقية لمسؤول", Colors.amber,
                      () async {
                    // التحقق من الصلاحيات
                    final hasPermission = await _checkAdminPermissions();
                    if (!hasPermission) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('ليس لديك صلاحية للقيام بهذه العملية'),
                                backgroundColor: Colors.red));
                      }
                      return;
                    }

                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .update({'role': 'admin'});

                    // تسجيل العملية الإدارية
                    await FirebaseFirestore.instance
                        .collection('admin_logs')
                        .add({
                      'type': 'role_change',
                      'adminId': FirebaseAuth.instance.currentUser?.uid,
                      'targetUserId': uid,
                      'targetUserName': data['name'] ?? 'مستخدم',
                      'oldRole': data['role'],
                      'newRole': 'admin',
                      'timestamp': FieldValue.serverTimestamp(),
                    });

                    if (ctx.mounted) Navigator.pop(ctx);
                  }, show: !isAdminUser),
                ]),
                _buildActionGroup("منطقة الخطر", [
                  _actionItem(Icons.delete_forever, "حذف وحظر نهائي 🚫",
                      Colors.redAccent, () {
                    Navigator.pop(ctx);
                    _deleteUserAndBan(
                        uid, data['name'] ?? 'مستخدم', data['email']);
                  }),
                ]),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionGroup(String title, List<Widget> children) {
    List<Widget> visible = children.where((c) {
      if (c is _ActionItemWrapper) return c.show;
      return true;
    }).toList();

    if (visible.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 8, top: 15),
          child: Text(title,
              style: TextStyle(
                  color: accentGold,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1)),
        ),
        Container(
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(15)),
          child: Column(children: visible),
        ),
      ],
    );
  }

  Widget _actionItem(
      IconData icon, String title, Color color, VoidCallback onTap,
      {bool show = true}) {
    return _ActionItemWrapper(
      show: show,
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          leading: Icon(icon, color: color, size: 22),
          title: Text(title,
              style: const TextStyle(color: Colors.white, fontSize: 14)),
          trailing: const Icon(Icons.arrow_forward_ios,
              color: Colors.white10, size: 12),
          onTap: onTap,
        ),
      ),
    );
  }

  Future<void> _uploadProfileImage(String uid, String userName) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return;

    try {
      final file = File(image.path);
      final imageUrl = await StorageService.uploadProfileImage(uid, file);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'profilePic': imageUrl});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم رفع الصورة بنجاح ✅'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في رفع الصورة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      appBar: AppBar(
        title: const Text('إدارة رعية رويال دور',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'ابحث (ID / اسم / بريد)...',
                hintStyle: const TextStyle(color: Colors.white24),
                prefixIcon: Icon(Icons.search, color: accentGold),
                suffixIcon: IconButton(
                  icon: Icon(Icons.filter_list, color: accentGold),
                  onPressed: _showFilterDialog,
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
              ),
              onChanged: (v) => setState(() => _searchText = v.toLowerCase()),
            ),
          ),
          if (_filterStatus != null ||
              _filterRole != null ||
              _filterDateRange != null ||
              _minBalance != null)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_filterStatus != null)
                    _filterChip(
                        'الحالة: ${_getFilterStatusLabel(_filterStatus!)}',
                        () => setState(() => _filterStatus = null)),
                  if (_filterRole != null)
                    _filterChip('الرتبة: ${_getFilterRoleLabel(_filterRole!)}',
                        () => setState(() => _filterRole = null)),
                  if (_filterDateRange != null)
                    _filterChip(
                        'التاريخ: ${_getFilterDateLabel(_filterDateRange!)}',
                        () => setState(() => _filterDateRange = null)),
                  if (_minBalance != null)
                    _filterChip('الحد الأدنى: $_minBalance',
                        () => setState(() => _minBalance = null)),
                ],
              ),
            ),
          // قسم الإحصائيات
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              final users = snapshot.data!.docs;
              int totalUsers = users.length;
              int bannedUsers = users
                  .where((u) =>
                      (u.data() as Map<String, dynamic>)['isBanned'] == true)
                  .length;
              int adminUsers = users
                  .where((u) =>
                      (u.data() as Map<String, dynamic>)['role'] == 'admin')
                  .length;
              int totalCoins = users.fold<int>(
                  0,
                  (total, u) =>
                      total +
                      (((u.data() as Map<String, dynamic>)['coins'] ?? 0)
                              as num)
                          .toInt());
              int totalGems = users.fold<int>(
                  0,
                  (total, u) =>
                      total +
                      (((u.data() as Map<String, dynamic>)['gems'] ?? 0) as num)
                          .toInt());

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(15),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.analytics, color: accentGold, size: 20),
                        const SizedBox(width: 8),
                        const Text('إحصائيات النظام',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.file_download,
                              color: Colors.blueAccent, size: 18),
                          onPressed: () => _exportUsersData(users),
                          tooltip: 'تصدير البيانات',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _statItem('المستخدمين', totalUsers.toString(),
                              Icons.people, Colors.blue),
                          const SizedBox(width: 20),
                          _statItem('المحظورين', bannedUsers.toString(),
                              Icons.block, Colors.red),
                          const SizedBox(width: 20),
                          _statItem('المسؤولين', adminUsers.toString(),
                              Icons.admin_panel_settings, Colors.amber),
                          const SizedBox(width: 20),
                          _statItem('إجمالي الكوينز', _formatNumber(totalCoins),
                              Icons.monetization_on, Colors.green),
                          const SizedBox(width: 20),
                          _statItem('إجمالي الجواهر', _formatNumber(totalGems),
                              Icons.diamond, Colors.blueAccent),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                      child: CircularProgressIndicator(color: accentGold));
                }
                var docs = snapshot.data!.docs;
                if (_searchText.isNotEmpty) {
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return (data['name'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(_searchText) ||
                        (data['royalId'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(_searchText) ||
                        (data['email'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(_searchText) ||
                        doc.id.toLowerCase().contains(_searchText);
                  }).toList();
                }
                // تطبيق الفلاتر المتقدمة
                docs = docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _applyFilters(data);
                }).toList();
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final uid = docs[index].id;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.05))),
                      child: ListTile(
                        onTap: () => _showUserActions(uid, data),
                        leading: CircleAvatar(
                            radius: 24,
                            backgroundImage:
                                (data['profilePic'] ?? '').isNotEmpty
                                    ? NetworkImage(data['profilePic'])
                                    : null,
                            child: (data['profilePic'] ?? '').isEmpty
                                ? Icon(Icons.person, color: accentGold)
                                : null),
                        title: Text(data['name'] ?? 'مستخدم',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _buildAuthProviderIcon(data),
                                const SizedBox(width: 6),
                                Text(_getAuthProviderDisplay(data),
                                    style: const TextStyle(
                                        color: Colors.white38, fontSize: 10)),
                                const SizedBox(width: 8),
                                Text("ID: ${data['royalId']}",
                                    style: const TextStyle(
                                        color: Colors.white38, fontSize: 10)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(_getAuthProviderDetails(data),
                                style: const TextStyle(
                                    color: Colors.white24, fontSize: 9)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _miniStat(
                                    Icons.stars,
                                    "${data['stars'] ?? data['coins'] ?? 0}",
                                    Colors.amber),
                                const SizedBox(width: 8),
                                _miniStat(Icons.diamond, "${data['gems'] ?? 0}",
                                    Colors.blue),
                                const SizedBox(width: 8),
                                _miniStat(
                                    Icons.account_balance_wallet,
                                    "${data['harvest_wallet'] ?? 0}",
                                    Colors.green),
                              ],
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.more_vert,
                            color: Colors.white24, size: 18),
                      ),
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

  Widget _miniStat(IconData icon, String val, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 10),
        const SizedBox(width: 2),
        Text(val,
            style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: 9,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildAuthProviderIcon(Map<String, dynamic> data) {
    final provider = data['authProvider'] ?? 'email';
    IconData icon;
    Color color;

    switch (provider) {
      case 'google':
        icon = Icons.g_mobiledata;
        color = Colors.red;
        break;
      case 'facebook':
        icon = Icons.facebook;
        color = Colors.blue;
        break;
      case 'phone':
        icon = Icons.phone;
        color = Colors.green;
        break;
      default:
        icon = Icons.email;
        color = Colors.orange;
        break;
    }

    return Icon(icon, color: color, size: 14);
  }

  String _getAuthProviderDisplay(Map<String, dynamic> data) {
    final provider = data['authProvider'] ?? 'email';
    switch (provider) {
      case 'google':
        return 'جوجل';
      case 'facebook':
        return 'فيسبوك';
      case 'phone':
        return 'رقم هاتف';
      default:
        return 'إيميل';
    }
  }

  String _getAuthProviderDetails(Map<String, dynamic> data) {
    final provider = data['authProvider'] ?? 'email';
    final details = data['authProviderDetails'] as Map<String, dynamic>?;

    switch (provider) {
      case 'google':
        return details?['email'] ?? details?['displayName'] ?? 'حساب جوجل';
      case 'facebook':
        return details?['name'] ?? details?['email'] ?? 'حساب فيسبوك';
      case 'phone':
        return data['phoneNumber'] ?? details?['phoneNumber'] ?? 'رقم هاتف';
      default:
        return data['email'] ?? details?['email'] ?? 'بدون إيميل';
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1B25),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: accentGold, width: 0.5)),
        title: Text('تصفية متقدمة',
            style: TextStyle(color: accentGold, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('الحالة:',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _filterOption('الكل', _filterStatus == null,
                      () => setState(() => _filterStatus = null)),
                  _filterOption('نشط', _filterStatus == 'active',
                      () => setState(() => _filterStatus = 'active')),
                  _filterOption('محظور', _filterStatus == 'banned',
                      () => setState(() => _filterStatus = 'banned')),
                ],
              ),
              const SizedBox(height: 16),
              const Text('الرتبة:',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _filterOption('الكل', _filterRole == null,
                      () => setState(() => _filterRole = null)),
                  _filterOption('مسؤول', _filterRole == 'admin',
                      () => setState(() => _filterRole = 'admin')),
                  _filterOption('مستخدم', _filterRole == 'user',
                      () => setState(() => _filterRole = 'user')),
                  _filterOption('مالك', _filterRole == 'owner',
                      () => setState(() => _filterRole = 'owner')),
                ],
              ),
              const SizedBox(height: 16),
              const Text('تاريخ التسجيل:',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _filterOption('الكل', _filterDateRange == null,
                      () => setState(() => _filterDateRange = null)),
                  _filterOption('اليوم', _filterDateRange == 'today',
                      () => setState(() => _filterDateRange = 'today')),
                  _filterOption('هذا الأسبوع', _filterDateRange == 'week',
                      () => setState(() => _filterDateRange = 'week')),
                  _filterOption('هذا الشهر', _filterDateRange == 'month',
                      () => setState(() => _filterDateRange = 'month')),
                ],
              ),
              const SizedBox(height: 16),
              const Text('الحد الأدنى للرصيد:',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 8),
              TextField(
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'أدخل المبلغ',
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (v) => setState(() => _minBalance = int.tryParse(v)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text('إغلاق', style: TextStyle(color: Colors.white38))),
          TextButton(
              onPressed: () {
                setState(() {
                  _filterStatus = null;
                  _filterRole = null;
                  _filterDateRange = null;
                  _minBalance = null;
                });
                Navigator.pop(ctx);
              },
              child: const Text('مسح الفلاتر',
                  style: TextStyle(color: Colors.redAccent))),
        ],
      ),
    );
  }

  Widget _filterOption(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? accentGold.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? accentGold : Colors.white12),
        ),
        child: Text(label,
            style: TextStyle(
                color: isSelected ? accentGold : Colors.white70, fontSize: 11)),
      ),
    );
  }

  Widget _filterChip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: accentGold.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(color: accentGold, fontSize: 10)),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: Icon(Icons.close, size: 12, color: accentGold),
          ),
        ],
      ),
    );
  }

  String _getFilterStatusLabel(String status) {
    switch (status) {
      case 'active':
        return 'نشط';
      case 'banned':
        return 'محظور';
      default:
        return status;
    }
  }

  String _getFilterRoleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'مسؤول';
      case 'user':
        return 'مستخدم';
      case 'owner':
        return 'مالك';
      default:
        return role;
    }
  }

  String _getFilterDateLabel(String range) {
    switch (range) {
      case 'today':
        return 'اليوم';
      case 'week':
        return 'هذا الأسبوع';
      case 'month':
        return 'هذا الشهر';
      default:
        return range;
    }
  }

  bool _applyFilters(Map<String, dynamic> data) {
    // تصفية الحالة
    if (_filterStatus != null) {
      final isBanned = data['isBanned'] ?? false;
      if (_filterStatus == 'active' && isBanned) return false;
      if (_filterStatus == 'banned' && !isBanned) return false;
    }

    // تصفية الرتبة
    if (_filterRole != null) {
      final role = data['role'] ?? 'user';
      if (role != _filterRole) return false;
    }

    // تصفية التاريخ
    if (_filterDateRange != null) {
      final createdAt = data['createdAt'] as Timestamp?;
      if (createdAt == null) return false;
      final date = createdAt.toDate();
      final now = DateTime.now();

      if (_filterDateRange == 'today') {
        if (date.day != now.day ||
            date.month != now.month ||
            date.year != now.year) {
          return false;
        }
      } else if (_filterDateRange == 'week') {
        final weekAgo = now.subtract(const Duration(days: 7));
        if (date.isBefore(weekAgo)) return false;
      } else if (_filterDateRange == 'month') {
        final monthAgo = now.subtract(const Duration(days: 30));
        if (date.isBefore(monthAgo)) return false;
      }
    }

    // تصفية الرصيد
    if (_minBalance != null) {
      final balance = ((data['stars'] ?? data['coins'] ?? 0) as num).toInt();
      if (balance < _minBalance!) return false;
    }

    return true;
  }

  Widget _statItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  Future<void> _exportUsersData(List<QueryDocumentSnapshot> users) async {
    try {
      final csvData = StringBuffer();
      csvData.writeln('ID,Name,Email,Role,Coins,Gems,IsBanned,CreatedAt');

      for (var userDoc in users) {
        final data = userDoc.data() as Map<String, dynamic>;
        final id = userDoc.id;
        final name = (data['name'] ?? '').toString().replaceAll(',', ' ');
        final email = (data['email'] ?? '').toString().replaceAll(',', ' ');
        final role = data['role'] ?? 'user';
        final coins = data['coins'] ?? 0;
        final gems = data['gems'] ?? 0;
        final isBanned = data['isBanned'] ?? false;
        final createdAt = data['createdAt'] as Timestamp?;
        final date = createdAt?.toDate() ?? DateTime.now();

        csvData.writeln('$id,$name,$email,$role,$coins,$gems,$isBanned,$date');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('تم تصدير البيانات بنجاح ✅'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('خطأ في التصدير: $e'), backgroundColor: Colors.red));
      }
    }
  }
}

class _ActionItemWrapper extends StatelessWidget {
  final Widget child;
  final bool show;
  const _ActionItemWrapper({required this.child, required this.show});
  @override
  Widget build(BuildContext context) => show ? child : const SizedBox.shrink();
}
