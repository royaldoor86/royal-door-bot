import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

// Cloud Function to initialize user statistics and settings
export const initializeUserSchema = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const userId = context.auth.uid;

  try {
    const userDoc = await db.collection('users').doc(userId).get();

    if (!userDoc.exists) {
      throw new functions.https.HttpsError(
        'not-found',
        'User document not found'
      );
    }

    const userData = userDoc.data() || {};

    // Initialize 2FA settings
    if (userData.twoFactorEnabled === undefined) {
      await db.collection('users').doc(userId).update({
        twoFactorEnabled: false,
        phoneNumber: '',
      });
    }

    // Initialize statistics
    const stats = {
      totalPosts: userData.totalPosts || 0,
      totalLikes: userData.totalLikes || 0,
      totalComments: userData.totalComments || 0,
      totalFriends: userData.totalFriends || 0,
      totalFollowers: userData.totalFollowers || 0,
      totalFollowing: userData.totalFollowing || 0,
      totalGiftsReceived: userData.totalGiftsReceived || 0,
      totalGiftsSent: userData.totalGiftsSent || 0,
      totalBadges: userData.totalBadges || 0,
      totalVoiceRooms: userData.totalVoiceRooms || 0,
    };

    await db.collection('users').doc(userId).update(stats);

    // Initialize join date if not present
    if (!userData.joinDate) {
      await db.collection('users').doc(userId).update({
        joinDate: admin.firestore.FieldValue.serverTimestamp(),
      });
    }

    // Initialize notification settings
    const notificationSettings = {
      internalNotificationsEnabled: userData.internalNotificationsEnabled ?? true,
      pushNotificationsEnabled: userData.pushNotificationsEnabled ?? true,
      followNotificationsEnabled: userData.followNotificationsEnabled ?? true,
      likeNotificationsEnabled: userData.likeNotificationsEnabled ?? true,
      commentNotificationsEnabled: userData.commentNotificationsEnabled ?? true,
      giftNotificationsEnabled: userData.giftNotificationsEnabled ?? true,
      badgeNotificationsEnabled: userData.badgeNotificationsEnabled ?? true,
      friendRequestNotificationsEnabled: userData.friendRequestNotificationsEnabled ?? true,
      chatNotificationsEnabled: userData.chatNotificationsEnabled ?? true,
      systemNotificationsEnabled: userData.systemNotificationsEnabled ?? true,
    };

    await db.collection('users').doc(userId).update(notificationSettings);

    // Initialize privacy settings
    const privacySettings = {
      profileVisibilityPublic: userData.profileVisibilityPublic ?? true,
      allowMessagesFromEveryone: userData.allowMessagesFromEveryone ?? true,
      allowMessagesFromFriendsOnly: userData.allowMessagesFromFriendsOnly ?? false,
      allowMessagesFromNoOne: userData.allowMessagesFromNoOne ?? false,
      showOnlineStatus: userData.showOnlineStatus ?? true,
      allowFriendRequests: userData.allowFriendRequests ?? true,
      notificationsFromNonFriends: userData.notificationsFromNonFriends ?? true,
    };

    await db.collection('users').doc(userId).update(privacySettings);

    // Initialize appearance settings
    const appearanceSettings = {
      darkMode: userData.darkMode ?? true,
      fontSize: userData.fontSize ?? 16.0,
      theme: userData.theme ?? 'royal',
    };

    await db.collection('users').doc(userId).update(appearanceSettings);

    // Initialize voice room settings
    const voiceRoomSettings = {
      autoJoinEnabled: userData.autoJoinEnabled ?? false,
      micAutoEnabled: userData.micAutoEnabled ?? true,
      speakerAutoEnabled: userData.speakerAutoEnabled ?? true,
      micVolume: userData.micVolume ?? 0.8,
      speakerVolume: userData.speakerVolume ?? 1.0,
      noiseCancellation: userData.noiseCancellation ?? true,
      echoCancellation: userData.echoCancellation ?? true,
    };

    await db.collection('users').doc(userId).update(voiceRoomSettings);

    return { success: true };
  } catch (error) {
    console.error('Error initializing user schema:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to initialize user schema'
    );
  }
});

// Cloud Function to increment user statistics
export const incrementUserStat = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const userId = context.auth.uid;
  const { statName, increment } = data;

  if (!statName || increment === undefined) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Stat name and increment value are required'
    );
  }

  const validStats = [
    'totalPosts',
    'totalLikes',
    'totalComments',
    'totalFriends',
    'totalFollowers',
    'totalFollowing',
    'totalGiftsReceived',
    'totalGiftsSent',
    'totalBadges',
    'totalVoiceRooms',
  ];

  if (!validStats.includes(statName)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Invalid stat name'
    );
  }

  try {
    await db.collection('users').doc(userId).update({
      [statName]: admin.firestore.FieldValue.increment(increment),
    });

    return { success: true };
  } catch (error) {
    console.error('Error incrementing user stat:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to increment user stat'
    );
  }
});

// Cloud Function to decrement user statistics
export const decrementUserStat = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const userId = context.auth.uid;
  const { statName, decrement } = data;

  if (!statName || decrement === undefined) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Stat name and decrement value are required'
    );
  }

  const validStats = [
    'totalPosts',
    'totalLikes',
    'totalComments',
    'totalFriends',
    'totalFollowers',
    'totalFollowing',
    'totalGiftsReceived',
    'totalGiftsSent',
    'totalBadges',
    'totalVoiceRooms',
  ];

  if (!validStats.includes(statName)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Invalid stat name'
    );
  }

  try {
    await db.collection('users').doc(userId).update({
      [statName]: admin.firestore.FieldValue.increment(-decrement),
    });

    return { success: true };
  } catch (error) {
    console.error('Error decrementing user stat:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to decrement user stat'
    );
  }
});
