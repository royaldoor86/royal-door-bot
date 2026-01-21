// lib/services/storage_service.dart

import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String _currentUid() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('المستخدم غير مسجل');
    return user.uid;
  }

  /// 🏠 رفع صورة الغرفة الصوتية (تم تبسيط المسار لحل مشكلة الصلاحيات)
  static Future<String> uploadRoomImage(File imageFile) async {
    final fileName = 'room_${DateTime.now().millisecondsSinceEpoch}.jpg';
    // رفع الصورة إلى مجلد عام مسموح بالكتابة فيه للمسجلين
    final ref = _storage.ref().child('rooms_images').child(fileName);
    final uploadTask = await ref.putFile(
        imageFile, SettableMetadata(contentType: 'image/jpeg'));
    return await uploadTask.ref.getDownloadURL();
  }

  /// 🎨 رفع ثيم الروم الملكي وترجع رابط URL
  static Future<String> uploadRoomTheme(String themeName, File file) async {
    final ext = file.path.split('.').last.toLowerCase();
    final fileName = 'theme_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final ref = _storage.ref().child('room_themes').child(fileName);

    final uploadTask = await ref.putFile(
      file,
      SettableMetadata(contentType: _getContentType(ext)),
    );
    return await uploadTask.ref.getDownloadURL();
  }

  /// 🏆 رفع صورة البطولة وترجع رابط URL
  static Future<String> uploadTournamentImage(File file) async {
    final ext = file.path.split('.').last.toLowerCase();
    final fileName = 'tour_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final ref = _storage.ref().child('tournaments').child(fileName);

    final uploadTask = await ref.putFile(
      file,
      SettableMetadata(contentType: _getContentType(ext)),
    );
    return await uploadTask.ref.getDownloadURL();
  }

  /// 🖼️ رفع إطار ملكي وترجع رابط URL
  static Future<String> uploadAvatarFrame(String frameName, File file) async {
    final ext = file.path.split('.').last.toLowerCase();
    final fileName = 'frame_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final ref = _storage.ref().child('avatar_frames').child(fileName);

    final uploadTask = await ref.putFile(
      file,
      SettableMetadata(contentType: _getContentType(ext)),
    );
    return await uploadTask.ref.getDownloadURL();
  }

  /// Castle رفع شعار العائلة
  static Future<String> uploadFamilyLogo(
      String familyId, File imageFile) async {
    final ref =
        _storage.ref().child('families').child(familyId).child('logo.jpg');
    final uploadTask = await ref.putFile(
        imageFile, SettableMetadata(contentType: 'image/jpeg'));
    return await uploadTask.ref.getDownloadURL();
  }

  /// 📸 رفع صور اليوميات
  static Future<String> uploadDailyPostImage(File imageFile) async {
    final uid = _currentUid();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('daily_posts').child(uid).child(fileName);
    final uploadTask = await ref.putFile(
        imageFile, SettableMetadata(contentType: 'image/jpeg'));
    return await uploadTask.ref.getDownloadURL();
  }

  /// 🎥 رفع فيديو يومي وترجع رابط URL
  static Future<String> uploadDailyPostVideo(File videoFile) async {
    final uid = _currentUid();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
    final ref = _storage.ref().child('daily_posts').child(uid).child(fileName);
    final uploadTask = await ref.putFile(
      videoFile,
      SettableMetadata(contentType: 'video/mp4'),
    );
    return await uploadTask.ref.getDownloadURL();
  }

  /// 💬 رفع ملف دردشة (صورة/فيديو/ملف) لمسار الدردشة
  static Future<String> uploadMessageFile(
      String chatId, String messageId, File file, String ext) async {
    final uid = _currentUid();
    final fileName = '$messageId.$ext';
    final ref =
        _storage.ref().child('chats').child(chatId).child(uid).child(fileName);
    final uploadTask = await ref.putFile(
      file,
      SettableMetadata(contentType: _getContentType(ext)),
    );
    return await uploadTask.ref.getDownloadURL();
  }

  static String _getContentType(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  StorageService._();
}
