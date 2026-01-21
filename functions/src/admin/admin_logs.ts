// Cloud Function: سجل العمليات الإدارية
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Placeholder: تسجيل عملية إدارية
export const logAdminAction = functions.region("us-central1").https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "يجب تسجيل الدخول");
  const adminDoc = await admin.firestore().collection("users").doc(context.auth.uid).get();
  if (!adminDoc.exists || adminDoc.data()?.role !== "admin") {
    throw new functions.https.HttpsError("permission-denied", "غير مصرح");
  }
  const {action, details} = data;
  await admin.firestore().collection("admin_logs").add({
    action,
    details: details || {},
    adminId: context.auth.uid,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
  return {success: true};
});
