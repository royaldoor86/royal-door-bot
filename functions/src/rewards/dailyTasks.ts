import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

export const completeDailyTask = functions.region("us-central1").https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "يجب تسجيل الدخول");
  }
  const uid = context.auth.uid;
  const {taskId} = data;
  if (!taskId) {
    throw new functions.https.HttpsError("invalid-argument", "معرف المهمة (taskId) مطلوب");
  }

  const dailyTasksRef = admin.firestore().collection("daily_tasks").doc(uid);
  const userRef = admin.firestore().collection("users").doc(uid);

  const dailyTasksSnap = await dailyTasksRef.get();
  const tasks = dailyTasksSnap.exists ? dailyTasksSnap.data() || {} : {};

  if (tasks[taskId] === true) {
    throw new functions.https.HttpsError("already-exists", "تم استلام مكافأة هذه المهمة بالفعل");
  }

  const templateSnap = await admin.firestore().collection("daily_tasks_templates").doc("ar").get();
  const templateData = templateSnap.data();
  
  if (!templateData || !Array.isArray(templateData.tasks)) {
    throw new functions.https.HttpsError("not-found", "قالب المهام غير موجود");
  }

  let taskToComplete: Record<string, unknown> | null = null;
  for (const category of templateData.tasks) {
    if (Array.isArray(category.tasks)) {
      const found = category.tasks.find((t: Record<string, unknown>) => (t as Record<string, unknown>).id === taskId);
      if (found) {
        taskToComplete = found;
        break;
      }
    }
  }

  if (!taskToComplete) {
    throw new functions.https.HttpsError("not-found", "المهمة غير موجودة في القالب");
  }

  // تحقق من الترتيب للمهام التي لها order
  if ((taskToComplete as Record<string, unknown>).order && (taskToComplete as Record<string, unknown>).order as number > 1) {
    for (const category of templateData.tasks) {
      if (Array.isArray(category.tasks)) {
        const taskCompOrder = (taskToComplete as Record<string, unknown>).order as number;
        const prevTask = category.tasks.find(
          (t: Record<string, unknown>) =>
            (t as Record<string, unknown>).order === taskCompOrder - 1
        );
        if (prevTask) {
          if (tasks[prevTask.id] !== true) {
            throw new functions.https.HttpsError("failed-precondition", "يجب إكمال المهمة السابقة أولاً");
          }
          break;
        }
      }
    }
  }

  // تحديث الجوائز
  const update: Record<string, admin.firestore.FieldValue | number> = {};
  let rewardMsg = "";

  if (taskToComplete.type === "coin") {
    const val = Number(taskToComplete.reward) || 0;
    update.stars = admin.firestore.FieldValue.increment(val);
    update.coins = admin.firestore.FieldValue.increment(val); // مزامنة مع الكوينز للإصدارات القديمة
    rewardMsg = `تم إضافة +${val} نجمة ⭐`;
  } else if (taskToComplete.type === "gem") {
    const val = Number(taskToComplete.reward) || 0;
    update.gems = admin.firestore.FieldValue.increment(val);
    rewardMsg = `تم إضافة +${val} جوهرة`;
  } else if (taskToComplete.type === "both") {
    const stars = Number(taskToComplete.coin_reward) || 0;
    const gems = Number(taskToComplete.gem_reward) || 0;
    update.stars = admin.firestore.FieldValue.increment(stars);
    update.coins = admin.firestore.FieldValue.increment(stars); // مزامنة مع الكوينز للإصدارات القديمة
    update.gems = admin.firestore.FieldValue.increment(gems);
    rewardMsg = `تم إضافة +${stars} نجمة ⭐ و +${gems} جوهرة`;
  } else if (taskToComplete.type === "xp") {
    const val = Number(taskToComplete.reward) || 0;
    update.royalXP = admin.firestore.FieldValue.increment(val); // زيادة نقاط الخبرة (التسمية الجديدة)
    rewardMsg = `تم إضافة +${val} خبرة XP`;
  }

  await userRef.set(update, {merge: true});
  
  // وسم المهمة كمكتملة
  tasks[taskId] = true;
  await dailyTasksRef.set(tasks, {merge: true});

  // إضافة سجل
  const logRef = admin.firestore().collection("daily_tasks_logs").doc(uid).collection("logs").doc();
  await logRef.set({
    taskId,
    title: taskToComplete.title || "",
    date: admin.firestore.FieldValue.serverTimestamp(),
    rewardMsg,
  });

  return {status: "success", message: rewardMsg};
});
