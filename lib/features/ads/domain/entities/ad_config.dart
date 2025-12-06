// Kylos IPTV Player - Ad Configuration
// Configuration for ad unit IDs and frequency caps.

import 'dart:io';

/// Ad unit configuration for different platforms and ad types.
class AdConfig {
  const AdConfig._();

  // ============================================================
  // TEST AD UNIT IDS (Replace with production IDs before release)
  // ============================================================

  /// Test banner ad unit ID for Android
  static const String testBannerAndroid = 'ca-app-pub-3940256099942544/6300978111';

  /// Test banner ad unit ID for iOS
  static const String testBannerIos = 'ca-app-pub-3940256099942544/2934735716';

  /// Test interstitial ad unit ID for Android
  static const String testInterstitialAndroid = 'ca-app-pub-3940256099942544/1033173712';

  /// Test interstitial ad unit ID for iOS
  static const String testInterstitialIos = 'ca-app-pub-3940256099942544/4411468910';

  /// Test rewarded ad unit ID for Android
  static const String testRewardedAndroid = 'ca-app-pub-3940256099942544/5224354917';

  /// Test rewarded ad unit ID for iOS
  static const String testRewardedIos = 'ca-app-pub-3940256099942544/1712485313';

  // ============================================================
  // PRODUCTION AD UNIT IDS (Configure these in your AdMob console)
  // ============================================================

  /// Production banner ad unit ID for Android
  static const String prodBannerAndroid = 'YOUR_ANDROID_BANNER_AD_UNIT_ID';

  /// Production banner ad unit ID for iOS
  static const String prodBannerIos = 'YOUR_IOS_BANNER_AD_UNIT_ID';

  /// Production interstitial ad unit ID for Android
  static const String prodInterstitialAndroid = 'YOUR_ANDROID_INTERSTITIAL_AD_UNIT_ID';

  /// Production interstitial ad unit ID for iOS
  static const String prodInterstitialIos = 'YOUR_IOS_INTERSTITIAL_AD_UNIT_ID';

  /// Production rewarded ad unit ID for Android
  static const String prodRewardedAndroid = 'YOUR_ANDROID_REWARDED_AD_UNIT_ID';

  /// Production rewarded ad unit ID for iOS
  static const String prodRewardedIos = 'YOUR_IOS_REWARDED_AD_UNIT_ID';

  // ============================================================
  // HELPERS
  // ============================================================

  /// Whether to use test ads (set to false in production)
  static const bool useTestAds = true;

  /// Get banner ad unit ID for current platform
  static String get bannerAdUnitId {
    if (useTestAds) {
      return Platform.isIOS ? testBannerIos : testBannerAndroid;
    }
    return Platform.isIOS ? prodBannerIos : prodBannerAndroid;
  }

  /// Get interstitial ad unit ID for current platform
  static String get interstitialAdUnitId {
    if (useTestAds) {
      return Platform.isIOS ? testInterstitialIos : testInterstitialAndroid;
    }
    return Platform.isIOS ? prodInterstitialIos : prodInterstitialAndroid;
  }

  /// Get rewarded ad unit ID for current platform
  static String get rewardedAdUnitId {
    if (useTestAds) {
      return Platform.isIOS ? testRewardedIos : testRewardedAndroid;
    }
    return Platform.isIOS ? prodRewardedIos : prodRewardedAndroid;
  }
}

/// Frequency caps for different ad types.
/// Aggressive monetization strategy similar to YouTube/Peacock.
class AdFrequencyCaps {
  const AdFrequencyCaps._();

  /// Minimum interval between interstitial ads (in seconds)
  /// Reduced for more aggressive monetization
  static const int interstitialMinIntervalSeconds = 60; // 1 minute

  /// Minimum interval between interstitial ads after player closes (in seconds)
  static const int interstitialAfterPlayerSeconds = 0; // Show immediately

  /// Maximum interstitials per session (high limit)
  static const int maxInterstitialsPerSession = 50;

  /// Maximum interstitials per hour
  static const int maxInterstitialsPerHour = 20;

  /// Cooldown after user dismisses an ad (in seconds)
  static const int dismissCooldownSeconds = 30;

  /// Mid-roll ad interval during playback (in seconds)
  /// Ads will show every X seconds of video playback
  static const int midrollIntervalSeconds = 300; // Every 5 minutes

  /// Minimum video duration to show mid-roll ads (in seconds)
  /// Videos shorter than this won't have mid-roll ads
  static const int midrollMinVideoDurationSeconds = 600; // 10 minutes

  /// Pre-roll ad should show for EVERY video (not just first)
  static const bool prerollOnEveryVideo = true;

  /// Skip delay for pre-roll ads (in seconds)
  static const int prerollSkipDelaySeconds = 5;
}

/// Ad placement identifiers for analytics and tracking.
class AdPlacements {
  const AdPlacements._();

  /// Banner on settings screen
  static const String settingsBanner = 'settings_banner';

  /// Banner on category selection screens
  static const String categoryBanner = 'category_banner';

  /// Interstitial after closing player
  static const String playerCloseInterstitial = 'player_close_interstitial';

  /// Interstitial on section navigation
  static const String navigationInterstitial = 'navigation_interstitial';

  /// Pre-roll before video playback
  static const String prerollVideo = 'preroll_video';

  /// Mid-roll during video playback
  static const String midrollVideo = 'midroll_video';
}
