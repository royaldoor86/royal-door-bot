// Cloud Function: إدارة الإنجازات والإحصائيات
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Placeholder: إضافة/تعديل/حذف إنجاز
export const manageAchievement = functions.region("us-central1").https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "يجب تسجيل الدخول");
  const adminDoc = await admin.firestore().collection("users").doc(context.auth.uid).get();
  if (!adminDoc.exists || adminDoc.data()?.role !== "admin") {
    throw new functions.https.HttpsError("permission-denied", "غير مصرح");
  }
  const {action, achievementId, achievementData} = data;
  const achievementsRef = admin.firestore().collection("achievements");
  if (action === "add") {
    const docRef = await achievementsRef.add(achievementData);
    return {success: true, id: docRef.id};
  } else if (action === "update" && achievementId) {
    await achievementsRef.doc(achievementId).set(achievementData, {merge: true});
    return {success: true};
  } else if (action === "delete" && achievementId) {
    await achievementsRef.doc(achievementId).delete();
    return {success: true};
  }
  return {success: false, message: "بيانات غير صحيحة"};
});

// Placeholder: تسجيل إنجاز للمستخدم
export const logUserAchievement = functions.region("us-central1").https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "يجب تسجيل الدخول");
  const uid = context.auth.uid;
  const {achievementId} = data;
  if (!achievementId) throw new functions.https.HttpsError("invalid-argument", "achievementId مطلوب");

  // تحقق إذا كان المستخدم حصل على الإنجاز مسبقاً
  const logRef = admin.firestore().collection("achievements_logs").doc(uid).collection("logs").doc(achievementId);
  const logSnap = await logRef.get();
  if (logSnap.exists) {
    throw new functions.https.HttpsError("already-exists", "تم تسجيل هذا الإنجاز بالفعل");
  }

  // تحديث سجل الإنجازات
  await logRef.set({
    achievedAt: admin.firestore.FieldValue.serverTimestamp(),
    achievementId,
  });
  // (يمكن إضافة منطق مكافأة هنا)
  return {success: true};
});
