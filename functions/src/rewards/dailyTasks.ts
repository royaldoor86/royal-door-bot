import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Cloud Function: completeDailyTask
export const completeDailyTask = functions.region("us-central1").https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "يجب تسجيل الدخول");
  }
  const uid = context.auth.uid;
  const {taskId} = data;
  if (!taskId) {
    throw new functions.https.HttpsError("invalid-argument", "معرف المهمة (taskId) مطلوب");
  }

  // مراجع Firestore
  const dailyTasksRef = admin.firestore().collection("daily_tasks").doc(uid);
  const userRef = admin.firestore().collection("users").doc(uid);

  // جلب بيانات المهام
  const dailyTasksSnap = await dailyTasksRef.get();
  const tasks = dailyTasksSnap.exists ? dailyTasksSnap.data() || {} : {};

  // تحقق إذا كانت المهمة مكتملة مسبقًا

  if (tasks[taskId] === true) {
    throw new functions.https.HttpsError("already-exists", "تم استلام مكافأة هذه المهمة بالفعل");
  }

  // تحديث المهمة كمكتملة
  tasks[taskId] = true;
  await dailyTasksRef.set(tasks, {merge: true});

  // جلب بيانات المهمة من daily_tasks_templates/ar
  const templateSnap = await admin.firestore().collection("daily_tasks_templates").doc("ar").get();
  const templateData = templateSnap.data();
  let rewardMsg = "";
  if (templateData && Array.isArray(templateData.tasks)) {
    let found = false;
    for (const category of templateData.tasks) {
      if (Array.isArray(category.tasks)) {
        for (const task of category.tasks) {
          if (task.id === taskId || task.title === taskId) {
            found = true;
            // التحقق من صلاحية VIP/Level
            const userSnap = await userRef.get();
            const userData = userSnap.data() || {};
            // VIP فقط
            if (task.vipOnly === true && !(userData.vip?.active === true)) {
              throw new functions.https.HttpsError("permission-denied", "هذه المهمة متاحة فقط لمشتركي VIP");
            }
            // مستوى معين
            if (task.minLevel && (userData.level || 0) < task.minLevel) {
              throw new functions.https.HttpsError("permission-denied", `هذه المهمة تتطلب مستوى ${task.minLevel} على الأقل`);
            }
            const rewardType = task.type || "coin";
            const rewardValue = Number(task.reward) || 0;
            const update: any = {};
            if (rewardType === "coin") {
              update.coins = admin.firestore.FieldValue.increment(rewardValue);
              rewardMsg = `تم إضافة +${rewardValue} كوينز`;
            } else if (rewardType === "gem") {
              update.gems = admin.firestore.FieldValue.increment(rewardValue);
              rewardMsg = `تم إضافة +${rewardValue} جوهرة`;
            } else if (rewardType === "xp") {
              update.xp = admin.firestore.FieldValue.increment(rewardValue);
              rewardMsg = `تم إضافة +${rewardValue} نقطة خبرة`;
            } else {
              rewardMsg = "تم استلام مكافأة المهمة.";
            }
            await userRef.set(update, {merge: true});
            // إضافة log في daily_tasks_logs/{uid}/logs
            const logRef = admin.firestore().collection("daily_tasks_logs").doc(uid).collection("logs").doc();
            await logRef.set({
              taskId,
              title: task.title || "",
              rewardType,
              rewardValue,
              date: admin.firestore.FieldValue.serverTimestamp(),
            });
            break;
          }
        }
      }
      if (found) break;
    }
    if (!found) rewardMsg = "تم استلام مكافأة المهمة.";
  } else {
    rewardMsg = "تم استلام مكافأة المهمة.";
  }

  return {
    message: rewardMsg || "تم استلام مكافأة المهمة اليومية",
    taskId,
  };
});
