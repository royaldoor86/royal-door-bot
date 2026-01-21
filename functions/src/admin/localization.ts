// Cloud Function: إدارة النصوص واللغات
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Placeholder: إضافة/تعديل/حذف نص
export const manageAppText = functions.region("us-central1").https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "يجب تسجيل الدخول");
  const adminDoc = await admin.firestore().collection("users").doc(context.auth.uid).get();
  if (!adminDoc.exists || adminDoc.data()?.role !== "admin") {
    throw new functions.https.HttpsError("permission-denied", "غير مصرح");
  }
  const {action, lang, textId, textData} = data;
  if (!lang) throw new functions.https.HttpsError("invalid-argument", "lang مطلوب");
  const textsRef = admin.firestore().collection("app_texts").doc(lang).collection("items");
  if (action === "add") {
    const docRef = await textsRef.add(textData);
    return {success: true, id: docRef.id};
  } else if (action === "update" && textId) {
    await textsRef.doc(textId).set(textData, {merge: true});
    return {success: true};
  } else if (action === "delete" && textId) {
    await textsRef.doc(textId).delete();
    return {success: true};
  }
  return {success: false, message: "بيانات غير صحيحة"};
});
