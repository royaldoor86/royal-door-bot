// lib/services/media_uploader.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:video_compress/video_compress.dart';

class MediaUploader {
  MediaUploader._();

  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// 🔹 ضغط صورة قبل الرفع
  static Future<Uint8List?> _compressImage(
    File file, {
    int minWidth = 1080,
    int minHeight = 1080,
    int quality = 75, 
  }) async {
    final result = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      minWidth: minWidth,
      minHeight: minHeight,
      quality: quality,
      format: CompressFormat.jpeg,
    );
    return result;
  }

  /// 📸 رفع صورة مضغوطة إلى Storage
  static Future<String> uploadCompressedImage({
    required File file,
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
  static Future<File?> _compressVideo(
    File file, {
    VideoQuality quality = VideoQuality.MediumQuality,
  }) async {
    await VideoCompress.setLogLevel(0);

    final info = await VideoCompress.compressVideo(
      file.path,
      quality: quality, 
      deleteOrigin: false, 
    );

    return info?.file;
  }

  /// 🎥 رفع فيديو مضغوط إلى Storage
  static Future<String> uploadCompressedVideo({
    required File file,
    required String pathInStorage, 
  }) async {
    final File? compressedFile = await _compressVideo(file);

    if (compressedFile == null) {
      throw Exception('فشل ضغط الفيديو');
    }

    final ref = _storage.ref().child(pathInStorage);

    final uploadTask = await ref.putFile(
      compressedFile,
      SettableMetadata(contentType: 'video/mp4'),
    );

    final url = await uploadTask.ref.getDownloadURL();
    return url;
  }

  /// 🎙️ رفع ملف صوتي
  static Future<String> uploadAudioFile({
    required File file,
    required String pathInStorage,
  }) async {
    final ref = _storage.ref().child(pathInStorage);
    final uploadTask = await ref.putFile(
      file,
      SettableMetadata(contentType: 'audio/m4a'),
    );
    final url = await uploadTask.ref.getDownloadURL();
    return url;
  }
}
