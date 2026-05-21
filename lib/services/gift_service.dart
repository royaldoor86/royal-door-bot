import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'challenges_service.dart';

class GiftService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  // ------------------------
  // Gifts (Layer 2 - Hybrid)
  // ------------------------
  static Future<void> sendGift({
    required String receiverUid,
    required String giftId,
    required String giftName,
    required int price,
    String? giftImage,
  }) async {
    final senderUid = _auth.currentUser?.uid;
    if (senderUid == null) return;

    final batch = _firestore.batch();

    // 1. خصم من محفظة الراسل
    final senderWalletRef = _firestore.collection('wallets').doc(senderUid);
    batch.update(senderWalletRef, {
      'balance': FieldValue.increment(-price),
    });

    // 2. إضافة سجل "هدايا مرسلة"
    final sentGiftRef = _firestore
        .collection('gifts_sent')
        .doc(senderUid)
        .collection('items')
        .doc();
    batch.set(sentGiftRef, {
      'giftId': giftId,
      'giftName': giftName,
      'receiverUid': receiverUid,
      'price': price,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 3. إضافة سجل "هدايا مستلمة"
    final receivedGiftRef = _firestore
        .collection('received_gifts')
        .doc(receiverUid)
        .collection('items')
        .doc();
    batch.set(receivedGiftRef, {
      'giftId': giftId,
      'giftName': giftName,
      'senderUid': senderUid,
      'price': price,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await batch.commit();

    // ربط التحديات اليومية (تحديث تقدم تحدي إرسال الهدايا)
    await ChallengesService.updateProgress(ChallengesService.typeGift);
  }
}
