# RoyalDoor Telegram Bot

بوت تيليجرام متكامل لإدارة التحديات، الشارات، الدعم الفني، الجوائز، والتكامل مع خدمات خارجية.

## المتطلبات
- python-telegram-bot >= 20.0
- firebase-admin
- google-cloud-firestore

## التشغيل
1. ضع متغير البيئة `BOT_TOKEN` في النظام أو ملف .env
2. شغل البوت:

```bash
python royaldoor_bot.py
```

## الملفات المضمنة
- royaldoor_bot.py (نقطة التشغيل الرئيسية)
- lib/royal_door_bot/* (جميع وظائف البوت)
- requirements.txt (جميع المتطلبات)

## ملاحظات
- تأكد من إعداد بيانات Firebase إذا كنت تستخدم الميزات المرتبطة بها.
- يمكن تخصيص الأوامر والردود من خلال ملفات handlers و STRINGS.
# flutter_application_1

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
