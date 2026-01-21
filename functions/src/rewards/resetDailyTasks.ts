import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Scheduled Function: Reset daily tasks for all users every day at 3 AM UTC
export const resetDailyTasks = functions.pubsub.schedule("0 3 * * *").timeZone("UTC").onRun(async (context) => {
  const dailyTasksRef = admin.firestore().collection("daily_tasks");
  const snapshot = await dailyTasksRef.get();
  const batch = admin.firestore().batch();

  snapshot.forEach((doc) => {
    // إعادة تعيين جميع المهام إلى false
    const data = doc.data();
    const resetData: any = {};
    for (const key in data) {
      if (Object.prototype.hasOwnProperty.call(data, key)) {
        resetData[key] = false;
      }
    }
    batch.set(doc.ref, resetData, {merge: true});
  });

  await batch.commit();
  console.log("تمت إعادة تعيين جميع المهام اليومية لكل المستخدمين");
  return null;
});
