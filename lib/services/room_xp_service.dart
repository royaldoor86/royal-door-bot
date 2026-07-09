import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// خدمة إدارة XP في الغرف الصوتية
class RoomXPService {
  static const int MIC_CHAT_XP = 5;
  static const int MESSAGE_XP = 1;
  static const int JOIN_SHARE_XP = 4;
  static const int GEM_GIFT_XP = 5;
  static const int STAR_GIFT_XP = 5;
  static const int THEME_PURCHASE_XP = 10;
  static const int BATTLE_WIN_XP = 10;

  /// كسب XP من الدردشة على المايك
  static Future<void> earnMicChatXP(String roomId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'royalXP': FieldValue.increment(MIC_CHAT_XP),
      'xp': FieldValue.increment(MIC_CHAT_XP),
    });
  }

  /// كسب XP من إرسال رسائل
  static Future<void> earnMessageXP(String roomId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'royalXP': FieldValue.increment(MESSAGE_XP),
      'xp': FieldValue.increment(MESSAGE_XP),
    });
  }

  /// كسب XP من مشاركة الغرفة والانضمام
  static Future<void> earnJoinShareXP(String roomId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'royalXP': FieldValue.increment(JOIN_SHARE_XP),
      'xp': FieldValue.increment(JOIN_SHARE_XP),
    });
  }

  /// كسب XP من هدايا الجواهر
  static Future<void> earnGemGiftXP(String roomId, int giftCount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'royalXP': FieldValue.increment(GEM_GIFT_XP * giftCount),
      'xp': FieldValue.increment(GEM_GIFT_XP * giftCount),
    });
  }

  /// كسب XP من هدايا النجوم
  static Future<void> earnStarGiftXP(String roomId, int giftCount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'royalXP': FieldValue.increment(STAR_GIFT_XP * giftCount),
      'xp': FieldValue.increment(STAR_GIFT_XP * giftCount),
    });
  }

  /// كسب XP من شراء موضوع للغرفة
  static Future<void> earnThemePurchaseXP(String roomId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'royalXP': FieldValue.increment(THEME_PURCHASE_XP),
      'xp': FieldValue.increment(THEME_PURCHASE_XP),
    });
  }

  /// كسب XP من الفوز بالمعركة
  static Future<void> earnBattleWinXP(String roomId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'royalXP': FieldValue.increment(BATTLE_WIN_XP),
      'xp': FieldValue.increment(BATTLE_WIN_XP),
    });
  }

  /// كسب XP عام (للاستخدام في الأنشطة المخصصة)
  static Future<void> earnXP(String roomId, int xpAmount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'royalXP': FieldValue.increment(xpAmount),
      'xp': FieldValue.increment(xpAmount),
    });
  }
}
