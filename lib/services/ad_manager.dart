import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class AdManager {
  static final AdManager _instance = AdManager._internal();
  factory AdManager() => _instance;
  AdManager._internal();

  RewardedAd? _rewardedAd;
  bool _isLoading = false;
  final String _adUnitId = 'ca-app-pub-3609643361862120/3056897690';
  
  // Stream to notify UI about ad status changes
  final StreamController<bool> _adStatusController = StreamController<bool>.broadcast();
  Stream<bool> get adStatusStream => _adStatusController.stream;

  RewardedAd? get rewardedAd => _rewardedAd;
  bool get isLoading => _isLoading;
  bool get isLoaded => _rewardedAd != null;

  Future<void> init() async {
    await MobileAds.instance.initialize();
    loadRewardedAd();
  }

  void loadRewardedAd() {
    if (_isLoading || _rewardedAd != null) return;

    _isLoading = true;
    _adStatusController.add(false);

    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint("AdManager: Ad Loaded Successfully");
          _rewardedAd = ad;
          _isLoading = false;
          _adStatusController.add(true);

          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              debugPrint("AdManager: Ad Dismissed");
              ad.dispose();
              _rewardedAd = null;
              loadRewardedAd(); // Load the next one immediately in the background
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint("AdManager: Ad Failed to Show: $error");
              ad.dispose();
              _rewardedAd = null;
              loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint("AdManager: Ad Failed to Load: ${error.message}");
          _isLoading = false;
          _rewardedAd = null;
          _adStatusController.add(false);
          // Retry after 10 seconds
          Future.delayed(const Duration(seconds: 10), () {
            loadRewardedAd();
          });
        },
      ),
    );
  }

  void showRewardedAd({
    required Function(RewardItem) onUserEarnedReward,
    VoidCallback? onAdClosed,
    VoidCallback? onAdFailed,
  }) {
    if (_rewardedAd != null) {
      _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
        onUserEarnedReward(reward);
      });
    } else {
      onAdFailed?.call();
      loadRewardedAd();
    }
  }
}
