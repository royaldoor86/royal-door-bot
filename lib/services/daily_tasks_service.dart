import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DailyTasksService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// إكمال المهمة ومنح الجوائز بشكل حقيقي في قاعدة البيانات
  static Future<void> completeTask(String taskId) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول أولاً';

    // 1. الحصول على بيانات المهمة من القالب
    final doc = await _firestore.collection('daily_tasks_templates').doc('ar').get();
    if (!doc.exists) throw 'قالب المهام غير موجود';

    final List tasksData = doc.data()?['tasks'] ?? [];
    Map<String, dynamic>? currentTask;

    for (var cat in tasksData) {
      final List tList = cat['tasks'] ?? [];
      for (var t in tList) {
        if (t['id'] == taskId) {
          currentTask = Map<String, dynamic>.from(t);
          break;
        }
      }
    }

    if (currentTask == null) throw 'بيانات المهمة غير موجودة';

    final userRef = _firestore.collection('users').doc(user.uid);
    final taskProgressRef = _firestore.collection('daily_tasks').doc(user.uid);

    // 2. تحديث بيانات المستخدم في ترانزاكشن واحد لضمان الدقة
    await _firestore.runTransaction((transaction) async {
      final userSnap = await transaction.get(userRef);
      final taskSnap = await transaction.get(taskProgressRef);

      if (!userSnap.exists) throw 'حساب المستخدم غير موجود';

      // التأكد أن المهمة لم تكتمل بالفعل اليوم
      if (taskSnap.exists) {
        final completedTasks = taskSnap.data() as Map<String, dynamic>;
        if (completedTasks[taskId] == true) {
          throw 'تم استلام جائزة هذه المهمة بالفعل اليوم';
        }
      }

      final userData = userSnap.data()!;
      final rewardAmount = (currentTask!['reward'] ?? 0).toInt();
      final rewardType = currentTask['type'];

      Map<String, dynamic> updates = {};

      // تطبيق الجائزة بناءً على نوعها
      if (rewardType == 'coin') {
        updates['stars'] = (userData['stars'] ?? 0) + rewardAmount;
        updates['coins'] = (userData['coins'] ?? 0) + rewardAmount; // Keep in sync
      } else if (rewardType == 'gem') {
        updates['gems'] = (userData['gems'] ?? 0) + rewardAmount;
      } else if (rewardType == 'xp') {
        // زيادة مستوى الخبرة XP الملكي
        updates['royalXP'] = (userData['royalXP'] ?? 0) + rewardAmount;
      }

      // تحديث بيانات المستخدم
      transaction.update(userRef, updates);

      // تعليم المهمة كمكتملة في سجل المستخدم اليومي
      transaction.set(taskProgressRef, {
        taskId: true,
        'lastUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  /// الاستماع لحالة المهام المكتملة للمستخدم الحالي
  static Stream<DocumentSnapshot<Map<String, dynamic>>> dailyTasksStream(String uid) {
    return _firestore.collection('daily_tasks').doc(uid).snapshots();
  }

  /// فحص وتصفير المهام إذا بدأ يوم جديد
  static Future<void> checkAndResetTasks(String uid) async {
    try {
      final doc = await _firestore.collection('daily_tasks').doc(uid).get();
      if (!doc.exists) return;

      final data = doc.data();
      if (data == null || data['lastUpdate'] == null) return;

      // الحصول على تاريخ آخر تحديث بشكل آمن
      final lastUpdateVal = data['lastUpdate'];
      if (lastUpdateVal == null || lastUpdateVal is! Timestamp) {
        // إذا كان الحقل غير موجود أو ليس Timestamp، نقوم بتصفير المهام لضمان السلامة
        await _firestore.collection('daily_tasks').doc(uid).set({
          'lastUpdate': FieldValue.serverTimestamp(),
        });
        return;
      }

      DateTime lastUpdate = lastUpdateVal.toDate();
      DateTime now = DateTime.now();

      // إذا كان اليوم مختلفاً (سنة أو شهر أو يوم)
      if (lastUpdate.year != now.year || 
          lastUpdate.month != now.month || 
          lastUpdate.day != now.day) {
        
        // تصفير جميع المهام (حذف جميع الحقول ما عدا الحقول الأساسية إن وجدت)
        // أو ببساطة حذف الوثيقة لتبدأ من جديد
        await _firestore.collection('daily_tasks').doc(uid).delete();
        
        // إنشاء وثيقة جديدة بتوقيت الآن لكي لا يتكرر التصفير في نفس اليوم
        await _firestore.collection('daily_tasks').doc(uid).set({
          'lastUpdate': FieldValue.serverTimestamp(),
        });
        
        print("DailyTasks: Tasks have been reset for a new day!");
      }
    } catch (e) {
      print("Error resetting tasks: $e");
    }
  }

  /// جلب قوالب المهام المتاحة
  static Future<List<Map<String, dynamic>>> fetchTasksTemplate({String lang = 'ar'}) async {
    try {
      final doc = await _firestore.collection('daily_tasks_templates').doc(lang).get();
      if (!doc.exists) {
        // إذا لم يكن القالب موجوداً، نقوم بإنشائه فوراً لضمان عمل الصفحة
        await setupAdTasks();
        final newDoc = await _firestore.collection('daily_tasks_templates').doc(lang).get();
        final data = newDoc.data();
        return data != null && data['tasks'] != null ? List<Map<String, dynamic>>.from(data['tasks']) : [];
      }
      final data = doc.data();
      if (data == null || data['tasks'] == null) return [];
      return List<Map<String, dynamic>>.from(data['tasks']);
    } catch (e) {
      print("Error fetching tasks template: $e");
      return []; // إرجاع قائمة فارغة بدلاً من تعليق التطبيق
    }
  }

  /// إعداد أولي للمهمات (10 مهمات لزيادة الأرباح)
  static Future<void> setupAdTasks() async {
    final List tasks = [
      {
        'category': 'المهام الملكية اليومية',
        'tasks': [
          {'id': 'ad_task_1', 'title': 'المهمة 1: دعم المملكة', 'desc': '5 نجوم ⭐ ملكية', 'type': 'coin', 'reward': 5, 'isAd': true, 'order': 1},
          {'id': 'ad_task_2', 'title': 'المهمة 2: كنز الياقوت', 'desc': '5 مجوهرات زرقاء', 'type': 'gem', 'reward': 5, 'isAd': true, 'order': 2},
          {'id': 'ad_task_3', 'title': 'المهمة 3: هدية الملوك', 'desc': '7 نجوم ⭐ ملكية', 'type': 'coin', 'reward': 7, 'isAd': true, 'order': 3},
          {'id': 'ad_task_4', 'title': 'المهمة 4: جوهرة التاج', 'desc': '7 مجوهرات زرقاء', 'type': 'gem', 'reward': 7, 'isAd': true, 'order': 4},
          {'id': 'ad_task_5', 'title': 'المهمة 5: وسام الاستحقاق', 'desc': '10 نجوم ⭐ ملكية', 'type': 'coin', 'reward': 10, 'isAd': true, 'order': 5},
          {'id': 'ad_task_6', 'title': 'المهمة 6: الياقوت النادر', 'desc': '10 مجوهرات زرقاء', 'type': 'gem', 'reward': 10, 'isAd': true, 'order': 6},
          {'id': 'ad_task_7', 'title': 'المهمة 7: ثروة القصر', 'desc': '12 نجمة ⭐ ملكية', 'type': 'coin', 'reward': 12, 'isAd': true, 'order': 7},
          {'id': 'ad_task_8', 'title': 'المهمة 8: ماسة الامبراطور', 'desc': '12 مجوهرة زرقاء', 'type': 'gem', 'reward': 12, 'isAd': true, 'order': 8},
          {'id': 'ad_task_9', 'title': 'المهمة 9: خبرة ملكية', 'desc': '15 خبرة XP', 'type': 'xp', 'reward': 15, 'isAd': true, 'order': 9},
          {'id': 'ad_task_10', 'title': 'المهمة 10: الجائزة الكبرى', 'desc': '20 خبرة XP', 'type': 'xp', 'reward': 20, 'isAd': true, 'order': 10},
        ]
      }
    ];
    await _firestore.collection('daily_tasks_templates').doc('ar').set({'tasks': tasks});
  }
}
