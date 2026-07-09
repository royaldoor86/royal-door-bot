# إعداد iOS لـ Firebase

## خطوات إضافة GoogleService-Info.plist

1. **انتقل إلى وحدة تحكم Firebase**
   - افتح [Firebase Console](https://console.firebase.google.com/)
   - اختر مشروعك: `royaldoor86-e6489`

2. **إضافة تطبيق iOS**
   - انقر على أيقونة iOS (+) لإضافة تطبيق
   - أدخل Bundle ID: `com.royaldoor.live.iOS`
   - انقر على "Register app"

3. **تحميل ملف التكوين**
   - انقر على "Download GoogleService-Info.plist"
   - انقل الملف إلى: `ios/Runner/GoogleService-Info.plist`

4. **تحديث Podfile**
   - افتح `ios/Podfile`
   - تأكد من إضافة:
     ```ruby
     pod 'Firebase/Core'
     pod 'Firebase/Auth'
     pod 'Firebase/Firestore'
     pod 'Firebase/Messaging'
     pod 'Firebase/Storage'
     pod 'Firebase/Database'
     pod 'Firebase/Functions'
     pod 'Firebase/AppCheck'
     ```

5. **تثبيت Pods**
   ```bash
   cd ios
   pod install
   cd ..
   ```

6. **تحديث AppDelegate.swift**
   - تأكد من أن AppDelegate.swift يحتوي على:
   ```swift
   import Firebase
   import FirebaseCore
   import FirebaseAuth
   ```

7. **إضافة إعدادات Capabilities**
   - افتح Xcode: `open ios/Runner.xcworkspace`
   - اختر Runner target
   - في Signing & Capabilities، أضف:
     - Push Notifications
     - Background Modes (Remote notifications)

## ملاحظات مهمة

- ملف Info.plist الحالي يحتوي على إعدادات Firebase لكن يُنصح باستخدام GoogleService-Info.plist الرسمي
- تأكد من أن Bundle ID في Xcode يتطابق مع Bundle ID في Firebase Console
- بعد إضافة GoogleService-Info.plist، يمكنك إزالة الإعدادات اليدوية من Info.plist إذا أردت

## التحقق من الإعداد

بعد إكمال الخطوات، قم بتشغيل التطبيق على جهاز iOS أو محاكي للتحقق من:
- اتصال Firebase
- تسجيل الدخول
- الإشعارات
