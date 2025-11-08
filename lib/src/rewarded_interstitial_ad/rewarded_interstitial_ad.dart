import '../../../preload_google_ads.dart';

/// A singleton class to manage loading and showing rewarded ads.
class RewardInterstitialAd {
  static final RewardInterstitialAd instance = RewardInterstitialAd._internal();

  factory RewardInterstitialAd() {
    return instance;
  }

  RewardInterstitialAd._internal();

  RewardedInterstitialAd?
  _rewardedInterstitialAd; // Stores the loaded rewarded interstitial ad.
  bool _isRewardedInterstitialAdLoaded =
      false; // Flag to track if the rewarded ad is loaded.
  var counter =
      0; // Counter to track the number of times the ad has been shown.

  /// Loads a rewarded ad with the given unit ID and configuration.
  Future<void> load() async {
    try {
      _isRewardedInterstitialAdLoaded = false;
      await RewardedInterstitialAd.load(
        adUnitId: unitIDRewardedInterstitial, // ID for the rewarded ad unit.
        request: const AdRequest(),
        rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
          // Called when the ad has successfully loaded.
          onAdLoaded: (ad) {
            AdStats
                .instance
                .rewardedInterstitialLoad
                .value++; // Increment ad load count.
            AppLogger.log("Rewarded ad loaded.");
            _rewardedInterstitialAd = ad;
            _rewardedInterstitialAd!.setImmersiveMode(
              true,
            ); // Enable immersive mode.
            _isRewardedInterstitialAdLoaded = true;
          },
          // Called if the ad fails to load.
          onAdFailedToLoad: (LoadAdError error) {
            AdStats
                .instance
                .rewardedInterstitialFailed
                .value++; // Increment ad load failure count.
            _rewardedInterstitialAd = null;
            _isRewardedInterstitialAdLoaded = false;
          },
        ),
      );
    } catch (error) {
      _rewardedInterstitialAd?.dispose(); // Dispose ad if there's an error.
    }
  }

  /// Shows the rewarded ad if it is loaded and the conditions are met.
  Future<void> showRewardedInterstitial({
    required Function({RewardedInterstitialAd? ad, AdError? error}) callBack,
    required Function(AdWithoutView ad, RewardItem reward) onReward,
  }) async {
    if (shouldShowRewardedInterAd) {
      // Check if rewarded ad should be shown.
      // Check if the ad is loaded and the counter has reached the limit.
      if (_isRewardedInterstitialAdLoaded &&
          _rewardedInterstitialAd != null &&
          counter >= getRewardedCounter) {
        counter = 0; // Reset the counter after showing the ad.
        _rewardedInterstitialAd!
            .fullScreenContentCallback = FullScreenContentCallback(
          // Called when the ad is dismissed.
          onAdDismissedFullScreenContent: (ad) {
            callBack(ad: ad); // Callback after ad is dismissed.
            ad.dispose();
            _rewardedInterstitialAd = null;
            load(); // Reload ad after dismissal.
          },
          // Called when the ad is shown (impression).
          onAdImpression: (ad) {
            AdStats.instance.rewardedImp.value++; // Increment impression count.
          },
          // Called if the ad fails to show.
          onAdFailedToShowFullScreenContent: (ad, error) {
            callBack(ad: ad, error: error); // Callback on failure to show.
            AppLogger.error('$ad failed to show: $error');
            _rewardedInterstitialAd = null;
            ad.dispose();
            load(); // Reload ad after failure.
          },
        );

        // Show the rewarded ad and handle the reward.
        await _rewardedInterstitialAd!.show(
          onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
            onReward(ad, reward); // Handle the reward when the user earns it.
          },
        );
      } else {
        counter++; // Increment the counter if ad is not shown yet.
        callBack(); // Callback if the ad is not shown.
      }
    } else {
      callBack(); // Callback if ads shouldn't be shown.
    }
  }
}
