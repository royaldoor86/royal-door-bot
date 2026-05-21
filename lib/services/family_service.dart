import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/family_model.dart';
import '../models/family_notification_model.dart';
import '../models/family_event_model.dart';
import '../models/family_badge_model.dart';
import '../models/family_alliance_model.dart';
import '../models/family_history_model.dart';
import '../models/family_challenge_model.dart';
import '../models/family_branding_model.dart';
import '../models/family_vote_model.dart';
import '../models/family_daily_reward_model.dart';
import '../models/family_invitation_model.dart';
import '../models/hand_effect_model.dart';
import '../models/family_store_item_model.dart';

class LevelReward {
  final int stars;
  final int gems;
  final int level;

  LevelReward({required this.stars, required this.gems, required this.level});
}

class FamilyService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // --- مساعد للتحقق من الصلاحيات ---

  Future<bool> _hasPermission(
      String familyId, String userId, List<String> allowedRoles) async {
    final memberSnap = await _db
        .collection('families')
        .doc(familyId)
        .collection('members')
        .doc(userId)
        .get();
    String role = memberSnap.data()?['role'] ?? 'member';
    return allowedRoles.contains(role);
  }

  // --- نظام جوائز المستويات التلقائي ---

  Future<LevelReward?> claimPendingLevelRewards(String familyId) async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final userRef = _db.collection('users').doc(user.uid);
    final familyRef = _db.collection('families').doc(familyId);
    final memberRef = familyRef.collection('members').doc(user.uid);

    LevelReward? rewardResult;

    await _db.runTransaction((tx) async {
      final familySnap = await tx.get(familyRef);
      final memberSnap = await tx.get(memberRef);

      if (!familySnap.exists || !memberSnap.exists) return;

      int currentFamilyLevel = (familySnap.data()?['level'] ?? 1);
      int lastClaimedLevel = (memberSnap.data()?['lastClaimedLevel'] ?? 1);

      if (currentFamilyLevel > lastClaimedLevel) {
        int totalStarsReward = 0;
        int totalGemsReward = 0;

        for (int i = lastClaimedLevel + 1; i <= currentFamilyLevel; i++) {
          totalStarsReward += i * 100;
          if (i % 5 == 0) totalGemsReward += (i ~/ 5) * 10;
        }

        tx.update(userRef, {
          'stars': FieldValue.increment(totalStarsReward),
          'coins': FieldValue.increment(totalStarsReward), // Keep in sync
          'gems': FieldValue.increment(totalGemsReward),
        });

        tx.update(memberRef, {
          'lastClaimedLevel': currentFamilyLevel,
        });

        tx.set(
            memberRef
                .collection('reward_history')
                .doc('level_$currentFamilyLevel'),
            {
              'level': currentFamilyLevel,
              'stars': totalStarsReward,
              'coins': totalStarsReward,
              'gems': totalGemsReward,
              'claimedAt': FieldValue.serverTimestamp(),
            });

        rewardResult = LevelReward(
          stars: totalStarsReward,
          gems: totalGemsReward,
          level: currentFamilyLevel,
        );
      }
    });

    return rewardResult;
  }

  // --- نظام حروب العائلات (Family Wars) ---

  Future<void> startFamilyWar({
    required String challengerId,
    required String targetId,
    required int durationMinutes,
  }) async {
    final warRef = _db.collection('family_wars').doc();
    final startTime = DateTime.now();
    final endTime = startTime.add(Duration(minutes: durationMinutes));

    final challengerSnap =
        await _db.collection('families').doc(challengerId).get();
    final targetSnap = await _db.collection('families').doc(targetId).get();

    if (!challengerSnap.exists || !targetSnap.exists) {
      throw 'إحدى العائلات غير موجودة';
    }

    await warRef.set({
      'challengerId': challengerId,
      'challengerName': challengerSnap.data()?['name'],
      'challengerLogo': challengerSnap.data()?['logoUrl'],
      'challengerPoints': 0,
      'targetId': targetId,
      'targetName': targetSnap.data()?['name'],
      'targetLogo': targetSnap.data()?['logoUrl'],
      'targetPoints': 0,
      'status': 'active',
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _db
        .collection('families')
        .doc(challengerId)
        .update({'currentWarId': warRef.id});
    await _db
        .collection('families')
        .doc(targetId)
        .update({'currentWarId': warRef.id});
  }

  Future<void> addWarPoints(String warId, String familyId, int points) async {
    final warRef = _db.collection('family_wars').doc(warId);
    await _db.runTransaction((tx) async {
      final warSnap = await tx.get(warRef);
      if (!warSnap.exists || warSnap.data()?['status'] != 'active') return;
      String field = (warSnap.data()?['challengerId'] == familyId)
          ? 'challengerPoints'
          : 'targetPoints';
      tx.update(warRef, {field: FieldValue.increment(points)});
    });
  }

  Future<void> endFamilyWar(String warId) async {
    final warRef = _db.collection('family_wars').doc(warId);
    await _db.runTransaction((tx) async {
      final warSnap = await tx.get(warRef);
      if (!warSnap.exists || warSnap.data()?['status'] == 'completed') return;
      final data = warSnap.data()!;
      final int cPoints = data['challengerPoints'] ?? 0;
      final int tPoints = data['targetPoints'] ?? 0;
      final String cId = data['challengerId'];
      final String tId = data['targetId'];
      String? winnerId;
      if (cPoints > tPoints) {
        winnerId = cId;
      } else if (tPoints > cPoints) {
        winnerId = tId;
      }
      if (winnerId != null) {
        final String loserId = (winnerId == cId) ? tId : cId;
        tx.update(_db.collection('families').doc(winnerId), {
          'warWins': FieldValue.increment(1),
          'warExp': FieldValue.increment(100),
          'warPoints': FieldValue.increment(100), // Legacy
          'familyGems': FieldValue.increment(500),
          'currentWarId': null,
        });
        tx.update(_db.collection('families').doc(loserId), {
          'warLosses': FieldValue.increment(1),
          'currentWarId': null,
        });
      } else {
        tx.update(_db.collection('families').doc(cId), {'currentWarId': null});
        tx.update(_db.collection('families').doc(tId), {'currentWarId': null});
      }
      tx.update(warRef, {'status': 'completed', 'winnerId': winnerId});
    });
  }

  // --- دوال العائلة الأساسية ---

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
        'totalExp': 0,
        'totalPoints': 0,
        'dailyExp': 0,
        'dailyPoints': 0,
        'weeklyExp': 0,
        'weeklyPoints': 0,
        'monthlyExp': 0,
        'monthlyPoints': 0,
        'memberCount': 1,
        'maxMembers': 50,
        'level': 1,
        'minLevelToJoin': 1,
        'isVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'familyGems': 0,
        'familyStars': 0,
        'familyCoins': 0,
        'perks': {},
        'isPrivate': false,
        'warWins': 0,
        'warLosses': 0,
        'warExp': 0,
        'warPoints': 0,
      });
      tx.update(_db.collection('users').doc(user.uid),
          {'familyId': familyRef.id, 'familyRole': 'leader'});
      tx.set(familyRef.collection('members').doc(user.uid), {
        'uid': user.uid,
        'role': 'leader',
        'joinedAt': FieldValue.serverTimestamp(),
        'totalContribution': 0,
        'lastClaimedLevel': 1,
      });
    });
  }

  Future<void> joinFamily(String familyId) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول أولاً';
    final userRef = _db.collection('users').doc(user.uid);
    final familyRef = _db.collection('families').doc(familyId);
    await _db.runTransaction((tx) async {
      final userSnap = await tx.get(userRef);
      if (userSnap.data()?['familyId'] != null) throw 'أنت منضم لعائلة بالفعل';
      final familySnap = await tx.get(familyRef);
      if (familySnap.data()?['isPrivate'] == true) {
        throw 'هذه العائلة خاصة، يرجى إرسال طلب انضمام';
      }
      int currentMembers = (familySnap.data()?['memberCount'] ?? 0);
      int maxMembers = (familySnap.data()?['maxMembers'] ?? 50);
      if (currentMembers >= maxMembers) throw 'العائلة ممتلئة';
      tx.update(familyRef, {'memberCount': FieldValue.increment(1)});
      tx.update(userRef, {'familyId': familyId, 'familyRole': 'member'});
      tx.set(familyRef.collection('members').doc(user.uid), {
        'uid': user.uid,
        'role': 'member',
        'joinedAt': FieldValue.serverTimestamp(),
        'totalContribution': 0,
        'lastClaimedLevel': familySnap.data()?['level'] ?? 1,
      });
    });
  }

  Future<void> leaveFamily(String familyId) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول أولاً';
    final userRef = _db.collection('users').doc(user.uid);
    final familyRef = _db.collection('families').doc(familyId);

    await _db.runTransaction((tx) async {
      final familySnap = await tx.get(familyRef);
      if (!familySnap.exists) return;

      tx.update(familyRef, {'memberCount': FieldValue.increment(-1)});
      tx.update(userRef, {'familyId': null, 'familyRole': null});
      tx.delete(familyRef.collection('members').doc(user.uid));
    });
  }

  Future<void> removeMember(String familyId, String targetUserId) async {
    await _db.runTransaction((tx) async {
      tx.update(_db.collection('families').doc(familyId),
          {'memberCount': FieldValue.increment(-1)});
      tx.update(_db.collection('users').doc(targetUserId),
          {'familyId': null, 'familyRole': null});
      tx.delete(_db
          .collection('families')
          .doc(familyId)
          .collection('members')
          .doc(targetUserId));
    });
  }

  Future<void> sendJoinRequest(String familyId) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول أولاً';

    await _db
        .collection('families')
        .doc(familyId)
        .collection('requests')
        .doc(user.uid)
        .set({
      'uid': user.uid,
      'requestedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> donateToFamily(
      String familyId, int amount, String currency) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول أولاً';
    final userRef = _db.collection('users').doc(user.uid);
    final familyRef = _db.collection('families').doc(familyId);
    final memberRef = familyRef.collection('members').doc(user.uid);

    await _db.runTransaction((tx) async {
      final userSnap = await tx.get(userRef);
      int userBalance = (userSnap.data()?[currency] ?? 0);
      if (userBalance < amount) throw 'رصيدك غير كافٍ';

      tx.update(userRef, {
        currency: FieldValue.increment(-amount),
        if (currency == 'stars') 'coins': FieldValue.increment(-amount),
      });
      tx.update(familyRef, {
        currency == 'gems' ? 'familyGems' : 'familyStars':
            FieldValue.increment(amount),
        if (currency == 'stars') 'familyCoins': FieldValue.increment(amount),
        'totalExp': FieldValue.increment(amount ~/ 10),
        'totalPoints': FieldValue.increment(amount ~/ 10), // Legacy sync
      });
      tx.update(memberRef, {'totalContribution': FieldValue.increment(amount)});
    });
  }

  Future<void> buyFamilyPerk(
      String familyId, String perkId, int cost, String currency) async {
    final familyRef = _db.collection('families').doc(familyId);

    await _db.runTransaction((tx) async {
      final familySnap = await tx.get(familyRef);
      if (!familySnap.exists) throw 'العائلة غير موجودة';

      int currentBalance = (familySnap
              .data()?[currency == 'gems' ? 'familyGems' : 'familyStars'] ??
          0);
      if (currentBalance < cost) throw 'رصيد الخزينة غير كافٍ';

      Map<String, dynamic> perks =
          Map<String, dynamic>.from(familySnap.data()?['perks'] ?? {});
      if (perks.containsKey(perkId)) throw 'هذه الميزة مفعلة بالفعل';

      perks[perkId] = true;

      tx.update(familyRef, {
        currency == 'gems' ? 'familyGems' : 'familyStars':
            FieldValue.increment(-cost),
        if (currency != 'gems') 'familyCoins': FieldValue.increment(-cost),
        'perks': perks,
      });
    });
  }

  Future<void> addFamilyPoints(
      String familyId, String userId, int points) async {
    final familyRef = _db.collection('families').doc(familyId);
    final memberRef = familyRef.collection('members').doc(userId);

    await _db.runTransaction((tx) async {
      final familySnap = await tx.get(familyRef);
      if (!familySnap.exists) return;

      int currentTotalExp = (familySnap.data()?['totalExp'] ??
          familySnap.data()?['totalPoints'] ??
          0);
      int newTotalExp = currentTotalExp + points;
      int currentLevel = (familySnap.data()?['level'] ?? 1);
      int nextLevelPoints = currentLevel * currentLevel * 10000;

      Map<String, dynamic> updates = {
        'totalExp': newTotalExp,
        'totalPoints': newTotalExp, // Legacy sync
      };

      if (newTotalExp >= nextLevelPoints) {
        currentLevel++;
        updates['level'] = currentLevel;
        updates['maxMembers'] = FamilyModel.calculateMaxMembers(currentLevel);
      }

      tx.update(familyRef, updates);
      tx.update(memberRef, {'totalContribution': FieldValue.increment(points)});
    });
  }

  Future<void> completeFamilyTask(
      String familyId, String userId, String taskId) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final taskRef = _db.collection('family_tasks_config').doc(taskId);
    final familyRef = _db.collection('families').doc(familyId);
    final memberRef = familyRef.collection('members').doc(userId);
    final taskLogRef =
        memberRef.collection('task_logs').doc('${taskId}_$today');

    await _db.runTransaction((tx) async {
      final logSnap = await tx.get(taskLogRef);
      if (logSnap.exists) throw 'لقد أتممت هذه المهمة اليوم بالفعل';

      final taskSnap = await tx.get(taskRef);
      if (!taskSnap.exists) throw 'المهمة غير موجودة';

      final familySnap = await tx.get(familyRef);
      if (!familySnap.exists) throw 'العائلة غير موجودة';

      final int xp = (taskSnap.data()?['xp'] ?? 0).toInt();
      final int stars =
          (taskSnap.data()?['stars'] ?? taskSnap.data()?['coins'] ?? 0).toInt();
      final int gems = (taskSnap.data()?['gems'] ?? 0).toInt();

      int currentTotalExp = (familySnap.data()?['totalExp'] ??
          familySnap.data()?['totalPoints'] ??
          0);
      int newTotalExp = currentTotalExp + xp;
      int currentLevel = (familySnap.data()?['level'] ?? 1);
      int nextLevelPoints = currentLevel * currentLevel * 10000;

      Map<String, dynamic> updates = {
        'familyGems': FieldValue.increment(gems),
        'familyStars': FieldValue.increment(stars),
        'familyCoins': FieldValue.increment(stars),
        'totalExp': newTotalExp,
        'totalPoints': newTotalExp,
        'dailyExp': FieldValue.increment(xp),
        'dailyPoints': FieldValue.increment(xp),
      };

      if (newTotalExp >= nextLevelPoints) {
        currentLevel++;
        updates['level'] = currentLevel;
        updates['maxMembers'] = FamilyModel.calculateMaxMembers(currentLevel);
      }

      tx.update(familyRef, updates);
      tx.update(memberRef, {'totalContribution': FieldValue.increment(xp)});
      tx.set(taskLogRef,
          {'taskId': taskId, 'completedAt': FieldValue.serverTimestamp()});
    });
  }

  Future<void> updateFamily(
      {required String familyId,
      String? name,
      String? description,
      String? slogan,
      String? logoUrl,
      int? minLevelToJoin,
      String? activeBadgeId,
      bool? isPrivate}) async {
    Map<String, dynamic> updates = {};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (slogan != null) updates['slogan'] = slogan;
    if (logoUrl != null) updates['logoUrl'] = logoUrl;
    if (isPrivate != null) updates['isPrivate'] = isPrivate;
    await _db.collection('families').doc(familyId).update(updates);
  }

  Future<void> acceptJoinRequest(String familyId, String targetUserId) async {
    final familySnap = await _db.collection('families').doc(familyId).get();
    if (!familySnap.exists) return;
    int currentLevel = (familySnap.data()?['level'] ?? 1);

    await _db.runTransaction((tx) async {
      tx.update(_db.collection('families').doc(familyId),
          {'memberCount': FieldValue.increment(1)});
      tx.update(_db.collection('users').doc(targetUserId),
          {'familyId': familyId, 'familyRole': 'member'});
      tx.set(
          _db
              .collection('families')
              .doc(familyId)
              .collection('members')
              .doc(targetUserId),
          {
            'uid': targetUserId,
            'role': 'member',
            'joinedAt': FieldValue.serverTimestamp(),
            'totalContribution': 0,
            'lastClaimedLevel': currentLevel,
          });
      tx.delete(_db
          .collection('families')
          .doc(familyId)
          .collection('requests')
          .doc(targetUserId));
    });
  }

  Future<void> rejectJoinRequest(String familyId, String targetUserId) async {
    await _db
        .collection('families')
        .doc(familyId)
        .collection('requests')
        .doc(targetUserId)
        .delete();
  }

  Future<void> deleteFamily(String familyId) async {
    final membersSnap = await _db
        .collection('families')
        .doc(familyId)
        .collection('members')
        .get();
    final batch = _db.batch();
    for (var doc in membersSnap.docs) {
      batch.update(_db.collection('users').doc(doc.id),
          {'familyId': null, 'familyRole': null});
      batch.delete(doc.reference);
    }
    batch.delete(_db.collection('families').doc(familyId));
    await batch.commit();
  }

  Future<void> updateMemberRole(
      String familyId, String targetUserId, String newRole) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول';
    if (!await _hasPermission(familyId, user.uid, ['leader', 'co-leader'])) {
      throw 'ليس لديك صلاحية';
    }
    await _db.runTransaction((tx) async {
      tx.update(
          _db
              .collection('families')
              .doc(familyId)
              .collection('members')
              .doc(targetUserId),
          {'role': newRole});
      tx.update(
          _db.collection('users').doc(targetUserId), {'familyRole': newRole});
    });
  }

  Future<void> addMemberByShortId(String familyId, String shortId) async {
    final userQuery = await _db
        .collection('users')
        .where('shortId', isEqualTo: shortId)
        .limit(1)
        .get();
    if (userQuery.docs.isEmpty) throw 'المستخدم غير موجود';
    await acceptJoinRequest(familyId, userQuery.docs.first.id);
  }

  Stream<List<FamilyModel>> searchFamilies(String query) {
    return _db
        .collection('families')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: '$query\uf8ff')
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => FamilyModel.fromFirestore(doc)).toList());
  }

  Stream<List<FamilyModel>> getLeaderboard(String type) {
    String field = type == 'daily'
        ? 'dailyExp'
        : (type == 'weekly' ? 'weeklyExp' : 'totalExp');
    return _db
        .collection('families')
        .orderBy(field, descending: true)
        .limit(50)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => FamilyModel.fromFirestore(doc)).toList());
  }

  // --- نظام الإشعارات الداخلية ---

  Future<void> sendFamilyNotification(
      String familyId, String title, String message, String type,
      {Map<String, dynamic>? data}) async {
    await _db.collection('family_notifications').add({
      'familyId': familyId,
      'title': title,
      'message': message,
      'type': type,
      'data': data,
      'createdAt': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _db
        .collection('family_notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> deleteNotification(String notificationId) async {
    await _db.collection('family_notifications').doc(notificationId).delete();
  }

  Stream<List<FamilyNotificationModel>> streamFamilyNotifications(
      String familyId) {
    return _db
        .collection('family_notifications')
        .where('familyId', isEqualTo: familyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => FamilyNotificationModel.fromFirestore(doc))
            .toList());
  }

  // --- نظام الرتب والتصنيف ---

  Future<void> updateMemberRanks(String familyId) async {
    final membersSnap = await _db
        .collection('families')
        .doc(familyId)
        .collection('members')
        .get();
    Map<String, int> contributions = {};
    for (var doc in membersSnap.docs) {
      contributions[doc.id] = (doc.data()['totalContribution'] ?? 0).toInt();
    }
    List<MapEntry<String, int>> sorted = contributions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    Map<String, String> ranks = {};
    for (int i = 0; i < sorted.length; i++) {
      String rank = i == 0
          ? 'Champion'
          : i < 3
              ? 'Elite'
              : i < 10
                  ? 'Warrior'
                  : 'Member';
      ranks[sorted[i].key] = rank;
    }
    await _db
        .collection('families')
        .doc(familyId)
        .update({'memberRanks': ranks});
  }

  // --- تطوير نظام المهام ---

  Future<void> generateRandomFamilyTask(String familyId, String type) async {
    // type: 'daily', 'weekly', 'monthly'
    List<String> tasks = [
      'شارك في غرفة لمدة 30 دقيقة',
      'أرسل 10 رسائل في الغرفة',
      'ادع صديقاً للانضمام',
      'تبرع 100 نقطة للعائلة',
      'اكمل مهمة يومية أخرى'
    ];
    String randomTask =
        tasks[DateTime.now().millisecondsSinceEpoch % tasks.length];
    int xp = type == 'daily'
        ? 50
        : type == 'weekly'
            ? 200
            : 500;
    int stars = type == 'daily'
        ? 10
        : type == 'weekly'
            ? 50
            : 100;
    int gems = type == 'monthly' ? 5 : 0;
    await _db.collection('family_tasks_config').add({
      'title': randomTask,
      'description': 'مهمة عشوائية للعائلة',
      'xp': xp,
      'stars': stars,
      'coins': stars,
      'gems': gems,
      'type': type,
      'familyId': familyId,
      'createdAt': FieldValue.serverTimestamp(),
      'isLimited': true,
      'expiryDate': type == 'daily'
          ? Timestamp.fromDate(DateTime.now().add(const Duration(days: 1)))
          : type == 'weekly'
              ? Timestamp.fromDate(DateTime.now().add(const Duration(days: 7)))
              : Timestamp.fromDate(
                  DateTime.now().add(const Duration(days: 30))),
    });
  }

  // --- تتبع النشاط اليومي ---

  Future<void> updateDailyActivity(
      String familyId, String userId, int minutes) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final activityRef = _db
        .collection('families')
        .doc(familyId)
        .collection('members')
        .doc(userId)
        .collection('daily_activity')
        .doc(today);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(activityRef);
      int currentMinutes = (snap.data()?['minutes'] ?? 0).toInt();
      tx.set(activityRef, {'minutes': currentMinutes + minutes, 'date': today},
          SetOptions(merge: true));
    });
  }

  Future<int> getDailyActivity(String familyId, String userId) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final snap = await _db
        .collection('families')
        .doc(familyId)
        .collection('members')
        .doc(userId)
        .collection('daily_activity')
        .doc(today)
        .get();
    return (snap.data()?['minutes'] ?? 0).toInt();
  }

  // --- تحسين الاقتصاد الداخلي ---

  Future<void> tradeResources(String familyId, String fromUserId,
      String toUserId, int amount, String currency) async {
    final fromRef = _db.collection('users').doc(fromUserId);
    final toRef = _db.collection('users').doc(toUserId);
    await _db.runTransaction((tx) async {
      final fromSnap = await tx.get(fromRef);
      int fromBalance = (fromSnap.data()?[currency] ?? 0).toInt();
      if (fromBalance < amount) throw 'رصيدك غير كافٍ';
      tx.update(fromRef, {
        currency: FieldValue.increment(-amount),
        if (currency == 'stars') 'coins': FieldValue.increment(-amount),
      });
      tx.update(toRef, {
        currency: FieldValue.increment(amount),
        if (currency == 'stars') 'coins': FieldValue.increment(amount),
      });
    });
  }

  Future<void> investInFamilyBuilding(
      String familyId, String userId, int cost, String currency) async {
    final userRef = _db.collection('users').doc(userId);
    final familyRef = _db.collection('families').doc(familyId);
    await _db.runTransaction((tx) async {
      final userSnap = await tx.get(userRef);
      int balance = (userSnap.data()?[currency] ?? 0).toInt();
      if (balance < cost) throw 'رصيدك غير كافٍ';
      tx.update(userRef, {
        currency: FieldValue.increment(-cost),
        if (currency == 'stars') 'coins': FieldValue.increment(-cost),
      });
      tx.update(familyRef, {
        'familyStars': FieldValue.increment(cost * 2),
        'familyCoins': FieldValue.increment(cost * 2),
        'totalExp': FieldValue.increment(cost),
        'totalPoints': FieldValue.increment(cost), // Legacy sync
      });
    });
  }

  // --- نظام الأحداث ---

  Future<void> createFamilyEvent(
      String familyId,
      String title,
      String description,
      DateTime startTime,
      DateTime endTime,
      Map<String, dynamic> rewards) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول';
    if (!await _hasPermission(familyId, user.uid, ['leader', 'co-leader'])) {
      throw 'ليس لديك صلاحية';
    }
    await _db.collection('family_events').add({
      'familyId': familyId,
      'title': title,
      'description': description,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'rewards': rewards,
      'participants': [],
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> joinFamilyEvent(String eventId) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول';
    await _db.collection('family_events').doc(eventId).update({
      'participants': FieldValue.arrayUnion([user.uid]),
    });
  }

  Stream<List<FamilyEventModel>> streamFamilyEvents(String familyId) {
    return _db
        .collection('family_events')
        .where('familyId', isEqualTo: familyId)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => FamilyEventModel.fromFirestore(doc))
            .toList());
  }

  // --- دوال إضافية للتعديل ---

  Future<void> setFamilyRoom(String familyId, String roomId) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول';
    if (!await _hasPermission(familyId, user.uid, ['leader'])) {
      throw 'ليس لديك صلاحية';
    }
    await _db.collection('families').doc(familyId).update({'roomId': roomId});
  }

  Future<void> updateFamilyLogo(String familyId, String logoUrl) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول';
    if (!await _hasPermission(
        familyId, user.uid, ['leader', 'co-leader', 'organizer'])) {
      throw 'ليس لديك صلاحية';
    }
    await _db.collection('families').doc(familyId).update({'logoUrl': logoUrl});
  }

  Future<void> updateFamilySlogan(String familyId, String slogan) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول';
    if (!await _hasPermission(
        familyId, user.uid, ['leader', 'co-leader', 'organizer'])) {
      throw 'ليس لديك صلاحية';
    }
    await _db.collection('families').doc(familyId).update({'slogan': slogan});
  }

  Future<void> updateFamilyDescription(
      String familyId, String description) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول';
    if (!await _hasPermission(
        familyId, user.uid, ['leader', 'co-leader', 'organizer'])) {
      throw 'ليس لديك صلاحية';
    }
    await _db
        .collection('families')
        .doc(familyId)
        .update({'description': description});
  }

  // --- نظام الشارات والأوسمة العائلية ---

  Future<void> createFamilyBadge({
    required String name,
    required String description,
    required String imageUrl,
    required String type,
    int cost = 0,
    int minContribution = 0,
    String? warId,
  }) async {
    await _db.collection('family_badges').add({
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'type': type,
      'cost': cost,
      'minContribution': minContribution,
      'warId': warId,
      'createdAt': FieldValue.serverTimestamp(),
      'isActive': true,
    });
  }

  Future<void> purchaseFamilyBadge(String familyId, String badgeId) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول';

    final badgeRef = _db.collection('family_badges').doc(badgeId);
    final familyRef = _db.collection('families').doc(familyId);

    await _db.runTransaction((tx) async {
      final badgeSnap = await tx.get(badgeRef);
      final familySnap = await tx.get(familyRef);

      if (!badgeSnap.exists) throw 'الشارة غير موجودة';
      if (!familySnap.exists) throw 'العائلة غير موجودة';

      final cost = badgeSnap.data()?['cost'] ?? 0;
      final currentGems = familySnap.data()?['familyGems'] ?? 0;

      if (currentGems < cost) throw 'رصيد خزينة العائلة غير كافٍ';

      tx.update(familyRef, {'familyGems': FieldValue.increment(-cost)});
      tx.set(familyRef.collection('badges').doc(badgeId), {
        'badgeId': badgeId,
        'purchasedAt': FieldValue.serverTimestamp(),
        'purchasedBy': user.uid,
      });
    });
  }

  Future<void> awardWarBadge(String familyId, String badgeId) async {
    final familyRef = _db.collection('families').doc(familyId);
    await familyRef.collection('badges').doc(badgeId).set({
      'badgeId': badgeId,
      'awardedAt': FieldValue.serverTimestamp(),
      'type': 'war_reward',
    });
  }

  Future<void> awardContributorBadge(
      String familyId, String userId, String badgeId) async {
    final familyRef = _db.collection('families').doc(familyId);
    await familyRef
        .collection('members')
        .doc(userId)
        .collection('badges')
        .doc(badgeId)
        .set({
      'badgeId': badgeId,
      'awardedAt': FieldValue.serverTimestamp(),
      'type': 'contributor',
    });
  }

  // --- نظام التحالفات بين العائلات ---

  Future<void> proposeAlliance({
    required String familyId1,
    required String familyId2,
    required String name,
    required String description,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول';

    final family1Snap = await _db.collection('families').doc(familyId1).get();
    final family2Snap = await _db.collection('families').doc(familyId2).get();

    if (!family1Snap.exists || !family2Snap.exists)
      throw 'إحدى العائلات غير موجودة';

    await _db.collection('family_alliances').add({
      'name': name,
      'description': description,
      'familyId1': familyId1,
      'familyId2': familyId2,
      'familyName1': family1Snap.data()?['name'],
      'familyName2': family2Snap.data()?['name'],
      'familyLogo1': family1Snap.data()?['logoUrl'],
      'familyLogo2': family2Snap.data()?['logoUrl'],
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptAlliance(String allianceId) async {
    await _db.collection('family_alliances').doc(allianceId).update({
      'status': 'active',
    });
  }

  Future<void> dissolveAlliance(String allianceId) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول';

    await _db.collection('family_alliances').doc(allianceId).update({
      'status': 'dissolved',
      'dissolvedAt': FieldValue.serverTimestamp(),
      'dissolvedBy': user.uid,
    });
  }

  Future<void> shareAllianceResources(
      String allianceId, int amount, String currency) async {
    final allianceSnap =
        await _db.collection('family_alliances').doc(allianceId).get();
    if (!allianceSnap.exists) throw 'التحالف غير موجود';

    final familyId1 = allianceSnap.data()?['familyId1'];
    final familyId2 = allianceSnap.data()?['familyId2'];

    await _db.runTransaction((tx) async {
      final family1Ref = _db.collection('families').doc(familyId1);
      final family2Ref = _db.collection('families').doc(familyId2);

      final family1Snap = await tx.get(family1Ref);
      final currentBalance = family1Snap
              .data()?[currency == 'gems' ? 'familyGems' : 'familyStars'] ??
          0;

      if (currentBalance < amount) throw 'رصيد غير كافٍ';

      tx.update(family1Ref, {
        currency == 'gems' ? 'familyGems' : 'familyStars':
            FieldValue.increment(-amount),
      });
      tx.update(family2Ref, {
        currency == 'gems' ? 'familyGems' : 'familyStars':
            FieldValue.increment(amount),
      });
    });
  }

  // --- نظام السجل التاريخي للعائلة ---

  Future<void> addFamilyHistory({
    required String familyId,
    required String type,
    required String title,
    required String description,
    Map<String, dynamic>? data,
    String? userId,
    String? userName,
  }) async {
    await _db.collection('family_history').add({
      'familyId': familyId,
      'type': type,
      'title': title,
      'description': description,
      'data': data,
      'userId': userId,
      'userName': userName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<FamilyHistoryModel>> getFamilyHistory(String familyId) {
    return _db
        .collection('family_history')
        .where('familyId', isEqualTo: familyId)
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => FamilyHistoryModel.fromFirestore(doc))
            .toList());
  }

  // --- نظام التحديات الداخلية ---

  Future<void> createFamilyChallenge({
    required String familyId,
    required String title,
    required String description,
    required String type,
    required int targetValue,
    required String metric,
    required Timestamp startDate,
    required Timestamp endDate,
    int rewardGems = 0,
    int rewardStars = 0,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول';

    await _db.collection('family_challenges').add({
      'familyId': familyId,
      'title': title,
      'description': description,
      'type': type,
      'targetValue': targetValue,
      'metric': metric,
      'startDate': startDate,
      'endDate': endDate,
      'createdBy': user.uid,
      'rewardGems': rewardGems,
      'rewardStars': rewardStars,
      'status': 'active',
    });
  }

  Future<void> completeFamilyChallenge(
      String challengeId, String userId) async {
    final challengeRef = _db.collection('family_challenges').doc(challengeId);
    final userRef = _db.collection('users').doc(userId);

    await _db.runTransaction((tx) async {
      final challengeSnap = await tx.get(challengeRef);
      if (!challengeSnap.exists) throw 'التحدي غير موجود';

      final rewardGems = challengeSnap.data()?['rewardGems'] ?? 0;
      final rewardStars = challengeSnap.data()?['rewardStars'] ?? 0;

      tx.update(userRef, {
        'gems': FieldValue.increment(rewardGems),
        'stars': FieldValue.increment(rewardStars),
        'coins': FieldValue.increment(rewardStars),
      });

      tx.update(challengeRef, {
        'winnerId': userId,
        'status': 'completed',
      });
    });
  }

  // --- نظام العلامات التجارية (Branding) ---

  Future<void> purchaseFamilyBackground(
      String familyId, String backgroundUrl) async {
    final familyRef = _db.collection('families').doc(familyId);

    await _db.runTransaction((tx) async {
      final familySnap = await tx.get(familyRef);
      if (!familySnap.exists) throw 'العائلة غير موجودة';

      final currentGems = familySnap.data()?['familyGems'] ?? 0;
      if (currentGems < 1000) throw 'رصيد خزينة العائلة غير كافٍ';

      tx.update(familyRef, {
        'familyGems': FieldValue.increment(-1000),
        'backgroundUrl': backgroundUrl,
        'hasCustomBackground': true,
        'backgroundPurchasedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> purchaseFamilyMusic(String familyId, String musicUrl) async {
    final familyRef = _db.collection('families').doc(familyId);

    await _db.runTransaction((tx) async {
      final familySnap = await tx.get(familyRef);
      if (!familySnap.exists) throw 'العائلة غير موجودة';

      final currentGems = familySnap.data()?['familyGems'] ?? 0;
      if (currentGems < 5000) throw 'رصيد خزينة العائلة غير كافٍ';

      tx.update(familyRef, {
        'familyGems': FieldValue.increment(-5000),
        'musicUrl': musicUrl,
        'hasCustomMusic': true,
        'musicPurchasedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> updateFamilyColors(
      String familyId, String primaryColor, String secondaryColor) async {
    await _db.collection('families').doc(familyId).update({
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
    });
  }

  // --- نظام الديمقراطية ---

  Future<void> createVote({
    required String familyId,
    required String type,
    required String title,
    required String description,
    Map<String, dynamic>? data,
    required Timestamp deadline,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول';

    final familySnap = await _db.collection('families').doc(familyId).get();
    final memberCount = familySnap.data()?['memberCount'] ?? 0;
    final requiredVotes = (memberCount * 0.5).ceil();

    await _db.collection('family_votes').add({
      'familyId': familyId,
      'type': type,
      'title': title,
      'description': description,
      'data': data,
      'proposedBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'deadline': deadline,
      'votes': {},
      'status': 'active',
      'requiredVotes': requiredVotes,
    });
  }

  Future<void> castVote(String voteId, String vote) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول';

    await _db.collection('family_votes').doc(voteId).update({
      'votes.${user.uid}': vote,
    });
  }

  // --- نظام المكافآت اليومية ---

  Future<void> claimDailyLoginReward(String familyId) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول';

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final rewardRef = _db
        .collection('families')
        .doc(familyId)
        .collection('daily_rewards')
        .doc('${user.uid}_$today');

    final rewardSnap = await rewardRef.get();
    if (rewardSnap.exists) throw 'لقد استلمت مكافأة اليوم بالفعل';

    await _db.runTransaction((tx) async {
      final userRef = _db.collection('users').doc(user.uid);

      tx.update(userRef, {
        'gems': FieldValue.increment(1),
        'stars': FieldValue.increment(2),
        'coins': FieldValue.increment(2),
      });

      tx.set(rewardRef, {
        'userId': user.uid,
        'date': Timestamp.now(),
        'gemsReward': 1,
        'coinsReward': 2,
        'isLoginReward': true,
        'claimedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> claimActivityReward(String familyId, int activityMinutes) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول';

    if (activityMinutes < 30) throw 'يجب أن يكون النشاط 30 دقيقة على الأقل';

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final rewardRef = _db
        .collection('families')
        .doc(familyId)
        .collection('daily_rewards')
        .doc('${user.uid}_activity_$today');

    final rewardSnap = await rewardRef.get();
    if (rewardSnap.exists) throw 'لقد استلمت مكافأة النشاط اليوم بالفعل';

    await _db.runTransaction((tx) async {
      final userRef = _db.collection('users').doc(user.uid);

      tx.update(userRef, {
        'gems': FieldValue.increment(1),
        'stars': FieldValue.increment(2),
        'coins': FieldValue.increment(2),
      });

      tx.set(rewardRef, {
        'userId': user.uid,
        'date': Timestamp.now(),
        'gemsReward': 1,
        'coinsReward': 2,
        'isActivityReward': true,
        'activityMinutes': activityMinutes,
        'claimedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // --- نظام الدعوات المخصصة ---

  Future<String> createFamilyInvitation(String familyId) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول';

    final familySnap = await _db.collection('families').doc(familyId).get();
    final userSnap = await _db.collection('users').doc(user.uid).get();

    final inviteCode =
        '${familyId.substring(0, 6)}_${DateTime.now().millisecondsSinceEpoch}';

    final docRef = await _db.collection('family_invitations').add({
      'familyId': familyId,
      'familyName': familySnap.data()?['name'],
      'familyLogo': familySnap.data()?['logoUrl'],
      'familyDescription': familySnap.data()?['description'],
      'inviterId': user.uid,
      'inviterName': userSnap.data()?['name'] ?? userSnap.data()?['shortId'],
      'inviteCode': inviteCode,
      'createdAt': FieldValue.serverTimestamp(),
      'totalInvites': 0,
      'acceptedInvites': 0,
      'rewardPerInvite': 2,
      'isActive': true,
    });

    return docRef.id;
  }

  Future<void> acceptFamilyInvitation(String invitationId) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول';

    final inviteSnap =
        await _db.collection('family_invitations').doc(invitationId).get();
    if (!inviteSnap.exists) throw 'الدعوة غير موجودة';

    final familyId = inviteSnap.data()?['familyId'];
    final inviterId = inviteSnap.data()?['inviterId'];

    await _db.runTransaction((tx) async {
      await joinFamily(familyId);

      tx.update(_db.collection('family_invitations').doc(invitationId), {
        'totalInvites': FieldValue.increment(1),
        'acceptedInvites': FieldValue.increment(1),
      });

      tx.update(_db.collection('users').doc(inviterId), {
        'gems': FieldValue.increment(2),
      });
    });
  }

  // --- نظام المتجر المتقدم ---

  Future<void> createFamilyStoreItem({
    required String name,
    required String description,
    required String imageUrl,
    required int cost,
    required String currency,
    required String type,
    String? effectId,
    int? durationDays,
  }) async {
    await _db.collection('family_store_items').add({
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'cost': cost,
      'currency': currency,
      'type': type,
      'effectId': effectId,
      'durationDays': durationDays,
      'isActive': true,
      'purchaseCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> purchaseFamilyStoreItem(String familyId, String itemId) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول';

    final itemRef = _db.collection('family_store_items').doc(itemId);
    final familyRef = _db.collection('families').doc(familyId);

    await _db.runTransaction((tx) async {
      final itemSnap = await tx.get(itemRef);
      final familySnap = await tx.get(familyRef);

      if (!itemSnap.exists) throw 'العنصر غير موجود';
      if (!familySnap.exists) throw 'العائلة غير موجودة';

      final cost = itemSnap.data()?['cost'] ?? 0;
      final currency = itemSnap.data()?['currency'] ?? 'family_gems';
      final currentBalance = familySnap.data()?[currency] ?? 0;

      if (currentBalance < cost) throw 'رصيد خزينة العائلة غير كافٍ';

      tx.update(familyRef, {
        currency: FieldValue.increment(-cost),
      });

      tx.update(itemRef, {
        'purchaseCount': FieldValue.increment(1),
      });

      tx.set(familyRef.collection('purchased_items').doc(itemId), {
        'itemId': itemId,
        'purchasedAt': FieldValue.serverTimestamp(),
        'purchasedBy': user.uid,
      });
    });
  }

  // --- نظام تأثيرات الإيدات ---

  Future<void> createHandEffect({
    required String name,
    required String description,
    required String imageUrl,
    required String animationUrl,
    required int cost,
    required String currency,
    required String type,
    String? familyId,
  }) async {
    await _db.collection('hand_effects').add({
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'animationUrl': animationUrl,
      'cost': cost,
      'currency': currency,
      'type': type,
      'familyId': familyId,
      'isActive': true,
      'purchaseCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> purchaseHandEffect(String effectId) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول';

    final effectRef = _db.collection('hand_effects').doc(effectId);
    final userRef = _db.collection('users').doc(user.uid);

    await _db.runTransaction((tx) async {
      final effectSnap = await tx.get(effectRef);
      final userSnap = await tx.get(userRef);

      if (!effectSnap.exists) throw 'التأثير غير موجود';

      final cost = effectSnap.data()?['cost'] ?? 0;
      final currency = effectSnap.data()?['currency'] ?? 'gems';
      final currentBalance = userSnap.data()?[currency] ?? 0;

      if (currentBalance < cost) throw 'رصيدك غير كافٍ';

      tx.update(userRef, {
        currency: FieldValue.increment(-cost),
      });

      tx.update(effectRef, {
        'purchaseCount': FieldValue.increment(1),
      });

      tx.set(userRef.collection('hand_effects').doc(effectId), {
        'effectId': effectId,
        'purchasedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}
