import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt_lib;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/rewards_constants.dart';

/// خدمة التشفير والأمان لنظام المكافآت
class EncryptionService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static late final encrypt_lib.Key _encryptionKey;
  static late final encrypt_lib.IV _iv;
  static bool _initialized = false;

  /// تهيئة خدمة التشفير
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      // محاولة استرجاع المفتاح من التخزين الآمن
      String? storedKey =
          await _secureStorage.read(key: RewardsConstants.encryptionKey);

      if (storedKey == null) {
        // توليد مفتاح جديد إذا لم يكن موجوداً
        _encryptionKey =
            encrypt_lib.Key.fromSecureRandom(RewardsConstants.keyLength);
        _iv = encrypt_lib.IV.fromSecureRandom(RewardsConstants.ivLength);

        // حفظ المفتاح بشكل آمن
        await _secureStorage.write(
          key: RewardsConstants.encryptionKey,
          value: base64Encode(_encryptionKey.bytes + _iv.bytes),
        );
      } else {
        // استرجاع المفتاح المحفوظ
        Uint8List keyData = Uint8List.fromList(base64Decode(storedKey));
        _encryptionKey =
            encrypt_lib.Key(keyData.sublist(0, RewardsConstants.keyLength));
        _iv = encrypt_lib.IV(keyData.sublist(RewardsConstants.keyLength));
      }

      _initialized = true;
    } catch (e) {
      throw Exception('${RewardsConstants.errorEncryptionFailed}: $e');
    }
  }

  /// تشفير بيانات حساسة
  static String encryptSensitive(String plaintext) {
    _ensureInitialized();

    try {
      final encrypter = encrypt_lib.Encrypter(encrypt_lib.AES(_encryptionKey));
      final encrypted = encrypter.encrypt(plaintext, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      throw Exception('${RewardsConstants.errorEncryptionFailed}: $e');
    }
  }

  /// تشفير بيانات (non-static wrapper for instance calls)
  String encrypt(String plaintext) {
    return encryptSensitive(plaintext);
  }

  /// فك تشفير البيانات
  static String decryptSensitive(String ciphertext) {
    _ensureInitialized();

    try {
      final encrypter = encrypt_lib.Encrypter(encrypt_lib.AES(_encryptionKey));
      final decrypted = encrypter.decrypt64(ciphertext, iv: _iv);
      return decrypted;
    } catch (e) {
      throw Exception('${RewardsConstants.errorDecryptionFailed}: $e');
    }
  }

  /// حساب hash آمن (للمقارنة بدون تخزين الأصلي)
  static String hashPassword(String password, [String? salt]) {
    final saltToUse = salt ?? _generateSalt();
    final hash = sha256.convert(utf8.encode('$password$saltToUse'));
    return '$hash:$saltToUse';
  }

  /// التحقق من hash
  static bool verifyPassword(String password, String hash) {
    try {
      final parts = hash.split(':');
      if (parts.length != 2) return false;

      final storedHash = parts[0];
      final salt = parts[1];

      final computedHash = sha256.convert(utf8.encode('$password$salt'));
      return computedHash.toString() == storedHash;
    } catch (e) {
      return false;
    }
  }

  /// تشفير بيانات متعددة الحقول
  static Map<String, dynamic> encryptSensitiveFields(
    Map<String, dynamic> data,
    List<String> sensitiveFields,
  ) {
    final encrypted = Map<String, dynamic>.from(data);

    for (final field in sensitiveFields) {
      if (encrypted.containsKey(field) && encrypted[field] != null) {
        encrypted[field] = encryptSensitive(encrypted[field].toString());
      }
    }

    return encrypted;
  }

  /// فك تشفير بيانات متعددة الحقول
  static Map<String, dynamic> decryptSensitiveFields(
    Map<String, dynamic> data,
    List<String> sensitiveFields,
  ) {
    final decrypted = Map<String, dynamic>.from(data);

    for (final field in sensitiveFields) {
      if (decrypted.containsKey(field) && decrypted[field] != null) {
        try {
          decrypted[field] = decryptSensitive(decrypted[field].toString());
        } catch (e) {
          // في حالة فشل فك التشفير، نترك البيانات كما هي
          decrypted[field] = '[ENCRYPTED_DATA_ERROR]';
        }
      }
    }

    return decrypted;
  }

  /// توليد salt عشوائي
  static String _generateSalt([int length = 16]) {
    final random = Random.secure();
    final values = List<int>.generate(length, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  /// التأكد من تهيئة الخدمة
  static void _ensureInitialized() {
    if (!_initialized) {
      throw Exception(
          'EncryptionService not initialized. Call initialize() first.');
    }
  }

  /// إعادة تعيين المفاتيح (للطوارئ فقط)
  static Future<void> resetKeys() async {
    await _secureStorage.delete(key: RewardsConstants.encryptionKey);
    _initialized = false;
    await initialize();
  }

  /// التحقق من صحة البيانات المشفرة
  static bool isValidEncryptedData(String data) {
    try {
      base64Decode(data);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// تشفير ملفات (للصور ووثائق الهوية)
  static Future<String> encryptFile(List<int> fileBytes) async {
    _ensureInitialized();

    try {
      final encrypter = encrypt_lib.Encrypter(encrypt_lib.AES(_encryptionKey));
      final encrypted =
          encrypter.encryptBytes(Uint8List.fromList(fileBytes), iv: _iv);
      return encrypted.base64;
    } catch (e) {
      throw Exception('فشل في تشفير الملف: $e');
    }
  }

  /// فك تشفير ملفات
  static Future<List<int>> decryptFile(String encryptedFile) async {
    _ensureInitialized();

    try {
      final encrypter = encrypt_lib.Encrypter(encrypt_lib.AES(_encryptionKey));
      final decrypted = encrypter.decrypt64(encryptedFile, iv: _iv);
      return decrypted.toString().codeUnits;
    } catch (e) {
      throw Exception('فشل في فك تشفير الملف: $e');
    }
  }
}
