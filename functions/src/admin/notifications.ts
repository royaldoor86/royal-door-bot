// Cloud Function: إدارة الإشعارات (Push + سجل)
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Placeholder: إرسال إشعار Push Notification
export const sendPushNotification = functions.region("us-central1").https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "يجب تسجيل الدخول");
  const adminDoc = await admin.firestore().collection("users").doc(context.auth.uid).get();
  if (!adminDoc.exists || (adminDoc.data()?.role !== "admin" && adminDoc.data()?.role !== "owner")) {
    throw new functions.https.HttpsError("permission-denied", "غير مصرح");
  }
  const {targetUid, title, body, type} = data;
  if (!targetUid || !title || !body) throw new functions.https.HttpsError("invalid-argument", "بيانات ناقصة");

  // إرسال إشعار عبر FCM (إذا كان هناك توكن)
  const userDoc = await admin.firestore().collection("users").doc(targetUid).get();
  const fcmToken = userDoc.data()?.fcmToken;
  if (fcmToken) {
    await admin.messaging().send({
      token: fcmToken,
      notification: {title, body},
      data: {type: type || "general"},
    });
  }
  // تسجيل الإشعار في Firestore
  await admin.firestore().collection("notifications").doc(targetUid).collection("items").add({
    title,
    body,
    type: type || "general",
    isRead: false,
    senderId: context.auth.uid,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
  return {success: true};
});
