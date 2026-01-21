import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/agency_model.dart';

class AgencyService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🏢 Agent: Get monthly report (total sales)
  Future<Map<String, dynamic>> getMonthlyReport(String agencyId) async {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);

    final salesQuery = await _db.collection('agent_sales')
        .where('agencyId', isEqualTo: agencyId)
        .where('createdAt', isGreaterThanOrEqualTo: firstDayOfMonth)
        .get();

    int totalGems = 0;
    int totalCoins = 0;
    int transactionCount = salesQuery.docs.length;

    for (var doc in salesQuery.docs) {
      final data = doc.data();
      if (data['currency'] == 'gems') {
        totalGems += (data['amount'] ?? 0) as int;
      } else if (data['currency'] == 'coins') {
        totalCoins += (data['amount'] ?? 0) as int;
      }
    }

    return {
      'totalGems': totalGems,
      'totalCoins': totalCoins,
      'count': transactionCount,
      'month': now.month,
      'year': now.year,
    };
  }

  /// 👑 Admin: Create a new agency by User ShortId
  Future<void> createAgencyByShortId({
    required String targetShortId,
    required String agencyName,
    required String logoUrl,
    required AgencyType type,
  }) async {
    final userQuery = await _db.collection('users')
        .where('shortId', isEqualTo: targetShortId.toUpperCase())
        .limit(1)
        .get();

    if (userQuery.docs.isEmpty) throw 'لم يتم العثور على مستخدم بهذا الـ ID';
    
    final userDoc = userQuery.docs.first;
    final targetUid = userDoc.id;
    final userData = userDoc.data();

    if (userData['isAgent'] == true) throw 'هذا المستخدم وكيل بالفعل';

    final agencyRef = _db.collection('agencies').doc();

    await _db.runTransaction((tx) async {
      tx.set(agencyRef, {
        'ownerId': targetUid,
        'ownerName': userData['displayName'] ?? 'وكيل ملكي',
        'name': agencyName,
        'logoUrl': logoUrl,
        'type': type == AgencyType.reseller ? 'reseller' : 'hosting',
        'balance': 0,
        'coinBalance': 0,
        'memberCount': 0,
        'commissionRate': 0.1,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      tx.update(userDoc.reference, {
        'isAgent': true,
        'agencyId': agencyRef.id,
        'agencyType': type == AgencyType.reseller ? 'reseller' : 'hosting',
      });
    });
  }

  /// 👑 Admin: Charge an agent's coin balance
  Future<void> chargeAgentCoins(String agencyId, int amount) async {
    await _db.collection('agencies').doc(agencyId).update({
      'coinBalance': FieldValue.increment(amount),
    });

    await _db.collection('agent_transactions').add({
      'agencyId': agencyId,
      'type': 'charge_coins',
      'amount': amount,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 🏢 Agent: Transfer coins to a user
  Future<void> transferCoinsToUser(String targetShortId, int amount) async {
    final agentUid = _auth.currentUser?.uid;
    if (agentUid == null) throw 'يجب تسجيل الدخول';

    final agentDoc = await _db.collection('users').doc(agentUid).get();
    final String? agencyId = agentDoc.data()?['agencyId'];
    final String agentName = agentDoc.data()?['displayName'] ?? 'وكيل رويال';
    final String agentAvatar = agentDoc.data()?['photoUrl'] ?? agentDoc.data()?['photoURL'] ?? '';
    
    if (agencyId == null) throw 'ليس لديك وكالة';

    final agencyRef = _db.collection('agencies').doc(agencyId);
    
    final userQuery = await _db.collection('users').where('shortId', isEqualTo: targetShortId.toUpperCase()).limit(1).get();
    if (userQuery.docs.isEmpty) throw 'لم يتم العثور على مستخدم بهذا الـ ID';
    final userDoc = userQuery.docs.first;

    await _db.runTransaction((tx) async {
      final agencySnap = await tx.get(agencyRef);
      if (!agencySnap.exists) throw 'الوكالة غير موجودة';
      
      final int currentCoins = (agencySnap.data()?['coinBalance'] ?? 0).toInt();
      if (currentCoins < amount) throw 'رصيد كوينز وكالتك غير كافٍ';

      tx.update(agencyRef, {'coinBalance': currentCoins - amount});
      tx.update(userDoc.reference, {'coins': FieldValue.increment(amount)});

      final saleRef = _db.collection('agent_sales').doc();
      tx.set(saleRef, {
        'agencyId': agencyId,
        'agentUid': agentUid,
        'targetUid': userDoc.id,
        'targetName': userDoc.data()['displayName'] ?? 'مستخدم',
        'amount': amount,
        'currency': 'coins',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // إرسال إشعار للمستلم (داخل الـ Transaction لضمان الوصول)
      final notifyRef = _db.collection('users').doc(userDoc.id).collection('notifications').doc();
      tx.set(notifyRef, {
        'title': "تم استلام كوينز 💰",
        'body': "قام الوكيل $agentName بتحويل $amount كوينز إليك.",
        'type': 'agency_charge',
        'senderId': agentUid,
        'senderName': agentName,
        'senderAvatar': agentAvatar,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// 👑 Admin: Update agency details
  Future<void> updateAgency(String agencyId, Map<String, dynamic> data) async {
    await _db.collection('agencies').doc(agencyId).update(data);
  }

  /// 👑 Admin: Toggle agency active status
  Future<void> toggleAgencyStatus(String agencyId, bool isActive) async {
    await _db.collection('agencies').doc(agencyId).update({'isActive': isActive});
  }

  /// 👑 Admin: Delete an agency
  Future<void> deleteAgency(String agencyId, String ownerId) async {
    await _db.runTransaction((tx) async {
      tx.delete(_db.collection('agencies').doc(agencyId));
      tx.update(_db.collection('users').doc(ownerId), {
        'isAgent': false,
        'agencyId': null,
        'agencyType': null,
      });
    });
  }

  /// 👑 Admin: Charge an agent's balance (Gems)
  Future<void> chargeAgentBalance(String agencyId, int amount) async {
    await _db.collection('agencies').doc(agencyId).update({
      'balance': FieldValue.increment(amount),
    });

    // Log the transaction
    await _db.collection('agent_transactions').add({
      'agencyId': agencyId,
      'type': 'charge',
      'amount': amount,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 🏢 Agent: Transfer gems to a user (For Reseller Agents)
  Future<void> transferGemsToUser(String targetShortId, int amount) async {
    final agentUid = _auth.currentUser?.uid;
    if (agentUid == null) throw 'يجب تسجيل الدخول';

    final agentDoc = await _db.collection('users').doc(agentUid).get();
    final String? agencyId = agentDoc.data()?['agencyId'];
    final String agentName = agentDoc.data()?['displayName'] ?? 'وكيل رويال';
    final String agentAvatar = agentDoc.data()?['photoUrl'] ?? agentDoc.data()?['photoURL'] ?? '';

    if (agencyId == null) throw 'ليس لديك وكالة';

    final agencyRef = _db.collection('agencies').doc(agencyId);
    
    final userQuery = await _db.collection('users').where('shortId', isEqualTo: targetShortId.toUpperCase()).limit(1).get();
    if (userQuery.docs.isEmpty) throw 'لم يتم العثور على مستخدم بهذا الـ ID';
    final userDoc = userQuery.docs.first;

    await _db.runTransaction((tx) async {
      final agencySnap = await tx.get(agencyRef);
      if (!agencySnap.exists) throw 'الوكالة غير موجودة';

      final int currentBalance = (agencySnap.data()?['balance'] ?? 0).toInt();
      if (currentBalance < amount) throw 'رصيد وكالتك غير كافٍ';

      tx.update(agencyRef, {'balance': currentBalance - amount});
      tx.update(userDoc.reference, {'gems': FieldValue.increment(amount)});

      final saleRef = _db.collection('agent_sales').doc();
      tx.set(saleRef, {
        'agencyId': agencyId,
        'agentUid': agentUid,
        'targetUid': userDoc.id,
        'targetName': userDoc.data()['displayName'] ?? 'مستخدم',
        'amount': amount,
        'currency': 'gems',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // إرسال إشعار للمستلم (داخل الـ Transaction)
      final notifyRef = _db.collection('users').doc(userDoc.id).collection('notifications').doc();
      tx.set(notifyRef, {
        'title': "تم استلام جواهر 💎",
        'body': "قام الوكيل $agentName بتحويل $amount جواهر إليك.",
        'type': 'agency_charge',
        'senderId': agentUid,
        'senderName': agentName,
        'senderAvatar': agentAvatar,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// 🏢 Agent: Add member to hosting agency
  Future<void> addMemberToAgency(String userShortId) async {
    final agentUid = _auth.currentUser?.uid;
    final agentDoc = await _db.collection('users').doc(agentUid).get();
    final String? agencyId = agentDoc.data()?['agencyId'];

    final userQuery = await _db.collection('users').where('shortId', isEqualTo: userShortId.toUpperCase()).limit(1).get();
    if (userQuery.docs.isEmpty) throw 'المستخدم غير موجود';
    final userDoc = userQuery.docs.first;

    if (userDoc.data()['agencyId'] != null) throw 'هذا المستخدم منضم لوكالة أخرى بالفعل';

    await _db.runTransaction((tx) async {
      tx.update(userDoc.reference, {'agencyId': agencyId});
      tx.update(_db.collection('agencies').doc(agencyId), {'memberCount': FieldValue.increment(1)});
      
      tx.set(_db.collection('agencies').doc(agencyId).collection('members').doc(userDoc.id), {
        'uid': userDoc.id,
        'joinedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Get current user's agency data
  Stream<AgencyModel?> watchMyAgency() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);

    return _db.collection('agencies').where('ownerId', isEqualTo: uid).limit(1).snapshots().map((snap) {
      if (snap.docs.isEmpty) return null;
      return AgencyModel.fromFirestore(snap.docs.first as DocumentSnapshot<Map<String, dynamic>>);
    });
  }
}
