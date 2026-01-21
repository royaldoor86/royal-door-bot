// Cloud Function: إدارة التحديات اليومية/الأسبوعية
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Placeholder: إضافة/تعديل/حذف تحدي
export const manageChallenge = functions.region("us-central1").https.onCall(async (data, context) => {
  // تحقق من صلاحية الأدمن أو المالك
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "يجب تسجيل الدخول");
  const adminDoc = await admin.firestore().collection("users").doc(context.auth.uid).get();
  const email = adminDoc.data()?.email?.toLowerCase();
  const isOwner = adminDoc.data()?.isOwner === true;
  const isAdmin = adminDoc.data()?.role === "admin";
  if (!adminDoc.exists || (!isAdmin && !isOwner && email !== "royaldoor86@gmail.com" && email !== "doorty86@gmail.com")) {
    throw new functions.https.HttpsError("permission-denied", "غير مصرح");
  }

  const {action, challengeId, challengeData} = data;
  const challengesRef = admin.firestore().collection("challenges");

  if (action === "add") {
    const docRef = await challengesRef.add(challengeData);
    return {success: true, id: docRef.id};
  } else if (action === "update" && challengeId) {
    await challengesRef.doc(challengeId).set(challengeData, {merge: true});
    return {success: true};
  } else if (action === "delete" && challengeId) {
    await challengesRef.doc(challengeId).delete();
    return {success: true};
  }
  return {success: false, message: "بيانات غير صحيحة"};
});

// Placeholder: استلام مكافأة تحدي
export const claimChallengeReward = functions.region("us-central1").https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "يجب تسجيل الدخول");
  const uid = context.auth.uid;
  const {challengeId} = data;
  if (!challengeId) throw new functions.https.HttpsError("invalid-argument", "challengeId مطلوب");

  // تحقق إذا كان المستخدم استلم المكافأة مسبقاً
  const logRef = admin.firestore().collection("challenge_logs").doc(uid).collection("logs").doc(challengeId);
  const logSnap = await logRef.get();
  if (logSnap.exists) {
    throw new functions.https.HttpsError("already-exists", "تم استلام مكافأة هذا التحدي بالفعل");
  }

  // تحديث سجل التحديات
  await logRef.set({
    claimedAt: admin.firestore.FieldValue.serverTimestamp(),
    challengeId,
  });
  // (يمكن إضافة منطق مكافأة هنا)
  return {success: true};
});
