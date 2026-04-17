import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class AdManager {
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  RewardedAd? _rewardedAd;
  bool _isLoading = false;
  
  // معرفات الإعلانات
  final String _rewardedAdUnitId = kDebugMode 
      ? 'ca-app-pub-3940256099942544/5224354917' 
      : 'ca-app-pub-3609643361862120/3056897690';

  final String _bannerAdUnitId = kDebugMode
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-3609643361862120/4739033429';
  
  final StreamController<bool> _adStatusController = StreamController<bool>.broadcast();
  Stream<bool> get adStatusStream => _adStatusController.stream;

  bool get isLoaded => _rewardedAd != null;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    await MobileAds.instance.initialize();
    loadRewardedAd();
  }

  // دالة لجلب إعلان بانر
  BannerAd getBannerAd() {
    return BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
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

    debugPrint("AdManager: Starting to load ad...");

    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint("AdManager: Ad loaded successfully!");
          _rewardedAd = ad;
          _isLoading = false;
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
          _adStatusController.add(false);
          // محاولة ذكية: زيادة وقت الانتظار تدريجياً أو المحاولة بعد 15 ثانية
          Future.delayed(const Duration(seconds: 15), () => loadRewardedAd());
        },
      ),
    );
  }

  void showRewardedAd({required Function(RewardItem) onUserEarnedReward, VoidCallback? onAdFailed}) {
    if (_rewardedAd != null) {
      _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
        onUserEarnedReward(reward);
      });
    } else {
      debugPrint("AdManager: No ad available to show");
      onAdFailed?.call();
      loadRewardedAd();
    }
  }
}
