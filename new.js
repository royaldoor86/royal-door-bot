rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // السماح للمستخدمين بالقراءة والكتابة في مستنداتهم الخاصة فقط
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // السماح بإنشاء المحفظة والإعدادات والمتابعات للمستخدم الجديد
    match /wallets/{userId} { allow read, write: if request.auth != null && request.auth.uid == userId; }
    match /settings/{userId} { allow read, write: if request.auth != null && request.auth.uid == userId; }
    match /followers/{userId} { allow read, write: if request.auth != null && request.auth.uid == userId; }
    match /follows/{userId} { allow read, write: if request.auth != null && request.auth.uid == userId; }

    // قاعدة عامة لبقية المجموعات (يمكنك تضييقها لاحقاً)
    match /{document=**} {
      allow read, write: if request.auth != null;
    }

    // السماح بقراءة الإعدادات العامة للجميع
    match /system_settings/global {
      allow read: if true;
    }
    match /settings/marquee {
      allow read: if true;
    }
  }
}
