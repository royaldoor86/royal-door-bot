// lib/services/media_uploader.dart

import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';
import 'package:flutter/foundation.dart';

class MediaUploader {
  MediaUploader._();

  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// 🔹 ضغط صورة قبل الرفع
  static Future<Uint8List?> _compressImage(
    dynamic file, {
    int minWidth = 1080,
    int minHeight = 1080,
    int quality = 75, 
  }) async {
    if (kIsWeb) {
      // Web: Read bytes directly (compression not supported on web)
      if (file is XFile) {
        return await file.readAsBytes();
      }
      return null;
    }
    
    // Mobile: Compress image
    final result = await FlutterImageCompress.compressWithFile(
      (file as File).absolute.path,
      minWidth: minWidth,
      minHeight: minHeight,
      quality: quality,
      format: CompressFormat.jpeg,
    );
    return result;
  }

  /// 📸 رفع صورة مضغوطة إلى Storage
  static Future<String> uploadCompressedImage({
    required dynamic file,
    required String pathInStorage, 
  }) async {
    final Uint8List? compressedBytes = await _compressImage(file);

    if (compressedBytes == null) {
      throw Exception('فشل ضغط الصورة');
    }

    final ref = _storage.ref().child(pathInStorage);

    final uploadTask = await ref.putData(
      compressedBytes,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final url = await uploadTask.ref.getDownloadURL();
    return url;
  }

  /// 🎥 ضغط فيديو قبل الرفع
  static Future<dynamic> _compressVideo(
    dynamic file, {
    VideoQuality quality = VideoQuality.MediumQuality,
  }) async {
    if (kIsWeb) {
      // Web: Return file as-is (compression not supported on web)
      return file;
    }
    
    await VideoCompress.setLogLevel(0);

    final info = await VideoCompress.compressVideo(
      (file as File).path,
      quality: quality, 
      deleteOrigin: false, 
    );

    return info?.file;
  }

  /// 🎥 رفع فيديو مضغوط إلى Storage
  static Future<String> uploadCompressedVideo({
    required dynamic file,
    required String pathInStorage, 
  }) async {
    final compressedFile = await _compressVideo(file);

    if (compressedFile == null) {
      throw Exception('فشل ضغط الفيديو');
    }

    final ref = _storage.ref().child(pathInStorage);

    if (kIsWeb && compressedFile is XFile) {
      // Web: Use XFile
      final bytes = await compressedFile.readAsBytes();
      final uploadTask = await ref.putData(
        bytes,
        SettableMetadata(contentType: 'video/mp4'),
      );
      final url = await uploadTask.ref.getDownloadURL();
      return url;
    } else {
      // Mobile: Use File
      final uploadTask = await ref.putFile(
        compressedFile as File,
        SettableMetadata(contentType: 'video/mp4'),
      );
      final url = await uploadTask.ref.getDownloadURL();
      return url;
    }
  }

  /// 🎙️ رفع ملف صوتي
  static Future<String> uploadAudioFile({
    required dynamic file,
    required String pathInStorage,
  }) async {
    final ref = _storage.ref().child(pathInStorage);
    
    if (kIsWeb && file is XFile) {
      // Web: Use XFile
      final bytes = await file.readAsBytes();
      final uploadTask = await ref.putData(
        bytes,
        SettableMetadata(contentType: 'audio/m4a'),
      );
      final url = await uploadTask.ref.getDownloadURL();
      return url;
    } else {
      // Mobile: Use File
      final uploadTask = await ref.putFile(
        file as File,
        SettableMetadata(contentType: 'audio/m4a'),
      );
      final url = await uploadTask.ref.getDownloadURL();
      return url;
    }
  }
}
