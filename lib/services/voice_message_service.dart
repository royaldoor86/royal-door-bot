import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class VoiceMessageService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _recordingPath;

  /// يتحقق من صلاحية الميكروفون ويطلبها إذا لم تكن ممنوحة.
  Future<bool> _checkPermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) {
      return true;
    }
    final result = await Permission.microphone.request();
    return result.isGranted;
  }

  /// يبدأ تسجيل رسالة صوتية.
  /// يُرجع `true` إذا بدأ التسجيل بنجاح.
  Future<bool> startRecording() async {
    if (await _audioRecorder.isRecording()) {
      if (kDebugMode) {
        print("التسجيل قيد التقدم بالفعل.");
      }
      return false;
    }

    final hasPermission = await _checkPermission();
    if (!hasPermission) {
      if (kDebugMode) {
        print("تم رفض إذن الميكروفون.");
      }
      // يمكنك هنا إظهار رسالة للمستخدم لإعلامه برفض الصلاحية
      return false;
    }

    try {
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'voice_message_${DateTime.now().millisecondsSinceEpoch}.m4a';
      _recordingPath = '${tempDir.path}/$fileName';

      const config = RecordConfig(
        encoder: AudioEncoder.aacLc, // جودة وتوافق ممتاز
        bitRate: 128000,
        sampleRate: 44100,
      );

      await _audioRecorder.start(config, path: _recordingPath!);
      if (kDebugMode) {
        print("بدأ التسجيل في: $_recordingPath");
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print("خطأ في بدء التسجيل: $e");
      }
      _recordingPath = null;
      return false;
    }
  }

  /// يوقف التسجيل الحالي.
  /// يُرجع مسار الملف المسجل في حالة النجاح، وإلا `null`.
  Future<String?> stopRecording() async {
    if (!await _audioRecorder.isRecording()) {
      if (kDebugMode) {
        print("لا يوجد تسجيل قيد التقدم لإيقافه.");
      }
      return null;
    }

    try {
      final path = await _audioRecorder.stop();
      if (kDebugMode) {
        print("توقف التسجيل. الملف في: $path");
      }
      _recordingPath = path;
      return _recordingPath;
    } catch (e) {
      if (kDebugMode) {
        print("خطأ في إيقاف التسجيل: $e");
      }
      await _deleteRecordingFile(); // تنظيف الملف الفاشل
      return null;
    }
  }

  /// يلغي التسجيل الحالي ويحذف الملف المؤقت.
  Future<void> cancelRecording() async {
    if (await _audioRecorder.isRecording()) {
      await _audioRecorder.stop(); // أوقفه أولاً
    }
    await _deleteRecordingFile();
    if (kDebugMode) {
      print("تم إلغاء التسجيل.");
    }
  }

  /// يحذف ملف التسجيل المؤقت إذا كان موجودًا.
  Future<void> _deleteRecordingFile() async {
    if (_recordingPath != null) {
      final file = File(_recordingPath!);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (e) {
          if (kDebugMode) print("خطأ في حذف الملف: $e");
        }
      }
      _recordingPath = null;
    }
  }

  /// يرفع ملف رسالة صوتية إلى Firebase Storage.
  /// يُرجع رابط التنزيل عند النجاح، وإلا `null`.
  Future<String?> uploadVoiceMessage(String filePath, String chatRoomId) async {
    final file = File(filePath);
    if (!await file.exists()) {
      if (kDebugMode) print("الملف المراد رفعه غير موجود: $filePath");
      return null;
    }

    try {
      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      // تنظيم الملفات حسب غرفة المحادثة لإدارة أفضل
      final storagePath = 'chat_voice_messages/$chatRoomId/$fileName';
      final ref = FirebaseStorage.instance.ref().child(storagePath);

      final metadata = SettableMetadata(contentType: 'audio/m4a');

      final uploadTask = await ref.putFile(file, metadata);
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      // تنظيف الملف المحلي بعد الرفع الناجح
      await file.delete();

      return downloadUrl;
    } catch (e) {
      if (kDebugMode) print("خطأ في رفع الرسالة الصوتية: $e");
      return null;
    }
  }

  void dispose() {
    _audioRecorder.dispose();
  }
}
