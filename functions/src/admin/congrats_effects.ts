// Cloud Function: إدارة التهاني والمؤثرات
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Placeholder: إضافة/تعديل/حذف تهنئة أو مؤثر
export const manageCongratsEffect = functions.region("us-central1").https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "يجب تسجيل الدخول");
  const adminDoc = await admin.firestore().collection("users").doc(context.auth.uid).get();
  if (!adminDoc.exists || adminDoc.data()?.role !== "admin") {
    throw new functions.https.HttpsError("permission-denied", "غير مصرح");
  }
  const {action, effectId, effectData} = data;
  const effectsRef = admin.firestore().collection("congrats_templates");
  if (action === "add") {
    const docRef = await effectsRef.add(effectData);
    return {success: true, id: docRef.id};
  } else if (action === "update" && effectId) {
    await effectsRef.doc(effectId).set(effectData, {merge: true});
    return {success: true};
  } else if (action === "delete" && effectId) {
    await effectsRef.doc(effectId).delete();
    return {success: true};
  }
  return {success: false, message: "بيانات غير صحيحة"};
});
