// Kylos IPTV Player - AdMob Ad Service Implementation
// Google AdMob implementation of the AdService interface.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kylos_iptv_player/features/ads/domain/ad_service.dart';
import 'package:kylos_iptv_player/features/ads/domain/entities/ad_config.dart';

/// AdMob implementation of [AdService].
///
/// Handles Google Mobile Ads SDK for banner, interstitial, and rewarded ads.
class AdMobAdService implements AdService {
  AdMobAdService();

  bool _isInitialized = false;

  // Banner ads keyed by placement
  final Map<String, BannerAd> _bannerAds = {};
  final Map<String, bool> _bannerLoaded = {};

  // Interstitial ad
  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;

  // Rewarded ad
  RewardedAd? _rewardedAd;
  bool _isRewardedLoading = false;

  @override
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Skip ads on unsupported platforms
      if (!_isPlatformSupported()) {
        debugPrint('AdMob: Platform not supported');
        return false;
      }

      await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('AdMob: Initialized successfully');

      // Pre-load an interstitial
      await loadInterstitial();

      return true;
    } catch (e) {
      debugPrint('AdMob: Initialization failed: $e');
      return false;
    }
  }

  @override
  Future<bool> isAvailable() async {
    return _isPlatformSupported() && _isInitialized;
  }

  bool _isPlatformSupported() {
    // AdMob is supported on iOS and Android
    return !kIsWeb && (Platform.isIOS || Platform.isAndroid);
  }

  @override
  void dispose() {
    // Dispose all banner ads
    for (final ad in _bannerAds.values) {
      ad.dispose();
    }
    _bannerAds.clear();
    _bannerLoaded.clear();

    // Dispose interstitial
    _interstitialAd?.dispose();
    _interstitialAd = null;

    // Dispose rewarded
    _rewardedAd?.dispose();
    _rewardedAd = null;

    _isInitialized = false;
  }

  // ============================================================
  // BANNER ADS
  // ============================================================

  @override
  Future<void> loadBannerAd({
    required String adUnitId,
    required String placement,
  }) async {
    if (!_isInitialized) return;

    // Dispose existing banner for this placement
    _bannerAds[placement]?.dispose();
    _bannerLoaded[placement] = false;

    final bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('AdMob: Banner loaded for $placement');
          _bannerLoaded[placement] = true;
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('AdMob: Banner failed to load for $placement: ${error.message}');
          ad.dispose();
          _bannerAds.remove(placement);
          _bannerLoaded[placement] = false;
        },
        onAdClicked: (ad) {
          debugPrint('AdMob: Banner clicked for $placement');
        },
      ),
    );

    _bannerAds[placement] = bannerAd;
    await bannerAd.load();
  }

  @override
  Widget? getBannerWidget({required String placement}) {
    final ad = _bannerAds[placement];
    final isLoaded = _bannerLoaded[placement] ?? false;

    if (ad == null || !isLoaded) {
      return null;
    }

    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }

  @override
  void disposeBanner({required String placement}) {
    _bannerAds[placement]?.dispose();
    _bannerAds.remove(placement);
    _bannerLoaded.remove(placement);
  }

  // ============================================================
  // INTERSTITIAL ADS
  // ============================================================

  @override
  Future<void> loadInterstitial() async {
    if (!_isInitialized || _isInterstitialLoading || _interstitialAd != null) {
      return;
    }

    _isInterstitialLoading = true;

    await InterstitialAd.load(
      adUnitId: AdConfig.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('AdMob: Interstitial loaded');
          _interstitialAd = ad;
          _isInterstitialLoading = false;

          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('AdMob: Interstitial dismissed');
              ad.dispose();
              _interstitialAd = null;
              // Pre-load next interstitial
              loadInterstitial();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('AdMob: Interstitial failed to show: ${error.message}');
              ad.dispose();
              _interstitialAd = null;
              loadInterstitial();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdMob: Interstitial failed to load: ${error.message}');
          _isInterstitialLoading = false;
        },
      ),
    );
  }

  @override
  bool isInterstitialReady() {
    return _interstitialAd != null;
  }

  @override
  Future<AdResult> showInterstitial({required String placement}) async {
    if (!_isInitialized) {
      return const AdFailed('Ad service not initialized');
    }

    if (_interstitialAd == null) {
      // Try to load and wait briefly
      await loadInterstitial();
      await Future<void>.delayed(const Duration(milliseconds: 500));

      if (_interstitialAd == null) {
        return const AdNotReady();
      }
    }

    try {
      await _interstitialAd!.show();
      return const AdShown();
    } catch (e) {
      return AdFailed(e.toString());
    }
  }

  // ============================================================
  // REWARDED ADS
  // ============================================================

  @override
  Future<void> loadRewarded() async {
    if (!_isInitialized || _isRewardedLoading || _rewardedAd != null) {
      return;
    }

    _isRewardedLoading = true;

    await RewardedAd.load(
      adUnitId: AdConfig.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('AdMob: Rewarded ad loaded');
          _rewardedAd = ad;
          _isRewardedLoading = false;
        },
        onAdFailedToLoad: (error) {
          debugPrint('AdMob: Rewarded ad failed to load: ${error.message}');
          _isRewardedLoading = false;
        },
      ),
    );
  }

  @override
  bool isRewardedReady() {
    return _rewardedAd != null;
  }

  @override
  Future<AdResult> showRewarded({
    required String placement,
    required void Function(int amount, String type) onReward,
  }) async {
    if (!_isInitialized) {
      return const AdFailed('Ad service not initialized');
    }

    if (_rewardedAd == null) {
      return const AdNotReady();
    }

    try {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('AdMob: Rewarded ad dismissed');
          ad.dispose();
          _rewardedAd = null;
          loadRewarded();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('AdMob: Rewarded ad failed to show: ${error.message}');
          ad.dispose();
          _rewardedAd = null;
          loadRewarded();
        },
      );

      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          debugPrint('AdMob: User earned reward: ${reward.amount} ${reward.type}');
          onReward(reward.amount.toInt(), reward.type);
        },
      );

      return const AdShown();
    } catch (e) {
      return AdFailed(e.toString());
    }
  }
}
