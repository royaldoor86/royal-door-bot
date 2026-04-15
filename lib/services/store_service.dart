import 'package:cloud_firestore/cloud_firestore.dart';

class StoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// إضافة البيانات الأولية للمتجر (الأغلفة والفقاعات)
  static Future<void> seedStoreData() async {
    // 10 أغلفة ملكية
    final List<Map<String, dynamic>> covers = [
      {'name': 'القصر الذهبي', 'url': 'https://img.freepik.com/free-photo/view-palace-with-golden-details_23-2151152062.jpg', 'price': 5000, 'isActive': true},
      {'name': 'سديم المجرة', 'url': 'https://img.freepik.com/free-photo/abstract-background-with-colorful-nebula_23-2148817731.jpg', 'price': 3500, 'isActive': true},
      {'name': 'الليل الملكي', 'url': 'https://img.freepik.com/free-photo/luxurious-blue-background-with-gold-details_23-2148812234.jpg', 'price': 4000, 'isActive': true},
      {'name': 'فجر الأمل', 'url': 'https://img.freepik.com/free-photo/beautiful-sunrise-sea-with-clouds_23-2148139527.jpg', 'price': 2500, 'isActive': true},
      {'name': 'الرخام الأسود', 'url': 'https://img.freepik.com/free-photo/black-marble-texture-background_23-2148813009.jpg', 'price': 4500, 'isActive': true},
      {'name': 'حدائق رويال', 'url': 'https://img.freepik.com/free-photo/beautiful-garden-with-flowers_23-2148139534.jpg', 'price': 3000, 'isActive': true},
      {'name': 'أضواء المدينة', 'url': 'https://img.freepik.com/free-photo/city-lights-night-background_23-2148139538.jpg', 'price': 2000, 'isActive': true},
      {'name': 'الصحراء الذهبية', 'url': 'https://img.freepik.com/free-photo/desert-landscape-with-sand-dunes_23-2148139542.jpg', 'price': 2800, 'isActive': true},
      {'name': 'البحر الفيروزي', 'url': 'https://img.freepik.com/free-photo/turquoise-sea-water-background_23-2148139546.jpg', 'price': 3200, 'isActive': true},
      {'name': 'هيبة الملوك', 'url': 'https://img.freepik.com/free-photo/majestic-lion-portrait_23-2148139550.jpg', 'price': 6000, 'isActive': true},
    ];

    // 10 فقاعات دردشة عالمية
    final List<Map<String, dynamic>> bubbles = [
      {'name': 'فقاعة رويال', 'url': 'https://cdn-icons-png.flaticon.com/512/1077/1077035.png', 'price': 2000, 'isActive': true},
      {'name': 'النيون الأزرق', 'url': 'https://cdn-icons-png.flaticon.com/512/1077/1077036.png', 'price': 1500, 'isActive': true},
      {'name': 'التوهج الوردي', 'url': 'https://cdn-icons-png.flaticon.com/512/1077/1077037.png', 'price': 1800, 'isActive': true},
      {'name': 'الماسية الشفافة', 'url': 'https://cdn-icons-png.flaticon.com/512/1077/1077038.png', 'price': 3000, 'isActive': true},
      {'name': 'الظلال الداكنة', 'url': 'https://cdn-icons-png.flaticon.com/512/1077/1077039.png', 'price': 1200, 'isActive': true},
      {'name': 'الألوان الساطعة', 'url': 'https://cdn-icons-png.flaticon.com/512/1077/1077040.png', 'price': 2500, 'isActive': true},
      {'name': 'البساطة الراقية', 'url': 'https://cdn-icons-png.flaticon.com/512/1077/1077041.png', 'price': 1000, 'isActive': true},
      {'name': 'فقاعة النجوم', 'url': 'https://cdn-icons-png.flaticon.com/512/1077/1077042.png', 'price': 2200, 'isActive': true},
      {'name': 'الذهب النقي', 'url': 'https://cdn-icons-png.flaticon.com/512/1077/1077043.png', 'price': 3500, 'isActive': true},
      {'name': 'المستقبل', 'url': 'https://cdn-icons-png.flaticon.com/512/1077/1077044.png', 'price': 2800, 'isActive': true},
    ];

    final WriteBatch batch = _db.batch();

    for (var cover in covers) {
      batch.set(_db.collection('covers').doc(), cover);
    }

    for (var bubble in bubbles) {
      batch.set(_db.collection('bubbles').doc(), bubble);
    }

    await batch.commit();
  }
}
