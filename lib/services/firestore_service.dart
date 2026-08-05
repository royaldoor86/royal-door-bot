import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/story_model.dart';
import '../models/chat_model.dart';
import 'notifications_service.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _isValidId(String id) => id.isNotEmpty && !id.contains('{');

  static List<String> normalizeVisitedRoomIds(Map<String, dynamic>? data) {
    if (data == null) return [];

    final rawRooms = data['visitedRooms'] ?? data['joinedRooms'] ?? [];
    if (rawRooms is! List) return [];

    return rawRooms
        .whereType<String>()
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
  }

  Future<void> trackRoomVisit(
      {required String userId, required String roomId}) async {
    if (!_isValidId(userId) || !_isValidId(roomId)) return;

    try {
      await _db.collection('users').doc(userId).set({
        'visitedRooms': FieldValue.arrayUnion([roomId]),
        'lastRoomVisitAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      _handleError('trackRoomVisit', e);
    }
  }

  // --- آلية معالجة الأخطاء الذكية لإظهار روابط الفهارس ---
  void _handleError(String context, dynamic error) {
    final errorStr = error.toString();
    debugPrint("❌ Firestore Error [$context]: $errorStr");

    // استخراج الرابط إذا وجد (رابط إنشاء الفهرس)
    if (errorStr.contains("https://console.firebase.google.com")) {
      final RegExp urlRegExp =
          RegExp(r'https://console\.firebase\.google\.com/[^\s\n]+');
      final match = urlRegExp.firstMatch(errorStr);
      if (match != null) {
        debugPrint("\n🔗 [رابط إنشاء الفهرس المطلوب]:");
        debugPrint("👉 ${match.group(0)} 👈\n");
        debugPrint(
            "انقر على الرابط أعلاه لفتح صفحة Firebase وتفعيل البحث لهذا القسم.");
      }
    }
  }

  // --- نظام إدارة الأجهزة والحظر (Device Management) ---

  /// تسجيل أو تحديث بيانات جهاز المستخدم
  Future<void> registerUserDevice({
    required String userId,
    required String userName,
    required String deviceId,
    required String deviceName,
    required String deviceIp,
    String? userEmail,
    String? userPhone,
  }) async {
    try {
      final deviceRef =
          _db.collection('user_devices').doc("${userId}_$deviceId");
      await deviceRef.set({
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail ?? '',
        'userPhone': userPhone ?? '',
        'deviceIp': deviceIp,
        'deviceId': deviceId,
        'deviceName': deviceName,
        'lastLogin': FieldValue.serverTimestamp(),
        'isBanned': false,
      }, SetOptions(merge: true));
    } catch (e) {
      _handleError("registerUserDevice", e);
    }
  }

  /// التحقق مما إذا كان الجهاز محظوراً
  Future<bool> isDeviceBanned(String deviceId, String deviceIp) async {
    try {
      // البحث في كولكشن الأجهزة المحظورة
      // ملاحظة: هذا الاستعلام قد يحتاج لـ Composite Index إذا أضفت orderBy
      final bannedByDoc = await _db
          .collection('banned_devices')
          .where('deviceId', isEqualTo: deviceId)
          .limit(1)
          .get();

      if (bannedByDoc.docs.isNotEmpty) return true;

      final bannedByIp = await _db
          .collection('banned_devices')
          .where('deviceIp', isEqualTo: deviceIp)
          .limit(1)
          .get();

      return bannedByIp.docs.isNotEmpty;
    } catch (e) {
      _handleError("isDeviceBanned", e);
      return false;
    }
  }

  /// حظر جهاز
  Future<void> banDevice({
    required String deviceId,
    required String deviceIp,
    required String userId,
    required String userName,
    required String reason,
    required String bannedBy,
  }) async {
    try {
      final batch = _db.batch();

      // 1. إضافة للجهاز المحظور
      final banRef = _db.collection('banned_devices').doc(deviceId);
      batch.set(banRef, {
        'deviceId': deviceId,
        'deviceIp': deviceIp,
        'userId': userId,
        'userName': userName,
        'reason': reason,
        'bannedBy': bannedBy,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. تحديث حالة الحظر في سجلات الأجهزة لجميع المستخدمين الذين استخدموا هذا الجهاز
      final matchingDevices = await _db
          .collection('user_devices')
          .where('deviceId', isEqualTo: deviceId)
          .get();

      for (var doc in matchingDevices.docs) {
        batch.update(doc.reference, {'isBanned': true});
      }

      await batch.commit();
    } catch (e) {
      _handleError("banDevice", e);
    }
  }

  /// فك حظر جهاز
  Future<void> unbanDevice(String deviceId) async {
    try {
      final batch = _db.batch();

      // 1. حذف من الأجهزة المحظورة
      batch.delete(_db.collection('banned_devices').doc(deviceId));

      // 2. تحديث الحالة في user_devices
      final matchingDevices = await _db
          .collection('user_devices')
          .where('deviceId', isEqualTo: deviceId)
          .get();

      for (var doc in matchingDevices.docs) {
        batch.update(doc.reference, {'isBanned': false});
      }

      await batch.commit();
    } catch (e) {
      _handleError("unbanDevice", e);
    }
  }

  // --- نظام خبرة الغرف (Room EXP System) ---
  Future<void> increaseRoomExp(String roomId, int amount) async {
    if (!_isValidId(roomId)) return;
    final roomRef = _db.collection('rooms').doc(roomId);

    try {
      await _db.runTransaction((transaction) async {
        final roomSnap = await transaction.get(roomRef);
        if (!roomSnap.exists) return;

        final data = roomSnap.data()!;
        int currentExp = data['exp'] ?? 0;
        int currentLevel = data['level'] ?? 1;

        int newExp = currentExp + amount;
        int nextLevelThreshold =
            currentLevel * 10000; // شروط المستوى كما في الصورة

        if (newExp >= nextLevelThreshold) {
          transaction.update(roomRef, {
            'exp': newExp - nextLevelThreshold,
            'level': currentLevel + 1,
          });
        } else {
          transaction.update(roomRef, {'exp': newExp});
        }
      });
    } catch (e) {
      _handleError("increaseRoomExp", e);
    }
  }

  // --- نظام XP المستخدم من أنشطة الغرف ---
  static const int MIC_CHAT_XP = 5; // كل ساعة
  static const int MESSAGE_XP = 1;
  static const int JOIN_SHARE_XP = 5;
  static const int GEM_GIFT_XP = 5;
  static const int COIN_GIFT_XP = 5;
  static const int THEME_PURCHASE_XP = 5;
  static const int BATTLE_WIN_XP = 5;
  static const int FAN_CLUB_JOIN_XP = 2;

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

  /// كسب XP من هدايا الكوينز
  static Future<void> earnCoinGiftXP(String roomId, int giftCount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'royalXP': FieldValue.increment(COIN_GIFT_XP * giftCount),
      'xp': FieldValue.increment(COIN_GIFT_XP * giftCount),
    });
  }

  /// كسب XP من الانضمام لنادي المعجبين
  static Future<void> earnFanClubJoinXP(String roomId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'royalXP': FieldValue.increment(FAN_CLUB_JOIN_XP),
      'xp': FieldValue.increment(FAN_CLUB_JOIN_XP),
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

  // --- المستخدمون ---
  Future<UserModel?> getUserByRoyalId(String royalId) async {
    final snap = await _db
        .collection('users')
        .where('royalId', isEqualTo: royalId)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) {
      return UserModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
    }
    return null;
  }

  Future<Map<String, dynamic>?> getUserData(String uid) async {
    if (!_isValidId(uid)) return null;
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  Stream<UserModel> streamUserData(String uid) {
    if (!_isValidId(uid)) return const Stream.empty();
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snap) => UserModel.fromMap(snap.data() ?? {}, snap.id));
  }

  Future<void> saveUser(UserModel user) async {
    if (!_isValidId(user.uid)) return;

    // منع الكتابة العرضية للآيدي إذا كان موجوداً مسبقاً في السيرفر
    // نقوم بحذف الحقل من الخريطة المرسلة لضمان عدم الكتابة فوق الآيدي المخصص
    final data = user.toMap();

    // إذا كان المستخدم يملك آيدي بالفعل، لا نرسله في عمليات التحديث العادية
    // الآيدي يتغير فقط عبر العمليات المخصصة (شراء/منح)
    data.remove('royalId');
    data.remove('shortId');

    await _db
        .collection('users')
        .doc(user.uid)
        .set(data, SetOptions(merge: true));
  }

  Future<void> updateSingleField(
      String uid, String field, dynamic value) async {
    if (!_isValidId(uid)) return;
    await _db.collection('users').doc(uid).update({field: value});
  }

  // --- نظام الإشعارات ---
  Future<void> sendUserNotification({
    required String toUid,
    required String fromUid,
    required String type,
    required Map<String, dynamic> data,
  }) async {
    if (!_isValidId(toUid) || !_isValidId(fromUid)) return;
    final notif = {
      'to': toUid,
      'from': fromUid,
      'type': type,
      'data': data,
      'read': false,
      'timestamp': FieldValue.serverTimestamp(),
    };
    await _db.collection('notifications').add(notif);
    await _db
        .collection('users')
        .doc(toUid)
        .collection('notifications')
        .add(notif);
  }

  // --- الدردشة ---
  Stream<List<ChatRoomModel>> streamChatRooms(String userId) {
    if (!_isValidId(userId)) return Stream.value([]);
    return _db
        .collection('chatRooms')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatRoomModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<MessageModel>> streamMessages(String roomId, {int limit = 20, String? userId}) {
    if (!_isValidId(roomId)) return Stream.value([]);
    return _db
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MessageModel.fromMap(doc.data(), doc.id))
            .where((msg) {
              // Filter out messages deleted for the current user
              if (userId != null && msg.deletedFor != null) {
                return !msg.deletedFor!.contains(userId);
              }
              return true;
            })
            .toList());
  }

  // --- تحسينات المحادثات العالمية ---

  // دالة الإرسال الأساسية (تم تحسينها لدعم الردود وتحديث بيانات الغرفة وإرسال الإشعارات)
  Future<void> sendMessage(String roomId, MessageModel message) async {
    if (!_isValidId(roomId)) return;
    final roomRef = _db.collection('chatRooms').doc(roomId);
    final msgRef = roomRef.collection('messages').doc();

    await msgRef.set(message.toMap());

    // تحديث بيانات الغرفة (آخر رسالة، التوقيت)
    await roomRef.update({
      'lastMessage': message.type == MessageType.image
          ? '📷 صورة'
          : message.type == MessageType.audio
              ? '🎤 رسالة صوتية'
              : message.text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    // --- إرسال إشعار للطرف الآخر ---
    try {
      final roomSnap = await roomRef.get();
      if (roomSnap.exists) {
        final roomData = roomSnap.data()!;
        final List<String> participants =
            List<String>.from(roomData['participants'] ?? []);
        final bool isGroup = roomData['isGroup'] ?? false;
        final String? groupName = roomData['groupName'];

        // جلب اسم المرسل
        final senderDoc =
            await _db.collection('users').doc(message.senderId).get();
        final senderName = senderDoc.data()?['name'] ?? 'مستخدم ملكي';

        String body = message.text;
        if (message.type == MessageType.image) body = '📷 أرسل صورة';
        if (message.type == MessageType.audio) body = '🎤 رسالة صوتية';
        if (message.type == MessageType.video) body = '🎥 أرسل فيديو';
        if (message.type == MessageType.gift) body = '🎁 أرسل هدية';

        List<Future> notificationTasks = [];
        for (final recipientUid in participants) {
          if (recipientUid == message.senderId) continue;

          notificationTasks.add(NotificationsService.sendPushNotification({
            'targetUid': recipientUid,
            'title': isGroup ? groupName ?? 'مجموعة ملكية' : senderName,
            'body': isGroup ? '$senderName: $body' : body,
            'type': 'chat',
            'chatId': roomId,
          }));
        }
        await Future.wait(notificationTasks);
      }
    } catch (e) {
      _handleError("sendMessageNotification", e);
    }
  }

  // 1. ميزة تحويل الرسائل (Forward) مع إشعار
  Future<void> forwardMessage(String originalRoomId, String messageId,
      String targetRoomId, String currentUserId) async {
    if (!_isValidId(originalRoomId) || !_isValidId(targetRoomId)) return;

    // جلب الرسالة الأصلية
    final originalDoc = await _db
        .collection('chatRooms')
        .doc(originalRoomId)
        .collection('messages')
        .doc(messageId)
        .get();

    if (!originalDoc.exists) return;
    final data = originalDoc.data()!;

    final message = MessageModel(
      id: '',
      senderId: currentUserId,
      text: data['text'] ?? '',
      type: MessageType.values.firstWhere(
        (e) => e.toString() == 'MessageType.${data['type']}',
        orElse: () => MessageType.text,
      ),
      imageUrl: data['imageUrl'],
      videoUrl: data['videoUrl'],
      audioUrl: data['audioUrl'],
      location: data['location'] != null
          ? Map<String, double>.from(data['location'])
          : null,
      contactData: data['contactData'],
      timestamp: DateTime.now(),
      forwardedFrom: data['senderId'],
    );

    await sendMessage(targetRoomId, message);
  }

  // 2. تحديث حالة التواجد (Online/Last Seen)
  Future<void> updateUserStatus(String uid, bool isOnline) async {
    if (!_isValidId(uid)) return;
    await _db.collection('users').doc(uid).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markMessagesAsRead(String roomId, List<String> messageIds,
      {String? readerId}) async {
    if (!_isValidId(roomId)) return;
    final batch = _db.batch();
    for (final mid in messageIds) {
      batch.update(
          _db
              .collection('chatRooms')
              .doc(roomId)
              .collection('messages')
              .doc(mid),
          {'isRead': true});
    }
    if (readerId != null) {
      batch.update(_db.collection('chatRooms').doc(roomId),
          {'unreadCounts.$readerId': 0});
    }
    await batch.commit();
  }

  Future<void> deleteConversation(String roomId, String userId) async {
    if (!_isValidId(roomId)) return;
    await _db.collection('chatRooms').doc(roomId).update({
      'participants': FieldValue.arrayRemove([userId]),
    });
  }

  Future<void> clearChatMessages(String roomId) async {
    final messages = await _db
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .get();
    final batch = _db.batch();
    for (var doc in messages.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> setTypingStatus(String roomId, String userId, bool isTyping) {
    return _db
        .collection('chatRooms')
        .doc(roomId)
        .update({'typingStatus.$userId': isTyping});
  }

  // دالة الحذف المتقدمة (للجميع vs من عندي فقط)
  Future<void> deleteMessage(String roomId, String messageId,
      {String? userId, bool deleteForEveryone = true}) async {
    final msgRef = _db
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .doc(messageId);

    if (deleteForEveryone) {
      // حذف للجميع: استبدال المحتوى بـ "تم الحذف" للحفاظ على تسلسل المحادثة (WhatsApp Style)
      await msgRef.update({
        'isDeleted': true,
        'text': '🚫 تم حذف هذه الرسالة',
        'type': 'text', // تحويل النوع لنص
        'imageUrl': FieldValue.delete(), // حذف المرفقات إن وجدت
        'videoUrl': FieldValue.delete(),
        'audioUrl': FieldValue.delete(),
        'voiceUrl': FieldValue.delete(),
        'giftName': FieldValue.delete(),
        'reactions': {}, // مسح التفاعلات
      });
    } else {
      // حذف من عندي فقط: إضافة المستخدم لقائمة الإخفاء
      if (userId != null) {
        await msgRef.update({
          'deletedFor': FieldValue.arrayUnion([userId])
        });
      }
    }
  }

  Future<void> updateMessageText(
      String roomId, String messageId, String newText) {
    return _db
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .doc(messageId)
        .update({'text': newText, 'editedAt': FieldValue.serverTimestamp()});
  }

  Future<void> addReaction(
      String roomId, String messageId, String userId, String emoji) async {
    await _db
        .collection('chatRooms')
        .doc(roomId)
        .collection('messages')
        .doc(messageId)
        .update({'reactions.$userId': emoji});

    // إرسال إشعار بالتفاعل
    try {
      final roomSnap = await _db.collection('chatRooms').doc(roomId).get();
      if (roomSnap.exists) {
        final roomData = roomSnap.data()!;
        final List<String> participants =
            List<String>.from(roomData['participants'] ?? []);

        final senderDoc = await _db.collection('users').doc(userId).get();
        final senderName = senderDoc.data()?['name'] ?? 'مستخدم ملكي';

        for (final recipientUid in participants) {
          if (recipientUid == userId) continue;
          NotificationsService.sendPushNotification({
            'targetUid': recipientUid,
            'title': senderName,
            'body': 'تفاعل بـ $emoji على الرسالة',
            'type': 'reaction',
          });
        }
      }
    } catch (e) {
      _handleError("addReactionNotification", e);
    }
  }

  Future<void> togglePinChatMessage(
      String roomId, String messageId, bool pin) async {
    if (!_isValidId(roomId)) return;
    final batch = _db.batch();
    final roomRef = _db.collection('chatRooms').doc(roomId);
    final msgRef = roomRef.collection('messages').doc(messageId);

    batch.update(msgRef, {'isPinned': pin});

    if (pin) {
      batch.update(roomRef, {
        'pinnedMessages': FieldValue.arrayUnion([messageId])
      });
    } else {
      batch.update(roomRef, {
        'pinnedMessages': FieldValue.arrayRemove([messageId])
      });
    }
    await batch.commit();
  }

  Future<void> updateChatWallpaper(String roomId, String wallpaperUrl) {
    return _db
        .collection('chatRooms')
        .doc(roomId)
        .update({'wallpaperUrl': wallpaperUrl});
  }

  Future<void> manageGroupMember(
      String roomId, String userId, bool isAdding) async {
    if (isAdding) {
      await _db.collection('chatRooms').doc(roomId).update({
        'participants': FieldValue.arrayUnion([userId])
      });
    } else {
      await _db.collection('chatRooms').doc(roomId).update({
        'participants': FieldValue.arrayRemove([userId])
      });
    }
  }

  // --- الأصدقاء والمتابعة ---
  Stream<List<Map<String, dynamic>>> streamFriendRequests(String userId) {
    return _db
        .collection('friendRequests')
        .where('receiverId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  Future<void> sendFriendRequest(String senderId, String receiverId) async {
    await _db.collection('friendRequests').add({
      'senderId': senderId,
      'receiverId': receiverId,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
    // مكافأة طلب الصداقة
    await _rewardSocialAction(
        userId: senderId, actionType: 'friend_request', targetId: receiverId);
  }

  Future<void> acceptFriendRequest(
      String requestId, String senderId, String receiverId) async {
    final batch = _db.batch();
    batch.update(_db.collection('friendRequests').doc(requestId),
        {'status': 'accepted'});
    batch.update(_db.collection('users').doc(senderId), {
      'friends': FieldValue.arrayUnion([receiverId])
    });
    batch.update(_db.collection('users').doc(receiverId), {
      'friends': FieldValue.arrayUnion([senderId])
    });
    await batch.commit();
  }

  Future<void> rejectFriendRequest(String requestId) {
    return _db
        .collection('friendRequests')
        .doc(requestId)
        .update({'status': 'rejected'});
  }

  Future<void> cancelFriendRequest(String requestId) async {
    await _db.collection('friendRequests').doc(requestId).delete();
  }

  Future<Map<String, dynamic>> getFriendshipState(
      String currentUid, String otherUid) async {
    final userDoc = await _db.collection('users').doc(currentUid).get();
    final friends =
        (userDoc.data()?['friends'] as List?)?.whereType<String>().toList() ??
            <String>[];

    if (friends.contains(otherUid)) {
      return {'status': 'friends', 'requestId': null};
    }

    final pendingSent = await _db
        .collection('friendRequests')
        .where('senderId', isEqualTo: currentUid)
        .where('receiverId', isEqualTo: otherUid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (pendingSent.docs.isNotEmpty) {
      return {'status': 'pending', 'requestId': pendingSent.docs.first.id};
    }

    final pendingIncoming = await _db
        .collection('friendRequests')
        .where('senderId', isEqualTo: otherUid)
        .where('receiverId', isEqualTo: currentUid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (pendingIncoming.docs.isNotEmpty) {
      return {'status': 'incoming', 'requestId': pendingIncoming.docs.first.id};
    }

    return {'status': 'none', 'requestId': null};
  }

  // --- نظام المكافآت الاجتماعية (Social Rewards System) ---
  Future<void> _rewardSocialAction({
    required String userId,
    required String actionType, // 'like', 'friend_request', 'follow'
    String? targetId,
  }) async {
    if (!_isValidId(userId)) return;

    int gemsReward = 0;
    int coinsReward = 0;
    int socialPointsReward = 0;
    String message = "";

    switch (actionType) {
      case 'like':
        gemsReward = 5;
        socialPointsReward = 10;
        message = "حصلت على 5 جواهر لتفاعلك الملكي! ❤️";
        break;
      case 'friend_request':
        coinsReward = 5;
        socialPointsReward = 30;
        message = "حصلت على 5 نجوم لطلب الصداقة! 🤝";
        break;
      case 'follow':
        gemsReward = 2;
        coinsReward = 2;
        socialPointsReward = 20;
        message = "حصلت على مكافأة متابعة ملكية! ✨";
        break;
    }

    try {
      final userRef = _db.collection('users').doc(userId);

      await _db.runTransaction((tx) async {
        final userDoc = await tx.get(userRef);
        if (!userDoc.exists) return;

        // تحديث الرصيد والنقاط الاجتماعية
        tx.update(userRef, {
          if (gemsReward > 0) 'gems': FieldValue.increment(gemsReward),
          if (coinsReward > 0) 'stars': FieldValue.increment(coinsReward),
          if (coinsReward > 0) 'coins': FieldValue.increment(coinsReward),
          'agentData.friendlyCoins': FieldValue.increment(socialPointsReward),
        });

        // إضافة سجل في التاريخ الاجتماعي
        final logRef = userRef.collection('friendly_logs').doc();
        tx.set(logRef, {
          'action': actionType,
          'targetId': targetId,
          'gems': gemsReward,
          'stars': coinsReward,
          'points': socialPointsReward,
          'timestamp': FieldValue.serverTimestamp(),
          'message': message,
        });
      });

      // إشعار المستخدم بالمكافأة
      NotificationsService.sendExtendedNotification(
        userId: userId,
        type: NotificationType.general,
        title: 'مكافأة اجتماعية 🌟',
        body: message,
        enablePush: true,
      );

      // إذا كان هناك هدف (Target)، نمنحه نقاط اجتماعية أيضاً لزيادة شعبيته
      if (targetId != null && _isValidId(targetId)) {
        await _db.collection('users').doc(targetId).update({
          'agentData.friendlyCoins': FieldValue.increment(socialPointsReward),
        });
      }
    } catch (e) {
      _handleError("_rewardSocialAction", e);
    }
  }

  Future<void> toggleFollow(String currentUid, String targetUid) async {
    final targetRef = _db.collection('users').doc(targetUid);
    final currentRef = _db.collection('users').doc(currentUid);
    final doc = await targetRef.get();
    List followers = List.from(doc.data()?['followers'] ?? []);
    if (followers.contains(currentUid)) {
      await targetRef.update({
        'followers': FieldValue.arrayRemove([currentUid])
      });
      await currentRef.update({
        'following': FieldValue.arrayRemove([targetUid])
      });
    } else {
      await targetRef.update({
        'followers': FieldValue.arrayUnion([currentUid])
      });
      await currentRef.update({
        'following': FieldValue.arrayUnion([targetUid])
      });
      // مكافأة المتابعة
      await _rewardSocialAction(
          userId: currentUid, actionType: 'follow', targetId: targetUid);
    }
  }

  Future<void> blockUser(String currentUid, String targetUid) {
    return _db.collection('users').doc(currentUid).update({
      'blockedUsers': FieldValue.arrayUnion([targetUid])
    });
  }

  Future<void> unblockUser(String currentUid, String targetUid) {
    return _db.collection('users').doc(currentUid).update({
      'blockedUsers': FieldValue.arrayRemove([targetUid])
    });
  }

  // --- نظام البلاغات (UGC Compliance) ---
  Future<void> reportEntity({
    required String reporterId,
    required String targetId,
    required String type, // 'user', 'post', 'room'
    required String reason,
    String? content,
  }) async {
    await _db.collection('reports').add({
      'reporterId': reporterId,
      'targetId': targetId,
      'type': type,
      'reason': reason,
      'content': content,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }

  // --- الغرف ---
  Future<String> createRoom(
      {required String ownerId,
      required String roomName,
      String? roomImage,
      int? maxSeats}) async {
    final ref = _db.collection('rooms').doc();

    // تحديد نمط المايكات بناءً على العدد
    String micMode = '4-4';
    int finalMaxSeats = maxSeats ?? 8;

    if (finalMaxSeats > 8) {
      micMode = 'grid'; // النمط الشبكي للغرف الكبيرة
    }

    await ref.set({
      'ownerId': ownerId,
      'name': roomName,
      'image': roomImage ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'maxSeats': finalMaxSeats,
      'level': 1,
      'exp': 0,
      'micMode': micMode,
      'requireMicApproval': true, // تفعيل طلب الموافقة افتراضياً لضمان الاحترافية
      'muteChat': false,
      'mutePublic': false,
      'adminOnlyMic': false,
      'lockedSeats': [],
      'moderators': [],
    });
    return ref.id;
  }

  // --- المنشورات (اليوميات) ---
  Stream<List<PostModel>> streamUserPosts(String userId) {
    return _db
        .collection('posts')
        .where('authorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => PostModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<PostModel>> streamPostsFromAuthors(List<String> uids) {
    if (uids.isEmpty) return Stream.value([]);

    final batches = <List<String>>[];
    for (var i = 0; i < uids.length; i += 10) {
      batches.add(uids.sublist(i, i + 10 > uids.length ? uids.length : i + 10));
    }

    if (batches.length == 1) {
      return _db
          .collection('posts')
          .where('authorId', whereIn: batches.first)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .handleError((error) {
        debugPrint('Error in streamPostsFromAuthors: $error');
      }).map((snap) => snap.docs
              .map((doc) => PostModel.fromMap(doc.data(), doc.id))
              .toList());
    }

    final latestBatchResults = List<List<PostModel>>.filled(batches.length, []);
    final subscriptions = <StreamSubscription<List<PostModel>>>[];
    final controller = StreamController<List<PostModel>>.broadcast(
      onListen: () {},
      onCancel: () async {
        await Future.wait(subscriptions.map((s) => s.cancel()));
      },
    );

    for (var batchIndex = 0; batchIndex < batches.length; batchIndex++) {
      final batch = batches[batchIndex];
      final sub = _db
          .collection('posts')
          .where('authorId', whereIn: batch)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .handleError((error) {
            debugPrint('Error in streamPostsFromAuthors batch: $error');
          })
          .map((snap) => snap.docs
              .map((doc) => PostModel.fromMap(doc.data(), doc.id))
              .toList())
          .listen((posts) {
            latestBatchResults[batchIndex] = posts;
            final merged = latestBatchResults.expand((list) => list).toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            if (!controller.isClosed) {
              controller.add(merged);
            }
          }, onError: (error) {
            if (!controller.isClosed) controller.addError(error);
          });
      subscriptions.add(sub);
    }

    return controller.stream;
  }

  Future<PostModel?> getPostById(String postId) async {
    if (!_isValidId(postId)) return null;
    final doc = await _db.collection('posts').doc(postId).get();
    if (doc.exists) return PostModel.fromMap(doc.data()!, doc.id);
    return null;
  }

  Future<void> addPost(PostModel post) async {
    // نظام الرقابة الآلية البسيط (Automated Content Moderation)
    final bannedKeywords = ['سكس', 'جنس', 'مخدرات', 'قتل', 'إرهاب', 'تحرش'];
    bool isBanned = false;
    for (var word in bannedKeywords) {
      if (post.content.contains(word)) {
        isBanned = true;
        break;
      }
    }

    if (isBanned) {
      throw Exception(
          'عذراً، يحتوي منشورك على كلمات تخالف قوانين رويال دور الملكية 🛡️');
    }

    await _db.collection('posts').add(post.toMap());

    // إشعار نشر اليوميات سيتم عبر Cloud Function بعد حفظ المنشور
  }

  Future<void> toggleLike(String postId, String userId) async {
    final ref = _db.collection('posts').doc(postId);
    final doc = await ref.get();
    final data = doc.data() ?? {};
    List likes = List.from(data['likes'] ?? []);
    if (likes.contains(userId)) {
      await ref.update({
        'likes': FieldValue.arrayRemove([userId])
      });
    } else {
      await ref.update({
        'likes': FieldValue.arrayUnion([userId])
      });
      // مكافأة الإعجاب بالمنشور
      await _rewardSocialAction(
          userId: userId, actionType: 'like', targetId: data['authorId']);
    }
  }

  Future<void> togglePinPost(String postId, bool pin) =>
      _db.collection('posts').doc(postId).update({'isPinned': pin});

  Future<void> deletePost(String postId) =>
      _db.collection('posts').doc(postId).delete();

  Future<void> updatePostContent(String postId, String content) =>
      _db.collection('posts').doc(postId).update({'content': content});

  Future<void> updatePost(String postId, Map<String, dynamic> data) =>
      _db.collection('posts').doc(postId).update(data);

  Stream<List<Map<String, dynamic>>> streamPostComments(String postId) {
    return _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  Future<void> addPostComment(
      String postId, String userId, String name, String pic, String text,
      {String? parentId, String? replyToName}) async {
    await _db.collection('posts').doc(postId).collection('comments').add({
      'userId': userId,
      'userName': name,
      'userPic': pic,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'parentId': parentId,
      'replyToName': replyToName,
      'likes': [],
    });

    // زيادة عداد التعليقات في المنشور
    await _db
        .collection('posts')
        .doc(postId)
        .update({'commentCount': FieldValue.increment(1)});
  }

  Future<void> editPostComment(String postId, String commentId, String text) =>
      _db
          .collection('posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .update({'text': text});

  Future<void> deletePostComment(String postId, String commentId) async {
    await _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId)
        .delete();
    // تقليل عداد التعليقات
    await _db
        .collection('posts')
        .doc(postId)
        .update({'commentCount': FieldValue.increment(-1)});
  }

  Future<void> togglePostCommentLike(
      String postId, String commentId, String userId) async {
    final ref = _db
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .doc(commentId);
    final doc = await ref.get();
    List likes = List.from(doc.data()?['likes'] ?? []);
    likes.contains(userId)
        ? await ref.update({
            'likes': FieldValue.arrayRemove([userId])
          })
        : await ref.update({
            'likes': FieldValue.arrayUnion([userId])
          });
  }

  // --- القصص (Stories) ---
  Stream<List<StoryModel>> streamStories() {
    return _db
        .collection('stories')
        .where('createdAt',
            isGreaterThan: DateTime.now().subtract(const Duration(hours: 24)))
        .snapshots()
        .handleError((error) {
      _handleError("streamStories", error);
    }).map((snap) {
      final list = snap.docs
          .map((doc) => StoryModel.fromMap(doc.data(), doc.id))
          .toList();
      // ترتيب القصص برمجياً لتجنب الحاجة لـ Index مركب
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> addStory({
    required String userId,
    required String userName,
    required String userPic,
    String? imageUrl,
    String? videoUrl,
    String? imageStoragePath,
    String? videoStoragePath,
    String? postReference,
    String? postContent,
    String? postAuthorName,
    String? storyText,
    String? storyBackgroundColor,
    String? storyFilter,
  }) async {
    final storyData = {
      'userId': userId,
      'userName': userName,
      'userPic': userPic,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'imageStoragePath': imageStoragePath,
      'videoStoragePath': videoStoragePath,
      'createdAt': FieldValue.serverTimestamp(),
    };

    // إضافة حقول مرجع المنشور إذا وجدت
    if (postReference != null) {
      storyData['postReference'] = postReference;
    }
    if (postContent != null) {
      storyData['postContent'] = postContent;
    }
    if (postAuthorName != null) {
      storyData['postAuthorName'] = postAuthorName;
    }

    // إضافة حقول القصة النصية إذا وجدت
    if (storyText != null) {
      storyData['storyText'] = storyText;
    }
    if (storyBackgroundColor != null) {
      storyData['storyBackgroundColor'] = storyBackgroundColor;
    }
    if (storyFilter != null) {
      storyData['storyFilter'] = storyFilter;
    }

    await _db.collection('stories').add(storyData);

    // إشعار نشر القصة سيتم عبر Cloud Function بعد حفظ المستند
  }

  Future<void> markStoryViewed(String storyId, String userId) =>
      _db.collection('stories').doc(storyId).update({
        'viewers': FieldValue.arrayUnion([userId])
      });

  Future<void> toggleStoryLike(String storyId, String userId) async {
    final ref = _db.collection('stories').doc(storyId);
    final doc = await ref.get();
    List likes = List.from(doc.data()?['likes'] ?? []);
    likes.contains(userId)
        ? await ref.update({
            'likes': FieldValue.arrayRemove([userId])
          })
        : await ref.update({
            'likes': FieldValue.arrayUnion([userId])
          });
  }

  Future<void> toggleStoryArchive(String storyId, String userId) async {
    final ref = _db.collection('stories').doc(storyId);
    final doc = await ref.get();
    List archivedBy = List.from(doc.data()?['archivedBy'] ?? []);
    archivedBy.contains(userId)
        ? await ref.update({
            'archivedBy': FieldValue.arrayRemove([userId])
          })
        : await ref.update({
            'archivedBy': FieldValue.arrayUnion([userId])
          });
  }

  Stream<List<StoryModel>> streamArchivedStories(String userId) {
    return _db
        .collection('stories')
        .where('archivedBy', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              return StoryModel.fromMap(data, doc.id);
            }).toList());
  }

  Future<void> addStoryReply(String storyId, String userId, String name,
          String pic, String text) =>
      _db.collection('stories').doc(storyId).collection('replies').add({
        'userId': userId,
        'userName': name,
        'userPic': pic,
        'text': text,
        'createdAt': FieldValue.serverTimestamp()
      });

  Future<void> deleteStory(String storyId) async {
    try {
      final doc = await _db.collection('stories').doc(storyId).get();
      if (!doc.exists) return;

      final data = doc.data() ?? {};

      // حذف ملفات التخزين إن وجدت
      if (data['imageStoragePath'] != null &&
          (data['imageStoragePath'] as String).isNotEmpty) {
        try {
          await FirebaseStorage.instance
              .ref()
              .child(data['imageStoragePath'])
              .delete();
        } catch (e) {
          debugPrint('خطأ في حذف صورة القصة: $e');
        }
      }

      if (data['videoStoragePath'] != null &&
          (data['videoStoragePath'] as String).isNotEmpty) {
        try {
          await FirebaseStorage.instance
              .ref()
              .child(data['videoStoragePath'])
              .delete();
        } catch (e) {
          debugPrint('خطأ في حذف فيديو القصة: $e');
        }
      }

      // حذف القصة والردود عليها
      final repliesSnap = await _db
          .collection('stories')
          .doc(storyId)
          .collection('replies')
          .get();
      for (var doc in repliesSnap.docs) {
        await doc.reference.delete();
      }

      // حذف القصة نفسها
      await _db.collection('stories').doc(storyId).delete();
    } catch (e) {
      debugPrint('خطأ في حذف القصة: $e');
      rethrow;
    }
  }

  Future<void> sendGiftInChat(
      {required String roomId,
      required String senderId,
      required String receiverId,
      required Map<String, dynamic> gift}) async {
    await sendMessage(
        roomId,
        MessageModel(
          id: '',
          senderId: senderId,
          text: 'أرسل هدية 🎁',
          type: MessageType.gift,
          giftName: gift['name'],
          timestamp: DateTime.now(),
        ));
  }

  Future<void> recordProfileVisit(String viewerUid, String targetUid) async {
    if (!_isValidId(targetUid)) return;
    await _db
        .collection('users')
        .doc(targetUid)
        .collection('visitors')
        .doc(viewerUid)
        .set({'timestamp': FieldValue.serverTimestamp()});
  }

  Future<void> toggleProfileLike(String visitorId, String targetUid) async {
    final ref = _db.collection('users').doc(targetUid);
    final doc = await ref.get();
    List likes = List.from(doc.data()?['profileLikes'] ?? []);
    if (likes.contains(visitorId)) {
      await ref.update({
        'profileLikes': FieldValue.arrayRemove([visitorId])
      });
    } else {
      await ref.update({
        'profileLikes': FieldValue.arrayUnion([visitorId])
      });
      // مكافأة الإعجاب بالبروفايل
      await _rewardSocialAction(
          userId: visitorId, actionType: 'like', targetId: targetUid);
    }
  }

  Stream<List<UserModel>> streamVisitors(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('visitors')
        .snapshots()
        .asyncMap((snap) async {
      List<UserModel> users = [];
      final now = DateTime.now();
      final twentyFourHoursAgo = now.subtract(const Duration(hours: 24));

      for (var d in snap.docs) {
        final data = d.data();
        final timestamp = data['timestamp'] as Timestamp?;

        if (timestamp != null) {
          final visitTime = timestamp.toDate();
          // فلترة الزوار الذين زاروا خلال آخر 24 ساعة فقط
          if (visitTime.isAfter(twentyFourHoursAgo)) {
            var u = await _db.collection('users').doc(d.id).get();
            if (u.exists) users.add(UserModel.fromMap(u.data()!, u.id));
          }
        }
      }
      return users;
    });
  }

  Stream<List<UserModel>> streamFriends(String uid) {
    return _db.collection('users').doc(uid).snapshots().asyncMap((snap) async {
      if (!snap.exists) return [];
      final data = UserModel.fromMap(snap.data() ?? {}, snap.id);
      final friendUids = data.friends;
      if (friendUids.isEmpty) return [];
      final usersSnap = await _db
          .collection('users')
          .where(FieldPath.documentId, whereIn: friendUids.take(10).toList())
          .get();
      return usersSnap.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<List<UserModel>> streamUsersFromList(List<String> uids) {
    if (uids.isEmpty) return Stream.value([]);
    return _db
        .collection('users')
        .where(FieldPath.documentId, whereIn: uids.take(10).toList())
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => UserModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<Map<String, dynamic>> getDailyRewardStatus(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return {
      'lastClaimed': doc.data()?['lastClaimedAt'],
      'streak': doc.data()?['rewardStreak'] ?? 0
    };
  }

  Future<String> ensureChatRoomExists(String uidA, String uidB) async {
    final roomId = [uidA, uidB]..sort();
    final id = roomId.join('_');
    final ref = _db.collection('chatRooms').doc(id);
    if (!(await ref.get()).exists) {
      await ref.set({
        'participants': roomId,
        'lastMessageTime': FieldValue.serverTimestamp()
      });
    }
    return id;
  }

  Future<void> toggleFollowRoom(String userId, String roomId) async {
    if (!_isValidId(userId) || !_isValidId(roomId)) return;
    final userRef = _db.collection('users').doc(userId);
    final userDoc = await userRef.get();

    if (!userDoc.exists) return;

    final followingRooms = Map<String, dynamic>.from(
        (userDoc.data()?['following_rooms'] as Map?) ?? {});

    if (followingRooms[roomId] == true) {
      followingRooms.remove(roomId);
    } else {
      followingRooms[roomId] = true;
    }

    await userRef.update({'following_rooms': followingRooms});
  }
}
