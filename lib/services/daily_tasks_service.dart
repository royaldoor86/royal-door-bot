import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DailyTasksService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// إكمال المهمة ومنح الجوائز
  static Future<Map<String, dynamic>> completeTask(String taskId) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول';

    // البحث في القوالب (جلب كافة التصنيفات)
    final doc = await _firestore.collection('daily_tasks_templates').doc('ar').get();
    if (!doc.exists) throw 'لا توجد مهام حالياً';

    final List categories = doc.data()?['tasks'] ?? [];
    Map<String, dynamic>? taskData;

    // البحث عن المهمة المحددة داخل التصنيفات
    for (var cat in categories) {
      final List tasks = cat['tasks'] ?? [];
      for (var t in tasks) {
        if (t['id'] == taskId) {
          taskData = Map<String, dynamic>.from(t);
          break;
        }
      }
    }

    if (taskData == null) throw 'بيانات المهمة غير موجودة';
    
    await _applyReward(taskId, taskData);
    
    return {'status': 'success', 'message': 'تم استلام الجوائز الملكية بنجاح 🎉'};
  }

  static Future<void> _applyReward(String taskId, Map<String, dynamic> taskData) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userRef = _firestore.collection('users').doc(user.uid);
    
    await _firestore.runTransaction((tx) async {
      final userSnap = await tx.get(userRef);
      if (!userSnap.exists) return;

      final userData = userSnap.data()!;
      
      int currentGems = (userData['gems'] ?? 0).toInt();
      int currentCoins = (userData['coins'] ?? 0).toInt();
      int currentLevel = (userData['userLevel'] ?? 1).toInt();

      tx.update(userRef, {
        'gems': currentGems + (taskData['reward'] != null && taskData['type'] == 'gem' ? taskData['reward'] : 0),
        'coins': currentCoins + (taskData['reward'] != null && taskData['type'] == 'coin' ? taskData['reward'] : 0),
        'userLevel': currentLevel + (taskData['reward'] != null && taskData['type'] == 'xp' ? taskData['reward'] : 0),
      });

      // وسم المهمة كمكتملة
      final tasksRef = _firestore.collection('daily_tasks').doc(user.uid);
      tx.set(tasksRef, {taskId: true}, SetOptions(merge: true));
    });
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> dailyTasksStream(String uid) {
    return _firestore.collection('daily_tasks').doc(uid).snapshots();
  }

  static Future<List<Map<String, dynamic>>> fetchTasksTemplate({String lang = 'ar'}) async {
    final doc = await _firestore.collection('daily_tasks_templates').doc(lang).get();
    if (!doc.exists) return [];
    final data = doc.data();
    if (data == null || data['tasks'] == null) return [];
    return List<Map<String, dynamic>>.from(data['tasks']);
  }
}
