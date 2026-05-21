import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/rewards_constants.dart';
import '../models/rewards_models.dart';

class RewardsSeedingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> seedPackages() async {
    final List<RewardPackage> packages = [
      RewardPackage(
        id: 'durra',
        name: 'الدر',
        description: 'باقة الدر الملكية',
        cost: 38500, // بالجواهر
        dailyReward: 1346,
        totalReward: 40400,
        durationDays: 30,
        currency: RewardsConstants.currency_gems,
        isActive: true,
        sortOrder: 1,
        features: {'stars_cost': 100000, 'monthly_bonus': 1900},
      ),
      RewardPackage(
        id: 'morjan',
        name: 'المرجان',
        description: 'باقة المرجان الملكية',
        cost: 77000,
        dailyReward: 2693, // 80800 / 30
        totalReward: 80800,
        durationDays: 30,
        currency: RewardsConstants.currency_gems,
        isActive: true,
        sortOrder: 2,
        features: {'stars_cost': 200000, 'monthly_bonus': 3800},
      ),
      RewardPackage(
        id: 'aqeeq',
        name: 'العقيق',
        description: 'باقة العقيق الملكية',
        cost: 115000,
        dailyReward: 4033, // 121000 / 30
        totalReward: 121000,
        durationDays: 30,
        currency: RewardsConstants.currency_gems,
        isActive: true,
        sortOrder: 3,
        features: {'stars_cost': 300000, 'monthly_bonus': 5700},
      ),
      RewardPackage(
        id: 'crystal',
        name: 'الكريستال',
        description: 'باقة الكريستال الملكية',
        cost: 192000,
        dailyReward: 6720,
        totalReward: 201600,
        durationDays: 30,
        currency: RewardsConstants.currency_gems,
        isActive: true,
        sortOrder: 4,
        features: {'stars_cost': 500000, 'monthly_bonus': 9600},
      ),
      RewardPackage(
        id: 'zabarjad',
        name: 'الزبرجد',
        description: 'باقة الزبرجد الملكية',
        cost: 288000,
        dailyReward: 10080,
        totalReward: 302400,
        durationDays: 30,
        currency: RewardsConstants.currency_gems,
        isActive: true,
        sortOrder: 5,
        features: {'stars_cost': 750000, 'monthly_bonus': 14400},
      ),
      RewardPackage(
        id: 'lulu',
        name: 'اللؤلؤ',
        description: 'باقة اللؤلؤ الملكية',
        cost: 385000,
        dailyReward: 13473,
        totalReward: 404200,
        durationDays: 30,
        currency: RewardsConstants.currency_gems,
        isActive: true,
        sortOrder: 6,
        features: {'stars_cost': 1000000, 'monthly_bonus': 19200},
      ),
      RewardPackage(
        id: 'fayrouz',
        name: 'الفيروز',
        description: 'باقة الفيروز الملكية',
        cost: 462000,
        dailyReward: 16153,
        totalReward: 484600,
        durationDays: 30,
        currency: RewardsConstants.currency_gems,
        isActive: true,
        sortOrder: 7,
        features: {'stars_cost': 1200000, 'monthly_bonus': 23000},
      ),
      RewardPackage(
        id: 'almas',
        name: 'الماس',
        description: 'باقة الماس الملكية',
        cost: 500000,
        dailyReward: 17500,
        totalReward: 525000,
        durationDays: 30,
        currency: RewardsConstants.currency_gems,
        isActive: true,
        sortOrder: 8,
        features: {'stars_cost': 1300000, 'monthly_bonus': 25000},
      ),
      RewardPackage(
        id: 'zumurrud',
        name: 'الزمرد',
        description: 'باقة الزمرد الملكية',
        cost: 538000,
        dailyReward: 18833,
        totalReward: 565000,
        durationDays: 30,
        currency: RewardsConstants.currency_gems,
        isActive: true,
        sortOrder: 9,
        features: {'stars_cost': 1400000, 'monthly_bonus': 27000},
      ),
      RewardPackage(
        id: 'yaqoot',
        name: 'الياقوت',
        description: 'باقة الياقوت الملكية الأعلى',
        cost: 577000,
        dailyReward: 20200,
        totalReward: 606000,
        durationDays: 30,
        currency: RewardsConstants.currency_gems,
        isActive: true,
        sortOrder: 10,
        features: {'stars_cost': 1500000, 'monthly_bonus': 29000},
      ),
    ];

    final batch = _firestore.batch();
    for (var package in packages) {
      final docRef = _firestore
          .collection(RewardsConstants.collectionPackages)
          .doc(package.id);
      batch.set(docRef, package.toMap());
    }

    await batch.commit();
    print('✅ تم حقن جميع الباقات الملكية بنجاح');
  }
}
