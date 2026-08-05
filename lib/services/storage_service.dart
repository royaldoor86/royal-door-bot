// lib/services/storage_service.dart

import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:cross_file/cross_file.dart';

class StorageService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String _currentUid() {
    final user = _auth.currentUser;
    if (user == null) throw Exception('المستخدم غير مسجل');
    return user.uid;
  }

  /// 🏠 رفع صورة الغرفة الصوتية (تم تبسيط المسار لحل مشكلة الصلاحيات)
  static Future<String> uploadRoomImage(dynamic imageFile) async {
    final fileName = 'room_${DateTime.now().millisecondsSinceEpoch}.jpg';
    // رفع الصورة إلى مجلد عام مسموح بالكتابة فيه للمسجلين
    final ref = _storage.ref().child('rooms_images').child(fileName);
    
    if (kIsWeb) {
      // Web: Use XFile from cross_file
      final xFile = imageFile as XFile;
      final bytes = await xFile.readAsBytes();
      final uploadTask = await ref.putData(
          bytes, SettableMetadata(contentType: 'image/jpeg'));
      return await uploadTask.ref.getDownloadURL();
    } else {
      // Mobile: Use File
      final file = imageFile as File;
      final uploadTask = await ref.putFile(
          file, SettableMetadata(contentType: 'image/jpeg'));
      return await uploadTask.ref.getDownloadURL();
    }
  }

  /// 🎨 رفع ثيم الروم الملكي وترجع رابط URL
  static Future<String> uploadRoomTheme(String themeName, dynamic file) async {
    String ext;
    if (kIsWeb && file is XFile) {
      ext = file.name.split('.').last.toLowerCase();
    } else {
      ext = (file as File).path.split('.').last.toLowerCase();
    }
    final fileName = 'theme_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final path = 'room_themes/$fileName';
    return await _uploadFile(file, path, _getContentType(ext));
  }

  /// 🏆 رفع صورة البطولة وترجع رابط URL
  static Future<String> uploadTournamentImage(dynamic file) async {
    String ext;
    if (kIsWeb && file is XFile) {
      ext = file.name.split('.').last.toLowerCase();
    } else {
      ext = (file as File).path.split('.').last.toLowerCase();
    }
    final fileName = 'tour_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final path = 'tournaments/$fileName';
    return await _uploadFile(file, path, _getContentType(ext));
  }

  /// 🖼️ رفع إطار ملكي وترجع رابط URL
  static Future<String> uploadAvatarFrame(String frameName, dynamic file) async {
    String ext;
    if (kIsWeb && file is XFile) {
      ext = file.name.split('.').last.toLowerCase();
    } else {
      ext = (file as File).path.split('.').last.toLowerCase();
    }
    final fileName = 'frame_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final path = 'avatar_frames/$fileName';
    return await _uploadFile(file, path, _getContentType(ext));
  }

  /// Castle رفع شعار العائلة
  static Future<String> uploadFamilyLogo(
      String familyId, dynamic imageFile) async {
    final path = 'families/$familyId/logo.jpg';
    return await _uploadFile(imageFile, path, 'image/jpeg');
  }

  /// 🏅 رفع شارة العائلة
  static Future<String> uploadFamilyBadge(
      String badgeId, dynamic imageFile) async {
    final path = 'family_badges/$badgeId.jpg';
    return await _uploadFile(imageFile, path, 'image/jpeg');
  }

  /// 📸 رفع صور اليوميات
  static Future<String> uploadDailyPostImage(dynamic imageFile) async {
    final uid = _currentUid();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'daily_posts/$uid/$fileName';
    return await _uploadFile(imageFile, path, 'image/jpeg');
  }

  /// 🎥 رفع فيديو يومي وترجع رابط URL
  static Future<String> uploadDailyPostVideo(dynamic videoFile) async {
    final uid = _currentUid();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
    final path = 'daily_posts/$uid/$fileName';
    return await _uploadFile(videoFile, path, 'video/mp4');
  }

  /// 🏷️ رفع صورة لقصة (Stories) — تحفظ تحت مسار `stories/<uid>/...`
  static Future<String> uploadStoryImage(dynamic imageFile) async {
    final uid = _currentUid();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'stories/$uid/$fileName';
    return await _uploadFile(imageFile, path, 'image/jpeg');
  }

  /// 🎬 رفع فيديو لقصة (Stories)
  static Future<String> uploadStoryVideo(dynamic videoFile) async {
    final uid = _currentUid();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
    final path = 'stories/$uid/$fileName';
    return await _uploadFile(videoFile, path, 'video/mp4');
  }

  /// 🎙️ رفع ملف صوتي لليوميات
  static Future<String> uploadDailyPostAudio(dynamic audioFile) async {
    final uid = _currentUid();
    String ext;
    if (kIsWeb && audioFile is XFile) {
      ext = audioFile.name.split('.').last.toLowerCase();
    } else {
      ext = (audioFile as File).path.split('.').last.toLowerCase();
    }
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$ext';
    final path = 'daily_posts/$uid/$fileName';
    return await _uploadFile(audioFile, path, _getContentType(ext));
  }

  /// مثل uploadStoryImage لكن يرجع خريطة تحتوي downloadUrl و storagePath (fullPath)
  static Future<Map<String, String>> uploadStoryImageWithPath(
      dynamic imageFile) async {
    final uid = _currentUid();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child('stories').child(uid).child(fileName);
    
    if (kIsWeb && imageFile is XFile) {
      final bytes = await imageFile.readAsBytes();
      final task = await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final url = await task.ref.getDownloadURL();
      final path = task.ref.fullPath;
      return {'url': url, 'path': path};
    } else {
      final task = await ref.putFile(
          imageFile as File, SettableMetadata(contentType: 'image/jpeg'));
      final url = await task.ref.getDownloadURL();
      final path = task.ref.fullPath;
      return {'url': url, 'path': path};
    }
  }

  /// مثل uploadStoryVideo لكن يرجع downloadUrl و storagePath
  static Future<Map<String, String>> uploadStoryVideoWithPath(
      dynamic videoFile) async {
    final uid = _currentUid();
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.mp4';
    final ref = _storage.ref().child('stories').child(uid).child(fileName);
    
    if (kIsWeb && videoFile is XFile) {
      final bytes = await videoFile.readAsBytes();
      final task = await ref.putData(bytes, SettableMetadata(contentType: 'video/mp4'));
      final url = await task.ref.getDownloadURL();
      final path = task.ref.fullPath;
      return {'url': url, 'path': path};
    } else {
      final task = await ref.putFile(
          videoFile as File, SettableMetadata(contentType: 'video/mp4'));
      final url = await task.ref.getDownloadURL();
      final path = task.ref.fullPath;
      return {'url': url, 'path': path};
    }
  }

  /// رفع صورة الملف الشخصي لأي مستخدم (للاستخدام من قبل الأدمن)
  static Future<String> uploadProfileImage(String uid, dynamic imageFile) async {
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = 'profile_pics/$uid/$fileName';
    return await _uploadFile(imageFile, path, 'image/jpeg');
  }

  /// 💬 رفع ملف دردشة (صورة/فيديو/ملف) لمسار الدردشة
  static Future<String> uploadMessageFile(
      String chatId, String messageId, dynamic file, String ext) async {
    final uid = _currentUid();
    final fileName = '$messageId.$ext';
    final path = 'chats/$chatId/$uid/$fileName';
    return await _uploadFile(file, path, _getContentType(ext));
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
      case 'm4a':
        return 'audio/m4a';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  /// 🔹 دالة مساعدة لرفع الملفات (تدعم الويب والموبايل)
  static Future<String> _uploadFile(dynamic file, String path, String contentType) async {
    final ref = _storage.ref().child(path);
    
    if (kIsWeb) {
      // Web: Use XFile from cross_file
      if (file is XFile) {
        final bytes = await file.readAsBytes();
        final uploadTask = await ref.putData(bytes, SettableMetadata(contentType: contentType));
        return await uploadTask.ref.getDownloadURL();
      } else if (file is File) {
        // Fallback for File on web (shouldn't happen but just in case)
        final bytes = await file.readAsBytes();
        final uploadTask = await ref.putData(bytes, SettableMetadata(contentType: contentType));
        return await uploadTask.ref.getDownloadURL();
      }
    } else {
      // Mobile: Use File
      if (file is File) {
        final uploadTask = await ref.putFile(file, SettableMetadata(contentType: contentType));
        return await uploadTask.ref.getDownloadURL();
      }
    }
    
    throw Exception('نوع الملف غير مدعوم');
  }

  StorageService._();
}
