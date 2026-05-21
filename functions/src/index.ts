import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Version: 1.0.1 - Updated Agora Keys
import {claimDailyLogin} from "./rewards/dailyLogin";
import {completeDailyTask} from "./rewards/dailyTasks";
import {resetDailyTasks} from "./rewards/resetDailyTasks";
import {generateAgoraToken} from "./agora";

admin.initializeApp();

import {purchaseRewardFromMarketplace} from "./rewards/marketplace";

export {claimDailyLogin, completeDailyTask, resetDailyTasks, generateAgoraToken, purchaseRewardFromMarketplace};

import {manageChallenge, claimChallengeReward} from "./admin/challenges";
import {purchaseRoyalId, assignRoyalIdToUser, respondToRoyalIdRequest} from "./admin/royalIdManagement";
import {sendOTP, verifyOTP} from "./otp";

export {manageChallenge, claimChallengeReward, purchaseRoyalId, assignRoyalIdToUser, respondToRoyalIdRequest, sendOTP, verifyOTP};

// تصدير كافة وظائف الإشعارات من الملف الموحد
export {
  sendChatNotification,
  sendGiftNotification,
  sendFriendRequestNotification,
  sendVisitorNotification,
  sendNewPostNotification,
  sendBattleNotification,
  sendInteractionNotification,
  sendMicInviteNotification,
  sendFollowNotification,
  sendStoryInteractionNotification,
  sendFamilyNotification,
  sendTransferNotification,
  sendGameInviteNotification,
} from "./notifications";

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
    role: "user",
    banned: false,
    coins: 0,
    gems: 0,
    level: 1,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };
  await admin.firestore().collection("users").doc(uid).set(userData);
});

/* ================================
   2️⃣ adminBanUser
   ================================ */
export const adminBanUser = functions.region("us-central1").https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "المستخدم غير مسجل");
  const adminUid = context.auth.uid;
  const adminDoc = await admin.firestore().collection("users").doc(adminUid).get();
  if (!adminDoc.exists || adminDoc.data()?.role !== "admin") {
    throw new functions.https.HttpsError("permission-denied", "ليس لديك صلاحية");
  }
  const {uid, reason} = data;
  if (!uid) throw new functions.https.HttpsError("invalid-argument", "uid مطلوب");
  await admin.auth().updateUser(uid, {disabled: true});
  await admin.firestore().collection("users").doc(uid).update({
    banned: true,
    banReason: reason || "بدون سبب",
    bannedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return {success: true, message: "تم حظر المستخدم"};
});

/* ================================
   3️⃣ adminUnbanUser
   ================================ */
export const adminUnbanUser = functions.region("us-central1").https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "المستخدم غير مسجل");
  const adminUid = context.auth.uid;
  const adminDoc = await admin.firestore().collection("users").doc(adminUid).get();
  if (!adminDoc.exists || adminDoc.data()?.role !== "admin") {
    throw new functions.https.HttpsError("permission-denied", "ليس لديك صلاحية");
  }
  const {uid} = data;
  if (!uid) throw new functions.https.HttpsError("invalid-argument", "uid مطلوب");
  await admin.auth().updateUser(uid, {disabled: false});
  await admin.firestore().collection("users").doc(uid).update({
    banned: false,
    unbannedAt: admin.firestore.FieldValue.serverTimestamp(),
  });
  return {success: true, message: "تم فك الحظر"};
});

// تصدير وظائف الستوري
export {onStoryDelete, onNotificationCreate} from "./storyFunctions";

/* ================================
   4️⃣ sendCallNotification (With Actions)
   ================================ */
export const sendCallNotification = functions.firestore
  .document("calls/{callId}")
  .onCreate(async (snapshot, context) => {
    const callData = snapshot.data();
    const receiverId = callData.receiverId;
    const callerId = callData.callerId;

    const receiverDoc = await admin.firestore().collection("users").doc(receiverId).get();
    const receiverData = receiverDoc.data();
    
    if (!receiverData || !receiverData.fcmToken) return null;

    const callerDoc = await admin.firestore().collection("users").doc(callerId).get();
    const callerName = callerDoc.data()?.name || "مستخدم";

    // إرسال رسالة تحتوي على بيانات + إشعار مرئي ليتلقى الجهاز الإشعار حتى لو كان التطبيق مغلقاً
    const payload: admin.messaging.Message = {
      token: receiverData.fcmToken,
      notification: {
        title: "مكالمة واردة",
        body: `${callerName} يتصل بك...`,
      },
      data: {
        type: "call",
        callId: context.params.callId,
        channelName: callData.channelName,
        callerId: callerId,
        callerName: callerName,
        isVideo: callData.type === "video" ? "true" : "false",
      },
      android: {
        priority: "high",
        ttl: 60000,
        notification: {
          channelId: "call_channel",
          sound: "default",
          defaultSound: true,
          visibility: "public",
        },
      },
      apns: {
        payload: {
          aps: {
            alert: { title: "مكالمة واردة", body: `${callerName} يتصل بك...` },
            sound: "default",
            contentAvailable: true,
          },
        },
      },
    };

    return admin.messaging().send(payload);
  });

/* ================================
   5️⃣ checkExpiredHarvests (Scheduled)
   ================================ */
export const checkExpiredHarvests = functions.pubsub
  .schedule("every 1 hours") // يعمل كل ساعة
  .onRun(async (context) => {
    const now = admin.firestore.Timestamp.now();
    const db = admin.firestore();

    // استعلام عن كل عمليات الحصاد النشطة التي انتهى وقتها
    const querySnapshot = await db
      .collectionGroup("active_harvests")
      .where("status", "==", "active")
      .where("endTime", "<=", now)
      .get();

    if (querySnapshot.empty) {
      console.log("No expired harvests to process.");
      return null;
    }

    const promises = querySnapshot.docs.map(async (doc) => {
      const harvest = doc.data();
      const userId = doc.ref.parent.parent?.id;

      if (!userId) return;

      // ١. تحديث حالة الحصاد إلى "جاهز للاستلام" لتجنب إرسال إشعارات متكررة
      await doc.ref.update({status: "ready_to_claim"});

      // ٢. إرسال إشعار للمستخدم
      const userDoc = await db.collection("users").doc(userId).get();
      const fcmToken = userDoc.data()?.fcmToken;

      if (fcmToken) {
        await admin.messaging().send({
          token: fcmToken,
          notification: {
            title: "🌟 مكافآتك جاهزة للاستلام!",
            body: `انتهت مدة حصادك في "${harvest.packageName}". اضغط هنا لاستلام مكافآتك.`,
          },
          data: {
            type: "harvest_ready",
            screen: "/harvest", // لتوجيه المستخدم للصفحة عند الضغط
          },
        });
      }
    });

    await Promise.all(promises);
    console.log(`Processed and sent notifications for ${querySnapshot.size} harvests.`);
    return null;
  });

/* ================================
   7️⃣ activateDailyRewards (Scheduled)
   ================================ */
export const activateDailyRewards = functions.pubsub
  .schedule("0 6 * * *")
  .timeZone("Asia/Baghdad")
  .onRun(async (context) => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();
    console.log("Activating daily rewards for all users...");

    try {
      // جلب جميع المستخدمين الذين لديهم باقات نشطة
      const activeRewardsSnapshot = await db
        .collectionGroup("active_rewards")
        .where("status", "==", "active")
        .get();

      if (activeRewardsSnapshot.empty) {
        console.log("No active rewards found.");
        return null;
      }

      console.log(`Found ${activeRewardsSnapshot.size} active rewards to process.`);

      const promises = activeRewardsSnapshot.docs.map(async (doc) => {
        const reward = doc.data();
        const userId = doc.ref.parent.parent?.id;

        if (!userId) {
          console.log(`Skipping reward ${doc.id}: No userId found`);
          return;
        }

        const lastRewardDate = reward.lastRewardDate ? 
          reward.lastRewardDate.toDate() : null;
        const dailyReward = reward.dailyReward || 0;
        const packageName = reward.packageName || "Unknown";

        // التحقق من مرور 24 ساعة منذ آخر حصاد
        if (lastRewardDate) {
          const nextAvailable = new Date(lastRewardDate.getTime() + 24 * 60 * 60 * 1000);
          if (now.toDate() < nextAvailable) {
            console.log(`Skipping reward ${doc.id} for user ${userId}: Not yet 24 hours since last harvest`);
            return;
          }
        }

        // تحديث وقت آخر حصاد
        await doc.ref.update({
          lastRewardDate: now,
          updated_at: now,
        });

        // إضافة الجواهر اليومية للمحفظة
        const userRef = db.collection("users").doc(userId);
        await userRef.update({
          rewards_wallet_gems: admin.firestore.FieldValue.increment(dailyReward),
          harvest_wallet: admin.firestore.FieldValue.increment(dailyReward),
        });

        // تسجيل العملية في السجل اليومي
        const logRef = userRef.collection("harvest_daily_logs").doc();
        await logRef.set({
          id: logRef.id,
          rewardId: doc.id,
          packageName: packageName,
          amount: dailyReward,
          currency: "gems",
          timestamp: now,
          type: "daily_claim_auto",
        });

        console.log(`Auto-harvested ${dailyReward} gems for user ${userId} from package ${packageName}`);

        // إرسال إشعار للمستخدم
        const userDoc = await userRef.get();
        const fcmToken = userDoc.data()?.fcmToken;

        if (fcmToken) {
          await admin.messaging().send({
            token: fcmToken,
            notification: {
              title: "🎁 حصاد تلقائي!",
              body: `تم حصاد ${dailyReward} جوهرة تلقائياً من باقة ${packageName}`,
            },
            data: {
              type: "auto_harvest",
              rewardId: doc.id,
            },
          });
        }
      });

      await Promise.all(promises);
      console.log(`Successfully processed ${activeRewardsSnapshot.size} rewards.`);
      return null;
    } catch (error) {
      console.error("Error activating daily rewards:", error);
      return null;
    }
  });

/* ================================
   8️⃣ finalizeExpiredPackages (Scheduled)
   ================================ */
export const finalizeExpiredPackages = functions.pubsub
  .schedule("0 7 * * *")
  .timeZone("Asia/Baghdad")
  .onRun(async (context) => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();
    console.log("Finalizing expired packages after 31 days...");

    try {
      // جلب جميع الباقات النشطة التي مر عليها 31 يوم
      const activeRewardsSnapshot = await db
        .collectionGroup("active_rewards")
        .where("status", "==", "active")
        .get();

      if (activeRewardsSnapshot.empty) {
        console.log("No active rewards found.");
        return null;
      }

      console.log(`Found ${activeRewardsSnapshot.size} active rewards to check for finalization.`);

      const promises = activeRewardsSnapshot.docs.map(async (doc) => {
        const reward = doc.data();
        const userId = doc.ref.parent.parent?.id;

        if (!userId) {
          console.log(`Skipping reward ${doc.id}: No userId found`);
          return;
        }

        const startTime = reward.startTime ? reward.startTime.toDate() : new Date();
        const expiryThreshold = new Date(startTime.getTime() + 31 * 24 * 60 * 60 * 1000); // 31 days

        if (now.toDate() < expiryThreshold) {
          console.log(`Skipping reward ${doc.id}: Not yet 31 days since start`);
          return;
        }

        // حساب النجوم المستحقة
        let starsAmount = 0;
        const packageSnapshot = await db
          .collection("reward_packages")
          .where("name", "==", reward.packageName)
          .limit(1)
          .get();

        if (packageSnapshot.docs.length > 0) {
          const pkg = packageSnapshot.docs[0].data();
          starsAmount = pkg.conversion_stars || 0;
        } else {
          // نسبة افتراضية (رأس المال + 5% ربح)
          const conversionRate = 105000 / 40400;
          starsAmount = (reward.totalReward || 0) * conversionRate;
        }

        // تحديث المحفظة (إضافة النجوم)
        const userRef = db.collection("users").doc(userId);
        const userDoc = await userRef.get();
        const userData = userDoc.data();

        if (userData) {
          const currentStars = userData.rewards_wallet_stars || userData.harvest_stars_wallet || 0;
          await userRef.update({
            rewards_wallet_stars: currentStars + starsAmount,
            harvest_stars_wallet: currentStars + starsAmount,
          });
        }

        // أرشفة الباقة
        const completedRef = userRef.collection("completed_rewards").doc(doc.id);
        await completedRef.set({
          ...reward,
          status: "finalized_and_converted",
          finalStarsAwarded: starsAmount,
          finalizedAt: now,
        });

        // حذف من النشط
        await doc.ref.delete();

        console.log(`Finalized package ${reward.packageName} for user ${userId}, awarded ${starsAmount} stars`);

        // إرسال إشعار
        const fcmToken = userData?.fcmToken;
        if (fcmToken) {
          await admin.messaging().send({
            token: fcmToken,
            notification: {
              title: "👑 اكتمال دورة الباقة",
              body: `تم تحويل باقة ${reward.packageName} بنجاح وإضافة ${starsAmount} نجمة لمحفظتك.`,
            },
            data: {
              type: "package_finalized",
              rewardId: doc.id,
            },
          });
        }
      });

      await Promise.all(promises);
      console.log(`Successfully processed package finalization.`);
      return null;
    } catch (error) {
      console.error("Error finalizing expired packages:", error);
      return null;
    }
  });

/* ================================
   9️⃣ sendHarvestReminders (Scheduled)
   ================================ */
export const sendHarvestReminders = functions.pubsub
  .schedule("0 */4 * * *") // كل 4 ساعات
  .timeZone("Asia/Baghdad")
  .onRun(async (context) => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();
    console.log("Sending harvest reminders...");

    try {
      // جلب جميع الباقات النشطة
      const activeRewardsSnapshot = await db
        .collectionGroup("active_rewards")
        .where("status", "==", "active")
        .get();

      if (activeRewardsSnapshot.empty) {
        console.log("No active rewards found.");
        return null;
      }

      const promises = activeRewardsSnapshot.docs.map(async (doc) => {
        const reward = doc.data();
        const userId = doc.ref.parent.parent?.id;

        if (!userId) return;

        const lastRewardDate = reward.lastRewardDate ? 
          reward.lastRewardDate.toDate() : null;

        if (!lastRewardDate) return; // لم يحصد بعد

        const hoursSinceLastHarvest = (now.toDate().getTime() - lastRewardDate.getTime()) / (1000 * 60 * 60);

        // إرسال تذكير إذا مرت 20 ساعة أو أكثر
        if (hoursSinceLastHarvest >= 20 && hoursSinceLastHarvest < 24) {
          const userDoc = await db.collection("users").doc(userId).get();
          const fcmToken = userDoc.data()?.fcmToken;

          if (fcmToken) {
            await admin.messaging().send({
              token: fcmToken,
              notification: {
                title: "⏰ حصادك جاهز!",
                body: `يمكنك حصاد مكافآتك من باقة ${reward.packageName} قريباً. لا تفوت فرصتك!`,
              },
              data: {
                type: "harvest_reminder",
                rewardId: doc.id,
              },
            });
          }
        }
      });

      await Promise.all(promises);
      console.log("Harvest reminders sent successfully.");
      return null;
    } catch (error) {
      console.error("Error sending harvest reminders:", error);
      return null;
    }
  });

/* ================================
   🔟 sendPackageExpiryWarnings (Scheduled)
   ================================ */
export const sendPackageExpiryWarnings = functions.pubsub
  .schedule("0 9 * * *") // يومياً الساعة 9 صباحاً
  .timeZone("Asia/Baghdad")
  .onRun(async (context) => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();
    console.log("Sending package expiry warnings...");

    try {
      // جلب جميع الباقات النشطة
      const activeRewardsSnapshot = await db
        .collectionGroup("active_rewards")
        .where("status", "==", "active")
        .get();

      if (activeRewardsSnapshot.empty) {
        console.log("No active rewards found.");
        return null;
      }

      const promises = activeRewardsSnapshot.docs.map(async (doc) => {
        const reward = doc.data();
        const userId = doc.ref.parent.parent?.id;

        if (!userId) return;

        const endTime = reward.endTime ? reward.endTime.toDate() : new Date();
        const daysUntilExpiry = Math.ceil((endTime.getTime() - now.toDate().getTime()) / (1000 * 60 * 60 * 24));

        // إرسال تحذير إذا بقي 3 أيام أو أقل
        if (daysUntilExpiry <= 3 && daysUntilExpiry > 0) {
          const userDoc = await db.collection("users").doc(userId).get();
          const fcmToken = userDoc.data()?.fcmToken;

          if (fcmToken) {
            await admin.messaging().send({
              token: fcmToken,
              notification: {
                title: "⚠️ باقتك تنتهي قريباً!",
                body: `باقة ${reward.packageName} ستنتهي خلال ${daysUntilExpiry} أيام. احصد مكافآتك الآن!`,
              },
              data: {
                type: "package_expiry_warning",
                rewardId: doc.id,
                daysLeft: daysUntilExpiry.toString(),
              },
            });
          }
        }
      });

      await Promise.all(promises);
      console.log("Package expiry warnings sent successfully.");
      return null;
    } catch (error) {
      console.error("Error sending package expiry warnings:", error);
      return null;
    }
  });

/* ================================
   1️⃣1️⃣ onHarvestListingCreated (Alert System)
   ================================ */
export const onHarvestListingCreated = functions.firestore
  .document("harvest_listings/{listingId}")
  .onCreate(async (snapshot, context) => {
    const listing = snapshot.data();
    if (!listing || listing.status !== "active") return null;

    const db = admin.firestore();
    
    // البحث عن التنبيهات المطابقة لنوع الباقة والسعر والعملة
    const alertsSnapshot = await db.collection("harvest_market_alerts")
      .where("packageName", "==", listing.packageName)
      .where("currency", "==", listing.currency)
      .where("maxPrice", ">=", listing.askingPrice)
      .get();

    if (alertsSnapshot.empty) return null;

    const promises = alertsSnapshot.docs.map(async (alertDoc) => {
      const alert = alertDoc.data();
      
      // لا ترسل إشعاراً لصاحب العرض نفسه
      if (alert.userId === listing.sellerId) return null;

      const userDoc = await db.collection("users").doc(alert.userId).get();
      const userData = userDoc.data();
      
      if (!userData || !userData.fcmToken) return null;

      const message: admin.messaging.Message = {
        token: userData.fcmToken,
        notification: {
          title: "باقة متاحة تهمك! 🔔",
          body: `توفرت باقة ${listing.packageType} بسعر ${listing.askingPrice} ${listing.currency}`,
        },
        data: {
          type: "marketplace_alert",
          listingId: context.params.listingId,
        },
      };

      await admin.messaging().send(message);
      
      // حذف التنبيه تلقائياً بعد إرسال أول إشعار مطابق لتقليل الإزعاج
      return alertDoc.ref.delete();
    });

    return Promise.all(promises);
  });
