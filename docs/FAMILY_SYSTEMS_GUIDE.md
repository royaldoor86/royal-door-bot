# دليل أنظمة العائلة - Royal Door Bot

## جدول المحتويات
1. [نظام الحروب (Family Wars)](#نظام-الحروب-family-wars)
2. [نظام الرتب (Member Ranks)](#نظام-الرتب-member-ranks)
3. [نظام التحالفات (Alliances)](#نظام-التحالفات-alliances)
4. [نظام المهام (Tasks)](#نظام-المهام-tasks)
5. [نظام الإشعارات (Notifications)](#نظام-الإشعارات-notifications)
6. [نظام الأحداث (Events)](#نظام-الأحداث-events)
7. [نظام التبرعات (Donations)](#نظام-التبرعات-donations)
8. [نظام المستويات (Levels)](#نظام-المستويات-levels)

---

## نظام الحروب (Family Wars)

### نظرة عامة
نظام الحروب يسمح للعائلات بالتنافس مع بعضها البعض في معارك منظمة مع نقاط ومكافآت.

### الميزات الرئيسية
- ✅ واجهة إدارة الحروب
- ✅ نظام تصنيف عالمي
- ✅ مكافآت متنوعة (نجوم، جواهر، شارات)
- ✅ نظام تحديات داخل الحرب
- ✅ إحصائيات مفصلة

### كيفية الاستخدام

#### 1. بدء حرب جديدة
```dart
final familyService = FamilyService();
await familyService.createWar(
  familyId: 'family_1',
  enemyFamilyId: 'family_2',
  enemyFamilyName: 'اسم العائلة المعادية',
  warType: 'standard', // 'standard', 'ranked', 'alliance'
  duration: Duration(hours: 24),
);
```

#### 2. إضافة نقاط للحرب
```dart
await familyService.addWarPoints(
  familyId: 'family_1',
  warId: 'war_123',
  userId: 'user_456',
  points: 100,
  contributionType: 'challenge', // 'challenge', 'battle', 'defense'
);
```

#### 3. إنهاء الحرب وتحديد الفائز
```dart
await familyService.endWar(
  warId: 'war_123',
  winnerFamilyId: 'family_1',
  loserFamilyId: 'family_2',
);
```

#### 4. الحصول على الحروب النشطة
```dart
final activeWars = await familyService.getActiveWars();
// أو استخدام Stream للتحديثات الحية
final warsStream = familyService.getActiveWars();
```

### أنواع الحروب
- **standard**: حرب عادية
- **ranked**: حرب تصنيفية تؤثر على الترتيب العالمي
- **alliance**: حرب بين تحالفات

### المكافآت
- **النجوم**: تُمنح للفائزين
- **الجواهر**: مكافأة إضافية للفوز
- **الشارات**: شارات حصرية للانتصارات

### التحديات داخل الحرب
يمكن إضافة تحديات داخل الحرب لزيادة التنافس:
```dart
await familyService.createWarChallenge(
  warId: 'war_123',
  title: 'تحدي النقاط',
  description: 'اجمع 500 نقطة',
  type: 'points',
  targetValue: 500,
  reward: {
    'stars': 100,
    'gems': 50,
  },
);
```

---

## نظام الرتب (Member Ranks)

### نظرة عامة
نظام الرتب يصنّف أعضاء العائلة بناءً على مساهماتهم، مع مزايا خاصة لكل رتبة.

### الرتب المتاحة
1. **برونزي (Bronze)** - 0 نقطة
2. **فضي (Silver)** - 500 نقطة
3. **ذهبي (Gold)** - 1500 نقطة
4. **بلاتيني (Platinum)** - 3000 نقطة
5. **ماسي (Diamond)** - 5000 نقطة
6. **ملكي (Royal)** - 10000 نقطة

### المزايا لكل رتبة

#### برونزي
- 💬 دردشة الأعضاء
- 📊 عرض الإحصائيات
- مكافآت يومية: 10 جوهرة، 20 نجمة

#### فضي
- جميع مزايا برونزي
- 🎁 مكافأة يومية
- 👥 دعوة أعضاء
- مكافآت يومية: 25 جوهرة، 50 نجمة

#### ذهبي
- جميع مزايا فضي
- 🏅 شارة حصرية
- 🚫 طرد أعضاء
- 📋 عرض السجلات
- مكافآت يومية: 50 جوهرة، 100 نجمة

#### بلاتيني
- جميع مزايا ذهبي
- ⚔️ مكافأة حرب
- ⬆️ ترقية أعضاء
- إدارة الحروب
- مكافآت يومية: 100 جوهرة، 200 نجمة

#### ماسي
- جميع مزايا بلاتيني
- 💎 دردشة VIP
- إدارة المزايا
- مكافآت يومية: 200 جوهرة، 400 نجمة

#### ملكي
- جميع مزايا ماسي
- 👑 مزايا ملكية
- ⚙️ تعديل الإعدادات
- مكافآت يومية: 500 جوهرة، 1000 نجمة

### كيفية الاستخدام

#### 1. إضافة نقاط مساهمة (تُحدث الرتب تلقائياً)
```dart
await familyService.addContributionPoints(
  familyId: 'family_1',
  userId: 'user_456',
  points: 100,
);
```

#### 2. الحصول على رتبة عضو
```dart
final rank = await familyService.getMemberRank(
  familyId: 'family_1',
  userId: 'user_456',
);
```

#### 3. تفعيل مزايا الرتبة
```dart
final perks = await familyService.activateRankPerks(
  familyId: 'family_1',
  userId: 'user_456',
);
```

#### 4. الحصول على المزايا المتاحة
```dart
final availablePerks = await familyService.getAvailableRankPerks(
  familyId: 'family_1',
  userId: 'user_456',
);
```

#### 5. المطالبة بالمكافأة اليومية
```dart
final result = await familyService.claimDailyRankBonus(
  familyId: 'family_1',
  userId: 'user_456',
);
```

### نظام التنافس بين الرتب
```dart
// تحديث التنافس لرتبة معينة
await familyService.recalculateRankCompetition(
  familyId: 'family_1',
  rankId: 'gold',
);

// الحصول على لوحة المتصدرين
final leaderboard = familyService.getRankCompetitionLeaderboard('family_1');

// إضافة إنجاز للرتبة
await familyService.addRankCompetitionAchievement(
  familyId: 'family_1',
  rankId: 'gold',
  achievementId: 'first_to_5000',
  achievementName: 'أول من وصل 5000 نقطة',
);
```

---

## نظام التحالفات (Alliances)

### نظرة عامة
نظام التحالفات يسمح للعائلات بالتعاون ومشاركة الموارد والتنافس معاً.

### أنواع التحالفات
- **military**: تحالف عسكري (مكافآت حرب، دفاع مشترك)
- **economic**: تحالف اقتصادي (تجارة، خزينة مشتركة)
- **social**: تحالف اجتماعي (دردشة، أحداث مشتركة)

### كيفية الاستخدام

#### 1. إنشاء تحالف جديد
```dart
final allianceId = await familyService.createAlliance(
  familyId: 'family_1',
  familyName: 'اسم العائلة',
  name: 'اسم التحالف',
  description: 'وصف التحالف',
  allianceType: 'military', // 'military', 'economic', 'social'
  maxMembers: 5,
  maxAlliancesPerFamily: 2,
);
```

#### 2. إرسال دعوة للانضمام
```dart
await familyService.sendAllianceInvitation(
  allianceId: 'alliance_123',
  targetFamilyId: 'family_2',
  targetFamilyName: 'اسم العائلة المستهدفة',
);
```

#### 3. قبول دعوة التحالف
```dart
await familyService.acceptAllianceInvitation('invitation_456');
```

#### 4. رفض دعوة التحالف
```dart
await familyService.rejectAllianceInvitation('invitation_456');
```

#### 5. مغادرة التحالف
```dart
await familyService.leaveAlliance(
  allianceId: 'alliance_123',
  familyId: 'family_1',
);
```

#### 6. حل التحالف
```dart
await familyService.dissolveAlliance(
  allianceId: 'alliance_123',
  familyId: 'family_1',
);
```

### فوائد التحالفات

#### التحالف العسكري
- مضاعف مكافآت الحرب: x1.5
- نقاط حرب مشتركة
- حروب تحالفية
- دفاع مشترك

#### التحالف الاقتصادي
- مضاعف مكافآت التجارة: x1.3
- خزينة مشتركة
- مشاركة الموارد
- تخفيض الضرائب: 10%

#### التحالف الاجتماعي
- الوصول للدردشة المشتركة
- أحداث مشتركة
- رؤية الأعضاء
- مضاعف السمعة: x1.2

---

## نظام المهام (Tasks)

### نظرة عامة
نظام المهام يشمل مهام تعاونية ومهام متكررة مع مكافآت متنوعة.

### أنواع المهام

#### 1. المهام التعاونية (Collaborative Tasks)
تتطلب تعاون عدة أعضاء لإكمالها.

```dart
await familyService.createCollaborativeTask(
  familyId: 'family_1',
  familyName: 'اسم العائلة',
  title: 'مهمة فريقية',
  description: 'اجمع 1000 نقطة معاً',
  type: 'team', // 'team', 'alliance', 'war', 'resource'
  requiredParticipants: 3,
  targetValue: 1000,
  deadline: Timestamp.fromDate(DateTime.now().add(Duration(days: 7))),
);
```

#### 2. المهام المتكررة (Recurring Tasks)
مهام يومية/أسبوعية/شهرية.

```dart
await familyService.createRecurringTask(
  familyId: 'family_1',
  familyName: 'اسم العائلة',
  title: 'مهمة يومية',
  description: 'اجمع 100 نقطة يومياً',
  frequency: 'daily', // 'daily', 'weekly', 'monthly'
  targetValue: 100,
);
```

### كيفية الاستخدام

#### الانضمام لمهمة تعاونية
```dart
await familyService.joinCollaborativeTask(
  taskId: 'task_123',
  userId: 'user_456',
);
```

#### إضافة مساهمة لمهمة
```dart
await familyService.addTaskContribution(
  taskId: 'task_123',
  userId: 'user_456',
  value: 50,
);
```

#### إكمال مهمة متكررة
```dart
await familyService.completeRecurringTask(
  taskId: 'task_123',
  userId: 'user_456',
);
```

### المكافآت

#### المهام التعاونية
- **فريق**: 500 جوهرة للعائلة، 50 جوهرة لكل مشارك
- **تحالف**: 1000 جوهرة للتحالف، 100 جوهرة لكل مشارك
- **حرب**: 500 نقطة حرب، 1000 جوهرة للعائلة
- **مورد**: مضاعف موارد x1.5

#### المهام المتكررة
- **يومي**: 50 جوهرة للعائلة، 10 جوهرة لكل مشارك
- **أسبوعي**: 300 جوهرة للعائلة، 50 جوهرة لكل مشارك
- **شهري**: 1000 جوهرة للعائلة، 150 جوهرة لكل مشارك

---

## نظام الإشعارات (Notifications)

### نظرة عامة
نظام الإشعارات يوفر إشعارات فورية عبر FCM وإشعارات محلية.

### كيفية الاستخدام

#### 1. إرسال إشعار لمستخدم
```dart
await NotificationsService.sendNotification(
  userId: 'user_456',
  title: 'عنوان الإشعار',
  message: 'نص الإشعار',
  type: 'general', // 'general', 'war', 'reward', 'event', etc.
);
```

#### 2. إرسال إشعار Push
```dart
final result = await NotificationsService.sendPushNotification({
  'title': 'عنوان',
  'body': 'نص',
  'userId': 'user_456',
  'data': {'key': 'value'},
});
```

#### 3. الحصول على سجل الإشعارات
```dart
final notificationsStream = NotificationsService.notificationsStream('user_456');
```

#### 4. تهيئة الإشعارات المحلية
```dart
await NotificationsService.initLocalNotifications();
```

### أنواع الإشعارات
- `general`: إشعارات عامة
- `war`: إشعارات الحروب
- `reward`: إشعارات المكافآت
- `event`: إشعارات الأحداث
- `alliance`: إشعارات التحالفات
- `rank`: إشعارات الرتب

---

## نظام الأحداث (Events)

### نظرة عامة
نظام الأحداث يسمح بإنشاء وإدارة أحداث العائلة مع تسجيل المشاركين والمكافآت.

### كيفية الاستخدام

#### 1. إنشاء حدث جديد
```dart
await familyService.createFamilyEvent(
  familyId: 'family_1',
  title: 'حدث العائلة',
  description: 'وصف الحدث',
  startTime: Timestamp.fromDate(DateTime.now().add(Duration(days: 1))),
  endTime: Timestamp.fromDate(DateTime.now().add(Duration(days: 2))),
  rewards: {
    'stars': 100,
    'gems': 50,
  },
);
```

#### 2. التسجيل في حدث
```dart
await familyService.registerForEvent(
  eventId: 'event_123',
  userId: 'user_456',
);
```

#### 3. الحصول على أحداث العائلة
```dart
final eventsStream = familyService.streamFamilyEvents('family_1');
```

#### 4. إكمال حدث ومنح المكافآت
```dart
await familyService.completeEvent(
  eventId: 'event_123',
  familyId: 'family_1',
);
```

---

## نظام التبرعات (Donations)

### نظرة عامة
نظام التبرعات يسمح للأعضاء بالتبرع للعائلة مع تتبع ومكافآت.

### كيفية الاستخدام

#### 1. التبرع
```dart
await familyService.donateToFamily(
  familyId: 'family_1',
  userId: 'user_456',
  amount: 100,
  currency: 'gems', // 'gems', 'stars', 'coins'
);
```

#### 2. الحصول على سجل التبرعات
```dart
final donationsStream = familyService.getDonationHistory('family_1');
```

#### 3. الحصول على لوحة المتصدرين
```dart
final leaderboard = familyService.getDonationLeaderboard('family_1');
```

#### 4. تحديد هدف للخزينة
```dart
await familyService.setTreasuryGoal(
  familyId: 'family_1',
  targetAmount: 10000,
  reward: {
    'stars': 500,
    'badge': 'treasury_master',
  },
);
```

---

## نظام المستويات (Levels)

### نظرة عامة
نظام المستويات يكافئ الأعضاء على نشاطهم مع ميزات خاصة لكل مستوى.

### المستويات
- **المستوى 1**: الوصول الأساسي
- **المستوى 2**: وصول متقدم
- **المستوى 3**: وصول VIP
- **المستوى 4**: وصول ملكي

### المكافآت لكل مستوى
- مكافآت متنوعة (جواهر، نجوم، عملات)
- ميزات خاصة (غرف صوتية، شارات)
- مهام خاصة
- شارات حصرية

### كيفية الاستخدام

#### 1. زيادة مستوى العضو
```dart
await familyService.increaseMemberLevel(
  familyId: 'family_1',
  userId: 'user_456',
  xp: 100,
);
```

#### 2. الحصول على مستوى العضو
```dart
final level = await familyService.getMemberLevel(
  familyId: 'family_1',
  userId: 'user_456',
);
```

#### 3. المطالبة بمكافأة المستوى
```dart
await familyService.claimLevelReward(
  familyId: 'family_1',
  userId: 'user_456',
  level: 2,
);
```

---

## ملاحظات مهمة

### الأمان
- جميع العمليات الحساسة تستخدم Firestore Transactions لضمان الاتساق
- التحقق من الصلاحيات قبل تنفيذ العمليات
- تسجيل جميع الأنشطة في سجل العائلة

### الأداء
- استخدام Streams للتحديثات الحية
- Caching للبيانات المتكررة
- تحميل البيانات عند الطلب (lazy loading)

### التوسع
- جميع النماذج قابلة للتوسع
- يمكن إضافة أنواع جديدة من المهام/الحروب/التحالفات
- نظام المكافآت مرن وقابل للتخصيص

---

## الدعم
للدعم والاستفسارات، راجع:
- ملفات النماذج في `lib/models/`
- ملفات الخدمات في `lib/services/`
- ملفات الواجهات في `lib/features/`
