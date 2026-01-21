import 'package:cloud_firestore/cloud_firestore.dart';

class AdminSetupService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> setupGlobalContent() async {
    await setupGifts();
    await setupFrames();
    await setupRanks();
  }

  static Future<void> setupGifts() async {
    final List<Map<String, dynamic>> gifts = [
      // هدايا ملكية فاخرة
      {'name': 'تاج الإمبراطور', 'price': 100000, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/2353/2353361.png', 'isAnimated': true},
      {'name': 'قلعة رويال', 'price': 50000, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/2353/2353351.png', 'isAnimated': true},
      {'name': 'أسد ذهبي', 'price': 25000, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/2353/2353341.png', 'isAnimated': true},
      {'name': 'خاتم الألماس', 'price': 15000, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/2353/2353331.png', 'isAnimated': true},
      {'name': 'سيارة فراري', 'price': 10000, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/2353/2353321.png', 'isAnimated': true},
      
      // هدايا العائلة
      {'name': 'درع القبيلة', 'price': 8000, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/2353/2353311.png', 'isAnimated': false},
      {'name': 'سيف العدالة', 'price': 5000, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/2353/2353301.png', 'isAnimated': false},
      {'name': 'بيرق العائلة', 'price': 3000, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/2353/2353291.png', 'isAnimated': false},
      
      // هدايا متنوعة
      {'name': 'وردة الحب', 'price': 100, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/2353/2353281.png', 'isAnimated': false},
      {'name': 'قلب مكسور', 'price': 200, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/2353/2353271.png', 'isAnimated': false},
      {'name': 'برج إيفل', 'price': 2000, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/2353/2353261.png', 'isAnimated': true},
      {'name': 'ساعة فاخرة', 'price': 1500, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/2353/2353251.png', 'isAnimated': false},
      {'name': 'عطر ملكي', 'price': 800, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/2353/2353241.png', 'isAnimated': false},
      {'name': 'طائرة خاصة', 'price': 30000, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/2353/2353231.png', 'isAnimated': true},
      {'name': 'يخت ملكي', 'price': 40000, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/2353/2353221.png', 'isAnimated': true},
      {'name': 'صقر جارح', 'price': 12000, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/2353/2353211.png', 'isAnimated': true},
      {'name': 'قهوة عربية', 'price': 50, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/2353/2353201.png', 'isAnimated': false},
      {'name': 'برق سريع', 'price': 300, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/2353/2353191.png', 'isAnimated': false},
      {'name': 'صاروخ مرح', 'price': 500, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/2353/2353181.png', 'isAnimated': true},
      {'name': 'قمر مضيء', 'price': 1000, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/2353/2353171.png', 'isAnimated': true},
    ];

    for (var gift in gifts) {
      await _db.collection('gifts').add({
        ...gift,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  static Future<void> setupFrames() async {
    final List<Map<String, dynamic>> frames = [
      {'name': 'إطار الملك الذهبي', 'price': 50000, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/2353/2353361.png', 'isFamilyFrame': true},
      {'name': 'إطار فارس العائلة', 'price': 20000, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/2353/2353351.png', 'isFamilyFrame': true},
      {'name': 'إطار النخبة المضيء', 'price': 15000, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/2353/2353341.png', 'isFamilyFrame': false},
      {'name': 'إطار النار المشتعلة', 'price': 10000, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/2353/2353331.png', 'isFamilyFrame': false},
      {'name': 'إطار الثلج الأزرق', 'price': 8000, 'imageUrl': 'https://cdn-icons-png.flaticon.com/512/2353/2353321.png', 'isFamilyFrame': false},
    ];

    for (var frame in frames) {
      await _db.collection('avatar_frames').add({
        ...frame,
        'isActive': true,
        'onSale': false,
        'salePrice': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  static Future<void> setupRanks() async {
    // الرتب تخزن عادة كقائمة ثابتة في الكود، لكن يمكننا تهيئة بياناتها
    // لإظهارها في شات أو واجهات معينة
  }
}
