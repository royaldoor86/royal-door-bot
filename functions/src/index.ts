import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { AppCheck } from "firebase-admin/app-check";

// Version: 1.0.1 - Removed Agora
import {claimDailyLogin} from "./rewards/dailyLogin";
import {completeDailyTask} from "./rewards/dailyTasks";
import {resetDailyTasks} from "./rewards/resetDailyTasks";
import {generateAgoraToken} from "./agora";
// import {sendOTP, verifyOTP, resendOTP, checkOTPStatus} from "./otp"; // File not found

admin.initializeApp();

// دالة مساعدة للتحقق من App Check token
async function verifyAppCheckToken(context: functions.https.CallableContext): Promise<void> {
  const appCheckToken = context.rawRequest?.headers?.['x-firebase-appcheck'];
  
  if (!appCheckToken) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'App Check token is missing'
    );
  }

  try {
    const token = typeof appCheckToken === 'string' ? appCheckToken : appCheckToken[0];
    await admin.appCheck().verifyToken(token);
  } catch (error) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'Invalid App Check token'
    );
  }
}

import {purchaseRewardFromMarketplace} from "./rewards/marketplace";

export {claimDailyLogin, completeDailyTask, resetDailyTasks, purchaseRewardFromMarketplace, generateAgoraToken};

import {manageChallenge, claimChallengeReward} from "./admin/challenges";
import {purchaseRoyalId, assignRoyalIdToUser, respondToRoyalIdRequest} from "./admin/royalIdManagement";
import {sendGift, collectRoomEarnings} from "./gifts";

// استيراد دوال بوت التلغرام
// import {handleTelegramUpdate, setTelegramWebhook, getTelegramWebhookInfo, approveImageFromBot, rejectImageFromBot} from "./telegram"; // File not found
import {telegramBotHandler} from "./telegram_bot_handler";
import {migrateTelegramUsers} from "./migrateTelegramUsers";
import {getTelegramCustomToken} from "./telegram_auth";

export {manageChallenge, claimChallengeReward, purchaseRoyalId, assignRoyalIdToUser, respondToRoyalIdRequest, sendGift, collectRoomEarnings};

// تصدير دوال بوت التلغرام
export {telegramBotHandler, migrateTelegramUsers, getTelegramCustomToken};

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
  sendFamilyWarNotification,
  sendFamilyVoteNotification,
  sendFamilyMiniGameNotification,
  sendFamilyChallengeNotification,
  sendFamilyAllianceNotification,
  sendFamilyMemberJoinedNotification,
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

/* ================================
   4️⃣ adminDeleteUser
   ================================ */
export const adminDeleteUser = functions.region("us-central1").https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "المستخدم غير مسجل");
  const adminUid = context.auth.uid;
  const adminDoc = await admin.firestore().collection("users").doc(adminUid).get();
  if (!adminDoc.exists || adminDoc.data()?.role !== "admin") {
    throw new functions.https.HttpsError("permission-denied", "ليس لديك صلاحية");
  }
  const {uid} = data;
  if (!uid) throw new functions.https.HttpsError("invalid-argument", "uid مطلوب");
  
  try {
    // حذف المستخدم من Firebase Auth
    await admin.auth().deleteUser(uid);
    return {success: true, message: "تم حذف المستخدم من Firebase Auth"};
  } catch (error: any) {
    // إذا كان المستخدم غير موجود في Auth، نرجع رسالة ولكن لا نوقف العملية
    if (error.code === 'auth/user-not-found') {
      console.log(`User ${uid} not found in Auth, but continuing with Firestore deletion`);
      return {success: true, message: "المستخدم غير موجود في Auth، يمكن حذفه من Firestore"};
    }
    throw error;
  }
});

// تصدير وظائف الستوري
export {onStoryDelete, onNotificationCreate} from "./storyFunctions";


/* ================================
   5️⃣ checkExpiredHarvests (Scheduled)
   ================================ */
export const checkExpiredHarvests = onSchedule(
  { schedule: "every 1 hours", region: "us-central1" },
  async () => {
    const now = admin.firestore.Timestamp.now();
    const db = admin.firestore();

    // استعلام عن كل عمليات المكافآت النشطة التي انتهى وقتها
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

      // ١. تحديث حالة المكافآت إلى "جاهز للاستلام" لتجنب إرسال إشعارات متكررة
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
  }
);

/* ================================
   7️⃣ activateDailyRewards (Scheduled)
   ================================ */
export const activateDailyRewards = onSchedule(
  { schedule: "0 6 * * *", timeZone: "Asia/Baghdad", region: "us-central1" },
  async () => {
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

        // التحقق من مرور 24 ساعة منذ آخر مكافأه
        if (lastRewardDate) {
          const nextAvailable = new Date(lastRewardDate.getTime() + 24 * 60 * 60 * 1000);
          if (now.toDate() < nextAvailable) {
            console.log(`Skipping reward ${doc.id} for user ${userId}: Not yet 24 hours since last harvest`);
            return;
          }
        }

        // تحديث وقت آخر مكافأه
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
  }
);

/* ================================
   8️⃣ finalizeExpiredPackages (Scheduled)
   ================================ */
export const finalizeExpiredPackages = onSchedule(
  { schedule: "0 7 * * *", timeZone: "Asia/Baghdad", region: "us-central1" },
  async () => {
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
      console.log("Successfully processed package finalization.");
      return null;
    } catch (error) {
      console.error("Error finalizing expired packages:", error);
      return null;
    }
  });
/* ================================
   9️⃣ sendHarvestReminders (Scheduled)
   ================================ */
export const sendHarvestReminders = onSchedule(
  { schedule: "0 */4 * * *", timeZone: "Asia/Baghdad", region: "us-central1" },
  async () => {
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
                title: "⏰ مكافأتك جاهزة!",
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
   
10 sendPackageExpiryWarnings (Scheduled)
   ================================ */
export const sendPackageExpiryWarnings = functions.pubsub
  .schedule("0 9 * * *") // يومياً الساعة 9 صباحاً
  .timeZone("Asia/Baghdad")
  .onRun(async () => {
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
  }
);

/* ================================
   11 onHarvestListingCreated (Alert System)
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

/* ================================
   12 endExpiredFamilyWars (Scheduled)
   ================================ */
export const endExpiredFamilyWars = functions.pubsub
  .schedule("every 1 minutes")
  .timeZone("Asia/Baghdad")
  .onRun(async () => {
    const db = admin.firestore();
    const now = admin.firestore.Timestamp.now();
    console.log("Checking for expired family wars...");

    try {
      // جلب جميع الحروب النشطة التي انتهى وقتها
      const warsSnapshot = await db
        .collection("family_wars")
        .where("status", "==", "active")
        .where("endTime", "<=", now)
        .get();

      if (warsSnapshot.empty) {
        console.log("No expired wars found.");
        return null;
      }

      console.log(`Found ${warsSnapshot.size} expired wars to process.`);

      const promises = warsSnapshot.docs.map(async (doc) => {
        const war = doc.data();
        const warId = doc.id;

        const challengerPoints = war.challengerPoints || 0;
        const targetPoints = war.targetPoints || 0;
        const challengerId = war.challengerId;
        const targetId = war.targetId;
        const rewards = war.rewards || {};

        let winnerId: string | null = null;

        // تحديد الفائز بناءً على النقاط
        if (challengerPoints > targetPoints) {
          winnerId = challengerId;
        } else if (targetPoints > challengerPoints) {
          winnerId = targetId;
        }

        await db.runTransaction(async (transaction) => {
          if (winnerId) {
            const loserId = winnerId === challengerId ? targetId : challengerId;

            // توزيع المكافآت للفائز
            const winnerRef = db.collection("families").doc(winnerId);
            transaction.update(winnerRef, {
              warWins: admin.firestore.FieldValue.increment(1),
              warExp: admin.firestore.FieldValue.increment(100),
              warPoints: admin.firestore.FieldValue.increment(100),
              familyGems: admin.firestore.FieldValue.increment(rewards.winnerGems || 500),
              familyCoins: admin.firestore.FieldValue.increment(rewards.winnerStars || 2500),
              currentWarId: null,
            });

            // توزيع مكافآت الخاسر
            const loserRef = db.collection("families").doc(loserId);
            transaction.update(loserRef, {
              warLosses: admin.firestore.FieldValue.increment(1),
              familyGems: admin.firestore.FieldValue.increment(rewards.loserGems || 100),
              familyCoins: admin.firestore.FieldValue.increment(rewards.loserStars || 500),
              currentWarId: null,
            });

            // منح شارة الحرب للفائز
            if (rewards.badge) {
              transaction.set(
                winnerRef.collection("badges").doc(rewards.badge),
                {
                  badgeId: rewards.badge,
                  awardedAt: admin.firestore.FieldValue.serverTimestamp(),
                  type: "war_reward",
                  warId: warId,
                }
              );
            }
          } else {
            // تعادل
            transaction.update(db.collection("families").doc(challengerId), {
              familyGems: admin.firestore.FieldValue.increment(200),
              familyCoins: admin.firestore.FieldValue.increment(1000),
              currentWarId: null,
            });
            transaction.update(db.collection("families").doc(targetId), {
              familyGems: admin.firestore.FieldValue.increment(200),
              familyCoins: admin.firestore.FieldValue.increment(1000),
              currentWarId: null,
            });
          }

          // تحديث حالة الحرب
          transaction.update(doc.ref, {
            status: "completed",
            winnerId: winnerId,
            completedAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        });

        console.log(`War ${warId} ended. Winner: ${winnerId || "Draw"}`);
      });

      await Promise.all(promises);
      console.log(`Successfully processed ${warsSnapshot.size} expired wars.`);
      return null;
    } catch (error) {
      console.error("Error ending expired family wars:", error);
      return null;
    }
  }
);

/* ================================
   13 updateMemberRanksDaily (Scheduled)
   ================================ */
export const updateMemberRanksDaily = functions.pubsub
  .schedule("0 0 * * *") // يومياً منتصف الليل
  .timeZone("Asia/Baghdad")
  .onRun(async () => {
    const db = admin.firestore();
    console.log("Updating member ranks for all families...");

    try {
      // جلب جميع العائلات
      const familiesSnapshot = await db.collection("families").get();

      if (familiesSnapshot.empty) {
        console.log("No families found.");
        return null;
      }

      console.log(`Found ${familiesSnapshot.size} families to process.`);

      // تعريف الرتب الافتراضية
      const defaultRanks = [
        {id: "bronze", requiredPoints: 0},
        {id: "silver", requiredPoints: 500},
        {id: "gold", requiredPoints: 1500},
        {id: "platinum", requiredPoints: 3000},
        {id: "diamond", requiredPoints: 5000},
        {id: "royal", requiredPoints: 10000},
      ];

      const promises = familiesSnapshot.docs.map(async (familyDoc) => {
        const familyId = familyDoc.id;
        const familyName = familyDoc.data()?.name || "Unknown";

        // جلب جميع أعضاء العائلة
        const membersSnapshot = await db
          .collection("families")
          .doc(familyId)
          .collection("members")
          .get();

        if (membersSnapshot.empty) return;

        const memberPromises = membersSnapshot.docs.map(async (memberDoc) => {
          const memberData = memberDoc.data();
          const userId = memberDoc.id;
          const contributionPoints = memberData.contributionPoints || 0;
          const currentRankId = memberData.rankId || "bronze";

          // تحديد الرتبة المناسبة بناءً على النقاط
          let newRank = defaultRanks[0];
          for (const rank of defaultRanks) {
            if (contributionPoints >= rank.requiredPoints) {
              newRank = rank;
            } else {
              break;
            }
          }

          // تحديث الرتبة إذا تغيرت
          if (newRank.id !== currentRankId) {
            await db
              .collection("families")
              .doc(familyId)
              .collection("members")
              .doc(userId)
              .update({
                rankId: newRank.id,
                rankLevel: defaultRanks.findIndex((r) => r.id === newRank.id) + 1,
                rankUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
              });

            console.log(`Updated rank for user ${userId} in family ${familyName}: ${currentRankId} -> ${newRank.id}`);
          }
        });

        await Promise.all(memberPromises);
      });

      await Promise.all(promises);
      console.log("Successfully updated member ranks for all families.");
      return null;
    } catch (error) {
      console.error("Error updating member ranks:", error);
      return null;
    }
  }
);
