import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

/**
 * 👑 دالة شراء باقة من السوق الملكي (Cloud Function)
 * تضمن هذه الدالة أن العملية تتم بأمان تام بعيداً عن تلاعب المستخدمين بالرصيد.
 */
export const purchaseRewardFromMarketplace = functions.region("us-central1").https.onCall(async (data, context) => {
  // ١. التحقق من الهوية
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "يجب تسجيل الدخول لإتمام العملية");
  }
  const buyerId = context.auth.uid;
  const {listingId} = data;

  if (!listingId) {
    throw new functions.https.HttpsError("invalid-argument", "معرف العرض (listingId) مطلوب");
  }

  const db = admin.firestore();

  return await db.runTransaction(async (transaction) => {
    // ٢. جلب بيانات العرض
    const listingRef = db.collection("reward_marketplace").doc(listingId);
    const listingDoc = await transaction.get(listingRef);

    if (!listingDoc.exists) {
      throw new functions.https.HttpsError("not-found", "العرض غير موجود في السوق");
    }

    const listingData = listingDoc.data()!;
    if (listingData.status !== "active") {
      throw new functions.https.HttpsError("failed-precondition", "هذا العرض لم يعد متاحاً للشراء");
    }

    const sellerId = listingData.sellerId;
    const askingPrice = Number(listingData.askingPrice);
    const currency = listingData.currency; // 'stars' or 'gems'
    const rewardId = listingData.rewardId;

    if (sellerId === buyerId) {
      throw new functions.https.HttpsError("permission-denied", "لا يمكنك شراء عرضك الخاص");
    }

    // ٣. التحقق من رصيد المشتري
    const buyerRef = db.collection("users").doc(buyerId);
    const buyerSnap = await transaction.get(buyerRef);
    if (!buyerSnap.exists) {
      throw new functions.https.HttpsError("not-found", "حساب المشتري غير موجود");
    }

    const buyerData = buyerSnap.data()!;
    // تحديد الحقل الصحيح بناءً على العملة (ندعم الحقول الجديدة والقديمة للتوافق)
    const buyerBalance = (currency === "stars")
      ? Number(buyerData.stars || buyerData.coins || 0)
      : Number(buyerData.gems || 0);

    if (buyerBalance < askingPrice) {
      throw new functions.https.HttpsError("failed-precondition", "رصيدك غير كافٍ لإتمام عملية الشراء");
    }

    // ٤. التأكد من أن المكافأة ما زالت عند البائع
    const sellerRewardRef = db.collection("users").doc(sellerId).collection("active_rewards").doc(rewardId);
    const sellerRewardDoc = await transaction.get(sellerRewardRef);
    if (!sellerRewardDoc.exists) {
      throw new functions.https.HttpsError("not-found", "المكافأة لم تعد متوفرة عند البائع");
    }

    // ٥. تنفيذ التحويلات المالية
    const commissionRate = 0.02; // ٢٪ عمولة الصيانة الملكية
    const commission = askingPrice * commissionRate;
    const netAmount = askingPrice - commission;

    // خصم من المشتري
    const buyerUpdate: any = {};
    if (currency === "stars") {
      buyerUpdate.stars = admin.firestore.FieldValue.increment(-askingPrice);
      buyerUpdate.coins = admin.firestore.FieldValue.increment(-askingPrice);
    } else {
      buyerUpdate.gems = admin.firestore.FieldValue.increment(-askingPrice);
    }
    transaction.update(buyerRef, buyerUpdate);

    // إضافة للبائع
    const sellerRef = db.collection("users").doc(sellerId);
    const sellerUpdate: any = {};
    if (currency === "stars") {
      sellerUpdate.stars = admin.firestore.FieldValue.increment(netAmount);
      sellerUpdate.coins = admin.firestore.FieldValue.increment(netAmount);
    } else {
      sellerUpdate.gems = admin.firestore.FieldValue.increment(netAmount);
    }
    transaction.update(sellerRef, sellerUpdate);

    // ٦. نقل ملكية المكافأة
    const buyerActiveRewardRef = db.collection("users").doc(buyerId).collection("active_rewards").doc(rewardId);
    const rewardData = sellerRewardDoc.data()!;

    // تحديث بيانات المكافأة للمالك الجديد
    transaction.set(buyerActiveRewardRef, {
      ...rewardData,
      userId: buyerId,
      status: "active",
      purchasedFrom: sellerId,
      purchasePrice: askingPrice,
      purchaseCurrency: currency,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    });

    // حذفها من عند البائع
    transaction.delete(sellerRewardRef);

    // ٧. تحديث حالة العرض في السوق
    transaction.update(listingRef, {
      status: "sold",
      buyerId: buyerId,
      soldAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // ٨. توثيق العمولة والعملية
    const auditLogRef = db.collection("audit_logs").doc();
    transaction.set(auditLogRef, {
      type: "MARKETPLACE_PURCHASE",
      buyerId,
      sellerId,
      listingId,
      amount: askingPrice,
      currency,
      commission,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      message: "تمت عملية الشراء بنجاح! مبروك الملكية الجديدة 👑",
      newOwner: buyerId,
    };
  });
});
