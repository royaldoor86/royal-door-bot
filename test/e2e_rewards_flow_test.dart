import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:royaldoor/services/rewards_service.dart';
import 'package:royaldoor/constants/rewards_constants.dart';
import 'package:royaldoor/models/rewards_models.dart';

void main() {
  // هذا الاختبار مصمم ليتم تشغيله في بيئة محاكاة أو جهاز حقيقي مع صلاحيات إدارية
  // ملاحظة: قد يحتاج لإعداد Firebase Mocking إذا لم يتوفر اتصال حقيقي
  
  group('E2E Rewards System Test', () {
    late RewardsService rewardsService;
    final String testUserId = 'test_user_123';
    final String recipientRoyalId = 'ROYAL999';
    final String recipientUid = 'recipient_user_456';

    setUp(() {
      rewardsService = RewardsService();
    });

    test('Full Scenario: Purchase -> Daily Harvest -> Transfer Gift', () async {
      print('--- Starting E2E Rewards Scenario Test ---');

      // 1. إعداد بيانات المستخدم التجريبية (رصيد كافٍ)
      final userRef = FirebaseFirestore.instance.collection('users').doc(testUserId);
      await userRef.set({
        'royalId': 'TESTER01',
        RewardsConstants.walletGemsField: 50000.0,
        'harvest_wallet': 50000.0, // للموافقة مع الأنظمة القديمة
      });

      final recipientRef = FirebaseFirestore.instance.collection('users').doc(recipientUid);
      await recipientRef.set({
        'royalId': recipientRoyalId,
        RewardsConstants.walletGemsField: 0.0,
      });

      print('Step 1: Mock Users Created.');

      // 2. شراء باقة مكافآت (Purchase Package)
      final activeReward = await rewardsService.purchaseReward(
        packageName: 'Golden Harvest',
        rewardAmount: 1000.0,
        totalReward: 30000.0,
        dailyReward: 1000.0,
        durationDays: 30,
        paymentMethod: 'gems',
      );

      expect(activeReward.packageName, 'Golden Harvest');
      print('Step 2: Package Purchased Successfully. ID: ${activeReward.id}');

      // 3. تفعيل العداد وحصاد المكافأة اليومية (Daily Harvest)
      // سنقوم بتجاوز وقت الانتظار برمجياً في Firestore (اختياري في الوحدة الحقيقية نحاكي مرور الوقت)
      await rewardsService.activateDailyReward(activeReward.id);
      
      final updatedUserDoc = await userRef.get();
      final currentGems = (updatedUserDoc.data()?['rewards_wallet_gems'] ?? 0.0) as double;
      
      print('Step 3: Daily Reward Harvested. New Balance: $currentGems');
      expect(currentGems, greaterThan(50000.0));

      // 4. تحويل هدية للتحقق من الصندوق العالمي (Transfer Gift & Global Support)
      final double transferAmount = 10000.0;
      await rewardsService.transferRoyalGifts(
        senderId: testUserId,
        recipientRoyalId: recipientRoyalId,
        amount: transferAmount,
        currency: 'gems',
      );

      print('Step 4: Gift Transferred ($transferAmount gems).');

      // 5. التحقق من تحديث الأرصدة والرسوم
      final senderDocAfter = await userRef.get();
      final recipientDocAfter = await recipientRef.get();
      final fundDoc = await FirebaseFirestore.instance.collection('global_support_fund').doc('status').get();

      final senderBalance = senderDocAfter.data()?['rewards_wallet_gems'] as double;
      final recipientBalance = recipientDocAfter.data()?['rewards_wallet_gems'] as double;
      final fundPool = fundDoc.data()?['current_gems_pool'] as double;

      print('Final Balances:');
      print('- Sender: $senderBalance');
      print('- Recipient: $recipientBalance');
      print('- Global Fund Pool: $fundPool');

      // الحسابات:
      // البداية: 50000 + 1000 (حصاد) = 51000
      // تحويل 10000:
      // المرسل يخصم منه 10000 -> 41000
      // العمولة 5% من 10000 = 500
      // المستلم يستلم 10000 - 500 = 9500
      // الصندوق يستلم 500

      expect(senderBalance, 41000.0);
      expect(recipientBalance, 9500.0);
      expect(fundPool, 500.0);

      print('--- E2E Rewards Scenario Test Passed 100% ---');
    });
  });
}
