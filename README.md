# Royal Door - تطبيق لعبة Domino الاجتماعي 👑

تطبيق Flutter متقدم يجمع بين لعبة Domino والشبكات الاجتماعية مع نظام مكافآت وغرف صوتية وغرف أسرية.

## 📱 المميزات الرئيسية

### 🎮 المميزات الأساسية
- **لعبة Domino** - لعبة استراتيجية متعددة اللاعبين
- **غرف صوتية** - تواصل مباشر عبر Agora
- **نظام الدردشة** - رسائل فردية وجماعية
- **الملفات الشخصية** - عرض البيانات والإنجازات

### 💎 نظام الحوافز والمكافآت
- **مكافآت يومية** - دخول يومي وأنشطة
- **المهام اليومية** - مهام محددة مع مكافآت
- **نظام النقاط والمستويات** - تحسين التقدم
- **سوق المكافآت** - شراء المميزات
- **Royal ID** - هوية ملكية حصرية

### 👨‍👩‍👧 نظام العائلة
- **عائلات اجتماعية** - تنظيم المستخدمين
- **مهام العائلة** - تحديات جماعية
- **النقاط المجمعة** - مكافآت عائلية

### 📸 النشاطات والمشاركة
- **اليوميات والمنشورات** - مشاركة اللحظات
- **القصص** - محتوى قصير الأجل
- **التفاعلات** - لايكات وتعليقات
- **الزوار** - تتبع المشاهدات

### 🔔 نظام الإشعارات
- **إشعارات فورية** - للأنشطة المهمة
- **رسائل الدردشة** - تنبيهات الرسائل الجديدة
- **دعوات اللعب** - دعوات معارك وألعاب
- **تفاعلات المنشورات** - إخطار بالتفاعلات

### 🛡️ الأمان والمصادقة
- **مصادقة البريد** - تسجيل عبر البريد الإلكتروني
- **مصادقة الهاتف** - تحقق عبر OTP
- **تسجيل Google** - دخول سريع
- **مصادقة ثنائية** - حماية إضافية

## 🏗️ معمار المشروع

### البنية الأساسية
```
lib/
├── features/           # المميزات الرئيسية
│   ├── auth/           # المصادقة والتسجيل
│   ├── chat/           # الدردشة والرسائل
│   ├── games/          # لعبة Domino
│   ├── profile/        # الملفات الشخصية
│   ├── rooms/          # الغرف الصوتية
│   ├── diaries/        # اليوميات والمنشورات
│   ├── rewards/        # نظام المكافآت
│   └── family/         # نظام العائلة
├── services/           # خدمات Firebase والمنطق
├── models/             # نماذج البيانات
├── widgets/            # الـ widgets المخصصة
├── theme/              # نظام التصميم والألوان
├── constants/          # الثوابت والإعدادات
└── main.dart           # نقطة الدخول
```

### الخدمات الخلفية
```
functions/             # Firebase Cloud Functions (TypeScript)
├── src/
│   ├── auth/          # وظائف المصادقة
│   ├── rewards/       # وظائف المكافآت
│   ├── admin/         # وظائف الإدارة
│   └── notifications/ # نظام الإشعارات
└── lib/               # ملفات مُترجمة
```

## 🚀 البدء السريع

### المتطلبات
- **Flutter**: >= 3.0.0
- **Dart**: >= 3.0.0 < 4.0.0
- **Firebase Project**: royaldoor86-e6489
- **Node.js**: >= 20 (لـ Cloud Functions)

### خطوات التثبيت

1. **استنساخ المشروع**
```bash
git clone https://github.com/royaldoor86/royaldoor.git
cd royaldoor
```

2. **تثبيت الاعتماديات**
```bash
flutter pub get
```

3. **تكوين Firebase**
```bash
flutter pub global activate flutterfire_cli
flutterfire configure
```

4. **تشغيل التطبيق**
```bash
flutter run
```

## 🔧 التطوير

### المتطلبات الإضافية
- **Android Studio** أو **Xcode** (للمنصات الأصلية)
- **Firebase CLI**: للنشر والاختبار
- **Agora Credentials**: للصوت والفيديو

### أوامر مفيدة

```bash
# تنظيف المشروع
flutter clean
flutter pub get

# فحص الأخطاء
flutter analyze

# تشغيل الاختبارات
flutter test

# بناء APK
flutter build apk --release

# بناء IPA
flutter build ios --release

# نشر Cloud Functions
cd functions
npm run deploy
```

## 📦 الاعتماديات الرئيسية

### Firebase
- `firebase_core` - التهيئة الأساسية
- `firebase_auth` - المصادقة
- `cloud_firestore` - قاعدة البيانات
- `firebase_storage` - تخزين الملفات
- `firebase_messaging` - الإشعارات
- `firebase_analytics` - التحليل

### الاتصالات
- `agora_rtc_engine` - صوت وفيديو
- `agora_rtm` - رسائل فورية
- `socket_io_client` - WebSockets

### وسائط
- `flutter_sound` - تسجيل صوتي
- `just_audio` - تشغيل صوتي
- `video_player` - تشغيل الفيديو
- `image_picker` - اختيار الصور

### التخزين
- `hive` - قاعدة بيانات محلية
- `shared_preferences` - الإعدادات
- `flutter_secure_storage` - تخزين آمن

## 🔐 الأمان

### قواعد Firestore
```
firestore.rules - قوانين أمان شاملة لقاعدة البيانات
```

### قواعد Realtime Database
```
database.rules.json - قوانين أمان لـ Realtime Database
```

### التشفير
- SHA-256 لكلمات المرور
- AES-256 للبيانات الحساسة
- HTTPS لجميع الاتصالات

## 📊 هيكل البيانات

### المستخدمون (users)
```
{
  uid: string
  email: string
  name: string
  phone: string
  avatar: string
  level: number
  coins: number
  gems: number
  createdAt: timestamp
}
```

### الرسائل (messages)
```
{
  id: string
  senderId: string
  receiverId: string
  content: string
  mediaUrl: string
  createdAt: timestamp
  isRead: boolean
}
```

### المنشورات (posts)
```
{
  id: string
  userId: string
  content: string
  images: array
  likes: number
  comments: number
  createdAt: timestamp
}
```

## 🎯 المسائل المعروفة

- ⚠️ Web version محدودة (يعمل على الأساسيات فقط)
- ⚠️ Windows/Linux versions قد تحتاج اختبار إضافي

## 🛠️ الصيانة الحالية

تم حل المشاكل التالية:
- ✅ إصلاح Firebase iOS Bundle ID
- ✅ حذف الملفات المؤقتة القديمة
- ✅ توحيد Cloud Functions (حذف firebase_functions القديم)
- ✅ تنظيف مجلدات Unity غير المستخدمة
- ✅ تحديث .gitignore

## 📝 المساهمة

نرحب بالمساهمات! يرجى:
1. عمل Fork للمشروع
2. إنشاء فرع للميزة (`git checkout -b feature/amazing-feature`)
3. الالتزام بالتغييرات (`git commit -m 'Add amazing feature'`)
4. دفع الفرع (`git push origin feature/amazing-feature`)
5. فتح Pull Request

## 📄 الترخيص

هذا المشروع مرخص بموجب MIT License - انظر ملف [LICENSE](LICENSE) للتفاصيل.

## 📞 الدعم والتواصل

- **البريد الإلكتروني**: royaldoor86@gmail.com
- **GitHub Issues**: للإبلاغ عن المشاكل والطلبات

## 👥 الفريق

تم تطوير هذا المشروع بواسطة فريق Royal Door.

---

**نسخة**: 1.0.0+12  
**آخر تحديث**: May 4, 2026  
**الحالة**: ✅ قيد التطوير النشط
