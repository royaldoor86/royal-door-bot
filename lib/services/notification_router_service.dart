import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../features/chat/individual_chat_page.dart';
import '../features/profile/friends_lists_page.dart';
import '../features/voice_room_page.dart';
import '../features/diaries/story_viewer.dart';
import '../features/diaries/single_post_page.dart';
import '../models/story_model.dart';
import '../models/user_model.dart';

/// Enhanced notification types with action support
enum EnhancedNotificationType {
  message, // رسائل - مع أزرار رد وغيرها
  friendRequest, // طلبات صداقة - مع أزرار قبول/رفض
  like, // إعجابات - تمييز كمقروء وإخفاء بعد النقر
  battle, // معارك - مع أزرار دخول/خروج
  story, // استوريات - مع زر إلغاء
  dailyPost, // يوميات - مع زر إلغاء
  post, // منشورات عادية
  reward, // مكافآت
  general, // عام
}

/// Notification action button configuration
class NotificationAction {
  final String id;
  final String label;
  final String action; // reply, accept, reject, enter, exit, cancel, etc.

  NotificationAction({
    required this.id,
    required this.label,
    required this.action,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'action': action,
    };
  }

  factory NotificationAction.fromMap(Map<String, dynamic> data) {
    return NotificationAction(
      id: data['id'] as String,
      label: data['label'] as String,
      action: data['action'] as String,
    );
  }
}

/// Enhanced notification data model
class EnhancedNotificationData {
  final String type;
  final String? targetId;
  final String? userId;
  final String? chatId;
  final String? roomId;
  final String? postId;
  final String? storyId;
  final List<NotificationAction> actions;
  final Map<String, dynamic> extraData;

  EnhancedNotificationData({
    required this.type,
    this.targetId,
    this.userId,
    this.chatId,
    this.roomId,
    this.postId,
    this.storyId,
    this.actions = const [],
    this.extraData = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'targetId': targetId,
      'userId': userId,
      'chatId': chatId,
      'roomId': roomId,
      'postId': postId,
      'storyId': storyId,
      'actions': actions.map((a) => a.toMap()).toList(),
      'extraData': extraData,
    };
  }

  factory EnhancedNotificationData.fromMap(Map<String, dynamic> data) {
    final actionsList = (data['actions'] as List?)
            ?.map((a) => NotificationAction.fromMap(a as Map<String, dynamic>))
            .toList() ??
        [];

    return EnhancedNotificationData(
      type: data['type'] as String,
      targetId: data['targetId'] as String?,
      userId: data['userId'] as String?,
      chatId: data['chatId'] as String?,
      roomId: data['roomId'] as String?,
      postId: data['postId'] as String?,
      storyId: data['storyId'] as String?,
      actions: actionsList,
      extraData: Map<String, dynamic>.from(data['extraData'] as Map? ?? {}),
    );
  }

  static EnhancedNotificationData forMessage({
    required String chatId,
    required String userId,
    String? messageId,
  }) {
    return EnhancedNotificationData(
      type: 'message',
      chatId: chatId,
      userId: userId,
      targetId: messageId,
      actions: [
        NotificationAction(id: 'reply', label: 'رد', action: 'reply'),
        NotificationAction(id: 'view', label: 'عرض', action: 'view'),
      ],
    );
  }

  static EnhancedNotificationData forFriendRequest({
    required String userId,
    required String requestId,
  }) {
    return EnhancedNotificationData(
      type: 'friendRequest',
      userId: userId,
      targetId: requestId,
      actions: [
        NotificationAction(id: 'accept', label: 'قبول', action: 'accept'),
        NotificationAction(id: 'reject', label: 'رفض', action: 'reject'),
      ],
    );
  }

  static EnhancedNotificationData forLike({
    required String userId,
    required String targetId,
    required String targetType, // post, story, etc.
  }) {
    return EnhancedNotificationData(
      type: 'like',
      userId: userId,
      targetId: targetId,
      extraData: {'targetType': targetType},
    );
  }

  static EnhancedNotificationData forBattle({
    required String roomId,
    required String battleId,
  }) {
    return EnhancedNotificationData(
      type: 'battle',
      roomId: roomId,
      targetId: battleId,
      actions: [
        NotificationAction(id: 'enter', label: 'دخول', action: 'enter'),
        NotificationAction(id: 'exit', label: 'خروج', action: 'exit'),
      ],
    );
  }

  static EnhancedNotificationData forStory({
    required String storyId,
    required String userId,
  }) {
    return EnhancedNotificationData(
      type: 'story',
      storyId: storyId,
      userId: userId,
      targetId: storyId,
      actions: [
        NotificationAction(id: 'cancel', label: 'إلغاء', action: 'cancel'),
      ],
    );
  }

  static EnhancedNotificationData forDailyPost({
    required String postId,
    required String userId,
  }) {
    return EnhancedNotificationData(
      type: 'dailyPost',
      postId: postId,
      userId: userId,
      targetId: postId,
      actions: [
        NotificationAction(id: 'cancel', label: 'إلغاء', action: 'cancel'),
      ],
    );
  }
}

/// Service for routing notifications with deep linking and action handling
class NotificationRouterService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Handle notification tap with routing
  static Future<void> handleNotificationTap(
    Map<String, dynamic> data, {
    String? action,
  }) async {
    final enhancedData = EnhancedNotificationData.fromMap(data);
    final navigator = navigatorKey.currentState;

    if (navigator == null) {
      debugPrint('Navigator not available');
      return;
    }

    // Handle action buttons first
    if (action != null) {
      await _handleAction(action, enhancedData);
      return;
    }

    // Handle main notification tap based on type
    switch (enhancedData.type) {
      case 'message':
        await _navigateToMessage(enhancedData, navigator);
        break;
      case 'friendRequest':
        await _navigateToFriendRequest(enhancedData, navigator);
        break;
      case 'like':
        await _handleLikeNotification(enhancedData, navigator);
        break;
      case 'battle':
        await _navigateToBattle(enhancedData, navigator);
        break;
      case 'story':
        await _navigateToStory(enhancedData, navigator);
        break;
      case 'dailyPost':
        await _navigateToDailyPost(enhancedData, navigator);
        break;
      case 'post':
        await _navigateToPost(enhancedData, navigator);
        break;
      case 'reward':
        await _navigateToReward(enhancedData, navigator);
        break;
      default:
        // General notification - just open app
        debugPrint('General notification opened');
    }
  }

  /// Handle notification action button clicks
  static Future<void> _handleAction(
    String action,
    EnhancedNotificationData data,
  ) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    switch (action) {
      case 'reply':
        // Navigate to chat with reply intent
        if (data.chatId != null) {
          // Get room info to navigate properly
          final roomDoc = await FirebaseFirestore.instance
              .collection('chatRooms')
              .doc(data.chatId)
              .get();
          if (roomDoc.exists) {
            final roomData = roomDoc.data();
            final participants = roomData?['participants'] as List<dynamic>?;
            final otherUserId = participants?.firstWhere((id) => id != currentUser.uid, orElse: () => null) as String?;
            
            if (otherUserId != null) {
              final otherUserDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(otherUserId)
                  .get();
              if (otherUserDoc.exists) {
                final otherUser = UserModel.fromMap(otherUserDoc.data() as Map<String, dynamic>, otherUserId);
                navigatorKey.currentState?.push(
                  MaterialPageRoute(
                    builder: (_) => IndividualChatPage(
                      otherUser: otherUser,
                      roomId: data.chatId!,
                    ),
                  ),
                );
              }
            }
          }
        }
        break;

      case 'accept':
        await _acceptFriendRequest(data.targetId ?? '', currentUser.uid);
        break;

      case 'reject':
        await _rejectFriendRequest(data.targetId ?? '', currentUser.uid);
        break;

      case 'enter':
        await _enterBattle(data.roomId ?? '', data.targetId ?? '');
        break;

      case 'exit':
        await _exitBattle(data.roomId ?? '', data.targetId ?? '');
        break;

      case 'cancel':
        await _cancelPostOrStory(data);
        break;

      case 'view':
        if (data.chatId != null) {
          // Get room info to navigate properly
          final roomDoc = await FirebaseFirestore.instance
              .collection('chatRooms')
              .doc(data.chatId)
              .get();
          if (roomDoc.exists) {
            final roomData = roomDoc.data();
            final participants = roomData?['participants'] as List<dynamic>?;
            final otherUserId = participants?.firstWhere((id) => id != currentUser.uid, orElse: () => null) as String?;
            
            if (otherUserId != null) {
              final otherUserDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(otherUserId)
                  .get();
              if (otherUserDoc.exists) {
                final otherUser = UserModel.fromMap(otherUserDoc.data() as Map<String, dynamic>, otherUserId);
                navigatorKey.currentState?.push(
                  MaterialPageRoute(
                    builder: (_) => IndividualChatPage(
                      otherUser: otherUser,
                      roomId: data.chatId!,
                    ),
                  ),
                );
              }
            }
          }
        }
        break;
    }
  }

  /// Navigate to message/chat
  static Future<void> _navigateToMessage(
    EnhancedNotificationData data,
    NavigatorState navigator,
  ) async {
    if (data.chatId != null) {
      // Get room info to navigate properly
      final roomDoc = await FirebaseFirestore.instance
          .collection('chatRooms')
          .doc(data.chatId)
          .get();
      if (roomDoc.exists) {
        final roomData = roomDoc.data();
        final participants = roomData?['participants'] as List<dynamic>?;
        final otherUserId = participants?.firstWhere((id) => id != _auth.currentUser?.uid, orElse: () => null) as String?;
        
        if (otherUserId != null) {
          final otherUserDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(otherUserId)
              .get();
          if (otherUserDoc.exists) {
            final otherUser = UserModel.fromMap(otherUserDoc.data() as Map<String, dynamic>, otherUserId);
            navigator.push(
              MaterialPageRoute(
                builder: (_) => IndividualChatPage(
                  otherUser: otherUser,
                  roomId: data.chatId!,
                ),
              ),
            );
          }
        }
      }
    }
  }

  /// Navigate to friend request
  static Future<void> _navigateToFriendRequest(
    EnhancedNotificationData data,
    NavigatorState navigator,
  ) async {
    navigator.push(
      MaterialPageRoute(
        builder: (_) => const FriendsListsPage(initialIndex: 1), // Requests tab
      ),
    );
  }

  /// Handle like notification - mark as read and dismiss
  static Future<void> _handleLikeNotification(
    EnhancedNotificationData data,
    NavigatorState navigator,
  ) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      // Mark notification as read in Firestore
      await _firestore
          .collection('notifications')
          .doc(currentUser.uid)
          .collection('items')
          .where('type', isEqualTo: 'like')
          .where('data.targetId', isEqualTo: data.targetId)
          .where('data.userId', isEqualTo: data.userId)
          .limit(1)
          .get()
          .then((snapshot) {
        for (var doc in snapshot.docs) {
          doc.reference.update({'read': true});
        }
      });

      // Optionally navigate to the liked content
      final targetType = data.extraData['targetType'] as String?;
      if (targetType == 'post' && data.postId != null) {
        navigator.push(
          MaterialPageRoute(
            builder: (_) => SinglePostPage(postId: data.postId!),
          ),
        );
      } else if (targetType == 'story' && data.storyId != null) {
        await _openStoryById(data.storyId!);
      }
    } catch (e) {
      debugPrint('Error handling like notification: $e');
    }
  }

  /// Navigate to battle
  static Future<void> _navigateToBattle(
    EnhancedNotificationData data,
    NavigatorState navigator,
  ) async {
    if (data.roomId != null) {
      // Get room info to fetch room name
      final roomDoc = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(data.roomId)
          .get();
      
      final roomName = roomDoc.exists ? (roomDoc.data()?['name'] as String? ?? 'غرفة صوتية') : 'غرفة صوتية';
      
      navigator.push(
        MaterialPageRoute(
          builder: (_) => VoiceRoomPage(
            roomId: data.roomId!,
            roomName: roomName,
          ),
        ),
      );
    }
  }

  /// Navigate to story
  static Future<void> _navigateToStory(
    EnhancedNotificationData data,
    NavigatorState navigator,
  ) async {
    if (data.storyId != null) {
      await _openStoryById(data.storyId!);
    }
  }

  /// Navigate to daily post
  static Future<void> _navigateToDailyPost(
    EnhancedNotificationData data,
    NavigatorState navigator,
  ) async {
    if (data.postId != null) {
      navigator.push(
        MaterialPageRoute(
          builder: (_) => SinglePostPage(postId: data.postId!),
        ),
      );
    }
  }

  /// Navigate to regular post
  static Future<void> _navigateToPost(
    EnhancedNotificationData data,
    NavigatorState navigator,
  ) async {
    if (data.postId != null) {
      navigator.push(
        MaterialPageRoute(
          builder: (_) => SinglePostPage(postId: data.postId!),
        ),
      );
    }
  }

  /// Navigate to rewards
  static Future<void> _navigateToReward(
    EnhancedNotificationData data,
    NavigatorState navigator,
  ) async {
    // Import rewards page if needed
    // navigator.push(MaterialPageRoute(builder: (_) => const RewardsPage()));
  }

  /// Open story by ID
  static Future<void> _openStoryById(String storyId) async {
    try {
      final storyDoc = await _firestore.collection('stories').doc(storyId).get();
      if (!storyDoc.exists) return;

      final storyData = storyDoc.data();
      if (storyData == null) return;

      final authorId = storyData['userId'] as String?;
      if (authorId == null || authorId.isEmpty) return;

      final storiesSnap = await _firestore
          .collection('stories')
          .where('userId', isEqualTo: authorId)
          .orderBy('createdAt', descending: true)
          .get();

      final stories = storiesSnap.docs
          .map((doc) => StoryModel.fromMap(doc.data(), doc.id))
          .toList();

      int initialIndex = stories.indexWhere((s) => s.id == storyId);
      if (initialIndex < 0) {
        initialIndex = 0;
      }

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => StoryViewer(
            stories: stories,
            initialIndex: initialIndex,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error opening story from notification: $e');
    }
  }

  /// Accept friend request
  static Future<void> _acceptFriendRequest(
    String requestId,
    String currentUserId,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friend_requests')
          .doc(requestId)
          .update({'status': 'accepted'});
      
      debugPrint('Friend request accepted');
    } catch (e) {
      debugPrint('Error accepting friend request: $e');
    }
  }

  /// Reject friend request
  static Future<void> _rejectFriendRequest(
    String requestId,
    String currentUserId,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('friend_requests')
          .doc(requestId)
          .update({'status': 'rejected'});
      
      debugPrint('Friend request rejected');
    } catch (e) {
      debugPrint('Error rejecting friend request: $e');
    }
  }

  /// Enter battle
  static Future<void> _enterBattle(String roomId, String battleId) async {
    try {
      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('battles')
          .doc(battleId)
          .update({
        'participants': FieldValue.arrayUnion([_auth.currentUser?.uid])
      });
      
      // Get room info to fetch room name
      final roomDoc = await FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .get();
      
      final roomName = roomDoc.exists ? (roomDoc.data()?['name'] as String? ?? 'غرفة صوتية') : 'غرفة صوتية';
      
      // Navigate to room
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => VoiceRoomPage(
            roomId: roomId,
            roomName: roomName,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error entering battle: $e');
    }
  }

  /// Exit battle
  static Future<void> _exitBattle(String roomId, String battleId) async {
    try {
      await _firestore
          .collection('rooms')
          .doc(roomId)
          .collection('battles')
          .doc(battleId)
          .update({
        'participants': FieldValue.arrayRemove([_auth.currentUser?.uid])
      });
      
      debugPrint('Exited battle');
    } catch (e) {
      debugPrint('Error exiting battle: $e');
    }
  }

  /// Cancel post or story
  static Future<void> _cancelPostOrStory(EnhancedNotificationData data) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;

    try {
      if (data.type == 'story' && data.storyId != null) {
        await _firestore
            .collection('stories')
            .doc(data.storyId)
            .delete();
      } else if (data.postId != null) {
        await _firestore
            .collection('posts')
            .doc(data.postId)
            .delete();
      }
      
      debugPrint('Post/story cancelled');
    } catch (e) {
      debugPrint('Error cancelling post/story: $e');
    }
  }

  /// Create notification with actions for Android
  static Future<void> showNotificationWithActions({
    required String title,
    required String body,
    required EnhancedNotificationData data,
    int id = 0,
  }) async {
    final FlutterLocalNotificationsPlugin plugin =
        FlutterLocalNotificationsPlugin();

    final androidDetails = AndroidNotificationDetails(
      'enhanced_notifications_channel',
      'إشعارات محسنة',
      channelDescription: 'إشعارات مع أزرار إجراءات',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
      icon: '@mipmap/ic_launcher',
      category: AndroidNotificationCategory.message,
      styleInformation: BigTextStyleInformation(body),
    );

    // Add action buttons if available
    List<AndroidNotificationAction> actions = [];
    for (var action in data.actions) {
      actions.add(
        AndroidNotificationAction(
          action.id,
          action.label,
          showsUserInterface: true,
        ),
      );
    }

    if (actions.isNotEmpty) {
      // Create a separate notification with actions
      final androidDetailsWithActions = AndroidNotificationDetails(
        'enhanced_notifications_channel',
        'إشعارات محسنة',
        channelDescription: 'إشعارات مع أزرار إجراءات',
        importance: Importance.high,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
        category: AndroidNotificationCategory.message,
        styleInformation: BigTextStyleInformation(body),
        actions: actions,
      );

      await plugin.show(
        id,
        title,
        body,
        NotificationDetails(android: androidDetailsWithActions),
        payload: jsonEncode(data.toMap()),
      );
    } else {
      await plugin.show(
        id,
        title,
        body,
        NotificationDetails(android: androidDetails),
        payload: jsonEncode(data.toMap()),
      );
    }
  }
}
