import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';

class RecordingService extends ChangeNotifier {
  final AudioRecorder _audioRecorder = AudioRecorder();

  bool _isRecording = false;
  bool _isStarting = false;
  bool _isRecordingLocked = false;
  bool _isSendingVoice = false;
  String? _recordingPath;
  int _recordingDuration = 0;
  DateTime? _lastVoiceTime;
  Timer? _recordingTimer;
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  double _currentAmplitude = -160.0;
  String? _uploadError;

  // Getters
  bool get isRecording => _isRecording;
  bool get isRecordingLocked => _isRecordingLocked;
  bool get isSendingVoice => _isSendingVoice;
  int get recordingDuration => _recordingDuration;
  String? get recordingPath => _recordingPath;
  double get currentAmplitude => _currentAmplitude;
  String? get uploadError => _uploadError;

  // Constants
  static const int floodProtectionSeconds = 1;
  static const int minFileSizeBytes = 300;
  static const int maxWaitFileWriteMs = 5000;
  static const int uploadTimeoutSeconds = 45;

  /// Start recording voice
  Future<void> startRecording() async {
    if (_isStarting) return;
    try {
      debugPrint('[RecordingService] Starting recording...');
      _isStarting = true;

      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        throw Exception('Microphone permission denied');
      }

      // Stop previous recording
      try {
        await _audioRecorder.stop().timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            debugPrint('[RecordingService] Previous recorder stop timed out');
            return null;
          },
        );
      } catch (e) {
        debugPrint('[RecordingService] Previous recorder stop error: $e');
      }

      final directory =
          await getTemporaryDirectory(); // Use temp dir for recording
      _recordingPath =
          '${directory.path}/rec_${DateTime.now().millisecondsSinceEpoch}.m4a';

      const recordConfig = RecordConfig(
        encoder: AudioEncoder.aacLc,
        sampleRate: 44100, // Better quality
        numChannels: 1,
        bitRate: 128000,
      );

      await _audioRecorder.start(recordConfig, path: _recordingPath!);

      _isRecording = true;
      _isStarting = false;
      _isRecordingLocked = false;
      _recordingDuration = 0;
      _currentAmplitude = -160.0;

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordingDuration++;
        notifyListeners();
      });

      // Monitor amplitude for visualizer
      _amplitudeSubscription = _audioRecorder
          .onAmplitudeChanged(const Duration(milliseconds: 100))
          .listen((amp) {
        _currentAmplitude = amp.current;
        notifyListeners();
      });

      debugPrint('[RecordingService] Recording started at: $_recordingPath');
      notifyListeners();
    } catch (e) {
      debugPrint('[RecordingService] Recording error: $e');
      _isRecording = false;
      _isStarting = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Lock recording (prevent accidental cancellation)
  void lockRecording() {
    _isRecordingLocked = true;
    debugPrint('[RecordingService] Recording locked');
    notifyListeners();
  }

  /// Cancel recording without sending
  Future<void> cancelRecording() async {
    try {
      _recordingTimer?.cancel();
      _amplitudeSubscription?.cancel();
      
      if (_isStarting) {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (await _audioRecorder.isRecording()) {
        await _audioRecorder.stop();
      }

      if (_recordingPath != null) {
        try {
          final file = File(_recordingPath!);
          if (await file.exists()) {
            await file.delete();
            debugPrint(
                '[RecordingService] Recording cancelled and file deleted');
          }
        } catch (e) {
          debugPrint(
              '[RecordingService] Error deleting cancelled recording: $e');
        }
      }

      _isRecording = false;
      _isRecordingLocked = false;
      _recordingDuration = 0;
      _recordingPath = null;
      notifyListeners();
    } catch (e) {
      debugPrint('[RecordingService] Error cancelling recording: $e');
      rethrow;
    }
  }

  /// Wait for file to be fully written
  Future<bool> _waitForFileWriteCompletion(File file) async {
    int lastSize = 0;
    int stableCount = 0;
    const int checkIntervalMs = 100;
    const int stableThreshold = 3;

    final stopwatch = Stopwatch()..start();

    while (stopwatch.elapsedMilliseconds < maxWaitFileWriteMs) {
      try {
        if (!await file.exists()) return false;
        int currentSize = await file.length();

        if (currentSize == lastSize && currentSize > 0) {
          stableCount++;
          if (stableCount >= stableThreshold) {
            debugPrint(
                '[RecordingService] File write completed. Final size: $currentSize bytes');
            return true;
          }
        } else {
          stableCount = 0;
          lastSize = currentSize;
        }

        await Future.delayed(const Duration(milliseconds: checkIntervalMs));
      } catch (e) {
        debugPrint('[RecordingService] Error checking file size: $e');
        return false;
      }
    }

    debugPrint(
        '[RecordingService] File write completion timeout after ${stopwatch.elapsedMilliseconds}ms');
    return lastSize > 0;
  }

  /// Stop and Upload recording to Firebase with improved error handling
  Future<String> stopAndUploadRecording(String roomId) async {
    _recordingTimer?.cancel();
    _amplitudeSubscription?.cancel();
    _uploadError = null;

    try {
      if (_isStarting) {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      // Stop recording
      await _audioRecorder.stop().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('[RecordingService] Stop recording timeout');
          return null;
        },
      );

      _isRecording = false;
      notifyListeners();

      if (_recordingPath == null || _recordingPath!.isEmpty) {
        throw Exception('لم يتم بدء التسجيل');
      }

      File file = File(_recordingPath!);

      // Check if file exists
      if (!await file.exists()) {
        throw Exception('ملف التسجيل مفقود');
      }

      // Wait for file to be fully written
      bool fileWriteCompleted = await _waitForFileWriteCompletion(file);
      if (!fileWriteCompleted) {
        try {
          if (await file.exists()) await file.delete();
        } catch (e) {
          debugPrint('[RecordingService] Error deleting incomplete file: $e');
        }
        throw Exception('لم يتم كتابة الملف بشكل صحيح');
      }

      int fileSize = await file.length();
      debugPrint('[RecordingService] File size: $fileSize bytes');

      // Validate file size
      if (fileSize < minFileSizeBytes) {
        try {
          if (await file.exists()) await file.delete();
        } catch (e) {
          debugPrint('[RecordingService] Error deleting small file: $e');
        }
        throw Exception('الرسالة قصيرة جداً - سجل لمدة أطول');
      }

      return await _uploadFileToFirebase(file, roomId);
    } catch (e) {
      _uploadError = e.toString().replaceAll('Exception: ', '');
      debugPrint('[RecordingService] Error in stopAndUploadRecording: $e');
      notifyListeners();
      rethrow;
    }
  }

  /// Upload file to Firebase Storage with retry logic
  Future<String> _uploadFileToFirebase(File file, String roomId) async {
    String fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
    Reference storageRef =
        FirebaseStorage.instance.ref().child('chat_media/$roomId/$fileName');

    debugPrint('[RecordingService] Starting upload to Firebase Storage...');

    int retryCount = 0;
    const int maxRetries = 2;

    while (retryCount <= maxRetries) {
      try {
        UploadTask uploadTask = storageRef.putFile(
          file,
          SettableMetadata(
            contentType: 'audio/mp4',
            customMetadata: {
              'type': 'voice_message',
              'duration': _recordingDuration.toString(),
            },
          ),
        );

        TaskSnapshot snapshot = await uploadTask.timeout(
          const Duration(seconds: 45),
          onTimeout: () {
            uploadTask.cancel();
            throw TimeoutException('فشل رفع الصوت - انتهت مهلة الوقت');
          },
        );

        String downloadUrl = await snapshot.ref.getDownloadURL();

        // Clean up the temporary file
        try {
          if (await file.exists()) await file.delete();
        } catch (e) {
          debugPrint('[RecordingService] Error deleting temp file: $e');
        }

        debugPrint('[RecordingService] Upload successful: $downloadUrl');
        _uploadError = null;
        return downloadUrl;
      } on TimeoutException {
        debugPrint(
            '[RecordingService] Upload timeout - Retry $retryCount/$maxRetries');
        retryCount++;
        if (retryCount > maxRetries) {
          throw Exception('فشل رفع الصوت - يرجى التحقق من الاتصال');
        }
        await Future.delayed(Duration(seconds: retryCount));
      } catch (e) {
        debugPrint('[RecordingService] Upload error: $e');
        retryCount++;
        if (retryCount > maxRetries) {
          throw Exception('فشل رفع التسجيل الصوتي');
        }
        await Future.delayed(Duration(seconds: retryCount));
      }
    }

    throw Exception('فشل رفع الصوت بعد عدة محاولات');
  }

  /// Upload recording to Firebase (Legacy method compatible with old code)
  Future<String> uploadRecording(String roomId) async {
    return stopAndUploadRecording(roomId);
  }

  /// Check flood protection - returns error message if too soon, null otherwise
  String? checkFloodProtection() {
    if (_lastVoiceTime != null) {
      final diff = DateTime.now().difference(_lastVoiceTime!);
      debugPrint(
          '[RecordingService] Flood check: Last voice sent ${diff.inSeconds}s ago, threshold: ${floodProtectionSeconds}s');
      if (diff.inSeconds < floodProtectionSeconds) {
        final waitSeconds = floodProtectionSeconds - diff.inSeconds;
        final message =
            'يرجى الانتظار ${waitSeconds > 0 ? waitSeconds : 1} ثانية قبل إرسال رسالة صوتية أخرى';
        debugPrint('[RecordingService] Flood protection triggered: $message');
        return message;
      }
    }
    debugPrint('[RecordingService] Flood protection check passed');
    return null;
  }

  /// Mark voice message as sent (update last voice time)
  void markVoiceSent() {
    _lastVoiceTime = DateTime.now();
    debugPrint(
        '[RecordingService] Voice message marked as sent at: $_lastVoiceTime');
    debugPrint(
        '[RecordingService] Next voice message can be sent after: ${_lastVoiceTime!.add(const Duration(seconds: floodProtectionSeconds))}');
  }

  /// Reset recording state
  void resetRecording() {
    _isRecording = false;
    _isRecordingLocked = false;
    _isSendingVoice = false;
    _recordingDuration = 0;
    _recordingPath = null;
    _recordingTimer?.cancel();
    _amplitudeSubscription?.cancel();
    notifyListeners();
  }

  /// Set sending state
  void setIsSendingVoice(bool value) {
    _isSendingVoice = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _amplitudeSubscription?.cancel();
    _audioRecorder.dispose();
    super.dispose();
  }
}
