import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as Twilio from "twilio";

/**
 * Royal Door OTP System (Twilio Verify V2)
 * TypeScript implementation for main functions folder
 */

const TWILIO_ACCOUNT_SID = process.env.TWILIO_ACCOUNT_SID || "";
const TWILIO_AUTH_TOKEN = process.env.TWILIO_AUTH_TOKEN || "";
const TWILIO_VERIFY_SERVICE_SID = process.env.TWILIO_VERIFY_SERVICE_SID || "";

export const sendOTP = functions.https.onCall(async (data, context) => {
  try {
    const phoneNumber = data.phoneNumber?.trim();
    const userId = context.auth?.uid;

    if (!phoneNumber || !/^\+?[1-9]\d{1,14}$/.test(phoneNumber)) {
      throw new functions.https.HttpsError("invalid-argument", "رقم الهاتف غير صحيح");
    }

    const client = Twilio(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN);

    const verification = await client.verify.v2
      .services(TWILIO_VERIFY_SERVICE_SID)
      .verifications.create({to: phoneNumber, channel: "sms"});

    await admin.firestore().collection("otp_logs").add({
      userId,
      phoneNumber,
      sid: verification.sid,
      status: verification.status,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      type: "send",
    });

    return {
      success: true,
      status: verification.status,
      message: "تم إرسال رمز التحقق بنجاح",
    };
  } catch (error: any) {
    console.error("Twilio Send Error:", error);
    throw new functions.https.HttpsError("internal", error.message || "فشل إرسال الرمز");
  }
});

export const verifyOTP = functions.https.onCall(async (data, context) => {
  try {
    const {phoneNumber, otp} = data;
    const userId = context.auth?.uid;

    if (!phoneNumber || !otp) {
      throw new functions.https.HttpsError("invalid-argument", "البيانات المطلوبة ناقصة");
    }

    const client = Twilio(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN);

    const verificationCheck = await client.verify.v2
      .services(TWILIO_VERIFY_SERVICE_SID)
      .verificationChecks.create({to: phoneNumber, code: otp});

    if (verificationCheck.status === "approved") {
      let customToken = null;

      if (userId) {
        await admin.firestore().collection("users").doc(userId).update({
          phoneNumber: phoneNumber,
          phoneVerified: true,
          phoneVerifiedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      } else {
        try {
          let userRecord;
          try {
            userRecord = await admin.auth().getUserByPhoneNumber(phoneNumber);
          } catch (e: any) {
            if (e.code === "auth/user-not-found") {
              userRecord = await admin.auth().createUser({phoneNumber});
            } else {
              throw e;
            }
          }
          customToken = await admin.auth().createCustomToken(userRecord.uid);
        } catch (tokenError) {
          console.error("Custom Token Error:", tokenError);
        }
      }

      await admin.firestore().collection("otp_logs").add({
        userId: userId || "anonymous",
        phoneNumber,
        status: "approved",
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        type: userId ? "verify_link_success" : "verify_login_success",
      });

      return {
        success: true,
        message: "تم التحقق بنجاح",
        customToken: customToken,
      };
    } else {
      throw new functions.https.HttpsError("permission-denied", "رمز التحقق غير صحيح أو منتهي الصلاحية");
    }
  } catch (error: any) {
    console.error("Twilio Verify Error:", error);
    throw new functions.https.HttpsError("internal", error.message || "فشل عملية التحقق");
  }
});
