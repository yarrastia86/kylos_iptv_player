// Kylos IPTV Player - Ad Service Interface
// Abstract interface for ad services (AdMob, etc.)

import 'package:flutter/widgets.dart';

/// Result of showing an ad.
sealed class AdResult {
  const AdResult();
}

/// Ad was shown successfully.
class AdShown extends AdResult {
  const AdShown({this.clicked = false});

  /// Whether the user clicked on the ad.
  final bool clicked;
}

/// Ad failed to show.
class AdFailed extends AdResult {
  const AdFailed(this.error);

  /// Error message describing why the ad failed.
  final String error;
}

/// Ad was not ready to show.
class AdNotReady extends AdResult {
  const AdNotReady();
}

/// User is a Pro subscriber (no ads should be shown).
class AdSkippedPro extends AdResult {
  const AdSkippedPro();
}

/// Ad was skipped due to frequency cap.
class AdSkippedFrequencyCap extends AdResult {
  const AdSkippedFrequencyCap();
}

/// Abstract interface for ad services.
///
/// Implementations handle the specifics of ad networks like Google AdMob.
/// The app uses this interface to remain decoupled from specific ad SDKs.
abstract class AdService {
  /// Initialize the ad service.
  ///
  /// Must be called before any other methods.
  /// Returns true if initialization was successful.
  Future<bool> initialize();

  /// Check if the ad service is available on this platform.
  Future<bool> isAvailable();

  /// Dispose of resources held by the ad service.
  void dispose();

  // ============================================================
  // BANNER ADS
  // ============================================================

  /// Load a banner ad with the given unit ID.
  ///
  /// The [placement] is used for analytics tracking.
  Future<void> loadBannerAd({
    required String adUnitId,
    required String placement,
  });

  /// Get a widget to display the loaded banner ad.
  ///
  /// Returns null if no banner is loaded.
  Widget? getBannerWidget({required String placement});

  /// Dispose of a specific banner ad.
  void disposeBanner({required String placement});

  // ============================================================
  // INTERSTITIAL ADS
  // ============================================================

  /// Load an interstitial ad.
  ///
  /// Should be called in advance to pre-load for smooth UX.
  Future<void> loadInterstitial();

  /// Check if an interstitial ad is ready to show.
  bool isInterstitialReady();

  /// Show an interstitial ad.
  ///
  /// Returns [AdResult] indicating success or failure.
  /// The [placement] is used for analytics tracking.
  Future<AdResult> showInterstitial({required String placement});

  // ============================================================
  // REWARDED ADS (Optional - for future use)
  // ============================================================

  /// Load a rewarded ad.
  Future<void> loadRewarded();

  /// Check if a rewarded ad is ready to show.
  bool isRewardedReady();

  /// Show a rewarded ad.
  ///
  /// Returns [AdResult] indicating success or failure.
  /// If successful, the reward callback will be invoked.
  Future<AdResult> showRewarded({
    required String placement,
    required void Function(int amount, String type) onReward,
  });
}

/// Mock ad service for testing and platforms without ad support.
class MockAdService implements AdService {
  @override
  Future<bool> initialize() async => true;

  @override
  Future<bool> isAvailable() async => false;

  @override
  void dispose() {}

  @override
  Future<void> loadBannerAd({
    required String adUnitId,
    required String placement,
  }) async {}

  @override
  Widget? getBannerWidget({required String placement}) => null;

  @override
  void disposeBanner({required String placement}) {}

  @override
  Future<void> loadInterstitial() async {}

  @override
  bool isInterstitialReady() => false;

  @override
  Future<AdResult> showInterstitial({required String placement}) async {
    return const AdNotReady();
  }

  @override
  Future<void> loadRewarded() async {}

  @override
  bool isRewardedReady() => false;

  @override
  Future<AdResult> showRewarded({
    required String placement,
    required void Function(int amount, String type) onReward,
  }) async {
    return const AdNotReady();
  }
}
