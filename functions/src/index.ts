
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {claimDailyLogin} from "./rewards/dailyLogin";
import {completeDailyTask} from "./rewards/dailyTasks";
import {resetDailyTasks} from "./rewards/resetDailyTasks";
// ================================
// 4️⃣ claimDailyLogin
// ================================
export {claimDailyLogin};

// ================================
// 5️⃣ completeDailyTask
// ================================
export {completeDailyTask};

// ================================
// 6️⃣ resetDailyTasks (Scheduled)
// ================================
export {resetDailyTasks};
import {manageChallenge, claimChallengeReward} from "./admin/challenges";
export {manageChallenge, claimChallengeReward};

admin.initializeApp();

/* ================================
   1️⃣ onUserCreated
   ================================ */
export const onUserCreated = functions.auth.user().onCreate(async (user) => {
  const uid = user.uid;

  const userData = {
    uid: uid,
    email: user.email ?? null,
    name: user.displayName ?? "مستخدم جديد",
    photo: user.photoURL ?? null,

    role: "user", // user | admin | vip
    banned: false,

    coins: 0,
    level: 1,

    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await admin.firestore().collection("users").doc(uid).set(userData);
});

/* ================================
   2️⃣ adminBanUser
   ================================ */
export const adminBanUser = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    // التحقق من تسجيل الدخول
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "المستخدم غير مسجل"
      );
    }

    const adminUid = context.auth.uid;

    // التحقق من أن المنفذ Admin
    const adminDoc = await admin
      .firestore()
      .collection("users")
      .doc(adminUid)
      .get();

    if (!adminDoc.exists || adminDoc.data()?.role !== "admin") {
      throw new functions.https.HttpsError(
        "permission-denied",
        "ليس لديك صلاحية"
      );
    }

    const {uid, reason} = data;

    if (!uid) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "uid مطلوب"
      );
    }

    // تعطيل المستخدم من Firebase Auth
    await admin.auth().updateUser(uid, {
      disabled: true,
    });

    // تحديث Firestore
    await admin.firestore().collection("users").doc(uid).update({
      banned: true,
      banReason: reason || "بدون سبب",
      bannedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      message: "تم حظر المستخدم",
    };
  });

/* ================================
   3️⃣ adminUnbanUser (اختياري لكن أنصحك)
   ================================ */
export const adminUnbanUser = functions
  .region("us-central1")
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "المستخدم غير مسجل"
      );
    }

    const adminUid = context.auth.uid;

    const adminDoc = await admin
      .firestore()
      .collection("users")
      .doc(adminUid)
      .get();

    if (!adminDoc.exists || adminDoc.data()?.role !== "admin") {
      throw new functions.https.HttpsError(
        "permission-denied",
        "ليس لديك صلاحية"
      );
    }

    const {uid} = data;

    if (!uid) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "uid مطلوب"
      );
    }

    await admin.auth().updateUser(uid, {
      disabled: false,
    });

    await admin.firestore().collection("users").doc(uid).update({
      banned: false,
      unbannedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      message: "تم فك الحظر",
    };
  });
