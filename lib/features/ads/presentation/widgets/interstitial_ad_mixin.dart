// Kylos IPTV Player - Interstitial Ad Mixin
// Mixin for showing interstitial ads in screens.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kylos_iptv_player/features/ads/domain/ad_service.dart';
import 'package:kylos_iptv_player/features/ads/presentation/providers/ad_providers.dart';

/// Mixin that provides interstitial ad functionality to ConsumerStatefulWidget states.
///
/// Add this mixin to any screen where you want to show interstitial ads
/// at specific triggers (e.g., closing the player, navigating away).
///
/// Example:
/// ```dart
/// class _MyScreenState extends ConsumerState<MyScreen>
///     with InterstitialAdMixin {
///
///   void _handleBack() {
///     showInterstitialOnNavigation().then((_) {
///       context.pop();
///     });
///   }
/// }
/// ```
mixin InterstitialAdMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  /// Show an interstitial ad when the player is closed.
  ///
  /// Uses a longer interval (5 minutes) between ads to avoid
  /// overwhelming users who watch multiple videos.
  Future<AdResult> showInterstitialAfterPlayer() async {
    final showAd = ref.read(showPlayerCloseInterstitialProvider);
    return showAd();
  }

  /// Show an interstitial ad on navigation between sections.
  ///
  /// Uses standard interval (3 minutes) between ads.
  Future<AdResult> showInterstitialOnNavigation() async {
    final showAd = ref.read(showNavigationInterstitialProvider);
    return showAd();
  }

  /// Check if an interstitial can be shown (frequency caps, Pro status).
  bool canShowInterstitial() {
    final controller = ref.read(adControllerProvider.notifier);
    return controller.canShowInterstitial();
  }

  /// Preload an interstitial ad for later display.
  Future<void> preloadInterstitial() async {
    final controller = ref.read(adControllerProvider.notifier);
    await controller.preloadInterstitial();
  }
}

/// Extension to easily show interstitial ads from any WidgetRef.
extension InterstitialAdExtension on WidgetRef {
  /// Show an interstitial ad after the player closes.
  Future<AdResult> showInterstitialAfterPlayer() async {
    final showAd = read(showPlayerCloseInterstitialProvider);
    return showAd();
  }

  /// Show an interstitial ad on section navigation.
  Future<AdResult> showInterstitialOnNavigation() async {
    final showAd = read(showNavigationInterstitialProvider);
    return showAd();
  }

  /// Check if ads should be shown to this user.
  bool get shouldShowAds => watch(shouldShowAdsProvider);

  /// Preload an interstitial for later use.
  Future<void> preloadInterstitial() async {
    final controller = read(adControllerProvider.notifier);
    await controller.preloadInterstitial();
  }
}

/// A wrapper widget that shows an interstitial when the user navigates away.
///
/// Useful for wrapping screens where you want to show an ad when leaving.
class InterstitialOnExitWrapper extends ConsumerStatefulWidget {
  const InterstitialOnExitWrapper({
    super.key,
    required this.child,
    this.onExit,
  });

  /// The screen content.
  final Widget child;

  /// Called after the ad is shown (or skipped) when user exits.
  final VoidCallback? onExit;

  @override
  ConsumerState<InterstitialOnExitWrapper> createState() =>
      _InterstitialOnExitWrapperState();
}

class _InterstitialOnExitWrapperState
    extends ConsumerState<InterstitialOnExitWrapper> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // Show interstitial, then allow pop
        await ref.showInterstitialOnNavigation();

        if (mounted) {
          widget.onExit?.call();
          Navigator.of(context).pop();
        }
      },
      child: widget.child,
    );
  }
}
