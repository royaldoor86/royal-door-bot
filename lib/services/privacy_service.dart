import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/privacy_model.dart';

/// Service for managing privacy settings and access control
class PrivacyService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get user's privacy settings
  static Future<UserPrivacySettings> getUserPrivacySettings(
      String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('privacy')
          .get();

      if (doc.exists) {
        return UserPrivacySettings.fromMap(doc.data()!);
      }

      // Return default settings if not found
      return UserPrivacySettings(userId: userId);
    } catch (e) {
      debugPrint('Error getting privacy settings: $e');
      return UserPrivacySettings(userId: userId);
    }
  }

  /// Save user's privacy settings
  static Future<void> savePrivacySettings(
      UserPrivacySettings settings) async {
    try {
      await _firestore
          .collection('users')
          .doc(settings.userId)
          .collection('settings')
          .doc('privacy')
          .set(settings.toMap());
    } catch (e) {
      debugPrint('Error saving privacy settings: $e');
      rethrow;
    }
  }

  /// Check if a user can view content based on privacy settings
  static Future<bool> canViewContent({
    required String contentOwnerId,
    required PrivacyLevel privacyLevel,
    String? viewerId,
  }) async {
    // If no viewer ID (not logged in), only public content is visible
    if (viewerId == null) {
      return privacyLevel == PrivacyLevel.public;
    }

    // Content owner can always view their own content
    if (viewerId == contentOwnerId) {
      return true;
    }

    // Public content is visible to everyone
    if (privacyLevel == PrivacyLevel.public) {
      return true;
    }

    // Friends only - check if they are friends
    if (privacyLevel == PrivacyLevel.friendsOnly) {
      return await _areFriends(contentOwnerId, viewerId);
    }

    // Friends of friends - check if they are friends or friends of friends
    if (privacyLevel == PrivacyLevel.friendsOfFriends) {
      final areFriends = await _areFriends(contentOwnerId, viewerId);
      if (areFriends) return true;

      return await _areFriendsOfFriends(contentOwnerId, viewerId);
    }

    return false;
  }

  /// Check if two users are friends
  static Future<bool> _areFriends(String userId1, String userId2) async {
    try {
      // Check in both directions
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

  /// Check if user2 is a friend of a friend of user1
  static Future<bool> _areFriendsOfFriends(String userId1, String userId2) async {
    try {
      // Get all friends of user1
      final friendsSnapshot = await _firestore
          .collection('users')
          .doc(userId1)
          .collection('friends')
          .get();

      // Check if any of user1's friends are friends with user2
      for (var friendDoc in friendsSnapshot.docs) {
        final friendId = friendDoc.id;
        if (await _areFriends(friendId, userId2)) {
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('Error checking friends of friends: $e');
      return false;
    }
  }

  /// Get stories that a user can view based on privacy
  static Query<Map<String, dynamic>> getVisibleStoriesQuery(String viewerId) {
    final now = Timestamp.now();
    
    // Get all stories that are not expired
    return _firestore
        .collection('stories')
        .where('expiresAt', isGreaterThan: now)
        .orderBy('createdAt', descending: true);
  }

  /// Filter stories based on privacy (client-side filtering)
  static Future<List<Map<String, dynamic>>> filterStoriesByPrivacy(
    List<Map<String, dynamic>> stories,
    String viewerId,
  ) async {
    final filtered = <Map<String, dynamic>>[];

    for (var story in stories) {
      final ownerId = story['userId'] as String?;
      final privacyLevel = story['privacy'] as String?;

      if (ownerId == null) continue;

      final level = privacyLevel != null
          ? PrivacyLevelExtension.fromString(privacyLevel)
          : PrivacyLevel.public;

      final canView = await canViewContent(
        contentOwnerId: ownerId,
        privacyLevel: level,
        viewerId: viewerId,
      );

      if (canView) {
        filtered.add(story);
      }
    }

    return filtered;
  }

  /// Get posts that a user can view based on privacy
  static Query<Map<String, dynamic>> getVisiblePostsQuery(String viewerId) {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true);
  }

  /// Filter posts based on privacy (client-side filtering)
  static Future<List<Map<String, dynamic>>> filterPostsByPrivacy(
    List<Map<String, dynamic>> posts,
    String viewerId,
  ) async {
    final filtered = <Map<String, dynamic>>[];

    for (var post in posts) {
      final ownerId = post['userId'] as String?;
      final privacyLevel = post['privacy'] as String?;

      if (ownerId == null) continue;

      final level = privacyLevel != null
          ? PrivacyLevelExtension.fromString(privacyLevel)
          : PrivacyLevel.public;

      final canView = await canViewContent(
        contentOwnerId: ownerId,
        privacyLevel: level,
        viewerId: viewerId,
      );

      if (canView) {
        filtered.add(post);
      }
    }

    return filtered;
  }

  /// Get user's friends list
  static Future<List<String>> getUserFriends(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('friends')
          .get();

      return snapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      debugPrint('Error getting friends list: $e');
      return [];
    }
  }

  /// Get user's friends of friends
  static Future<List<String>> getFriendsOfFriends(String userId) async {
    try {
      final friends = await getUserFriends(userId);
      final friendsOfFriends = <String>{};

      for (var friendId in friends) {
        final friendFriends = await getUserFriends(friendId);
        friendsOfFriends.addAll(friendFriends);
      }

      // Remove the user themselves and their direct friends
      friendsOfFriends.remove(userId);
      for (var friend in friends) {
        friendsOfFriends.remove(friend);
      }

      return friendsOfFriends.toList();
    } catch (e) {
      debugPrint('Error getting friends of friends: $e');
      return [];
    }
  }
}
