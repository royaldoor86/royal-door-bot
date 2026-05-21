import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'royal_panel/royal_admin_panel_page.dart';

/// نقطة الدخول للوحة التحكم الملكية
class RoyalAdminPanelEntry extends StatelessWidget {
  const RoyalAdminPanelEntry({super.key});

  bool _isOwner(User? user, Map<String, dynamic>? userData) {
    if (user == null) return false;
    final email = user.email?.toLowerCase();
    if (email == 'royaldoor86@gmail.com' || email == 'doorty86@gmail.com') {
      return true;
    }
    if (userData != null && (userData['isOwner'] == true)) return true;
    return false;
  }

  Future<Map<String, dynamic>?> _getUserData(String uid) async {
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('يجب تسجيل الدخول')));
    }
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserData(user.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (!_isOwner(user, snapshot.data)) {
          return const Scaffold(body: Center(child: Text('غير مصرح لك')));
        }
        return const RoyalAdminPanelPage();
      },
    );
  }
}
