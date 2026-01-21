// Cloud Function: إدارة الصلاحيات المتقدمة
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Placeholder: تعديل صلاحيات المستخدم
export const updateUserRole = functions.region("us-central1").https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "يجب تسجيل الدخول");
  const adminDoc = await admin.firestore().collection("users").doc(context.auth.uid).get();
  const email = adminDoc.data()?.email?.toLowerCase();
  if (!adminDoc.exists || (adminDoc.data()?.role !== "admin" && email !== "royaldoor86@gmail.com" && email !== "doorty86@gmail.com")) {
    throw new functions.https.HttpsError("permission-denied", "غير مصرح");
  }
  const {uid, role, permissions} = data;
  if (!uid || !role) throw new functions.https.HttpsError("invalid-argument", "uid و role مطلوبان");
  const userRef = admin.firestore().collection("users").doc(uid);
  await userRef.set({role, permissions: permissions || []}, {merge: true});
  return {success: true};
});
