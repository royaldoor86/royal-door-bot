import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import '../app_theme.dart';
import 'profile/user_details_view_page.dart';
import '../models/user_model.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A12),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'الإشعارات',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.done_all, color: Colors.white70),
              onPressed: _markAllAsRead,
              tooltip: 'تعليم الكل كمقروء',
            ),
          ],
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: _db
              .collection('users')
              .doc(_currentUserId)
              .collection('notifications')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.royalGold),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'لا توجد إشعارات حالياً',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }

            final notifications = snapshot.data!.docs;
            final unreadCount = notifications
                .where((doc) => !((doc.data() as Map)['isRead'] ?? false))
                .length;

            return Column(
              children: [
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    color: AppTheme.royalGold.withValues(alpha: 0.1),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.mark_email_unread,
                          color: AppTheme.royalGold,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'لديك $unreadCount إشعار غير مقروء',
                          style: const TextStyle(
                            color: AppTheme.royalGold,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _markAllAsRead,
                          child: const Text(
                            'تعليم الكل كمقروء',
                            style: TextStyle(
                              color: AppTheme.royalGold,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification =
                          notifications[index].data() as Map<String, dynamic>;
                      final docId = notifications[index].id;
                      final isRead = notification['isRead'] ?? false;

                      return _buildNotificationCard(
                        notification,
                        docId,
                        isRead,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationCard(
    Map<String, dynamic> notification,
    String docId,
    bool isRead,
  ) {
    final String title = notification['title'] ?? 'إشعار جديد';
    final String body = notification['body'] ?? '';
    final String type = notification['type'] ?? 'general';
    final String? senderId = notification['senderId'];
    final String? senderName = notification['senderName'];
    final String? senderPic = notification['senderPic'];
    final String? targetId = notification['targetId'];
    final String? targetType = notification['targetType'];
    final Timestamp? timestamp = notification['timestamp'];

    return GestureDetector(
      onTap: () =>
          _handleNotificationTap(docId, type, targetId, targetType, senderId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: isRead
              ? Colors.white.withValues(alpha: 0.02)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isRead
                ? Colors.white.withValues(alpha: 0.05)
                : AppTheme.royalGold.withValues(alpha: 0.3),
            width: isRead ? 1 : 2,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getNotificationColor(type).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: senderPic != null && senderPic.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: senderPic,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.royalGold,
                            strokeWidth: 2,
                          ),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          _getNotificationIcon(type),
                          color: _getNotificationColor(type),
                          size: 24,
                        ),
                      ),
                    )
                  : Icon(
                      _getNotificationIcon(type),
                      color: _getNotificationColor(type),
                      size: 24,
                    ),
            ),
            const SizedBox(width: 15),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight:
                                isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.royalGold,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (senderName != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          senderName,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    _formatTimestamp(timestamp),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'comment':
        return Icons.comment;
      case 'follow':
        return Icons.person_add;
      case 'friend_request':
        return Icons.person_add_alt_1;
      case 'gift':
        return Icons.card_giftcard;
      case 'badge':
        return Icons.workspace_premium;
      case 'system':
        return Icons.notifications;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'like':
        return Colors.red;
      case 'comment':
        return Colors.blue;
      case 'follow':
        return Colors.green;
      case 'friend_request':
        return Colors.purple;
      case 'gift':
        return Colors.pink;
      case 'badge':
        return Colors.amber;
      case 'system':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final notificationTime = timestamp.toDate();
    final difference = now.difference(notificationTime);

    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else if (difference.inDays < 7) {
      return 'منذ ${difference.inDays} يوم';
    } else {
      return '${notificationTime.day}/${notificationTime.month}/${notificationTime.year}';
    }
  }

  Future<void> _handleNotificationTap(
    String docId,
    String type,
    String? targetId,
    String? targetType,
    String? senderId,
  ) async {
    // تعليم الإشعار كمقروء أولاً
    await _markAsRead(docId);

    // التنقل بناءً على نوع الإشعار
    if (!mounted) return;

    switch (type) {
      case 'follow':
      case 'friend_request':
        if (senderId != null) {
          _navigateToUserProfile(senderId);
        }
        break;
      case 'like':
      case 'comment':
        if (targetId != null && targetType != null) {
          _navigateToPost(targetId, targetType);
        }
        break;
      case 'gift':
      case 'badge':
      case 'reward':
        // التنقل إلى صفحة البروفايل للمستخدم
        if (senderId != null) {
          _navigateToUserProfile(senderId);
        }
        break;
      case 'chat':
      case 'message':
        if (targetId != null) {
          _navigateToChat(targetId);
        }
        break;
      case 'room_invite':
      case 'voice_room':
        if (targetId != null) {
          _navigateToRoom(targetId);
        }
        break;
      case 'royal_id_request':
        // الإشعارات الخاصة بطلب تغيير الآيدي الملكي
        break;
      case 'system':
      case 'announcement':
        // الإشعارات النظامية لا تتطلب تنقل
        break;
      case 'level_up':
        // التنقل إلى صفحة المستوى عند ترقية المستوى
        if (senderId != null) {
          _navigateToUserProfile(senderId);
        }
        break;
      default:
        // التنقل الافتراضي إلى البروفايل إذا كان هناك senderId
        if (senderId != null) {
          _navigateToUserProfile(senderId);
        }
    }
  }

  Future<void> _navigateToUserProfile(String userId) async {
    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      if (!userDoc.exists) return;

      final userData =
          UserModel.fromMap(userDoc.data() as Map<String, dynamic>, userId);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UserDetailsViewPage(user: userData),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error navigating to user profile: $e');
    }
  }

  Future<void> _navigateToPost(String postId, String postType) async {
    // يمكن إضافة التنقل إلى المنشورات هنا
    // حالياً سنعرض رسالة أن هذه الميزة قيد التطوير
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('سيتم إضافة التنقل إلى المنشورات قريباً'),
          backgroundColor: AppTheme.royalGold,
        ),
      );
    }
  }

  Future<void> _navigateToChat(String roomId) async {
    // يمكن إضافة التنقل إلى المحادثات هنا
    // حالياً سنعرض رسالة أن هذه الميزة قيد التطوير
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('سيتم إضافة التنقل إلى المحادثات قريباً'),
          backgroundColor: AppTheme.royalGold,
        ),
      );
    }
  }

  Future<void> _navigateToRoom(String roomId) async {
    // يمكن إضافة التنقل إلى الغرف الصوتية هنا
    // حالياً سنعرض رسالة أن هذه الميزة قيد التطوير
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('سيتم إضافة التنقل إلى الغرف الصوتية قريباً'),
          backgroundColor: AppTheme.royalGold,
        ),
      );
    }
  }

  Future<void> _markAsRead(String docId) async {
    try {
      await _db
          .collection('users')
          .doc(_currentUserId)
          .collection('notifications')
          .doc(docId)
          .update({'isRead': true});
      HapticFeedback.lightImpact();
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(_currentUserId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      final batch = _db.batch();
      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تعليم جميع الإشعارات كمقروء'),
            backgroundColor: AppTheme.royalGold,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
    }
  }
}
