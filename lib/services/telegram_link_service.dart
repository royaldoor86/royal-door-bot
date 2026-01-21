import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TelegramLinkService {
  static Future<String> linkTelegram(String code) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return "يجب تسجيل الدخول أولاً";
    }

    final docRef =
        FirebaseFirestore.instance.collection('telegram_links').doc(code);
    final doc = await docRef.get();

    if (!doc.exists) {
      return "❌ كود غير صحيح";
    }

    final data = doc.data()!;
    final bool used = data['used'];
    final Timestamp expiresAt = data['expires_at'];

    if (used) {
      return "❌ هذا الكود مستخدم مسبقًا";
    }

    if (expiresAt.toDate().isBefore(DateTime.now())) {
      return "⌛ انتهت صلاحية الكود";
    }

    await docRef.update({
      'used': true,
      'linked_uid': user.uid,
    });

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'telegram_id': data['telegram_id'],
      'telegram_linked': true,
    }, SetOptions(merge: true));

    return "👑 تم ربط حسابك بنجاح";
  }
}
