import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AdminUidPage extends StatefulWidget {
  const AdminUidPage({super.key});

  @override
  State<AdminUidPage> createState() => _AdminUidPageState();
}

class _AdminUidPageState extends State<AdminUidPage> {
  final TextEditingController searchController = TextEditingController();
  String _searchText = "";

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

  Future<void> _deleteUserCompletely(String uid, String name, String? email) async {
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
            Text("حذف نهائي كامل",
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
            "هل أنت متأكد من حذف $name نهائياً؟\n\nUID: $uid\nالبريد: ${email ?? 'غير متوفر'}\n\nسيتم مسح كافة البيانات من Firestore وحذف الحساب من Firebase Auth 🚫.",
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
              child: const Text("حذف نهائي",
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
              Text("هل أنت متأكد تماماً من حذف $name نهائياً؟",
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              const Text(
                  "سيتم مسح جميع البيانات وحذف الحساب من Firebase Auth",
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
            'reason': 'Permanent Deletion by admin through UID Management',
          });
        }

        // 2. الحذف من Auth عبر Cloud Function
        try {
          await FirebaseFunctions.instance
              .httpsCallable('adminDeleteUser')
              .call({'uid': uid}).timeout(const Duration(seconds: 10));
        } catch (e) {
          debugPrint("Cloud function error: $e");
          // إذا فشلت Cloud Function، نحاول حذف المستخدم من Firestore فقط
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
              content: Text("تم حذف المستخدم نهائياً بنجاح ✅"),
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

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Scaffold(
        backgroundColor: primaryDark,
        appBar: AppBar(
          backgroundColor: primaryDark,
          title: const Text(
            'إدارة المستخدمين (UID)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Column(
          children: [
            // شريط البحث
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'بحث بالاسم أو UID...',
                  hintStyle: const TextStyle(color: Colors.white38),
                  prefixIcon: Icon(Icons.search, color: accentGold),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white54),
                          onPressed: () {
                            searchController.clear();
                            setState(() {
                              _searchText = "";
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchText = value.toLowerCase();
                  });
                },
              ),
            ),
            // قائمة المستخدمين
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
                    );
                  }

                  final users = snapshot.data!.docs;
                  
                  // تصفية النتائج
                  final filteredUsers = users.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['name'] ?? '').toString().toLowerCase();
                    final uid = doc.id.toLowerCase();
                    final email = (data['email'] ?? '').toString().toLowerCase();
                    
                    return name.contains(_searchText) ||
                           uid.contains(_searchText) ||
                           email.contains(_searchText);
                  }).toList();

                  if (filteredUsers.isEmpty) {
                    return Center(
                      child: Text(
                        _searchText.isEmpty
                            ? 'لا يوجد مستخدمين'
                            : 'لا توجد نتائج للبحث',
                        style: const TextStyle(color: Colors.white54),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final doc = filteredUsers[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final uid = doc.id;
                      final name = data['name'] ?? 'مستخدم';
                      final email = data['email'] ?? 'غير متوفر';
                      final royalId = data['royalId'] ?? 'غير متوفر';
                      final createdAt = data['createdAt'];
                      final createdText = createdAt is Timestamp
                          ? DateFormat('yyyy-MM-dd HH:mm').format(createdAt.toDate())
                          : 'غير متوفر';
                      final isBanned = data['isBanned'] ?? false;
                      final isOnline = data['isOnline'] ?? false;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        color: Colors.white.withValues(alpha: 0.03),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isBanned
                                ? Colors.red.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          tileColor: Colors.transparent,
                          splashColor: accentGold.withValues(alpha: 0.1),
                          leading: CircleAvatar(
                            backgroundColor: Colors.white12,
                            backgroundImage: data['profilePic'] != null &&
                                    data['profilePic'].toString().isNotEmpty
                                ? NetworkImage(data['profilePic']) as ImageProvider
                                : null,
                            child: data['profilePic'] == null ||
                                    data['profilePic'].toString().isEmpty
                                ? const Icon(Icons.person, color: Colors.white54)
                                : null,
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (isOnline)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                                  ),
                                  child: const Text(
                                    'متصل',
                                    style: TextStyle(color: Colors.green, fontSize: 10),
                                  ),
                                ),
                              if (isBanned)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                                  ),
                                  child: const Text(
                                    'محظور',
                                    style: TextStyle(color: Colors.red, fontSize: 10),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              _buildInfoRow('UID:', uid, Icons.fingerprint),
                              _buildInfoRow('الآيدي:', royalId, Icons.badge),
                              _buildInfoRow('البريد:', email, Icons.email),
                              _buildInfoRow('انضم:', createdText, Icons.calendar_today),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_forever, color: Colors.red),
                            onPressed: () => _deleteUserCompletely(uid, name, email),
                            tooltip: 'حذف نهائي',
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 12, color: accentGold),
          const SizedBox(width: 4),
          Text(
            ' $label ',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
