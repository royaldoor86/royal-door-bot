import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

// Cloud Function to update session activity automatically
export const updateSessionActivity = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const userId = context.auth.uid;
  const sessionId = data.sessionId;

  if (!sessionId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Session ID is required'
    );
  }

  try {
    await db
      .collection('users')
      .doc(userId)
      .collection('sessions')
      .doc(sessionId)
      .update({
        lastActive: admin.firestore.FieldValue.serverTimestamp(),
      });

    // Update user's last active timestamp
    await db.collection('users').doc(userId).update({
      lastActive: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true };
  } catch (error) {
    throw new functions.https.HttpsError(
      'internal',
      'Failed to update session activity'
    );
  }
});

// Scheduled Cloud Function to clean up old sessions (runs daily)
export const cleanupOldSessions = functions.pubsub
  .schedule('0 0 * * *') // Runs daily at midnight
  .timeZone('UTC')
  .onRun(async (context) => {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    try {
      // Get all users
      const usersSnapshot = await db.collection('users').get();

      const batch = db.batch();

      for (const userDoc of usersSnapshot.docs) {
        // Get old sessions for this user
        const oldSessionsSnapshot = await db
          .collection('users')
          .doc(userDoc.id)
          .collection('sessions')
          .where('lastActive', '<', thirtyDaysAgo)
          .get();

        // Delete old sessions
        oldSessionsSnapshot.docs.forEach((sessionDoc) => {
          batch.delete(sessionDoc.ref);
        });
      }

      await batch.commit();

      console.log(`Cleaned up old sessions successfully`);
      return null;
    } catch (error) {
      console.error('Error cleaning up old sessions:', error);
      return null;
    }
  });

// Cloud Function to revoke a specific session
export const revokeSession = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const userId = context.auth.uid;
  const sessionId = data.sessionId;

  if (!sessionId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Session ID is required'
    );
  }

  try {
    await db
      .collection('users')
      .doc(userId)
      .collection('sessions')
      .doc(sessionId)
      .delete();

    return { success: true };
  } catch (error) {
    throw new functions.https.HttpsError(
      'internal',
      'Failed to revoke session'
    );
  }
});

// Cloud Function to revoke all sessions except current
export const revokeAllSessions = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const userId = context.auth.uid;
  const currentSessionId = data.currentSessionId;

  try {
    const sessionsSnapshot = await db
      .collection('users')
      .doc(userId)
      .collection('sessions')
      .get();

    const batch = db.batch();

    sessionsSnapshot.docs.forEach((sessionDoc) => {
      // Don't delete the current session if provided
      if (currentSessionId && sessionDoc.id === currentSessionId) {
        return;
      }
      batch.delete(sessionDoc.ref);
    });

    await batch.commit();

    return { success: true };
  } catch (error) {
    throw new functions.https.HttpsError(
      'internal',
      'Failed to revoke all sessions'
    );
  }
});

// Cloud Function to track new session
export const trackSession = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const userId = context.auth.uid;
  const { deviceId, deviceType, deviceName, location } = data;

  if (!deviceId || !deviceType || !deviceName) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Device information is required'
    );
  }

  try {
    const sessionId = context.auth.token?.sub || Date.now().toString();

    await db
      .collection('users')
      .doc(userId)
      .collection('sessions')
      .doc(sessionId)
      .set({
        sessionId,
        deviceId,
        deviceType,
        deviceName,
        location: location || 'Unknown',
        lastActive: admin.firestore.FieldValue.serverTimestamp(),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        isActive: true,
      });

    // Update user's last active timestamp
    await db.collection('users').doc(userId).update({
      lastActive: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true, sessionId };
  } catch (error) {
    throw new functions.https.HttpsError(
      'internal',
      'Failed to track session'
    );
  }
});
