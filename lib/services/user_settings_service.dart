import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// مركزية إدارة إعدادات المستخدم
class UserSettingsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ==================== إعدادات الإشعارات ====================

  /// التحقق من تفعيل إشعار معين
  static Future<bool> isNotificationEnabled(String notificationType) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return true;

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['${notificationType}NotificationsEnabled'] ?? true;
      }
    } catch (e) {
      debugPrint('Error checking notification setting: $e');
    }
    return true;
  }

  /// تحديث إعداد إشعار
  static Future<void> setNotificationEnabled(
      String notificationType, bool enabled) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore.collection('users').doc(userId).update({
        '${notificationType}NotificationsEnabled': enabled,
      });
    } catch (e) {
      debugPrint('Error updating notification setting: $e');
    }
  }

  /// التحقق من تفعيل الإشعارات الداخلية
  static Future<bool> areInternalNotificationsEnabled() async {
    return await isNotificationEnabled('internal');
  }

  /// التحقق من تفعيل الإشعارات الفورية
  static Future<bool> arePushNotificationsEnabled() async {
    return await isNotificationEnabled('push');
  }

  /// التحقق من تفعيل إشعارات المتابعة
  static Future<bool> areFollowNotificationsEnabled() async {
    return await isNotificationEnabled('follow');
  }

  /// التحقق من تفعيل إشعارات الإعجابات
  static Future<bool> areLikeNotificationsEnabled() async {
    return await isNotificationEnabled('like');
  }

  /// التحقق من تفعيل إشعارات التعليقات
  static Future<bool> areCommentNotificationsEnabled() async {
    return await isNotificationEnabled('comment');
  }

  /// التحقق من تفعيل إشعارات الهدايا
  static Future<bool> areGiftNotificationsEnabled() async {
    return await isNotificationEnabled('gift');
  }

  /// التحقق من تفعيل إشعارات الأوسمة
  static Future<bool> areBadgeNotificationsEnabled() async {
    return await isNotificationEnabled('badge');
  }

  /// التحقق من تفعيل إشعارات المعارك
  static Future<bool> areBattleNotificationsEnabled() async {
    return await isNotificationEnabled('battle');
  }

  /// التحقق من تفعيل إشعارات المكافآت
  static Future<bool> areRewardNotificationsEnabled() async {
    return await isNotificationEnabled('reward');
  }

  /// التحقق من تفعيل إشعارات طلبات الصداقة
  static Future<bool> areFriendRequestNotificationsEnabled() async {
    return await isNotificationEnabled('friendRequest');
  }

  /// التحقق من تفعيل إشعارات المحادثات
  static Future<bool> areChatNotificationsEnabled() async {
    return await isNotificationEnabled('chat');
  }

  /// التحقق من تفعيل إشعارات النظام
  static Future<bool> areSystemNotificationsEnabled() async {
    return await isNotificationEnabled('system');
  }

  // ==================== إعدادات الخصوصية ====================

  /// التحقق من أن الحساب خاص
  static Future<bool> isAccountPrivate() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['isPrivate'] ?? false;
      }
    } catch (e) {
      debugPrint('Error checking private account: $e');
    }
    return false;
  }

  /// التحقق من أن البروفايل عام
  static Future<bool> isProfilePublic() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return true;

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['profileVisibilityPublic'] ?? true;
      }
    } catch (e) {
      debugPrint('Error checking profile visibility: $e');
    }
    return true;
  }

  /// التحقق من السماح بالرسائل من الجميع
  static Future<bool> canReceiveMessagesFromEveryone() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return true;

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['allowMessagesFromEveryone'] ?? true;
      }
    } catch (e) {
      debugPrint('Error checking message permissions: $e');
    }
    return true;
  }

  /// التحقق من السماح بالرسائل من الأصدقاء فقط
  static Future<bool> canReceiveMessagesFromFriendsOnly() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['allowMessagesFromFriendsOnly'] ?? false;
      }
    } catch (e) {
      debugPrint('Error checking message permissions: $e');
    }
    return false;
  }

  /// التحقق من إظهار الحالة النشطة
  static Future<bool> shouldShowOnlineStatus() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return true;

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['showOnlineStatus'] ?? true;
      }
    } catch (e) {
      debugPrint('Error checking online status: $e');
    }
    return true;
  }

  /// التحقق من قبول طلبات الصداقة
  static Future<bool> canReceiveFriendRequests() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return true;

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['allowFriendRequests'] ?? true;
      }
    } catch (e) {
      debugPrint('Error checking friend request permissions: $e');
    }
    return true;
  }

  /// التحقق من استلام إشعارات من غير الأصدقاء
  static Future<bool> canReceiveNotificationsFromNonFriends() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return true;

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['notificationsFromNonFriends'] ?? true;
      }
    } catch (e) {
      debugPrint('Error checking non-friend notifications: $e');
    }
    return true;
  }

  /// التحقق من تفعيل الحظر التلقائي
  static Future<bool> isAutoBlockEnabled() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['autoBlockEnabled'] ?? false;
      }
    } catch (e) {
      debugPrint('Error checking auto block: $e');
    }
    return false;
  }

  // ==================== التحقق من الصلاحيات ====================

  /// التحقق مما إذا كان المستخدم يمكنه إرسال رسالة لمستخدم آخر
  static Future<bool> canSendMessageTo(String targetUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return false;

    // التحقق من إعدادات المستخدم المستهدف
    try {
      final doc = await _firestore.collection('users').doc(targetUserId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final allowFromEveryone = data['allowMessagesFromEveryone'] ?? true;
        final allowFromFriendsOnly = data['allowMessagesFromFriendsOnly'] ?? false;
        final allowFromNoOne = data['allowMessagesFromNoOne'] ?? false;

        if (allowFromNoOne) return false;
        if (allowFromEveryone) return true;
        if (allowFromFriendsOnly) {
          // التحقق من الصداقة
          return await _areFriends(currentUserId, targetUserId);
        }
      }
    } catch (e) {
      debugPrint('Error checking message permission: $e');
    }
    return true;
  }

  /// التحقق من الصداقة بين مستخدمين
  static Future<bool> _areFriends(String userId1, String userId2) async {
    try {
      final doc1 = await _firestore
          .collection('users')
          .doc(userId1)
          .collection('friends')
          .doc(userId2)
          .get();

      if (doc1.exists) return true;

      final doc2 = await _firestore
          .collection('users')
          .doc(userId2)
          .collection('friends')
          .doc(userId1)
          .get();

      return doc2.exists;
    } catch (e) {
      debugPrint('Error checking friendship: $e');
      return false;
    }
  }

  /// التحقق مما إذا كان المستخدم يمكنه إرسال طلب صداقة
  static Future<bool> canSendFriendRequestTo(String targetUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return false;

    try {
      final doc = await _firestore.collection('users').doc(targetUserId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['allowFriendRequests'] ?? true;
      }
    } catch (e) {
      debugPrint('Error checking friend request permission: $e');
    }
    return true;
  }

  /// التحقق مما إذا كان المستخدم محظور
  static Future<bool> isUserBlocked(String userId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return false;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blockedUsers')
          .doc(userId)
          .get();

      return doc.exists;
    } catch (e) {
      debugPrint('Error checking if user is blocked: $e');
      return false;
    }
  }

  /// حظر مستخدم
  static Future<void> blockUser(String userId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blockedUsers')
          .doc(userId)
          .set({'blockedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      debugPrint('Error blocking user: $e');
    }
  }

  /// إلغاء حظر مستخدم
  static Future<void> unblockUser(String userId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('blockedUsers')
          .doc(userId)
          .delete();
    } catch (e) {
      debugPrint('Error unblocking user: $e');
    }
  }

  // ==================== إعدادات المظهر ====================

  /// التحقق من الوضع الليلي
  static Future<bool> isDarkModeEnabled() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return true;

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['darkMode'] ?? true;
      }
    } catch (e) {
      debugPrint('Error checking dark mode: $e');
    }
    return true;
  }

  /// الحصول على حجم الخط
  static Future<double> getFontSize() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return 16.0;

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return (data['fontSize'] ?? 16.0).toDouble();
      }
    } catch (e) {
      debugPrint('Error getting font size: $e');
    }
    return 16.0;
  }

  // ==================== إعدادات الصوتيات ====================

  /// التحقق من تفعيل المؤثرات الصوتية
  static Future<bool> areSoundEffectsEnabled() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return true;

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['soundEnabled'] ?? true;
      }
    } catch (e) {
      debugPrint('Error checking sound effects: $e');
    }
    return true;
  }

  // ==================== الحصول على جميع الإعدادات ====================

  /// الحصول على جميع إعدادات المستخدم
  static Future<Map<String, dynamic>> getAllSettings(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error getting all settings: $e');
    }
    return {};
  }

  /// تحديث إعدادات متعددة دفعة واحدة
  static Future<void> updateMultipleSettings(
      Map<String, dynamic> settings) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore.collection('users').doc(userId).update(settings);
    } catch (e) {
      debugPrint('Error updating multiple settings: $e');
    }
  }
}
