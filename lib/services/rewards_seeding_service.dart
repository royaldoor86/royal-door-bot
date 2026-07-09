import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/rewards_constants.dart';

class RewardsSeedingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> seedPackages() async {
    final List<Map<String, dynamic>> packagesData = [
      {
        'id': 'durra',
        'name': 'الدر',
        'cost_gems': 38500,
        'cost_stars': 100000,
        'monthly_bonus_gems': 1900,
        'total_gems': 40400,
        'total_stars_after': 105000, // 100k + 5k profit
        'sort': 1,
      },
      {
        'id': 'morjan',
        'name': 'المرجان',
        'cost_gems': 77000,
        'cost_stars': 200000,
        'monthly_bonus_gems': 3800,
        'total_gems': 80800,
        'total_stars_after': 210000,
        'sort': 2,
      },
      {
        'id': 'aqeeq',
        'name': 'العقيق',
        'cost_gems': 115000,
        'cost_stars': 300000,
        'monthly_bonus_gems': 5700,
        'total_gems': 121000,
        'total_stars_after': 315000,
        'sort': 3,
      },
      {
        'id': 'crystal',
        'name': 'الكريستال',
        'cost_gems': 192000,
        'cost_stars': 500000,
        'monthly_bonus_gems': 9600,
        'total_gems': 201600,
        'total_stars_after': 525000,
        'sort': 4,
      },
      {
        'id': 'zabarjad',
        'name': 'الزبرجد',
        'cost_gems': 288000,
        'cost_stars': 750000,
        'monthly_bonus_gems': 14400,
        'total_gems': 302400,
        'total_stars_after': 787500,
        'sort': 5,
      },
      {
        'id': 'lulu',
        'name': 'اللؤلؤ',
        'cost_gems': 385000,
        'cost_stars': 1000000,
        'monthly_bonus_gems': 19200,
        'total_gems': 404200,
        'total_stars_after': 1050000,
        'sort': 6,
      },
      {
        'id': 'fayrouz',
        'name': 'الفيروز',
        'cost_gems': 462000,
        'cost_stars': 1200000,
        'monthly_bonus_gems': 23000,
        'total_gems': 484600,
        'total_stars_after': 1260000,
        'sort': 7,
      },
      {
        'id': 'almas',
        'name': 'الماس',
        'cost_gems': 500000,
        'cost_stars': 1300000,
        'monthly_bonus_gems': 25000,
        'total_gems': 525000,
        'total_stars_after': 1365000,
        'sort': 8,
      },
      {
        'id': 'zumurrud',
        'name': 'الزمرد',
        'cost_gems': 538000,
        'cost_stars': 1400000,
        'monthly_bonus_gems': 27000,
        'total_gems': 565000,
        'total_stars_after': 1470000,
        'sort': 9,
      },
      {
        'id': 'yaqoot',
        'name': 'الياقوت',
        'cost_gems': 577000,
        'cost_stars': 1500000,
        'monthly_bonus_gems': 29000,
        'total_gems': 606000,
        'total_stars_after': 1575000,
        'sort': 10,
      },
    ];

    final batch = _firestore.batch();
    for (var data in packagesData) {
      final docRef = _firestore.collection(RewardsConstants.collectionPackages).doc(data['id']);
      
      // حساب الربح اليومي: الإجمالي / 30 يوم
      double dailyGems = (data['total_gems'] as num) / 30;

      batch.set(docRef, {
        'name': data['name'],
        'cost': data['cost_gems'], // الافتراضي شراء بالجواهر
        'stars_cost': data['cost_stars'],
        'daily_reward': dailyGems,
        'total_reward': data['total_gems'],
        'conversion_stars': data['total_stars_after'],
        'durationDays': 30,
        'isActive': true,
        'sortOrder': data['sort'],
        'currency': 'gems',
        'metadata': {
          'monthly_profit_gems': data['monthly_bonus_gems'],
        }
      });
    }

    await batch.commit();
    print('✅ تم تحديث كافة الباقات الملكية بنجاح');
  }
}
