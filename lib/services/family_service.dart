import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/family_model.dart';

class FamilyService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // إنشاء عائلة جديدة مع ربطها بغرفة
  Future<void> createFamily({
    required String name,
    required String description,
    required String slogan,
    required String logoUrl,
    String? roomId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول أولاً';

    final userDoc = await _db.collection('users').doc(user.uid).get();
    if (userDoc.data()?['familyId'] != null) throw 'أنت منضم لعائلة بالفعل';

    final familyRef = _db.collection('families').doc();
    
    await _db.runTransaction((tx) async {
      tx.set(familyRef, {
        'name': name,
        'description': description,
        'slogan': slogan,
        'logoUrl': logoUrl,
        'creatorId': user.uid,
        'roomId': roomId,
        'totalPoints': 0,
        'dailyPoints': 0,
        'weeklyPoints': 0,
        'monthlyPoints': 0,
        'memberCount': 1,
        'maxMembers': 50,
        'level': 1,
        'minLevelToJoin': 1,
        'isVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.update(_db.collection('users').doc(user.uid), {
        'familyId': familyRef.id,
        'familyRole': 'leader',
      });

      tx.set(familyRef.collection('members').doc(user.uid), {
        'uid': user.uid,
        'role': 'leader',
        'joinedAt': FieldValue.serverTimestamp(),
        'totalContribution': 0,
      });
    });
  }

  // تحديث بيانات العائلة
  Future<void> updateFamily({
    required String familyId,
    String? name,
    String? description,
    String? slogan,
    String? logoUrl,
    int? minLevelToJoin,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول أولاً';

    final familyRef = _db.collection('families').doc(familyId);
    final familySnap = await familyRef.get();
    
    if (!familySnap.exists) throw 'العائلة غير موجودة';
    if (familySnap.data()?['creatorId'] != user.uid) throw 'ليس لديك صلاحية تعديل هذه العائلة';

    Map<String, dynamic> updates = {};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (slogan != null) updates['slogan'] = slogan;
    if (logoUrl != null) updates['logoUrl'] = logoUrl;
    if (minLevelToJoin != null) updates['minLevelToJoin'] = minLevelToJoin;

    await familyRef.update(updates);
  }

  // حذف العائلة نهائياً
  Future<void> deleteFamily(String familyId) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول أولاً';

    final familyRef = _db.collection('families').doc(familyId);
    final familySnap = await familyRef.get();
    
    if (!familySnap.exists) throw 'العائلة غير موجودة';
    if (familySnap.data()?['creatorId'] != user.uid) throw 'ليس لديك صلاحية حذف هذه العائلة';

    // العملية تتطلب حذف المرجع من جميع الأعضاء أولاً
    final membersSnap = await familyRef.collection('members').get();
    
    final batch = _db.batch();
    
    for (var doc in membersSnap.docs) {
      // إزالة العائلة من بروفايل العضو
      batch.update(_db.collection('users').doc(doc.id), {
        'familyId': null,
        'familyRole': null,
      });
      // حذف وثيقة العضوية
      batch.delete(doc.reference);
    }

    // حذف وثيقة العائلة نفسها
    batch.delete(familyRef);

    await batch.commit();
  }

  // إزالة عضو من العائلة (طرد بواسطة القائد)
  Future<void> removeMember(String familyId, String targetUserId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw 'يجب تسجيل الدخول أولاً';

    // التأكد أن المستخدم الحالي هو القائد
    final familyRef = _db.collection('families').doc(familyId);
    final familySnap = await familyRef.get();
    if (familySnap.data()?['creatorId'] != currentUserId) throw 'ليس لديك صلاحية طرد الأعضاء';
    
    if (targetUserId == currentUserId) throw 'لا يمكنك طرد نفسك، استخدم خيار الحذف أو المغادرة';

    await _db.runTransaction((tx) async {
      tx.update(familyRef, {
        'memberCount': FieldValue.increment(-1)
      });
      tx.update(_db.collection('users').doc(targetUserId), {
        'familyId': null,
        'familyRole': null
      });
      tx.delete(familyRef.collection('members').doc(targetUserId));
    });
  }

  // إضافة نقاط للعائلة (عند إرسال هدايا)
  Future<void> addFamilyPoints(String familyId, String userId, int points) async {
    final familyRef = _db.collection('families').doc(familyId);
    final memberRef = familyRef.collection('members').doc(userId);

    await _db.runTransaction((tx) async {
      final familySnap = await tx.get(familyRef);
      if (!familySnap.exists) return;

      int newTotal = (familySnap.data()?['totalPoints'] ?? 0) + points;
      int newDaily = (familySnap.data()?['dailyPoints'] ?? 0) + points;
      
      // تحديث الليفل تلقائياً بناءً على النقاط
      int currentLevel = (familySnap.data()?['level'] ?? 1);
      int nextLevelPoints = currentLevel * currentLevel * 10000;
      if (newTotal >= nextLevelPoints) {
        currentLevel++;
        tx.update(familyRef, {'level': currentLevel, 'maxMembers': 50 + (currentLevel * 5)});
      }

      tx.update(familyRef, {
        'totalPoints': newTotal,
        'dailyPoints': newDaily,
        'weeklyPoints': FieldValue.increment(points),
        'monthlyPoints': FieldValue.increment(points),
      });

      tx.update(memberRef, {
        'totalContribution': FieldValue.increment(points),
      });
    });
  }

  // الانضمام لعائلة مع التحقق من الشروط
  Future<void> joinFamily(String familyId) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول أولاً';

    final userRef = _db.collection('users').doc(user.uid);
    final familyRef = _db.collection('families').doc(familyId);

    await _db.runTransaction((tx) async {
      final userSnap = await tx.get(userRef);
      final userData = userSnap.data() ?? {};
      if (userData['familyId'] != null) throw 'أنت منضم لعائلة بالفعل';

      final familySnap = await tx.get(familyRef);
      final familyData = familySnap.data() ?? {};
      
      int currentMembers = (familyData['memberCount'] ?? 0);
      int maxMembers = (familyData['maxMembers'] ?? 50);
      int minLevel = (familyData['minLevelToJoin'] ?? 1);
      int userLevel = (userData['level'] ?? 1);

      if (currentMembers >= maxMembers) throw 'العائلة ممتلئة';
      if (userLevel < minLevel) throw 'مستواك أقل من الحد الأدنى المطلوب للانضمام';

      tx.update(familyRef, {'memberCount': currentMembers + 1});
      tx.update(userRef, {'familyId': familyId, 'familyRole': 'member'});
      tx.set(familyRef.collection('members').doc(user.uid), {
        'uid': user.uid,
        'role': 'member',
        'joinedAt': FieldValue.serverTimestamp(),
        'totalContribution': 0,
      });
    });
  }

  // إضافة عضو بواسطة القائد باستخدام الـ ID القصير
  Future<void> addMemberByShortId(String familyId, String shortId) async {
    final currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) throw 'يجب تسجيل الدخول أولاً';

    // التأكد أن المستخدم الحالي هو القائد
    final memberDoc = await _db.collection('families').doc(familyId).collection('members').doc(currentUserId).get();
    if (!memberDoc.exists || memberDoc.data()?['role'] != 'leader') {
      throw 'ليس لديك صلاحية إضافة أعضاء';
    }

    // البحث عن المستخدم بواسطة shortId
    final userQuery = await _db.collection('users').where('shortId', isEqualTo: shortId).limit(1).get();
    if (userQuery.docs.isEmpty) throw 'المستخدم غير موجود';
    
    final targetUserDoc = userQuery.docs.first;
    final targetUserId = targetUserDoc.id;
    final targetUserData = targetUserDoc.data();

    if (targetUserData['familyId'] != null) throw 'المستخدم منضم لعائلة بالفعل';

    final familyRef = _db.collection('families').doc(familyId);

    await _db.runTransaction((tx) async {
      final familySnap = await tx.get(familyRef);
      int currentMembers = (familySnap.data()?['memberCount'] ?? 0);
      int maxMembers = (familySnap.data()?['maxMembers'] ?? 50);

      if (currentMembers >= maxMembers) throw 'العائلة ممتلئة';

      tx.update(familyRef, {'memberCount': currentMembers + 1});
      tx.update(_db.collection('users').doc(targetUserId), {
        'familyId': familyId,
        'familyRole': 'member'
      });
      tx.set(familyRef.collection('members').doc(targetUserId), {
        'uid': targetUserId,
        'role': 'member',
        'joinedAt': FieldValue.serverTimestamp(),
        'totalContribution': 0,
      });
    });
  }

  // مغادرة العائلة
  Future<void> leaveFamily(String familyId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _db.runTransaction((tx) async {
      tx.update(_db.collection('families').doc(familyId), {
        'memberCount': FieldValue.increment(-1)
      });
      tx.update(_db.collection('users').doc(user.uid), {
        'familyId': null,
        'familyRole': null
      });
      tx.delete(_db.collection('families').doc(familyId).collection('members').doc(user.uid));
    });
  }

  // البحث عن العائلات (عالمي)
  Stream<List<FamilyModel>> searchFamilies(String query) {
    return _db.collection('families')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => FamilyModel.fromFirestore(doc)).toList());
  }

  // جلب المتصدرين حسب النوع (يومي، أسبوعي، كلي)
  Stream<List<FamilyModel>> getLeaderboard(String type) {
    String field = 'totalPoints';
    if (type == 'daily') field = 'dailyPoints';
    if (type == 'weekly') field = 'weeklyPoints';

    return _db.collection('families')
        .orderBy(field, descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => FamilyModel.fromFirestore(doc)).toList());
  }
}
