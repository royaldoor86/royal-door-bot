import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/user_model.dart';
import '../models/post_model.dart';
import '../models/story_model.dart';
import '../models/chat_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- نظام الإشعارات والتحقق للبوت (الميزات الجديدة) ---
  Future<void> sendBotNotification(String tgId, String message) async {
    if (tgId.isEmpty) return;
    await _db.collection('bot_notifications').add({
      'telegramId': tgId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<String> generateVerificationCode(String uid) async {
    String code = (Random().nextInt(9000) + 1000).toString();
    await _db.collection('users').doc(uid).update({
      'verificationCode': code,
    });
    return code;
  }

  // --- إدارة العوائل الملكية ---
  Stream<List<Map<String, dynamic>>> streamAllFamilies() {
    return _db.collection('families').orderBy('level', descending: true).snapshots().map((snapshot) => snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  Future<void> joinFamily(String familyId, String userId) async {
    final batch = _db.batch();
    batch.update(_db.collection('families').doc(familyId), {'membersCount': FieldValue.increment(1)});
    batch.update(_db.collection('users').doc(userId), {'familyId': familyId, 'familyRole': 'member'});
    await batch.commit();
  }

  Future<void> leaveFamily(String familyId, String userId) async {
    final batch = _db.batch();
    batch.update(_db.collection('families').doc(familyId), {'membersCount': FieldValue.increment(-1)});
    batch.update(_db.collection('users').doc(userId), {'familyId': FieldValue.delete(), 'familyRole': FieldValue.delete()});
    await batch.commit();
  }

  // --- إدارة الغرف الصوتية ---
  Stream<List<Map<String, dynamic>>> streamRooms() {
    return _db.collection('rooms').orderBy('createdAt', descending: true).snapshots().map((snapshot) => snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  Future<String> createRoom({
    required String ownerId,
    required String roomName,
    String? roomImage,
  }) async {
    final roomRef = _db.collection('rooms').doc();
    await roomRef.set({
      'ownerId': ownerId,
      'name': roomName,
      'image': roomImage ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'membersCount': 1,
      'activeMics': {},
      'membershipFee': 0,
      'isLocked': false,
    });
    return roomRef.id;
  }

  // البحث عن مستخدم بواسطة الايدي الملكي
  Future<UserModel?> getUserByRoyalId(String royalId) async {
    final snap = await _db.collection('users').where('royalId', isEqualTo: royalId).limit(1).get();
    if (snap.docs.isNotEmpty) {
      return UserModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
    }
    return null;
  }

  // --- نظام الهدايا المطور ---
  Future<void> sendGiftInChat({
    required String roomId,
    required String senderId,
    required String receiverId,
    required Map<String, dynamic> gift,
    String? receiverTgId,
  }) async {
    final batch = _db.batch();
    int price = gift['price'];

    batch.update(_db.collection('users').doc(senderId), {'coins': FieldValue.increment(-price)});
    batch.update(_db.collection('users').doc(receiverId), {'gems': FieldValue.increment((price * 0.5).toInt())});

    if (receiverTgId != null) {
      await sendBotNotification(receiverTgId, "🎁 تهانينا! لقد تلقيت هدية '${gift['name']}' في التطبيق!");
    }

    final msgRef = _db.collection('chatRooms').doc(roomId).collection('messages').doc();
    final giftMessage = MessageModel(
      id: '',
      senderId: senderId,
      text: 'أرسل هدية: ${gift['name']} 🎁',
      giftId: gift['id'],
      giftName: gift['name'],
      giftImage: gift['image'],
      giftPrice: price,
      timestamp: DateTime.now(),
    );
    batch.set(msgRef, giftMessage.toMap());
    await batch.commit();
  }

  Stream<UserModel> streamUserData(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snap) => UserModel.fromMap(snap.data() ?? {}, snap.id));
  }

  Future<void> saveUser(UserModel user) {
    return _db.collection('users').doc(user.uid).set(user.toMap(), SetOptions(merge: true));
  }

  Future<void> updateSingleField(String uid, String field, dynamic value) {
    return _db.collection('users').doc(uid).update({field: value});
  }

  Stream<List<ChatRoomModel>> streamChatRooms(String userId) {
    return _db.collection('chatRooms').where('participants', arrayContains: userId).orderBy('lastMessageTime', descending: true).snapshots().map((snapshot) => snapshot.docs.map((doc) => ChatRoomModel.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<List<MessageModel>> streamMessages(String roomId) {
    return _db.collection('chatRooms').doc(roomId).collection('messages').orderBy('timestamp', descending: true).snapshots().map((snapshot) => snapshot.docs.map((doc) => MessageModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> sendMessage(String roomId, MessageModel message) async {
    final batch = _db.batch();
    final msgRef = _db.collection('chatRooms').doc(roomId).collection('messages').doc();
    batch.set(msgRef, message.toMap());
    final roomRef = _db.collection('chatRooms').doc(roomId);
    batch.update(roomRef, {'lastMessage': message.text, 'lastMessageTime': FieldValue.serverTimestamp()});
    await batch.commit();
  }

  Stream<List<PostModel>> streamPosts() {
    return _db.collection('posts').orderBy('createdAt', descending: true).snapshots().map((snapshot) => snapshot.docs.map((doc) => PostModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> addPost(PostModel post) => _db.collection('posts').add(post.toMap());

  Future<void> toggleLike(String postId, String userId) async {
    final postRef = _db.collection('posts').doc(postId);
    final doc = await postRef.get();
    if (!doc.exists) return;
    List<String> likes = List<String>.from(doc.data()?['likes'] ?? []);
    likes.contains(userId) ? likes.remove(userId) : likes.add(userId);
    await postRef.update({'likes': likes});
  }

  Stream<List<StoryModel>> streamStories() {
    DateTime last24Hours = DateTime.now().subtract(const Duration(hours: 24));
    return _db.collection('stories').where('createdAt', isGreaterThan: last24Hours).orderBy('createdAt', descending: true).snapshots().map((snap) => snap.docs.map((doc) => StoryModel.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<List<UserModel>> streamVisitors(String uid) {
    return _db.collection('users').doc(uid).collection('visitors').orderBy('timestamp', descending: true).limit(50).snapshots().asyncMap((snap) async {
      List<UserModel> visitors = [];
      for (var doc in snap.docs) {
        var uDoc = await _db.collection('users').doc(doc.id).get();
        if (uDoc.exists) visitors.add(UserModel.fromMap(uDoc.data()!, uDoc.id));
      }
      return visitors;
    });
  }

  Stream<List<UserModel>> streamFriends(String uid) {
    return _db.collection('users').doc(uid).snapshots().asyncMap((snap) async {
      final data = UserModel.fromMap(snap.data() ?? {}, snap.id);
      final friendUids = data.following.where((id) => data.followers.contains(id)).toList();
      if (friendUids.isEmpty) return [];
      final usersSnap = await _db.collection('users').where(FieldPath.documentId, whereIn: friendUids.take(10).toList()).get();
      return usersSnap.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Stream<List<UserModel>> streamUsersFromList(List<String> uids) {
    if (uids.isEmpty) return Stream.value([]);
    return _db.collection('users').where(FieldPath.documentId, whereIn: uids.take(10).toList()).snapshots().map((snap) => snap.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<Map<String, dynamic>> getDailyRewardStatus(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data() ?? {};
    return {'lastClaimed': data['lastClaimedAt'] as Timestamp?, 'streak': data['rewardStreak'] ?? 0};
  }

  Stream<QuerySnapshot> streamActiveInvestments(String uid) => _db.collection('users').doc(uid).collection('investments').where('status', isEqualTo: 'active').snapshots();
}
