// Kylos IPTV Player - Ad Controller
// Manages ad state, frequency capping, and subscription-aware ad display.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kylos_iptv_player/features/ads/domain/ad_service.dart';
import 'package:kylos_iptv_player/features/ads/domain/entities/ad_config.dart';

/// State for ad frequency tracking and management.
class AdState {
  const AdState({
    this.isInitialized = false,
    this.isPro = false,
    this.lastInterstitialTime,
    this.interstitialsShownThisSession = 0,
    this.interstitialsShownThisHour = 0,
    this.hourStartTime,
    this.isShowingAd = false,
  });

  /// Whether the ad service is initialized.
  final bool isInitialized;

  /// Whether the user is a Pro subscriber (no ads).
  final bool isPro;

  /// Timestamp of the last interstitial shown.
  final DateTime? lastInterstitialTime;

  /// Number of interstitials shown this session.
  final int interstitialsShownThisSession;

  /// Number of interstitials shown this hour.
  final int interstitialsShownThisHour;

  /// Start time of the current hour for tracking.
  final DateTime? hourStartTime;

  /// Whether an ad is currently being shown.
  final bool isShowingAd;

  AdState copyWith({
    bool? isInitialized,
    bool? isPro,
    DateTime? lastInterstitialTime,
    int? interstitialsShownThisSession,
    int? interstitialsShownThisHour,
    DateTime? hourStartTime,
    bool? isShowingAd,
  }) {
    return AdState(
      isInitialized: isInitialized ?? this.isInitialized,
      isPro: isPro ?? this.isPro,
      lastInterstitialTime: lastInterstitialTime ?? this.lastInterstitialTime,
      interstitialsShownThisSession: interstitialsShownThisSession ?? this.interstitialsShownThisSession,
      interstitialsShownThisHour: interstitialsShownThisHour ?? this.interstitialsShownThisHour,
      hourStartTime: hourStartTime ?? this.hourStartTime,
      isShowingAd: isShowingAd ?? this.isShowingAd,
    );
  }
}

/// Controller for managing ads with frequency capping and Pro subscriber awareness.
class AdController extends StateNotifier<AdState> {
  AdController({
    required this.adService,
  }) : super(const AdState());

  final AdService adService;

  /// Initialize the ad controller and service.
  Future<void> initialize() async {
    if (state.isInitialized) return;

    final success = await adService.initialize();
    state = state.copyWith(
      isInitialized: success,
      hourStartTime: DateTime.now(),
    );

    debugPrint('AdController: Initialized, success=$success');
  }

  /// Update Pro status from subscription state.
  void updateProStatus(bool isPro) {
    if (state.isPro != isPro) {
      state = state.copyWith(isPro: isPro);
      debugPrint('AdController: Pro status updated to $isPro');
    }
  }

  /// Check if ads should be shown to this user.
  bool get shouldShowAds => !state.isPro && state.isInitialized;

  /// Check if an interstitial can be shown based on frequency caps.
  bool canShowInterstitial({int? customMinIntervalSeconds}) {
    if (!shouldShowAds) {
      debugPrint('AdController: Cannot show interstitial - Pro user or not initialized');
      return false;
    }

    if (state.isShowingAd) {
      debugPrint('AdController: Cannot show interstitial - Already showing an ad');
      return false;
    }

    final now = DateTime.now();
    final minInterval = customMinIntervalSeconds ?? AdFrequencyCaps.interstitialMinIntervalSeconds;

    // Check time since last interstitial
    if (state.lastInterstitialTime != null) {
      final secondsSinceLast = now.difference(state.lastInterstitialTime!).inSeconds;
      if (secondsSinceLast < minInterval) {
        debugPrint('AdController: Cannot show interstitial - Too soon ($secondsSinceLast < $minInterval)');
        return false;
      }
    }

    // Check session limit
    if (state.interstitialsShownThisSession >= AdFrequencyCaps.maxInterstitialsPerSession) {
      debugPrint('AdController: Cannot show interstitial - Session limit reached');
      return false;
    }

    // Check hourly limit (reset if hour has passed)
    _checkHourlyReset(now);
    if (state.interstitialsShownThisHour >= AdFrequencyCaps.maxInterstitialsPerHour) {
      debugPrint('AdController: Cannot show interstitial - Hourly limit reached');
      return false;
    }

    return true;
  }

  void _checkHourlyReset(DateTime now) {
    if (state.hourStartTime == null) {
      state = state.copyWith(
        hourStartTime: now,
        interstitialsShownThisHour: 0,
      );
      return;
    }

    final hoursSinceStart = now.difference(state.hourStartTime!).inHours;
    if (hoursSinceStart >= 1) {
      state = state.copyWith(
        hourStartTime: now,
        interstitialsShownThisHour: 0,
      );
    }
  }

  /// Attempt to show an interstitial ad with frequency cap enforcement.
  ///
  /// Returns [AdResult] indicating success or reason for not showing.
  Future<AdResult> showInterstitialIfAllowed({
    required String placement,
    int? customMinIntervalSeconds,
  }) async {
    if (state.isPro) {
      return const AdSkippedPro();
    }

    if (!canShowInterstitial(customMinIntervalSeconds: customMinIntervalSeconds)) {
      return const AdSkippedFrequencyCap();
    }

    state = state.copyWith(isShowingAd: true);

    try {
      final result = await adService.showInterstitial(placement: placement);

      if (result is AdShown) {
        final now = DateTime.now();
        state = state.copyWith(
          lastInterstitialTime: now,
          interstitialsShownThisSession: state.interstitialsShownThisSession + 1,
          interstitialsShownThisHour: state.interstitialsShownThisHour + 1,
          isShowingAd: false,
        );
        debugPrint('AdController: Interstitial shown at $placement');
      } else {
        state = state.copyWith(isShowingAd: false);
      }

      return result;
    } catch (e) {
      state = state.copyWith(isShowingAd: false);
      return AdFailed(e.toString());
    }
  }

  /// Show interstitial after player closes (with longer interval).
  Future<AdResult> showInterstitialAfterPlayer() async {
    return showInterstitialIfAllowed(
      placement: AdPlacements.playerCloseInterstitial,
      customMinIntervalSeconds: AdFrequencyCaps.interstitialAfterPlayerSeconds,
    );
  }

  /// Show interstitial on navigation between sections.
  Future<AdResult> showInterstitialOnNavigation() async {
    return showInterstitialIfAllowed(
      placement: AdPlacements.navigationInterstitial,
    );
  }

  /// Pre-load an interstitial ad.
  Future<void> preloadInterstitial() async {
    if (shouldShowAds) {
      await adService.loadInterstitial();
    }
  }

  /// Load a banner ad for a specific placement.
  Future<void> loadBanner(String placement) async {
    if (!shouldShowAds) return;

    await adService.loadBannerAd(
      adUnitId: AdConfig.bannerAdUnitId,
      placement: placement,
    );
  }

  /// Dispose resources.
  @override
  void dispose() {
    adService.dispose();
    super.dispose();
  }
}
