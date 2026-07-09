import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();

/**
 * إرسال هدية في الغرفة
 * يتحقق من الرصيد، يخصم العملة، ويحدث أرباح الغرفة
 */
export const sendGift = functions.region("us-central1").https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "يجب تسجيل الدخول");
  }

  const senderId = context.auth.uid;
  const { roomId, giftId, receiverId, count = 1, currency = "stars" } = data;

  if (!roomId || !giftId || !receiverId) {
    throw new functions.https.HttpsError("invalid-argument", "بيانات غير مكتملة");
  }

  if (count < 1 || count > 99) {
    throw new functions.https.HttpsError("invalid-argument", "عدد الهدايا يجب أن يكون بين 1 و 99");
  }

  try {
    await db.runTransaction(async (transaction) => {
      // 1. جلب بيانات المرسل
      const senderRef = db.collection("users").doc(senderId);
      const senderDoc = await transaction.get(senderRef);
      if (!senderDoc.exists) {
        throw new functions.https.HttpsError("not-found", "المستخدم غير موجود");
      }

      const senderData = senderDoc.data();
      const currentBalance = senderData?.[currency] || 0;

      // 2. جلب بيانات الهدية
      const giftRef = db.collection("gifts").doc(giftId);
      const giftDoc = await transaction.get(giftRef);
      if (!giftDoc.exists) {
        throw new functions.https.HttpsError("not-found", "الهدية غير موجودة");
      }

      const giftData = giftDoc.data();
      const giftCost = giftData?.[currency] || 0;
      const totalCost = giftCost * count;

      // 3. التحقق من الرصيد
      if (currentBalance < totalCost) {
        throw new functions.https.HttpsError("failed-precondition", "رصيدك غير كافٍ");
      }

      // 4. خصم الرصيد من المرسل
      transaction.update(senderRef, {
        [currency]: admin.firestore.FieldValue.increment(-totalCost),
      });

      // 5. إضافة سجل المعاملة
      const transactionRef = senderRef.collection("gift_transactions").doc();
      transaction.set(transactionRef, {
        giftId,
        giftName: giftData?.name || "Unknown",
        receiverId,
        roomId,
        count,
        currency,
        totalCost,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      // 6. تحديث أرباح الغرفة (1% من قيمة الهدية)
      const roomRef = db.collection("rooms").doc(roomId);
      const roomDoc = await transaction.get(roomRef);
      if (roomDoc.exists) {
        const roomEarnings = totalCost * 0.01; // 1%
        transaction.update(roomRef, {
          pendingEarnings: admin.firestore.FieldValue.increment(roomEarnings),
        });
      }

      // 7. تسجيل حدث الهدية في الغرفة
      const giftEventRef = roomRef.collection("gift_events").doc();
      transaction.set(giftEventRef, {
        giftName: giftData?.name || "Unknown",
        giftImageUrl: giftData?.imageUrl || "",
        giftVideoUrl: giftData?.videoUrl || "",
        senderName: senderData?.name || "Unknown",
        senderId,
        receiverId,
        receiverName: data.receiverName || "Unknown",
        count,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        giftType: giftData?.type || "image",
        soundUrl: giftData?.soundUrl || "",
      });
    });

    return { success: true, message: "تم إرسال الهدية بنجاح" };
  } catch (error: any) {
    console.error("Error sending gift:", error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError("internal", "فشل في إرسال الهدية");
  }
});

/**
 * جمع أرباح الغرفة
 * يحول الأرباح المعلقة إلى محفظة المالك
 */
export const collectRoomEarnings = functions.region("us-central1").https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "يجب تسجيل الدخول");
  }

  const { roomId } = data;
  if (!roomId) {
    throw new functions.https.HttpsError("invalid-argument", "معرف الغرفة مطلوب");
  }

  try {
    await db.runTransaction(async (transaction) => {
      const roomRef = db.collection("rooms").doc(roomId);
      const roomDoc = await transaction.get(roomRef);
      
      if (!roomDoc.exists) {
        throw new functions.https.HttpsError("not-found", "الغرفة غير موجودة");
      }

      const roomData = roomDoc.data();
      const ownerId = roomData?.ownerId;
      const pendingEarnings = roomData?.pendingEarnings || 0;

      if (context.auth.uid !== ownerId) {
        throw new functions.https.HttpsError("permission-denied", "فقط المالك يمكنه جمع الأرباح");
      }

      if (pendingEarnings <= 0) {
        throw new functions.https.HttpsError("failed-precondition", "لا توجد أرباح لجمعها");
      }

      // إضافة الأرباح لمحفظة المالك
      const ownerRef = db.collection("users").doc(ownerId);
      transaction.update(ownerRef, {
        stars: admin.firestore.FieldValue.increment(pendingEarnings),
      });

      // تصفير الأرباح المعلقة
      transaction.update(roomRef, {
        pendingEarnings: 0,
      });

      // تسجيل العملية
      const earningsLogRef = ownerRef.collection("earnings_logs").doc();
      transaction.set(earningsLogRef, {
        roomId,
        amount: pendingEarnings,
        currency: "stars",
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    return { success: true, message: "تم جمع الأرباح بنجاح" };
  } catch (error: any) {
    console.error("Error collecting earnings:", error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError("internal", "فشل في جمع الأرباح");
  }
});
