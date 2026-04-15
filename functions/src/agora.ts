import * as functions from "firebase-functions";
import {RtcTokenBuilder, RtcRole} from "agora-token";

export const generateAgoraToken = functions.https.onCall((data, context) => {
  // التحقق من تسجيل الدخول
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "يجب تسجيل الدخول لتوليد التوكن"
    );
  }

  const appId = "daed7a59dcbd4de2969b7504ae0843dc";
  // ملاحظة: يجب وضع App Certificate الخاص بك هنا ليعمل الأمان
  // يمكنك الحصول عليه من لوحة تحكم Agora
  const appCertificate = "ضع_هنا_APP_CERTIFICATE_الخاص_بك"; 
  
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
