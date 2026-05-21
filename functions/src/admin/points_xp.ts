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
  const {uid, stars, xp, level} = data;
  if (!uid) throw new functions.https.HttpsError("invalid-argument", "uid مطلوب");
  const userRef = admin.firestore().collection("users").doc(uid);
  const update: Record<string, number> = {};
  if (stars !== undefined) {
    update.stars = stars;
    update.coins = stars; // مزامنة مع الكوينز للإصدارات القديمة
  }
  if (xp !== undefined) {
    update.royalXP = xp;
    update.xp = xp; // مزامنة مع الحقل القديم
  }
  if (level !== undefined) update.userLevel = level;
  if (Object.keys(update).length === 0) throw new functions.https.HttpsError("invalid-argument", "لا يوجد بيانات للتحديث");
  await userRef.set(update, {merge: true});
  return {success: true};
});
