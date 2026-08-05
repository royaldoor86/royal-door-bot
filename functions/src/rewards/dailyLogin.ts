import * as admin from "firebase-admin";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { CallableRequest } from "firebase-functions/v2/https";

// Cloud Function: claimDailyLogin
export const claimDailyLogin = onCall(
  { region: "us-central1" },
  async (request: CallableRequest) => {
  // التحقق من App Check token
  const appCheckToken = request.rawRequest?.headers?.['x-firebase-appcheck'];
  if (appCheckToken) {
    try {
      const token = typeof appCheckToken === 'string' ? appCheckToken : appCheckToken[0];
      await admin.appCheck().verifyToken(token);
    } catch (error) {
      throw new HttpsError('unauthenticated', 'Invalid App Check token');
    }
  }

  // تحقق من تسجيل الدخول
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "يجب تسجيل الدخول");
  }
  const uid = request.auth.uid;

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
        throw new HttpsError("already-exists", "تم استلام مكافأة اليوم بالفعل");
      }
    }
  }

  // تحديث بيانات streak و lastLogin
  await dailyLoginRef.set({
    lastLogin: admin.firestore.Timestamp.fromDate(today),
    streak,
  }, {merge: true});

  // مكافأة النجوم (مثال: 10 نجوم)
  await userRef.set({
    stars: admin.firestore.FieldValue.increment(10),
    coins: admin.firestore.FieldValue.increment(10), // مزامنة مع الكوينز للإصدارات القديمة
    dailyStreak: streak,
    lastDailyLogin: admin.firestore.Timestamp.fromDate(today),
  }, {merge: true});

  // إرجاع النتيجة
  return {
    message: "تم استلام مكافأة تسجيل الدخول اليومي",
    streak,
  };
});
