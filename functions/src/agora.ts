 import * as crypto from "crypto";
import * as functions from "firebase-functions";
import { RtcTokenBuilder, RtcRole } from "agora-token";

function deriveAgoraUid(firebaseUid: string): number {
  const hash = crypto.createHash("sha256").update(firebaseUid, "utf8").digest();
  const uid = ((hash.readUInt32BE(0) >>> 0) & 0x7fffffff) + 1;
  return uid;
}

export const generateAgoraToken = functions.https.onCall((data, context) => {
  const appId = "2042a5996de7444e9a72babc8527b25e";
  const appCertificate = "4b1952e689234f4fb5eb83a290b37581";

  const channelName = data.channelName;
  if (!channelName) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "اسم القناة مطلوب"
    );
  }

  const firebaseUid = context.auth?.uid;
  if (!firebaseUid) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "يجب أن يكون المستخدم مسجلاً للمصادقة"
    );
  }

  const uid = deriveAgoraUid(firebaseUid);
  const expirationTimeInSeconds = 3600; // صلاحية التوكن ساعة واحدة
  const currentTimestamp = Math.floor(Date.now() / 1000);
  const privilegeExpiredTimestamp = currentTimestamp + expirationTimeInSeconds;

  const tokenString = RtcTokenBuilder.buildTokenWithUid(
    appId,
    appCertificate,
    channelName,
    uid,
    RtcRole.PUBLISHER,
    privilegeExpiredTimestamp,
    privilegeExpiredTimestamp
  );

  return {
    token: tokenString,
    uid,
  };
});
