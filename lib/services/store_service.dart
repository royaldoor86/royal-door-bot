import 'package:cloud_firestore/cloud_firestore.dart';

class StoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// إضافة البيانات الأولية للمتجر (الأغلفة والفقاعات) بتصاميم عالمية
  static Future<void> seedStoreData() async {
    // حذف البيانات القديمة أولاً لتجنب التكرار ولتحديث الأشكال
    final coversSnap = await _db.collection('covers').get();
    for (var doc in coversSnap.docs) {
      await doc.reference.delete();
    }
    final bubblesSnap = await _db.collection('bubbles').get();
    for (var doc in bubblesSnap.docs) {
      await doc.reference.delete();
    }

    // 10 أغلفة ملكية عالمية (مناظر طبيعية، تجريدية، فخمة)
    final List<Map<String, dynamic>> covers = [
      {
        'name': 'الأفق المخملي',
        'url':
            'https://images.unsplash.com/photo-1506744038136-46273834b3fb?q=80&w=1000&auto=format&fit=crop',
        'price': 5000,
        'isActive': true
      },
      {
        'name': 'الرخام الملكي',
        'url':
            'https://images.unsplash.com/photo-1533158326339-7f3cf2404354?q=80&w=1000&auto=format&fit=crop',
        'price': 3500,
        'isActive': true
      },
      {
        'name': 'سديم النور',
        'url':
            'https://images.unsplash.com/photo-1464802686167-b939a67e06a1?q=80&w=1000&auto=format&fit=crop',
        'price': 4000,
        'isActive': true
      },
      {
        'name': 'الشفق القطبي',
        'url':
            'https://images.unsplash.com/photo-1531366930499-41f59c113054?q=80&w=1000&auto=format&fit=crop',
        'price': 2500,
        'isActive': true
      },
      {
        'name': 'الذهب الأسود',
        'url':
            'https://images.unsplash.com/photo-1502691876148-a84978f5d81b?q=80&w=1000&auto=format&fit=crop',
        'price': 4500,
        'isActive': true
      },
      {
        'name': 'الصحراء الهادئة',
        'url':
            'https://images.unsplash.com/photo-1473580044384-7ba9967e16a0?q=80&w=1000&auto=format&fit=crop',
        'price': 3000,
        'isActive': true
      },
      {
        'name': 'غابة الضباب',
        'url':
            'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?q=80&w=1000&auto=format&fit=crop',
        'price': 2000,
        'isActive': true
      },
      {
        'name': 'بحيرة الكريستال',
        'url':
            'https://images.unsplash.com/photo-1439853949127-fa647821eba0?q=80&w=1000&auto=format&fit=crop',
        'price': 2800,
        'isActive': true
      },
      {
        'name': 'زهرة اللوتس',
        'url':
            'https://images.unsplash.com/photo-1502622645662-300bb5bab403?q=80&w=1000&auto=format&fit=crop',
        'price': 3200,
        'isActive': true
      },
      {
        'name': 'فخامة ملكية',
        'url':
            'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?q=80&w=1000&auto=format&fit=crop',
        'price': 6000,
        'isActive': true
      },
    ];

    // 10 فقاعات دردشة (تصاميم ناعمة وحديثة)
    final List<Map<String, dynamic>> bubbles = [
      {
        'name': 'الوهج الذهبي',
        'url': 'https://i.ibb.co/vYmYp5X/gold-bubble.png',
        'gemsPrice': 20,
        'coinsPrice': 2000,
        'price': 2000,
        'isActive': true
      },
      {
        'name': 'النيون البنفسجي',
        'url': 'https://i.ibb.co/zXqXy2p/neon-bubble.png',
        'gemsPrice': 15,
        'coinsPrice': 1500,
        'price': 1500,
        'isActive': true
      },
      {
        'name': 'الشفافية الملكية',
        'url': 'https://i.ibb.co/3W6n6qT/glass-bubble.png',
        'gemsPrice': 18,
        'coinsPrice': 1800,
        'price': 1800,
        'isActive': true
      },
      {
        'name': 'الماس الوردي',
        'url': 'https://i.ibb.co/0mR3Y8T/pink-diamond.png',
        'gemsPrice': 30,
        'coinsPrice': 3000,
        'price': 3000,
        'isActive': true
      },
      {
        'name': 'الظلال الملكية',
        'url': 'https://i.ibb.co/v4KxW9B/dark-royal.png',
        'gemsPrice': 12,
        'coinsPrice': 1200,
        'price': 1200,
        'isActive': true
      },
      {
        'name': 'انسياب الألوان',
        'url': 'https://i.ibb.co/kDfW5mX/color-flow.png',
        'gemsPrice': 25,
        'coinsPrice': 2500,
        'price': 2500,
        'isActive': true
      },
      {
        'name': 'بساطة النخبة',
        'url': 'https://i.ibb.co/vYmYp5X/simple-elite.png',
        'gemsPrice': 10,
        'coinsPrice': 1000,
        'price': 1000,
        'isActive': true
      },
      {
        'name': 'بريق النجوم',
        'url': 'https://i.ibb.co/zXqXy2p/star-bubble.png',
        'gemsPrice': 22,
        'coinsPrice': 2200,
        'price': 2200,
        'isActive': true
      },
      {
        'name': 'التاجر الصغير',
        'url': 'https://i.ibb.co/3W6n6qT/merchant-bubble.png',
        'gemsPrice': 35,
        'coinsPrice': 3500,
        'price': 3500,
        'isActive': true
      },
      {
        'name': 'سيادة رويال',
        'url': 'https://i.ibb.co/0mR3Y8T/royal-sovereignty.png',
        'gemsPrice': 28,
        'coinsPrice': 2800,
        'price': 2800,
        'isActive': true
      },
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

  /// تحديث الفقاعات القديمة لإضافة gemsPrice و coinsPrice
  static Future<void> updateBubblesWithDualPricing() async {
    final bubblesSnap = await _db.collection('bubbles').get();
    final WriteBatch batch = _db.batch();

    for (var doc in bubblesSnap.docs) {
      final data = doc.data();
      final price = data['price'] ?? 0;

      // إذا لم يكن هناك gemsPrice أو coinsPrice، أضفهما
      if (!data.containsKey('gemsPrice') || !data.containsKey('coinsPrice')) {
        final gemsPrice = (price / 100).round(); // 1 جوهرة = 100 كوينز
        batch.update(doc.reference, {
          'gemsPrice': gemsPrice,
          'coinsPrice': price,
        });
      }
    }

    if (bubblesSnap.docs.isNotEmpty) {
      await batch.commit();
    }
  }
}
