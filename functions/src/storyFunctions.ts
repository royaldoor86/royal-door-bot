import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();
const storage = admin.storage();

// When a story document is deleted, delete referenced storage files (if any)
export const onStoryDelete = functions.firestore
  .document("stories/{storyId}")
  .onDelete(async (snap, context) => {
    const data = snap.data() || {};
    const imgPath = data["imageStoragePath"] as string | undefined;
    const vidPath = data["videoStoragePath"] as string | undefined;

    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const deletes: Array<Promise<any>> = [];
    try {
      if (imgPath) {
        deletes.push(storage.bucket().file(imgPath).delete().catch((e) => {
          console.warn("Failed to delete image file:", imgPath, e.message || e);
        }));
      }
      if (vidPath) {
        deletes.push(storage.bucket().file(vidPath).delete().catch((e) => {
          console.warn("Failed to delete video file:", vidPath, e.message || e);
        }));
      }

      // Also delete replies subcollection documents
      const repliesCol = db.collection(`stories/${context.params.storyId}/replies`);
      const repliesSnap = await repliesCol.get();
      const batch = db.batch();
      repliesSnap.docs.forEach((d) => batch.delete(d.ref));
      await batch.commit();

      await Promise.all(deletes);
      console.log("onStoryDelete: cleaned up storage files and replies for", context.params.storyId);
    } catch (err) {
      console.error("onStoryDelete error:", err);
      throw err;
    }
  });

// When a notification doc is created, send an FCM push to the recipient if they have fcmToken
export const onNotificationCreate = functions.firestore
  .document("notifications/{notifId}")
  .onCreate(async (snap) => {
    const data = snap.data() || {};
    const toUid = data["to"] as string | undefined;
    const fromUid = data["from"] as string | undefined;
    const type = data["type"] as string | undefined;
    const payloadData = (data["data"] as Record<string, string | number | boolean>) ?? {};

    if (!toUid) return null;

    try {
      // read user's FCM token from users collection (token must be stored client-side)
      const userDoc = await db.collection("users").doc(toUid).get();
      const userData = userDoc.data() ?? {};
      const fcmToken = userData["fcmToken"] as string | undefined;

      const notificationTitle = (payloadData["title"] as string) ?? "تفاعل على ستوريتك";
      const notificationBody = (payloadData["message"] as string) ?? "لديك تفاعل جديد";

      if (fcmToken) {
        const message: admin.messaging.Message = {
          token: fcmToken,
          notification: {title: notificationTitle, body: notificationBody},
          data: {
            type: type ?? "story_event",
            storyId: (payloadData["storyId"] as string) ?? "",
            fromUid: fromUid ?? "",
          },
        };
        const res = await admin.messaging().send(message);
        console.log("Sent FCM to", toUid, res);
      } else {
        console.log("No fcmToken for user", toUid, "skip push");
      }

      return null;
    } catch (err) {
      console.error("onNotificationCreate error", err);
      throw err;
    }
  });
