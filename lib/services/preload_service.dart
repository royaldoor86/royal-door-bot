import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// بدء عملية التحميل المسبق الشاملة
  Future<void> init(BuildContext context) async {
    debugPrint('🚀 PreloadService: Starting background assets loading...');
    
    // تشغيل العمليات بالتوازي لضمان السرعة
    Future.wait([
      _preloadGifts(context),
      _preloadStoreItems(context),
      _preloadDiaries(context),
      _preloadStories(context),
    ]);
  }

  /// تحميل هدايا الغرف الصوتية
  Future<void> _preloadGifts(BuildContext context) async {
    try {
      final snap = await _db.collection('gifts').where('isActive', isEqualTo: true).limit(50).get();
      for (var doc in snap.docs) {
        final url = doc.data()['imageUrl'] as String?;
        if (url != null) _cacheImage(context, url);
        
        // إذا كانت الهدية تحتوي على تأثير Lottie أو فيديو
        final effectUrl = doc.data()['effectUrl'] as String?;
        if (effectUrl != null && effectUrl.contains('.mp4')) {
          _cacheVideo(effectUrl);
        }
      }
    } catch (e) {
      debugPrint('Preload Error (Gifts): $e');
    }
  }

  /// تحميل منتجات المتجر الملكي (إطارات، مركبات، الخ)
  Future<void> _preloadStoreItems(BuildContext context) async {
    final collections = ['frames', 'vehicles', 'entry_effects', 'covers', 'bubbles'];
    for (var col in collections) {
      try {
        final snap = await _db.collection(col).where('isActive', isEqualTo: true).limit(20).get();
        for (var doc in snap.docs) {
          final url = doc.data()['imageUrl'] as String?;
          if (url != null) _cacheImage(context, url);
          
          final previewUrl = doc.data()['previewUrl'] as String?;
          if (previewUrl != null) _cacheImage(context, previewUrl);
        }
      } catch (e) {
        debugPrint('Preload Error ($col): $e');
      }
    }
  }

  /// تحميل صور اليوميات (المنشورات)
  Future<void> _preloadDiaries(BuildContext context) async {
    try {
      final snap = await _db.collection('posts').orderBy('createdAt', descending: true).limit(15).get();
      for (var doc in snap.docs) {
        final url = doc.data()['imageUrl'] as String?;
        if (url != null) _cacheImage(context, url);
      }
    } catch (e) {
      debugPrint('Preload Error (Posts): $e');
    }
  }

  /// تحميل صور وفيديوهات القصص (Stories)
  Future<void> _preloadStories(BuildContext context) async {
    try {
      final now = DateTime.now();
      final snap = await _db.collection('stories')
          .where('createdAt', isGreaterThan: now.subtract(const Duration(hours: 24)))
          .limit(20)
          .get();
          
      for (var doc in snap.docs) {
        final imgUrl = doc.data()['imageUrl'] as String?;
        if (imgUrl != null) _cacheImage(context, imgUrl);
        
        final vidUrl = doc.data()['videoUrl'] as String?;
        if (vidUrl != null) _cacheVideo(vidUrl);
      }
    } catch (e) {
      debugPrint('Preload Error (Stories): $e');
    }
  }

  void _cacheImage(BuildContext context, String url) {
    if (url.isEmpty || _cachedUrls.contains(url)) return;
    
    // استخدام precacheImage من Flutter لضمان وجود الصورة في ذاكرة الـ GPU
    precacheImage(CachedNetworkImageProvider(url), context).then((_) {
      _cachedUrls.add(url);
    }).catchError((_) {});
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
