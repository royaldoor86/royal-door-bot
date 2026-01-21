import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  // ------------------------
  // Chats (Layer 2 - Lazy Initializer)
  // ------------------------
  static Future<String> startChat(String otherUid) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) throw Exception("User not logged in");

    // إنشاء ID موحد للمحادثة بين الطرفين دائماً نفس الـ ID
    List<String> ids = [currentUid, otherUid];
    ids.sort();
    String chatId = ids.join('_');

    final chatRef = _firestore.collection('chats').doc(chatId);
    final chatDoc = await chatRef.get();

    if (!chatDoc.exists) {
      // لا يتم إنشاء المحادثة فعلياً إلا عند أول رسالة أو تفاعل
      // هنا نقوم بتهيئة المستند الأساسي
      await chatRef.set({
        'participants': [currentUid, otherUid],
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': 'بدأت المحادثة الملكية ✨',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': {currentUid: 0, otherUid: 0},
      });
    }

    return chatId;
  }

  static Future<void> sendMessage({
    required String chatId,
    required String text,
    String? type = 'text',
  }) async {
    final currentUid = _auth.currentUser?.uid;
    if (currentUid == null) return;

    final batch = _firestore.batch();
    
    // 1. إضافة الرسالة إلى المجموعات الفرعية (messages/{chatId}/items)
    final msgRef = _firestore
        .collection('messages')
        .doc(chatId)
        .collection('items')
        .doc();

    batch.set(msgRef, {
      'senderId': currentUid,
      'text': text,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 2. تحديث مستند المحادثة الرئيسي
    final chatRef = _firestore.collection('chats').doc(chatId);
    batch.update(chatRef, {
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    await batch.commit();
  }
}
