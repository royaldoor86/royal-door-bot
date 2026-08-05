import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// خدمة التحميل المسبق للأصول (Preloading Service)
/// تهدف لضمان تجربة مستخدم سريعة وسلسة عبر تحميل الصور والفيديوهات في الخلفية
class PreloadService {
  static final PreloadService _instance = PreloadService._internal();
  factory PreloadService() => _instance;
  PreloadService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Set<String> _cachedUrls = {};

  // قائمة سوداء للروابط المشكلة (صور تالفة أو بصيغة غير مدعومة)
  final Set<String> _blacklistedUrls = {
    'https://firebasestorage.googleapis.com/v0/b/royaldoor86-e6489.firebasestorage.app/o/gifts%2F1771708497494?alt=media&token=ad45a488-5c90-4cec-a8ce-bec6ee97ee0d',
  };

  /// بدء عملية التحميل المسبق الشاملة
  Future<void> init(BuildContext context) async {
    debugPrint('🚀 PreloadService: Starting phased assets loading...');

    // ننتظر حتى استقرار حالة المستخدم، ونحاول التحميل بصمت
    await Future.delayed(const Duration(seconds: 3));

    if (!context.mounted) return;

    try {
      await _preloadGifts(context);
      if (!context.mounted) return;
      await _preloadStoreItems(context);
      if (!context.mounted) return;
      await _preloadDiaries(context);
      if (!context.mounted) return;
      await _preloadStories(context);
    } catch (e) {
      // تجاهل الأخطاء العامة لضمان عدم توقف التطبيق
    }
  }

  /// تحميل هدايا الغرف الصوتية
  Future<void> _preloadGifts(BuildContext context) async {
    try {
      final snap = await _db
          .collection('gifts')
          .where('isActive', isEqualTo: true)
          .limit(30)
          .get();
      if (!context.mounted) return;

      for (var doc in snap.docs) {
        final url = doc.data()['imageUrl'] as String?;
        if (url != null) _cacheImage(context, url);

        final effectUrl = doc.data()['effectUrl'] as String?;
        if (effectUrl != null && effectUrl.contains('.mp4')) {
          _cacheVideo(effectUrl);
        }
      }
    } catch (_) {}
  }

  /// تحميل منتجات المتجر الملكي (إطارات، مركبات، الخ)
  Future<void> _preloadStoreItems(BuildContext context) async {
    final collections = ['frames', 'vehicles', 'entry_effects'];
    for (var col in collections) {
      try {
        final snap = await _db
            .collection(col)
            .where('isActive', isEqualTo: true)
            .limit(10)
            .get();
        if (!context.mounted) return;

        for (var doc in snap.docs) {
          final url = doc.data()['imageUrl'] as String?;
          if (url != null) _cacheImage(context, url);
        }
      } catch (_) {}
    }
  }

  /// تحميل صور اليوميات (المنشورات)
  Future<void> _preloadDiaries(BuildContext context) async {
    try {
      // فقط إذا كان هناك مستخدم مسجل
      if (FirebaseAuth.instance.currentUser == null) return;

      final snap = await _db
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();
      if (!context.mounted) return;

      for (var doc in snap.docs) {
        final url = doc.data()['imageUrl'] as String?;
        if (url != null) _cacheImage(context, url);
      }
    } catch (_) {}
  }

  /// تحميل صور وفيديوهات القصص (Stories)
  Future<void> _preloadStories(BuildContext context) async {
    try {
      if (FirebaseAuth.instance.currentUser == null) return;

      final now = DateTime.now();
      final snap = await _db
          .collection('stories')
          .where('createdAt',
              isGreaterThan: now.subtract(const Duration(hours: 24)))
          .limit(10)
          .get();
      if (!context.mounted) return;

      for (var doc in snap.docs) {
        final imgUrl = doc.data()['imageUrl'] as String?;
        if (imgUrl != null) _cacheImage(context, imgUrl);
      }
    } catch (_) {}
  }

  void _cacheImage(BuildContext context, String url) {
    if (url.isEmpty || !url.startsWith('http') || _cachedUrls.contains(url)) {
      return;
    }
    if (!context.mounted) return;

    // فلتر لحماية الـ Decoder من الروابط المشبوهة
    if (url.length < 15 || url.contains(' ')) return;

    // تجنب الروابط في القائمة السوداء (صور تالفة أو بصيغة غير مدعومة)
    if (_blacklistedUrls.contains(url)) {
      debugPrint('⚠️ PreloadService: Skipping blacklisted image: $url');
      return;
    }

    // فلتر لصيغ الصور المدعومة فقط
    final supportedExtensions = [
      '.jpg',
      '.jpeg',
      '.png',
      '.gif',
      '.webp',
      '.bmp'
    ];
    final cleanUrl = url.split('?').first.toLowerCase();
    final hasSupportedExtension =
        supportedExtensions.any((ext) => cleanUrl.endsWith(ext));

    // إذا لم يكن هناك امتداد واضح، تحقق من وجود معامل alt=media في Firebase Storage
    if (!hasSupportedExtension) {
      if (!url.contains('firebasestorage')) {
        debugPrint(
            '⚠️ PreloadService: Skipping image without supported extension: $url');
        return;
      }
      // لروابط Firebase Storage بدون امتداد، حاول التحميل لكن مع معالجة أخطاء محسنة
    }

    try {
      precacheImage(
        CachedNetworkImageProvider(url),
        context,
        onError: (exception, stackTrace) {
          debugPrint('❌ PreloadService: Failed to precache image: $url');
          debugPrint('   Error: $exception');
          // إضافة الرابط إلى القائمة السوداء إذا فشل التحميل
          _blacklistedUrls.add(url);
        },
      ).then((_) {
        _cachedUrls.add(url);
      }).catchError((e) {
        debugPrint('⚠️ PreloadService: Image cache error (non-critical): $e');
        // إضافة الرابط إلى القائمة السوداء إذا فشل التحميل
        _blacklistedUrls.add(url);
      });
    } catch (e) {
      debugPrint(
          '⚠️ PreloadService: Exception during image caching (non-critical): $e');
      _blacklistedUrls.add(url);
    }
  }

  void _cacheVideo(String url) async {
    if (url.isEmpty || _cachedUrls.contains(url)) return;

    // للتحميل المسبق للفيديو، نقوم بإنشاء وحدة تحكم وتهيئتها ثم التخلص منها
    // هذا سيجعل النظام يقوم بعمل Caching للملف في الذاكرة المؤقتة للهاتف
    try {
      final controller = VideoPlayerController.networkUrl(Uri.parse(url));
      await controller.initialize();
      await controller.dispose();
      _cachedUrls.add(url);
    } catch (e) {
      // ignore errors
    }
  }
}
