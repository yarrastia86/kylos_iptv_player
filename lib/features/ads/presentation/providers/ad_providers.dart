// Kylos IPTV Player - Ad Providers
// Riverpod providers for ad state management.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kylos_iptv_player/features/ads/domain/ad_service.dart';
import 'package:kylos_iptv_player/features/ads/infrastructure/admob_ad_service.dart';
import 'package:kylos_iptv_player/features/ads/presentation/ad_controller.dart';
import 'package:kylos_iptv_player/infrastructure/firebase/firebase_providers.dart';
import 'package:kylos_iptv_player/shared/providers/platform_providers.dart';

/// Provider for the ad service implementation.
///
/// Returns [AdMobAdService] for mobile platforms, [MockAdService] for others.
final adServiceProvider = Provider<AdService>((ref) {
  // Use mock service for TV platforms (no banner ads on TV)
  // Interstitials and pre-roll can still work on TV
  return AdMobAdService();
});

/// Provider for the ad controller.
///
/// Manages ad display with frequency capping and subscription awareness.
final adControllerProvider = StateNotifierProvider<AdController, AdState>((ref) {
  final adService = ref.watch(adServiceProvider);
  final controller = AdController(adService: adService);

  // Listen to Pro status changes
  ref.listen(hasProProvider, (previous, next) {
    controller.updateProStatus(next);
  });

  // Initialize on first access
  controller.initialize();

  ref.onDispose(() {
    controller.dispose();
  });

  return controller;
});

/// Whether ads should be shown to the current user.
///
/// Returns false for Pro subscribers or if ads are not initialized.
final shouldShowAdsProvider = Provider<bool>((ref) {
  final adState = ref.watch(adControllerProvider);
  final isPro = ref.watch(hasProProvider);
  return !isPro && adState.isInitialized;
});

/// Whether the platform supports banner ads.
///
/// Returns false for TV platforms where banners have poor UX.
final supportsBannerAdsProvider = Provider<bool>((ref) {
  final isTV = ref.watch(isTvProvider);
  // No banner ads on TV - poor UX with remote control
  return !isTV;
});

/// Whether the platform supports any ads at all.
final supportsAdsProvider = Provider<bool>((ref) {
  final adState = ref.watch(adControllerProvider);
  return adState.isInitialized;
});

/// Helper to show an interstitial ad after the player closes.
///
/// Usage: `ref.read(showPlayerCloseInterstitialProvider)();`
final showPlayerCloseInterstitialProvider = Provider<Future<AdResult> Function()>((ref) {
  final controller = ref.read(adControllerProvider.notifier);
  return () => controller.showInterstitialAfterPlayer();
});

/// Helper to show an interstitial ad on section navigation.
///
/// Usage: `ref.read(showNavigationInterstitialProvider)();`
final showNavigationInterstitialProvider = Provider<Future<AdResult> Function()>((ref) {
  final controller = ref.read(adControllerProvider.notifier);
  return () => controller.showInterstitialOnNavigation();
});

/// Helper to load a banner ad for a placement.
///
/// Usage: `ref.read(loadBannerProvider)(AdPlacements.settingsBanner);`
final loadBannerProvider = Provider<Future<void> Function(String placement)>((ref) {
  final controller = ref.read(adControllerProvider.notifier);
  return (placement) => controller.loadBanner(placement);
});

/// Get the banner widget for a placement if loaded.
///
/// Usage: `ref.watch(bannerWidgetProvider(AdPlacements.settingsBanner))`
final bannerWidgetProvider = Provider.family<Widget?, String>((ref, placement) {
  final shouldShow = ref.watch(shouldShowAdsProvider);
  final supportsBanners = ref.watch(supportsBannerAdsProvider);

  if (!shouldShow || !supportsBanners) {
    return null;
  }

  final adService = ref.watch(adServiceProvider);
  return adService.getBannerWidget(placement: placement);
});
