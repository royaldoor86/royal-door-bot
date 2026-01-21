import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import '../../theme/app_theme.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;
  final String userName;
  final String? photoUrl;
  final bool isBlocked;
  final Function()? onToggleBlock;

  const UserProfilePage({
    super.key,
    required this.userId,
    required this.userName,
    this.photoUrl,
    required this.isBlocked,
    this.onToggleBlock,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _newIdController = TextEditingController();
  bool _loading = false;

  Future<void> _setShortId() async {
    final newId = _newIdController.text.trim().toUpperCase();
    if (newId.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الـ ID قصير جداً')));
      return;
    }

    setState(() => _loading = true);
    try {
      final db = FirebaseFirestore.instance;
      // 1. التأكد أن الـ ID غير محجوز
      final check = await db.collection('short_ids').doc(newId).get();
      if (check.exists) {
        throw 'هذا الـ ID محجوز لمستخدم آخر';
      }

      final userRef = db.collection('users').doc(widget.userId);
      final userSnap = await userRef.get();
      final oldId = (userSnap.data()?['shortId'] as String?)?.toUpperCase();

      await db.runTransaction((tx) async {
        // حجز الجديد
        tx.set(db.collection('short_ids').doc(newId), {
          'uid': widget.userId,
          'createdAt': FieldValue.serverTimestamp(),
          'source': 'admin_action'
        });
        // حذف القديم
        if (oldId != null && oldId.isNotEmpty) {
          tx.delete(db.collection('short_ids').doc(oldId));
        }
        // تحديث المستخدم
        tx.update(userRef, {'shortId': newId});
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تغيير الـ ID بنجاح ✅')));
        _newIdController.clear();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AppTheme.background(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: const Text('إدارة المستخدم')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: widget.photoUrl != null ? NetworkImage(widget.photoUrl!) : null,
                  child: widget.photoUrl == null ? const Icon(Icons.person, size: 60) : null,
                ),
                const SizedBox(height: 16),
                Text(widget.userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 30),
                
                AppTheme.glassContainer(
                  child: Column(
                    children: [
                      const Text('تغيير الـ ID يدوياً (الأدمن)', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      TextField(
                        controller: _newIdController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'اكتب الـ ID الجديد...',
                          hintStyle: TextStyle(color: Colors.white38),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 15),
                      _loading 
                        ? const CircularProgressIndicator()
                        : AppTheme.gradientButton(text: 'تحديث الـ ID', onPressed: _setShortId),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                
                AppTheme.gradientButton(
                  text: widget.isBlocked ? 'إلغاء حظر المستخدم' : 'حظر المستخدم نهائياً',
                  onPressed: widget.onToggleBlock,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
