import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSetupService {
  static Future<void> setupGlobalContent() async {
    // إضافة هدايا افتراضية إذا كان المتجر فارغاً
    final giftsSnap = await FirebaseFirestore.instance.collection('gifts').limit(1).get();
    if (giftsSnap.docs.isEmpty) {
      await _seedInitialGifts();
    }
  }

  static Future<void> _seedInitialGifts() async {
    final List<Map<String, dynamic>> initialGifts = [
      {
        'name': 'التفاحة الملكية 🍎',
        'price': 500,
        'imageUrl': 'https://firebasestorage.googleapis.com/v0/b/royaldoor-app.appspot.com/o/gifts%2Froyal_apple.png?alt=media', // رابط افتراضي
        'currencyType': 'gems',
        'giftType': 'image',
        'category': 'رويال',
        'giftPlacement': 'room',
        'showInStore': true,
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      {
        'name': 'سيارة ملكية 🏎️',
        'price': 2500,
        'imageUrl': 'https://example.com/car.png',
        'currencyType': 'gems',
        'giftType': 'image',
        'category': 'رويال',
        'giftPlacement': 'room',
        'showInStore': true,
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }
    ];

    for (var gift in initialGifts) {
      await FirebaseFirestore.instance.collection('gifts').add(gift);
    }
  }
}
