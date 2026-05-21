import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class AdManager {
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  RewardedAd? _rewardedAd;
  InterstitialAd? _interstitialAd;
  AppOpenAd? _appOpenAd;
  bool _isLoading = false;
  bool _isInterstitialLoading = false;
  bool _isAppOpenAdLoading = false;
  DateTime? _appOpenLoadTime;

  // معرف إعلان Native
  final String _nativeAdUnitId = kDebugMode 
      ? 'ca-app-pub-3940256099942544/2247696110' 
      : 'ca-app-pub-3609643361862120/5465942371';
  
  // معرفات الإعلانات
  final String _rewardedAdUnitId = kDebugMode 
      ? 'ca-app-pub-3940256099942544/5224354917' 
      : 'ca-app-pub-3609643361862120/3056897690';

  final String _bannerAdUnitId = kDebugMode
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-3609643361862120/4739033429';
  
  final StreamController<bool> _adStatusController = StreamController<bool>.broadcast();
  Stream<bool> get adStatusStream => _adStatusController.stream;

  int _loadAttempts = 0;
  final int _maxAttemptsBeforeFallback = 3;
  bool _fallbackEnabled = false;

  bool get isLoaded => _rewardedAd != null;
  bool get isLoading => _isLoading;
  bool get isFallbackEnabled => _fallbackEnabled;

  Future<void> init() async {
    await MobileAds.instance.initialize();
    
    // إضافة معرفات الأجهزة التجريبية لمنع تقييد الحساب أثناء التطوير
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(testDeviceIds: ["66B9E8C083888B763F1032AB23B18102"]),
    );

    loadRewardedAd();
    loadInterstitialAd();
    loadAppOpenAd();
  }

  void loadAppOpenAd() {
    if (_isAppOpenAdLoading || _appOpenAd != null) return;
    _isAppOpenAdLoading = true;

    AppOpenAd.load(
      adUnitId: kDebugMode 
          ? 'ca-app-pub-3940256099942544/9257395921' 
          : 'ca-app-pub-3609643361862120/1908233772',
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _isAppOpenAdLoading = false;
          _appOpenLoadTime = DateTime.now();
        },
        onAdFailedToLoad: (error) {
          _isAppOpenAdLoading = false;
          debugPrint('AppOpenAd failed to load: $error');
        },
      ),
    );
  }

  void showAppOpenAdIfAvailable() {
    if (_appOpenAd == null) {
      loadAppOpenAd();
      return;
    }

    // صلاحية الإعلان 4 ساعات فقط بحسب سياسة جوجل
    if (_appOpenLoadTime != null && 
        DateTime.now().difference(_appOpenLoadTime!).inHours >= 4) {
      _appOpenAd!.dispose();
      _appOpenAd = null;
      loadAppOpenAd();
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        _appOpenAd = null;
        loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _appOpenAd = null;
        loadAppOpenAd();
      },
    );

    _appOpenAd!.show();
  }

  void loadInterstitialAd() {
    if (_isInterstitialLoading || _interstitialAd != null) return;
    _isInterstitialLoading = true;

    InterstitialAd.load(
      adUnitId: kDebugMode 
          ? 'ca-app-pub-3940256099942544/1033173712' 
          : 'ca-app-pub-3609643361862120/4636906232',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (err) {
          _isInterstitialLoading = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  void showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
    } else {
      loadInterstitialAd();
    }
  }

  // دالة لفتح جدار العروض (Offerwall) عبر IronSource
  void showOfferWall() {
    debugPrint("AdManager: Opening OfferWall...");
    // سيتم استدعاء SDK الخاص بـ IronSource هنا
    // IronSource.showOfferwall();
  }

  // دالة لجلب إعلان Native مدمج
  NativeAd getNativeAd({required void Function() onAdLoaded, required void Function(LoadAdError) onAdFailed}) {
    // ملاحظة: الـ factoryId 'listTile' يجب أن يكون مسجلاً في MainActivity.kt في الجانب الأصلي (Native)
    // إذا كنت تواجه أخطاء Permission Denied أو Factory not found، يرجى التحقق من التسجيل.
    return NativeAd(
      adUnitId: _nativeAdUnitId,
      factoryId: 'listTile', 
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) => onAdLoaded(),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          onAdFailed(error);
        },
      ),
    )..load();
  }

  // دالة لجلب إعلان بانر محسّن
  BannerAd getBannerAd({required AdSize size, VoidCallback? onAdLoaded}) {
    return BannerAd(
      adUnitId: _bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) => onAdLoaded?.call(),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('BannerAd failed to load: $error');
        },
      ),
    )..load();
  }

  void loadRewardedAd() {
    if (_isLoading || _rewardedAd != null) {
      _adStatusController.add(isLoaded);
      return;
    }

    _isLoading = true;
    _adStatusController.add(false);

    debugPrint("AdManager: Starting to load ad... Attempt: ${_loadAttempts + 1}");

    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint("AdManager: Ad loaded successfully!");
          _rewardedAd = ad;
          _isLoading = false;
          _loadAttempts = 0; // Reset attempts on success
          _fallbackEnabled = false;
          _adStatusController.add(true);
          
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              debugPrint("AdManager: Ad dismissed");
              ad.dispose();
              _rewardedAd = null;
              _adStatusController.add(false);
              loadRewardedAd(); // تحميل الإعلان التالي فوراً ليكون جاهزاً
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint("AdManager: Ad failed to show: ${error.message}");
              ad.dispose();
              _rewardedAd = null;
              _adStatusController.add(false);
              loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint("AdManager: Ad failed to load: ${error.message}");
          _isLoading = false;
          _rewardedAd = null;
          _loadAttempts++;
          _adStatusController.add(false);

          if (_loadAttempts >= _maxAttemptsBeforeFallback) {
             debugPrint("AdManager: Max attempts reached. Enabling fallback.");
             _fallbackEnabled = true;
             _adStatusController.add(true); // Signal "Ready" even if it's fallback
          } else {
             // محاولة ذكية: زيادة وقت الانتظار تدريجياً
             int retrySeconds = _loadAttempts * 5; 
             Future.delayed(Duration(seconds: retrySeconds), () => loadRewardedAd());
          }
        },
      ),
    );
  }

  void showRewardedAd({required Function(RewardItem?) onUserEarnedReward, VoidCallback? onAdFailed}) {
    if (_rewardedAd != null) {
      _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
        onUserEarnedReward(reward);
      });
    } else if (_fallbackEnabled) {
      debugPrint("AdManager: Using Fallback Mode (No ad available)");
      onUserEarnedReward(null); // Return null to indicate success via fallback
    } else {
      debugPrint("AdManager: No ad available to show");
      onAdFailed?.call();
      loadRewardedAd();
    }
  }
}
