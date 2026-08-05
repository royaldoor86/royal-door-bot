import * as functions from "firebase-functions";
import {RtcTokenBuilder, RtcRole} from "agora-token";

export const generateAgoraToken = functions.https.onCall(async (data, context) => {
  // التحقق من App Check
  if (context.app) {
    console.log('✅ App Check token received:', context.app.appId);
  } else {
    console.log('⚠️ No App Check token received (allowed for now)');
  }

  // التحقق من تسجيل الدخول
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "يجب تسجيل الدخول لتوليد التوكن"
    );
  }

  const appId = "2042a5996de7444e9a72babc8527b25e";
  // ملاحظة: يجب وضع App Certificate الخاص بك هنا ليعمل الأمان
  // يمكنك الحصول عليه من لوحة تحكم Agora
  const appCertificate = "4b1952e689234f4fb5eb83a290b37581";

  const channelName = data.channelName;
  if (!channelName) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "اسم القناة مطلوب"
    );
  }

  const uid = 0; // استخدام 0 يعني أن أغورا ستخصص UID تلقائياً
  const role = RtcRole.PUBLISHER;
  const expirationTimeInSeconds = 3600; // ساعة واحدة
  const currentTimestamp = Math.floor(Date.now() / 1000);
  const privilegeExpiredTimestamp = currentTimestamp + expirationTimeInSeconds;

  const token = RtcTokenBuilder.buildTokenWithUid(
    appId,
    appCertificate,
    channelName,
    uid,
    role,
    privilegeExpiredTimestamp,
    privilegeExpiredTimestamp
  );

  return {
    token: token,
  };
});
