import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();

async function isSuperAdmin(uid: string): Promise<boolean> {
  const adminDoc = await db.collection("users").doc(uid).get();
  const role = adminDoc.data()?.role;
  return role === "super_admin" || role === "owner";
}

async function ensureRoyalIdFree(royalId: string): Promise<void> {
  const query = await db.collection("users").where("royalId", "==", royalId).limit(1).get();
  if (!query.empty) {
    throw new functions.https.HttpsError("already-exists", "هذا المعرف مستخدم بالفعل");
  }
}

function royalIdAuditEntry(uid: string, oldRoyalId: string | null, newRoyalId: string, changedBy: string, changeType: string, reason: string) {
  return {
    oldRoyalId,
    newRoyalId,
    changedBy,
    changeType,
    reason,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  };
}

export const purchaseRoyalId = functions.region("us-central1").https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "المستخدم غير مسجل");
  }

  const uid = context.auth.uid;
  const specialIdDocId = data?.specialIdDocId;

  if (!specialIdDocId || typeof specialIdDocId !== "string") {
    throw new functions.https.HttpsError("invalid-argument", "معرف المعرف المميز مطلوب");
  }

  const specialDocRef = db.collection("special_ids").doc(specialIdDocId);
  const specialDoc = await specialDocRef.get();
  if (!specialDoc.exists) {
    throw new functions.https.HttpsError("not-found", "المعرف المميز غير موجود");
  }

  const specialData = specialDoc.data() as Record<string, any>;
  const isSold = specialData["isSold"] === true;
  const showInStore = specialData["showInStore"] !== false;
  const royalIdValue = (specialData["royalId"] || specialData["value"] || "").toString();
  const currency = (specialData["currencyType"] || "coins").toString();
  const price = Number(specialData["price"] ?? 0);

  if (isSold) {
    throw new functions.https.HttpsError("failed-precondition", "هذا المعرف المميز تم بيعه سابقاً");
  }
  if (!showInStore) {
    throw new functions.https.HttpsError("failed-precondition", "هذا المعرف غير متاح للبيع حالياً");
  }
  if (royalIdValue.trim().length === 0) {
    throw new functions.https.HttpsError("invalid-argument", "قيمة المعرف المميز غير صالحة");
  }

  const userRef = db.collection("users").doc(uid);
  const userDoc = await userRef.get();
  if (!userDoc.exists) {
    throw new functions.https.HttpsError("not-found", "المستخدم غير موجود");
  }

  const userData = userDoc.data() as Record<string, any>;
  const balance = Number(userData[currency] ?? 0);
  if (balance < price) {
    throw new functions.https.HttpsError("failed-precondition", "الرصيد غير كافٍ لشراء هذا المعرف");
  }

  await ensureRoyalIdFree(royalIdValue);

  return await db.runTransaction(async (tx) => {
    const freshUserDoc = await tx.get(userRef);
    if (!freshUserDoc.exists) {
      throw new functions.https.HttpsError("not-found", "المستخدم غير موجود");
    }

    const freshUserData = freshUserDoc.data() as Record<string, any>;
    const oldRoyalId = freshUserData["royalId"]?.toString() ?? null;
    const currentBalance = Number(freshUserData[currency] ?? 0);

    if (currentBalance < price) {
      throw new functions.https.HttpsError("failed-precondition", "الرصيد غير كافٍ");
    }

    tx.update(userRef, {
      royalId: royalIdValue,
      shortId: royalIdValue,
      hasCustomId: true,
      royalIdAssignedAt: admin.firestore.FieldValue.serverTimestamp(),
      royalIdAssignmentType: "purchase",
      royalIdAssignmentSource: `special_ids/${specialIdDocId}`,
      [currency]: currentBalance - price,
    });

    tx.update(specialDocRef, {
      isSold: true,
      ownerUid: uid,
      soldAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const historyRef = userRef.collection("royalIdHistory").doc();
    tx.set(historyRef, royalIdAuditEntry(uid, oldRoyalId, royalIdValue, uid, "purchase", "شراء معرف من المتجر"));

    return {success: true, royalId: royalIdValue};
  });
});

export const assignRoyalIdToUser = functions.region("us-central1").https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "المستخدم غير مسجل");
  }

  const adminUid = context.auth.uid;
  if (!(await isSuperAdmin(adminUid))) {
    throw new functions.https.HttpsError("permission-denied", "ليس لديك صلاحية لتعيين معرف. هذه الصلاحية للمالك فقط.");
  }

  const targetUid = data?.targetUid;
  const newRoyalId = data?.newRoyalId;
  const reason = data?.reason ?? "منح يدوي من لوحة التحكم";

  if (!targetUid || !newRoyalId || typeof targetUid !== "string" || typeof newRoyalId !== "string") {
    throw new functions.https.HttpsError("invalid-argument", "المعرف الجديد ومعرف المستخدم مطلوبان");
  }

  // التأكد من أن الآيدي متاح قبل إرسال الطلب
  await ensureRoyalIdFree(newRoyalId);

  const targetRef = db.collection("users").doc(targetUid);
  const targetDoc = await targetRef.get();
  if (!targetDoc.exists) {
    throw new functions.https.HttpsError("not-found", "المستخدم المستهدف غير موجود");
  }

  // بدلاً من التحديث المباشر، نرسل طلباً للمستخدم للموافقة
  const notificationRef = db.collection("notifications").doc(targetUid).collection("items").doc();
  await notificationRef.set({
    title: "طلب تغيير المعرف الملكي 👑",
    message: `المدير يطلب منحك معرفاً ملكياً جديداً: (${newRoyalId}). هل توافق على التغيير؟`,
    type: "royal_id_request",
    data: {
      newRoyalId,
      adminUid,
      reason,
      requestId: notificationRef.id,
    },
    read: false,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {success: true, message: "تم إرسال طلب التغيير للمستخدم للموافقة"};
});

/**
 * استجابة المستخدم لطلب تغيير الآيدي
 */
export const respondToRoyalIdRequest = functions.region("us-central1").https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "غير مصرح");
  }

  const uid = context.auth.uid;
  const requestId = data?.requestId;
  const action = data?.action; // 'accept' or 'reject'

  if (!requestId || !action) {
    throw new functions.https.HttpsError("invalid-argument", "المعرف والإجراء مطلوبان");
  }

  const notificationRef = db.collection("notifications").doc(uid).collection("items").doc(requestId);
  const notificationDoc = await notificationRef.get();

  if (!notificationDoc.exists || notificationDoc.data()?.type !== "royal_id_request") {
    throw new functions.https.HttpsError("not-found", "الطلب غير موجود أو غير صالح");
  }

  const requestData = notificationDoc.data()?.data;
  const newRoyalId = requestData.newRoyalId;

  if (action === "accept") {
    // التحقق مرة أخرى من توفر الآيدي
    await ensureRoyalIdFree(newRoyalId);

    const userRef = db.collection("users").doc(uid);
    const userDoc = await userRef.get();
    const oldRoyalId = userDoc.data()?.royalId || null;

    await db.runTransaction(async (tx) => {
      tx.update(userRef, {
        royalId: newRoyalId,
        shortId: newRoyalId,
        hasCustomId: true,
        royalIdAssignedAt: admin.firestore.FieldValue.serverTimestamp(),
        royalIdAssignmentType: "admin_grant_accepted",
      });

      const historyRef = userRef.collection("royalIdHistory").doc();
      tx.set(historyRef, royalIdAuditEntry(uid, oldRoyalId, newRoyalId, requestData.adminUid, "admin_grant_accepted", requestData.reason));
    });

    // حذف الإشعار بعد التنفيذ
    await notificationRef.delete();
    return {success: true, royalId: newRoyalId};
  } else {
    // رفض الطلب
    await notificationRef.delete();
    return {success: false, message: "تم رفض الطلب"};
  }
});

