// Cloud Function: إدارة النقاط والخبرة
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Placeholder: تحديث نقاط/خبرة المستخدم
export const updateUserPointsXP = functions.region("us-central1").https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "يجب تسجيل الدخول");
  const adminDoc = await admin.firestore().collection("users").doc(context.auth.uid).get();
  if (!adminDoc.exists || (adminDoc.data()?.role !== "admin" && adminDoc.data()?.role !== "owner")) {
    throw new functions.https.HttpsError("permission-denied", "غير مصرح");
  }
  const {uid, points, xp, level} = data;
  if (!uid) throw new functions.https.HttpsError("invalid-argument", "uid مطلوب");
  const userRef = admin.firestore().collection("users").doc(uid);
  const update: any = {};
  if (points !== undefined) update.points = points;
  if (xp !== undefined) update.xp = xp;
  if (level !== undefined) update.level = level;
  if (Object.keys(update).length === 0) throw new functions.https.HttpsError("invalid-argument", "لا يوجد بيانات للتحديث");
  await userRef.set(update, {merge: true});
  return {success: true};
});
