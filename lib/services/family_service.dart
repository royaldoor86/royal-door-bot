import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/family_model.dart';
import '../models/family_notification_model.dart';
import '../models/family_event_model.dart';
import '../models/family_history_model.dart';
import '../models/family_war_model.dart';
import '../models/member_rank_model.dart';
import '../models/alliance_model.dart';
import '../models/war_leaderboard_model.dart';
import '../models/war_challenge_model.dart';
import '../models/rank_competition_model.dart';
import '../models/alliance_contract_model.dart';
import '../models/alliance_war_model.dart';
import '../models/collaborative_task_model.dart';
import '../models/recurring_task_model.dart';
import '../models/recommendation_model.dart';
import '../models/progressive_reward_model.dart';
import '../models/family_customization_model.dart';
import '../models/enhanced_chat_model.dart';
import '../models/mini_game_model.dart';

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

  // --- نظام حروب العائلات (Family Wars) المحسّن ---

  Future<String> startFamilyWar({
    required String challengerId,
    required String targetId,
    required int durationMinutes,
    String warType = 'normal',
    Map<String, dynamic>? customRewards,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول أولاً';

    final warRef = _db.collection('family_wars').doc();
    final startTime = DateTime.now();
    final endTime = startTime.add(Duration(minutes: durationMinutes));

    final challengerSnap =
        await _db.collection('families').doc(challengerId).get();
    final targetSnap = await _db.collection('families').doc(targetId).get();

    if (!challengerSnap.exists || !targetSnap.exists) {
      throw 'إحدى العائلات غير موجودة';
    }

    // التحقق من أن العائلات ليست في حرب حالية
    if (challengerSnap.data()?['currentWarId'] != null) {
      throw 'عائلتك في حرب حالية';
    }
    if (targetSnap.data()?['currentWarId'] != null) {
      throw 'العائلة المستهدفة في حرب حالية';
    }

    // حساب المكافآت الافتراضية بناءً على نوع الحرب
    Map<String, dynamic> rewards = customRewards ?? {};
    if (rewards.isEmpty) {
      rewards = FamilyWarModel.getDefaultRewards(warType);
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
      'warType': warType,
      'durationMinutes': durationMinutes,
      'rewards': rewards,
      'participants': [],
      'contributionPoints': {},
      'createdBy': user.uid,
    });

    await _db
        .collection('families')
        .doc(challengerId)
        .update({'currentWarId': warRef.id});
    await _db
        .collection('families')
        .doc(targetId)
        .update({'currentWarId': warRef.id});

    // إضافة سجل للعائلة
    await addFamilyHistory(
      familyId: challengerId,
      type: 'war_started',
      title: 'بدء حرب عائلية',
      description: 'بدأت عائلتك حرباً ضد ${targetSnap.data()?['name']}',
      data: {'warId': warRef.id, 'targetFamily': targetSnap.data()?['name']},
      userId: user.uid,
    );

    await addFamilyHistory(
      familyId: targetId,
      type: 'war_declared',
      title: 'إعلان حرب',
      description: 'أعلنت عائلة ${challengerSnap.data()?['name']} الحرب عليكم',
      data: {
        'warId': warRef.id,
        'challengerFamily': challengerSnap.data()?['name']
      },
    );

    return warRef.id;
  }

  Future<void> addWarPoints(String warId, String familyId, int amount,
      {String? userId, String currency = 'coins'}) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول أولاً';

    // حساب نقاط الحرب بناءً على نوع العملة
    // 5 كوينز = 1 نقطة حرب (الكوينز ضعيفة)
    // 1 جوهرة = 1 نقطة حرب (الجواهر قوية)
    final warPoints = currency == 'gems' ? amount : (amount / 5).floor();

    final warRef = _db.collection('family_wars').doc(warId);
    final userRef = _db.collection('users').doc(user.uid);

    await _db.runTransaction((tx) async {
      final warSnap = await tx.get(warRef);
      if (!warSnap.exists || warSnap.data()?['status'] != 'active') {
        throw 'الحرب غير موجودة أو منتهية';
      }

      // التحقق من رصيد المستخدم وخصم العملة
      final userSnap = await tx.get(userRef);
      if (!userSnap.exists) throw 'المستخدم غير موجود';

      final currencyField = currency == 'gems' ? 'gems' : 'coins';
      final userBalance = (userSnap.data()?[currencyField] ?? 0).toInt();

      if (userBalance < amount) {
        throw 'رصيدك غير كافٍ (${currency == 'gems' ? 'جواهر' : 'كوينز'})';
      }

      // خصم من رصيد المستخدم
      tx.update(userRef, {
        currencyField: FieldValue.increment(-amount),
        if (currency == 'coins')
          'stars': FieldValue.increment(-amount), // Keep sync
      });

      String field = (warSnap.data()?['challengerId'] == familyId)
          ? 'challengerPoints'
          : 'targetPoints';

      tx.update(warRef, {field: FieldValue.increment(warPoints)});

      // إضافة نقاط المساهمة للمستخدم
      if (userId != null) {
        Map<String, dynamic> currentContributions = Map<String, dynamic>.from(
            warSnap.data()?['contributionPoints'] ?? {});
        currentContributions[userId] =
            (currentContributions[userId] ?? 0) + warPoints;
        tx.update(warRef, {'contributionPoints': currentContributions});

        // تحديث نقاط المساهمة في العائلة وتحديث الرتبة تلقائياً
        final memberRef = _db
            .collection('families')
            .doc(familyId)
            .collection('members')
            .doc(userId);
        final memberSnap = await tx.get(memberRef);
        if (memberSnap.exists) {
          final currentPoints = memberSnap.data()?['contributionPoints'] ?? 0;
          final newPoints = currentPoints + warPoints;

          tx.update(memberRef, {
            'contributionPoints': newPoints,
            'lastContributionAt': FieldValue.serverTimestamp(),
          });

          // تحديث الرتبة تلقائياً
          final newRank = MemberRankModel.getRankForPoints(newPoints);
          final currentRankId = memberSnap.data()?['rankId'] ?? 'bronze';

          if (newRank.id != currentRankId) {
            tx.update(memberRef, {
              'rankId': newRank.id,
              'rankName': newRank.nameAr,
              'rankLevel': newRank.level,
              'rankUpdatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      }
    });
  }

  Future<void> autoEndWar(String warId) async {
    final warRef = _db.collection('family_wars').doc(warId);
    await _db.runTransaction((tx) async {
      final warSnap = await tx.get(warRef);
      if (!warSnap.exists || warSnap.data()?['status'] != 'active') return;

      final data = warSnap.data()!;
      final int cPoints = data['challengerPoints'] ?? 0;
      final int tPoints = data['targetPoints'] ?? 0;
      final String cId = data['challengerId'];
      final String tId = data['targetId'];
      final rewards = data['rewards'] as Map<String, dynamic>;

      String? winnerId;
      if (cPoints > tPoints) {
        winnerId = cId;
      } else if (tPoints > cPoints) {
        winnerId = tId;
      }

      if (winnerId != null) {
        final String loserId = (winnerId == cId) ? tId : cId;

        // توزيع المكافآت للفائز
        tx.update(_db.collection('families').doc(winnerId), {
          'warWins': FieldValue.increment(1),
          'warExp': FieldValue.increment(100),
          'warPoints': FieldValue.increment(100),
          'familyGems': FieldValue.increment(rewards['winnerGems'] ?? 500),
          'familyStars': FieldValue.increment(rewards['winnerStars'] ?? 2500),
          'familyCoins': FieldValue.increment(rewards['winnerStars'] ?? 2500),
          'currentWarId': null,
        });

        // توزيع مكافآت الخاسر
        tx.update(_db.collection('families').doc(loserId), {
          'warLosses': FieldValue.increment(1),
          'familyGems': FieldValue.increment(rewards['loserGems'] ?? 100),
          'familyStars': FieldValue.increment(rewards['loserStars'] ?? 500),
          'familyCoins': FieldValue.increment(rewards['loserStars'] ?? 500),
          'currentWarId': null,
        });

        // منح شارة الحرب للفائز
        if (rewards['badge'] != null) {
          tx.set(
              _db
                  .collection('families')
                  .doc(winnerId)
                  .collection('badges')
                  .doc(rewards['badge']),
              {
                'badgeId': rewards['badge'],
                'awardedAt': FieldValue.serverTimestamp(),
                'type': 'war_reward',
                'warId': warId,
              });
        }
      } else {
        // تعادل
        tx.update(_db.collection('families').doc(cId), {
          'familyGems': FieldValue.increment(200),
          'familyStars': FieldValue.increment(1000),
          'familyCoins': FieldValue.increment(1000),
          'currentWarId': null,
        });
        tx.update(_db.collection('families').doc(tId), {
          'familyGems': FieldValue.increment(200),
          'familyStars': FieldValue.increment(1000),
          'familyCoins': FieldValue.increment(1000),
          'currentWarId': null,
        });
      }

      tx.update(warRef, {
        'status': 'completed',
        'winnerId': winnerId,
        'completedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> endFamilyWar(String warId) async {
    await autoEndWar(warId);
  }

  Future<Map<String, dynamic>> getWarStatistics(String warId) async {
    final warSnap = await _db.collection('family_wars').doc(warId).get();
    if (!warSnap.exists) throw 'الحرب غير موجودة';

    final data = warSnap.data()!;
    final contributions =
        Map<String, int>.from(data['contributionPoints'] ?? {});

    // ترتيب المساهمين
    final sortedContributions = contributions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // حساب الإحصائيات
    final totalPoints =
        (data['challengerPoints'] ?? 0) + (data['targetPoints'] ?? 0);
    final avgContribution = contributions.isNotEmpty
        ? (totalPoints / contributions.length).round()
        : 0;

    return {
      'warId': warId,
      'status': data['status'],
      'challengerPoints': data['challengerPoints'],
      'targetPoints': data['targetPoints'],
      'totalPoints': totalPoints,
      'topContributors': sortedContributions.take(5).toList(),
      'totalContributors': contributions.length,
      'avgContribution': avgContribution,
      'startTime': data['startTime'],
      'endTime': data['endTime'],
      'completedAt': data['completedAt'],
      'winnerId': data['winnerId'],
    };
  }

  Stream<List<FamilyWarModel>> getActiveWars() {
    return _db
        .collection('family_wars')
        .where('status', isEqualTo: 'active')
        .orderBy('endTime', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => FamilyWarModel.fromFirestore(doc)).toList());
  }

  Stream<List<FamilyWarModel>> getFamilyWars(String familyId) {
    return _db
        .collection('family_wars')
        .where('challengerId', isEqualTo: familyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => FamilyWarModel.fromFirestore(doc)).toList());
  }

  Stream<List<FamilyWarModel>> getWarsAgainstFamily(String familyId) {
    return _db
        .collection('family_wars')
        .where('targetId', isEqualTo: familyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => FamilyWarModel.fromFirestore(doc)).toList());
  }

  Future<FamilyWarModel?> getCurrentWar(String familyId) async {
    final familySnap = await _db.collection('families').doc(familyId).get();
    if (!familySnap.exists) return null;

    final currentWarId = familySnap.data()?['currentWarId'];
    if (currentWarId == null) return null;

    final warSnap = await _db.collection('family_wars').doc(currentWarId).get();
    if (!warSnap.exists) return null;

    return FamilyWarModel.fromFirestore(warSnap);
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

      // التحقق مما إذا كان المستخدم هو مؤسس العائلة
      final creatorId = familySnap.data()?['creatorId'];
      final isCreator = creatorId == user.uid;

      // إذا كان المستخدم هو المؤسس، يسمح له بالدخول مباشرة حتى لو كانت العائلة خاصة
      if (familySnap.data()?['isPrivate'] == true && !isCreator) {
        throw 'هذه العائلة خاصة، يرجى إرسال طلب انضمام';
      }

      int currentMembers = (familySnap.data()?['memberCount'] ?? 0);
      int maxMembers = (familySnap.data()?['maxMembers'] ?? 50);
      if (currentMembers >= maxMembers) throw 'العائلة ممتلئة';

      // إذا كان المؤسس، يعطيه دور القائد، وإلا دور العضو
      final role = isCreator ? 'leader' : 'member';

      tx.update(familyRef, {'memberCount': FieldValue.increment(1)});
      tx.update(userRef, {'familyId': familyId, 'familyRole': role});
      tx.set(familyRef.collection('members').doc(user.uid), {
        'uid': user.uid,
        'role': role,
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
      });
      tx.update(familyRef, {
        currency == 'gems' ? 'familyGems' : 'familyCoins':
            FieldValue.increment(amount),
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
              .data()?[currency == 'gems' ? 'familyGems' : 'familyCoins'] ??
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

    // التحقق من وجود الغرفة
    final roomSnap = await _db.collection('rooms').doc(roomId).get();
    if (!roomSnap.exists) {
      throw 'الغرفة غير موجودة';
    }

    // التحقق من أن المستخدم هو مالك الغرفة أو لديه صلاحية
    final roomData = roomSnap.data();
    if (roomData != null && roomData['createdBy'] != user.uid) {
      throw 'ليس لديك صلاحية على هذه الغرفة';
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

  // --- نظام التحالفات بين العائلات (محسّن) ---

  Future<String> createAlliance({
    required String familyId,
    required String familyName,
    required String name,
    required String description,
    String? logoUrl,
    String allianceType = 'social',
    int maxMembers = 5,
    int maxAlliancesPerFamily = 2,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول';

    // التحقق من عدد التحالفات الحالية للعائلة
    final currentAlliances = await _db
        .collection('family_alliances')
        .where('memberFamilyIds', arrayContains: familyId)
        .where('status', isEqualTo: 'active')
        .get();

    if (currentAlliances.docs.length >= maxAlliancesPerFamily) {
      throw 'وصلت إلى الحد الأقصى للتحالفات المسموح بها';
    }

    // إنشاء التحالف
    final allianceRef = await _db.collection('family_alliances').add({
      'name': name,
      'description': description,
      'logoUrl': logoUrl,
      'creatorFamilyId': familyId,
      'creatorFamilyName': familyName,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'memberFamilyIds': [familyId],
      'sharedResources': {
        'gems': 0,
        'stars': 0,
        'coins': 0,
      },
      'maxMembers': maxMembers,
      'maxAlliancesPerFamily': maxAlliancesPerFamily,
      'benefits': AllianceModel.getDefaultBenefits(allianceType),
      'allianceType': allianceType,
      'lastActivityAt': FieldValue.serverTimestamp(),
    });

    // إضافة التحالف للعائلة
    await _db.collection('families').doc(familyId).update({
      'allianceIds': FieldValue.arrayUnion([allianceRef.id]),
    });

    // تسجيل في سجل العائلة
    await addFamilyHistory(
      familyId: familyId,
      type: 'alliance_created',
      title: 'إنشاء تحالف',
      description: 'تم إنشاء التحالف $name',
      data: {
        'allianceId': allianceRef.id,
        'allianceName': name,
        'allianceType': allianceType,
      },
    );

    return allianceRef.id;
  }

  Future<void> sendAllianceInvitation({
    required String allianceId,
    required String targetFamilyId,
    required String targetFamilyName,
  }) async {
    final allianceSnap =
        await _db.collection('family_alliances').doc(allianceId).get();
    if (!allianceSnap.exists) throw 'التحالف غير موجود';

    final alliance = allianceSnap.data();
    if (alliance?['status'] != 'active') throw 'التحالف غير نشط';

    final memberFamilyIds =
        alliance?['memberFamilyIds'] as List<dynamic>? ?? [];
    if (memberFamilyIds.contains(targetFamilyId)) {
      throw 'العائلة بالفعل عضو في التحالف';
    }

    if (memberFamilyIds.length >= (alliance?['maxMembers'] ?? 5)) {
      throw 'التحالف ممتلئ';
    }

    // التحقق من عدد التحالفات للعائلة المستهدفة
    final targetAlliances = await _db
        .collection('family_alliances')
        .where('memberFamilyIds', arrayContains: targetFamilyId)
        .where('status', isEqualTo: 'active')
        .get();

    final maxAlliances = alliance?['maxAlliancesPerFamily'] ?? 2;
    if (targetAlliances.docs.length >= maxAlliances) {
      throw 'العائلة المستهدفة وصلت للحد الأقصى للتحالفات';
    }

    // إرسال الدعوة
    await _db.collection('alliance_invitations').add({
      'allianceId': allianceId,
      'allianceName': alliance?['name'],
      'targetFamilyId': targetFamilyId,
      'targetFamilyName': targetFamilyName,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // إرسال إشعار للعائلة
    await sendFamilyNotification(
      targetFamilyId,
      'دعوة تحالف',
      'تمت دعوتك للانضمام إلى تحالف ${alliance?['name']}',
      'alliance_invitation',
      data: {
        'allianceId': allianceId,
        'allianceName': alliance?['name'],
      },
    );
  }

  Future<void> acceptAllianceInvitation(String invitationId) async {
    final invitationSnap =
        await _db.collection('alliance_invitations').doc(invitationId).get();
    if (!invitationSnap.exists) throw 'الدعوة غير موجودة';

    final invitation = invitationSnap.data();
    if (invitation?['status'] != 'pending') throw 'الدعوة غير صالحة';

    final allianceId = invitation?['allianceId'];
    final targetFamilyId = invitation?['targetFamilyId'];

    await _db.runTransaction((tx) async {
      final allianceRef = _db.collection('family_alliances').doc(allianceId);
      final allianceSnap = await tx.get(allianceRef);

      if (!allianceSnap.exists) throw 'التحالف غير موجود';

      final allianceData = allianceSnap.data();
      final memberFamilyIds =
          allianceData?['memberFamilyIds'] as List<dynamic>? ?? [];

      if (memberFamilyIds.length >= (allianceData?['maxMembers'] ?? 5)) {
        throw 'التحالف ممتلئ';
      }

      // إضافة العائلة للتحالف
      tx.update(allianceRef, {
        'memberFamilyIds': FieldValue.arrayUnion([targetFamilyId]),
        'lastActivityAt': FieldValue.serverTimestamp(),
      });

      // إضافة التحالف للعائلة
      tx.update(_db.collection('families').doc(targetFamilyId), {
        'allianceIds': FieldValue.arrayUnion([allianceId]),
      });

      // تحديث حالة الدعوة
      tx.update(_db.collection('alliance_invitations').doc(invitationId), {
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });
    });

    // تسجيل في سجل العائلة
    await addFamilyHistory(
      familyId: targetFamilyId,
      type: 'alliance_joined',
      title: 'الانضمام لتحالف',
      description: 'انضممت للتحالف ${invitation?['allianceName']}',
      data: {
        'allianceId': allianceId,
        'allianceName': invitation?['allianceName'],
      },
    );
  }

  Future<void> rejectAllianceInvitation(String invitationId) async {
    await _db.collection('alliance_invitations').doc(invitationId).update({
      'status': 'rejected',
      'rejectedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> leaveAlliance(String allianceId, String familyId) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول';

    await _db.runTransaction((tx) async {
      final allianceRef = _db.collection('family_alliances').doc(allianceId);
      final allianceSnap = await tx.get(allianceRef);

      if (!allianceSnap.exists) throw 'التحالف غير موجود';

      final allianceData = allianceSnap.data();
      final creatorFamilyId = allianceData?['creatorFamilyId'];

      if (creatorFamilyId == familyId) {
        throw 'لا يمكن لمؤسس التحالف مغادرته. يجب حل التحالف أولاً.';
      }

      // إزالة العائلة من التحالف
      tx.update(allianceRef, {
        'memberFamilyIds': FieldValue.arrayRemove([familyId]),
        'lastActivityAt': FieldValue.serverTimestamp(),
      });

      // إزالة التحالف من العائلة
      tx.update(_db.collection('families').doc(familyId), {
        'allianceIds': FieldValue.arrayRemove([allianceId]),
      });
    });

    // تسجيل في سجل العائلة
    await addFamilyHistory(
      familyId: familyId,
      type: 'alliance_left',
      title: 'مغادرة تحالف',
      description: 'غادرت التحالف',
      data: {
        'allianceId': allianceId,
      },
    );
  }

  Future<void> dissolveAlliance(String allianceId, String familyId) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول';

    final allianceSnap =
        await _db.collection('family_alliances').doc(allianceId).get();
    if (!allianceSnap.exists) throw 'التحالف غير موجود';

    final allianceData = allianceSnap.data();
    final creatorFamilyId = allianceData?['creatorFamilyId'];

    if (creatorFamilyId != familyId) {
      throw 'فقط مؤسس التحالف يمكنه حله';
    }

    final memberFamilyIds =
        allianceData?['memberFamilyIds'] as List<dynamic>? ?? [];

    await _db.runTransaction((tx) async {
      // تحديث حالة التحالف
      tx.update(_db.collection('family_alliances').doc(allianceId), {
        'status': 'dissolved',
        'dissolvedAt': FieldValue.serverTimestamp(),
        'dissolvedBy': user.uid,
      });

      // إزالة التحالف من جميع العائلات الأعضاء
      for (final familyId in memberFamilyIds) {
        tx.update(_db.collection('families').doc(familyId), {
          'allianceIds': FieldValue.arrayRemove([allianceId]),
        });
      }
    });

    // تسجيل في سجل جميع العائلات
    for (final familyId in memberFamilyIds) {
      await addFamilyHistory(
        familyId: familyId,
        type: 'alliance_dissolved',
        title: 'حل التحالف',
        description: 'تم حل التحالف ${allianceData?['name']}',
        data: {
          'allianceId': allianceId,
          'allianceName': allianceData?['name'],
        },
      );
    }
  }

  Future<void> contributeToAlliance({
    required String allianceId,
    required String familyId,
    required int amount,
    required String currency,
  }) async {
    await _db.runTransaction((tx) async {
      final allianceRef = _db.collection('family_alliances').doc(allianceId);
      final familyRef = _db.collection('families').doc(familyId);

      final allianceSnap = await tx.get(allianceRef);
      final familySnap = await tx.get(familyRef);

      if (!allianceSnap.exists) throw 'التحالف غير موجود';
      if (!familySnap.exists) throw 'العائلة غير موجودة';

      final allianceData = allianceSnap.data();
      final memberFamilyIds =
          allianceData?['memberFamilyIds'] as List<dynamic>? ?? [];

      if (!memberFamilyIds.contains(familyId)) {
        throw 'العائلة ليست عضو في التحالف';
      }

      // خصم من العائلة
      final familyCurrency = currency == 'gems' ? 'familyGems' : 'familyStars';
      final currentBalance = familySnap.data()?[familyCurrency] ?? 0;

      if (currentBalance < amount) throw 'رصيد العائلة غير كافٍ';

      tx.update(familyRef, {
        familyCurrency: FieldValue.increment(-amount),
      });

      // إضافة للتحالف
      final resourceKey = 'sharedResources.$currency';
      tx.update(allianceRef, {
        resourceKey: FieldValue.increment(amount),
        'lastActivityAt': FieldValue.serverTimestamp(),
      });
    });

    // تسجيل في سجل العائلة
    await addFamilyHistory(
      familyId: familyId,
      type: 'alliance_contribution',
      title: 'مساهمة في التحالف',
      description: 'ساهمت بـ $amount $currency في التحالف',
      data: {
        'allianceId': allianceId,
        'amount': amount,
        'currency': currency,
      },
    );
  }

  Future<void> applyAllianceBenefit({
    required String allianceId,
    required String familyId,
    required String benefitType,
  }) async {
    final allianceSnap =
        await _db.collection('family_alliances').doc(allianceId).get();
    if (!allianceSnap.exists) throw 'التحالف غير موجود';

    final allianceData = allianceSnap.data();
    final benefits = allianceData?['benefits'] as Map<String, dynamic>? ?? {};

    // التحقق من الميزة
    if (!benefits.containsKey(benefitType)) {
      throw 'الميزة غير متاحة لهذا التحالف';
    }

    // تطبيق الميزة حسب النوع
    switch (benefitType) {
      case 'warBonusMultiplier':
        // سيتم تطبيق تلقائياً في الحروب
        break;
      case 'tradeBonusMultiplier':
        // سيتم تطبيق تلقائياً في التداول
        break;
      case 'sharedTreasury':
        // يمكن الوصول للخزينة المشتركة
        break;
      default:
        throw 'الميزة غير مدعومة حالياً';
    }
  }

  Stream<List<AllianceModel>> getFamilyAlliances(String familyId) {
    return _db
        .collection('family_alliances')
        .where('memberFamilyIds', arrayContains: familyId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => AllianceModel.fromFirestore(doc)).toList());
  }

  Stream<List<Map<String, dynamic>>> getAllianceInvitations(String familyId) {
    return _db
        .collection('alliance_invitations')
        .where('targetFamilyId', isEqualTo: familyId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.data()).toList());
  }

  Future<int> getFamilyAllianceCount(String familyId) async {
    final snapshot = await _db
        .collection('family_alliances')
        .where('memberFamilyIds', arrayContains: familyId)
        .where('status', isEqualTo: 'active')
        .get();
    return snapshot.docs.length;
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

      final itemData = itemSnap.data() as Map<String, dynamic>;
      final int originalCost = itemData['cost'] ?? 0;
      final int? saleCost = itemData['saleCost'];
      final int actualCost =
          (saleCost != null && saleCost > 0) ? saleCost : originalCost;

      final currency = itemData['currency'] ?? 'family_gems';
      final type = itemData['type'] ?? '';
      final currentBalance = familySnap.data()?[currency] ?? 0;

      if (currentBalance < actualCost) throw 'رصيد خزينة العائلة غير كافٍ';

      tx.update(familyRef, {
        currency: FieldValue.increment(-actualCost),
      });

      tx.update(itemRef, {
        'purchaseCount': FieldValue.increment(1),
      });

      tx.set(familyRef.collection('purchased_items').doc(itemId), {
        'itemId': itemId,
        'purchasedAt': FieldValue.serverTimestamp(),
        'purchasedBy': user.uid,
      });

      // إضافة العنصر إلى محفظة المستخدم
      final userRef = _db.collection('users').doc(user.uid);
      tx.update(userRef, {
        'inventory': FieldValue.arrayUnion([itemId]),
      });

      // إذا كان العنصر إيد، قم بتغيير إيد العائلة
      if (type == 'hand_effect' || type == 'hand_id') {
        final handNumber = itemSnap.data()?['handNumber'];
        final handLetters = itemSnap.data()?['handLetters'];

        if (handNumber != null || handLetters != null) {
          Map<String, dynamic> handUpdates = {};
          if (handNumber != null) handUpdates['familyHandNumber'] = handNumber;
          if (handLetters != null) {
            handUpdates['familyHandLetters'] = handLetters;
          }

          tx.update(familyRef, handUpdates);
        }
      }
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

  // --- نظام الرتب (Member Ranks) ---

  Future<void> updateMemberRank(String familyId, String userId) async {
    final memberRef = _db
        .collection('families')
        .doc(familyId)
        .collection('members')
        .doc(userId);

    await _db.runTransaction((tx) async {
      final memberSnap = await tx.get(memberRef);
      if (!memberSnap.exists) return;

      final contributionPoints = memberSnap.data()?['contributionPoints'] ?? 0;
      final currentRankId = memberSnap.data()?['rankId'] ?? 'bronze';

      // الحصول على الرتبة المناسبة بناءً على النقاط
      final newRank = MemberRankModel.getRankForPoints(contributionPoints);

      // تحديث الرتبة إذا تغيرت
      if (newRank.id != currentRankId) {
        tx.update(memberRef, {
          'rankId': newRank.id,
          'rankName': newRank.nameAr,
          'rankLevel': newRank.level,
          'rankUpdatedAt': FieldValue.serverTimestamp(),
        });

        // إضافة سجل للعائلة
        await addFamilyHistory(
          familyId: familyId,
          type: 'rank_up',
          title: 'ترقية رتبة عضو',
          description: 'تم ترقية رتبة العضو إلى ${newRank.nameAr}',
          data: {
            'userId': userId,
            'newRank': newRank.nameAr,
            'newRankLevel': newRank.level,
          },
        );
      }
    });
  }

  Future<void> updateAllMemberRanks(String familyId) async {
    final membersSnapshot = await _db
        .collection('families')
        .doc(familyId)
        .collection('members')
        .get();

    final promises = membersSnapshot.docs.map((doc) async {
      await updateMemberRank(familyId, doc.id);
    });

    await Future.wait(promises);
  }

  Future<void> addContributionPoints(
      String familyId, String userId, int points) async {
    final memberRef = _db
        .collection('families')
        .doc(familyId)
        .collection('members')
        .doc(userId);

    await _db.runTransaction((tx) async {
      final memberSnap = await tx.get(memberRef);
      if (!memberSnap.exists) return;

      final currentPoints = memberSnap.data()?['contributionPoints'] ?? 0;
      final newPoints = currentPoints + points;

      tx.update(memberRef, {
        'contributionPoints': newPoints,
        'lastContributionAt': FieldValue.serverTimestamp(),
      });

      // تحديث الرتبة تلقائياً
      final newRank = MemberRankModel.getRankForPoints(newPoints);
      final currentRankId = memberSnap.data()?['rankId'] ?? 'bronze';

      if (newRank.id != currentRankId) {
        tx.update(memberRef, {
          'rankId': newRank.id,
          'rankName': newRank.nameAr,
          'rankLevel': newRank.level,
          'rankUpdatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Stream<MemberRankModel> getMemberRank(String familyId, String userId) {
    return _db
        .collection('families')
        .doc(familyId)
        .collection('members')
        .doc(userId)
        .snapshots()
        .map((doc) {
      final data = doc.data();
      if (data == null) return MemberRankModel.getDefaultRanks().first;
      final rankId = data['rankId'] ?? 'bronze';
      final ranks = MemberRankModel.getDefaultRanks();
      return ranks.firstWhere((r) => r.id == rankId, orElse: () => ranks.first);
    });
  }

  Stream<List<Map<String, dynamic>>> getMembersByRank(String familyId) {
    return _db
        .collection('families')
        .doc(familyId)
        .collection('members')
        .orderBy('rankLevel', descending: true)
        .orderBy('contributionPoints', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              final ranks = MemberRankModel.getDefaultRanks();
              final rankId = data['rankId'] ?? 'bronze';
              final rank = ranks.firstWhere((r) => r.id == rankId,
                  orElse: () => ranks.first);
              return {
                'userId': doc.id,
                'rank': rank,
                'contributionPoints': data['contributionPoints'] ?? 0,
                'joinedAt': data['joinedAt'],
                'role': data['role'] ?? 'member',
              };
            }).toList());
  }

  Future<bool> hasRankPermission(
      String familyId, String userId, String permission) async {
    final memberSnap = await _db
        .collection('families')
        .doc(familyId)
        .collection('members')
        .doc(userId)
        .get();

    if (!memberSnap.exists) return false;

    final rankId = memberSnap.data()?['rankId'] ?? 'bronze';
    final ranks = MemberRankModel.getDefaultRanks();
    final rank =
        ranks.firstWhere((r) => r.id == rankId, orElse: () => ranks.first);

    return rank.permissions[permission] == true;
  }

  // --- تفعيل مزايا الرتب ---

  Future<void> claimDailyRankBonus(String familyId, String userId) async {
    final memberRef = _db
        .collection('families')
        .doc(familyId)
        .collection('members')
        .doc(userId);
    final userRef = _db.collection('users').doc(userId);

    await _db.runTransaction((tx) async {
      final memberSnap = await tx.get(memberRef);
      if (!memberSnap.exists) return;

      final rankId = memberSnap.data()?['rankId'] ?? 'bronze';
      final ranks = MemberRankModel.getDefaultRanks();
      final rank =
          ranks.firstWhere((r) => r.id == rankId, orElse: () => ranks.first);

      // التحقق من أن الرتبة لديها ميزة المكافأة اليومية
      if (!rank.perks.contains('daily_bonus')) {
        throw 'رتبتك لا تملك ميزة المكافأة اليومية';
      }

      // التحقق من أن المستخدم لم يستلم المكافأة اليوم
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final lastClaim = memberSnap.data()?['lastDailyBonusClaim'];
      if (lastClaim == today) {
        throw 'لقد استلمت مكافأة اليوم بالفعل';
      }

      // حساب المكافأة بناءً على مضاعف الرتبة
      const baseBonus = 10;
      final bonus = (baseBonus * rank.bonusMultiplier).round();

      tx.update(userRef, {
        'gems': FieldValue.increment(bonus),
        'stars': FieldValue.increment(bonus * 2),
        'coins': FieldValue.increment(bonus * 2),
      });

      tx.update(memberRef, {
        'lastDailyBonusClaim': today,
        'totalDailyBonusClaimed': FieldValue.increment(bonus),
      });
    });
  }

  Future<void> claimWarRankBonus(
      String familyId, String userId, String warId) async {
    final memberRef = _db
        .collection('families')
        .doc(familyId)
        .collection('members')
        .doc(userId);
    final userRef = _db.collection('users').doc(userId);

    await _db.runTransaction((tx) async {
      final memberSnap = await tx.get(memberRef);
      if (!memberSnap.exists) return;

      final rankId = memberSnap.data()?['rankId'] ?? 'bronze';
      final ranks = MemberRankModel.getDefaultRanks();
      final rank =
          ranks.firstWhere((r) => r.id == rankId, orElse: () => ranks.first);

      // التحقق من أن الرتبة لديها ميزة مكافأة الحرب
      if (!rank.perks.contains('war_bonus')) {
        return; // لا يوجد مكافأة إضافية
      }

      // حساب المكافأة الإضافية
      const baseBonus = 50;
      final bonus = (baseBonus * rank.bonusMultiplier).round();

      tx.update(userRef, {
        'gems': FieldValue.increment(bonus),
        'stars': FieldValue.increment(bonus * 2),
      });

      tx.update(memberRef, {
        'totalWarBonusClaimed': FieldValue.increment(bonus),
      });
    });
  }

  Future<bool> hasPerk(String familyId, String userId, String perk) async {
    final memberSnap = await _db
        .collection('families')
        .doc(familyId)
        .collection('members')
        .doc(userId)
        .get();

    if (!memberSnap.exists) return false;

    final rankId = memberSnap.data()?['rankId'] ?? 'bronze';
    final ranks = MemberRankModel.getDefaultRanks();
    final rank =
        ranks.firstWhere((r) => r.id == rankId, orElse: () => ranks.first);

    return rank.perks.contains(perk);
  }

  // تفعيل جميع مزايا الرتبة للمستخدم
  Future<Map<String, dynamic>> activateRankPerks(
      String familyId, String userId) async {
    final memberRef = _db
        .collection('families')
        .doc(familyId)
        .collection('members')
        .doc(userId);
    final userRef = _db.collection('users').doc(userId);

    Map<String, dynamic> activatedPerks = {};

    await _db.runTransaction((tx) async {
      final memberSnap = await tx.get(memberRef);
      if (!memberSnap.exists) return;

      final rankId = memberSnap.data()?['rankId'] ?? 'bronze';
      final ranks = MemberRankModel.getDefaultRanks();
      final rank =
          ranks.firstWhere((r) => r.id == rankId, orElse: () => ranks.first);

      final userSnap = await tx.get(userRef);
      if (!userSnap.exists) return;

      // تفعيل الشارة الحصرية
      if (rank.badgeId != null) {
        final badges = List<String>.from(userSnap.data()?['badges'] ?? []);
        if (!badges.contains(rank.badgeId)) {
          badges.add(rank.badgeId!);
          tx.update(userRef, {'badges': badges});
          activatedPerks['badge'] = rank.badgeId;
        }
      }

      // تفعيل لون الدردشة المخصص
      if (rank.chatColor != null) {
        tx.update(userRef, {'chatColor': rank.chatColor});
        activatedPerks['chatColor'] = rank.chatColor;
      }

      // تفعيل الميزات الخاصة
      final features =
          List<String>.from(userSnap.data()?['specialFeatures'] ?? []);
      for (final feature in rank.specialFeatures) {
        if (!features.contains(feature)) {
          features.add(feature);
        }
      }
      tx.update(userRef, {'specialFeatures': features});
      activatedPerks['specialFeatures'] = rank.specialFeatures;

      // تطبيق المكافآت المخصصة
      if (rank.customRewards.isNotEmpty) {
        final rewards =
            Map<String, dynamic>.from(userSnap.data()?['customRewards'] ?? {});
        for (final entry in rank.customRewards.entries) {
          rewards[entry.key] = entry.value;
        }
        tx.update(userRef, {'customRewards': rewards});
        activatedPerks['customRewards'] = rank.customRewards;
      }

      // تحديث الصلاحيات
      final permissions =
          Map<String, dynamic>.from(userSnap.data()?['permissions'] ?? {});
      for (final entry in rank.permissions.entries) {
        permissions[entry.key] = entry.value;
      }
      tx.update(userRef, {'permissions': permissions});
      activatedPerks['permissions'] = rank.permissions;
    });

    return activatedPerks;
  }

  // الحصول على المزايا المتاحة للرتبة
  Future<Map<String, dynamic>> getAvailableRankPerks(
      String familyId, String userId) async {
    final memberSnap = await _db
        .collection('families')
        .doc(familyId)
        .collection('members')
        .doc(userId)
        .get();

    if (!memberSnap.exists) return {};

    final rankId = memberSnap.data()?['rankId'] ?? 'bronze';
    final ranks = MemberRankModel.getDefaultRanks();
    final rank =
        ranks.firstWhere((r) => r.id == rankId, orElse: () => ranks.first);

    return {
      'rank': rank.nameAr,
      'level': rank.level,
      'perks': rank.perks,
      'bonusMultiplier': rank.bonusMultiplier,
      'permissions': rank.permissions,
      'badgeId': rank.badgeId,
      'chatColor': rank.chatColor,
      'specialFeatures': rank.specialFeatures,
      'customRewards': rank.customRewards,
      'pointsToNextRank': rank.pointsToNextRank,
      'progressToNextRank': rank.progressToNextRank,
    };
  }

  Future<double> getBonusMultiplier(String familyId, String userId) async {
    final memberSnap = await _db
        .collection('families')
        .doc(familyId)
        .collection('members')
        .doc(userId)
        .get();

    if (!memberSnap.exists) return 1.0;

    final rankId = memberSnap.data()?['rankId'] ?? 'bronze';
    final ranks = MemberRankModel.getDefaultRanks();
    final rank =
        ranks.firstWhere((r) => r.id == rankId, orElse: () => ranks.first);

    return rank.bonusMultiplier;
  }

  // --- نظام التنافس بين الرتب ---

  Future<void> recalculateRankCompetition(
      String familyId, String rankId) async {
    final membersSnapshot = await _db
        .collection('families')
        .doc(familyId)
        .collection('members')
        .where('rankId', isEqualTo: rankId)
        .get();

    if (membersSnapshot.docs.isEmpty) return;

    final ranks = MemberRankModel.getDefaultRanks();
    final rank =
        ranks.firstWhere((r) => r.id == rankId, orElse: () => ranks.first);

    int totalContribution = 0;
    int weeklyContribution = 0;
    int monthlyContribution = 0;
    List<String> topMembers = [];

    for (final doc in membersSnapshot.docs) {
      final contribution = (doc.data()['contributionPoints'] ?? 0) as int;
      totalContribution += contribution;

      // حساب المساهمات الأسبوعية والشهرية (تبسيط)
      weeklyContribution += contribution ~/ 4;
      monthlyContribution += contribution;

      topMembers.add(doc.id);
    }

    // ترتيب أفضل الأعضاء
    topMembers.sort((a, b) {
      final aPoints = membersSnapshot.docs
              .firstWhere((doc) => doc.id == a)
              .data()['contributionPoints'] ??
          0;
      final bPoints = membersSnapshot.docs
              .firstWhere((doc) => doc.id == b)
              .data()['contributionPoints'] ??
          0;
      return bPoints.compareTo(aPoints);
    });

    final competitionScore = RankCompetitionModel.calculateCompetitionScore(
      membersSnapshot.docs.length,
      membersSnapshot.docs.length,
      totalContribution,
      weeklyContribution,
    );

    final competitionRef = _db
        .collection('families')
        .doc(familyId)
        .collection('rank_competitions')
        .doc(rankId);

    await competitionRef.set({
      'familyId': familyId,
      'rankId': rankId,
      'rankName': rank.nameAr,
      'totalMembers': membersSnapshot.docs.length,
      'activeMembers': membersSnapshot.docs.length,
      'totalContributionPoints': totalContribution,
      'weeklyContributionPoints': weeklyContribution,
      'monthlyContributionPoints': monthlyContribution,
      'competitionScore': competitionScore,
      'lastUpdated': FieldValue.serverTimestamp(),
      'topMembers': topMembers.take(10).toList(),
      'achievements': {},
    }, SetOptions(merge: true));
  }

  Future<void> updateAllRankCompetitions(String familyId) async {
    final ranks = MemberRankModel.getDefaultRanks();
    for (final rank in ranks) {
      await recalculateRankCompetition(familyId, rank.id);
    }
  }

  Stream<List<Map<String, dynamic>>> getRankCompetitionLeaderboard(
      String familyId) {
    return _db
        .collection('families')
        .doc(familyId)
        .collection('rank_competitions')
        .orderBy('competitionScore', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data();
              return {
                'rankId': data['rankId'],
                'rankName': data['rankName'],
                'totalMembers': data['totalMembers'],
                'activeMembers': data['activeMembers'],
                'totalContributionPoints': data['totalContributionPoints'],
                'weeklyContributionPoints': data['weeklyContributionPoints'],
                'monthlyContributionPoints': data['monthlyContributionPoints'],
                'competitionScore': data['competitionScore'],
                'topMembers': List<String>.from(data['topMembers'] ?? []),
                'achievements':
                    Map<String, dynamic>.from(data['achievements'] ?? {}),
              };
            }).toList());
  }

  Future<void> addRankCompetitionAchievement(String familyId, String rankId,
      String achievementId, String achievementName) async {
    final competitionRef = _db
        .collection('families')
        .doc(familyId)
        .collection('rank_competitions')
        .doc(rankId);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(competitionRef);
      if (!snap.exists) return;

      final achievements =
          Map<String, dynamic>.from(snap.data()?['achievements'] ?? {});
      achievements[achievementId] = {
        'name': achievementName,
        'achievedAt': FieldValue.serverTimestamp(),
      };

      tx.update(competitionRef, {
        'achievements': achievements,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<Map<String, dynamic>> getMemberRankCompetitionStats(
      String familyId, String userId) async {
    final memberSnap = await _db
        .collection('families')
        .doc(familyId)
        .collection('members')
        .doc(userId)
        .get();

    if (!memberSnap.exists) return {};

    final rankId = memberSnap.data()?['rankId'] ?? 'bronze';
    final competitionSnap = await _db
        .collection('families')
        .doc(familyId)
        .collection('rank_competitions')
        .doc(rankId)
        .get();

    if (!competitionSnap.exists) return {};

    final data = competitionSnap.data()!;
    final topMembers = List<String>.from(data['topMembers'] ?? []);
    final memberRank = topMembers.indexOf(userId) + 1;

    return {
      'rankId': rankId,
      'competitionScore': data['competitionScore'],
      'totalMembers': data['totalMembers'],
      'memberRank': memberRank > 0 ? memberRank : null,
      'isTopMember': topMembers.contains(userId),
      'achievements': data['achievements'],
    };
  }

  // --- نظام التصنيف العالمي للحروب ---

  Future<void> updateWarLeaderboard(
      String familyId, bool won, int pointsEarned) async {
    final leaderboardRef = _db.collection('war_leaderboard').doc(familyId);

    await _db.runTransaction((tx) async {
      final leaderboardSnap = await tx.get(leaderboardRef);

      if (!leaderboardSnap.exists) {
        // إنشاء سجل جديد للعائلة
        final familySnap =
            await tx.get(_db.collection('families').doc(familyId));
        final familyData = familySnap.data();

        tx.set(leaderboardRef, {
          'familyId': familyId,
          'familyName': familyData?['name'] ?? 'Unknown',
          'familyLogo': familyData?['logoUrl'],
          'totalWars': 1,
          'warsWon': won ? 1 : 0,
          'warsLost': won ? 0 : 1,
          'totalPoints': pointsEarned,
          'currentStreak': won ? 1 : 0,
          'bestStreak': won ? 1 : 0,
          'lastWarDate': FieldValue.serverTimestamp(),
          'rank': 0,
        });
      } else {
        final data = leaderboardSnap.data();
        final totalWars = (data?['totalWars'] ?? 0) + 1;
        final warsWon =
            won ? (data?['warsWon'] ?? 0) + 1 : (data?['warsWon'] ?? 0);
        final warsLost =
            won ? (data?['warsLost'] ?? 0) : (data?['warsLost'] ?? 0) + 1;
        final totalPoints = (data?['totalPoints'] ?? 0) + pointsEarned;
        final currentStreak = won ? (data?['currentStreak'] ?? 0) + 1 : 0;
        final bestStreak = currentStreak > (data?['bestStreak'] ?? 0)
            ? currentStreak
            : (data?['bestStreak'] ?? 0);

        tx.update(leaderboardRef, {
          'totalWars': totalWars,
          'warsWon': warsWon,
          'warsLost': warsLost,
          'totalPoints': totalPoints,
          'currentStreak': currentStreak,
          'bestStreak': bestStreak,
          'lastWarDate': FieldValue.serverTimestamp(),
        });
      }
    });

    // تحديث الرتب العالمية
    await _updateGlobalRanks();
  }

  Future<void> _updateGlobalRanks() async {
    final leaderboardSnapshot = await _db
        .collection('war_leaderboard')
        .orderBy('totalPoints', descending: true)
        .get();

    final batch = _db.batch();

    for (int i = 0; i < leaderboardSnapshot.docs.length; i++) {
      final doc = leaderboardSnapshot.docs[i];
      batch.update(doc.reference, {'rank': i + 1});
    }

    await batch.commit();
  }

  Stream<List<WarLeaderboardModel>> getWarLeaderboard() {
    return _db
        .collection('war_leaderboard')
        .orderBy('totalPoints', descending: true)
        .limit(100)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => WarLeaderboardModel.fromFirestore(doc))
            .toList());
  }

  Stream<WarLeaderboardModel?> getFamilyLeaderboard(String familyId) {
    return _db.collection('war_leaderboard').doc(familyId).snapshots().map(
        (doc) => doc.exists ? WarLeaderboardModel.fromFirestore(doc) : null);
  }

  Future<List<WarLeaderboardModel>> getTopFamilies(int limit) async {
    final snapshot = await _db
        .collection('war_leaderboard')
        .orderBy('totalPoints', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs
        .map((doc) => WarLeaderboardModel.fromFirestore(doc))
        .toList();
  }

  // --- نظام التحديات داخل الحرب ---

  Future<void> createWarChallenges(
      String warId, String familyId, String familyName) async {
    final challenges =
        WarChallengeModel.getDefaultChallenges(warId, familyId, familyName);

    for (final challenge in challenges) {
      await _db.collection('war_challenges').add(challenge.toMap());
    }
  }

  Future<void> joinWarChallenge(String challengeId, String userId) async {
    final challengeRef = _db.collection('war_challenges').doc(challengeId);

    await _db.runTransaction((tx) async {
      final challengeSnap = await tx.get(challengeRef);
      if (!challengeSnap.exists) return;

      final challengeData = challengeSnap.data();
      final participantIds =
          challengeData?['participantIds'] as List<dynamic>? ?? [];

      if (participantIds.contains(userId)) return;

      tx.update(challengeRef, {
        'participantIds': FieldValue.arrayUnion([userId]),
        'participantProgress.$userId': 0,
      });
    });
  }

  Future<void> updateChallengeProgress(
      String challengeId, String userId, int progress) async {
    final challengeRef = _db.collection('war_challenges').doc(challengeId);

    await _db.runTransaction((tx) async {
      final challengeSnap = await tx.get(challengeRef);
      if (!challengeSnap.exists) return;

      final challengeData = challengeSnap.data();
      final currentValue = challengeData?['currentValue'] ?? 0;
      final targetValue = challengeData?['targetValue'] ?? 100;
      final newValue = currentValue + progress;
      final newStatus = newValue >= targetValue
          ? 'completed'
          : challengeData?['status'] ?? 'active';

      tx.update(challengeRef, {
        'currentValue': newValue,
        'participantProgress.$userId': FieldValue.increment(progress),
        'status': newStatus,
        if (newStatus == 'completed')
          'completedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Stream<List<WarChallengeModel>> getWarChallenges(
      String warId, String familyId) {
    return _db
        .collection('war_challenges')
        .where('warId', isEqualTo: warId)
        .where('familyId', isEqualTo: familyId)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => WarChallengeModel.fromFirestore(doc))
            .toList());
  }

  Future<void> claimChallengeReward(String challengeId, String userId) async {
    final challengeRef = _db.collection('war_challenges').doc(challengeId);
    final userRef = _db.collection('users').doc(userId);

    await _db.runTransaction((tx) async {
      final challengeSnap = await tx.get(challengeRef);
      if (!challengeSnap.exists) return;

      final challengeData = challengeSnap.data();
      if (challengeData?['status'] != 'completed') return;

      final rewardType = challengeData?['rewardType'] ?? 'stars';
      final rewardPoints = challengeData?['rewardPoints'] ?? 50;
      final rewardBadgeId = challengeData?['rewardBadgeId'];

      // منح المكافأة
      if (rewardType == 'gems') {
        tx.update(userRef, {
          'gems': FieldValue.increment(rewardPoints),
        });
      } else if (rewardType == 'stars') {
        tx.update(userRef, {
          'stars': FieldValue.increment(rewardPoints),
          'coins': FieldValue.increment(rewardPoints),
        });
      }

      // منح الشارة إذا وجدت
      if (rewardBadgeId != null) {
        tx.set(userRef.collection('badges').doc(rewardBadgeId), {
          'badgeId': rewardBadgeId,
          'awardedAt': FieldValue.serverTimestamp(),
          'type': 'challenge_reward',
          'challengeId': challengeId,
        });
      }
    });
  }

  // --- نظام التنافس بين الرتب ---

  Future<void> updateRankCompetition(
      String familyId, String rankId, String rankName, int points) async {
    final competitionRef =
        _db.collection('rank_competitions').doc('${familyId}_$rankId');

    await _db.runTransaction((tx) async {
      final competitionSnap = await tx.get(competitionRef);

      if (!competitionSnap.exists) {
        // إنشاء سجل جديد للتنافس
        tx.set(competitionRef, {
          'familyId': familyId,
          'rankId': rankId,
          'rankName': rankName,
          'totalMembers': 1,
          'activeMembers': 1,
          'totalContributionPoints': points,
          'weeklyContributionPoints': points,
          'monthlyContributionPoints': points,
          'competitionScore': RankCompetitionModel.calculateCompetitionScore(
              1, 1, points, points),
          'rank': 0,
          'lastUpdated': FieldValue.serverTimestamp(),
          'topMembers': [],
          'achievements': {},
        });
      } else {
        final data = competitionSnap.data();
        final totalContribution =
            (data?['totalContributionPoints'] ?? 0) + points;
        final weeklyContribution =
            (data?['weeklyContributionPoints'] ?? 0) + points;
        final monthlyContribution =
            (data?['monthlyContributionPoints'] ?? 0) + points;
        final totalMembers = data?['totalMembers'] ?? 1;
        final activeMembers = data?['activeMembers'] ?? 1;

        tx.update(competitionRef, {
          'totalContributionPoints': totalContribution,
          'weeklyContributionPoints': weeklyContribution,
          'monthlyContributionPoints': monthlyContribution,
          'competitionScore': RankCompetitionModel.calculateCompetitionScore(
            totalMembers,
            activeMembers,
            totalContribution,
            weeklyContribution,
          ),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    });

    // تحديث الرتب العالمية
    await _updateRankCompetitionRanks(familyId);
  }

  Future<void> _updateRankCompetitionRanks(String familyId) async {
    final competitionSnapshot = await _db
        .collection('rank_competitions')
        .where('familyId', isEqualTo: familyId)
        .orderBy('competitionScore', descending: true)
        .get();

    final batch = _db.batch();

    for (int i = 0; i < competitionSnapshot.docs.length; i++) {
      final doc = competitionSnapshot.docs[i];
      batch.update(doc.reference, {'rank': i + 1});
    }

    await batch.commit();
  }

  Stream<List<RankCompetitionModel>> getFamilyRankCompetitions(
      String familyId) {
    return _db
        .collection('rank_competitions')
        .where('familyId', isEqualTo: familyId)
        .orderBy('competitionScore', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => RankCompetitionModel.fromFirestore(doc))
            .toList());
  }

  Future<void> addRankAchievement(String familyId, String rankId,
      String achievementId, String achievementName) async {
    final competitionRef =
        _db.collection('rank_competitions').doc('${familyId}_$rankId');

    await _db.runTransaction((tx) async {
      final competitionSnap = await tx.get(competitionRef);
      if (!competitionSnap.exists) return;

      final achievements =
          competitionSnap.data()?['achievements'] as Map<String, dynamic>? ??
              {};
      achievements[achievementId] = {
        'name': achievementName,
        'achievedAt': FieldValue.serverTimestamp(),
      };

      tx.update(competitionRef, {
        'achievements': achievements,
      });
    });
  }

  Future<void> resetWeeklyRankCompetition(String familyId) async {
    final competitions = await _db
        .collection('rank_competitions')
        .where('familyId', isEqualTo: familyId)
        .get();

    final batch = _db.batch();

    for (final doc in competitions.docs) {
      batch.update(doc.reference, {
        'weeklyContributionPoints': 0,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // --- نظام عقود التحالفات ---

  Future<String> createAllianceContract({
    required String allianceId,
    required String allianceName,
    required String familyId,
    required String familyName,
    required String contractType,
    String? createdBy,
  }) async {
    final contractRef = await _db.collection('alliance_contracts').add({
      'allianceId': allianceId,
      'allianceName': allianceName,
      'familyId': familyId,
      'familyName': familyName,
      'contractType': contractType,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'signedAt': null,
      'expiresAt': null,
      'terms': AllianceContractModel.getDefaultTerms(contractType),
      'signatories': [],
      'createdBy': createdBy,
      'terminatedBy': null,
      'terminatedAt': null,
      'terminationReason': null,
    });

    return contractRef.id;
  }

  Future<void> signAllianceContract(String contractId, String userId) async {
    final contractRef = _db.collection('alliance_contracts').doc(contractId);

    await _db.runTransaction((tx) async {
      final contractSnap = await tx.get(contractRef);
      if (!contractSnap.exists) return;

      final data = contractSnap.data();
      final signatories = data?['signatories'] as List<dynamic>? ?? [];

      if (signatories.contains(userId)) return;

      tx.update(contractRef, {
        'signatories': FieldValue.arrayUnion([userId]),
        'signedAt': FieldValue.serverTimestamp(),
        'status': 'active',
      });
    });
  }

  Future<void> rejectAllianceContract(String contractId, String userId) async {
    final contractRef = _db.collection('alliance_contracts').doc(contractId);

    await contractRef.update({
      'status': 'rejected',
      'terminatedBy': userId,
      'terminatedAt': FieldValue.serverTimestamp(),
      'terminationReason': 'رفض العقد',
    });
  }

  Future<void> terminateAllianceContract(
      String contractId, String userId, String reason) async {
    final contractRef = _db.collection('alliance_contracts').doc(contractId);

    await contractRef.update({
      'status': 'terminated',
      'terminatedBy': userId,
      'terminatedAt': FieldValue.serverTimestamp(),
      'terminationReason': reason,
    });
  }

  Stream<List<AllianceContractModel>> getAllianceContracts(String allianceId) {
    return _db
        .collection('alliance_contracts')
        .where('allianceId', isEqualTo: allianceId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AllianceContractModel.fromFirestore(doc))
            .toList());
  }

  Stream<List<AllianceContractModel>> getFamilyContracts(String familyId) {
    return _db
        .collection('alliance_contracts')
        .where('familyId', isEqualTo: familyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AllianceContractModel.fromFirestore(doc))
            .toList());
  }

  Future<void> checkExpiredContracts() async {
    final now = Timestamp.now();
    final expiredContracts = await _db
        .collection('alliance_contracts')
        .where('status', isEqualTo: 'active')
        .where('expiresAt', isLessThan: now)
        .get();

    final batch = _db.batch();

    for (final doc in expiredContracts.docs) {
      batch.update(doc.reference, {
        'status': 'expired',
        'terminatedAt': now,
        'terminationReason': 'انتهاء صلاحية العقد',
      });
    }

    await batch.commit();
  }

  // --- نظام حروب التحالفات ---

  Future<String> startAllianceWar({
    required String allianceId1,
    required String allianceName1,
    required String allianceId2,
    required String allianceName2,
    required String warType,
    required Duration duration,
    List<String>? participatingFamilies1,
    List<String>? participatingFamilies2,
  }) async {
    final endTime = Timestamp.fromDate(DateTime.now().add(duration));

    final warRef = await _db.collection('alliance_wars').add({
      'allianceId1': allianceId1,
      'allianceName1': allianceName1,
      'allianceId2': allianceId2,
      'allianceName2': allianceName2,
      'warType': warType,
      'status': 'preparing',
      'createdAt': FieldValue.serverTimestamp(),
      'startedAt': null,
      'endedAt': null,
      'endTime': endTime,
      'alliance1Points': 0,
      'alliance2Points': 0,
      'targetPoints': 5000,
      'progress': 0.0,
      'winnerAllianceId': null,
      'participatingFamilies1': participatingFamilies1 ?? [],
      'participatingFamilies2': participatingFamilies2 ?? [],
      'rewards': AllianceWarModel.getDefaultRewards(warType),
    });

    return warRef.id;
  }

  Future<void> startAllianceWarPhase(String warId) async {
    final warRef = _db.collection('alliance_wars').doc(warId);

    await warRef.update({
      'status': 'active',
      'startedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addAllianceWarPoints(
      String warId, String allianceId, int points) async {
    final warRef = _db.collection('alliance_wars').doc(warId);

    await _db.runTransaction((tx) async {
      final warSnap = await tx.get(warRef);
      if (!warSnap.exists) return;

      final data = warSnap.data();
      final isAlliance1 = allianceId == data?['allianceId1'];
      final alliance1Points =
          (data?['alliance1Points'] ?? 0) + (isAlliance1 ? points : 0);
      final alliance2Points =
          (data?['alliance2Points'] ?? 0) + (isAlliance1 ? 0 : points);
      final totalPoints = alliance1Points + alliance2Points;
      final targetPoints = data?['targetPoints'] ?? 5000;
      final progress =
          AllianceWarModel.calculateProgress(totalPoints, targetPoints);

      tx.update(warRef, {
        'alliance1Points': alliance1Points,
        'alliance2Points': alliance2Points,
        'progress': progress,
      });
    });
  }

  Future<void> endAllianceWar(String warId) async {
    final warRef = _db.collection('alliance_wars').doc(warId);

    await _db.runTransaction((tx) async {
      final warSnap = await tx.get(warRef);
      if (!warSnap.exists) return;

      final data = warSnap.data();
      final alliance1Points = data?['alliance1Points'] ?? 0;
      final alliance2Points = data?['alliance2Points'] ?? 0;
      final winner = alliance1Points > alliance2Points
          ? (data?['allianceId1'] ?? '')
          : (data?['allianceId2'] ?? '');

      tx.update(warRef, {
        'status': 'ended',
        'endedAt': FieldValue.serverTimestamp(),
        'winnerAllianceId': winner,
        'progress': 1.0,
      });
    });
  }

  Stream<List<AllianceWarModel>> getAllianceWars(String allianceId) {
    return _db
        .collection('alliance_wars')
        .where('allianceId1', isEqualTo: allianceId)
        .snapshots()
        .map((snap1) {
      final wars1 =
          snap1.docs.map((doc) => AllianceWarModel.fromFirestore(doc)).toList();
      return wars1;
    });
  }

  Stream<List<AllianceWarModel>> getActiveAllianceWars() {
    return _db
        .collection('alliance_wars')
        .where('status', isEqualTo: 'active')
        .orderBy('endTime', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => AllianceWarModel.fromFirestore(doc))
            .toList());
  }

  // --- نظام المهام التعاونية ---

  Future<String> createCollaborativeTask({
    required String familyId,
    required String familyName,
    required String title,
    required String description,
    required String type,
    required Duration duration,
    required int requiredParticipants,
    String? createdBy,
  }) async {
    final deadline = Timestamp.fromDate(DateTime.now().add(duration));

    final taskRef = await _db.collection('collaborative_tasks').add({
      'familyId': familyId,
      'familyName': familyName,
      'title': title,
      'description': description,
      'type': type,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'startedAt': null,
      'completedAt': null,
      'deadline': deadline,
      'requiredParticipants': requiredParticipants,
      'participantIds': [],
      'participantContributions': {},
      'targetValue': 100,
      'currentValue': 0,
      'rewards': CollaborativeTaskModel.getDefaultRewards(type),
      'createdBy': createdBy,
      'completedBy': null,
    });

    return taskRef.id;
  }

  Future<void> joinCollaborativeTask(String taskId, String userId) async {
    final taskRef = _db.collection('collaborative_tasks').doc(taskId);

    await _db.runTransaction((tx) async {
      final taskSnap = await tx.get(taskRef);
      if (!taskSnap.exists) return;

      final data = taskSnap.data();
      final participantIds = data?['participantIds'] as List<dynamic>? ?? [];

      if (participantIds.contains(userId)) return;

      tx.update(taskRef, {
        'participantIds': FieldValue.arrayUnion([userId]),
        'participantContributions.$userId': 0,
      });
    });
  }

  Future<void> startCollaborativeTask(String taskId) async {
    final taskRef = _db.collection('collaborative_tasks').doc(taskId);

    await taskRef.update({
      'status': 'in_progress',
      'startedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addTaskContribution(
      String taskId, String userId, int value) async {
    final taskRef = _db.collection('collaborative_tasks').doc(taskId);

    await _db.runTransaction((tx) async {
      final taskSnap = await tx.get(taskRef);
      if (!taskSnap.exists) return;

      final data = taskSnap.data();
      final currentValue = data?['currentValue'] ?? 0;
      final targetValue = data?['targetValue'] ?? 100;
      final newValue = currentValue + value;
      final newStatus = newValue >= targetValue
          ? 'completed'
          : data?['status'] ?? 'in_progress';

      tx.update(taskRef, {
        'currentValue': newValue,
        'participantContributions.$userId': FieldValue.increment(value),
        'status': newStatus,
      });

      if (newStatus == 'completed') {
        tx.update(taskRef, {
          'completedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Stream<List<CollaborativeTaskModel>> getFamilyCollaborativeTasks(
      String familyId) {
    return _db
        .collection('collaborative_tasks')
        .where('familyId', isEqualTo: familyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => CollaborativeTaskModel.fromFirestore(doc))
            .toList());
  }

  Future<void> completeCollaborativeTask(String taskId, String userId) async {
    final taskRef = _db.collection('collaborative_tasks').doc(taskId);
    final taskSnap = await taskRef.get();

    if (!taskSnap.exists) return;

    final data = taskSnap.data();
    final rewards = data?['rewards'] as Map<String, dynamic>? ?? {};

    // منح المكافآت
    await _db.runTransaction((tx) async {
      // تحديث المهمة
      tx.update(taskRef, {
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'completedBy': userId,
      });

      // منح مكافآت للعائلة
      final familyRef = _db.collection('families').doc(data?['familyId']);
      tx.update(familyRef, {
        'familyGems': FieldValue.increment(rewards['familyGems'] ?? 0),
        'familyStars': FieldValue.increment(rewards['familyStars'] ?? 0),
      });
    });
  }

  // --- نظام المهام المتكررة (يومية/أسبوعية/شهرية) ---

  Future<String> createRecurringTask({
    required String familyId,
    required String familyName,
    required String title,
    required String description,
    required String frequency,
    required int targetValue,
    String? createdBy,
  }) async {
    final nextDueAt =
        RecurringTaskModel.calculateNextDueAt(frequency, Timestamp.now());

    final taskRef = await _db.collection('recurring_tasks').add({
      'familyId': familyId,
      'familyName': familyName,
      'title': title,
      'description': description,
      'frequency': frequency,
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
      'lastCompletedAt': null,
      'nextDueAt': nextDueAt,
      'targetValue': targetValue,
      'currentValue': 0,
      'rewards': RecurringTaskModel.getDefaultRewards(frequency),
      'completedBy': [],
      'streak': 0,
      'maxStreak': 0,
      'createdBy': createdBy,
    });

    return taskRef.id;
  }

  Future<void> addRecurringTaskContribution(String taskId, int value) async {
    final taskRef = _db.collection('recurring_tasks').doc(taskId);

    await _db.runTransaction((tx) async {
      final taskSnap = await tx.get(taskRef);
      if (!taskSnap.exists) return;

      final data = taskSnap.data();
      final currentValue = data?['currentValue'] ?? 0;
      final targetValue = data?['targetValue'] ?? 100;
      final newValue = currentValue + value;
      final newStatus =
          newValue >= targetValue ? 'completed' : data?['status'] ?? 'active';

      tx.update(taskRef, {
        'currentValue': newValue,
        'status': newStatus,
      });
    });
  }

  Future<void> completeRecurringTask(String taskId, String userId) async {
    final taskRef = _db.collection('recurring_tasks').doc(taskId);

    await _db.runTransaction((tx) async {
      final taskSnap = await tx.get(taskRef);
      if (!taskSnap.exists) return;

      final data = taskSnap.data();
      final completedBy = data?['completedBy'] as List<dynamic>? ?? [];
      final streak = data?['streak'] ?? 0;
      final maxStreak = data?['maxStreak'] ?? 0;
      final frequency = data?['frequency'] ?? 'daily';
      final rewards = data?['rewards'] as Map<String, dynamic>? ?? {};

      final newCompletedBy = List<dynamic>.from(completedBy);
      if (!newCompletedBy.contains(userId)) {
        newCompletedBy.add(userId);
      }

      final newStreak = streak + 1;
      final newMaxStreak = newStreak > maxStreak ? newStreak : maxStreak;
      final nextDueAt =
          RecurringTaskModel.calculateNextDueAt(frequency, Timestamp.now());

      // تحديث المهمة
      tx.update(taskRef, {
        'status': 'completed',
        'lastCompletedAt': FieldValue.serverTimestamp(),
        'nextDueAt': nextDueAt,
        'completedBy': newCompletedBy,
        'streak': newStreak,
        'maxStreak': newMaxStreak,
        'currentValue': data?['targetValue'] ?? 100,
      });

      // منح مكافآت للعائلة
      final familyRef = _db.collection('families').doc(data?['familyId']);
      tx.update(familyRef, {
        'familyGems': FieldValue.increment(rewards['familyGems'] ?? 0),
        'familyStars': FieldValue.increment(rewards['familyStars'] ?? 0),
      });
    });
  }

  Future<void> resetRecurringTask(String taskId) async {
    final taskRef = _db.collection('recurring_tasks').doc(taskId);

    await _db.runTransaction((tx) async {
      final taskSnap = await tx.get(taskRef);
      if (!taskSnap.exists) return;

      final data = taskSnap.data();
      final frequency = data?['frequency'] ?? 'daily';
      final streak = data?['streak'] ?? 0;
      final maxStreak = data?['maxStreak'] ?? 0;
      final nextDueAt =
          RecurringTaskModel.calculateNextDueAt(frequency, Timestamp.now());

      tx.update(taskRef, {
        'status': 'active',
        'currentValue': 0,
        'completedBy': [],
        'nextDueAt': nextDueAt,
        'streak': streak,
        'maxStreak': maxStreak,
      });
    });
  }

  Stream<List<RecurringTaskModel>> getFamilyRecurringTasks(String familyId) {
    return _db
        .collection('recurring_tasks')
        .where('familyId', isEqualTo: familyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => RecurringTaskModel.fromFirestore(doc))
            .toList());
  }

  Future<void> checkExpiredRecurringTasks() async {
    final now = Timestamp.now();
    final expiredTasks = await _db
        .collection('recurring_tasks')
        .where('status', isEqualTo: 'active')
        .where('nextDueAt', isLessThan: now)
        .get();

    final batch = _db.batch();

    for (final doc in expiredTasks.docs) {
      batch.update(doc.reference, {
        'status': 'expired',
        'streak': 0,
      });
    }

    await batch.commit();
  }

  // --- تحسين نظام الإشعارات - إشعارات فورية ---

  Future<void> sendInstantNotification({
    required String userId,
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
  }) async {
    await _db.collection('user_notifications').add({
      'userId': userId,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'data': data ?? {},
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
      'type': 'instant',
    });
  }

  Future<void> sendBulkInstantNotifications({
    required List<String> userIds,
    required String title,
    required String body,
    String? imageUrl,
    Map<String, dynamic>? data,
  }) async {
    final batch = _db.batch();

    for (final userId in userIds) {
      final notificationRef = _db.collection('user_notifications').doc();
      batch.set(notificationRef, {
        'userId': userId,
        'title': title,
        'body': body,
        'imageUrl': imageUrl,
        'data': data ?? {},
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'instant',
      });
    }

    await batch.commit();
  }

  Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) {
    return _db
        .collection('user_notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.data()).toList());
  }

  Future<void> markUserNotificationAsRead(String notificationId) async {
    await _db.collection('user_notifications').doc(notificationId).update({
      'read': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    final notifications = await _db
        .collection('user_notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();

    final batch = _db.batch();

    for (final doc in notifications.docs) {
      batch.update(doc.reference, {
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  Future<int> getUnreadNotificationCount(String userId) async {
    final snapshot = await _db
        .collection('user_notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .count()
        .get();

    return snapshot.count ?? 0;
  }

  // --- تحسين نظام الإشعارات - إعدادات مخصصة ---

  Future<void> updateNotificationSettings({
    required String userId,
    bool? enablePushNotifications,
    bool? enableEmailNotifications,
    bool? enableInAppNotifications,
    bool? enableSound,
    bool? enableVibration,
    Map<String, bool>? categoryPreferences,
  }) async {
    final settingsRef =
        _db.collection('user_notification_settings').doc(userId);

    final updateData = <String, dynamic>{};
    if (enablePushNotifications != null) {
      updateData['enablePushNotifications'] = enablePushNotifications;
    }
    if (enableEmailNotifications != null) {
      updateData['enableEmailNotifications'] = enableEmailNotifications;
    }
    if (enableInAppNotifications != null) {
      updateData['enableInAppNotifications'] = enableInAppNotifications;
    }
    if (enableSound != null) updateData['enableSound'] = enableSound;
    if (enableVibration != null) {
      updateData['enableVibration'] = enableVibration;
    }
    if (categoryPreferences != null) {
      updateData['categoryPreferences'] = categoryPreferences;
    }

    updateData['updatedAt'] = FieldValue.serverTimestamp();

    await settingsRef.set(updateData, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>> getNotificationSettings(String userId) async {
    final settingsSnap =
        await _db.collection('user_notification_settings').doc(userId).get();

    if (!settingsSnap.exists) {
      // إعدادات افتراضية
      return {
        'enablePushNotifications': true,
        'enableEmailNotifications': false,
        'enableInAppNotifications': true,
        'enableSound': true,
        'enableVibration': true,
        'categoryPreferences': {
          'family': true,
          'war': true,
          'alliance': true,
          'task': true,
          'reward': true,
        },
      };
    }

    return settingsSnap.data() ?? {};
  }

  Stream<Map<String, dynamic>> streamNotificationSettings(String userId) {
    return _db
        .collection('user_notification_settings')
        .doc(userId)
        .snapshots()
        .map((snap) =>
            snap.data() ??
            {
              'enablePushNotifications': true,
              'enableEmailNotifications': false,
              'enableInAppNotifications': true,
              'enableSound': true,
              'enableVibration': true,
              'categoryPreferences': {
                'family': true,
                'war': true,
                'alliance': true,
                'task': true,
                'reward': true,
              },
            });
  }

  Future<bool> shouldSendNotification(String userId, String category) async {
    final settings = await getNotificationSettings(userId);
    final categoryPreferences =
        settings['categoryPreferences'] as Map<String, dynamic>? ?? {};
    final enableInApp = settings['enableInAppNotifications'] as bool? ?? true;

    return enableInApp && (categoryPreferences[category] as bool? ?? true);
  }

  // --- تفعيل نظام الأحداث - تذكيرات للأحداث ---

  Future<void> sendEventReminders(String familyId) async {
    final now = Timestamp.now();
    final upcomingEvents = await _db
        .collection('family_events')
        .where('familyId', isEqualTo: familyId)
        .where('startTime', isGreaterThan: now)
        .where('startTime',
            isLessThan: Timestamp.fromDate(
                DateTime.now().add(const Duration(hours: 24))))
        .get();

    for (final eventDoc in upcomingEvents.docs) {
      final event = eventDoc.data();
      final participants = event['participants'] as List<dynamic>? ?? [];
      final eventTitle = event['title'] ?? 'حدث';
      final eventTime = event['startTime'] as Timestamp?;

      if (eventTime != null) {
        final timeDiff = eventTime.toDate().difference(DateTime.now());
        final hoursUntil = timeDiff.inHours;

        for (final participantId in participants) {
          final userId = participantId as String;

          String reminderMessage;
          if (hoursUntil < 1) {
            reminderMessage = 'تذكير: الحدث "$eventTitle" سيبدأ قريباً!';
          } else if (hoursUntil < 24) {
            reminderMessage =
                'تذكير: الحدث "$eventTitle" سيبدأ خلال $hoursUntil ساعة.';
          } else {
            reminderMessage = 'تذكير: الحدث "$eventTitle" سيبدأ غداً.';
          }

          await sendInstantNotification(
            userId: userId,
            title: 'تذكير بحدث',
            body: reminderMessage,
            data: {
              'type': 'event_reminder',
              'eventId': eventDoc.id,
              'eventTitle': eventTitle,
            },
          );
        }
      }
    }
  }

  Future<void> scheduleEventReminder(
      String eventId, String userId, Duration beforeEvent) async {
    final eventDoc = await _db.collection('family_events').doc(eventId).get();
    if (!eventDoc.exists) return;

    final event = eventDoc.data();
    final startTime = event?['startTime'] as Timestamp?;
    if (startTime == null) return;

    final reminderTime = startTime.toDate().subtract(beforeEvent);
    final now = DateTime.now();

    if (reminderTime.isAfter(now)) {
      // في التطبيق الحقيقي، سيتم استخدام Cloud Functions أو Cloud Scheduler
      // هنا سنحفظ التذكير في Firestore ليتم معالجته لاحقاً
      await _db.collection('event_reminders').add({
        'eventId': eventId,
        'userId': userId,
        'reminderTime': Timestamp.fromDate(reminderTime),
        'status': 'scheduled',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> cancelEventReminder(String reminderId) async {
    await _db.collection('event_reminders').doc(reminderId).update({
      'status': 'cancelled',
      'cancelledAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> getUserEventReminders(String userId) {
    return _db
        .collection('event_reminders')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'scheduled')
        .orderBy('reminderTime')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.data()).toList());
  }

  // --- نظام التوصيات الذكية ---

  // اقتراح حروب مناسبة بناءً على مستوى العائلة
  Future<List<Map<String, dynamic>>> getWarRecommendations(
      String familyId) async {
    final familyDoc = await _db.collection('families').doc(familyId).get();
    if (!familyDoc.exists) return [];

    final familyData = familyDoc.data();
    final familyLevel = familyData?['level'] ?? 1;
    final familyPoints = familyData?['totalPoints'] ?? 0;
    final memberCount = familyData?['memberCount'] ?? 0;

    // الحصول على العائلات الأخرى
    final otherFamilies = await _db
        .collection('families')
        .where(FieldPath.documentId, isNotEqualTo: familyId)
        .get();

    final recommendations = <Map<String, dynamic>>[];

    for (final otherFamilyDoc in otherFamilies.docs) {
      final otherFamilyData = otherFamilyDoc.data();
      final otherFamilyId = otherFamilyDoc.id;
      final otherFamilyName = otherFamilyData['name'] ?? 'غير معروف';
      final otherFamilyLevel = otherFamilyData['level'] ?? 1;
      final otherFamilyPoints = otherFamilyData['totalPoints'] ?? 0;
      final otherMemberCount = otherFamilyData['memberCount'] ?? 0;

      // حساب درجة التوصية
      double score = 0;
      final reasons = <String, dynamic>{};

      // مستوى العائلة يجب أن يكون قريباً
      final levelDiff = (familyLevel - otherFamilyLevel).abs();
      if (levelDiff <= 2) {
        score += 30;
        reasons['level_match'] = 'مستوى العائلة مناسب';
      } else if (levelDiff <= 5) {
        score += 15;
        reasons['level_match'] = 'مستوى العائلة مقبول';
      }

      // النقاط يجب أن تكون قريبة
      final pointsDiff = (familyPoints - otherFamilyPoints).abs();
      final pointsRatio = familyPoints > 0 ? pointsDiff / familyPoints : 1;
      if (pointsRatio < 0.2) {
        score += 30;
        reasons['points_match'] = 'النقاط متقاربة';
      } else if (pointsRatio < 0.5) {
        score += 15;
        reasons['points_match'] = 'النقاط مقبولة';
      }

      // عدد الأعضاء يجب أن يكون قريباً
      final memberDiff = (memberCount - otherMemberCount).abs();
      if (memberDiff <= 2) {
        score += 20;
        reasons['member_match'] = 'عدد الأعضاء مناسب';
      } else if (memberDiff <= 5) {
        score += 10;
        reasons['member_match'] = 'عدد الأعضاء مقبول';
      }

      // التحقق من عدم وجود حرب نشطة
      final activeWar = await _db
          .collection('family_wars')
          .where('familyId', isEqualTo: familyId)
          .where('enemyFamilyId', isEqualTo: otherFamilyId)
          .where('status', isEqualTo: 'active')
          .get();

      if (activeWar.docs.isEmpty) {
        score += 20;
        reasons['no_active_war'] = 'لا توجد حرب نشطة';
      }

      if (score >= 50) {
        recommendations.add({
          'type': 'war',
          'targetId': otherFamilyId,
          'targetName': otherFamilyName,
          'score': score,
          'reasons': reasons,
          'enemyLevel': otherFamilyLevel,
          'enemyPoints': otherFamilyPoints,
          'enemyMemberCount': otherMemberCount,
        });
      }
    }

    // ترتيب حسب الدرجة
    recommendations
        .sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

    return recommendations.take(5).toList();
  }

  // اقتراح تحالفات متوافقة
  Future<List<Map<String, dynamic>>> getAllianceRecommendations(
      String familyId) async {
    final familyDoc = await _db.collection('families').doc(familyId).get();
    if (!familyDoc.exists) return [];

    final familyData = familyDoc.data();
    final familyType = familyData?['type'] ?? 'general';

    // الحصول على التحالفات الموجودة للعائلة
    final currentAlliances = await _db
        .collection('family_alliances')
        .where('memberFamilyIds', arrayContains: familyId)
        .where('status', isEqualTo: 'active')
        .get();

    final currentAllianceIds =
        currentAlliances.docs.map((doc) => doc.id).toSet();

    // الحصول على التحالفات المتاحة
    final availableAlliances = await _db
        .collection('family_alliances')
        .where('status', isEqualTo: 'active')
        .get();

    final recommendations = <Map<String, dynamic>>[];

    for (final allianceDoc in availableAlliances.docs) {
      if (currentAllianceIds.contains(allianceDoc.id)) continue;

      final allianceData = allianceDoc.data();
      final allianceId = allianceDoc.id;
      final allianceName = allianceData['name'] ?? 'غير معروف';
      final allianceType = allianceData['allianceType'] ?? 'social';
      final memberFamilyIds =
          allianceData['memberFamilyIds'] as List<dynamic>? ?? [];
      final maxMembers = allianceData['maxMembers'] ?? 5;

      // حساب درجة التوصية
      double score = 0;
      final reasons = <String, dynamic>{};

      // نوع التحالف يجب أن يكون متوافقاً
      if (allianceType == familyType) {
        score += 40;
        reasons['type_match'] = 'نوع التحالف مناسب';
      }

      // عدد الأعضاء يجب أن يكون أقل من الحد الأقصى
      if (memberFamilyIds.length < maxMembers) {
        score += 30;
        reasons['space_available'] = 'يوجد مساحة للانضمام';
      }

      // التحقق من عدد التحالفات الحالي للعائلة
      if (currentAllianceIds.length < 2) {
        score += 30;
        reasons['alliance_limit'] = 'يمكن الانضمام للمزيد من التحالفات';
      }

      if (score >= 50) {
        recommendations.add({
          'type': 'alliance',
          'targetId': allianceId,
          'targetName': allianceName,
          'score': score,
          'reasons': reasons,
          'allianceType': allianceType,
          'currentMembers': memberFamilyIds.length,
          'maxMembers': maxMembers,
        });
      }
    }

    // ترتيب حسب الدرجة
    recommendations
        .sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

    return recommendations.take(5).toList();
  }

  // اقتراح مهام مناسبة لكل عضو
  Future<List<Map<String, dynamic>>> getTaskRecommendations(
      String familyId, String userId) async {
    final memberDoc = await _db
        .collection('families')
        .doc(familyId)
        .collection('members')
        .doc(userId)
        .get();

    if (!memberDoc.exists) return [];

    final memberData = memberDoc.data();
    final memberRank = memberData?['rankId'] ?? 'bronze';
    final contributionPoints = memberData?['contributionPoints'] ?? 0;

    final recommendations = <Map<String, dynamic>>[];

    // اقتراح مهام تعاونية
    final collaborativeTasks = await _db
        .collection('collaborative_tasks')
        .where('familyId', isEqualTo: familyId)
        .where('status', isEqualTo: 'pending')
        .get();

    for (final taskDoc in collaborativeTasks.docs) {
      final taskData = taskDoc.data();
      final taskId = taskDoc.id;
      final taskTitle = taskData['title'] ?? 'غير معروف';
      final taskType = taskData['type'] ?? 'team';
      final requiredParticipants = taskData['requiredParticipants'] ?? 3;
      final participantIds = taskData['participantIds'] as List<dynamic>? ?? [];

      // التحقق من عدم الانضمام مسبقاً
      if (participantIds.contains(userId)) continue;

      double score = 0;
      final reasons = <String, dynamic>{};

      // نوع المهمة مناسب للرتبة
      if (taskType == 'team' &&
          ['silver', 'gold', 'platinum'].contains(memberRank)) {
        score += 30;
        reasons['rank_suitable'] = 'المهمة مناسبة لرتبتك';
      } else if (taskType == 'war' &&
          ['platinum', 'diamond', 'royal'].contains(memberRank)) {
        score += 40;
        reasons['rank_suitable'] = 'المهمة مناسبة لرتبتك العالية';
      }

      // عدد المشاركين الحالي
      if (participantIds.length < requiredParticipants) {
        score += 30;
        reasons['needs_participants'] = 'المهمة تحتاج مشاركين';
      }

      // نقاط المساهمة
      if (contributionPoints > 1000) {
        score += 20;
        reasons['experienced'] = 'لديك خبرة كافية';
      }

      if (score >= 50) {
        recommendations.add({
          'type': 'task',
          'targetId': taskId,
          'targetName': taskTitle,
          'score': score,
          'reasons': reasons,
          'taskType': taskType,
          'currentParticipants': participantIds.length,
          'requiredParticipants': requiredParticipants,
        });
      }
    }

    // اقتراح مهام متكررة
    final recurringTasks = await _db
        .collection('recurring_tasks')
        .where('familyId', isEqualTo: familyId)
        .where('status', isEqualTo: 'active')
        .get();

    for (final taskDoc in recurringTasks.docs) {
      final taskData = taskDoc.data();
      final taskId = taskDoc.id;
      final taskTitle = taskData['title'] ?? 'غير معروف';
      final frequency = taskData['frequency'] ?? 'daily';
      final completedBy = taskData['completedBy'] as List<dynamic>? ?? [];

      // التحقق من عدم الإكمال اليوم
      if (completedBy.contains(userId)) continue;

      double score = 0;
      final reasons = <String, dynamic>{};

      // تكرار المهمة
      if (frequency == 'daily') {
        score += 30;
        reasons['daily_task'] = 'مهمة يومية';
      } else if (frequency == 'weekly') {
        score += 25;
        reasons['weekly_task'] = 'مهمة أسبوعية';
      }

      // الرتبة
      if (['gold', 'platinum', 'diamond', 'royal'].contains(memberRank)) {
        score += 20;
        reasons['rank_bonus'] = 'مكافأة إضافية لرتبتك';
      }

      if (score >= 50) {
        recommendations.add({
          'type': 'recurring_task',
          'targetId': taskId,
          'targetName': taskTitle,
          'score': score,
          'reasons': reasons,
          'frequency': frequency,
        });
      }
    }

    // ترتيب حسب الدرجة
    recommendations
        .sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));

    return recommendations.take(5).toList();
  }

  // حفظ التوصية في Firestore
  Future<void> saveRecommendation({
    required String familyId,
    required String type,
    required String targetId,
    required String targetName,
    required double score,
    required Map<String, dynamic> reasons,
  }) async {
    await _db.collection('recommendations').add({
      'type': type,
      'targetId': targetId,
      'targetName': targetName,
      'familyId': familyId,
      'score': score,
      'reasons': reasons,
      'createdAt': FieldValue.serverTimestamp(),
      'isViewed': false,
      'isAccepted': false,
    });
  }

  // الحصول على التوصيات للعائلة
  Stream<List<RecommendationModel>> getRecommendationsStream(String familyId) {
    return _db
        .collection('recommendations')
        .where('familyId', isEqualTo: familyId)
        .where('isViewed', isEqualTo: false)
        .orderBy('score', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => RecommendationModel.fromFirestore(doc))
            .toList());
  }

  // تحديد التوصية كمشاهدة
  Future<void> markRecommendationAsViewed(String recommendationId) async {
    await _db.collection('recommendations').doc(recommendationId).update({
      'isViewed': true,
      'viewedAt': FieldValue.serverTimestamp(),
    });
  }

  // قبول التوصية
  Future<void> acceptRecommendation(String recommendationId) async {
    await _db.collection('recommendations').doc(recommendationId).update({
      'isAccepted': true,
      'acceptedAt': FieldValue.serverTimestamp(),
    });
  }

  // --- نظام المكافآت التدريجية ---

  // المطالبة بالمكافأة اليومية المتصاعدة
  Future<Map<String, dynamic>> claimProgressiveDailyReward(
      String familyId, String userId) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول';

    // الحصول على سجل المكافآت التدريجية للمستخدم
    final rewardDoc = await _db
        .collection('progressive_rewards')
        .where('userId', isEqualTo: userId)
        .where('familyId', isEqualTo: familyId)
        .limit(1)
        .get();

    ProgressiveRewardModel? reward;

    if (rewardDoc.docs.isEmpty) {
      // إنشاء سجل جديد
      final newReward = ProgressiveRewardModel(
        id: '',
        userId: userId,
        familyId: familyId,
        consecutiveDays: 0,
        currentStreak: 0,
        maxStreak: 0,
        baseGems: 1,
        currentGems: 1,
        bonusMultiplier: 1,
        lastClaimDate: Timestamp.now(),
        nextClaimDate:
            Timestamp.fromDate(DateTime.now().add(const Duration(days: 1))),
        rewards: {},
      );

      final docRef =
          await _db.collection('progressive_rewards').add(newReward.toMap());
      reward = newReward.copyWith(id: docRef.id);
    } else {
      reward = ProgressiveRewardModel.fromFirestore(rewardDoc.docs.first);
    }

    // التحقق من إمكانية المطالبة
    if (!reward.canClaim) {
      throw 'لم يحين وقت المطالبة بعد';
    }

    // التحقق من كسر السلسلة
    int newStreak = reward.currentStreak;
    if (reward.isStreakBroken) {
      newStreak = 0; // إعادة تعيين السلسلة
    } else {
      newStreak += 1; // زيادة السلسلة
    }

    // حساب المكافآت
    final gems = ProgressiveRewardModel.calculateGemsForStreak(newStreak);
    final multiplier =
        ProgressiveRewardModel.calculateBonusMultiplier(newStreak);
    final totalGems = gems * multiplier;
    final stars = totalGems * 2;
    final newMaxStreak =
        newStreak > reward.maxStreak ? newStreak : reward.maxStreak;

    // تحديث سجل المكافآت
    await _db.collection('progressive_rewards').doc(reward.id).update({
      'consecutiveDays': reward.consecutiveDays + 1,
      'currentStreak': newStreak,
      'maxStreak': newMaxStreak,
      'baseGems': gems,
      'currentGems': totalGems,
      'bonusMultiplier': multiplier,
      'lastClaimDate': FieldValue.serverTimestamp(),
      'nextClaimDate':
          Timestamp.fromDate(DateTime.now().add(const Duration(days: 1))),
      'rewards': {
        'gems': totalGems,
        'stars': stars,
        'streak': newStreak,
        'multiplier': multiplier,
      },
    });

    // إضافة المكافآت للمستخدم
    await _db.collection('users').doc(userId).update({
      'gems': FieldValue.increment(totalGems),
      'stars': FieldValue.increment(stars),
    });

    // إضافة المكافآت للعائلة
    await _db.collection('families').doc(familyId).update({
      'totalGems': FieldValue.increment(totalGems),
      'totalStars': FieldValue.increment(stars),
    });

    return {
      'gems': totalGems,
      'stars': stars,
      'streak': newStreak,
      'maxStreak': newMaxStreak,
      'multiplier': multiplier,
      'nextClaim': DateTime.now().add(const Duration(days: 1)),
    };
  }

  // الحصول على سجل المكافآت التدريجية
  Future<ProgressiveRewardModel?> getProgressiveReward(
      String familyId, String userId) async {
    final rewardDoc = await _db
        .collection('progressive_rewards')
        .where('userId', isEqualTo: userId)
        .where('familyId', isEqualTo: familyId)
        .limit(1)
        .get();

    if (rewardDoc.docs.isEmpty) return null;

    return ProgressiveRewardModel.fromFirestore(rewardDoc.docs.first);
  }

  // الحصول على Stream للمكافآت التدريجية
  Stream<ProgressiveRewardModel?> getProgressiveRewardStream(
      String familyId, String userId) {
    return _db
        .collection('progressive_rewards')
        .where('userId', isEqualTo: userId)
        .where('familyId', isEqualTo: familyId)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      return ProgressiveRewardModel.fromFirestore(snap.docs.first);
    });
  }

  // إعادة تعيين السلسلة (عند كسرها)
  Future<void> resetProgressiveStreak(String familyId, String userId) async {
    final rewardDoc = await _db
        .collection('progressive_rewards')
        .where('userId', isEqualTo: userId)
        .where('familyId', isEqualTo: familyId)
        .limit(1)
        .get();

    if (rewardDoc.docs.isEmpty) return;

    await _db
        .collection('progressive_rewards')
        .doc(rewardDoc.docs.first.id)
        .update({
      'currentStreak': 0,
      'baseGems': 1,
      'currentGems': 1,
      'bonusMultiplier': 1,
    });
  }

  // --- نظام مكافآت الولاء ---

  // إضافة نقاط ولاء للمستخدم
  Future<void> addLoyaltyPoints(
      String familyId, String userId, int points) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول';

    await _db.runTransaction((tx) async {
      final userRef = _db.collection('users').doc(userId);
      final userSnap = await tx.get(userRef);

      if (!userSnap.exists) return;

      final currentPoints = userSnap.data()?['loyaltyPoints'] ?? 0;
      final newPoints = currentPoints + points;

      tx.update(userRef, {
        'loyaltyPoints': newPoints,
        'loyaltyPointsUpdatedAt': FieldValue.serverTimestamp(),
      });

      // التحقق من مستوى الولاء
      final loyaltyLevel = _calculateLoyaltyLevel(newPoints);
      tx.update(userRef, {'loyaltyLevel': loyaltyLevel});
    });
  }

  // حساب مستوى الولاء بناءً على النقاط
  int _calculateLoyaltyLevel(int points) {
    if (points >= 10000) return 5;
    if (points >= 5000) return 4;
    if (points >= 2500) return 3;
    if (points >= 1000) return 2;
    if (points >= 500) return 1;
    return 0;
  }

  // المطالبة بمكافأة الولاء
  Future<Map<String, dynamic>> claimLoyaltyReward(
      String familyId, String userId) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول';

    final userDoc = await _db.collection('users').doc(userId).get();
    if (!userDoc.exists) throw 'المستخدم غير موجود';

    final userData = userDoc.data();
    final loyaltyLevel = userData?['loyaltyLevel'] ?? 0;
    final lastClaim = userData?['loyaltyRewardLastClaim'] as Timestamp?;

    // التحقق من عدم المطالبة في الشهر الحالي
    if (lastClaim != null) {
      final now = DateTime.now();
      final lastClaimDate = lastClaim.toDate();
      if (now.year == lastClaimDate.year && now.month == lastClaimDate.month) {
        throw 'تم المطالبة بمكافأة الولاء هذا الشهر بالفعل';
      }
    }

    // حساب المكافأة بناءً على مستوى الولاء
    final rewards = _calculateLoyaltyRewards(loyaltyLevel);

    // تحديث المستخدم
    await _db.collection('users').doc(userId).update({
      'gems': FieldValue.increment(rewards['gems']),
      'stars': FieldValue.increment(rewards['stars']),
      'loyaltyRewardLastClaim': FieldValue.serverTimestamp(),
    });

    // إضافة للعائلة
    await _db.collection('families').doc(familyId).update({
      'totalGems': FieldValue.increment(rewards['gems']),
      'totalStars': FieldValue.increment(rewards['stars']),
    });

    return rewards;
  }

  // حساب مكافآت الولاء
  Map<String, dynamic> _calculateLoyaltyRewards(int level) {
    switch (level) {
      case 5:
        return {'gems': 500, 'stars': 1000};
      case 4:
        return {'gems': 300, 'stars': 600};
      case 3:
        return {'gems': 200, 'stars': 400};
      case 2:
        return {'gems': 100, 'stars': 200};
      case 1:
        return {'gems': 50, 'stars': 100};
      default:
        return {'gems': 10, 'stars': 20};
    }
  }

  // --- نظام مكافآت الإحالات ---

  // إنشاء رابط إحالة
  Future<String> createReferralLink(String familyId, String userId) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول';

    final referralCode =
        '${userId.substring(0, 8)}_${familyId.substring(0, 8)}';

    await _db.collection('referrals').doc(referralCode).set({
      'referrerId': userId,
      'familyId': familyId,
      'createdAt': FieldValue.serverTimestamp(),
      'totalReferrals': 0,
      'activeReferrals': 0,
    });

    return referralCode;
  }

  // استخدام رابط الإحالة
  Future<Map<String, dynamic>> useReferralLink(
      String referralCode, String newUserId) async {
    final referralDoc =
        await _db.collection('referrals').doc(referralCode).get();
    if (!referralDoc.exists) throw 'رابط الإحالة غير صالح';

    final referralData = referralDoc.data();
    final referrerId = referralData?['referrerId'];

    // إضافة مكافأة للمحيل
    await _db.collection('users').doc(referrerId).update({
      'gems': FieldValue.increment(5),
      'coins': FieldValue.increment(5),
      'stars': FieldValue.increment(5),
      'totalReferrals': FieldValue.increment(1),
    });

    // إضافة مكافأة للمحال
    await _db.collection('users').doc(newUserId).update({
      'gems': FieldValue.increment(5),
      'coins': FieldValue.increment(5),
      'stars': FieldValue.increment(5),
    });

    // تحديث سجل الإحالة
    await _db.collection('referrals').doc(referralCode).update({
      'totalReferrals': FieldValue.increment(1),
      'activeReferrals': FieldValue.increment(1),
    });

    return {
      'referrerGems': 5,
      'referrerCoins': 5,
      'referrerStars': 5,
      'refereeGems': 5,
      'refereeCoins': 5,
      'refereeStars': 5,
    };
  }

  // الحصول على إحصائيات الإحالة
  Future<Map<String, dynamic>> getReferralStats(String userId) async {
    final referralDocs = await _db
        .collection('referrals')
        .where('referrerId', isEqualTo: userId)
        .get();

    int totalReferrals = 0;
    int activeReferrals = 0;

    for (final doc in referralDocs.docs) {
      final data = doc.data();
      totalReferrals += (data['totalReferrals'] as num?)?.toInt() ?? 0;
      activeReferrals += (data['activeReferrals'] as num?)?.toInt() ?? 0;
    }

    return {
      'totalReferrals': totalReferrals,
      'activeReferrals': activeReferrals,
      'totalEarnedGems': totalReferrals * 5,
      'totalEarnedCoins': totalReferrals * 5,
      'totalEarnedStars': totalReferrals * 5,
    };
  }

  // --- نظام التخصيص ---

  // إنشاء تخصيص جديد للعائلة
  Future<String> createFamilyCustomization({
    required String familyId,
    String theme = 'dark',
    String? primaryColor,
    String? secondaryColor,
    String? logoUrl,
    String? bannerUrl,
    Map<String, dynamic>? customSettings,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول';

    // استخدام الألوان الافتراضية للموضوع إذا لم يتم تحديدها
    final themeSettings =
        FamilyCustomizationModel.getDefaultThemeSettings(theme);
    final finalPrimaryColor =
        primaryColor ?? themeSettings['primaryColor'] as String;
    final finalSecondaryColor =
        secondaryColor ?? themeSettings['secondaryColor'] as String;
    final finalCustomSettings = customSettings ?? themeSettings;

    final customization = FamilyCustomizationModel(
      id: '',
      familyId: familyId,
      theme: theme,
      primaryColor: finalPrimaryColor,
      secondaryColor: finalSecondaryColor,
      logoUrl: logoUrl,
      bannerUrl: bannerUrl,
      customSettings: finalCustomSettings,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    );

    final docRef = await _db
        .collection('family_customizations')
        .add(customization.toMap());

    // تحديث العائلة بمعرف التخصيص
    await _db.collection('families').doc(familyId).update({
      'customizationId': docRef.id,
    });

    return docRef.id;
  }

  // تحديث تخصيص العائلة
  Future<void> updateFamilyCustomization({
    required String customizationId,
    String? theme,
    String? primaryColor,
    String? secondaryColor,
    String? logoUrl,
    String? bannerUrl,
    Map<String, dynamic>? customSettings,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول';

    final updateData = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (theme != null) {
      updateData['theme'] = theme;
      // تحديث الألوان الافتراضية للموضوع الجديد
      final themeSettings =
          FamilyCustomizationModel.getDefaultThemeSettings(theme);
      updateData['primaryColor'] = themeSettings['primaryColor'];
      updateData['secondaryColor'] = themeSettings['secondaryColor'];
      updateData['customSettings'] = themeSettings;
    }

    if (primaryColor != null) updateData['primaryColor'] = primaryColor;
    if (secondaryColor != null) updateData['secondaryColor'] = secondaryColor;
    if (logoUrl != null) updateData['logoUrl'] = logoUrl;
    if (bannerUrl != null) updateData['bannerUrl'] = bannerUrl;
    if (customSettings != null) updateData['customSettings'] = customSettings;

    await _db
        .collection('family_customizations')
        .doc(customizationId)
        .update(updateData);
  }

  // الحصول على تخصيص العائلة
  Future<FamilyCustomizationModel?> getFamilyCustomization(
      String familyId) async {
    final familyDoc = await _db.collection('families').doc(familyId).get();
    if (!familyDoc.exists) return null;

    final familyData = familyDoc.data();
    final customizationId = familyData?['customizationId'];

    if (customizationId == null) return null;

    final customizationDoc = await _db
        .collection('family_customizations')
        .doc(customizationId)
        .get();
    if (!customizationDoc.exists) return null;

    return FamilyCustomizationModel.fromFirestore(customizationDoc);
  }

  // الحصول على Stream لتخصيص العائلة
  Stream<FamilyCustomizationModel?> getFamilyCustomizationStream(
      String familyId) {
    return _db
        .collection('families')
        .doc(familyId)
        .snapshots()
        .asyncMap((familyDoc) async {
      if (!familyDoc.exists) return null;

      final familyData = familyDoc.data();
      final customizationId = familyData?['customizationId'];

      if (customizationId == null) return null;

      final customizationDoc = await _db
          .collection('family_customizations')
          .doc(customizationId)
          .get();
      if (!customizationDoc.exists) return null;

      return FamilyCustomizationModel.fromFirestore(customizationDoc);
    });
  }

  // تغيير موضوع العائلة
  Future<void> changeFamilyTheme(String familyId, String theme) async {
    final customization = await getFamilyCustomization(familyId);
    if (customization == null) {
      // إنشاء تخصيص جديد
      await createFamilyCustomization(familyId: familyId, theme: theme);
    } else {
      // تحديث التخصيص الموجود
      await updateFamilyCustomization(
        customizationId: customization.id,
        theme: theme,
      );
    }
  }

  // تحديث شعار العائلة (التخصيص)
  Future<void> updateFamilyCustomizationLogo(
      String familyId, String logoUrl) async {
    final customization = await getFamilyCustomization(familyId);
    if (customization == null) {
      await createFamilyCustomization(familyId: familyId, logoUrl: logoUrl);
    } else {
      await updateFamilyCustomization(
        customizationId: customization.id,
        logoUrl: logoUrl,
      );
    }
  }

  // تحديث بانر العائلة
  Future<void> updateFamilyBanner(String familyId, String bannerUrl) async {
    final customization = await getFamilyCustomization(familyId);
    if (customization == null) {
      await createFamilyCustomization(familyId: familyId, bannerUrl: bannerUrl);
    } else {
      await updateFamilyCustomization(
        customizationId: customization.id,
        bannerUrl: bannerUrl,
      );
    }
  }

  // الحصول على المواضيع المتاحة
  List<Map<String, dynamic>> getAvailableThemes() {
    return [
      {
        'id': 'dark',
        'name': 'داكن',
        'nameEn': 'Dark',
        'icon': '🌙',
        'settings': FamilyCustomizationModel.getDefaultThemeSettings('dark'),
      },
      {
        'id': 'light',
        'name': 'فاتح',
        'nameEn': 'Light',
        'icon': '☀️',
        'settings': FamilyCustomizationModel.getDefaultThemeSettings('light'),
      },
      {
        'id': 'royal',
        'name': 'ملكي',
        'nameEn': 'Royal',
        'icon': '👑',
        'settings': FamilyCustomizationModel.getDefaultThemeSettings('royal'),
      },
      {
        'id': 'nature',
        'name': 'طبيعي',
        'nameEn': 'Nature',
        'icon': '🌿',
        'settings': FamilyCustomizationModel.getDefaultThemeSettings('nature'),
      },
      {
        'id': 'ocean',
        'name': 'بحري',
        'nameEn': 'Ocean',
        'icon': '🌊',
        'settings': FamilyCustomizationModel.getDefaultThemeSettings('ocean'),
      },
    ];
  }

  // --- نظام الدردشة المحسّن ---

  // إرسال رسالة مع ردود فعل
  Future<void> sendEnhancedChatMessage({
    required String familyId,
    required String senderId,
    required String senderName,
    required String message,
    bool isDisappearing = false,
    Duration? disappearAfter,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول';

    Timestamp? disappearAt;
    if (isDisappearing && disappearAfter != null) {
      disappearAt = Timestamp.fromDate(DateTime.now().add(disappearAfter));
    }

    await _db.collection('family_chat').add({
      'familyId': familyId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'reactions': [],
      'isDisappearing': isDisappearing,
      'disappearAt': disappearAt,
      'isDeleted': false,
      'metadata': {},
    });
  }

  // إضافة رد فعل لرسالة
  Future<void> addMessageReaction(String messageId, String emoji) async {
    final messageDoc = await _db.collection('family_chat').doc(messageId).get();
    if (!messageDoc.exists) throw 'الرسالة غير موجودة';

    final messageData = messageDoc.data();
    final reactions = messageData?['reactions'] as List<dynamic>? ?? [];

    if (!reactions.contains(emoji)) {
      await _db.collection('family_chat').doc(messageId).update({
        'reactions': FieldValue.arrayUnion([emoji]),
      });
    }
  }

  // إزالة رد فعل من رسالة
  Future<void> removeMessageReaction(String messageId, String emoji) async {
    await _db.collection('family_chat').doc(messageId).update({
      'reactions': FieldValue.arrayRemove([emoji]),
    });
  }

  // حذف رسالة
  Future<void> deleteMessage(String messageId) async {
    await _db.collection('family_chat').doc(messageId).update({
      'isDeleted': true,
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }

  // الحصول على رسائل الدردشة
  Stream<List<EnhancedChatMessageModel>> getFamilyChatMessages(
      String familyId) {
    return _db
        .collection('family_chat')
        .where('familyId', isEqualTo: familyId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => EnhancedChatMessageModel.fromFirestore(doc))
            .where((msg) => !msg.isExpired)
            .toList());
  }

  // --- نظام الغرف الصوتية ---

  // إنشاء غرفة صوتية
  Future<String> createVoiceRoom({
    required String familyId,
    required String name,
    required String description,
    required String createdBy,
    int maxParticipants = 10,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول';

    final room = VoiceRoomModel(
      id: '',
      familyId: familyId,
      name: name,
      description: description,
      createdBy: createdBy,
      participants: [createdBy],
      createdAt: Timestamp.now(),
      isActive: true,
      maxParticipants: maxParticipants,
      settings: {},
    );

    final docRef = await _db.collection('voice_rooms').add(room.toMap());
    return docRef.id;
  }

  // الانضمام لغرفة صوتية
  Future<void> joinVoiceRoom(String roomId, String userId) async {
    final roomDoc = await _db.collection('voice_rooms').doc(roomId).get();
    if (!roomDoc.exists) throw 'الغرفة غير موجودة';

    final roomData = roomDoc.data();
    final isActive = roomData?['isActive'] ?? false;
    final participants = roomData?['participants'] as List<dynamic>? ?? [];
    final maxParticipants = roomData?['maxParticipants'] ?? 10;

    if (!isActive) throw 'الغرفة غير نشطة';
    if (participants.length >= maxParticipants) throw 'الغرفة ممتلئة';
    if (participants.contains(userId)) throw 'أنت بالفعل في الغرفة';

    await _db.collection('voice_rooms').doc(roomId).update({
      'participants': FieldValue.arrayUnion([userId]),
    });
  }

  // مغادرة غرفة صوتية
  Future<void> leaveVoiceRoom(String roomId, String userId) async {
    await _db.collection('voice_rooms').doc(roomId).update({
      'participants': FieldValue.arrayRemove([userId]),
    });
  }

  // تحديث المتحدث النشط
  Future<void> updateActiveSpeaker(String roomId, String? speakerId) async {
    await _db.collection('voice_rooms').doc(roomId).update({
      'activeSpeaker': speakerId,
    });
  }

  // إنهاء غرفة صوتية
  Future<void> endVoiceRoom(String roomId) async {
    await _db.collection('voice_rooms').doc(roomId).update({
      'isActive': false,
      'endedAt': FieldValue.serverTimestamp(),
    });
  }

  // الحصول على الغرف الصوتية للعائلة
  Stream<List<VoiceRoomModel>> getFamilyVoiceRooms(String familyId) {
    return _db
        .collection('voice_rooms')
        .where('familyId', isEqualTo: familyId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => VoiceRoomModel.fromFirestore(doc)).toList());
  }

  // الحصول على Stream لغرفة صوتية محددة
  Stream<VoiceRoomModel?> getVoiceRoomStream(String roomId) {
    return _db.collection('voice_rooms').doc(roomId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return VoiceRoomModel.fromFirestore(doc);
    });
  }

  // --- نظام الألعاب المصغرة ---

  // إنشاء لعبة مصغرة
  Future<String> createMiniGame({
    required String familyId,
    required String name,
    required String nameAr,
    required String type,
    required String description,
    required Map<String, dynamic> gameData,
    int maxPlayers = 2,
    required String createdBy,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول';

    final game = MiniGameModel(
      id: '',
      familyId: familyId,
      name: name,
      nameAr: nameAr,
      type: type,
      description: description,
      gameData: gameData,
      maxPlayers: maxPlayers,
      currentPlayers: 0,
      createdBy: createdBy,
      createdAt: Timestamp.now(),
      isActive: true,
      results: {},
    );

    final docRef = await _db.collection('mini_games').add(game.toMap());
    return docRef.id;
  }

  // الانضمام للعبة
  Future<void> joinMiniGame(String gameId, String userId) async {
    final gameDoc = await _db.collection('mini_games').doc(gameId).get();
    if (!gameDoc.exists) throw 'اللعبة غير موجودة';

    final gameData = gameDoc.data();
    final isActive = gameData?['isActive'] ?? false;
    final currentPlayers = gameData?['currentPlayers'] ?? 0;
    final maxPlayers = gameData?['maxPlayers'] ?? 2;

    if (!isActive) throw 'اللعبة غير نشطة';
    if (currentPlayers >= maxPlayers) throw 'اللعبة ممتلئة';

    await _db.collection('mini_games').doc(gameId).update({
      'currentPlayers': FieldValue.increment(1),
    });
  }

  // بدء اللعبة
  Future<void> startMiniGame(String gameId) async {
    await _db.collection('mini_games').doc(gameId).update({
      'startedAt': FieldValue.serverTimestamp(),
    });
  }

  // إنهاء اللعبة
  Future<void> endMiniGame(String gameId, Map<String, dynamic> results) async {
    await _db.collection('mini_games').doc(gameId).update({
      'isActive': false,
      'endedAt': FieldValue.serverTimestamp(),
      'results': results,
    });
  }

  // الحصول على ألعاب العائلة
  Stream<List<MiniGameModel>> getFamilyMiniGames(String familyId) {
    return _db
        .collection('mini_games')
        .where('familyId', isEqualTo: familyId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => MiniGameModel.fromFirestore(doc)).toList());
  }

  // --- نظام التحديات اليومية ---

  // إنشاء تحدي يومي
  Future<String> createDailyChallenge({
    required String familyId,
    required String title,
    required String titleAr,
    required String description,
    required String type,
    required int targetValue,
    required Map<String, dynamic> rewards,
    Duration duration = const Duration(days: 1),
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw 'يجب تسجيل الدخول';

    final challenge = DailyChallengeModel(
      id: '',
      familyId: familyId,
      title: title,
      titleAr: titleAr,
      description: description,
      type: type,
      targetValue: targetValue,
      currentValue: 0,
      startDate: Timestamp.now(),
      endDate: Timestamp.fromDate(DateTime.now().add(duration)),
      rewards: rewards,
      completedBy: [],
      isActive: true,
    );

    final docRef =
        await _db.collection('daily_challenges').add(challenge.toMap());
    return docRef.id;
  }

  // إضافة تقدم للتحدي
  Future<void> addChallengeProgress(String challengeId, int value) async {
    await _db.collection('daily_challenges').doc(challengeId).update({
      'currentValue': FieldValue.increment(value),
    });
  }

  // إكمال التحدي
  Future<void> completeChallenge(String challengeId, String userId) async {
    await _db.collection('daily_challenges').doc(challengeId).update({
      'completedBy': FieldValue.arrayUnion([userId]),
    });
  }

  // الحصول على تحديات العائلة
  Stream<List<DailyChallengeModel>> getFamilyDailyChallenges(String familyId) {
    return _db
        .collection('daily_challenges')
        .where('familyId', isEqualTo: familyId)
        .where('isActive', isEqualTo: true)
        .where('endDate', isGreaterThan: Timestamp.now())
        .orderBy('endDate')
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => DailyChallengeModel.fromFirestore(doc))
            .toList());
  }

  // --- نظام بطاقات القيادة للألعاب ---

  // الحصول على بطاقة القيادة للعائلة
  Stream<List<Map<String, dynamic>>> getGameLeaderboard(String familyId) {
    return _db
        .collection('mini_games')
        .where('familyId', isEqualTo: familyId)
        .where('isActive', isEqualTo: false)
        .orderBy('endedAt', descending: true)
        .snapshots()
        .map((snap) {
      final leaderboard = <String, int>{};

      for (final doc in snap.docs) {
        final gameData = doc.data();
        final results = gameData['results'] as Map<String, dynamic>?;
        if (results != null) {
          results.forEach((userId, score) {
            leaderboard[userId] = (leaderboard[userId] ?? 0) + (score as int);
          });
        }
      }

      // تحويل إلى قائمة مرتبة
      final sortedList = leaderboard.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedList
          .map((e) => {'userId': e.key, 'score': e.value})
          .toList();
    });
  }

  // ========== نظام التوصيات الذكية ==========

  /// اقتراح حروب مناسبة بناءً على مستوى العائلة
  Future<List<Map<String, dynamic>>> suggestWars(String familyId) async {
    final familySnap = await _db.collection('families').doc(familyId).get();
    if (!familySnap.exists) return [];

    final family = familySnap.data()!;
    final myLevel = family['level'] ?? 1;
    final myExp = family['totalExp'] ?? 0;

    // البحث عن عوائل بمستوى مشابه (+/- 3 مستويات)
    final candidates = await _db
        .collection('families')
        .where('level', isGreaterThanOrEqualTo: myLevel - 3)
        .where('level', isLessThanOrEqualTo: myLevel + 3)
        .where('id', isNotEqualTo: familyId)
        .limit(10)
        .get();

    final suggestions = candidates.docs.map((doc) {
      final data = doc.data();
      final levelDiff = (data['level'] as num? ?? 1).toInt() - myLevel;
      final expDiff = (data['totalExp'] as num? ?? 0).toInt() - myExp;

      return {
        'familyId': doc.id,
        'familyName': data['name'] ?? '',
        'familyLogo': data['logoUrl'] ?? '',
        'level': data['level'] ?? 1,
        'levelDiff': levelDiff,
        'expDiff': expDiff,
        'winProbability': _calculateWinProbability(levelDiff, expDiff),
        'recommended': (levelDiff.abs() <= 1 && expDiff.abs() <= 5000),
      };
    }).toList();

    // ترتيب حسب الاحتمالية
    suggestions.sort((a, b) => (b['winProbability'] as double)
        .compareTo(a['winProbability'] as double));

    return suggestions.take(5).toList();
  }

  double _calculateWinProbability(num levelDiff, num expDiff) {
    // حساب احتمالية الفوز بناءً على فرق المستوى والخبرة
    double score = 0.5; // 50% افتراضي

    if (levelDiff < 0) score += 0.1 * levelDiff.abs(); // مستوى أقل = فرصة أعلى
    if (levelDiff > 0) score -= 0.1 * levelDiff; // مستوى أعلى = فرصة أقل

    if (expDiff < 0) {
      score += 0.05 * (expDiff.abs() / 1000); // خبرة أقل = فرصة أعلى
    }
    if (expDiff > 0) score -= 0.05 * (expDiff / 1000); // خبرة أعلى = فرصة أقل

    return score.clamp(0.1, 0.9);
  }

  /// اقتراح تحالفات متوافقة
  Future<List<Map<String, dynamic>>> suggestAlliances(String familyId) async {
    final familySnap = await _db.collection('families').doc(familyId).get();
    if (!familySnap.exists) return [];

    final family = familySnap.data()!;
    final myLevel = family['level'] ?? 1;
    final myMemberCount = family['memberCount'] ?? 0;

    // البحث عن عوائل يمكن التحالف معها
    final candidates = await _db
        .collection('families')
        .where('level', isGreaterThanOrEqualTo: myLevel - 2)
        .where('level', isLessThanOrEqualTo: myLevel + 2)
        .where('id', isNotEqualTo: familyId)
        .limit(10)
        .get();

    final suggestions = candidates.docs.map((doc) {
      final data = doc.data();
      final levelDiff = (data['level'] as num? ?? 1).toInt() - myLevel;
      final memberDiff =
          (data['memberCount'] as num? ?? 0).toInt() - myMemberCount;

      return {
        'familyId': doc.id,
        'familyName': data['name'] ?? '',
        'familyLogo': data['logoUrl'] ?? '',
        'level': data['level'] ?? 1,
        'levelDiff': levelDiff,
        'memberCount': data['memberCount'] ?? 0,
        'compatibilityScore':
            _calculateAllianceCompatibility(levelDiff, memberDiff),
        'recommended': (levelDiff.abs() <= 1 && memberDiff.abs() <= 5),
      };
    }).toList();

    suggestions.sort((a, b) => (b['compatibilityScore'] as double)
        .compareTo(a['compatibilityScore'] as double));

    return suggestions.take(5).toList();
  }

  double _calculateAllianceCompatibility(num levelDiff, num memberDiff) {
    double score = 0.5;

    // مستوى مشابه = توافق أعلى
    if (levelDiff.abs() <= 1) {
      score += 0.3;
    } else if (levelDiff.abs() <= 2) score += 0.1;

    // عدد أعضاء مشابه = توافق أعلى
    if (memberDiff.abs() <= 5) {
      score += 0.2;
    } else if (memberDiff.abs() <= 10) score += 0.1;

    return score.clamp(0.1, 1.0);
  }

  /// اقتراح مهام مناسبة لكل عضو
  Future<List<Map<String, dynamic>>> suggestTasksForMember(
      String userId, String familyId) async {
    final userSnap = await _db.collection('users').doc(userId).get();
    if (!userSnap.exists) return [];

    final user = userSnap.data()!;
    final userLevel = user['level'] ?? 1;
    final userRole = user['familyRole'] ?? 'member';

    final familySnap = await _db.collection('families').doc(familyId).get();
    final familyLevel = familySnap.data()?['level'] ?? 1;

    final suggestions = <Map<String, dynamic>>[];

    // اقتراح مهام بناءً على المستوى
    if (userLevel <= 5) {
      suggestions.add({
        'type': 'beginner',
        'title': 'مهمة مبتدئ',
        'description': 'أكمل 5 مهام بسيطة',
        'rewardGems': 50,
        'rewardStars': 100,
        'difficulty': 'سهل',
        'recommended': true,
      });
    } else if (userLevel <= 15) {
      suggestions.add({
        'type': 'intermediate',
        'title': 'مهمة متوسطة',
        'description': 'أكمل 10 مهام متوسطة',
        'rewardGems': 100,
        'rewardStars': 200,
        'difficulty': 'متوسط',
        'recommended': true,
      });
    } else {
      suggestions.add({
        'type': 'advanced',
        'title': 'مهمة متقدمة',
        'description': 'أكمل 15 مهمة متقدمة',
        'rewardGems': 200,
        'rewardStars': 400,
        'difficulty': 'صعب',
        'recommended': true,
      });
    }

    // اقتراح مهام بناءً على الدور
    if (userRole == 'leader' || userRole == 'co-leader') {
      suggestions.add({
        'type': 'leadership',
        'title': 'قيادة العائلة',
        'description': 'وجه 5 أعضاء جدد',
        'rewardGems': 150,
        'rewardStars': 300,
        'difficulty': 'متوسط',
        'recommended': true,
      });
    } else if (userRole == 'recruiter') {
      suggestions.add({
        'type': 'recruitment',
        'title': 'تجنيد أعضاء',
        'description': 'جذب 3 أعضاء جدد',
        'rewardGems': 100,
        'rewardStars': 200,
        'difficulty': 'سهل',
        'recommended': true,
      });
    }

    // اقتراح مهام بناءً على مستوى العائلة
    if (familyLevel >= 10) {
      suggestions.add({
        'type': 'family_war',
        'title': 'المشاركة في الحرب',
        'description': 'ساهم في حرب عائلية',
        'rewardGems': 200,
        'rewardStars': 400,
        'difficulty': 'صعب',
        'recommended': true,
      });
    }

    return suggestions.take(3).toList();
  }

  // ========== نظام الإحصائيات المتقدمة ==========

  /// الحصول على إحصائيات العائلة المتقدمة
  Future<Map<String, dynamic>> getAdvancedFamilyStats(String familyId) async {
    final familySnap = await _db.collection('families').doc(familyId).get();
    if (!familySnap.exists) return {};

    final family = familySnap.data()!;
    final membersSnap = await _db
        .collection('users')
        .where('familyId', isEqualTo: familyId)
        .get();

    final members = membersSnap.docs;
    final totalMembers = members.length;
    final totalExp = members.fold<int>(
        0, (sum, doc) => sum + (doc.data()['totalExp'] as num? ?? 0).toInt());
    final totalGems = members.fold<int>(
        0, (sum, doc) => sum + (doc.data()['gems'] as num? ?? 0).toInt());

    // حساب النشاط الشهري
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 30));
    final activitySnap = await _db
        .collection('families')
        .doc(familyId)
        .collection('activity_log')
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(monthAgo))
        .get();

    final monthlyActivity = activitySnap.docs.length;

    return {
      'totalMembers': totalMembers,
      'totalExp': totalExp,
      'totalGems': totalGems,
      'averageExpPerMember': totalMembers > 0 ? totalExp / totalMembers : 0,
      'monthlyActivity': monthlyActivity,
      'activityRate': monthlyActivity / 30, // متوسط النشاط اليومي
      'familyLevel': family['level'] ?? 1,
      'familyGems': family['familyGems'] ?? 0,
      'familyStars': family['familyStars'] ?? 0,
    };
  }

  /// الحصول على مقارنة العائلة مع عائلات أخرى
  Future<Map<String, dynamic>> getFamilyComparison(String familyId) async {
    final myFamilySnap = await _db.collection('families').doc(familyId).get();
    if (!myFamilySnap.exists) return {};

    final myFamily = myFamilySnap.data()!;
    final myLevel = myFamily['level'] ?? 1;
    final myExp = myFamily['totalExp'] ?? 0;

    // الحصول على العوائل الأعلى
    final topFamilies = await _db
        .collection('families')
        .orderBy('totalExp', descending: true)
        .limit(10)
        .get();

    final myRank = topFamilies.docs.indexWhere((doc) => doc.id == familyId);

    return {
      'myLevel': myLevel,
      'myExp': myExp,
      'myRank': myRank >= 0 ? myRank + 1 : null,
      'totalFamilies': topFamilies.docs.length,
      'topFamilies': topFamilies.docs
          .map((doc) => {
                'id': doc.id,
                'name': doc.data()['name'],
                'level': doc.data()['level'],
                'exp': doc.data()['totalExp'],
              })
          .toList(),
    };
  }

  // ========== نظام المهام العائلية ==========

  /// الحصول على تيار المهام العائلية
  Stream<QuerySnapshot> streamFamilyTasks(String familyId) {
    return _db
        .collection('family_tasks_config')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ========== نظام الترشيحات والمقترحات ==========

  /// الحصول على تيار الترشيحات والمقترحات
  Stream<QuerySnapshot> streamFamilyNominations(String familyId) {
    return _db
        .collection('family_nominations')
        .where('familyId', isEqualTo: familyId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// إنشاء ترشيح جديد
  Future<void> createNomination({
    required String familyId,
    required String userId,
    required String type,
    required String title,
    required String description,
  }) async {
    await _db.collection('family_nominations').add({
      'familyId': familyId,
      'createdBy': userId,
      'type': type,
      'title': title,
      'description': description,
      'votes': {},
      'status': 'active',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// التصويت على ترشيح
  Future<void> voteOnNomination({
    required String nominationId,
    required String userId,
    required bool approve,
  }) async {
    final nominationRef =
        _db.collection('family_nominations').doc(nominationId);
    await nominationRef.update({
      'votes.$userId': approve ? 'approve' : 'reject',
    });
  }

  // ========== نظام الأرشيف العائلي ==========

  /// الحصول على تيار الأرشيف العائلي
  Stream<QuerySnapshot> streamFamilyArchive(String familyId, String category) {
    Query query =
        _db.collection('family_archive').where('familyId', isEqualTo: familyId);

    if (category != 'all') {
      query = query.where('category', isEqualTo: category);
    }

    return query.orderBy('archivedAt', descending: true).snapshots();
  }

  /// أرشفة عنصر (حرب، حدث، تصويت، مهمة)
  Future<void> archiveItem({
    required String familyId,
    required String category,
    required Map<String, dynamic> itemData,
  }) async {
    await _db.collection('family_archive').add({
      'familyId': familyId,
      'category': category,
      'data': itemData,
      'archivedAt': FieldValue.serverTimestamp(),
    });
  }
}
