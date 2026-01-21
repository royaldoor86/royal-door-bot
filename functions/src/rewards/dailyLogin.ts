import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Cloud Function: claimDailyLogin
export const claimDailyLogin = functions.region("us-central1").https.onCall(async (data, context) => {
  // تحقق من تسجيل الدخول
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "يجب تسجيل الدخول");
  }
  const uid = context.auth.uid;

  // مراجع Firestore
  const dailyLoginRef = admin.firestore().collection("daily_logins").doc(uid);
  const userRef = admin.firestore().collection("users").doc(uid);

  // جلب بيانات تسجيل الدخول اليومي
  const dailyLoginSnap = await dailyLoginRef.get();
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  let streak = 1;
  let lastLogin = null;
  if (dailyLoginSnap.exists) {
    const data = dailyLoginSnap.data();
    lastLogin = data?.lastLogin?.toDate?.() || null;
    streak = data?.streak || 1;
    if (lastLogin) {
      const last = new Date(lastLogin);
      last.setHours(0, 0, 0, 0);
      const diff = (today.getTime() - last.getTime()) / (1000 * 60 * 60 * 24);
      if (diff === 1) {
        streak += 1;
      } else if (diff > 1) {
        streak = 1;
      } else if (diff === 0) {
        throw new functions.https.HttpsError("already-exists", "تم استلام مكافأة اليوم بالفعل");
      }
    }
  }

  // تحديث بيانات streak و lastLogin
  await dailyLoginRef.set({
    lastLogin: admin.firestore.Timestamp.fromDate(today),
    streak,
  }, {merge: true});

  // مكافأة الكوينز (مثال: 10 كوينز)
  await userRef.set({
    coins: admin.firestore.FieldValue.increment(10),
    dailyStreak: streak,
    lastDailyLogin: admin.firestore.Timestamp.fromDate(today),
  }, {merge: true});

  // إرجاع النتيجة
  return {
    message: "تم استلام مكافأة تسجيل الدخول اليومي",
    streak,
  };
});
